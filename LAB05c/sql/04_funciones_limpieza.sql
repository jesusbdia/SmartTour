-- =====================================================================
-- Lab 05c · Paso 17 · Funciones de limpieza y búsqueda de municipios
-- Ejecutar en pgAdmin: Query Tool de smarttour_db > pegar > F5
--
-- Creamos (en el esquema stg, porque son herramientas del ETL):
--   1. stg.arreglar_tildes(texto)   'Ãvila'          -> 'Ávila'
--   2. stg.normalizar(texto)        'Tiemblo (El)'   -> 'TIEMBLO EL'
--   3. stg.municipios_busqueda      tabla con los nombres normalizados
--   4. stg.buscar_municipio(provincia, nombre1, nombre2)  -> municipio_key
-- =====================================================================

-- unaccent quita las tildes: 'Ávila' -> 'Avila'. Viene incluida en PostgreSQL.
CREATE EXTENSION IF NOT EXISTS unaccent;

-- ---------------------------------------------------------------------
-- 1. Arreglar tildes rotas.
--    Los CSV del profesor son UTF-8, pero en algún momento se leyeron como
--    LATIN1 y se volvieron a guardar: 'Á' se convirtió en 'Ã' + otro carácter.
--    Deshacemos el error: lo pasamos a bytes LATIN1 y los leemos como UTF-8.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION stg.arreglar_tildes(texto TEXT)
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    IF texto IS NULL OR texto NOT LIKE '%Ã%' THEN
        RETURN texto;                       -- no está roto: se deja igual
    END IF;
    RETURN convert_from(convert_to(texto, 'LATIN1'), 'UTF8');
EXCEPTION WHEN OTHERS THEN
    RETURN texto;                           -- si no se puede arreglar, se deja igual
END;
$$;

-- ---------------------------------------------------------------------
-- 2. Normalizar un nombre para poder compararlo:
--    sin tildes, en mayúsculas, sin signos, y el artículo al final.
--    'La Adrada', 'ADRADA (LA)' y 'Adrada, La'  ->  'ADRADA LA'
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION stg.normalizar(texto TEXT)
RETURNS TEXT
LANGUAGE sql STABLE AS $$
    SELECT NULLIF(
        REGEXP_REPLACE(                                     -- 4) artículo inicial al final
            TRIM(REGEXP_REPLACE(                            -- 3) espacios repetidos -> uno
                REGEXP_REPLACE(                             -- 2) signos -> espacio
                    UPPER(unaccent(stg.arreglar_tildes(texto))),   -- 1) tildes y mayúsculas
                    '[^A-Z0-9 ]', ' ', 'g'),
                '\s+', ' ', 'g')),
            '^(EL|LA|LOS|LAS) (.+)$', '\2 \1'),
        '')
$$;

-- ---------------------------------------------------------------------
-- 3. Tabla de búsqueda: cada municipio y cada pedanía, ya normalizados.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS stg.municipios_busqueda;

CREATE TABLE stg.municipios_busqueda AS
-- los municipios
SELECT municipio_key,
       stg.normalizar(provincia) AS provincia_norm,
       stg.normalizar(nombre)    AS nombre_norm,
       FALSE                     AS es_pedania
FROM dim_municipio
WHERE municipio_key > 0
UNION ALL
-- las pedanías (Entidades Locales Menores): 'Candín' pertenece a 'VALLE DE ANCARES'
SELECT municipio_key,
       stg.normalizar(provincia),
       stg.normalizar(TRIM(p)),
       TRUE
FROM dim_municipio,
     UNNEST(STRING_TO_ARRAY(pedanias, ',')) AS p
WHERE pedanias IS NOT NULL;

CREATE INDEX ON stg.municipios_busqueda (provincia_norm, nombre_norm);
CREATE INDEX ON stg.municipios_busqueda (nombre_norm);

