DROP DATABASE IF EXISTS abarrotec;
CREATE DATABASE abarrotec CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE abarrotec;

CREATE TABLE usuario (
  id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(100) NOT NULL,
  usuario         VARCHAR(50)  NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL,
  rol             ENUM('ADMINISTRADOR','CAJERO') NOT NULL,
  activo          BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE permiso_usuario (
  id_usuario            INT PRIMARY KEY,
  perm_producto_comun   BOOLEAN NOT NULL DEFAULT FALSE,
  perm_mayoreo          BOOLEAN NOT NULL DEFAULT FALSE,
  perm_descuento        BOOLEAN NOT NULL DEFAULT FALSE,
  perm_historial_ventas BOOLEAN NOT NULL DEFAULT FALSE,
  perm_entradas_salidas BOOLEAN NOT NULL DEFAULT FALSE,
  perm_cobrar           BOOLEAN NOT NULL DEFAULT TRUE,
  perm_cobrar_credito   BOOLEAN NOT NULL DEFAULT FALSE,
  perm_cancelar_devolver BOOLEAN NOT NULL DEFAULT FALSE,
  perm_eliminar_articulos BOOLEAN NOT NULL DEFAULT FALSE,
  perm_facturar         BOOLEAN NOT NULL DEFAULT FALSE,
  perm_pago_servicios   BOOLEAN NOT NULL DEFAULT FALSE,
  perm_recargas         BOOLEAN NOT NULL DEFAULT FALSE,
  perm_buscador         BOOLEAN NOT NULL DEFAULT TRUE,
  perm_clientes         BOOLEAN NOT NULL DEFAULT FALSE,
  perm_productos        BOOLEAN NOT NULL DEFAULT FALSE,
  perm_inventario       BOOLEAN NOT NULL DEFAULT FALSE,
  perm_otros            BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE caja (
  id_caja        INT AUTO_INCREMENT PRIMARY KEY,
  nombre_caja    VARCHAR(50) NOT NULL,
  activa         BOOLEAN NOT NULL DEFAULT TRUE,
  ultimo_acceso  DATE NULL
);

CREATE TABLE configuracion (
  id_configuracion       INT AUTO_INCREMENT PRIMARY KEY,
  nombre_negocio         VARCHAR(120) NOT NULL,
  usar_inventarios       BOOLEAN NOT NULL DEFAULT TRUE,
  metodo_costo_inventario VARCHAR(30) NOT NULL DEFAULT 'PROMEDIO',
  ofrecer_credito        BOOLEAN NOT NULL DEFAULT FALSE,
  habilitar_producto_comun BOOLEAN NOT NULL DEFAULT TRUE,
  calcular_precio_auto   BOOLEAN NOT NULL DEFAULT FALSE,
  margen_ganancia_pct    DECIMAL(5,2) NOT NULL DEFAULT 0,
  redondeo_centavos      BOOLEAN NOT NULL DEFAULT FALSE,
  tipo_redondeo          VARCHAR(30) NULL,
  aviso_texto            VARCHAR(255) NULL,
  aviso_cada_n_ventas    INT NULL,
  folio_ticket_texto     VARCHAR(20) NULL,
  moneda_simbolo         VARCHAR(5)  NOT NULL DEFAULT '$',
  separador_miles        VARCHAR(2)  NOT NULL DEFAULT ',',
  separador_decimal      VARCHAR(2)  NOT NULL DEFAULT '.',
  unidades_habilitadas   VARCHAR(100) NOT NULL DEFAULT 'PZA',
  iva_tasa_default       DECIMAL(5,2) NOT NULL DEFAULT 16.00,
  precios_incluyen_iva   BOOLEAN NOT NULL DEFAULT TRUE,
  compras_habilitado     BOOLEAN NOT NULL DEFAULT TRUE,
  idioma_app             VARCHAR(10) NOT NULL DEFAULT 'es-MX',
  fecha_ultima_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,
  estado_sistema         BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_config_margen CHECK (margen_ganancia_pct >= 0),
  CONSTRAINT chk_config_iva CHECK (iva_tasa_default >= 0),
  CONSTRAINT chk_config_aviso CHECK (aviso_cada_n_ventas IS NULL OR aviso_cada_n_ventas >= 0)
);

CREATE TABLE forma_pago (
  id_forma_pago  INT AUTO_INCREMENT PRIMARY KEY,
  id_configuracion INT NOT NULL,
  nombre         VARCHAR(40) NOT NULL UNIQUE,
  habilitada     BOOLEAN NOT NULL DEFAULT TRUE,
  bloquear_si_efectivo_menor BOOLEAN NOT NULL DEFAULT FALSE,
  tipo_cambio    DECIMAL(10,4) NULL,
  cobrar_comision BOOLEAN NOT NULL DEFAULT FALSE,
  comision_pct   DECIMAL(5,2) NOT NULL DEFAULT 0,
  etiqueta_personalizada VARCHAR(50) NULL,
  CONSTRAINT fk_forma_pago_config FOREIGN KEY (id_configuracion)
    REFERENCES configuracion(id_configuracion) ON DELETE RESTRICT,
  CONSTRAINT chk_fp_cambio CHECK (tipo_cambio IS NULL OR tipo_cambio > 0),
  CONSTRAINT chk_fp_comision CHECK (comision_pct BETWEEN 0 AND 100)
);

CREATE TABLE config_corte (
  id_configuracion INT PRIMARY KEY,
  modo_corte       ENUM('solicitar_y_ajustar','no_solicitar') NOT NULL DEFAULT 'solicitar_y_ajustar',
  limite_efectivo_accion  VARCHAR(50) NULL,
  limite_efectivo_monto   DECIMAL(10,2) NULL,
  limite_efectivo_mensaje VARCHAR(255) NULL,
  CONSTRAINT fk_config_corte_config FOREIGN KEY (id_configuracion)
    REFERENCES configuracion(id_configuracion) ON DELETE CASCADE
);

CREATE TABLE config_ticket (
  id_configuracion INT PRIMARY KEY,
  nombre_negocio_ticket VARCHAR(120) NULL,
  direccion_ticket      VARCHAR(200) NULL,
  telefono_ticket       VARCHAR(20)  NULL,
  rfc_ticket            VARCHAR(13)  NULL,
  mensaje_final         VARCHAR(255) NULL,
  logo_ruta             VARCHAR(255) NULL,
  lineas_arriba         INT NOT NULL DEFAULT 0,
  lineas_abajo          INT NOT NULL DEFAULT 0,
  incluir_precio_unitario BOOLEAN NOT NULL DEFAULT TRUE,
  descripcion_completa  BOOLEAN NOT NULL DEFAULT FALSE,
  imprimir_datos_cliente BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_config_ticket_config FOREIGN KEY (id_configuracion)
    REFERENCES configuracion(id_configuracion) ON DELETE CASCADE,
  CONSTRAINT chk_ticket_lineas CHECK (lineas_arriba >= 0 AND lineas_abajo >= 0)
);

CREATE TABLE config_facturacion (
  id_configuracion INT PRIMARY KEY,
  rfc_emisor            VARCHAR(13)  NULL,
  razon_social_emisor   VARCHAR(150) NULL,
  regimen_fiscal_emisor VARCHAR(5)   NULL,
  codigo_postal_expedicion VARCHAR(5) NULL,
  certificado_cer_ruta  VARCHAR(255) NULL,
  llave_key_ruta        VARCHAR(255) NULL,
  llave_password        VARCHAR(255) NULL,
  serie_default         VARCHAR(10)  NULL,
  folio_actual          INT NOT NULL DEFAULT 1,
  CONSTRAINT fk_config_facturacion_config FOREIGN KEY (id_configuracion)
    REFERENCES configuracion(id_configuracion) ON DELETE CASCADE,
  CONSTRAINT chk_config_folio CHECK (folio_actual >= 1)
);

CREATE TABLE dispositivo (
  id_configuracion INT PRIMARY KEY,
  impresora_nombre   VARCHAR(100) NULL,
  impresora_fuente   VARCHAR(50)  NULL,
  impresora_tamano   INT NULL,
  impresora_columnas INT NULL,
  impresora_fuente_normal_totales BOOLEAN NOT NULL DEFAULT FALSE,
  impresora_negritas BOOLEAN NOT NULL DEFAULT FALSE,
  lector_serial_activo BOOLEAN NOT NULL DEFAULT FALSE,
  lector_puerto      VARCHAR(20) NULL,
  lector_baudios     INT NULL,
  lector_bits_datos  INT NULL,
  lector_paridad     VARCHAR(10) NULL,
  lector_bits_parada INT NULL,
  lector_control_flujo VARCHAR(20) NULL,
  cajon_impresora    VARCHAR(100) NULL,
  cajon_puerto       VARCHAR(20) NULL,
  bascula_conectada  BOOLEAN NOT NULL DEFAULT FALSE,
  bascula_prefijo_codigo VARCHAR(10) NULL,
  bascula_etiqueta_precio BOOLEAN NOT NULL DEFAULT FALSE,
  bascula_etiqueta_peso   BOOLEAN NOT NULL DEFAULT FALSE,
  terminal_mercado_pago   BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_dispositivo_config FOREIGN KEY (id_configuracion)
    REFERENCES configuracion(id_configuracion) ON DELETE CASCADE
);

CREATE TABLE config_servicios (
  id_configuracion INT PRIMARY KEY,
  compras_nombre_negocio  VARCHAR(120) NULL,
  compras_datos_contacto  VARCHAR(255) NULL,
  compras_correo_envio    VARCHAR(150) NULL,
  recargas_proveedor_telcel   VARCHAR(50) NULL,
  recargas_proveedor_movistar VARCHAR(50) NULL,
  recargas_proveedor_nextel_att VARCHAR(50) NULL,
  recargas_proveedor_att_plus VARCHAR(50) NULL,
  recargas_proveedor_unefon   VARCHAR(50) NULL,
  recargas_comision_fija  BOOLEAN NOT NULL DEFAULT FALSE,
  pago_servicios_proveedor VARCHAR(50) NULL,
  nube_id_comercio        VARCHAR(50) NULL,
  nube_sucursal           VARCHAR(80) NULL,
  nube_correo             VARCHAR(150) NULL,
  nube_estado_cuenta      VARCHAR(30) NULL,
  nube_ultima_sync        DATETIME NULL,
  notificaciones_correo_activas BOOLEAN NOT NULL DEFAULT FALSE,
  respaldo_ruta           VARCHAR(255) NULL,
  respaldo_auto_al_salir  BOOLEAN NOT NULL DEFAULT FALSE,
  respaldo_dias_retencion INT NULL,
  actualizaciones_buscar_al VARCHAR(30) NULL,
  licencia_estado         VARCHAR(50) NULL,
  CONSTRAINT fk_config_servicios_config FOREIGN KEY (id_configuracion)
    REFERENCES configuracion(id_configuracion) ON DELETE CASCADE,
  CONSTRAINT chk_serv_retencion CHECK (respaldo_dias_retencion IS NULL OR respaldo_dias_retencion >= 0)
);

CREATE TABLE configuracion_usuario (
  id_usuario INT PRIMARY KEY,
  id_configuracion INT NOT NULL,
  CONSTRAINT fk_config_usuario_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_config_usuario_config FOREIGN KEY (id_configuracion)
    REFERENCES configuracion(id_configuracion) ON DELETE RESTRICT
);

CREATE TABLE configuracion_caja (
  id_caja INT PRIMARY KEY,
  id_configuracion INT NOT NULL,
  CONSTRAINT fk_config_caja_caja FOREIGN KEY (id_caja)
    REFERENCES caja(id_caja) ON DELETE CASCADE,
  CONSTRAINT fk_config_caja_config FOREIGN KEY (id_configuracion)
    REFERENCES configuracion(id_configuracion) ON DELETE RESTRICT
);

CREATE TABLE departamento (
  id_departamento INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE producto (
  id_producto     INT AUTO_INCREMENT PRIMARY KEY,
  codigo_barras   VARCHAR(50)  NOT NULL UNIQUE,
  descripcion     VARCHAR(150) NOT NULL,
  tipo_venta      ENUM('UNIDAD','GRANEL','PAQUETE') NOT NULL DEFAULT 'UNIDAD',
  precio_costo    DECIMAL(10,2) NOT NULL,
  porcentaje_ganancia DECIMAL(5,2) NOT NULL DEFAULT 0,
  precio_venta    DECIMAL(10,2) NOT NULL,
  precio_mayoreo  DECIMAL(10,2) NOT NULL DEFAULT 0,
  tasa_iva        DECIMAL(5,2) NOT NULL DEFAULT 16.00,
  id_departamento INT NULL,
  usa_inventario  BOOLEAN NOT NULL DEFAULT TRUE,
  existencia      DECIMAL(10,3) NOT NULL DEFAULT 0,
  minimo          DECIMAL(10,3) NOT NULL DEFAULT 0,
  maximo          DECIMAL(10,3) NOT NULL DEFAULT 0,
  FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
);

CREATE TABLE proveedor (
  id_proveedor  INT AUTO_INCREMENT PRIMARY KEY,
  nombre        VARCHAR(120) NOT NULL,
  representante VARCHAR(100),
  telefonos     VARCHAR(100),
  correos       VARCHAR(150),
  pagina_web    VARCHAR(150),
  comentarios   TEXT
);

CREATE TABLE producto_proveedor (
  id_producto  INT NOT NULL,
  id_proveedor INT NOT NULL,
  PRIMARY KEY (id_producto, id_proveedor),
  FOREIGN KEY (id_producto)  REFERENCES producto(id_producto),
  FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor)
);

CREATE TABLE cliente (
  id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
  folio           INT NULL UNIQUE,
  nombres         VARCHAR(100) NOT NULL,
  apellidos       VARCHAR(100) NULL,
  telefono        VARCHAR(20)  NULL,
  correo_electronico VARCHAR(150) NULL,
  domicilio1      VARCHAR(150) NULL,
  domicilio2      VARCHAR(150) NULL,
  colonia         VARCHAR(80)  NULL,
  municipio       VARCHAR(80)  NULL,
  estado_geografico VARCHAR(60) NULL,
  codigo_postal   VARCHAR(5)   NULL,
  notas           VARCHAR(255) NULL,
  tiene_credito_autorizado BOOLEAN NOT NULL DEFAULT FALSE,
  limite_credito  DECIMAL(10,2) NOT NULL DEFAULT 0,
  saldo_actual    DECIMAL(10,2) NOT NULL DEFAULT 0,
  fecha_ultimo_pago DATE NULL,
  fecha_registro  DATE NOT NULL DEFAULT (CURRENT_DATE),
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  INDEX idx_cliente_nombre (nombres, apellidos),
  INDEX idx_cliente_telefono (telefono),
  CONSTRAINT chk_cliente_cp CHECK (codigo_postal IS NULL OR codigo_postal REGEXP '^[0-9]{5}$'),
  CONSTRAINT chk_cliente_limite CHECK (limite_credito >= 0),
  CONSTRAINT chk_cliente_saldo CHECK (saldo_actual >= 0)
);

CREATE TABLE cliente_facturacion (
  id_cliente_facturacion INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente      INT NOT NULL UNIQUE,
  rfc             VARCHAR(13) NOT NULL,
  razon_social    VARCHAR(150) NOT NULL,
  regimen_fiscal  VARCHAR(5)  NOT NULL,
  uso_cfdi        VARCHAR(5)  NOT NULL,
  codigo_postal_fiscal VARCHAR(5) NOT NULL,
  CONSTRAINT fk_cliente_fiscal_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
  INDEX idx_cliente_fiscal_rfc (rfc),
  CONSTRAINT chk_cliente_fiscal_rfc CHECK (CHAR_LENGTH(rfc) IN (12, 13)),
  CONSTRAINT chk_cliente_fiscal_cp CHECK (codigo_postal_fiscal REGEXP '^[0-9]{5}$')
);

CREATE TABLE venta (
  id_venta     INT AUTO_INCREMENT PRIMARY KEY,
  folio        INT NOT NULL UNIQUE,
  fecha_hora   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario   INT NOT NULL,
  id_caja      INT NULL,
  id_cliente   INT NULL,
  tipo_venta   ENUM('MENUDEO','MAYOREO') NOT NULL DEFAULT 'MENUDEO',
  estado       ENUM('ABIERTA','PENDIENTE_PAGO','PAGO_COMPLETADO','RECHAZADA','CANCELADA') NOT NULL DEFAULT 'ABIERTA',
  es_credito   BOOLEAN NOT NULL DEFAULT FALSE,
  fecha_hora_pago DATETIME NULL,
  total        DECIMAL(12,2) NOT NULL DEFAULT 0,
  motivo_cancelacion VARCHAR(255) NULL,
  notas        VARCHAR(255),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  FOREIGN KEY (id_caja)    REFERENCES caja(id_caja),
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

CREATE TABLE detalle_venta (
  id_detalle_venta INT AUTO_INCREMENT PRIMARY KEY,
  id_venta     INT NOT NULL,
  id_producto  INT NOT NULL,
  id_departamento INT NULL,
  cantidad     DECIMAL(10,3) NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  costo_unitario  DECIMAL(10,2) NOT NULL DEFAULT 0,
  tasa_iva        DECIMAL(5,2)  NOT NULL DEFAULT 16.00,
  importe      DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (id_venta)    REFERENCES venta(id_venta),
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
  FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
);

CREATE TABLE pago_venta (
  id_pago_venta INT AUTO_INCREMENT PRIMARY KEY,
  id_venta      INT NOT NULL,
  id_forma_pago INT NOT NULL,
  monto         DECIMAL(10,2) NOT NULL,
  comision      DECIMAL(10,2) NOT NULL DEFAULT 0,
  referencia    VARCHAR(50) NULL,
  FOREIGN KEY (id_venta)      REFERENCES venta(id_venta),
  FOREIGN KEY (id_forma_pago) REFERENCES forma_pago(id_forma_pago)
);

CREATE TABLE abono (
  id_abono      INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente    INT NOT NULL,
  id_venta      INT NULL,
  fecha_abono   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  monto         DECIMAL(10,2) NOT NULL,
  id_forma_pago INT NOT NULL,
  id_usuario    INT NOT NULL,
  id_caja       INT NULL,
  saldo_anterior DECIMAL(10,2) NOT NULL,
  saldo_nuevo   DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (id_cliente)    REFERENCES cliente(id_cliente),
  FOREIGN KEY (id_venta)      REFERENCES venta(id_venta),
  FOREIGN KEY (id_forma_pago) REFERENCES forma_pago(id_forma_pago),
  FOREIGN KEY (id_usuario)    REFERENCES usuario(id_usuario),
  FOREIGN KEY (id_caja)       REFERENCES caja(id_caja),
  INDEX idx_abono_cliente_fecha (id_cliente, fecha_abono),
  CONSTRAINT chk_abono_monto CHECK (monto > 0),
  CONSTRAINT chk_abono_saldos CHECK (saldo_anterior >= 0 AND saldo_nuevo >= 0
                                    AND saldo_nuevo = saldo_anterior - monto)
);

CREATE TABLE factura (
  id_factura    INT AUTO_INCREMENT PRIMARY KEY,
  id_configuracion INT NOT NULL,
  serie         VARCHAR(10) NOT NULL DEFAULT '',
  folio         INT NOT NULL,
  id_cliente    INT NOT NULL,
  id_venta      INT NULL,
  tipo          ENUM('por_venta','global') NOT NULL DEFAULT 'por_venta',
  fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  rfc_emisor    VARCHAR(13) NOT NULL,
  rfc_receptor  VARCHAR(13) NOT NULL,
  uso_cfdi      VARCHAR(5)  NOT NULL,
  forma_pago    VARCHAR(5)  NOT NULL,
  metodo_pago   ENUM('PUE','PPD') NOT NULL,
  moneda        VARCHAR(5)  NOT NULL DEFAULT 'MXN',
  subtotal      DECIMAL(12,2) NOT NULL,
  descuento     DECIMAL(12,2) NOT NULL DEFAULT 0,
  impuestos     DECIMAL(12,2) NOT NULL DEFAULT 0,
  total         DECIMAL(12,2) NOT NULL,
  estado        ENUM('vigente','cancelacion solicitada','cancelada') NOT NULL DEFAULT 'vigente',
  fecha_cancelacion  DATETIME NULL,
  motivo_cancelacion VARCHAR(2) NULL,
  uuid_sustitucion   VARCHAR(36) NULL,
  uuid          VARCHAR(36) NULL UNIQUE,
  fecha_timbrado DATETIME NULL,
  xml_ruta      VARCHAR(255) NULL,
  pdf_ruta      VARCHAR(255) NULL,
  UNIQUE KEY uq_factura_folio_emisor (rfc_emisor, serie, folio),
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
  CONSTRAINT fk_factura_venta FOREIGN KEY (id_venta) REFERENCES venta(id_venta),
  CONSTRAINT fk_factura_config FOREIGN KEY (id_configuracion)
    REFERENCES config_facturacion(id_configuracion) ON DELETE RESTRICT,
  CONSTRAINT fk_factura_datos_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente_facturacion(id_cliente) ON DELETE RESTRICT,
  INDEX idx_factura_fecha (fecha_emision),
  CONSTRAINT chk_factura_folio CHECK (folio >= 1),
  CONSTRAINT chk_factura_montos CHECK (subtotal >= 0 AND descuento >= 0
    AND descuento <= subtotal AND impuestos >= 0 AND total >= 0),
  CONSTRAINT chk_factura_total CHECK (total = subtotal - descuento + impuestos),
  CONSTRAINT chk_factura_tipo_venta CHECK (
    (tipo = 'por_venta' AND id_venta IS NOT NULL) OR
    (tipo = 'global' AND id_venta IS NULL)),
  CONSTRAINT chk_factura_motivo CHECK (motivo_cancelacion IS NULL
    OR motivo_cancelacion IN ('01','02','03','04')),
  CONSTRAINT chk_factura_sustitucion CHECK (uuid_sustitucion IS NULL
    OR (motivo_cancelacion IS NOT NULL AND motivo_cancelacion = '01'))
);

CREATE TABLE factura_detalle (
  id_factura_detalle INT AUTO_INCREMENT PRIMARY KEY,
  id_factura       INT NOT NULL,
  id_producto      INT NULL,
  codigo_barras    VARCHAR(50) NULL,
  clave_prod_serv  VARCHAR(10) NOT NULL,
  clave_unidad     VARCHAR(5)  NOT NULL,
  descripcion      VARCHAR(200) NOT NULL,
  cantidad         DECIMAL(10,3) NOT NULL,
  valor_unitario   DECIMAL(12,2) NOT NULL,
  importe          DECIMAL(12,2) GENERATED ALWAYS AS
                   (ROUND(cantidad * valor_unitario, 2)) STORED,
  objeto_impuesto  ENUM('01','02','03') NOT NULL,
  tasa_iva         DECIMAL(5,2) NOT NULL DEFAULT 16.00,
  CONSTRAINT fk_factura_detalle_factura FOREIGN KEY (id_factura)
    REFERENCES factura(id_factura) ON DELETE RESTRICT,
  CONSTRAINT fk_factura_detalle_producto FOREIGN KEY (id_producto)
    REFERENCES producto(id_producto) ON DELETE RESTRICT,
  CONSTRAINT chk_fd_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_fd_valor CHECK (valor_unitario >= 0),
  CONSTRAINT chk_fd_tasa CHECK (tasa_iva BETWEEN 0 AND 100)
);

CREATE TABLE factura_venta_global (
  id_factura INT NOT NULL,
  id_venta INT NOT NULL,
  PRIMARY KEY (id_factura, id_venta),
  CONSTRAINT fk_fvg_factura FOREIGN KEY (id_factura)
    REFERENCES factura(id_factura) ON DELETE RESTRICT,
  CONSTRAINT fk_fvg_venta FOREIGN KEY (id_venta)
    REFERENCES venta(id_venta) ON DELETE RESTRICT
);

CREATE TABLE devolucion (
  id_devolucion  INT AUTO_INCREMENT PRIMARY KEY,
  id_venta       INT NOT NULL,
  id_usuario     INT NOT NULL,
  fecha_hora     DATETIME NOT NULL,
  monto          DECIMAL(12,2) NOT NULL,
  costo_devuelto DECIMAL(12,2) NOT NULL DEFAULT 0,
  motivo         VARCHAR(255) NULL,
  FOREIGN KEY (id_venta)   REFERENCES venta(id_venta),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  CONSTRAINT chk_dev_monto CHECK (monto >= 0 AND costo_devuelto >= 0)
);

CREATE TABLE bitacora (
  id_bitacora  INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario   INT NULL,
  fecha_hora   DATETIME NOT NULL,
  evento       ENUM('EXPORTACION','ACCESO_DENEGADO','ALERTA_DISCREPANCIA') NOT NULL,
  reporte      VARCHAR(60) NULL,
  formato_export ENUM('XLSX','CSV') NULL,
  registros_exportados INT NULL,
  nombre_archivo VARCHAR(120) NULL,
  detalle      VARCHAR(255) NULL,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE INDEX idx_venta_pago ON venta (estado, fecha_hora_pago, id_caja);
CREATE INDEX idx_devolucion_fecha ON devolucion (fecha_hora);
CREATE INDEX idx_bitacora_evento ON bitacora (evento, fecha_hora);

CREATE TABLE orden_compra (
  id_orden_compra INT AUTO_INCREMENT PRIMARY KEY,
  numero       INT NOT NULL UNIQUE,
  id_proveedor INT NOT NULL,
  id_usuario   INT NOT NULL,
  estado       ENUM('PENDIENTE','ENVIADA','RECIBIDA','CANCELADA') NOT NULL DEFAULT 'PENDIENTE',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_recepcion DATETIME NULL,
  total        DECIMAL(10,2) NOT NULL DEFAULT 0,
  FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor),
  FOREIGN KEY (id_usuario)   REFERENCES usuario(id_usuario)
);

CREATE TABLE detalle_orden_compra (
  id_detalle_orden_compra INT AUTO_INCREMENT PRIMARY KEY,
  id_orden_compra INT NOT NULL,
  id_producto  INT NOT NULL,
  cantidad     DECIMAL(10,3) NOT NULL,
  precio_compra DECIMAL(10,2) NOT NULL,
  importe      DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (id_orden_compra) REFERENCES orden_compra(id_orden_compra),
  FOREIGN KEY (id_producto)     REFERENCES producto(id_producto)
);

CREATE TABLE pago_compra (
  id_pago_compra  INT AUTO_INCREMENT PRIMARY KEY,
  id_orden_compra INT NOT NULL,
  id_forma_pago   INT NOT NULL,
  monto           DECIMAL(10,2) NOT NULL,
  referencia      VARCHAR(50) NULL,
  FOREIGN KEY (id_orden_compra) REFERENCES orden_compra(id_orden_compra),
  FOREIGN KEY (id_forma_pago)   REFERENCES forma_pago(id_forma_pago)
);

CREATE TABLE corte_caja (
  id_corte_caja   INT AUTO_INCREMENT PRIMARY KEY,
  id_caja         INT NOT NULL,
  id_usuario      INT NOT NULL,
  fecha_apertura  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_cierre    DATETIME NULL,
  fondo_inicial   DECIMAL(12,2) NOT NULL DEFAULT 0,
  efectivo_esperado DECIMAL(12,2) NULL,
  efectivo_contado  DECIMAL(12,2) NULL,
  diferencia      DECIMAL(12,2) NULL,
  estado          ENUM('ABIERTO','CERRADO') NOT NULL DEFAULT 'ABIERTO',
  FOREIGN KEY (id_caja)    REFERENCES caja(id_caja),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  INDEX idx_corte_caja_estado (id_caja, estado),
  CONSTRAINT chk_corte_fondo CHECK (fondo_inicial >= 0),
  CONSTRAINT chk_corte_fechas CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_apertura)
);

CREATE TABLE movimiento_efectivo (
  id_movimiento_efectivo INT AUTO_INCREMENT PRIMARY KEY,
  id_corte_caja INT NOT NULL,
  id_usuario    INT NOT NULL,
  tipo          ENUM('ENTRADA','SALIDA') NOT NULL,
  monto         DECIMAL(12,2) NOT NULL,
  concepto      VARCHAR(150) NOT NULL,
  fecha_hora    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_corte_caja) REFERENCES corte_caja(id_corte_caja),
  FOREIGN KEY (id_usuario)    REFERENCES usuario(id_usuario),
  CONSTRAINT chk_mov_efectivo_monto CHECK (monto > 0)
);

CREATE TABLE movimiento_inventario (
  id_movimiento_inventario INT AUTO_INCREMENT PRIMARY KEY,
  id_producto   INT NOT NULL,
  tipo          ENUM('ENTRADA_COMPRA','SALIDA_VENTA','DEVOLUCION','AJUSTE') NOT NULL,
  cantidad      DECIMAL(10,3) NOT NULL,
  existencia_resultante DECIMAL(10,3) NOT NULL,
  fecha_hora    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario    INT NOT NULL,
  id_detalle_venta INT NULL,
  id_orden_compra  INT NULL,
  id_devolucion    INT NULL,
  motivo        VARCHAR(255) NULL,
  FOREIGN KEY (id_producto)      REFERENCES producto(id_producto),
  FOREIGN KEY (id_usuario)       REFERENCES usuario(id_usuario),
  FOREIGN KEY (id_detalle_venta) REFERENCES detalle_venta(id_detalle_venta),
  FOREIGN KEY (id_orden_compra)  REFERENCES orden_compra(id_orden_compra),
  FOREIGN KEY (id_devolucion)    REFERENCES devolucion(id_devolucion),
  INDEX idx_mov_inv_producto_fecha (id_producto, fecha_hora),
  CONSTRAINT chk_mov_inv_cantidad CHECK (cantidad <> 0)
);

ALTER TABLE proveedor ADD COLUMN activo BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE venta ADD COLUMN id_corte_caja INT NULL,
  ADD CONSTRAINT fk_venta_corte FOREIGN KEY (id_corte_caja) REFERENCES corte_caja(id_corte_caja);
ALTER TABLE pago_venta
  ADD COLUMN estado ENUM('PENDIENTE','APROBADO','RECHAZADO') NOT NULL DEFAULT 'APROBADO',
  ADD COLUMN fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN motivo_rechazo VARCHAR(150) NULL;

ALTER TABLE producto
  ADD CONSTRAINT chk_producto_precios CHECK (precio_costo >= 0 AND precio_venta >= 0 AND precio_mayoreo >= 0),
  ADD CONSTRAINT chk_producto_iva CHECK (tasa_iva BETWEEN 0 AND 100);
ALTER TABLE venta
  ADD CONSTRAINT chk_venta_total CHECK (total >= 0),
  ADD CONSTRAINT chk_venta_pago_fecha CHECK (estado <> 'PAGO_COMPLETADO' OR fecha_hora_pago IS NOT NULL);
ALTER TABLE detalle_venta
  ADD CONSTRAINT chk_dv_cantidad CHECK (cantidad > 0),
  ADD CONSTRAINT chk_dv_montos CHECK (precio_unitario >= 0 AND costo_unitario >= 0 AND importe >= 0),
  ADD CONSTRAINT chk_dv_iva CHECK (tasa_iva BETWEEN 0 AND 100);
ALTER TABLE pago_venta
  ADD CONSTRAINT chk_pv_monto CHECK (monto > 0 AND comision >= 0);
ALTER TABLE orden_compra ADD CONSTRAINT chk_oc_total CHECK (total >= 0);
ALTER TABLE detalle_orden_compra
  ADD CONSTRAINT chk_doc_cantidad CHECK (cantidad > 0),
  ADD CONSTRAINT chk_doc_montos CHECK (precio_compra >= 0 AND importe >= 0);
ALTER TABLE pago_compra ADD CONSTRAINT chk_pc_monto CHECK (monto > 0);

CREATE INDEX idx_producto_descripcion ON producto (descripcion);
CREATE INDEX idx_venta_fecha ON venta (fecha_hora);
CREATE INDEX idx_pago_venta_estado ON pago_venta (estado, fecha_hora);
CREATE INDEX idx_orden_compra_estado ON orden_compra (estado, fecha_creacion);

INSERT INTO configuracion (nombre_negocio) VALUES ('Mi negocio');
INSERT INTO forma_pago (id_configuracion, nombre, habilitada) VALUES
 (1,'EFECTIVO',TRUE),(1,'DOLARES',FALSE),(1,'TARJETA',TRUE),(1,'TRANSFERENCIA',FALSE),
 (1,'CHEQUE',FALSE),(1,'VALES',FALSE),(1,'CREDITO',TRUE),(1,'MIXTO',TRUE);
INSERT INTO caja (nombre_caja) VALUES ('Caja 1');

INSERT INTO config_corte (id_configuracion) VALUES (1);
INSERT INTO config_ticket (id_configuracion, nombre_negocio_ticket)
  SELECT id_configuracion, nombre_negocio FROM configuracion WHERE id_configuracion = 1;
INSERT INTO config_facturacion (id_configuracion) VALUES (1);
INSERT INTO dispositivo (id_configuracion) VALUES (1);
INSERT INTO config_servicios (id_configuracion) VALUES (1);
INSERT INTO configuracion_caja (id_caja, id_configuracion)
  SELECT id_caja, 1 FROM caja;
INSERT INTO usuario (nombre, usuario, contrasena_hash, rol) VALUES ('Administrador','admin','CAMBIAR_HASH','ADMINISTRADOR');
INSERT INTO configuracion_usuario (id_usuario, id_configuracion) VALUES (1, 1);

CREATE OR REPLACE VIEW vw_reporte_saldos AS
SELECT c.id_cliente,
       CONCAT(c.nombres, ' ', COALESCE(c.apellidos, '')) AS cliente,
       c.telefono, c.limite_credito, c.saldo_actual,
       c.limite_credito - c.saldo_actual AS credito_disponible,
       c.fecha_ultimo_pago
FROM cliente c
WHERE c.activo = TRUE AND c.tiene_credito_autorizado = TRUE;

CREATE OR REPLACE VIEW vw_factura_detalle_iva AS
SELECT d.*,
       CASE WHEN d.objeto_impuesto = '02'
            THEN ROUND(d.importe * d.tasa_iva / 100, 2)
            ELSE 0.00 END AS iva_importe
FROM factura_detalle d;

DELIMITER $$

CREATE PROCEDURE sp_registrarAbono (
    IN p_idCliente INT,
    IN p_monto DECIMAL(10,2),
    IN p_idFormaPago INT,
    IN p_idCajero INT,
    IN p_idCaja INT
)
BEGIN
    DECLARE v_saldo DECIMAL(10,2) DEFAULT NULL;
    DECLARE v_cfg INT DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_monto IS NULL OR p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto debe ser mayor a cero';
    END IF;
    START TRANSACTION;
    SELECT saldo_actual INTO v_saldo FROM cliente
      WHERE id_cliente = p_idCliente AND activo = TRUE FOR UPDATE;
    IF v_saldo IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente no existe o esta inactivo';
    END IF;
    IF p_monto > v_saldo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El abono excede el saldo del cliente';
    END IF;
    SELECT id_configuracion INTO v_cfg FROM forma_pago
      WHERE id_forma_pago = p_idFormaPago AND habilitada = TRUE;
    IF v_cfg IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La forma de pago no existe o esta deshabilitada';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM usuario u JOIN configuracion_usuario cu ON cu.id_usuario = u.id_usuario
        WHERE u.id_usuario = p_idCajero AND u.activo = TRUE AND cu.id_configuracion = v_cfg
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente, inactivo o de otra configuracion';
    END IF;
    IF p_idCaja IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM configuracion_caja WHERE id_caja = p_idCaja AND id_configuracion = v_cfg
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La caja no pertenece a la configuracion del pago';
    END IF;

    INSERT INTO abono (id_cliente, monto, id_forma_pago, id_usuario, id_caja,
                       saldo_anterior, saldo_nuevo)
    VALUES (p_idCliente, p_monto, p_idFormaPago, p_idCajero, p_idCaja,
            v_saldo, v_saldo - p_monto);
    UPDATE cliente SET saldo_actual = v_saldo - p_monto, fecha_ultimo_pago = CURRENT_DATE
      WHERE id_cliente = p_idCliente;
    COMMIT;
END$$

CREATE PROCEDURE sp_crearFactura (
    IN p_idConfiguracion INT,
    IN p_idCliente INT,
    IN p_idVenta INT,
    IN p_tipo VARCHAR(10),
    IN p_formaPago VARCHAR(5),
    IN p_metodoPago VARCHAR(3),
    IN p_usoCFDI VARCHAR(5),
    OUT p_idFactura INT
)
BEGIN
    DECLARE v_serie VARCHAR(10) DEFAULT NULL;
    DECLARE v_folio INT DEFAULT NULL;
    DECLARE v_emisor VARCHAR(13) DEFAULT NULL;
    DECLARE v_receptor VARCHAR(13) DEFAULT NULL;
    DECLARE v_uso VARCHAR(5) DEFAULT NULL;
    DECLARE v_estado_venta VARCHAR(20) DEFAULT NULL;
    DECLARE v_cliente_venta INT DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_idFactura = NULL;
        RESIGNAL;
    END;
    SET p_idFactura = NULL;
    IF p_tipo IS NULL OR p_tipo NOT IN ('por_venta','global') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de factura invalido';
    END IF;
    IF (p_tipo = 'por_venta' AND p_idVenta IS NULL)
       OR (p_tipo = 'global' AND p_idVenta IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Venta incompatible con el tipo de factura';
    END IF;
    IF p_formaPago IS NULL OR TRIM(p_formaPago) = ''
       OR p_metodoPago IS NULL OR p_metodoPago NOT IN ('PUE','PPD') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Indique forma fiscal y metodo de pago validos';
    END IF;

    START TRANSACTION;
    SELECT serie_default, folio_actual, rfc_emisor INTO v_serie, v_folio, v_emisor
      FROM config_facturacion WHERE id_configuracion = p_idConfiguracion FOR UPDATE;
    IF v_folio IS NULL OR v_emisor IS NULL OR TRIM(v_emisor) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Configure los datos del emisor antes de facturar';
    END IF;
    SELECT cf.rfc, cf.uso_cfdi INTO v_receptor, v_uso
      FROM cliente_facturacion cf JOIN cliente c ON c.id_cliente = cf.id_cliente
      WHERE cf.id_cliente = p_idCliente AND c.activo = TRUE;
    IF v_receptor IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente no esta activo o carece de datos fiscales';
    END IF;

    IF p_tipo = 'por_venta' THEN
        SELECT estado, id_cliente INTO v_estado_venta, v_cliente_venta
          FROM venta WHERE id_venta = p_idVenta FOR UPDATE;
        IF v_estado_venta IS NULL OR v_estado_venta <> 'PAGO_COMPLETADO' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta no existe o no esta pagada';
        END IF;
        IF v_cliente_venta IS NOT NULL AND v_cliente_venta <> p_idCliente THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta pertenece a otro cliente';
        END IF;
        IF EXISTS (SELECT 1 FROM factura WHERE id_venta = p_idVenta AND estado <> 'cancelada')
           OR EXISTS (SELECT 1 FROM factura_venta_global g JOIN factura f ON f.id_factura = g.id_factura
                      WHERE g.id_venta = p_idVenta AND f.estado <> 'cancelada') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta ya esta vinculada a una factura no cancelada';
        END IF;
    END IF;

    INSERT INTO factura (id_configuracion, serie, folio, id_cliente, id_venta, tipo,
                         rfc_emisor, rfc_receptor, uso_cfdi, forma_pago, metodo_pago,
                         subtotal, descuento, impuestos, total)
    VALUES (p_idConfiguracion, COALESCE(v_serie, ''), v_folio, p_idCliente, p_idVenta, p_tipo,
            v_emisor, v_receptor, COALESCE(NULLIF(TRIM(p_usoCFDI), ''), v_uso),
            p_formaPago, p_metodoPago, 0, 0, 0, 0);
    SET p_idFactura = LAST_INSERT_ID();
    UPDATE config_facturacion SET folio_actual = folio_actual + 1
      WHERE id_configuracion = p_idConfiguracion;
    COMMIT;
END$$

CREATE TRIGGER trg_factura_global_insert BEFORE INSERT ON factura_venta_global
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(10) DEFAULT NULL;
    DECLARE v_uuid VARCHAR(36) DEFAULT NULL;
    DECLARE v_estado VARCHAR(30) DEFAULT NULL;
    DECLARE v_venta VARCHAR(20) DEFAULT NULL;
    SELECT tipo, uuid, estado INTO v_tipo, v_uuid, v_estado
      FROM factura WHERE id_factura = NEW.id_factura FOR UPDATE;
    IF v_tipo IS NULL OR v_tipo <> 'global' OR v_uuid IS NOT NULL OR v_estado <> 'vigente' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Se requiere una factura global vigente y sin timbrar';
    END IF;
    SELECT estado INTO v_venta FROM venta WHERE id_venta = NEW.id_venta FOR UPDATE;
    IF v_venta IS NULL OR v_venta <> 'PAGO_COMPLETADO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta no existe o no esta pagada';
    END IF;
    IF EXISTS (SELECT 1 FROM factura WHERE id_venta = NEW.id_venta AND estado <> 'cancelada')
       OR EXISTS (SELECT 1 FROM factura_venta_global g JOIN factura f ON f.id_factura = g.id_factura
                  WHERE g.id_venta = NEW.id_venta AND f.estado <> 'cancelada') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta ya esta vinculada a una factura no cancelada';
    END IF;
END$$

CREATE TRIGGER trg_factura_global_update BEFORE UPDATE ON factura_venta_global
FOR EACH ROW
BEGIN
    IF NEW.id_factura <> OLD.id_factura OR NEW.id_venta <> OLD.id_venta THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Para corregir la asociacion, eliminarla y registrarla nuevamente';
    END IF;
END$$

CREATE TRIGGER trg_factura_global_delete BEFORE DELETE ON factura_venta_global
FOR EACH ROW
BEGIN
    DECLARE v_uuid VARCHAR(36);
    DECLARE v_estado VARCHAR(30);
    SELECT uuid, estado INTO v_uuid, v_estado FROM factura
      WHERE id_factura = OLD.id_factura FOR UPDATE;
    IF v_uuid IS NOT NULL OR v_estado <> 'vigente' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se elimina la relacion de una factura timbrada o cancelada';
    END IF;
END$$

CREATE PROCEDURE sp_calcularTotales (IN p_idFactura INT)
BEGIN
    DECLARE v_estado VARCHAR(30) DEFAULT NULL;
    DECLARE v_uuid VARCHAR(36) DEFAULT NULL;
    DECLARE v_descuento DECIMAL(12,2);
    DECLARE v_subtotal DECIMAL(12,2);
    DECLARE v_iva DECIMAL(12,2);
    DECLARE v_n INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    SELECT estado, uuid, descuento INTO v_estado, v_uuid, v_descuento
      FROM factura WHERE id_factura = p_idFactura FOR UPDATE;
    IF v_estado IS NULL OR v_estado <> 'vigente' OR v_uuid IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se recalculan facturas vigentes sin timbrar';
    END IF;
    IF v_descuento <> 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El calculo basico no admite descuentos globales';
    END IF;
    SELECT COUNT(*), COALESCE(SUM(importe), 0), COALESCE(SUM(iva_importe), 0)
      INTO v_n, v_subtotal, v_iva FROM vw_factura_detalle_iva WHERE id_factura = p_idFactura;
    IF v_n = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Agregue al menos un concepto antes de calcular';
    END IF;
    UPDATE factura SET subtotal = v_subtotal, impuestos = v_iva,
                       total = v_subtotal - v_descuento + v_iva
      WHERE id_factura = p_idFactura;
    COMMIT;
END$$

CREATE PROCEDURE sp_solicitarCancelacion (
    IN p_idFactura INT,
    IN p_motivo CHAR(2),
    IN p_uuidSustitucion VARCHAR(36)
)
BEGIN
    DECLARE v_estado VARCHAR(30) DEFAULT NULL;
    DECLARE v_uuid VARCHAR(36) DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF p_motivo IS NULL OR p_motivo NOT IN ('01','02','03','04') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo de cancelacion invalido';
    END IF;
    IF p_motivo = '01' AND (p_uuidSustitucion IS NULL OR TRIM(p_uuidSustitucion) = '') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El motivo 01 requiere el UUID de sustitucion';
    END IF;
    START TRANSACTION;
    SELECT estado, uuid INTO v_estado, v_uuid FROM factura
      WHERE id_factura = p_idFactura FOR UPDATE;
    IF v_estado IS NULL OR v_estado <> 'vigente' OR v_uuid IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se solicita cancelar una factura vigente y timbrada';
    END IF;
    UPDATE factura SET estado = 'cancelacion solicitada',
      motivo_cancelacion = p_motivo,
      uuid_sustitucion = IF(p_motivo = '01', p_uuidSustitucion, NULL)
      WHERE id_factura = p_idFactura;
    COMMIT;
END$$

CREATE PROCEDURE sp_cancelarFactura (IN p_idFactura INT)
BEGIN
    UPDATE factura SET estado = 'cancelada', fecha_cancelacion = CURRENT_TIMESTAMP
      WHERE id_factura = p_idFactura AND estado = 'cancelacion solicitada';
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Primero debe solicitarse la cancelacion';
    END IF;
END$$

CREATE PROCEDURE sp_consultarFacturas (IN p_mes INT, IN p_anio INT)
BEGIN
    SELECT f.id_factura, f.serie, f.folio, f.fecha_emision, f.tipo, f.rfc_receptor,
           CONCAT(c.nombres, ' ', COALESCE(c.apellidos, '')) AS cliente,
           f.subtotal, f.descuento, f.impuestos, f.total, f.estado, f.uuid
      FROM factura f JOIN cliente c ON c.id_cliente = f.id_cliente
      WHERE MONTH(f.fecha_emision) = p_mes AND YEAR(f.fecha_emision) = p_anio
      ORDER BY f.fecha_emision, f.folio;
END$$

DELIMITER ;

CREATE OR REPLACE VIEW v_renglones_cobrados AS
SELECT v.id_venta, DATE(v.fecha_hora_pago) AS fecha, v.id_caja, v.id_usuario, v.id_cliente,
       d.id_departamento, d.importe,
       d.importe / (1 + d.tasa_iva / 100) AS base,
       d.importe - d.importe / (1 + d.tasa_iva / 100) AS iva,
       d.importe / (1 + d.tasa_iva / 100) - d.cantidad * d.costo_unitario AS ganancia
FROM venta v
JOIN detalle_venta d ON d.id_venta = v.id_venta
WHERE v.estado = 'PAGO_COMPLETADO';

CREATE OR REPLACE VIEW v_devoluciones_dia AS
SELECT DATE(dv.fecha_hora) AS fecha, v.id_caja,
       SUM(dv.monto) AS devoluciones,
       SUM(dv.monto - dv.costo_devuelto) AS utilidad_devuelta
FROM devolucion dv JOIN venta v ON v.id_venta = dv.id_venta
GROUP BY DATE(dv.fecha_hora), v.id_caja;

CREATE OR REPLACE VIEW v_reporte_ventas_dia AS
SELECT r.fecha, r.id_caja,
       SUM(r.importe) - COALESCE(MAX(d.devoluciones), 0) AS ventas_totales,
       SUM(r.ganancia) - COALESCE(MAX(d.utilidad_devuelta), 0) AS ganancia,
       COUNT(DISTINCT r.id_venta) AS num_ventas
FROM v_renglones_cobrados r
LEFT JOIN v_devoluciones_dia d ON d.fecha = r.fecha AND d.id_caja = r.id_caja
GROUP BY r.fecha, r.id_caja;

CREATE OR REPLACE VIEW v_ventas_por_cajero AS
SELECT r.fecha, r.id_caja, r.id_usuario, u.nombre AS cajero,
       SUM(r.importe) AS ventas, SUM(r.ganancia) AS ganancia
FROM v_renglones_cobrados r JOIN usuario u ON u.id_usuario = r.id_usuario
GROUP BY r.fecha, r.id_caja, r.id_usuario, u.nombre;

CREATE OR REPLACE VIEW v_ventas_por_departamento AS
SELECT r.fecha, r.id_caja, r.id_departamento, dp.nombre AS departamento,
       SUM(r.importe) AS ventas, SUM(r.ganancia) AS ganancia
FROM v_renglones_cobrados r JOIN departamento dp ON dp.id_departamento = r.id_departamento
GROUP BY r.fecha, r.id_caja, r.id_departamento, dp.nombre;

CREATE OR REPLACE VIEW v_ventas_por_cliente AS
SELECT c.folio AS Folio, CONCAT(c.nombres, ' ', COALESCE(c.apellidos, '')) AS Nombre,
       COUNT(DISTINCT r.id_venta) AS numero_ventas,
       SUM(r.importe) AS acumulado_ventas,
       SUM(r.ganancia) AS acumulado_ganancias
FROM v_renglones_cobrados r JOIN cliente c ON c.id_cliente = r.id_cliente
GROUP BY c.id_cliente, c.folio, c.nombres, c.apellidos;

DELIMITER $$

CREATE PROCEDURE sp_reporte_ventas(IN p_desde DATE, IN p_hasta DATE, IN p_id_caja INT)
BEGIN
  IF p_desde > p_hasta OR p_hasta > CURRENT_DATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Intervalo de fechas inválido. Ingrese de nuevo';
  END IF;
  SELECT COALESCE(SUM(ventas_totales), 0) AS ventas_totales,
         COALESCE(SUM(ganancia), 0)       AS ganancia,
         COALESCE(SUM(num_ventas), 0)     AS num_ventas,
         IF(COALESCE(SUM(num_ventas), 0) = 0, 0, SUM(ventas_totales) / SUM(num_ventas)) AS ticket_promedio,
         COALESCE(SUM(num_ventas), 0) > 0 AS hay_ventas
  FROM v_reporte_ventas_dia
  WHERE fecha BETWEEN p_desde AND p_hasta
    AND (p_id_caja IS NULL OR id_caja = p_id_caja);
END$$

CREATE PROCEDURE sp_serie_ventas(IN p_desde DATE, IN p_hasta DATE, IN p_id_caja INT)
BEGIN
  SELECT fecha AS etiqueta, SUM(ventas_totales) AS importe
  FROM v_reporte_ventas_dia
  WHERE fecha BETWEEN p_desde AND p_hasta AND (p_id_caja IS NULL OR id_caja = p_id_caja)
  GROUP BY fecha ORDER BY fecha;
END$$

CREATE PROCEDURE sp_ventas_por_cajero(IN p_desde DATE, IN p_hasta DATE, IN p_id_caja INT)
BEGIN
  SELECT cajero, SUM(ventas) AS ventas, SUM(ganancia) AS ganancia
  FROM v_ventas_por_cajero
  WHERE fecha BETWEEN p_desde AND p_hasta AND (p_id_caja IS NULL OR id_caja = p_id_caja)
  GROUP BY id_usuario, cajero ORDER BY ventas DESC;
END$$

CREATE PROCEDURE sp_ventas_por_departamento(IN p_desde DATE, IN p_hasta DATE, IN p_id_caja INT)
BEGIN
  SELECT departamento, SUM(ventas) AS ventas, SUM(ganancia) AS ganancia,
         100 * SUM(ventas) / NULLIF(SUM(SUM(ventas)) OVER (), 0) AS porcentaje_total
  FROM v_ventas_por_departamento
  WHERE fecha BETWEEN p_desde AND p_hasta AND (p_id_caja IS NULL OR id_caja = p_id_caja)
  GROUP BY id_departamento, departamento ORDER BY ventas DESC;
END$$

CREATE PROCEDURE sp_registrar_exportacion(IN p_id_usuario INT, IN p_formato VARCHAR(4), IN p_registros INT)
BEGIN
  DECLARE v_rol VARCHAR(20);
  SELECT rol INTO v_rol FROM usuario WHERE id_usuario = p_id_usuario;
  IF v_rol <> 'ADMINISTRADOR' THEN
    INSERT INTO bitacora (id_usuario, fecha_hora, evento, reporte, detalle)
    VALUES (p_id_usuario, UTC_TIMESTAMP(), 'ACCESO_DENEGADO', 'ventas_por_cliente', 'Acceso denegado');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Acceso denegado';
  END IF;
  INSERT INTO bitacora (id_usuario, fecha_hora, evento, reporte, formato_export, registros_exportados, nombre_archivo)
  VALUES (p_id_usuario, UTC_TIMESTAMP(), 'EXPORTACION', 'ventas_por_cliente', p_formato, p_registros,
          CONCAT('abarrotec_ventas_por_cliente_', DATE_FORMAT(CURRENT_DATE(), '%Y-%m-%d')));
END$$

DELIMITER ;
