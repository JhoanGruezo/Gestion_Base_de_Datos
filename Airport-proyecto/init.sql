CREATE TABLE vuelos (
    vuelo_id SERIAL PRIMARY KEY,
    numero_vuelo VARCHAR(10),
    origen VARCHAR(100),
    destino VARCHAR(100),
    fecha_salida TIMESTAMP,
    capacidad INT
);

CREATE TABLE pasajeros (
    pasajero_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    documento_identidad VARCHAR(20)
);

CREATE TABLE reservas (
    reserva_id SERIAL PRIMARY KEY,
    pasajero_id INT REFERENCES pasajeros(pasajero_id),
    vuelo_id INT REFERENCES vuelos(vuelo_id),
    fecha_reserva TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(50)
);

INSERT INTO vuelos (numero_vuelo, origen, destino, fecha_salida, capacidad) 
VALUES ('AA101', 'Madrid', 'New York', '2025-07-15 10:00:00', 200);

INSERT INTO pasajeros (nombre, documento_identidad) 
VALUES ('Carlos Ruiz', 'X12345678');

INSERT INTO reservas (pasajero_id, vuelo_id, estado) 
VALUES (1, 1, 'reservado');
