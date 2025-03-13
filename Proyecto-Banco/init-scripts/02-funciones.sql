-- Funciones para operaciones financieras

-- Función para realizar una transacción (asegura ACID)
CREATE OR REPLACE FUNCTION realizar_transaccion(
    p_cliente_id INT,
    p_tipo_id INT,
    p_monto DECIMAL(12,2),
    p_descripcion TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_saldo_actual DECIMAL(12,2);
    v_saldo_nuevo DECIMAL(12,2);
    v_tipo_nombre VARCHAR(50);
BEGIN
    -- Obtener el tipo de transacción
    SELECT nombre INTO v_tipo_nombre FROM tipos_transaccion WHERE tipo_id = p_tipo_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tipo de transacción no válido';
    END IF;
    
    -- Iniciar transacción
    BEGIN
        -- Leer el saldo actual con bloqueo para evitar condiciones de carrera
        SELECT saldo INTO v_saldo_actual FROM clientes 
        WHERE cliente_id = p_cliente_id FOR UPDATE;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cliente no encontrado';
        END IF;
        
        -- Calcular nuevo saldo según el tipo de transacción
        IF v_tipo_nombre = 'deposito' OR v_tipo_nombre = 'transferencia_recibida' THEN
            v_saldo_nuevo := v_saldo_actual + p_monto;
        ELSIF v_tipo_nombre = 'retiro' OR v_tipo_nombre = 'transferencia_enviada' THEN
            IF v_saldo_actual < p_monto THEN
                RAISE EXCEPTION 'Saldo insuficiente';
            END IF;
            v_saldo_nuevo := v_saldo_actual - p_monto;
        ELSE
            RAISE EXCEPTION 'Tipo de transacción no soportado';
        END IF;
        
        -- Actualizar el saldo del cliente
        UPDATE clientes SET saldo = v_saldo_nuevo WHERE cliente_id = p_cliente_id;
        
        -- Registrar la transacción
        INSERT INTO transacciones (cliente_id, tipo_id, monto, saldo_resultante, descripcion)
        VALUES (p_cliente_id, p_tipo_id, p_monto, v_saldo_nuevo, p_descripcion);
        
        RETURN TRUE;
    EXCEPTION WHEN OTHERS THEN
        RAISE;
    END;
END;
$$ LANGUAGE plpgsql;

-- Función para generar informe de transacciones por periodo
-- Corregido para aceptar TIMESTAMP WITH TIME ZONE
CREATE OR REPLACE FUNCTION informe_transacciones(
    fecha_inicio TIMESTAMP WITH TIME ZONE,
    fecha_fin TIMESTAMP WITH TIME ZONE
) RETURNS TABLE (
    cliente VARCHAR,
    tipo_transaccion VARCHAR,
    total_monto DECIMAL(12,2),
    cantidad_transacciones BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.nombre || ' ' || c.apellido AS cliente,
        tp.nombre AS tipo_transaccion,
        SUM(t.monto) AS total_monto,
        COUNT(t.transaccion_id) AS cantidad_transacciones
    FROM transacciones t
    JOIN clientes c ON t.cliente_id = c.cliente_id
    JOIN tipos_transaccion tp ON t.tipo_id = tp.tipo_id
    WHERE t.fecha BETWEEN fecha_inicio AND fecha_fin
    GROUP BY c.nombre, c.apellido, tp.nombre
    ORDER BY c.nombre, c.apellido, tp.nombre;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener el historial de saldo de un cliente
-- Corregido para aceptar TIMESTAMP WITH TIME ZONE
CREATE OR REPLACE FUNCTION historial_saldo(
    p_cliente_id INT,
    p_fecha_inicio TIMESTAMP WITH TIME ZONE,
    p_fecha_fin TIMESTAMP WITH TIME ZONE
) RETURNS TABLE (
    fecha TIMESTAMP,
    tipo_transaccion VARCHAR,
    monto DECIMAL(12,2),
    saldo DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.fecha,
        tp.nombre AS tipo_transaccion,
        t.monto,
        t.saldo_resultante AS saldo
    FROM transacciones t
    JOIN tipos_transaccion tp ON t.tipo_id = tp.tipo_id
    WHERE t.cliente_id = p_cliente_id
    AND t.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
    ORDER BY t.fecha;
END;
$$ LANGUAGE plpgsql;

-- Crear una función para transferencia entre cuentas (garantiza ACID)
CREATE OR REPLACE FUNCTION transferencia_entre_cuentas(
    p_origen_id INT,
    p_destino_id INT,
    p_monto DECIMAL(12,2),
    p_descripcion TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_origen_saldo DECIMAL(12,2);
    v_destino_saldo DECIMAL(12,2);
    v_tipo_id_enviada INT;
    v_tipo_id_recibida INT;
    v_referencia VARCHAR(100);
BEGIN
    -- Obtener tipos de transacción
    SELECT tipo_id INTO v_tipo_id_enviada FROM tipos_transaccion WHERE nombre = 'transferencia_enviada';
    SELECT tipo_id INTO v_tipo_id_recibida FROM tipos_transaccion WHERE nombre = 'transferencia_recibida';
    
    -- Generar referencia única
    v_referencia := 'TRANS-' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '-' || p_origen_id || '-' || p_destino_id;
    
    -- Iniciar transacción
    BEGIN
        -- Verificar que las cuentas existan y obtener saldos con bloqueo
        SELECT saldo INTO v_origen_saldo FROM clientes 
        WHERE cliente_id = p_origen_id FOR UPDATE;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cuenta de origen no encontrada';
        END IF;
        
        SELECT saldo INTO v_destino_saldo FROM clientes 
        WHERE cliente_id = p_destino_id FOR UPDATE;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cuenta de destino no encontrada';
        END IF;
        
        -- Verificar saldo suficiente
        IF v_origen_saldo < p_monto THEN
            RAISE EXCEPTION 'Saldo insuficiente en cuenta origen';
        END IF;
        
        -- Actualizar saldos
        UPDATE clientes SET saldo = saldo - p_monto WHERE cliente_id = p_origen_id;
        UPDATE clientes SET saldo = saldo + p_monto WHERE cliente_id = p_destino_id;
        
        -- Registrar transacción de envío
        INSERT INTO transacciones (
            cliente_id, tipo_id, monto, saldo_resultante, 
            descripcion, referencia
        ) VALUES (
            p_origen_id, v_tipo_id_enviada, p_monto, 
            v_origen_saldo - p_monto, 
            p_descripcion, v_referencia
        );
        
        -- Registrar transacción de recepción
        INSERT INTO transacciones (
            cliente_id, tipo_id, monto, saldo_resultante, 
            descripcion, referencia
        ) VALUES (
            p_destino_id, v_tipo_id_recibida, p_monto, 
            v_destino_saldo + p_monto, 
            p_descripcion, v_referencia
        );
        
        RETURN TRUE;
    EXCEPTION WHEN OTHERS THEN
        RAISE;
    END;
END;
$$ LANGUAGE plpgsql;

-- Crear una vista para el balance diario
CREATE VIEW v_balance_diario AS
SELECT 
    CAST(t.fecha AS DATE) AS fecha,
    SUM(CASE WHEN tp.nombre IN ('deposito', 'transferencia_recibida') THEN t.monto ELSE 0 END) AS ingresos,
    SUM(CASE WHEN tp.nombre IN ('retiro', 'transferencia_enviada') THEN t.monto ELSE 0 END) AS egresos,
    SUM(CASE WHEN tp.nombre IN ('deposito', 'transferencia_recibida') THEN t.monto ELSE -t.monto END) AS balance_neto
FROM transacciones t
JOIN tipos_transaccion tp ON t.tipo_id = tp.tipo_id
GROUP BY CAST(t.fecha AS DATE)
ORDER BY CAST(t.fecha AS DATE);