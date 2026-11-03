--
-- PostgreSQL database cluster dump
--

\restrict f7dxmaSC7cJUsqYevAVbdHBigsm4kC5FGqC4iQby9hGSP4JMUMCP0ebYHTaA8C5

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE usuario;
ALTER ROLE usuario WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:TlebUvIL8TbuiCkF5VX0NA==$9ZEtXSie/AzhMpUDFNumKdr2TmmKTitG/HqnRI3SRvc=:0ddmc14ejS8WiC+eA7fvYvgKKDNal21PHEFOnXjsKLM=';

--
-- User Configurations
--








\unrestrict f7dxmaSC7cJUsqYevAVbdHBigsm4kC5FGqC4iQby9hGSP4JMUMCP0ebYHTaA8C5

--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

\restrict M6lhG2TSHfOffPhvoURldKj5Vuj2sdH88wxKjHOxONmrmRWkAhCH8npbm6IDPW1

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6 (Debian 18.6-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- PostgreSQL database dump complete
--

\unrestrict M6lhG2TSHfOffPhvoURldKj5Vuj2sdH88wxKjHOxONmrmRWkAhCH8npbm6IDPW1

--
-- Database "bbdd_prueba" dump
--

--
-- PostgreSQL database dump
--

\restrict SPfvmDJcwSkCP6ki4drDYcbGIGbwU1yx7jIbgu1lk9fBlYLZC73T1Xs8OrevWR2

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6 (Debian 18.6-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: bbdd_prueba; Type: DATABASE; Schema: -; Owner: usuario
--

CREATE DATABASE bbdd_prueba WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE bbdd_prueba OWNER TO usuario;

\unrestrict SPfvmDJcwSkCP6ki4drDYcbGIGbwU1yx7jIbgu1lk9fBlYLZC73T1Xs8OrevWR2
\connect bbdd_prueba
\restrict SPfvmDJcwSkCP6ki4drDYcbGIGbwU1yx7jIbgu1lk9fBlYLZC73T1Xs8OrevWR2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alumnos; Type: TABLE; Schema: public; Owner: usuario
--

CREATE TABLE public.alumnos (
    id_alumno integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellidos character varying(150) NOT NULL
);


ALTER TABLE public.alumnos OWNER TO usuario;

--
-- Name: alumnos_id_alumno_seq; Type: SEQUENCE; Schema: public; Owner: usuario
--

ALTER TABLE public.alumnos ALTER COLUMN id_alumno ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.alumnos_id_alumno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notas; Type: TABLE; Schema: public; Owner: usuario
--

CREATE TABLE public.notas (
    id_nota integer NOT NULL,
    id_alumno integer NOT NULL,
    asignatura character varying(100) NOT NULL,
    nota numeric(4,2) NOT NULL,
    CONSTRAINT notas_nota_check CHECK (((nota >= (0)::numeric) AND (nota <= (10)::numeric)))
);


ALTER TABLE public.notas OWNER TO usuario;

--
-- Name: notas_id_nota_seq; Type: SEQUENCE; Schema: public; Owner: usuario
--

ALTER TABLE public.notas ALTER COLUMN id_nota ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.notas_id_nota_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: alumnos; Type: TABLE DATA; Schema: public; Owner: usuario
--

COPY public.alumnos (id_alumno, nombre, apellidos) FROM stdin;
1	Lucía	Fernández Gómez
2	Marcos	Ruiz Delgado
3	Ainhoa	Torres Navarro
4	Hugo	Martín Serrano
5	Carmen	Jiménez Ortega
6	Pablo	López Iglesias
7	Noelia	García Benítez
8	Iván	Sánchez Molina
9	Rosa	Álvarez Cabrera
10	Sergio	Moreno Pascual
11	Elena	Vidal Quintana
12	Adrián	Romero Campos
13	Patricia	Suárez Lozano
14	Daniel	Pérez Aguilar
15	Marta	Blanco Ríos
16	Javier	Castro Peña
17	Sara	Ortiz Fuentes
18	Óscar	Ramos Herrera
19	Julia	Medina Cano
20	Andrés	Guerrero Salas
\.


--
-- Data for Name: notas; Type: TABLE DATA; Schema: public; Owner: usuario
--

COPY public.notas (id_nota, id_alumno, asignatura, nota) FROM stdin;
1	1	Big Data	8.75
2	1	Bases de Datos	7.50
3	2	Big Data	6.25
4	2	Bases de Datos	5.90
5	3	Big Data	9.10
6	3	Bases de Datos	8.40
7	4	Big Data	4.80
8	4	Bases de Datos	6.00
9	5	Big Data	7.35
10	5	Bases de Datos	7.80
11	6	Big Data	9.60
12	6	Bases de Datos	9.25
13	7	Big Data	5.50
14	7	Bases de Datos	4.75
15	8	Big Data	6.80
16	8	Bases de Datos	7.10
17	9	Big Data	8.00
18	9	Bases de Datos	8.55
19	10	Big Data	3.90
20	10	Bases de Datos	5.20
21	11	Big Data	7.95
22	11	Bases de Datos	8.30
23	12	Big Data	6.40
24	12	Bases de Datos	6.70
25	13	Big Data	9.35
26	13	Bases de Datos	9.00
27	14	Big Data	5.10
28	14	Bases de Datos	6.35
29	15	Big Data	8.60
30	15	Bases de Datos	7.45
31	16	Big Data	7.20
32	16	Bases de Datos	7.95
33	17	Big Data	4.50
34	17	Bases de Datos	5.65
35	18	Big Data	8.85
36	18	Bases de Datos	8.10
37	19	Big Data	6.95
38	19	Bases de Datos	7.60
39	20	Big Data	9.05
40	20	Bases de Datos	8.75
\.


--
-- Name: alumnos_id_alumno_seq; Type: SEQUENCE SET; Schema: public; Owner: usuario
--

SELECT pg_catalog.setval('public.alumnos_id_alumno_seq', 20, true);


--
-- Name: notas_id_nota_seq; Type: SEQUENCE SET; Schema: public; Owner: usuario
--

SELECT pg_catalog.setval('public.notas_id_nota_seq', 40, true);


--
-- Name: alumnos alumnos_pkey; Type: CONSTRAINT; Schema: public; Owner: usuario
--

ALTER TABLE ONLY public.alumnos
    ADD CONSTRAINT alumnos_pkey PRIMARY KEY (id_alumno);


--
-- Name: notas notas_pkey; Type: CONSTRAINT; Schema: public; Owner: usuario
--

ALTER TABLE ONLY public.notas
    ADD CONSTRAINT notas_pkey PRIMARY KEY (id_nota);


--
-- Name: notas fk_notas_alumnos; Type: FK CONSTRAINT; Schema: public; Owner: usuario
--

ALTER TABLE ONLY public.notas
    ADD CONSTRAINT fk_notas_alumnos FOREIGN KEY (id_alumno) REFERENCES public.alumnos(id_alumno) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict SPfvmDJcwSkCP6ki4drDYcbGIGbwU1yx7jIbgu1lk9fBlYLZC73T1Xs8OrevWR2

--
-- PostgreSQL database cluster dump complete
--

