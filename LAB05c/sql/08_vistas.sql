-- =====================================================================
-- Lab 05c · Paso 21 · Capa de vistas analíticas (para consultas y Power BI)
-- Ejecutar en pgAdmin: Query Tool de smarttour_db > pegar > F5
--
-- Son las consultas 1 a 10 del enunciado convertidas en vistas (CREATE VIEW),
-- más la comparación de los tres procesos (con CTE) y su mejora por mes,
-- tres vistas extra con datos que traen los CSV y una vista materializada.
--
-- Se agrupa siempre por la clave (municipio_key, hotel_key...) además de
-- por el nombre: hay municipios y monumentos con el mismo nombre que, si
-- no, se sumarían juntos.
-- =====================================================================

-- ---------------------------------------------------------------------
-- RESERVAS DE HOTEL
-- ---------------------------------------------------------------------

-- Consulta 1. Reservas por municipio
CREATE OR REPLACE VIEW vw_reservas_municipio AS
SELECT
    m.municipio_key,
    m.nombre AS municipio,
    m.provincia,
    COUNT(*) AS total_reservas
FROM fact_reservas_hotel r
JOIN dim_municipio m ON r.municipio_key = m.municipio_key
GROUP BY m.municipio_key, m.nombre, m.provincia;

-- Consulta 2. Turistas por provincia
CREATE OR REPLACE VIEW vw_turistas_provincia AS
SELECT
    m.provincia,
    SUM(r.turistas) AS total_turistas
FROM fact_reservas_hotel r
JOIN dim_municipio m ON r.municipio_key = m.municipio_key
GROUP BY m.provincia;

-- Consulta 3. Ingresos mensuales (por fecha de entrada: el fichero no trae fecha de reserva)
CREATE OR REPLACE VIEW vw_ingresos_mensuales AS
SELECT
    f.anio,
    f.mes,
    f.nombre_mes,
    SUM(r.importe) AS ingresos
FROM fact_reservas_hotel r
JOIN dim_fecha f ON r.fecha_entrada_key = f.fecha_key
GROUP BY f.anio, f.mes, f.nombre_mes;

-- Consulta 4. Turistas y estancia media por hotel
CREATE OR REPLACE VIEW vw_estancia_hoteles AS
SELECT
    h.hotel_key,
    h.nombre AS hotel,
    h.categoria,
    SUM(r.turistas) AS total_turistas,
    SUM(r.noches)   AS total_noches,
    ROUND(SUM(r.noches)::NUMERIC / NULLIF(COUNT(*), 0), 2) AS media_noches_reserva
FROM fact_reservas_hotel r
JOIN dim_hotel h ON r.hotel_key = h.hotel_key
GROUP BY h.hotel_key, h.nombre, h.categoria;

-- ---------------------------------------------------------------------
-- OFICINAS DE TURISMO
-- ---------------------------------------------------------------------

-- Consulta 5. Oficinas más visitadas
CREATE OR REPLACE VIEW vw_visitas_oficinas AS
SELECT
    o.oficina_key,
    o.nombre AS oficina,
    SUM(v.num_visitas) AS total_visitas
FROM fact_visitas_oficinas v
JOIN dim_oficina_turismo o ON v.oficina_key = o.oficina_key
GROUP BY o.oficina_key, o.nombre;

-- Consulta 6. Visitas a oficinas por municipio
CREATE OR REPLACE VIEW vw_visitas_oficinas_municipio AS
SELECT
    m.municipio_key,
    m.nombre AS municipio,
    m.provincia,
    SUM(v.num_visitas) AS total_visitas
FROM fact_visitas_oficinas v
JOIN dim_municipio m ON v.municipio_key = m.municipio_key
GROUP BY m.municipio_key, m.nombre, m.provincia;

-- Consulta 7. Evolución mensual de visitas a oficinas
CREATE OR REPLACE VIEW vw_visitas_oficinas_mensuales AS
SELECT
    f.anio,
    f.mes,
    f.nombre_mes,
    SUM(v.num_visitas) AS total_visitas
FROM fact_visitas_oficinas v
JOIN dim_fecha f ON v.fecha_key = f.fecha_key
GROUP BY f.anio, f.mes, f.nombre_mes;

