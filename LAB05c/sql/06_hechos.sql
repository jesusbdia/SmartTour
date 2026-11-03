-- =====================================================================
-- Lab 05c · Paso 19 · Tablas de hechos
--   fact_reservas_hotel, fact_visitas_oficinas, fact_visitas_monumentos
-- Ejecutar en pgAdmin: Query Tool de smarttour_db > pegar > F5
--
-- Cada hecho guarda las claves (*_key) de sus dimensiones, nunca los
-- identificadores de los CSV. Para traducirlos usamos las dimensiones
-- y las tablas stg.mapa_* (que además dan el municipio_key).
--
-- Diferencias con el diseño del enunciado, por cómo vienen los datos:
--   - Las reservas NO traen fecha de reserva: solo entrada y salida.
--   - Las visitas vienen una por registro (id_visita), no agregadas por día:
--     mantenemos ese detalle (granularidad = 1 visita registrada).
-- =====================================================================

-- CASCADE borra también las vistas que dependen de los hechos: después hay que repetir el paso 21 (08_vistas.sql)
DROP TABLE IF EXISTS fact_reservas_hotel, fact_visitas_oficinas, fact_visitas_monumentos CASCADE;

-- =====================================================================
-- 1. fact_reservas_hotel  (granularidad: 1 fila = 1 reserva)
-- =====================================================================
CREATE TABLE fact_reservas_hotel (
    reserva_id        BIGINT PRIMARY KEY,
    fecha_entrada_key INTEGER NOT NULL REFERENCES dim_fecha (fecha_key),
    fecha_salida_key  INTEGER NOT NULL REFERENCES dim_fecha (fecha_key),
    hotel_key         INTEGER NOT NULL REFERENCES dim_hotel (hotel_key),
    viajero_key       INTEGER NOT NULL REFERENCES dim_viajero (viajero_key),
    municipio_key     INTEGER NOT NULL REFERENCES dim_municipio (municipio_key),
    canal             VARCHAR(20),                 -- Web, Telefono, OTA, Agencia, Recepcion
    turistas          INTEGER       NOT NULL CHECK (turistas > 0),
    noches            INTEGER       NOT NULL CHECK (noches > 0),
    precio_noche      NUMERIC(10,2) NOT NULL CHECK (precio_noche >= 0),
    importe           NUMERIC(12,2) NOT NULL CHECK (importe >= 0),
    num_reservas      INTEGER       NOT NULL DEFAULT 1,
    CHECK (fecha_salida_key > fecha_entrada_key)
);

-- El id_hotel de las reservas es el N.Registro, que se repite entre un hotel y
-- una casa rural (149 casos). Como el fichero es de reservas de HOTELES, ante
-- la duda nos quedamos con el 'Alojamientos Hoteleros'.
INSERT INTO fact_reservas_hotel
SELECT
    r.id_reserva::BIGINT,
    TO_CHAR(r.fecha_checkin::DATE,  'YYYYMMDD')::INTEGER,
    TO_CHAR(r.fecha_checkout::DATE, 'YYYYMMDD')::INTEGER,
    h.hotel_key,
    v.viajero_key,
    h.municipio_key,
    r.canal,
    r.num_huespedes::INTEGER,
    r.noches::INTEGER,
    r.precio_noche::NUMERIC(10,2),
    r.total::NUMERIC(12,2),
    1
FROM stg.reservas_hoteles r
JOIN (SELECT DISTINCT ON (hotel_id) hotel_id, hotel_key, municipio_key
      FROM stg.mapa_hotel
      ORDER BY hotel_id, (establecimiento <> 'Alojamientos Hoteleros')   -- FALSE primero = hotel
     ) h ON h.hotel_id = r.id_hotel
JOIN dim_viajero v ON v.viajero_id = r.id_viajero::INTEGER;

-- =====================================================================
-- 2. fact_visitas_oficinas  (granularidad: 1 fila = 1 visita registrada)
-- =====================================================================
CREATE TABLE fact_visitas_oficinas (
    visita_id      BIGINT PRIMARY KEY,
    fecha_key      INTEGER NOT NULL REFERENCES dim_fecha (fecha_key),
    oficina_key    INTEGER NOT NULL REFERENCES dim_oficina_turismo (oficina_key),
    municipio_key  INTEGER NOT NULL REFERENCES dim_municipio (municipio_key),
    motivo         VARCHAR(30),                    -- Informacion, Folletos, Reservas, Reclamacion, Otro
    num_visitas    INTEGER NOT NULL CHECK (num_visitas >= 0),   -- personas atendidas
    num_consultas  INTEGER NOT NULL DEFAULT 1                   -- cada registro = 1 consulta
);

