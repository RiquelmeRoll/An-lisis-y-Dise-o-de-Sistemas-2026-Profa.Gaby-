/* =====================================================================
   POS ESTILO ELEVENTA - MÓDULO DE INTELIGENCIA ARTIFICIAL Y TOMA DE DECISIONES
   VERSIÓN 2: ajustada al esquema real `abarrotec` (borrador v0.2 de los otros equipos)
   Motor: MySQL 8.0.46 (InnoDB, utf8mb4)    Backend IA: Python 3.13

   ORDEN DE EJECUCIÓN
     1) Que exista la base `abarrotec` (script de los otros equipos).
        OJO: ese script hace DROP DATABASE abarrotec; si lo vuelven a correr,
        las vistas v_ext_* quedan inválidas hasta recrearlas (Parte 1).
     2) Este script: Parte 0 (BD/permisos), Parte 1 (vistas), Parte 2 (tablas ia_*).

   ESTRUCTURA
     PARTE 1. CONTRATO DE LECTURA (v_ext_*)  -> datos que NOS DAN otros equipos
     PARTE 2. TABLAS PROPIAS DEL MÓDULO DE IA (ia_*) -> datos que PRODUCIMOS

   HALLAZGOS DEL ANÁLISIS DE `abarrotec` QUE AFECTAN AL DISEÑO
     - Todas las PK de negocio son INT firmado -> nuestras referencias lógicas son INT.
     - NO EXISTE en origen (las vistas devuelven NULL con -- PENDIENTE):
       costo por renglón de venta, descuento, activo/fecha_alta de producto,
       activo de proveedor, proveedor principal, unidad_medida, ultima_actualizacion
       de inventario, fecha_entrega_prometida, cantidad_recibida.
     - Inventario = solo saldo actual (producto.existencia) -> ia_snapshot_inventario_diario
       es indispensable y su historia empieza el día que se corra el ETL.
     - Venta válida = venta.estado 'COBRADA'. Compra válida = orden_compra.estado 'RECIBIDA'.
     - Sin sucursal/almacén en origen: no se agrega esa dimensión.
   ===================================================================== */

/* ---------------------------------------------------------------------
   PARTE 0. BASE DE DATOS Y PERMISOS
   --------------------------------------------------------------------- */
CREATE DATABASE IF NOT EXISTS pos_ia
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE pos_ia;

/* Usuario del módulo de IA: escribe en pos_ia, SOLO LEE de abarrotec.
   (Ejecutar con un usuario administrador; ajustar contraseña/host.)
CREATE USER IF NOT EXISTS 'ia_app'@'%' IDENTIFIED BY 'CAMBIAR_PASSWORD';
GRANT ALL PRIVILEGES ON pos_ia.* TO 'ia_app'@'%';
GRANT SELECT ON abarrotec.venta            TO 'ia_app'@'%';
GRANT SELECT ON abarrotec.detalle_venta    TO 'ia_app'@'%';
GRANT SELECT ON abarrotec.orden_compra     TO 'ia_app'@'%';
GRANT SELECT ON abarrotec.detalle_orden_compra TO 'ia_app'@'%';
GRANT SELECT ON abarrotec.producto         TO 'ia_app'@'%';
GRANT SELECT ON abarrotec.departamento      TO 'ia_app'@'%';
GRANT SELECT ON abarrotec.proveedor        TO 'ia_app'@'%';
*/

/* =====================================================================
   PARTE 1. CONTRATO DE LECTURA: VISTAS DE INTEGRACIÓN (v_ext_*)
   Viven en pos_ia (nunca dentro de abarrotec). Los alias de salida son
   los del contrato; lo que no existe en origen sale como NULL (-- PENDIENTE).
   ===================================================================== */

