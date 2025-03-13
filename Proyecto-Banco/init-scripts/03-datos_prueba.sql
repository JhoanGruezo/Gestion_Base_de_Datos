-- Datos de prueba para el sistema bancario

-- Añadir tipos de transacciones
INSERT INTO tipos_transaccion (nombre, descripcion) VALUES 
('deposito', 'Ingreso de dinero a la cuenta'),
('retiro', 'Extracción de dinero de la cuenta'),
('transferencia_enviada', 'Transferencia a otra cuenta'),
('transferencia_recibida', 'Transferencia desde otra cuenta');

-- Añadir clientes de ejemplo
INSERT INTO clientes (nombre, apellido, email, saldo) VALUES 
('Juan', 'Pérez', 'juan.perez@example.com', 1500.00),
('Ana', 'García', 'ana.garcia@example.com', 2500.00),
('Carlos', 'Rodríguez', 'carlos.rodriguez@example.com', 3200.00),
('María', 'López', 'maria.lopez@example.com', 4100.00),
('Pedro', 'Martínez', 'pedro.martinez@example.com', 800.00),
('Laura', 'Sánchez', 'laura.sanchez@example.com', 1900.00);

-- Registrar algunas transacciones de ejemplo

-- Depósitos
SELECT realizar_transaccion(1, 1, 500.00, 'Depósito inicial');
SELECT realizar_transaccion(2, 1, 1000.00, 'Depósito de nómina');
SELECT realizar_transaccion(3, 1, 750.00, 'Depósito por venta');

-- Retiros
SELECT realizar_transaccion(1, 2, 200.00, 'Retiro en cajero automático');
SELECT realizar_transaccion(2, 2, 300.00, 'Retiro en sucursal');
SELECT realizar_transaccion(3, 2, 150.00, 'Pago de servicio');

-- Transferencias
SELECT transferencia_entre_cuentas(1, 2, 100.00, 'Pago de deuda');
SELECT transferencia_entre_cuentas(2, 3, 250.00, 'Transferencia para gastos compartidos');
SELECT transferencia_entre_cuentas(3, 1, 75.00, 'Reembolso de gastos');
SELECT transferencia_entre_cuentas(4, 5, 120.00, 'Pago de alquiler');
SELECT transferencia_entre_cuentas(5, 6, 80.00, 'Pago de servicios');

-- Más depósitos y retiros para generar un historial más completo
SELECT realizar_transaccion(4, 1, 600.00, 'Depósito de cheque');
SELECT realizar_transaccion(5, 1, 350.00, 'Depósito en efectivo');
SELECT realizar_transaccion(6, 1, 450.00, 'Ingreso por servicios prestados');

SELECT realizar_transaccion(4, 2, 250.00, 'Retiro para gastos personales');
SELECT realizar_transaccion(5, 2, 100.00, 'Retiro para compras');
SELECT realizar_transaccion(6, 2, 200.00, 'Pago de factura');

-- Consultas de ejemplo para verificar los datos
-- (Estas consultas son solo para referencia y no se ejecutarán automáticamente)

/*
-- Ver saldos de todos los clientes
SELECT * FROM v_saldos_clientes;

-- Ver las transacciones recientes
SELECT * FROM v_transacciones_recientes LIMIT 10;

-- Ver el informe de transacciones del último mes (con CAST explícito)
SELECT * FROM informe_transacciones(NOW() - INTERVAL '1 month', NOW());

-- Ver el historial de saldo de un cliente específico (con CAST explícito)
SELECT * FROM historial_saldo(1, NOW() - INTERVAL '1 month', NOW());

-- Ver el balance diario
SELECT * FROM v_balance_diario;
*/