-- ---------------------------------------------------------------------
-- MONUMENTOS
-- ---------------------------------------------------------------------

-- Consulta 8. Monumentos más visitados
CREATE OR REPLACE VIEW vw_monumentos_mas_visitados AS
SELECT
    m.monumento_key,
    m.nombre AS monumento,
    m.tipo,
    SUM(v.num_visitas) AS total_visitas
FROM fact_visitas_monumentos v
JOIN dim_monumento m ON v.monumento_key = m.monumento_key
GROUP BY m.monumento_key, m.nombre, m.tipo;

-- Consulta 9. Ingresos por monumento
CREATE OR REPLACE VIEW vw_ingresos_monumentos AS
SELECT
    m.monumento_key,
    m.nombre AS monumento,
    SUM(v.num_entradas)     AS entradas_vendidas,
    SUM(v.importe_entradas) AS ingresos
FROM fact_visitas_monumentos v
JOIN dim_monumento m ON v.monumento_key = m.monumento_key
GROUP BY m.monumento_key, m.nombre;

-- Consulta 10. Evolución mensual de visitas por monumento
CREATE OR REPLACE VIEW vw_visitas_monumentos_mensuales AS
SELECT
    m.monumento_key,
    m.nombre AS monumento,
    f.anio,
    f.mes,
    f.nombre_mes,
    SUM(v.num_visitas) AS visitas
FROM fact_visitas_monumentos v
JOIN dim_monumento m ON v.monumento_key = m.monumento_key
JOIN dim_fecha f     ON v.fecha_key = f.fecha_key
GROUP BY m.monumento_key, m.nombre, f.anio, f.mes, f.nombre_mes;

-- ---------------------------------------------------------------------
-- LOS TRES PROCESOS JUNTOS
-- Se agrega cada tabla de hechos por separado (CTE) y DESPUÉS se unen,
-- para no multiplicar filas al mezclar granularidades distintas.
-- ---------------------------------------------------------------------

-- Actividad turística total por municipio
CREATE OR REPLACE VIEW vw_actividad_turistica_municipio AS
WITH reservas AS (
    SELECT municipio_key,
           SUM(turistas) AS turistas_alojados,
           SUM(importe)  AS ingresos_hoteles
    FROM fact_reservas_hotel
    GROUP BY municipio_key
),
oficinas AS (
    SELECT municipio_key, SUM(num_visitas) AS visitas_oficinas
    FROM fact_visitas_oficinas
    GROUP BY municipio_key
),
monumentos AS (
    SELECT municipio_key, SUM(num_visitas) AS visitas_monumentos
    FROM fact_visitas_monumentos
    GROUP BY municipio_key
)
SELECT
    m.municipio_key,
    m.nombre AS municipio,
    m.provincia,
    COALESCE(r.turistas_alojados, 0)   AS turistas_alojados,
    COALESCE(r.ingresos_hoteles, 0)    AS ingresos_hoteles,
    COALESCE(o.visitas_oficinas, 0)    AS visitas_oficinas,
    COALESCE(mo.visitas_monumentos, 0) AS visitas_monumentos
FROM dim_municipio m
LEFT JOIN reservas   r  ON m.municipio_key = r.municipio_key
LEFT JOIN oficinas   o  ON m.municipio_key = o.municipio_key
LEFT JOIN monumentos mo ON m.municipio_key = mo.municipio_key;