/* 1.1 CATÁLOGO DE PRODUCTOS ------------------------------------------- */
CREATE OR REPLACE VIEW v_ext_catalogo_productos AS
SELECT
  p.id_producto,                                    -- INT
  p.codigo_barras,                                  -- VARCHAR(50)
  p.descripcion              AS nombre,             -- VARCHAR(150)
  p.id_departamento          AS id_categoria,       -- INT NULL
  d.nombre                   AS categoria,          -- VARCHAR(80) NULL
  CAST(NULL AS SIGNED)       AS id_proveedor_principal, -- PENDIENTE: producto_proveedor es N:M sin "principal"
  CAST(NULL AS CHAR(20))     AS unidad_medida,      -- PENDIENTE: solo existe tipo_venta
  p.precio_venta,                                   -- DECIMAL(10,2) (incluye IVA si precios_incluyen_iva=TRUE)
  CAST(NULL AS SIGNED)       AS activo,             -- PENDIENTE: producto no tiene baja lógica
  CAST(NULL AS DATE)         AS fecha_alta,         -- PENDIENTE
  p.tipo_venta,                                     -- EXTRA: ENUM('UNIDAD','GRANEL','PAQUETE')
  p.usa_inventario                                  -- EXTRA: BOOLEAN; el reorden salta los FALSE
FROM abarrotec.producto p
LEFT JOIN abarrotec.departamento d ON d.id_departamento = p.id_departamento;

/* 1.2 PROVEEDORES ------------------------------------------------------ */
CREATE OR REPLACE VIEW v_ext_proveedores AS
SELECT
  pr.id_proveedor,                                  -- INT
  pr.nombre,                                        -- VARCHAR(120)
  CAST(NULL AS SIGNED)       AS activo              -- PENDIENTE: proveedor no tiene baja lógica
FROM abarrotec.proveedor pr;

/* 1.3 VENTAS A NIVEL RENGLÓN ------------------------------------------- */
/* Venta válida = estado 'COBRADA' (PENDIENTE = ticket abierto; CANCELADA se excluye).
   No existe estado DEVUELTA ni tabla de devoluciones en el borrador v0.2. */
CREATE OR REPLACE VIEW v_ext_ventas_detalle AS
SELECT
  v.id_venta,                                       -- INT
  v.fecha_hora,                                     -- DATETIME (sin zona horaria)
  v.id_cliente,                                     -- INT NULL
  dv.id_producto,                                   -- INT
  dv.cantidad,                                      -- DECIMAL(10,3)
  dv.precio_unitario,                               -- DECIMAL(10,2)
  CAST(NULL AS DECIMAL(10,2)) AS costo_unitario,    -- PENDIENTE: no hay costo congelado en el renglón
  CAST(NULL AS DECIMAL(10,2)) AS descuento          -- PENDIENTE: el descuento solo existe en factura
FROM abarrotec.detalle_venta dv
JOIN abarrotec.venta v ON v.id_venta = dv.id_venta
WHERE v.estado = 'COBRADA';

/* 1.4 VENTAS DIARIAS CONSOLIDADAS POR PRODUCTO -------------------------- */
/* ingreso_neto = cantidad * precio_unitario (puede incluir IVA y no resta descuento);
   no se usa detalle_venta.importe porque no es columna generada.
   OJO: en productos GRANEL, unidades_vendidas son kg/l, no piezas. */
CREATE OR REPLACE VIEW v_ext_ventas_diarias_producto AS
SELECT
  DATE(fecha_hora)                  AS fecha,
  id_producto,
  SUM(cantidad)                     AS unidades_vendidas,
  SUM(cantidad * precio_unitario)   AS ingreso_neto,
  CAST(NULL AS DECIMAL(14,2))       AS costo_total,   -- PENDIENTE
  COUNT(DISTINCT id_venta)          AS num_tickets
FROM v_ext_ventas_detalle
GROUP BY DATE(fecha_hora), id_producto;

/* 1.5 ESTADO ACTUAL DE INVENTARIO Y COSTOS ------------------------------ */
/* costo_promedio = producto.precio_costo (costo vigente según
   configuracion.metodo_costo_inventario; no es promedio histórico). */
