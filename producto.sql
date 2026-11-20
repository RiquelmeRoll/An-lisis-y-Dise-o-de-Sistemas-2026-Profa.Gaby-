-- base de datos de productos
CREATE DATABASE IF NOT EXISTS pos_modulo_producto
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pos_modulo_producto;

SET FOREIGN_KEY_CHECKS = 0;

-- sucursales y usuarios
CREATE TABLE IF NOT EXISTS sucursal (
    id_sucursal INT NOT NULL AUTO_INCREMENT,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255) NULL,
    telefono VARCHAR(20) NULL,
    es_matriz TINYINT(1) NOT NULL DEFAULT 0,
    activa TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_sucursal),
    UNIQUE KEY uq_sucursal_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario INT NOT NULL AUTO_INCREMENT,
    id_sucursal_principal INT NULL,
    nombre VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    pin_autorizacion_hash VARCHAR(255) NULL,
    rol ENUM('ADMIN', 'GERENTE', 'CAJERO', 'ALMACENISTA', 'COBRANZA') NOT NULL DEFAULT 'CAJERO',
    activo TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario),
    UNIQUE KEY uq_usuario_login (usuario),
    KEY idx_usuario_sucursal (id_sucursal_principal),
    CONSTRAINT fk_usuario_sucursal
        FOREIGN KEY (id_sucursal_principal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- catalogos
CREATE TABLE IF NOT EXISTS departamento (
    id_departamento INT NOT NULL AUTO_INCREMENT,
    id_departamento_padre INT NULL,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    descripcion VARCHAR(255) NULL,
    margen_utilidad_sugerido DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    color_hex VARCHAR(7) NULL DEFAULT '#3B82F6',
    restringir_credito TINYINT(1) NOT NULL DEFAULT 0,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_departamento),
    UNIQUE KEY uq_departamento_codigo (codigo),
    KEY idx_departamento_padre (id_departamento_padre),
    CONSTRAINT fk_departamento_padre
        FOREIGN KEY (id_departamento_padre) REFERENCES departamento (id_departamento)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS marca (
    id_marca INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_marca),
    UNIQUE KEY uq_marca_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS unidad_medida (
    id_unidad INT NOT NULL AUTO_INCREMENT,
    clave_sat VARCHAR(10) NULL,
    codigo VARCHAR(15) NOT NULL,
    nombre VARCHAR(60) NOT NULL,
    permite_decimales TINYINT(1) NOT NULL DEFAULT 0,
    es_unidad_base TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_unidad),
    UNIQUE KEY uq_unidad_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS lista_precio (
    id_lista_precio INT NOT NULL AUTO_INCREMENT,
    id_sucursal INT NULL,
    nombre VARCHAR(80) NOT NULL,
    tipo ENUM('GENERAL', 'MAYOREO', 'ESPECIAL', 'PROMOCION', 'CREDITO') NOT NULL DEFAULT 'GENERAL',
    prioridad SMALLINT NOT NULL DEFAULT 1,
    fecha_inicio TIMESTAMP NULL,
    fecha_fin TIMESTAMP NULL,
    activa TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_lista_precio),
    KEY idx_lista_precio_sucursal (id_sucursal),
    CONSTRAINT fk_lista_precio_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- productos y precios
CREATE TABLE IF NOT EXISTS producto (
    id_producto INT NOT NULL AUTO_INCREMENT,
    id_departamento INT NOT NULL,
    id_marca INT NULL,
    id_unidad_venta INT NOT NULL,
    id_unidad_compra INT NOT NULL,
    codigo_barras VARCHAR(50) NULL,
    sku VARCHAR(50) NOT NULL,
    clave_sat VARCHAR(15) NULL,
    nombre VARCHAR(180) NOT NULL,
    nombre_corto_ticket VARCHAR(40) NULL,
    descripcion VARCHAR(150) NULL,
    tipo_venta ENUM('UNIDAD', 'GRANEL', 'PAQUETE', 'SERVICIO') NOT NULL DEFAULT 'UNIDAD',
    precio_costo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    costo_promedio DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    porcentaje_ganancia DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    precio_mayoreo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    usa_inventario TINYINT(1) NOT NULL DEFAULT 1,
    existencia DECIMAL(10,3) NOT NULL DEFAULT 0.000,
    minimo DECIMAL(10,3) NOT NULL DEFAULT 0.000,
    maximo DECIMAL(10,3) NOT NULL DEFAULT 0.000,
    maneja_lotes TINYINT(1) NOT NULL DEFAULT 0,
    maneja_caducidad TINYINT(1) NOT NULL DEFAULT 0,
    metodo_salida ENUM('PEPS', 'UEPS', 'PROMEDIO', 'FEFO') NOT NULL DEFAULT 'PEPS',
    metodo_costeo ENUM('ULTIMO_COSTO', 'COSTO_PROMEDIO', 'PEPS') NOT NULL DEFAULT 'COSTO_PROMEDIO',
    factor_conversion_compra DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
    precio_incluye_impuestos TINYINT(1) NOT NULL DEFAULT 1,
    permite_descuento TINYINT(1) NOT NULL DEFAULT 1,
    porcentaje_descuento_max DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    es_favorito_pos TINYINT(1) NOT NULL DEFAULT 0,
    imagen_url VARCHAR(500) NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    PRIMARY KEY (id_producto),
    UNIQUE KEY uq_producto_sku (sku),
    KEY idx_producto_codigo_barras (codigo_barras),
    KEY idx_producto_nombre (nombre),
    KEY idx_producto_departamento (id_departamento),
    KEY idx_producto_marca (id_marca),
    CONSTRAINT fk_producto_departamento
        FOREIGN KEY (id_departamento) REFERENCES departamento (id_departamento)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_producto_marca
        FOREIGN KEY (id_marca) REFERENCES marca (id_marca)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_producto_unidad_venta
        FOREIGN KEY (id_unidad_venta) REFERENCES unidad_medida (id_unidad)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_producto_unidad_compra
        FOREIGN KEY (id_unidad_compra) REFERENCES unidad_medida (id_unidad)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS presentacion_producto (
    id_presentacion BIGINT NOT NULL AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_unidad INT NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    factor_unidades_base DECIMAL(12,4) NOT NULL DEFAULT 1.0000,
    precio_venta DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    activa TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_presentacion),
    KEY idx_presentacion_producto (id_producto),
    CONSTRAINT fk_presentacion_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_presentacion_unidad
        FOREIGN KEY (id_unidad) REFERENCES unidad_medida (id_unidad)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS codigo_barras_producto (
    id_codigo_barras BIGINT NOT NULL AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_presentacion BIGINT NULL,
    codigo VARCHAR(60) NOT NULL,
    tipo ENUM('EAN13', 'EAN8', 'UPC', 'CODE128', 'INTERNO') NOT NULL DEFAULT 'EAN13',
    es_principal TINYINT(1) NOT NULL DEFAULT 0,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_codigo_barras),
    UNIQUE KEY uq_codigo_barras_valor (codigo),
    KEY idx_cb_producto (id_producto),
    KEY idx_cb_presentacion (id_presentacion),
    CONSTRAINT fk_cb_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cb_presentacion
        FOREIGN KEY (id_presentacion) REFERENCES presentacion_producto (id_presentacion)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_precio_escala (
    id_precio_escala BIGINT NOT NULL AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_lista_precio INT NOT NULL,
    cantidad_minima DECIMAL(12,3) NOT NULL DEFAULT 1.000,
    cantidad_maxima DECIMAL(12,3) NULL,
    precio_unitario DECIMAL(12,4) NOT NULL,
    margen_porcentaje DECIMAL(5,2) NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_precio_escala),
    KEY idx_escala_producto (id_producto),
    KEY idx_escala_lista (id_lista_precio),
    CONSTRAINT fk_escala_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_escala_lista_precio
        FOREIGN KEY (id_lista_precio) REFERENCES lista_precio (id_lista_precio)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- impuestos, kits e historial
CREATE TABLE IF NOT EXISTS impuesto (
    id_impuesto INT NOT NULL AUTO_INCREMENT,
    codigo VARCHAR(15) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    clave_sat VARCHAR(10) NULL,
    tipo ENUM('TRASLADO', 'RETENCION') NOT NULL DEFAULT 'TRASLADO',
    base_calculo ENUM('SUBTOTAL', 'IMPORTE_CON_IEPS', 'CUOTA_FIJA') NOT NULL DEFAULT 'SUBTOTAL',
    tasa_o_cuota DECIMAL(10,6) NOT NULL DEFAULT 0.160000,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_impuesto),
    UNIQUE KEY uq_impuesto_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_impuesto (
    id_producto_impuesto BIGINT NOT NULL AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_impuesto INT NOT NULL,
    orden_aplicacion SMALLINT NOT NULL DEFAULT 1,
    aplica_en_venta TINYINT(1) NOT NULL DEFAULT 1,
    aplica_en_compra TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_producto_impuesto),
    UNIQUE KEY uq_producto_impuesto (id_producto, id_impuesto),
    CONSTRAINT fk_pi_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pi_impuesto
        FOREIGN KEY (id_impuesto) REFERENCES impuesto (id_impuesto)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_kit_componente (
    id_kit BIGINT NOT NULL AUTO_INCREMENT,
    id_producto_padre INT NOT NULL,
    id_producto_componente INT NOT NULL,
    cantidad_componente DECIMAL(12,3) NOT NULL DEFAULT 1.000,
    descontar_inventario_componente TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_kit),
    UNIQUE KEY uq_kit_padre_componente (id_producto_padre, id_producto_componente),
    CONSTRAINT fk_kit_padre
        FOREIGN KEY (id_producto_padre) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_kit_componente
        FOREIGN KEY (id_producto_componente) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS historial_precio_costo (
    id_historial_precio BIGINT NOT NULL AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_usuario INT NOT NULL,
    costo_anterior DECIMAL(12,4) NOT NULL,
    costo_nuevo DECIMAL(12,4) NOT NULL,
    precio_anterior DECIMAL(12,4) NOT NULL,
    precio_nuevo DECIMAL(12,4) NOT NULL,
    motivo VARCHAR(200) NULL,
    fecha_cambio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_historial_precio),
    KEY idx_historial_precio_producto (id_producto),
    CONSTRAINT fk_hpc_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_hpc_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- proveedores, clientes, ventas y compras
CREATE TABLE IF NOT EXISTS proveedor (
    id_proveedor INT NOT NULL AUTO_INCREMENT,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    razon_social VARCHAR(150) NULL,
    rfc VARCHAR(20) NULL,
    representante VARCHAR(100) NULL,
    telefonos VARCHAR(100) NULL,
    correos VARCHAR(150) NULL,
    pagina_web VARCHAR(150) NULL,
    comentarios TEXT NULL,
    dias_credito SMALLINT NOT NULL DEFAULT 0,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_proveedor),
    UNIQUE KEY uq_proveedor_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto_proveedor (
    id_producto INT NOT NULL,
    id_proveedor INT NOT NULL,
    codigo_proveedor VARCHAR(50) NULL,
    ultimo_costo DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    tiempo_entrega_dias SMALLINT NOT NULL DEFAULT 1,
    es_principal TINYINT(1) NOT NULL DEFAULT 0,
    fecha_ultima_compra DATE NULL,
    PRIMARY KEY (id_producto, id_proveedor),
    CONSTRAINT fk_pp_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pp_proveedor
        FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cliente (
    id_cliente BIGINT NOT NULL AUTO_INCREMENT,
    id_lista_precio_asignada INT NULL,
    codigo VARCHAR(30) NOT NULL,
    tipo ENUM('FISICA', 'MORAL', 'PUBLICO_GENERAL') NOT NULL DEFAULT 'FISICA',
    nombre_completo VARCHAR(160) NOT NULL,
    rfc VARCHAR(20) NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_cliente),
    UNIQUE KEY uq_cliente_codigo (codigo),
    CONSTRAINT fk_cliente_lista_precio
        FOREIGN KEY (id_lista_precio_asignada) REFERENCES lista_precio (id_lista_precio)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS venta (
    id_venta INT NOT NULL AUTO_INCREMENT,
    id_sucursal INT NULL,
    id_cliente BIGINT NULL,
    id_usuario INT NOT NULL,
    folio INT NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo_venta ENUM('CONTADO', 'CREDITO', 'APARTADO') NOT NULL DEFAULT 'CONTADO',
    estado ENUM('COMPLETADA', 'PENDIENTE', 'CANCELADA') NOT NULL DEFAULT 'COMPLETADA',
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    es_credito TINYINT(1) NOT NULL DEFAULT 0,
    notas VARCHAR(255) NULL,
    PRIMARY KEY (id_venta),
    UNIQUE KEY uq_venta_folio (folio),
    CONSTRAINT fk_venta_sucursal_prod
        FOREIGN KEY (id_sucursal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_venta_cliente_prod
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_venta_usuario_prod
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS detalle_venta (
    id_detalle_venta INT NOT NULL AUTO_INCREMENT,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    id_presentacion BIGINT NULL,
    cantidad DECIMAL(10,3) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    importe DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_detalle_venta),
    KEY idx_dv_venta (id_venta),
    KEY idx_dv_producto (id_producto),
    CONSTRAINT fk_dv_venta
        FOREIGN KEY (id_venta) REFERENCES venta (id_venta)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_dv_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_dv_presentacion
        FOREIGN KEY (id_presentacion) REFERENCES presentacion_producto (id_presentacion)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orden_compra (
    id_orden_compra INT NOT NULL AUTO_INCREMENT,
    id_sucursal INT NULL,
    numero INT NOT NULL,
    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    estado ENUM('BORRADOR', 'ENVIADA', 'RECIBIDA', 'CANCELADA') NOT NULL DEFAULT 'BORRADOR',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_recepcion DATETIME NULL,
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (id_orden_compra),
    CONSTRAINT fk_oc_sucursal_prod
        FOREIGN KEY (id_sucursal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_oc_proveedor_prod
        FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_oc_usuario_prod
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS detalle_orden_compra (
    id_detalle_orden_compra INT NOT NULL AUTO_INCREMENT,
    id_orden_compra INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,3) NOT NULL,
    precio_compra DECIMAL(10,2) NOT NULL,
    importe DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_detalle_orden_compra),
    KEY idx_doc_orden (id_orden_compra),
    KEY idx_doc_producto (id_producto),
    CONSTRAINT fk_doc_orden_compra
        FOREIGN KEY (id_orden_compra) REFERENCES orden_compra (id_orden_compra)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_doc_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;