-- Abarrotec - Modulo de REPORTES (CU9-CU11, RF17-RF25, RN1-RN17)
CREATE SCHEMA IF NOT EXISTS `abarrotec` DEFAULT CHARACTER SET utf8mb4;
USE `abarrotec`;

CREATE TABLE IF NOT EXISTS `usuario` (
  `id_usuario` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `usuario` VARCHAR(50) NOT NULL,
  `contrasena_hash` VARCHAR(255) NOT NULL,
  `rol` ENUM('ADMINISTRADOR','EMPLEADO') NOT NULL,
  `activo` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `uq_usuario_usuario` (`usuario`)
) ENGINE=InnoDB COMMENT='Actores del sistema. Reportes solo para ADMINISTRADOR (RN11).';

CREATE TABLE IF NOT EXISTS `caja` (
  `id_caja` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(50) NOT NULL,
  `activa` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_caja`)
) ENGINE=InnoDB COMMENT='Cajas registradoras; filtro de CU9.';

CREATE TABLE IF NOT EXISTS `cliente` (
  `id_cliente` INT NOT NULL AUTO_INCREMENT,
  `folio` INT NOT NULL,
  `nombre` VARCHAR(120) NOT NULL,
  `telefono` VARCHAR(20) NULL,
  `correo` VARCHAR(150) NULL,
  `limite_credito` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `activo` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_cliente`),
  UNIQUE KEY `uq_cliente_folio` (`folio`)
) ENGINE=InnoDB COMMENT='Clientes con linea de credito (RN4).';

CREATE TABLE IF NOT EXISTS `departamento` (
  `id_departamento` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(80) NOT NULL,
  PRIMARY KEY (`id_departamento`)
) ENGINE=InnoDB COMMENT='Departamentos de producto.';

CREATE TABLE IF NOT EXISTS `producto` (
  `id_producto` INT NOT NULL AUTO_INCREMENT,
  `codigo_barras` VARCHAR(50) NOT NULL,
  `descripcion` VARCHAR(150) NOT NULL,
  `id_departamento` INT NOT NULL,
  `precio_costo` DECIMAL(10,2) NOT NULL,
  `precio_venta` DECIMAL(10,2) NOT NULL,
  `tasa_iva` DECIMAL(5,2) NOT NULL DEFAULT 16.00,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `uq_producto_codigo_barras` (`codigo_barras`),
  KEY `fk_producto_id_departamento_idx` (`id_departamento`)
) ENGINE=InnoDB COMMENT='Inventario; tasa IVA obligatoria (RN16).';