CREATE OR REPLACE VIEW v_ext_inventario_actual AS
SELECT
  p.id_producto,
  p.existencia,                                     -- DECIMAL(10,3)
  p.minimo                   AS stock_minimo,       -- DECIMAL(10,3)
  p.maximo                   AS stock_maximo,       -- DECIMAL(10,3)
  p.precio_costo             AS costo_promedio,     -- DECIMAL(10,2)
  CAST(NULL AS DATETIME)     AS ultima_actualizacion -- PENDIENTE
FROM abarrotec.producto p;

/* 1.6 RECEPCIONES DE COMPRA POR RENGLÓN --------------------------------- */
/* Compra válida = estado 'RECIBIDA'. fecha_pedido = fecha_creacion de la orden,
   por lo que dias_entrega_real incluye el tiempo en PENDIENTE/ENVIADA. */
CREATE OR REPLACE VIEW v_ext_compras_recepcion AS
SELECT
  oc.id_orden_compra         AS id_compra,
  oc.id_proveedor,
  d.id_producto,
  oc.fecha_creacion          AS fecha_pedido,                -- DATETIME
  CAST(NULL AS DATETIME)     AS fecha_entrega_prometida,     -- PENDIENTE
  oc.fecha_recepcion,                                        -- DATETIME NULL
  d.cantidad                 AS cantidad_pedida,             -- DECIMAL(10,3)
  CAST(NULL AS DECIMAL(10,3)) AS cantidad_recibida,          -- PENDIENTE
  d.precio_compra            AS costo_unitario,              -- DECIMAL(10,2)
  CASE WHEN oc.fecha_recepcion IS NULL THEN NULL
       ELSE DATEDIFF(DATE(oc.fecha_recepcion), DATE(oc.fecha_creacion))
  END                        AS dias_entrega_real,
  CAST(NULL AS SIGNED)       AS dias_entrega_prometida       -- PENDIENTE
FROM abarrotec.detalle_orden_compra d
JOIN abarrotec.orden_compra oc ON oc.id_orden_compra = d.id_orden_compra
WHERE oc.estado = 'RECIBIDA';

/* =====================================================================
   PARTE 2. TABLAS PROPIAS DEL MÓDULO DE IA (ia_*)
   Convención: id_producto / id_proveedor / id_usuario son REFERENCIAS
   LÓGICAS a los otros módulos (comentadas con "-- EXT"). Las FK físicas
   solo existen entre tablas ia_*.
   ===================================================================== */

/* ---------- 2.A  CONFIGURACIÓN Y TRAZABILIDAD ------------------------ */

CREATE TABLE ia_modelo (
  id_modelo     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(80)  NOT NULL,
  tipo          ENUM('DEMANDA','REABASTECIMIENTO','REGLAS_ASOCIACION',
                     'ANOMALIAS','CLASIFICACION_ABC_XYZ') NOT NULL,
  descripcion   VARCHAR(255) NULL,
  activo        TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id_modelo),
  UNIQUE KEY uq_modelo_nombre (nombre)
) ENGINE=InnoDB COMMENT='Catálogo de modelos/algoritmos del módulo de IA';

CREATE TABLE ia_modelo_version (
  id_version           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_modelo            SMALLINT UNSIGNED NOT NULL,
  version              VARCHAR(20)  NOT NULL,
  algoritmo            VARCHAR(80)  NOT NULL,          -- p.ej. 'Prophet','SARIMA','XGBoost','FP-Growth'
  hiperparametros      JSON NULL,
  metricas_entrenamiento JSON NULL,                    -- MAE, RMSE, MAPE, etc.
  ruta_artefacto       VARCHAR(255) NULL,              -- archivo .pkl/.joblib
  fecha_creacion       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activa               TINYINT(1) NOT NULL DEFAULT 0,  -- versión en producción
  PRIMARY KEY (id_version),
  UNIQUE KEY uq_modelo_version (id_modelo, version),
  KEY ix_version_activa (id_modelo, activa),
  CONSTRAINT fk_version_modelo FOREIGN KEY (id_modelo) REFERENCES ia_modelo(id_modelo)
) ENGINE=InnoDB COMMENT='Versiones entrenadas de cada modelo';

