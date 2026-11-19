-- ============================================================================
-- MÓDULO DE CORTE - ABARROTEC (DDL Compatible con Importador SQL de Draw.io)
-- ============================================================================

CREATE TABLE usuarios (
    usuario_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    rol ENUM('ADMINISTRADOR', 'EMPLEADO') NOT NULL
);

CREATE TABLE cajas (
    caja_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE configuracion_corte (
    configuracion_id INT AUTO_INCREMENT PRIMARY KEY,
    modo_cierre ENUM('CON_AJUSTE', 'SIN_AJUSTE') NOT NULL DEFAULT 'CON_AJUSTE',
    modo_limite_efectivo ENUM('DESACTIVADO', 'SOLO_AVISAR', 'BLOQUEAR') NOT NULL DEFAULT 'DESACTIVADO',
    monto_limite_efectivo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    mensaje_limite_efectivo VARCHAR(255) NOT NULL,
    tolerancia_diferencia DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    actualizado_por INT NOT NULL,
    fecha_actualizacion DATETIME NOT NULL,
    CONSTRAINT fk_config_usuario FOREIGN KEY (actualizado_por) REFERENCES usuarios(usuario_id)
);

CREATE TABLE turnos (
    turno_id INT AUTO_INCREMENT PRIMARY KEY,
    caja_id INT NOT NULL,
    cajero_id INT NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NULL,
    fondo_inicial DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado ENUM('ABIERTO', 'CERRADO') NOT NULL DEFAULT 'ABIERTO',
    CONSTRAINT fk_turnos_caja FOREIGN KEY (caja_id) REFERENCES cajas(caja_id),
    CONSTRAINT fk_turnos_cajero FOREIGN KEY (cajero_id) REFERENCES usuarios(usuario_id)
);

CREATE TABLE movimientos_efectivo (
    movimiento_id INT AUTO_INCREMENT PRIMARY KEY,
    turno_id INT NOT NULL,
    usuario_id INT NOT NULL,
    tipo_movimiento ENUM('ENTRADA', 'SALIDA') NOT NULL,
    origen ENUM('MANUAL', 'AJUSTE_SOBRANTE', 'AJUSTE_FALTANTE', 'RETIRO_LIMITE') NOT NULL DEFAULT 'MANUAL',
    monto DECIMAL(12,2) NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    fecha_hora DATETIME NOT NULL,
    CONSTRAINT fk_mov_turno FOREIGN KEY (turno_id) REFERENCES turnos(turno_id),
    CONSTRAINT fk_mov_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

CREATE TABLE cortes (
    corte_id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_corte ENUM('CAJERO', 'DIA') NOT NULL,
    turno_id INT NULL,
    caja_id INT NULL,
    usuario_ejecuta_id INT NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NOT NULL,
    ventas_totales DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    ganancia_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    fondo_inicial DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    ventas_efectivo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    abonos_efectivo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_entradas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_salidas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    devoluciones_efectivo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    efectivo_esperado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    ventas_tarjeta DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    ventas_credito DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    ventas_vales DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    ventas_transferencia DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    ventas_cheque DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    devoluciones_ventas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    ingresos_contado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    impuestos_generados DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    pagos_creditos_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    efectivo_contado DECIMAL(12,2) NULL,
    diferencia_efectivo DECIMAL(12,2) NULL,
    tipo_ajuste ENUM('FALTANTE', 'SOBRANTE', 'NINGUNO') NOT NULL DEFAULT 'NINGUNO',
    tarjeta_esperado DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    tarjeta_terminal DECIMAL(12,2) NULL,
    diferencia_tarjeta DECIMAL(12,2) NULL,
    autorizado_por INT NULL,
    motivo_autorizacion VARCHAR(255) NULL,
    fecha_creacion DATETIME NOT NULL,
    CONSTRAINT fk_cortes_turno FOREIGN KEY (turno_id) REFERENCES turnos(turno_id),
    CONSTRAINT fk_cortes_caja FOREIGN KEY (caja_id) REFERENCES cajas(caja_id),
    CONSTRAINT fk_cortes_usuario FOREIGN KEY (usuario_ejecuta_id) REFERENCES usuarios(usuario_id),
    CONSTRAINT fk_cortes_autoriza FOREIGN KEY (autorizado_por) REFERENCES usuarios(usuario_id)
);

CREATE TABLE corte_ventas_departamento (
    corte_depto_id INT AUTO_INCREMENT PRIMARY KEY,
    corte_id INT NOT NULL,
    departamento_id INT NOT NULL,
    nombre_departamento VARCHAR(100) NOT NULL,
    monto_ventas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_corte_depto FOREIGN KEY (corte_id) REFERENCES cortes(corte_id)
);

CREATE TABLE ajustes_corte_cerrado (
    ajuste_id INT AUTO_INCREMENT PRIMARY KEY,
    corte_id INT NOT NULL,
    admin_autoriza_id INT NOT NULL,
    tipo_ajuste ENUM('EFECTIVO', 'TARJETA', 'OTRO') NOT NULL,
    monto_ajuste DECIMAL(12,2) NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    fecha_hora DATETIME NOT NULL,
    CONSTRAINT fk_ajuste_corte FOREIGN KEY (corte_id) REFERENCES cortes(corte_id),
    CONSTRAINT fk_ajuste_admin FOREIGN KEY (admin_autoriza_id) REFERENCES usuarios(usuario_id)
);

CREATE TABLE bitacora_corte (
    bitacora_id INT AUTO_INCREMENT PRIMARY KEY,
    turno_id INT NULL,
    corte_id INT NULL,
    usuario_id INT NOT NULL,
    evento ENUM('EXCESO_LIMITE_EFECTIVO', 'DIFERENCIA_CIERRE', 'DIFERENCIA_TARJETA', 'AUTORIZACION_DIFERENCIA', 'AJUSTE_CORTE_CERRADO', 'PERMISO_DENEGADO') NOT NULL,
    descripcion TEXT NOT NULL,
    fecha_hora DATETIME NOT NULL,
    CONSTRAINT fk_bitacora_turno FOREIGN KEY (turno_id) REFERENCES turnos(turno_id),
    CONSTRAINT fk_bitacora_corte FOREIGN KEY (corte_id) REFERENCES cortes(corte_id),
    CONSTRAINT fk_bitacora_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

CREATE TABLE recibos_turno (
    recibo_id INT AUTO_INCREMENT PRIMARY KEY,
    turno_id INT NOT NULL,
    estado ENUM('PENDIENTE', 'PAGADO', 'CANCELADO', 'DEVUELTO') NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    ganancia DECIMAL(12,2) NOT NULL,
    impuestos DECIMAL(12,2) NOT NULL,
    fecha_pago DATETIME NULL,
    CONSTRAINT fk_recibo_turno FOREIGN KEY (turno_id) REFERENCES turnos(turno_id)
);

CREATE TABLE pagos_recibo_turno (
    pago_id INT AUTO_INCREMENT PRIMARY KEY,
    recibo_id INT NOT NULL,
    forma_pago ENUM('EFECTIVO', 'TARJETA_CREDITO', 'CREDITO', 'VALES_DESPENSA', 'TRANSFERENCIA', 'CHEQUE') NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    num_aprobacion_terminal VARCHAR(50) NULL,
    CONSTRAINT fk_pago_recibo FOREIGN KEY (recibo_id) REFERENCES recibos_turno(recibo_id)
);

CREATE TABLE abonos_credito_turno (
    abono_id INT AUTO_INCREMENT PRIMARY KEY,
    turno_id INT NOT NULL,
    forma_pago ENUM('EFECTIVO', 'TARJETA_CREDITO', 'TRANSFERENCIA', 'CHEQUE') NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_hora DATETIME NOT NULL,
    CONSTRAINT fk_abono_turno FOREIGN KEY (turno_id) REFERENCES turnos(turno_id)
);