-- ---------------------------------------------------------------------
-- 4. Buscar el municipio_key de un nombre. Prueba, por orden:
--    a) provincia + nombre exacto
--    b) nombre exacto, si solo existe en una provincia
--    c) nombre que coincide con el principio o el final del oficial
--       ('Manjabálago' -> 'MANJABÁLAGO Y ORTIGOSA DE RIOALMAR')
--    d) pedanía de un municipio de esa provincia
--    Se le pueden pasar dos nombres (p. ej. municipio y localidad) y, si un
--    nombre lleva paréntesis ('Sedano (Valle de Sedano)'), prueba también
--    cada parte por separado. Si no encuentra nada devuelve 0 (DESCONOCIDO).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION stg.buscar_municipio(provincia TEXT, nombre1 TEXT, nombre2 TEXT DEFAULT NULL)
RETURNS INTEGER
LANGUAGE plpgsql STABLE AS $$
DECLARE
    prov       TEXT := stg.normalizar(provincia);
    candidatos TEXT[] := ARRAY[]::TEXT[];
    original   TEXT;
    n          TEXT;
    clave      INTEGER;
    partes     TEXT[];
BEGIN
    -- Lista de nombres a probar (con las partes de los paréntesis)
    FOREACH original IN ARRAY ARRAY[nombre1, nombre2] LOOP
        CONTINUE WHEN original IS NULL;
        candidatos := candidatos || original;
        partes := REGEXP_MATCH(stg.arreglar_tildes(original), '^(.*?)\s*\((.+)\)\s*$');
        IF partes IS NOT NULL AND stg.normalizar(partes[2]) NOT IN ('EL', 'LA', 'LOS', 'LAS') THEN
            candidatos := candidatos || partes[1] || partes[2];
        END IF;
    END LOOP;

    FOREACH original IN ARRAY candidatos LOOP
        n := stg.normalizar(original);
        CONTINUE WHEN n IS NULL;

        -- a) provincia + nombre
        SELECT municipio_key INTO clave FROM stg.municipios_busqueda
        WHERE NOT es_pedania AND provincia_norm = prov AND nombre_norm = n LIMIT 1;
        IF FOUND THEN RETURN clave; END IF;

        -- b) nombre único en toda la comunidad
        SELECT MIN(municipio_key) INTO clave FROM stg.municipios_busqueda
        WHERE NOT es_pedania AND nombre_norm = n
        HAVING COUNT(*) = 1;
        IF clave IS NOT NULL THEN RETURN clave; END IF;

        -- c) principio o final del nombre oficial (solo si hay uno)
        SELECT MIN(municipio_key) INTO clave FROM stg.municipios_busqueda
        WHERE NOT es_pedania AND provincia_norm = prov
          AND (nombre_norm LIKE n || ' %' OR nombre_norm LIKE '% ' || n)
        HAVING COUNT(*) = 1;
        IF clave IS NOT NULL THEN RETURN clave; END IF;

        -- d) pedanía (solo si pertenece a un único municipio)
        SELECT MIN(municipio_key) INTO clave FROM stg.municipios_busqueda
        WHERE es_pedania AND provincia_norm = prov AND nombre_norm = n
        HAVING COUNT(DISTINCT municipio_key) = 1;
        IF clave IS NOT NULL THEN RETURN clave; END IF;
    END LOOP;

    RETURN 0;
END;
$$;

-- ---------------------------------------------------------------------
-- Pruebas: cada fila debe mostrar el municipio correcto
-- ---------------------------------------------------------------------
SELECT prueba, m.nombre AS municipio_encontrado, m.provincia
FROM (VALUES
    ('Ãvila / Tiemblo (El)',            stg.buscar_municipio('Ãvila',  'Tiemblo (El)')),
    ('LeÃ³n / CandÃ­n (pedanía)',      stg.buscar_municipio('LeÃ³n',  'CandÃ­n')),
    ('Burgos / Sedano (Valle de Sedano)', stg.buscar_municipio('Burgos', 'Sedano (Valle de Sedano)')),
    ('Ávila / Manjabálago',             stg.buscar_municipio('Ávila',  'Manjabálago')),
    ('Madrid / Madrid (no es de CyL)',  stg.buscar_municipio('Madrid', 'Madrid'))
) AS t(prueba, clave)
JOIN dim_municipio m ON m.municipio_key = t.clave;
