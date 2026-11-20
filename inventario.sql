
CREATE DATABASE IF NOT EXISTS abarrotec_inventario
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE abarrotec_inventario;

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS sucursal (
    suc_id INT NOT NULL AUTO_INCREMENT,
    suc_codigo VARCHAR(20) NOT NULL,
    suc_nombre VARCHAR(100) NOT NULL,
    suc_direccion VARCHAR(255) NULL,
    suc_activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (suc_id),
    UNIQUE KEY uk_suc_codigo (suc_codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS almacen (
    alm_id INT NOT NULL AUTO_INCREMENT,
    suc_id INT NOT NULL,
    alm_codigo VARCHAR(20) NOT NULL,
    alm_nombre VARCHAR(100) NOT NULL,
    alm_permite_venta_pos TINYINT(1) NOT NULL DEFAULT 1,
    alm_activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (alm_id),
    UNIQUE KEY uk_alm_codigo (alm_codigo),
    KEY idx_alm_sucursal (suc_id),
    CONSTRAINT fk_almacen_sucursal
        FOREIGN KEY (suc_id) REFERENCES sucursal (suc_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proveedor (
    prv_id INT NOT NULL AUTO_INCREMENT,
    prv_razon_social VARCHAR(150) NOT NULL,
    prv_nombre_comercial VARCHAR(150) NULL,
    prv_telefono VARCHAR(20) NULL,
    prv_activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (prv_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS usuario (
    usu_id INT NOT NULL AUTO_INCREMENT,
    suc_id INT NOT NULL,
    usu_username VARCHAR(50) NOT NULL,
    usu_nombre_completo VARCHAR(120) NOT NULL,
    usu_rol ENUM('ADMINISTRADOR', 'ENCARGADO', 'EMPLEADO') NOT NULL DEFAULT 'EMPLEADO',
    usu_activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (usu_id),
    UNIQUE KEY uk_usu_username (usu_username),
    KEY idx_usu_sucursal (suc_id),
    CONSTRAINT fk_usuario_sucursal
        FOREIGN KEY (suc_id) REFERENCES sucursal (suc_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS departamento (
    dep_id INT NOT NULL AUTO_INCREMENT,
    dep_nombre VARCHAR(100) NOT NULL,
    dep_activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (dep_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS producto (
    pro_id BIGINT NOT NULL AUTO_INCREMENT,
    dep_id INT NOT NULL,
    pro_sku VARCHAR(40) NOT NULL,
    pro_nombre VARCHAR(150) NOT NULL,
    pro_tipo_venta ENUM('UNIDAD', 'GRANEL', 'KIT') NOT NULL DEFAULT 'UNIDAD',
    pro_es_inventariable TINYINT(1) NOT NULL DEFAULT 1,
    pro_maneja_lotes TINYINT(1) NOT NULL DEFAULT 0,
    pro_maneja_caducidad TINYINT(1) NOT NULL DEFAULT 0,
    pro_costo DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    pro_precio_venta DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    pro_precio_mayoreo DECIMAL(12,4) NULL,
    pro_activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (pro_id),
    UNIQUE KEY uk_pro_sku (pro_sku),
    KEY idx_pro_departamento (dep_id),
    CONSTRAINT fk_producto_departamento
        FOREIGN KEY (dep_id) REFERENCES departamento (dep_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- nucleo del modulo de inventario
CREATE TABLE IF NOT EXISTS inventario_stock (
    inv_id BIGINT NOT NULL AUTO_INCREMENT,
    pro_id BIGINT NOT NULL,
    alm_id INT NOT NULL,
    inv_cantidad_existencia DECIMAL(12,3) NOT NULL DEFAULT 0.000,
    inv_min DECIMAL(12,3) NOT NULL DEFAULT 0.000,
    inv_max DECIMAL(12,3) NOT NULL DEFAULT 0.000,
    inv_costo_promedio DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    inv_fecha_ultimo_movimiento TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (inv_id),
    UNIQUE KEY uk_inv_producto_almacen (pro_id, alm_id),
    KEY idx_inv_almacen (alm_id),
    CONSTRAINT fk_inv_producto
        FOREIGN KEY (pro_id) REFERENCES producto (pro_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inv_almacen
        FOREIGN KEY (alm_id) REFERENCES almacen (alm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_inv_no_negativo CHECK (inv_cantidad_existencia >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS lote_inventario (
    lot_id BIGINT NOT NULL AUTO_INCREMENT,
    inv_id BIGINT NOT NULL,
    pro_id BIGINT NOT NULL,
    alm_id INT NOT NULL,
    prv_id INT NULL,
    lot_codigo VARCHAR(60) NOT NULL,
    lot_fecha_ingreso DATE NOT NULL,
    lot_fecha_caducidad DATE NULL,
    lot_cantidad_inicial DECIMAL(12,3) NOT NULL,
    lot_cantidad_actual DECIMAL(12,3) NOT NULL,
    lot_costo_unitario DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    lot_estado ENUM('ACTIVO', 'AGOTADO', 'CADUCADO', 'BLOQUEADO') NOT NULL DEFAULT 'ACTIVO',
    PRIMARY KEY (lot_id),
    UNIQUE KEY uk_lote_codigo_almacen (pro_id, alm_id, lot_codigo),
    KEY idx_lote_inv (inv_id),
    KEY idx_lote_almacen (alm_id),
    KEY idx_lote_proveedor (prv_id),
    KEY idx_lote_peps_caducidad (pro_id, alm_id, lot_estado, lot_fecha_caducidad, lot_fecha_ingreso),
    CONSTRAINT fk_lote_inventariostock
        FOREIGN KEY (inv_id) REFERENCES inventario_stock (inv_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_lote_producto
        FOREIGN KEY (pro_id) REFERENCES producto (pro_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_lote_almacen
        FOREIGN KEY (alm_id) REFERENCES almacen (alm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_lote_proveedor
        FOREIGN KEY (prv_id) REFERENCES proveedor (prv_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_lote_no_negativo CHECK (lot_cantidad_actual >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS movimiento_inventario (
    mov_id BIGINT NOT NULL AUTO_INCREMENT,
    inv_id BIGINT NOT NULL,
    pro_id BIGINT NOT NULL,
    alm_id INT NOT NULL,
    lot_id BIGINT NULL,
    usu_id INT NOT NULL,
    mov_tipo ENUM(
        'ENTRADA_COMPRA',
        'SALIDA_VENTA',
        'AJUSTE_ENTRADA',
        'AJUSTE_SALIDA',
        'MERMA',
        'TRASPASO_ENTRADA',
        'TRASPASO_SALIDA',
        'CONTEO_FISICO'
    ) NOT NULL,
    mov_naturaleza ENUM('ENTRADA', 'SALIDA') NOT NULL,
    mov_cantidad DECIMAL(12,3) NOT NULL,
    mov_existencia_anterior DECIMAL(12,3) NOT NULL,
    mov_existencia_posterior DECIMAL(12,3) NOT NULL,
    mov_costo_unitario DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    mov_motivo VARCHAR(255) NULL,
    mov_referencia_tipo VARCHAR(40) NULL,
    mov_referencia_id BIGINT NULL,
    mov_fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (mov_id),
    KEY idx_mov_inv (inv_id),
    KEY idx_mov_almacen (alm_id),
    KEY idx_mov_lote (lot_id),
    KEY idx_mov_usuario (usu_id),
    KEY idx_mov_kardex_fecha (pro_id, alm_id, mov_fecha),
    CONSTRAINT fk_mov_inventariostock
        FOREIGN KEY (inv_id) REFERENCES inventario_stock (inv_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_mov_producto
        FOREIGN KEY (pro_id) REFERENCES producto (pro_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_mov_almacen
        FOREIGN KEY (alm_id) REFERENCES almacen (alm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_mov_lote
        FOREIGN KEY (lot_id) REFERENCES lote_inventario (lot_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_mov_usuario
        FOREIGN KEY (usu_id) REFERENCES usuario (usu_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS alerta_inventario (
    ale_id BIGINT NOT NULL AUTO_INCREMENT,
    inv_id BIGINT NOT NULL,
    lot_id BIGINT NULL,
    ale_tipo ENUM('STOCK_MINIMO', 'PROXIMO_CADUCAR', 'LOTE_CADUCADO') NOT NULL,
    ale_mensaje VARCHAR(255) NOT NULL,
    ale_atendida TINYINT(1) NOT NULL DEFAULT 0,
    ale_fecha_generacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ale_id),
    KEY idx_ale_inv (inv_id),
    KEY idx_ale_lote (lot_id),
    CONSTRAINT fk_alerta_inventariostock
        FOREIGN KEY (inv_id) REFERENCES inventario_stock (inv_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_alerta_lote
        FOREIGN KEY (lot_id) REFERENCES lote_inventario (lot_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ajuste_merma_inventario (
    aju_id BIGINT NOT NULL AUTO_INCREMENT,
    alm_id INT NOT NULL,
    usu_id_solicita INT NOT NULL,
    usu_id_autoriza INT NULL,
    aju_folio VARCHAR(30) NOT NULL,
    aju_tipo ENUM('ENTRADA_MANUAL', 'SALIDA_MANUAL', 'MERMA') NOT NULL,
    aju_motivo VARCHAR(255) NOT NULL,
    aju_estado ENUM('PENDIENTE', 'AUTORIZADO', 'CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
    aju_fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (aju_id),
    UNIQUE KEY uk_aju_folio (aju_folio),
    KEY idx_aju_almacen (alm_id),
    KEY idx_aju_usu_solicita (usu_id_solicita),
    KEY idx_aju_usu_autoriza (usu_id_autoriza),
    CONSTRAINT fk_ajuste_almacen
        FOREIGN KEY (alm_id) REFERENCES almacen (alm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ajuste_usu_solicita
        FOREIGN KEY (usu_id_solicita) REFERENCES usuario (usu_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ajuste_usu_autoriza
        FOREIGN KEY (usu_id_autoriza) REFERENCES usuario (usu_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS detalle_ajuste_merma (
    daj_id BIGINT NOT NULL AUTO_INCREMENT,
    aju_id BIGINT NOT NULL,
    pro_id BIGINT NOT NULL,
    lot_id BIGINT NULL,
    daj_cantidad DECIMAL(12,3) NOT NULL,
    daj_costo_unitario DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
    PRIMARY KEY (daj_id),
    KEY idx_daj_ajuste (aju_id),
    KEY idx_daj_producto (pro_id),
    KEY idx_daj_lote (lot_id),
    CONSTRAINT fk_det_ajuste
        FOREIGN KEY (aju_id) REFERENCES ajuste_merma_inventario (aju_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_det_ajuste_prod
        FOREIGN KEY (pro_id) REFERENCES producto (pro_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_det_ajuste_lote
        FOREIGN KEY (lot_id) REFERENCES lote_inventario (lot_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS traspaso_almacen (
    tra_id BIGINT NOT NULL AUTO_INCREMENT,
    alm_id_origen INT NOT NULL,
    alm_id_destino INT NOT NULL,
    usu_id_envia INT NOT NULL,
    usu_id_recibe INT NULL,
    tra_folio VARCHAR(30) NOT NULL,
    tra_estado ENUM('EN_TRANSITO', 'RECIBIDO', 'CANCELADO') NOT NULL DEFAULT 'EN_TRANSITO',
    tra_fecha_envio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tra_fecha_recepcion TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (tra_id),
    UNIQUE KEY uk_tra_folio (tra_folio),
    KEY idx_tra_alm_origen (alm_id_origen),
    KEY idx_tra_alm_destino (alm_id_destino),
    KEY idx_tra_usu_envia (usu_id_envia),
    KEY idx_tra_usu_recibe (usu_id_recibe),
    CONSTRAINT fk_traspaso_alm_origen
        FOREIGN KEY (alm_id_origen) REFERENCES almacen (alm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_traspaso_alm_destino
        FOREIGN KEY (alm_id_destino) REFERENCES almacen (alm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_traspaso_usu_envia
        FOREIGN KEY (usu_id_envia) REFERENCES usuario (usu_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_traspaso_usu_recibe
        FOREIGN KEY (usu_id_recibe) REFERENCES usuario (usu_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_traspaso_almacenes_distintos CHECK (alm_id_origen <> alm_id_destino)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS detalle_traspaso (
    dtr_id BIGINT NOT NULL AUTO_INCREMENT,
    tra_id BIGINT NOT NULL,
    pro_id BIGINT NOT NULL,
    lot_id_origen BIGINT NULL,
    dtr_cantidad_enviada DECIMAL(12,3) NOT NULL,
    dtr_cantidad_recibida DECIMAL(12,3) NULL,
    PRIMARY KEY (dtr_id),
    KEY idx_dtr_traspaso (tra_id),
    KEY idx_dtr_producto (pro_id),
    KEY idx_dtr_lote (lot_id_origen),
    CONSTRAINT fk_det_traspaso
        FOREIGN KEY (tra_id) REFERENCES traspaso_almacen (tra_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_det_traspaso_prod
        FOREIGN KEY (pro_id) REFERENCES producto (pro_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_det_traspaso_lote
        FOREIGN KEY (lot_id_origen) REFERENCES lote_inventario (lot_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS conteo_fisico (
    con_id BIGINT NOT NULL AUTO_INCREMENT,
    alm_id INT NOT NULL,
    usu_id_responsable INT NOT NULL,
    con_folio VARCHAR(30) NOT NULL,
    con_estado ENUM('ABIERTO', 'CERRADO', 'CANCELADO') NOT NULL DEFAULT 'ABIERTO',
    con_fecha_inicio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    con_fecha_cierre TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (con_id),
    UNIQUE KEY uk_con_folio (con_folio),
    KEY idx_con_almacen (alm_id),
    KEY idx_con_usuario (usu_id_responsable),
    CONSTRAINT fk_conteo_almacen
        FOREIGN KEY (alm_id) REFERENCES almacen (alm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_conteo_usuario
        FOREIGN KEY (usu_id_responsable) REFERENCES usuario (usu_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS detalle_conteo_fisico (
    dco_id BIGINT NOT NULL AUTO_INCREMENT,
    con_id BIGINT NOT NULL,
    pro_id BIGINT NOT NULL,
    lot_id BIGINT NULL,
    dco_existencia_teorica DECIMAL(12,3) NOT NULL,
    dco_existencia_contada DECIMAL(12,3) NOT NULL,
    dco_diferencia DECIMAL(12,3) NOT NULL,
    PRIMARY KEY (dco_id),
    KEY idx_dco_conteo (con_id),
    KEY idx_dco_producto (pro_id),
    KEY idx_dco_lote (lot_id),
    CONSTRAINT fk_det_conteo
        FOREIGN KEY (con_id) REFERENCES conteo_fisico (con_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_det_conteo_prod
        FOREIGN KEY (pro_id) REFERENCES producto (pro_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_det_conteo_lote
        FOREIGN KEY (lot_id) REFERENCES lote_inventario (lot_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
