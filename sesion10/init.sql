-- Crear tabla clientes
CREATE TABLE IF NOT EXISTS clientes (
  cliente_id SERIAL PRIMARY KEY,
  nombre_cliente VARCHAR(100),
  direccion_cliente VARCHAR(150)
);

-- Insertar clientes con nombres colombianos
INSERT INTO clientes (nombre_cliente, direccion_cliente) VALUES 
('Juan Camilo Rodríguez', 'Bogotá'),
('Laura Vanessa Pérez', 'Medellín'),
('Andrés Felipe González', 'Cali'),
('María Fernanda Ríos', 'Barranquilla'),
('Santiago Alejandro Martínez', 'Bucaramanga'),
('Valentina López', 'Cartagena'),
('Carlos Eduardo Niño', 'Manizales'),
('Natalia Andrea Suárez', 'Pereira'),
('José David Ramírez', 'Santa Marta'),
('Daniela Catalina Vargas', 'Villavicencio');

-- 🧩 Ejercicio 1: Crear un índice
CREATE INDEX idx_nombre_cliente ON clientes(nombre_cliente);
