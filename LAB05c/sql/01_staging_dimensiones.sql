-- =====================================================================
-- Lab 05c · Paso 14 · Staging de los datos de las dimensiones
-- Ejecutar en pgAdmin: clic derecho en smarttour_db > Query Tool > F5
--
-- Cargamos cada CSV TAL CUAL en una tabla de paso (esquema stg).
-- Todas las columnas son TEXT: así el COPY nunca falla por un dato raro.
-- La limpieza la haremos después, al pasar de stg a las dimensiones.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS stg;

-- Si repetimos el paso, empezamos de cero
DROP TABLE IF EXISTS stg.municipios, stg.hoteles, stg.monumentos, stg.oficinas;

-- ---------------------------------------------------------------------
-- 1. Municipios (13 columnas)
-- ---------------------------------------------------------------------
CREATE TABLE stg.municipios (
    municipio                 TEXT,
    cod_municipio             TEXT,
    provincia                 TEXT,
    cod_provincia             TEXT,
    cod_ine                   TEXT,
    poblacion                 TEXT,
    mancomunidades            TEXT,
    entidades_locales_menores TEXT,
    comarca                   TEXT,
    longitud                  TEXT,
    latitud                   TEXT,
    coordenada_x              TEXT,
    coordenada_y              TEXT
);

COPY stg.municipios
FROM '/smarttour/LAB05c/datasets/municipios/municipios.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ---------------------------------------------------------------------
-- 2. Hoteles (27 columnas)
-- ---------------------------------------------------------------------
CREATE TABLE stg.hoteles (
    establecimiento  TEXT,
    n_registro       TEXT,
    codigo           TEXT,
    tipo             TEXT,
    categoria        TEXT,
    especialidades   TEXT,
    clase            TEXT,
    nombre           TEXT,
    direccion        TEXT,
    c_postal         TEXT,
    provincia        TEXT,
    municipio        TEXT,
    localidad        TEXT,
    nucleo           TEXT,
    telefono_1       TEXT,
    telefono_2       TEXT,
    telefono_3       TEXT,
    email            TEXT,
    web              TEXT,
    q_calidad        TEXT,
    posada_real      TEXT,
    plazas           TEXT,
    gps_longitud     TEXT,
    gps_latitud      TEXT,
    accesible        TEXT,
    column_27        TEXT,
    posicion         TEXT
);

COPY stg.hoteles
FROM '/smarttour/LAB05c/datasets/hoteles/hoteles.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ---------------------------------------------------------------------
-- 3. Monumentos (18 columnas)
-- ---------------------------------------------------------------------
CREATE TABLE stg.monumentos (
    identificador         TEXT,
    nombre                TEXT,
    tipo_monumento        TEXT,
    id_bien_interes_cult  TEXT,
    calle                 TEXT,
    clasificacion         TEXT,
    tipo_construccion     TEXT,
    codigo_postal         TEXT,
    descripcion           TEXT,
    periodo_historico     TEXT,
    latitud               TEXT,
    longitud              TEXT,
    poblacion_provincia   TEXT,
    poblacion_municipio   TEXT,
    poblacion_localidad   TEXT,
    pto_geolocalizado     TEXT,
    poblacion             TEXT,
    coordenadas           TEXT
);

COPY stg.monumentos
FROM '/smarttour/LAB05c/datasets/monumentos/monumentos.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ---------------------------------------------------------------------
-- 4. Oficinas de turismo (7 columnas)
-- ---------------------------------------------------------------------
CREATE TABLE stg.oficinas (
    id_oficina      TEXT,
    provincia       TEXT,
    localidad       TEXT,
    tipo            TEXT,
    nombre          TEXT,
    establecimiento TEXT,
    ambito          TEXT
);

COPY stg.oficinas
FROM '/smarttour/LAB05c/datasets/oficinas_turismo/oficinas.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- ---------------------------------------------------------------------
-- Comprobación: filas cargadas (deben coincidir con los CSV)
-- ---------------------------------------------------------------------
SELECT 'municipios' AS tabla, COUNT(*) AS filas FROM stg.municipios
UNION ALL SELECT 'hoteles',    COUNT(*) FROM stg.hoteles
UNION ALL SELECT 'monumentos', COUNT(*) FROM stg.monumentos
UNION ALL SELECT 'oficinas',   COUNT(*) FROM stg.oficinas;
