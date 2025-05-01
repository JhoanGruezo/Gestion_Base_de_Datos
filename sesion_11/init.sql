-- Crear la base de datos (si no existe, aunque Docker lo hace)
-- CREATE DATABASE banco;

-- Conectarse a la base de datos (Docker lo hace automáticamente después de crearla)
-- \c banco;

-- Crear el rol y el usuario
CREATE ROLE generador_datos WITH LOGIN PASSWORD 'clave_segura';
GRANT CONNECT ON DATABASE banco TO generador_datos;

-- El usuario mi_usuario ya estará en el rol generador_datos al crearlo
CREATE USER mi_usuario WITH PASSWORD 'mi_clave' IN ROLE generador_datos;

-- Crear las tablas
CREATE TABLE cuentas (
    id_cuenta SERIAL PRIMARY KEY,
    nombre_cliente VARCHAR(255),
    saldo DECIMAL
);

CREATE TABLE transacciones (
    id_transaccion SERIAL PRIMARY KEY,
    id_cuenta INTEGER,
    tipo_transaccion VARCHAR(10),
    monto DECIMAL,
    fecha_transaccion TIMESTAMP,
    FOREIGN KEY (id_cuenta) REFERENCES cuentas(id_cuenta)
);

-- Otorgar permisos al rol generador_datos
GRANT INSERT ON TABLE cuentas TO generador_datos;
GRANT SELECT ON TABLE cuentas TO generador_datos; -- Permiso SELECT en cuentas (ya estaba)
GRANT INSERT ON TABLE transacciones TO generador_datos;
GRANT SELECT ON TABLE transacciones TO generador_datos; -- ¡Añadido permiso SELECT en transacciones!

-- Otorgar permisos de USAGE en las secuencias si es necesario (opcional, INSERT suele bastar)
GRANT USAGE ON SEQUENCE cuentas_id_cuenta_seq TO generador_datos;
GRANT USAGE ON SEQUENCE transacciones_id_transaccion_seq TO generador_datos;