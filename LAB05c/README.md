# Lab 05c · Data Warehouse SmartTour en PostgreSQL

Base de datos `smarttour_db` (contenedor `smarttour-postgres`). Datos: `datasets.zip` del profesor, descomprimido en `LAB05c/datasets/`.

## Modelo: constelación de hechos

Tres tablas de hechos que comparten `dim_fecha` y `dim_municipio`. Las dimensiones son independientes entre sí (modelo en estrella): hotel, monumento y oficina no tienen clave foránea a municipio. Cada hecho guarda directamente su `municipio_key`.

| Tabla | Tipo | Filas | Granularidad | Origen |
|---|---|---|---|---|
| `dim_fecha` | Dimensión | 730 | 1 día (2025-2026) | Generada con `generate_series` |
| `dim_municipio` | Dimensión | 2.249 | 1 municipio + fila 0 «DESCONOCIDO» | `municipios/municipios.csv` |
| `dim_hotel` | Dimensión | 2.378 | 1 alojamiento (con columnas SCD 2) | `hoteles/hoteles.csv` |
| `dim_monumento` | Dimensión | 1.374 | 1 monumento | `monumentos/monumentos.csv` |
| `dim_oficina_turismo` | Dimensión | 263 | 1 oficina | `oficinas_turismo/oficinas.csv` |
| `dim_viajero` | Dimensión | 10.000 | 1 viajero | `hechos/viajeros.csv` |
| `fact_reservas_hotel` | Hechos | 17.838 | 1 reserva | `hechos/reservas_hoteles.csv` |
| `fact_visitas_oficinas` | Hechos | 12.000 | 1 visita registrada | `hechos/visitas_oficinas_turismo.csv` |
| `fact_visitas_monumentos` | Hechos | 60.000 | 1 visita registrada | `hechos/visitas_monumentos.csv` |

Claves foráneas de los hechos (11):

- `fact_reservas_hotel` → `dim_fecha` (entrada y salida), `dim_hotel`, `dim_viajero`, `dim_municipio`
- `fact_visitas_oficinas` → `dim_fecha`, `dim_oficina_turismo`, `dim_municipio`
- `fact_visitas_monumentos` → `dim_fecha`, `dim_monumento`, `dim_municipio`

## Cómo se construye (carpeta `sql/`, en este orden, en la Query Tool de `smarttour_db`)

| Paso | Archivo | Qué hace |
|---|---|---|
| 14 | `01_staging_dimensiones.sql` | `COPY` de municipios, hoteles, monumentos y oficinas al esquema `stg` (todo TEXT) |
| 15 | `02_staging_hechos.sql` | `COPY` de viajeros, reservas y visitas al esquema `stg` |
| 16 | `03_dim_fecha_municipio.sql` | Crea `dim_fecha` (generada) y `dim_municipio` |
| 17 | `04_funciones_limpieza.sql` | Funciones `stg.arreglar_tildes`, `stg.normalizar` y `stg.buscar_municipio` |
| 18 | `05_dim_hotel_monumento_oficina_viajero.sql` | Resto de dimensiones + tablas `stg.mapa_*` (municipio de cada una) |
| 19 | `06_hechos.sql` | Crea y carga las 3 tablas de hechos con sus claves foráneas |
| 20 | `07_comprobaciones.sql` | 13 comprobaciones de integridad (todas OK) |
| 21 | `08_vistas.sql` | 15 vistas analíticas + 1 vista materializada |

pgAdmin no ve las carpetas de Windows en *Open File*: se abre cada `.sql` con el Bloc de notas y se pega en la Query Tool.

## Decisiones de diseño