CREATE TABLE ia_ejecucion (
  id_ejecucion      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_version        INT UNSIGNED NULL,                 -- NULL en ETL/métricas sin modelo
  tipo_ejecucion    ENUM('ETL','METRICAS','ENTRENAMIENTO','PREDICCION',
                         'RECOMENDACION','ALERTAS','REGLAS') NOT NULL,
  disparador        ENUM('PROGRAMADO','MANUAL') NOT NULL DEFAULT 'PROGRAMADO',
  id_usuario        INT NULL,              -- EXT: abarrotec.usuario (si fue manual)
  estado            ENUM('EN_CURSO','EXITOSA','FALLIDA','CANCELADA') NOT NULL DEFAULT 'EN_CURSO',
  fecha_inicio      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_fin         DATETIME NULL,
  registros_leidos  INT UNSIGNED NULL,
  registros_generados INT UNSIGNED NULL,
  parametros        JSON NULL,
  mensaje_error     TEXT NULL,
  PRIMARY KEY (id_ejecucion),
  KEY ix_ejec_tipo_fecha (tipo_ejecucion, fecha_inicio),
  KEY ix_ejec_version (id_version),
  CONSTRAINT fk_ejec_version FOREIGN KEY (id_version) REFERENCES ia_modelo_version(id_version)
) ENGINE=InnoDB COMMENT='Historial de ejecuciones (ETL, entrenamiento, predicción, etc.)';

CREATE TABLE ia_parametro (
  id_parametro   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  ambito         ENUM('GLOBAL','CATEGORIA','PROVEEDOR','PRODUCTO') NOT NULL DEFAULT 'GLOBAL',
  id_referencia  INT NOT NULL DEFAULT 0,   -- EXT (INT) según ámbito; 0 = global
  clave          VARCHAR(60) NOT NULL,                 -- 'nivel_servicio','umbral_sobreinventario_dias'
  valor          JSON NOT NULL,
  vigente_desde  DATE NOT NULL,
  vigente_hasta  DATE NULL,
  PRIMARY KEY (id_parametro),
  UNIQUE KEY uq_parametro (ambito, id_referencia, clave, vigente_desde)
) ENGINE=InnoDB COMMENT='Parámetros de negocio configurables para decisiones';

/* ---------- 2.B  DATOS DERIVADOS / MÉTRICAS --------------------------- */

CREATE TABLE ia_snapshot_inventario_diario (
  fecha           DATE NOT NULL,
  id_producto     INT NOT NULL,             -- EXT: abarrotec.producto
  existencia      DECIMAL(10,3) NOT NULL,
  costo_promedio  DECIMAL(10,2) NOT NULL,
  stock_minimo    DECIMAL(10,3) NULL,
  stock_maximo    DECIMAL(10,3) NULL,
  PRIMARY KEY (fecha, id_producto),
  KEY ix_snap_producto (id_producto, fecha)
) ENGINE=InnoDB COMMENT='Foto diaria del inventario (abarrotec guarda solo el saldo actual en producto.existencia; la historia empieza al correr el ETL); permite detectar quiebres que censuran la demanda';

