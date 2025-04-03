-- Crear esquema para organización de la BD
CREATE SCHEMA tienda;

-- Crear tabla de clientes
CREATE TABLE tienda.clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- Crear tabla de productos
CREATE TABLE tienda.productos (
    producto_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) CHECK (precio > 0) NOT NULL,
    stock INT CHECK (stock >= 0) NOT NULL
);

-- Crear tabla de ventas con claves foráneas y restricciones
CREATE TABLE tienda.ventas (
    venta_id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT CHECK (cantidad > 0) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES tienda.clientes(cliente_id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES tienda.productos(producto_id) ON DELETE CASCADE
);

-- Índice para mejorar consultas por fecha
CREATE INDEX idx_ventas_fecha ON tienda.ventas(fecha);