1. **Dimensiones independientes (opción B, estrella).** Un solo JOIN para analizar por municipio. La coherencia la garantiza el ETL: está comprobado que cada hotel, oficina y monumento va siempre con el mismo municipio.
2. **Claves sustitutas** (`*_key`) generadas por PostgreSQL (`IDENTITY`). Las claves de los CSV se guardan como atributos (`hotel_id`, `monumento_id`, `oficina_id`, `viajero_id`).
3. **Staging + ETL en SQL.** Los CSV se cargan tal cual en `stg` y se limpian con `INSERT ... SELECT`. Si algo falla no hay que volver a leer los ficheros.
4. **Miembro desconocido** `municipio_key = 0`. Se usa para la oficina de Castilla y León en Madrid y para el «Castro de la Loma», que no trae municipio.
5. **Granularidad del origen.** Las visitas se guardan una por registro, no agregadas por día, para no perder el motivo y el tipo de visitante.
6. **Sin fecha de reserva.** El fichero solo trae entrada y salida, así que `dim_fecha` se usa con esos dos papeles.

## Problemas de calidad de los datos y solución

| Problema | Afecta a | Solución |
|---|---|---|
| Tildes rotas («Ãvila») | hoteles, monumentos, oficinas | `stg.arreglar_tildes`: se convierte a bytes LATIN1 y se lee como UTF-8 |
| Municipio escrito de otra forma («Tiemblo (El)», «Sedano (Valle de Sedano)», pedanías como «Candín») | hoteles, monumentos, oficinas | `stg.buscar_municipio`: provincia + nombre normalizado, partes del paréntesis, principio o final del nombre y pedanías. Resultado: hoteles 100 %, monumentos 99,9 %, oficinas 99,6 % |
| N.º de registro repetido entre hotel y casa rural (149) | hoteles / reservas | `dim_hotel` guarda `establecimiento`. Las reservas se asignan al «Alojamientos Hoteleros» |
| Monumento repetido con dos tipos (4) | monumentos | Una fila con el tipo concreto + `es_real_sitio` |
| Código postal como decimal (`5001.0`) | monumentos | Texto de 5 dígitos (`05001`) |
| Coma decimal en coordenadas (`-4,603775`) | municipios | Conversión a `NUMERIC` |
| Categoría escrita de varias formas | hoteles | Columna `estrellas` numérica |

## Vistas (`08_vistas.sql`)

| Vista | Pregunta |
|---|---|
| `vw_reservas_municipio` | Reservas por municipio |
| `vw_turistas_provincia` | Turistas por provincia |
| `vw_ingresos_mensuales` | Ingresos por mes (de entrada) |
| `vw_estancia_hoteles` | Turistas y estancia media por hotel |
| `vw_visitas_oficinas` | Oficinas más visitadas |
| `vw_visitas_oficinas_municipio` | Visitas a oficinas por municipio |
| `vw_visitas_oficinas_mensuales` | Evolución mensual de las oficinas |
| `vw_monumentos_mas_visitados` | Monumentos más visitados |
| `vw_ingresos_monumentos` | Ingresos por entradas |
| `vw_visitas_monumentos_mensuales` | Evolución mensual por monumento |
| `vw_actividad_turistica_municipio` | Los tres procesos por municipio (CTE) |
| `vw_actividad_turistica_municipio_mes` | Los tres procesos por municipio y mes |
| `vw_reservas_canal` | Reservas por canal de venta |
| `vw_reservas_origen` | Reservas por país y tipo de viajero |
| `vw_oficinas_motivo` | Motivos de consulta en las oficinas |
| `mv_visitas_monumentos` | Vista materializada (`REFRESH MATERIALIZED VIEW` para actualizar) |

Los 5 municipios con más turistas alojados son Salamanca (1.929), Burgos (1.718), León (1.468), Segovia (1.054) y Valladolid (1.029).

## Copia de seguridad

```powershell
docker exec smarttour-postgres pg_dump -U smarttour -d smarttour_db -Fc -f /smarttour/backups/smarttour_db_lab05c.dump
```

Para restaurarla:

```powershell
docker exec smarttour-postgres pg_restore -U smarttour -d smarttour_db --clean /smarttour/backups/smarttour_db_lab05c.dump
```
