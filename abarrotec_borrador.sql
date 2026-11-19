-- Abarrotec - BORRADOR v0.2 (Ventas, Compras + Configuración, Clientes, Facturación) - MySQL 8.0
-- Agrega al v0.1 lo del PDF MODULOS_CONFIGURACION_FACTURA_CLIENTE.
-- ATENCIÓN: borra y vuelve a crear la base "abarrotec" (es borrador).
-- Convención: snake_case, tablas en singular, PK = id_<tabla>, FK = id_<tabla_referida>.
DROP DATABASE IF EXISTS abarrotec;
CREATE DATABASE abarrotec CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE abarrotec;

-- ===== USUARIOS Y CAJAS (clase Cajero y Caja) =====
CREATE TABLE usuario (            -- = clase Cajero (+ rol de administrador)
  id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(100) NOT NULL,      -- nombreCompleto
  usuario         VARCHAR(50)  NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL,
  rol             ENUM('ADMINISTRADOR','CAJERO') NOT NULL,
  activo          BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE permiso_usuario (    -- permisos del cajero (1 a 1 con usuario)
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
  ultimo_acceso  DATE NULL
);

-- ===== CONFIGURACIÓN (clase Configuracion y sus 5 clases) =====
CREATE TABLE configuracion (      -- una sola fila
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
  unidades_habilitadas   VARCHAR(100) NOT NULL DEFAULT 'PZA',  -- PZA, KG/G, L/ML, M/CM, H/MIN, NO APLICA
  iva_tasa_default       DECIMAL(5,2) NOT NULL DEFAULT 16.00,  -- propuesta
  precios_incluyen_iva   BOOLEAN NOT NULL DEFAULT TRUE,        -- propuesta
  compras_habilitado     BOOLEAN NOT NULL DEFAULT TRUE,
  idioma_app             VARCHAR(10) NOT NULL DEFAULT 'es-MX', -- propuesta
  fecha_ultima_actualizacion DATETIME NULL,                    -- propuesta
  estado_sistema         BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE forma_pago (
  id_forma_pago  INT AUTO_INCREMENT PRIMARY KEY,
  id_configuracion INT NULL,
  nombre         VARCHAR(40) NOT NULL UNIQUE,   -- Efectivo, Dólares, Tarjeta, Transferencia, Cheque, Vales, Mixto
  habilitada     BOOLEAN NOT NULL DEFAULT TRUE,
  bloquear_si_efectivo_menor BOOLEAN NOT NULL DEFAULT FALSE,  -- solo Efectivo
  tipo_cambio    DECIMAL(10,4) NULL,                          -- solo Dólares
  cobrar_comision BOOLEAN NOT NULL DEFAULT FALSE,             -- solo Tarjeta
  comision_pct   DECIMAL(5,2) NOT NULL DEFAULT 0,             -- solo Tarjeta (POR CONFIRMAR)
  etiqueta_personalizada VARCHAR(50) NULL,                    -- solo Transferencia
  FOREIGN KEY (id_configuracion) REFERENCES configuracion(id_configuracion)
);

CREATE TABLE config_corte (
  id_configuracion INT PRIMARY KEY,
  modo_corte       ENUM('solicitar_y_ajustar','no_solicitar') NOT NULL DEFAULT 'solicitar_y_ajustar',
  limite_efectivo_accion  VARCHAR(50) NULL,     -- p. ej. ignorar entradas al superar el límite
  limite_efectivo_monto   DECIMAL(10,2) NULL,
  limite_efectivo_mensaje VARCHAR(255) NULL,
  FOREIGN KEY (id_configuracion) REFERENCES configuracion(id_configuracion)
);

CREATE TABLE config_ticket (
  id_configuracion INT PRIMARY KEY,
  nombre_negocio_ticket VARCHAR(120) NULL,
  direccion_ticket      VARCHAR(200) NULL,
  telefono_ticket       VARCHAR(20)  NULL,
  rfc_ticket            VARCHAR(13)  NULL,
  mensaje_final         VARCHAR(255) NULL,
  logo_ruta             VARCHAR(255) NULL,      -- 300 a 600 px x 63 px
  lineas_arriba         INT NOT NULL DEFAULT 0,
  lineas_abajo          INT NOT NULL DEFAULT 0,
  incluir_precio_unitario BOOLEAN NOT NULL DEFAULT TRUE,
  descripcion_completa  BOOLEAN NOT NULL DEFAULT FALSE,
  imprimir_datos_cliente BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (id_configuracion) REFERENCES configuracion(id_configuracion)
);

CREATE TABLE config_facturacion (
  id_configuracion INT PRIMARY KEY,
  rfc_emisor            VARCHAR(13)  NULL,
  razon_social_emisor   VARCHAR(150) NULL,
  regimen_fiscal_emisor VARCHAR(5)   NULL,
  codigo_postal_expedicion VARCHAR(5) NULL,
  certificado_cer_ruta  VARCHAR(255) NULL,      -- archivo .CER
  llave_key_ruta        VARCHAR(255) NULL,      -- archivo .KEY
  llave_password        VARCHAR(255) NULL,      -- guardar CIFRADA
  serie_default         VARCHAR(10)  NULL,
  folio_actual          INT NOT NULL DEFAULT 1,
  FOREIGN KEY (id_configuracion) REFERENCES configuracion(id_configuracion)
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
  FOREIGN KEY (id_configuracion) REFERENCES configuracion(id_configuracion)
);

CREATE TABLE config_servicios (
  id_configuracion INT PRIMARY KEY,
  compras_nombre_negocio  VARCHAR(120) NULL,
  compras_datos_contacto  VARCHAR(255) NULL,
  compras_correo_envio    VARCHAR(150) NULL,    -- Gmail con OAuth (no guardar contraseña)
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
  nube_estado_cuenta      VARCHAR(30) NULL,     -- prueba / licencia
  nube_ultima_sync        DATETIME NULL,
  notificaciones_correo_activas BOOLEAN NOT NULL DEFAULT FALSE,
  respaldo_ruta           VARCHAR(255) NULL,
  respaldo_auto_al_salir  BOOLEAN NOT NULL DEFAULT FALSE,
  respaldo_dias_retencion INT NULL,
  actualizaciones_buscar_al VARCHAR(30) NULL,
  licencia_estado         VARCHAR(50) NULL,
  FOREIGN KEY (id_configuracion) REFERENCES configuracion(id_configuracion)
);

-- ===== CATÁLOGOS (v0.1) =====
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

-- ===== CLIENTES (módulo de Clientes) =====
CREATE TABLE cliente (
  id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
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
  fecha_registro  DATE NOT NULL DEFAULT (CURRENT_DATE),  -- propuesta
  activo          BOOLEAN NOT NULL DEFAULT TRUE          -- propuesta
);

CREATE TABLE cliente_facturacion (       -- 1 cliente : 0..1 datos fiscales
  id_cliente_facturacion INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente      INT NOT NULL UNIQUE,
  rfc             VARCHAR(13) NOT NULL,
  razon_social    VARCHAR(150) NOT NULL,
  regimen_fiscal  VARCHAR(5)  NOT NULL,   -- clave SAT
  uso_cfdi        VARCHAR(5)  NOT NULL,   -- clave SAT
  codigo_postal_fiscal VARCHAR(5) NOT NULL,
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

-- ===== VENTAS =====
CREATE TABLE venta (
  id_venta     INT AUTO_INCREMENT PRIMARY KEY,
  folio        INT NOT NULL UNIQUE,          -- número de ticket consecutivo
  fecha_hora   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario   INT NOT NULL,                 -- cajero
  id_caja      INT NULL,
  id_cliente   INT NULL,                     -- asignarClienteAVenta (crédito / factura)
  tipo_venta   ENUM('MENUDEO','MAYOREO') NOT NULL DEFAULT 'MENUDEO',
  estado       ENUM('PENDIENTE','COBRADA','CANCELADA') NOT NULL DEFAULT 'PENDIENTE',
  total        DECIMAL(10,2) NOT NULL DEFAULT 0,
  notas        VARCHAR(255),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  FOREIGN KEY (id_caja)    REFERENCES caja(id_caja),
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

CREATE TABLE detalle_venta (
  id_detalle_venta INT AUTO_INCREMENT PRIMARY KEY,
  id_venta     INT NOT NULL,
  id_producto  INT NOT NULL,
  cantidad     DECIMAL(10,3) NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  importe      DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (id_venta)    REFERENCES venta(id_venta),
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

CREATE TABLE pago_venta (
  id_pago_venta INT AUTO_INCREMENT PRIMARY KEY,
  id_venta      INT NOT NULL,
  id_forma_pago INT NOT NULL,
  monto         DECIMAL(10,2) NOT NULL,
  comision      DECIMAL(10,2) NOT NULL DEFAULT 0,
  referencia    VARCHAR(50) NULL,            -- número de aprobación (tarjeta); NO se guarda número de tarjeta
  FOREIGN KEY (id_venta)      REFERENCES venta(id_venta),
  FOREIGN KEY (id_forma_pago) REFERENCES forma_pago(id_forma_pago)
);

CREATE TABLE abono (
  id_abono      INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente    INT NOT NULL,
  fecha_abono   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  monto         DECIMAL(10,2) NOT NULL,
  id_forma_pago INT NOT NULL,                -- en el PDF es texto (formaPago); aquí FK
  id_usuario    INT NOT NULL,                -- idCajero
  id_caja       INT NULL,
  saldo_anterior DECIMAL(10,2) NOT NULL,
  saldo_nuevo   DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (id_cliente)    REFERENCES cliente(id_cliente),
  FOREIGN KEY (id_forma_pago) REFERENCES forma_pago(id_forma_pago),
  FOREIGN KEY (id_usuario)    REFERENCES usuario(id_usuario),
  FOREIGN KEY (id_caja)       REFERENCES caja(id_caja)
);

-- ===== FACTURACIÓN =====
CREATE TABLE factura (
  id_factura    INT AUTO_INCREMENT PRIMARY KEY,
  serie         VARCHAR(10) NULL,
  folio         INT NOT NULL,
  id_cliente    INT NOT NULL,
  id_venta      INT NULL,                    -- vacío en la factura global
  tipo          ENUM('por_venta','global') NOT NULL DEFAULT 'por_venta',
  fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  rfc_emisor    VARCHAR(13) NOT NULL,
  rfc_receptor  VARCHAR(13) NOT NULL,        -- dato congelado al emitir
  uso_cfdi      VARCHAR(5)  NOT NULL,
  forma_pago    VARCHAR(5)  NOT NULL,        -- clave SAT
  metodo_pago   ENUM('PUE','PPD') NOT NULL,
  moneda        VARCHAR(5)  NOT NULL DEFAULT 'MXN',
  subtotal      DECIMAL(12,2) NOT NULL,
  descuento     DECIMAL(12,2) NOT NULL DEFAULT 0,
  impuestos     DECIMAL(12,2) NOT NULL DEFAULT 0,
  total         DECIMAL(12,2) NOT NULL,
  estado        ENUM('vigente','cancelacion solicitada','cancelada') NOT NULL DEFAULT 'vigente',
  fecha_cancelacion  DATETIME NULL,          -- propuesta
  motivo_cancelacion VARCHAR(2) NULL,        -- clave SAT 01 a 04 (propuesta)
  uuid_sustitucion   VARCHAR(36) NULL,       -- solo motivo 01 (propuesta)
  uuid          VARCHAR(36) NULL UNIQUE,     -- folio fiscal del timbrado
  fecha_timbrado DATETIME NULL,
  xml_ruta      VARCHAR(255) NULL,
  pdf_ruta      VARCHAR(255) NULL,
  UNIQUE (serie, folio),
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
  FOREIGN KEY (id_venta)   REFERENCES venta(id_venta)
);

CREATE TABLE factura_detalle (               -- factura 1 : 1..* detalle
  id_factura_detalle INT AUTO_INCREMENT PRIMARY KEY,
  id_factura       INT NOT NULL,
  codigo_barras    VARCHAR(50) NULL,
  clave_prod_serv  VARCHAR(10) NOT NULL,     -- clave SAT
  clave_unidad     VARCHAR(5)  NOT NULL,     -- clave SAT
  descripcion      VARCHAR(200) NOT NULL,
  cantidad         DECIMAL(10,3) NOT NULL,
  valor_unitario   DECIMAL(12,2) NOT NULL,
  importe          DECIMAL(12,2) NOT NULL,
  objeto_impuesto  ENUM('01','02','03') NOT NULL,
  tasa_iva         DECIMAL(5,2) NOT NULL DEFAULT 16.00,
  FOREIGN KEY (id_factura) REFERENCES factura(id_factura)
);

-- ===== COMPRAS =====
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

-- Pago de compra (sub-caso tarjeta en Compras: POR CONFIRMAR, Eleventa no lo tiene)
CREATE TABLE pago_compra (
  id_pago_compra  INT AUTO_INCREMENT PRIMARY KEY,
  id_orden_compra INT NOT NULL,
  id_forma_pago   INT NOT NULL,
  monto           DECIMAL(10,2) NOT NULL,
  referencia      VARCHAR(50) NULL,
  FOREIGN KEY (id_orden_compra) REFERENCES orden_compra(id_orden_compra),
  FOREIGN KEY (id_forma_pago)   REFERENCES forma_pago(id_forma_pago)
);

-- ===== DATOS INICIALES =====
INSERT INTO configuracion (nombre_negocio) VALUES ('Mi negocio');
INSERT INTO forma_pago (id_configuracion, nombre, habilitada) VALUES
 (1,'EFECTIVO',TRUE),(1,'DOLARES',FALSE),(1,'TARJETA',TRUE),(1,'TRANSFERENCIA',FALSE),
 (1,'CHEQUE',FALSE),(1,'VALES',FALSE),(1,'CREDITO',TRUE),(1,'MIXTO',TRUE);
INSERT INTO caja (nombre_caja) VALUES ('Caja 1');