INSERT INTO fact_visitas_oficinas
SELECT
    vo.id_visita::BIGINT,
    TO_CHAR(vo.fecha::DATE, 'YYYYMMDD')::INTEGER,
    o.oficina_key,
    o.municipio_key,
    vo.motivo,
    vo.num_visitantes::INTEGER,
    1
FROM stg.visitas_oficinas vo
JOIN stg.mapa_oficina o ON o.oficina_id = vo.id_oficina::INTEGER;

-- =====================================================================
-- 3. fact_visitas_monumentos  (granularidad: 1 fila = 1 visita registrada)
--    precio_entrada es por persona; si es 0, la visita es gratuita.
-- =====================================================================
CREATE TABLE fact_visitas_monumentos (
    visita_id             BIGINT PRIMARY KEY,
    fecha_key             INTEGER NOT NULL REFERENCES dim_fecha (fecha_key),
    monumento_key         INTEGER NOT NULL REFERENCES dim_monumento (monumento_key),
    municipio_key         INTEGER NOT NULL REFERENCES dim_municipio (municipio_key),
    tipo_visitante        VARCHAR(20),             -- Individual, Grupo, Escolar, Jubilado
    precio_entrada        NUMERIC(8,2)  NOT NULL CHECK (precio_entrada >= 0),
    num_visitas           INTEGER       NOT NULL CHECK (num_visitas >= 0),
    num_entradas          INTEGER       NOT NULL CHECK (num_entradas >= 0),          -- de pago
    num_visitas_gratuitas INTEGER       NOT NULL CHECK (num_visitas_gratuitas >= 0),
    importe_entradas      NUMERIC(12,2) NOT NULL CHECK (importe_entradas >= 0)
);

INSERT INTO fact_visitas_monumentos
SELECT
    vm.id_visita::BIGINT,
    TO_CHAR(vm.fecha::DATE, 'YYYYMMDD')::INTEGER,
    m.monumento_key,
    m.municipio_key,
    vm.tipo_visitante,
    vm.precio_entrada::NUMERIC(8,2),
    vm.num_visitantes::INTEGER,
    CASE WHEN vm.precio_entrada::NUMERIC > 0 THEN vm.num_visitantes::INTEGER ELSE 0 END,
    CASE WHEN vm.precio_entrada::NUMERIC = 0 THEN vm.num_visitantes::INTEGER ELSE 0 END,
    vm.num_visitantes::INTEGER * vm.precio_entrada::NUMERIC
FROM stg.visitas_monumentos vm
JOIN stg.mapa_monumento m ON m.monumento_id = vm.id_monumento::INTEGER;

-- Índices en las claves foráneas más usadas en los JOIN
CREATE INDEX ON fact_reservas_hotel (municipio_key);
CREATE INDEX ON fact_reservas_hotel (hotel_key);
CREATE INDEX ON fact_reservas_hotel (fecha_entrada_key);
CREATE INDEX ON fact_visitas_oficinas (municipio_key);
CREATE INDEX ON fact_visitas_oficinas (oficina_key);
CREATE INDEX ON fact_visitas_oficinas (fecha_key);
CREATE INDEX ON fact_visitas_monumentos (municipio_key);
CREATE INDEX ON fact_visitas_monumentos (monumento_key);
CREATE INDEX ON fact_visitas_monumentos (fecha_key);

-- =====================================================================
-- Comprobación: filas en staging vs. filas cargadas (deben coincidir)
-- =====================================================================
SELECT 'fact_reservas_hotel' AS hechos,
       (SELECT COUNT(*) FROM stg.reservas_hoteles) AS filas_csv,
       COUNT(*) AS filas_cargadas
FROM fact_reservas_hotel
UNION ALL
SELECT 'fact_visitas_oficinas', (SELECT COUNT(*) FROM stg.visitas_oficinas), COUNT(*)
FROM fact_visitas_oficinas
UNION ALL
SELECT 'fact_visitas_monumentos', (SELECT COUNT(*) FROM stg.visitas_monumentos), COUNT(*)
FROM fact_visitas_monumentos;