CREATE TABLE IF NOT EXISTS `forma_pago` (
  `id_forma_pago` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(40) NOT NULL,
  `habilitada` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_forma_pago`)
) ENGINE=InnoDB COMMENT='Efectivo, tarjeta, credito, vales, transferencia, cheque.';

CREATE TABLE IF NOT EXISTS `venta` (
  `id_venta` INT NOT NULL AUTO_INCREMENT,
  `folio` INT NOT NULL,
  `id_caja` INT NOT NULL,
  `id_usuario` INT NOT NULL,
  `id_cliente` INT NULL,
  `estado` ENUM('ABIERTA','PENDIENTE_PAGO','PAGO_COMPLETADO','RECHAZADA','CANCELADA') NOT NULL,
  `es_credito` TINYINT(1) NOT NULL DEFAULT 0,
  `fecha_creacion` DATETIME NOT NULL,
  `fecha_hora_pago` DATETIME NULL,
  `total` DECIMAL(12,2) NOT NULL,
  `motivo_cancelacion` VARCHAR(255) NULL,
  PRIMARY KEY (`id_venta`),
  UNIQUE KEY `uq_venta_folio` (`folio`),
  KEY `fk_venta_id_caja_idx` (`id_caja`),
  KEY `fk_venta_id_usuario_idx` (`id_usuario`),
  KEY `fk_venta_id_cliente_idx` (`id_cliente`)
) ENGINE=InnoDB COMMENT='Recibo. Cuenta como venta solo PAGO_COMPLETADO (RN1); fecha = fecha de pago (RN9).';

CREATE TABLE IF NOT EXISTS `detalle_venta` (
  `id_detalle_venta` INT NOT NULL AUTO_INCREMENT,
  `id_venta` INT NOT NULL,
  `id_producto` INT NOT NULL,
  `id_departamento` INT NOT NULL,
  `cantidad` DECIMAL(10,3) NOT NULL,
  `precio_unitario` DECIMAL(10,2) NOT NULL,
  `costo_unitario` DECIMAL(10,2) NOT NULL,
  `tasa_iva` DECIMAL(5,2) NOT NULL,
  `importe` DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (`id_detalle_venta`),
  KEY `fk_detalle_venta_id_venta_idx` (`id_venta`),
  KEY `fk_detalle_venta_id_producto_idx` (`id_producto`),
  KEY `fk_detalle_venta_id_departamento_idx` (`id_departamento`)
) ENGINE=InnoDB COMMENT='Renglon con costo, IVA y departamento al momento del cobro (RN2, RN3, RN5).';

CREATE TABLE IF NOT EXISTS `pago_venta` (
  `id_pago_venta` INT NOT NULL AUTO_INCREMENT,
  `id_venta` INT NOT NULL,
  `id_forma_pago` INT NOT NULL,
  `monto` DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (`id_pago_venta`),
  KEY `fk_pago_venta_id_venta_idx` (`id_venta`),
  KEY `fk_pago_venta_id_forma_pago_idx` (`id_forma_pago`)
) ENGINE=InnoDB COMMENT='Pagos mixtos; suman el total (RN7).';

CREATE TABLE IF NOT EXISTS `devolucion` (
  `id_devolucion` INT NOT NULL AUTO_INCREMENT,
  `id_venta` INT NOT NULL,
  `id_usuario` INT NOT NULL,
  `fecha_hora` DATETIME NOT NULL,
  `monto` DECIMAL(12,2) NOT NULL,
  `costo_devuelto` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `motivo` VARCHAR(255) NULL,
  PRIMARY KEY (`id_devolucion`),
  KEY `fk_devolucion_id_venta_idx` (`id_venta`),
  KEY `fk_devolucion_id_usuario_idx` (`id_usuario`)
) ENGINE=InnoDB COMMENT='Se resta de ventas en la fecha en que ocurre (RN17).';

CREATE TABLE IF NOT EXISTS `abono_credito` (
  `id_abono_credito` INT NOT NULL AUTO_INCREMENT,
  `id_cliente` INT NOT NULL,
  `id_venta` INT NOT NULL,
  `id_forma_pago` INT NOT NULL,
  `fecha_hora` DATETIME NOT NULL,
  `monto` DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (`id_abono_credito`),
  KEY `fk_abono_credito_id_cliente_idx` (`id_cliente`),
  KEY `fk_abono_credito_id_venta_idx` (`id_venta`),
  KEY `fk_abono_credito_id_forma_pago_idx` (`id_forma_pago`)
) ENGINE=InnoDB COMMENT='Abonos: no son ventas nuevas (RN6).';

CREATE TABLE IF NOT EXISTS `bitacora` (
  `id_bitacora` INT NOT NULL AUTO_INCREMENT,
  `id_usuario` INT NULL,
  `fecha_hora` DATETIME NOT NULL,
  `evento` ENUM('EXPORTACION','ACCESO_DENEGADO','ALERTA_DISCREPANCIA') NOT NULL,
  `reporte` VARCHAR(60) NULL,
  `formato_export` ENUM('XLSX','CSV') NULL,
  `registros_exportados` INT NULL,
  `nombre_archivo` VARCHAR(120) NULL,
  `detalle` VARCHAR(255) NULL,
  PRIMARY KEY (`id_bitacora`),
  KEY `fk_bitacora_id_usuario_idx` (`id_usuario`)
) ENGINE=InnoDB COMMENT='Exportaciones (CU11, RN12), accesos denegados (RN11), alertas reporte vs corte (RN10).';


ALTER TABLE `producto` ADD CONSTRAINT `fk_producto_id_departamento` FOREIGN KEY (`id_departamento`) REFERENCES `departamento` (`id_departamento`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `venta` ADD CONSTRAINT `fk_venta_id_caja` FOREIGN KEY (`id_caja`) REFERENCES `caja` (`id_caja`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `venta` ADD CONSTRAINT `fk_venta_id_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `venta` ADD CONSTRAINT `fk_venta_id_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `detalle_venta` ADD CONSTRAINT `fk_detalle_venta_id_venta` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id_venta`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `detalle_venta` ADD CONSTRAINT `fk_detalle_venta_id_producto` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `detalle_venta` ADD CONSTRAINT `fk_detalle_venta_id_departamento` FOREIGN KEY (`id_departamento`) REFERENCES `departamento` (`id_departamento`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `pago_venta` ADD CONSTRAINT `fk_pago_venta_id_venta` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id_venta`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `pago_venta` ADD CONSTRAINT `fk_pago_venta_id_forma_pago` FOREIGN KEY (`id_forma_pago`) REFERENCES `forma_pago` (`id_forma_pago`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `devolucion` ADD CONSTRAINT `fk_devolucion_id_venta` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id_venta`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `devolucion` ADD CONSTRAINT `fk_devolucion_id_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `abono_credito` ADD CONSTRAINT `fk_abono_credito_id_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `abono_credito` ADD CONSTRAINT `fk_abono_credito_id_venta` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id_venta`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `abono_credito` ADD CONSTRAINT `fk_abono_credito_id_forma_pago` FOREIGN KEY (`id_forma_pago`) REFERENCES `forma_pago` (`id_forma_pago`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `bitacora` ADD CONSTRAINT `fk_bitacora_id_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_usuario`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Indices para los filtros de reportes (RNF16, RNF21, RNF25)
CREATE INDEX idx_venta_pago ON venta (estado, fecha_hora_pago, id_caja);
CREATE INDEX idx_devolucion_fecha ON devolucion (fecha_hora);
CREATE INDEX idx_bitacora_evento ON bitacora (evento, fecha_hora);

-- ======================= VISTAS =======================
-- Renglones de ventas cobradas (RN1). Importe incluye IVA; base = importe / (1 + tasa) (RN16).
-- Ganancia = base - cantidad * costo guardado al cobrar (RN2). No se redondea al sumar (RN13).
CREATE OR REPLACE VIEW v_renglones_cobrados AS
SELECT v.id_venta, DATE(v.fecha_hora_pago) AS fecha, v.id_caja, v.id_usuario, v.id_cliente,
       d.id_departamento, d.importe,
       d.importe / (1 + d.tasa_iva / 100) AS base,
       d.importe - d.importe / (1 + d.tasa_iva / 100) AS iva,
       d.importe / (1 + d.tasa_iva / 100) - d.cantidad * d.costo_unitario AS ganancia
FROM venta v
JOIN detalle_venta d ON d.id_venta = v.id_venta
WHERE v.estado = 'PAGO_COMPLETADO';

-- Devoluciones por dia y caja (RN17)
CREATE OR REPLACE VIEW v_devoluciones_dia AS
SELECT DATE(dv.fecha_hora) AS fecha, v.id_caja,
       SUM(dv.monto) AS devoluciones,
       SUM(dv.monto - dv.costo_devuelto) AS utilidad_devuelta
FROM devolucion dv JOIN venta v ON v.id_venta = dv.id_venta
GROUP BY DATE(dv.fecha_hora), v.id_caja;

-- CU9: indicadores por dia y caja
CREATE OR REPLACE VIEW v_reporte_ventas_dia AS
SELECT r.fecha, r.id_caja,
       SUM(r.importe) - COALESCE(MAX(d.devoluciones), 0) AS ventas_totales,
       SUM(r.ganancia) - COALESCE(MAX(d.utilidad_devuelta), 0) AS ganancia,
       COUNT(DISTINCT r.id_venta) AS num_ventas
FROM v_renglones_cobrados r
LEFT JOIN v_devoluciones_dia d ON d.fecha = r.fecha AND d.id_caja = r.id_caja
GROUP BY r.fecha, r.id_caja;

-- CU9: ventas por cajero
CREATE OR REPLACE VIEW v_ventas_por_cajero AS
SELECT r.fecha, r.id_caja, r.id_usuario, u.nombre AS cajero,
       SUM(r.importe) AS ventas, SUM(r.ganancia) AS ganancia
FROM v_renglones_cobrados r JOIN usuario u ON u.id_usuario = r.id_usuario
GROUP BY r.fecha, r.id_caja, r.id_usuario, u.nombre;

-- CU9: ventas por departamento
CREATE OR REPLACE VIEW v_ventas_por_departamento AS
SELECT r.fecha, r.id_caja, r.id_departamento, dp.nombre AS departamento,
       SUM(r.importe) AS ventas, SUM(r.ganancia) AS ganancia
FROM v_renglones_cobrados r JOIN departamento dp ON dp.id_departamento = r.id_departamento
GROUP BY r.fecha, r.id_caja, r.id_departamento, dp.nombre;

-- CU10: ventas por cliente (solo ventas con cliente asignado, RN4)
CREATE OR REPLACE VIEW v_ventas_por_cliente AS
SELECT c.folio AS Folio, c.nombre AS Nombre,
       COUNT(DISTINCT r.id_venta) AS numero_ventas,
       SUM(r.importe) AS acumulado_ventas,
       SUM(r.ganancia) AS acumulado_ganancias
FROM v_renglones_cobrados r JOIN cliente c ON c.id_cliente = r.id_cliente
GROUP BY c.id_cliente, c.folio, c.nombre;

-- ======================= PROCEDIMIENTOS =======================
DELIMITER $$

-- CU9: resumen del periodo. p_id_caja NULL = Todas las cajas.
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

-- CU9: grafica de ventas por dia (para mes/anio se agrupa en la aplicacion)
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

-- CU9: ventas por departamento con porcentaje del total
CREATE PROCEDURE sp_ventas_por_departamento(IN p_desde DATE, IN p_hasta DATE, IN p_id_caja INT)
BEGIN
  SELECT departamento, SUM(ventas) AS ventas, SUM(ganancia) AS ganancia,
         100 * SUM(ventas) / NULLIF(SUM(SUM(ventas)) OVER (), 0) AS porcentaje_total
  FROM v_ventas_por_departamento
  WHERE fecha BETWEEN p_desde AND p_hasta AND (p_id_caja IS NULL OR id_caja = p_id_caja)
  GROUP BY id_departamento, departamento ORDER BY ventas DESC;
END$$

-- CU11: registra la exportacion en bitacora (RN12, RNF19)
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
