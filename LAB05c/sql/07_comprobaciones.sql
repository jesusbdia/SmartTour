-- =====================================================================
-- Lab 05c · Paso 20 · Comprobar claves foráneas e integridad de los datos
-- Ejecutar en pgAdmin: Query Tool de smarttour_db > pegar > F5
--
-- Devuelve una tabla: cada comprobación con su resultado y el valor esperado.
-- Si resultado = esperado en todas las filas, el Data Warehouse está bien.
-- =====================================================================

SELECT comprobacion, resultado, esperado,
       CASE WHEN resultado = esperado THEN 'OK' ELSE 'REVISAR' END AS estado
FROM (

    -- 1. Claves foráneas definidas: reservas 5 + oficinas 3 + monumentos 3 = 11
    SELECT 1 AS orden, 'Claves foráneas definidas en los hechos' AS comprobacion,
           (SELECT COUNT(*) FROM information_schema.table_constraints
            WHERE constraint_type = 'FOREIGN KEY' AND table_name LIKE 'fact_%')::TEXT AS resultado,
           '11' AS esperado

    -- 2. Hechos huérfanos: claves que no existen en su dimensión
    UNION ALL
    SELECT 2, 'Reservas con hotel inexistente',
           (SELECT COUNT(*) FROM fact_reservas_hotel r
            LEFT JOIN dim_hotel h ON h.hotel_key = r.hotel_key WHERE h.hotel_key IS NULL)::TEXT, '0'
    UNION ALL
    SELECT 3, 'Visitas a oficinas con oficina inexistente',
           (SELECT COUNT(*) FROM fact_visitas_oficinas v
            LEFT JOIN dim_oficina_turismo o ON o.oficina_key = v.oficina_key WHERE o.oficina_key IS NULL)::TEXT, '0'
    UNION ALL
    SELECT 4, 'Visitas a monumentos con monumento inexistente',
           (SELECT COUNT(*) FROM fact_visitas_monumentos v
            LEFT JOIN dim_monumento m ON m.monumento_key = v.monumento_key WHERE m.monumento_key IS NULL)::TEXT, '0'

    -- 3. Coherencia: un mismo hotel/oficina/monumento siempre en el mismo municipio
    UNION ALL
    SELECT 5, 'Hoteles con reservas en más de un municipio',
           (SELECT COUNT(*) FROM (SELECT hotel_key FROM fact_reservas_hotel
             GROUP BY hotel_key HAVING COUNT(DISTINCT municipio_key) > 1) x)::TEXT, '0'
    UNION ALL
    SELECT 6, 'Oficinas con visitas en más de un municipio',
           (SELECT COUNT(*) FROM (SELECT oficina_key FROM fact_visitas_oficinas
             GROUP BY oficina_key HAVING COUNT(DISTINCT municipio_key) > 1) x)::TEXT, '0'
    UNION ALL
    SELECT 7, 'Monumentos con visitas en más de un municipio',
           (SELECT COUNT(*) FROM (SELECT monumento_key FROM fact_visitas_monumentos
             GROUP BY monumento_key HAVING COUNT(DISTINCT municipio_key) > 1) x)::TEXT, '0'

    -- 4. Coherencia de las medidas
    UNION ALL
    SELECT 8, 'Reservas con noches distintas a (salida - entrada)',
           (SELECT COUNT(*) FROM fact_reservas_hotel r
            JOIN dim_fecha e ON e.fecha_key = r.fecha_entrada_key
            JOIN dim_fecha s ON s.fecha_key = r.fecha_salida_key
            WHERE s.fecha - e.fecha <> r.noches)::TEXT, '0'
    UNION ALL
    SELECT 9, 'Reservas con importe distinto a noches x precio',
           (SELECT COUNT(*) FROM fact_reservas_hotel
            WHERE ABS(importe - noches * precio_noche) > 0.02)::TEXT, '0'
    UNION ALL
    SELECT 10, 'Monumentos con entradas + gratuitas distinto a visitas',
           (SELECT COUNT(*) FROM fact_visitas_monumentos
            WHERE num_entradas + num_visitas_gratuitas <> num_visitas)::TEXT, '0'

    -- 5. Hechos con municipio desconocido (municipio_key = 0)
    UNION ALL
    SELECT 11, 'Reservas con municipio desconocido',
           (SELECT COUNT(*) FROM fact_reservas_hotel WHERE municipio_key = 0)::TEXT, '0'
    UNION ALL
    SELECT 12, 'Visitas a oficinas con municipio desconocido (oficina de Madrid)',
           (SELECT COUNT(*) FROM fact_visitas_oficinas WHERE municipio_key = 0)::TEXT,
           (SELECT COUNT(*) FROM fact_visitas_oficinas v
            JOIN dim_oficina_turismo o ON o.oficina_key = v.oficina_key
            WHERE o.provincia = 'Madrid')::TEXT
    UNION ALL
    SELECT 13, 'Monumentos sin municipio identificado (debe ser 1)',
           (SELECT COUNT(DISTINCT monumento_key) FROM fact_visitas_monumentos WHERE municipio_key = 0)::TEXT,
           '1'

) AS c
ORDER BY orden;

-- ---------------------------------------------------------------------
-- Detalle (opcional): qué clave foránea apunta a qué dimensión
-- Selecciona solo esta consulta y pulsa F5 para verla.
-- ---------------------------------------------------------------------
-- SELECT tc.table_name AS tabla_hechos, kcu.column_name AS columna, ccu.table_name AS dimension
-- FROM information_schema.table_constraints tc
-- JOIN information_schema.key_column_usage kcu ON kcu.constraint_name = tc.constraint_name
-- JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY'
-- ORDER BY 1, 2;