CREATE TABLE ia_metrica_producto (
  id_metrica        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ejecucion      BIGINT UNSIGNED NOT NULL,
  id_producto       INT NOT NULL,           -- EXT: abarrotec.producto
  fecha_calculo     DATE NOT NULL,
  ventana_dias      SMALLINT UNSIGNED NOT NULL,
  venta_prom_diaria DECIMAL(12,4) NOT NULL,
  desviacion_std    DECIMAL(12,4) NOT NULL,
  coef_variacion    DECIMAL(8,4) NULL,
  rotacion          DECIMAL(10,4) NULL,
  dias_inventario   DECIMAL(10,2) NULL,
  margen_unitario   DECIMAL(12,4) NULL,
  clase_abc         ENUM('A','B','C') NULL,
  clase_xyz         ENUM('X','Y','Z') NULL,
  PRIMARY KEY (id_metrica),
  UNIQUE KEY uq_metrica_prod (id_producto, fecha_calculo, ventana_dias),
  KEY ix_metrica_ejec (id_ejecucion),
  CONSTRAINT fk_metprod_ejec FOREIGN KEY (id_ejecucion) REFERENCES ia_ejecucion(id_ejecucion)
) ENGINE=InnoDB COMMENT='Métricas calculadas por producto (rotación, variabilidad, ABC/XYZ)';

CREATE TABLE ia_metrica_proveedor (
  id_metrica        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ejecucion      BIGINT UNSIGNED NOT NULL,
  id_proveedor      INT NOT NULL,           -- EXT: abarrotec.proveedor
  fecha_calculo     DATE NOT NULL,
  num_ordenes       INT UNSIGNED NOT NULL,
  lead_time_prom_dias DECIMAL(8,2) NOT NULL,
  lead_time_desv_dias DECIMAL(8,2) NOT NULL,
  fill_rate         DECIMAL(5,4) NULL,                  -- recibido / pedido (0 a 1)
  cumplimiento_fecha DECIMAL(5,4) NULL,                 -- % entregas a tiempo (0 a 1)
  PRIMARY KEY (id_metrica),
  UNIQUE KEY uq_metrica_prov (id_proveedor, fecha_calculo),
  KEY ix_metprov_ejec (id_ejecucion),
  CONSTRAINT fk_metprov_ejec FOREIGN KEY (id_ejecucion) REFERENCES ia_ejecucion(id_ejecucion)
) ENGINE=InnoDB COMMENT='Desempeño calculado de proveedores (lead time, cumplimiento)';

/* ---------- 2.C  PREDICCIONES ---------------------------------------- */

CREATE TABLE ia_prediccion_demanda (
  id_prediccion     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ejecucion      BIGINT UNSIGNED NOT NULL,
  id_version        INT UNSIGNED NOT NULL,
  id_producto       INT NOT NULL,           -- EXT: abarrotec.producto
  fecha_objetivo    DATE NOT NULL,
  demanda_pronosticada DECIMAL(12,3) NOT NULL,
  limite_inferior   DECIMAL(12,3) NULL,
  limite_superior   DECIMAL(12,3) NULL,
  nivel_confianza   DECIMAL(4,3) NULL,                  -- p.ej. 0.950
  fecha_generacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_prediccion),
  UNIQUE KEY uq_pred (id_ejecucion, id_producto, fecha_objetivo),
  KEY ix_pred_prod_fecha (id_producto, fecha_objetivo),
  KEY ix_pred_version (id_version),
  CONSTRAINT fk_pred_ejec    FOREIGN KEY (id_ejecucion) REFERENCES ia_ejecucion(id_ejecucion),
  CONSTRAINT fk_pred_version FOREIGN KEY (id_version)   REFERENCES ia_modelo_version(id_version)
) ENGINE=InnoDB COMMENT='Pronóstico de demanda por producto y día';

CREATE TABLE ia_evaluacion_prediccion (
  id_prediccion     BIGINT UNSIGNED NOT NULL,           -- PK = FK (relación 1 a 1)
  demanda_real      DECIMAL(12,3) NOT NULL,
  error_abs         DECIMAL(12,3) NOT NULL,
  error_pct         DECIMAL(10,4) NULL,
  dentro_intervalo  TINYINT(1) NULL,
  fecha_evaluacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_prediccion),
  CONSTRAINT fk_eval_pred FOREIGN KEY (id_prediccion) REFERENCES ia_prediccion_demanda(id_prediccion)
) ENGINE=InnoDB COMMENT='Comparación pronóstico vs. venta real (monitoreo del modelo)';

