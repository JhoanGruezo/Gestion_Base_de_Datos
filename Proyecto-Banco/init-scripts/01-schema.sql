-- Estructura básica de la base de datos bancaria

-- Crear tabla de clientes con más campos útiles
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    saldo DECIMAL(12, 2) DEFAULT 0.00,
    estado VARCHAR(20) DEFAULT 'activo'
);

-- Crear tabla de tipos de transacciones para mantener consistencia
CREATE TABLE tipos_transaccion (
    tipo_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

-- Crear tabla de transacciones mejorada
CREATE TABLE transacciones (
    transaccion_id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    tipo_id INT NOT NULL,
    monto DECIMAL(12, 2) NOT NULL,
    saldo_resultante DECIMAL(12, 2) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descripcion TEXT,
    referencia VARCHAR(100),
    FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    FOREIGN KEY (tipo_id) REFERENCES tipos_transaccion(tipo_id)
);

-- Crear índices para mejorar el rendimiento de las consultas
CREATE INDEX idx_transacciones_cliente_id ON transacciones(cliente_id);
CREATE INDEX idx_transacciones_fecha ON transacciones(fecha);
CREATE INDEX idx_transacciones_tipo_id ON transacciones(tipo_id);

-- Crear vistas para facilitar la generación de informes
CREATE VIEW v_saldos_clientes AS
SELECT c.cliente_id, c.nombre, c.apellido, c.saldo, c.estado
FROM clientes c
WHERE c.estado = 'activo';

CREATE VIEW v_transacciones_recientes AS
SELECT t.transaccion_id, c.nombre || ' ' || c.apellido AS cliente, 
       tp.nombre AS tipo_transaccion, t.monto, t.saldo_resultante, 
       t.fecha, t.descripcion
FROM transacciones t
JOIN clientes c ON t.cliente_id = c.cliente_id
JOIN tipos_transaccion tp ON t.tipo_id = tp.tipo_id
ORDER BY t.fecha DESC;