-- Mejora (2ª versión): la misma comparación por municipio, año y mes
CREATE OR REPLACE VIEW vw_actividad_turistica_municipio_mes AS
WITH reservas AS (
    SELECT r.municipio_key, f.anio, f.mes,
           SUM(r.turistas) AS turistas_alojados,
           SUM(r.importe)  AS ingresos_hoteles
    FROM fact_reservas_hotel r
    JOIN dim_fecha f ON r.fecha_entrada_key = f.fecha_key
    GROUP BY r.municipio_key, f.anio, f.mes
),
oficinas AS (
    SELECT v.municipio_key, f.anio, f.mes, SUM(v.num_visitas) AS visitas_oficinas
    FROM fact_visitas_oficinas v
    JOIN dim_fecha f ON v.fecha_key = f.fecha_key
    GROUP BY v.municipio_key, f.anio, f.mes
),
monumentos AS (
    SELECT v.municipio_key, f.anio, f.mes, SUM(v.num_visitas) AS visitas_monumentos
    FROM fact_visitas_monumentos v
    JOIN dim_fecha f ON v.fecha_key = f.fecha_key
    GROUP BY v.municipio_key, f.anio, f.mes
),
periodos AS (               -- todas las combinaciones municipio-mes con alguna actividad
    SELECT municipio_key, anio, mes FROM reservas
    UNION SELECT municipio_key, anio, mes FROM oficinas
    UNION SELECT municipio_key, anio, mes FROM monumentos
)
SELECT
    m.municipio_key,
    m.nombre AS municipio,
    m.provincia,
    p.anio,
    p.mes,
    COALESCE(r.turistas_alojados, 0)   AS turistas_alojados,
    COALESCE(r.ingresos_hoteles, 0)    AS ingresos_hoteles,
    COALESCE(o.visitas_oficinas, 0)    AS visitas_oficinas,
    COALESCE(mo.visitas_monumentos, 0) AS visitas_monumentos
FROM periodos p
JOIN dim_municipio m    ON p.municipio_key = m.municipio_key
LEFT JOIN reservas   r  ON r.municipio_key  = p.municipio_key AND r.anio  = p.anio AND r.mes  = p.mes
LEFT JOIN oficinas   o  ON o.municipio_key  = p.municipio_key AND o.anio  = p.anio AND o.mes  = p.mes
LEFT JOIN monumentos mo ON mo.municipio_key = p.municipio_key AND mo.anio = p.anio AND mo.mes = p.mes;

-- ---------------------------------------------------------------------
-- EXTRA: aprovechan columnas que traen los datos del laboratorio
-- ---------------------------------------------------------------------

-- Reservas e ingresos por canal de venta
CREATE OR REPLACE VIEW vw_reservas_canal AS
SELECT
    canal,
    COUNT(*)                      AS total_reservas,
    SUM(importe)                  AS ingresos,
    ROUND(AVG(precio_noche), 2)   AS precio_medio_noche
FROM fact_reservas_hotel
GROUP BY canal;

-- Turistas por país de origen y tipo de viajero
CREATE OR REPLACE VIEW vw_reservas_origen AS
SELECT
    v.pais_origen,
    v.tipo_viajero,
    COUNT(*)        AS total_reservas,
    SUM(r.turistas) AS total_turistas,
    SUM(r.importe)  AS ingresos
FROM fact_reservas_hotel r
JOIN dim_viajero v ON r.viajero_key = v.viajero_key
GROUP BY v.pais_origen, v.tipo_viajero;

-- Motivos de consulta en las oficinas de turismo
CREATE OR REPLACE VIEW vw_oficinas_motivo AS
SELECT
    motivo,
    COUNT(*)         AS consultas,
    SUM(num_visitas) AS visitantes
FROM fact_visitas_oficinas
GROUP BY motivo;

-- ---------------------------------------------------------------------
-- VISTA MATERIALIZADA (guarda el resultado; hay que refrescarla)
-- ---------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS mv_visitas_monumentos;
CREATE MATERIALIZED VIEW mv_visitas_monumentos AS
SELECT
    m.monumento_key,
    m.nombre AS monumento,
    SUM(v.num_visitas) AS total_visitas
FROM fact_visitas_monumentos v
JOIN dim_monumento m ON v.monumento_key = m.monumento_key
GROUP BY m.monumento_key, m.nombre;

CREATE INDEX idx_mv_monumentos ON mv_visitas_monumentos (monumento);

-- Para actualizarla cuando cambien los datos:
-- REFRESH MATERIALIZED VIEW mv_visitas_monumentos;

-- =====================================================================
-- Comprobación: vistas creadas y un ejemplo de uso
-- =====================================================================
SELECT municipio, provincia, turistas_alojados, ingresos_hoteles, visitas_oficinas, visitas_monumentos
FROM vw_actividad_turistica_municipio
ORDER BY turistas_alojados DESC
LIMIT 5;