/* ---------- 2.D  RECOMENDACIONES Y ALERTAS ---------------------------- */

CREATE TABLE ia_recomendacion_compra (
  id_recomendacion  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ejecucion      BIGINT UNSIGNED NOT NULL,
  id_producto       INT NOT NULL,           -- EXT: abarrotec.producto
  id_proveedor_sugerido INT NULL,           -- EXT: abarrotec.proveedor
  cantidad_sugerida DECIMAL(12,3) NOT NULL,
  fecha_pedido_sugerida DATE NOT NULL,
  existencia_al_calcular DECIMAL(12,3) NOT NULL,
  punto_reorden     DECIMAL(12,3) NOT NULL,
  stock_seguridad   DECIMAL(12,3) NOT NULL,
  costo_unitario_estimado DECIMAL(12,4) NULL,
  prioridad         ENUM('BAJA','MEDIA','ALTA','CRITICA') NOT NULL DEFAULT 'MEDIA',
  estado            ENUM('PENDIENTE','ACEPTADA','MODIFICADA','RECHAZADA','CADUCADA')
                    NOT NULL DEFAULT 'PENDIENTE',
  explicacion       JSON NULL,                          -- variables que justifican la sugerencia
  fecha_generacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion  DATE NULL,
  PRIMARY KEY (id_recomendacion),
  KEY ix_rec_estado_prio (estado, prioridad),
  KEY ix_rec_producto (id_producto, fecha_generacion),
  KEY ix_rec_ejec (id_ejecucion),
  CONSTRAINT fk_rec_ejec FOREIGN KEY (id_ejecucion) REFERENCES ia_ejecucion(id_ejecucion),
  CONSTRAINT ck_rec_cantidad CHECK (cantidad_sugerida > 0)
) ENGINE=InnoDB COMMENT='Sugerencias de compra (qué, cuánto, cuándo, a quién)';

CREATE TABLE ia_alerta_inventario (
  id_alerta         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ejecucion      BIGINT UNSIGNED NOT NULL,
  id_producto       INT NOT NULL,           -- EXT: abarrotec.producto
  tipo              ENUM('QUIEBRE_INMINENTE','SOBREINVENTARIO','BAJA_ROTACION',
                         'ANOMALIA_VENTAS','SIN_MOVIMIENTO') NOT NULL,
  severidad         ENUM('INFO','ADVERTENCIA','CRITICA') NOT NULL DEFAULT 'ADVERTENCIA',
  mensaje           VARCHAR(255) NOT NULL,
  dias_cobertura    DECIMAL(8,2) NULL,
  valor_observado   DECIMAL(14,4) NULL,
  valor_umbral      DECIMAL(14,4) NULL,
  estado            ENUM('ABIERTA','VISTA','ATENDIDA','DESCARTADA') NOT NULL DEFAULT 'ABIERTA',
  explicacion       JSON NULL,
  fecha_generacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion  DATETIME NULL,
  PRIMARY KEY (id_alerta),
  KEY ix_alerta_estado (estado, severidad),
  KEY ix_alerta_producto (id_producto, tipo, fecha_generacion),
  KEY ix_alerta_ejec (id_ejecucion),
  CONSTRAINT fk_alerta_ejec FOREIGN KEY (id_ejecucion) REFERENCES ia_ejecucion(id_ejecucion)
) ENGINE=InnoDB COMMENT='Alertas de inventario generadas por IA';

/* ---------- 2.E  REGLAS DE ASOCIACIÓN (VENTA CRUZADA) ----------------- */

