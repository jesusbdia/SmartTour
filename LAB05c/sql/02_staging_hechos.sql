-- =====================================================================
-- Lab 05c · Paso 15 · Staging de los datos de hechos (carpeta hechos/)
-- Ejecutar en pgAdmin: Query Tool de smarttour_db > pegar > F5
--
-- Igual que en el paso 14: cada CSV tal cual, todo TEXT, en el esquema stg.
-- =====================================================================

DROP TABLE IF EXISTS stg.viajeros, stg.reservas_hoteles, stg.visitas_oficinas, stg.visitas_monumentos;

-- ---------------------------------------------------------------------
-- 1. Viajeros (7 columnas) -> será la dimensión dim_viajero
-- ---------------------------------------------------------------------
CREATE TABLE stg.viajeros (
    id_viajero     TEXT,
    nombre         TEXT,
    apellido       TEXT,
    pais_origen    TEXT,
    edad           TEXT,
    tipo_viajero   TEXT,
    fecha_registro TEXT
);

COPY stg.viajeros
FROM '/smarttour/LAB05c/datasets/hechos/viajeros.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ---------------------------------------------------------------------
-- 2. Reservas de hoteles (10 columnas) -> fact_reservas_hotel
-- ---------------------------------------------------------------------
CREATE TABLE stg.reservas_hoteles (
    id_reserva     TEXT,
    id_viajero     TEXT,
    id_hotel       TEXT,     -- es el N.Registro del hotel (p. ej. 05/000758)
    fecha_checkin  TEXT,
    fecha_checkout TEXT,
    noches         TEXT,
    num_huespedes  TEXT,
    precio_noche   TEXT,
    total          TEXT,
    canal          TEXT
);

COPY stg.reservas_hoteles
FROM '/smarttour/LAB05c/datasets/hechos/reservas_hoteles.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ---------------------------------------------------------------------
-- 3. Visitas a oficinas de turismo (5 columnas) -> fact_visitas_oficinas
-- ---------------------------------------------------------------------
CREATE TABLE stg.visitas_oficinas (
    id_visita      TEXT,
    id_oficina     TEXT,
    fecha          TEXT,
    num_visitantes TEXT,
    motivo         TEXT
);

COPY stg.visitas_oficinas
FROM '/smarttour/LAB05c/datasets/hechos/visitas_oficinas_turismo.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ---------------------------------------------------------------------
-- 4. Visitas a monumentos (6 columnas) -> fact_visitas_monumentos
-- ---------------------------------------------------------------------
CREATE TABLE stg.visitas_monumentos (
    id_visita      TEXT,
    id_monumento   TEXT,     -- es el identificador del monumento
    fecha          TEXT,
    num_visitantes TEXT,
    precio_entrada TEXT,
    tipo_visitante TEXT
);

COPY stg.visitas_monumentos
FROM '/smarttour/LAB05c/datasets/hechos/visitas_monumentos.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ---------------------------------------------------------------------
-- Comprobación: filas cargadas (deben coincidir con los CSV)
-- ---------------------------------------------------------------------
SELECT 'viajeros' AS tabla, COUNT(*) AS filas FROM stg.viajeros
UNION ALL SELECT 'reservas_hoteles',   COUNT(*) FROM stg.reservas_hoteles
UNION ALL SELECT 'visitas_oficinas',   COUNT(*) FROM stg.visitas_oficinas
UNION ALL SELECT 'visitas_monumentos', COUNT(*) FROM stg.visitas_monumentos;
