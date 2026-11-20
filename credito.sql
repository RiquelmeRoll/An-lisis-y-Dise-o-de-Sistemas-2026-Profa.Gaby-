-- base de datos de credito
CREATE DATABASE IF NOT EXISTS pos_modulo_credito
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pos_modulo_credito;

SET FOREIGN_KEY_CHECKS = 0;

-- tablas generales
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
    CONSTRAINT fk_cred_usuario_sucursal
        FOREIGN KEY (id_sucursal_principal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS caja_turno (
    id_turno BIGINT NOT NULL AUTO_INCREMENT,
    id_sucursal INT NOT NULL,
    id_usuario_cajero INT NOT NULL,
    caja_numero VARCHAR(20) NOT NULL,
    fecha_apertura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre TIMESTAMP NULL,
    estado ENUM('ABIERTA', 'CERRADA', 'ARQUEADA') NOT NULL DEFAULT 'ABIERTA',
    PRIMARY KEY (id_turno),
    KEY idx_turno_sucursal (id_sucursal),
    KEY idx_turno_cajero (id_usuario_cajero),
    CONSTRAINT fk_turno_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_turno_cajero
        FOREIGN KEY (id_usuario_cajero) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
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
    CONSTRAINT fk_cred_lista_precio_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS forma_pago (
    id_forma_pago INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(40) NOT NULL,
    habilitada TINYINT(1) NOT NULL DEFAULT 1,
    comision_porcentaje DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (id_forma_pago)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- politicas y clientes
CREATE TABLE IF NOT EXISTS politica_credito (
    id_politica INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(80) NOT NULL,
    dias_plazo_defecto SMALLINT NOT NULL DEFAULT 30,
    dias_gracia_mora SMALLINT NOT NULL DEFAULT 3,
    tasa_interes_mora_diaria DECIMAL(6,4) NOT NULL DEFAULT 0.0000,
    porcentaje_enganche_minimo DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    bloquear_si_tiene_vencidos TINYINT(1) NOT NULL DEFAULT 1,
    activa TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_politica),
    UNIQUE KEY uq_politica_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cliente (
    id_cliente BIGINT NOT NULL AUTO_INCREMENT,
    id_lista_precio_asignada INT NULL,
    codigo VARCHAR(30) NOT NULL,
    tipo ENUM('FISICA', 'MORAL', 'PUBLICO_GENERAL') NOT NULL DEFAULT 'FISICA',
    nombre_completo VARCHAR(160) NOT NULL,
    rfc VARCHAR(20) NULL,
    telefono_principal VARCHAR(20) NULL,
    telefono_secundario VARCHAR(20) NULL,
    email VARCHAR(120) NULL,
    direccion_completa VARCHAR(300) NULL,
    referencia_aval_nombre VARCHAR(140) NULL,
    referencia_aval_telefono VARCHAR(20) NULL,
    score_comportamiento SMALLINT NOT NULL DEFAULT 100,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente),
    UNIQUE KEY uq_cliente_codigo (codigo),
    KEY idx_cliente_nombre (nombre_completo),
    CONSTRAINT fk_cred_cliente_lista_precio
        FOREIGN KEY (id_lista_precio_asignada) REFERENCES lista_precio (id_lista_precio)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ventas
CREATE TABLE IF NOT EXISTS venta (
    id_venta INT NOT NULL AUTO_INCREMENT,
    id_sucursal INT NOT NULL,
    id_turno BIGINT NOT NULL,
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
    KEY idx_venta_cliente (id_cliente),
    KEY idx_venta_fecha (fecha_hora),
    CONSTRAINT fk_venta_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_venta_turno
        FOREIGN KEY (id_turno) REFERENCES caja_turno (id_turno)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_venta_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_venta_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- cuentas, cargos, abonos y cobranza
CREATE TABLE IF NOT EXISTS cuenta_credito (
    id_cuenta_credito BIGINT NOT NULL AUTO_INCREMENT,
    id_cliente BIGINT NOT NULL,
    id_politica INT NOT NULL,
    id_usuario_aprueba INT NOT NULL,
    numero_cuenta VARCHAR(30) NOT NULL,
    limite DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    saldo_deudor DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    saldo_intereses_mora DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    credito_disponible DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    dias_plazo SMALLINT NOT NULL DEFAULT 30,
    estado ENUM('ACTIVA', 'SUSPENDIDA', 'BLOQUEADA', 'CANCELADA') NOT NULL DEFAULT 'ACTIVA',
    permite_sobregiro TINYINT(1) NOT NULL DEFAULT 0,
    monto_sobregiro_max DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    fecha_apertura DATE NOT NULL,
    fecha_ultimo_cargo TIMESTAMP NULL,
    fecha_ultimo_pago DATE NULL,
    version_concurrencia INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_cuenta_credito),
    UNIQUE KEY uq_cuenta_cliente (id_cliente),
    UNIQUE KEY uq_cuenta_numero (numero_cuenta),
    CONSTRAINT fk_cuenta_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cuenta_politica
        FOREIGN KEY (id_politica) REFERENCES politica_credito (id_politica)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cuenta_usuario_aprueba
        FOREIGN KEY (id_usuario_aprueba) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cargo_credito (
    id_cargo BIGINT NOT NULL AUTO_INCREMENT,
    id_cuenta_credito BIGINT NOT NULL,
    id_venta INT NOT NULL,
    id_sucursal INT NOT NULL,
    id_usuario_cajero INT NOT NULL,
    folio_nota VARCHAR(30) NOT NULL,
    monto_original DECIMAL(12,2) NOT NULL,
    enganche_pagado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    monto_financiado DECIMAL(12,2) NOT NULL,
    saldo_capital_pendiente DECIMAL(12,2) NOT NULL,
    saldo_mora_pendiente DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    fecha_emision TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento DATE NOT NULL,
    dias_atraso INT NOT NULL DEFAULT 0,
    estado ENUM('PENDIENTE', 'PARCIAL', 'PAGADO', 'VENCIDO', 'CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
    PRIMARY KEY (id_cargo),
    UNIQUE KEY uq_cargo_venta (id_venta),
    UNIQUE KEY uq_cargo_folio_nota (folio_nota),
    KEY idx_cargo_cuenta (id_cuenta_credito),
    KEY idx_cargo_vencimiento (fecha_vencimiento, estado),
    CONSTRAINT fk_cargo_cuenta
        FOREIGN KEY (id_cuenta_credito) REFERENCES cuenta_credito (id_cuenta_credito)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cargo_venta
        FOREIGN KEY (id_venta) REFERENCES venta (id_venta)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cargo_sucursal
        FOREIGN KEY (id_sucursal) REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cargo_cajero
        FOREIGN KEY (id_usuario_cajero) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS abono_credito (
    id_abono BIGINT NOT NULL AUTO_INCREMENT,
    id_cuenta_credito BIGINT NOT NULL,
    id_turno BIGINT NOT NULL,
    id_usuario_cajero INT NOT NULL,
    id_forma_pago INT NOT NULL,
    folio_recibo VARCHAR(30) NOT NULL,
    monto_total DECIMAL(12,2) NOT NULL,
    referencia_bancaria VARCHAR(80) NULL,
    saldo_deudor_anterior DECIMAL(12,2) NOT NULL,
    saldo_deudor_nuevo DECIMAL(12,2) NOT NULL,
    estado ENUM('APLICADO', 'CANCELADO') NOT NULL DEFAULT 'APLICADO',
    motivo_cancelacion VARCHAR(250) NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_abono),
    UNIQUE KEY uq_abono_folio_recibo (folio_recibo),
    KEY idx_abono_cuenta (id_cuenta_credito),
    CONSTRAINT fk_abono_cuenta
        FOREIGN KEY (id_cuenta_credito) REFERENCES cuenta_credito (id_cuenta_credito)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_abono_turno
        FOREIGN KEY (id_turno) REFERENCES caja_turno (id_turno)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_abono_cajero
        FOREIGN KEY (id_usuario_cajero) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_abono_forma_pago
        FOREIGN KEY (id_forma_pago) REFERENCES forma_pago (id_forma_pago)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS aplicacion_abono (
    id_aplicacion BIGINT NOT NULL AUTO_INCREMENT,
    id_abono BIGINT NOT NULL,
    id_cargo BIGINT NOT NULL,
    monto_a_capital DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    monto_a_mora DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    monto_total_aplicado DECIMAL(12,2) NOT NULL,
    fecha_aplicacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_aplicacion),
    KEY idx_aplicacion_abono (id_abono),
    KEY idx_aplicacion_cargo (id_cargo),
    CONSTRAINT fk_aplicacion_abono
        FOREIGN KEY (id_abono) REFERENCES abono_credito (id_abono)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_aplicacion_cargo
        FOREIGN KEY (id_cargo) REFERENCES cargo_credito (id_cargo)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS interes_moratorio (
    id_interes BIGINT NOT NULL AUTO_INCREMENT,
    id_cargo BIGINT NOT NULL,
    id_usuario_condona INT NULL,
    fecha_calculo DATE NOT NULL,
    base_calculo DECIMAL(12,2) NOT NULL,
    tasa_aplicada DECIMAL(6,4) NOT NULL,
    monto_generado DECIMAL(12,2) NOT NULL,
    condonado TINYINT(1) NOT NULL DEFAULT 0,
    motivo_condonacion VARCHAR(200) NULL,
    PRIMARY KEY (id_interes),
    KEY idx_interes_cargo (id_cargo),
    CONSTRAINT fk_interes_cargo
        FOREIGN KEY (id_cargo) REFERENCES cargo_credito (id_cargo)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_interes_usuario_condona
        FOREIGN KEY (id_usuario_condona) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS historial_credito (
    id_historial_credito BIGINT NOT NULL AUTO_INCREMENT,
    id_cuenta_credito BIGINT NOT NULL,
    id_usuario_autoriza INT NOT NULL,
    tipo_evento ENUM('APERTURA', 'AUMENTO_LIMITE', 'REDUCCION_LIMITE', 'CAMBIO_ESTADO', 'BLOQUEO', 'DESBLOQUEO') NOT NULL,
    limite_anterior DECIMAL(12,2) NULL,
    limite_nuevo DECIMAL(12,2) NULL,
    estado_anterior ENUM('ACTIVA', 'SUSPENDIDA', 'BLOQUEADA', 'CANCELADA') NULL,
    estado_nuevo ENUM('ACTIVA', 'SUSPENDIDA', 'BLOQUEADA', 'CANCELADA') NULL,
    motivo VARCHAR(250) NOT NULL,
    fecha_evento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_historial_credito),
    KEY idx_historial_cuenta (id_cuenta_credito),
    CONSTRAINT fk_hc_cuenta
        FOREIGN KEY (id_cuenta_credito) REFERENCES cuenta_credito (id_cuenta_credito)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_hc_usuario_autoriza
        FOREIGN KEY (id_usuario_autoriza) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS gestion_cobranza (
    id_gestion BIGINT NOT NULL AUTO_INCREMENT,
    id_cuenta_credito BIGINT NOT NULL,
    id_usuario_gestor INT NOT NULL,
    canal ENUM('LLAMADA', 'WHATSAPP', 'SMS', 'EMAIL', 'VISITA') NOT NULL DEFAULT 'LLAMADA',
    resultado ENUM('CONTACTADO_PROMESA', 'CONTACTADO_SIN_ACUERDO', 'NO_CONTESTA', 'NUMERO_EQUIVOCADO', 'PAGO_REALIZADO') NOT NULL,
    fecha_gestion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_promesa_pago DATE NULL,
    monto_prometido DECIMAL(12,2) NULL,
    observaciones VARCHAR(400) NULL,
    PRIMARY KEY (id_gestion),
    KEY idx_gestion_cuenta (id_cuenta_credito),
    CONSTRAINT fk_gc_cuenta
        FOREIGN KEY (id_cuenta_credito) REFERENCES cuenta_credito (id_cuenta_credito)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_gc_usuario_gestor
        FOREIGN KEY (id_usuario_gestor) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;