CREATE TABLE ia_regla_asociacion (
  id_regla          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ejecucion      BIGINT UNSIGNED NOT NULL,
  soporte           DECIMAL(8,6) NOT NULL,
  confianza         DECIMAL(8,6) NOT NULL,
  lift              DECIMAL(10,4) NOT NULL,
  num_transacciones INT UNSIGNED NOT NULL,
  activa            TINYINT(1) NOT NULL DEFAULT 1,
  fecha_generacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_regla),
  KEY ix_regla_ejec (id_ejecucion, activa),
  KEY ix_regla_lift (lift),
  CONSTRAINT fk_regla_ejec FOREIGN KEY (id_ejecucion) REFERENCES ia_ejecucion(id_ejecucion)
) ENGINE=InnoDB COMMENT='Reglas "si compra A entonces B" con sus métricas';

CREATE TABLE ia_regla_asociacion_item (
  id_regla          BIGINT UNSIGNED NOT NULL,
  id_producto       INT NOT NULL,           -- EXT: abarrotec.producto
  rol               ENUM('ANTECEDENTE','CONSECUENTE') NOT NULL,
  PRIMARY KEY (id_regla, id_producto, rol),
  KEY ix_item_producto (id_producto, rol),
  CONSTRAINT fk_item_regla FOREIGN KEY (id_regla) REFERENCES ia_regla_asociacion(id_regla)
    ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Productos de cada regla (permite itemsets de varios productos)';

/* ---------- 2.F  FEEDBACK Y BITÁCORA DE DECISIONES -------------------- */

CREATE TABLE ia_feedback (
  id_feedback       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario        INT NOT NULL,           -- EXT: abarrotec.usuario
  id_recomendacion  BIGINT UNSIGNED NULL,
  id_alerta         BIGINT UNSIGNED NULL,
  id_regla          BIGINT UNSIGNED NULL,
  accion            ENUM('ACEPTAR','MODIFICAR','RECHAZAR','IGNORAR','RESOLVER','UTIL','NO_UTIL') NOT NULL,
  cantidad_final    DECIMAL(12,3) NULL,                 -- si MODIFICAR una compra
  motivo            VARCHAR(255) NULL,
  fecha             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_feedback),
  KEY ix_fb_rec (id_recomendacion),
  KEY ix_fb_alerta (id_alerta),
  KEY ix_fb_regla (id_regla),
  KEY ix_fb_usuario (id_usuario, fecha),
  CONSTRAINT fk_fb_rec    FOREIGN KEY (id_recomendacion) REFERENCES ia_recomendacion_compra(id_recomendacion),
  CONSTRAINT fk_fb_alerta FOREIGN KEY (id_alerta)        REFERENCES ia_alerta_inventario(id_alerta),
  CONSTRAINT fk_fb_regla  FOREIGN KEY (id_regla)         REFERENCES ia_regla_asociacion(id_regla),
  CONSTRAINT ck_fb_un_objetivo CHECK (
    (id_recomendacion IS NOT NULL) + (id_alerta IS NOT NULL) + (id_regla IS NOT NULL) = 1)
) ENGINE=InnoDB COMMENT='Respuesta del usuario a cada recomendación, alerta o regla (apunta a exactamente una)';

CREATE TABLE ia_decision_log (
  id_log            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ejecucion      BIGINT UNSIGNED NOT NULL,
  id_producto       INT NULL,               -- EXT: abarrotec.producto
  tipo_decision     ENUM('CALCULO_REORDEN','GENERAR_ALERTA','DESCARTAR_RECOMENDACION',
                         'CAMBIO_VERSION_MODELO','OTRA') NOT NULL,
  entradas          JSON NULL,                          -- datos usados
  regla_aplicada    VARCHAR(120) NULL,                  -- p.ej. 'existencia <= punto_reorden'
  resultado         JSON NULL,
  fecha             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_log),
  KEY ix_log_ejec (id_ejecucion),
  KEY ix_log_prod_fecha (id_producto, fecha),
  CONSTRAINT fk_log_ejec FOREIGN KEY (id_ejecucion) REFERENCES ia_ejecucion(id_ejecucion)
) ENGINE=InnoDB COMMENT='Bitácora auditable de decisiones automáticas del módulo (explicabilidad)';