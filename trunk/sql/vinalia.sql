--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: vinalia; Type: DATABASE; Schema: -; Owner: vinalia
--

CREATE DATABASE vinalia WITH TEMPLATE = template0 ENCODING = 'UTF8';


ALTER DATABASE vinalia OWNER TO vinalia;

\connect vinalia

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


SET search_path = public, pg_catalog;

--
-- Name: plr_call_handler(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION plr_call_handler() RETURNS language_handler
    AS '$libdir/plr', 'plr_call_handler'
    LANGUAGE c;


ALTER FUNCTION public.plr_call_handler() OWNER TO postgres;

--
-- Name: plr; Type: PROCEDURAL LANGUAGE; Schema: public; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plr HANDLER plr_call_handler;


--
-- Name: plr_environ_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE plr_environ_type AS (
	name text,
	value text
);


ALTER TYPE public.plr_environ_type OWNER TO postgres;

--
-- Name: r_typename; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE r_typename AS (
	typename text,
	typeoid oid
);


ALTER TYPE public.r_typename OWNER TO postgres;

--
-- Name: install_rcmd(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION install_rcmd(text) RETURNS text
    AS '$libdir/plr', 'install_rcmd'
    LANGUAGE c STRICT;


ALTER FUNCTION public.install_rcmd(text) OWNER TO postgres;

--
-- Name: load_r_typenames(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION load_r_typenames() RETURNS text
    AS $$
  sql <- "select upper(typname::text) || 'OID' as typename, oid from pg_catalog.pg_type where typtype = 'b' order by typname"
  rs <- pg.spi.exec(sql)
  for(i in 1:nrow(rs))
  {
    typobj <- rs[i,1]
    typval <- rs[i,2]
    if (substr(typobj,1,1) == "_")
      typobj <- paste("ARRAYOF", substr(typobj,2,nchar(typobj)), sep="")
    assign(typobj, typval, .GlobalEnv)
  }
  return("OK")
$$
    LANGUAGE plr;


ALTER FUNCTION public.load_r_typenames() OWNER TO postgres;

--
-- Name: plr_array_accum(double precision[], double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION plr_array_accum(double precision[], double precision) RETURNS double precision[]
    AS '$libdir/plr', 'plr_array_accum'
    LANGUAGE c;


ALTER FUNCTION public.plr_array_accum(double precision[], double precision) OWNER TO postgres;

--
-- Name: plr_array_push(double precision[], double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION plr_array_push(double precision[], double precision) RETURNS double precision[]
    AS '$libdir/plr', 'plr_array_push'
    LANGUAGE c STRICT;


ALTER FUNCTION public.plr_array_push(double precision[], double precision) OWNER TO postgres;

--
-- Name: plr_environ(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION plr_environ() RETURNS SETOF plr_environ_type
    AS '$libdir/plr', 'plr_environ'
    LANGUAGE c;


ALTER FUNCTION public.plr_environ() OWNER TO postgres;

--
-- Name: plr_singleton_array(double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION plr_singleton_array(double precision) RETURNS double precision[]
    AS '$libdir/plr', 'plr_array'
    LANGUAGE c STRICT;


ALTER FUNCTION public.plr_singleton_array(double precision) OWNER TO postgres;

--
-- Name: r_mad(double precision[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION r_mad(double precision[]) RETURNS double precision
    AS $$mad(arg1)$$
    LANGUAGE plr;


ALTER FUNCTION public.r_mad(double precision[]) OWNER TO postgres;

--
-- Name: r_mean(double precision[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION r_mean(double precision[]) RETURNS double precision
    AS $$mean(arg1, trim = 0.2)$$
    LANGUAGE plr;


ALTER FUNCTION public.r_mean(double precision[]) OWNER TO postgres;

--
-- Name: r_median(double precision[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION r_median(double precision[]) RETURNS double precision
    AS $$median(arg1)$$
    LANGUAGE plr;


ALTER FUNCTION public.r_median(double precision[]) OWNER TO postgres;

--
-- Name: r_typenames(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION r_typenames() RETURNS SETOF r_typename
    AS $$
  x <- ls(name = .GlobalEnv, pat = "OID")
  y <- vector()
  for (i in 1:length(x)) {y[i] <- eval(parse(text = x[i]))}
  data.frame(typename = x, typeoid = y)
$$
    LANGUAGE plr;


ALTER FUNCTION public.r_typenames() OWNER TO postgres;

--
-- Name: reload_plr_modules(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION reload_plr_modules() RETURNS text
    AS '$libdir/plr', 'reload_plr_modules'
    LANGUAGE c;


ALTER FUNCTION public.reload_plr_modules() OWNER TO postgres;

--
-- Name: mad(double precision); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE mad(double precision) (
    SFUNC = plr_array_accum,
    STYPE = double precision[],
    FINALFUNC = r_mad
);


ALTER AGGREGATE public.mad(double precision) OWNER TO postgres;

--
-- Name: mean(double precision); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE mean(double precision) (
    SFUNC = plr_array_accum,
    STYPE = double precision[],
    FINALFUNC = r_mean
);


ALTER AGGREGATE public.mean(double precision) OWNER TO postgres;

--
-- Name: median(double precision); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE median(double precision) (
    SFUNC = plr_array_accum,
    STYPE = double precision[],
    FINALFUNC = r_median
);


ALTER AGGREGATE public.median(double precision) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: __rekallobjects; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE __rekallobjects (
    id integer NOT NULL,
    name text,
    "type" text,
    definition bytea,
    description bytea,
    savedate text,
    extension text
);


ALTER TABLE public.__rekallobjects OWNER TO vinalia;

--
-- Name: __rekallobjects_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE __rekallobjects_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.__rekallobjects_id_seq OWNER TO vinalia;

--
-- Name: __rekallobjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE __rekallobjects_id_seq OWNED BY __rekallobjects.id;


SET default_with_oids = true;

--
-- Name: attributes; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE attributes (
    attribute_id integer NOT NULL,
    name character varying(64) NOT NULL
);


ALTER TABLE public.attributes OWNER TO vinalia;

--
-- Name: attributes_attribute_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE attributes_attribute_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.attributes_attribute_id_seq OWNER TO vinalia;

--
-- Name: attributes_attribute_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE attributes_attribute_id_seq OWNED BY attributes.attribute_id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE categories (
    category_id integer NOT NULL,
    name character varying(64) NOT NULL,
    sort integer
);


ALTER TABLE public.categories OWNER TO vinalia;

--
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE categories_category_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.categories_category_id_seq OWNER TO vinalia;

--
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE categories_category_id_seq OWNED BY categories.category_id;


--
-- Name: colors; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE colors (
    color_id integer NOT NULL,
    name character varying(64) NOT NULL
);


ALTER TABLE public.colors OWNER TO vinalia;

--
-- Name: colors_color_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE colors_color_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.colors_color_id_seq OWNER TO vinalia;

--
-- Name: colors_color_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE colors_color_id_seq OWNED BY colors.color_id;


SET default_with_oids = false;

--
-- Name: groups; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE groups (
    group_id integer NOT NULL,
    name text NOT NULL,
    sort integer
);


ALTER TABLE public.groups OWNER TO vinalia;

--
-- Name: groups_group_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE groups_group_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.groups_group_id_seq OWNER TO vinalia;

--
-- Name: groups_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE groups_group_id_seq OWNED BY groups.group_id;


SET default_with_oids = true;

--
-- Name: judges; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE judges (
    judge_id integer NOT NULL,
    family_name character varying(128) NOT NULL,
    name character varying(128),
    group_id integer,
    sort integer
);


ALTER TABLE public.judges OWNER TO vinalia;

--
-- Name: judges_judge_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE judges_judge_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.judges_judge_id_seq OWNER TO vinalia;

--
-- Name: judges_judge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE judges_judge_id_seq OWNED BY judges.judge_id;


--
-- Name: producers; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE producers (
    producer_id integer NOT NULL,
    family_name character varying(128) NOT NULL,
    name character varying(128),
    address character varying(128) NOT NULL,
    street character varying(128),
    phone character varying(128)
);


ALTER TABLE public.producers OWNER TO vinalia;

--
-- Name: scores; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE scores (
    judge_id integer NOT NULL,
    wine_id integer NOT NULL,
    score real DEFAULT 0 NOT NULL,
    score_id integer NOT NULL,
    CONSTRAINT scores_score_check CHECK (((score >= (0)::double precision) AND (score <= (100)::double precision)))
);


ALTER TABLE public.scores OWNER TO vinalia;

--
-- Name: varieties; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE varieties (
    variety_id integer NOT NULL,
    name character varying(64) NOT NULL,
    color_id integer,
    description text,
    catalog_order integer
);


ALTER TABLE public.varieties OWNER TO vinalia;

--
-- Name: wines; Type: TABLE; Schema: public; Owner: vinalia; Tablespace: 
--

CREATE TABLE wines (
    wine_id integer NOT NULL,
    producer_id integer NOT NULL,
    variety_id integer NOT NULL,
    attribute_id integer NOT NULL,
    category_id integer NOT NULL,
    "year" integer DEFAULT 2006 NOT NULL,
    note text,
    sort_value integer,
    group_id integer,
    CONSTRAINT wines_year_check CHECK ((("year" > 1900) AND ("year" <= 2008)))
);


ALTER TABLE public.wines OWNER TO vinalia;

--
-- Name: wines_trimmed_means; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_trimmed_means AS
    SELECT wines.wine_id, mean((COALESCE(scores.score, (0.0)::real))::double precision) AS score FROM (wines LEFT JOIN scores USING (wine_id)) GROUP BY wines.wine_id;


ALTER TABLE public.wines_trimmed_means OWNER TO vinalia;

--
-- Name: wines_scores; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_scores AS
    SELECT wines_trimmed_means.wine_id, wines_trimmed_means.score FROM wines_trimmed_means;


ALTER TABLE public.wines_scores OWNER TO vinalia;

--
-- Name: wines_summary; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_summary AS
    SELECT wines.wine_id AS id, producers.family_name AS producer_family_name, producers.name AS producer_name, producers.address AS producer_address, varieties.name AS variety, colors.name AS color, attributes.name AS attribute, categories.name AS category, wines."year", wines.note, wines.sort_value, wines_scores.score, CASE WHEN (wines_scores.score >= (90)::double precision) THEN 'ZM'::text WHEN ((wines_scores.score >= (85)::double precision) AND (wines_scores.score < (90)::double precision)) THEN 'SM'::text WHEN ((wines_scores.score >= (75)::double precision) AND (wines_scores.score < (85)::double precision)) THEN 'BM'::text ELSE ''::text END AS medal FROM ((((((wines LEFT JOIN producers USING (producer_id)) LEFT JOIN varieties USING (variety_id)) LEFT JOIN colors USING (color_id)) LEFT JOIN attributes USING (attribute_id)) LEFT JOIN categories USING (category_id)) LEFT JOIN wines_scores USING (wine_id)) ORDER BY wines.wine_id;


ALTER TABLE public.wines_summary OWNER TO vinalia;

--
-- Name: medals_distribution; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW medals_distribution AS
    SELECT wines_summary.medal, count(*) AS total FROM wines_summary GROUP BY wines_summary.medal ORDER BY count(*) DESC;


ALTER TABLE public.medals_distribution OWNER TO vinalia;

--
-- Name: producers_producer_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE producers_producer_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.producers_producer_id_seq OWNER TO vinalia;

--
-- Name: producers_producer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE producers_producer_id_seq OWNED BY producers.producer_id;


--
-- Name: results_addresses; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW results_addresses AS
    SELECT addresses.leftcol AS address, addresses.rightcol AS count FROM (SELECT producers.address AS leftcol, count(*) AS rightcol, '1' AS unionorder FROM producers WHERE (producers.producer_id IN (SELECT wines.producer_id FROM wines)) GROUP BY producers.address UNION SELECT 'Spolu' AS leftcol, count(*) AS rightcol, '2' AS unionorder FROM producers WHERE (producers.producer_id IN (SELECT wines.producer_id FROM wines))) addresses ORDER BY addresses.unionorder, addresses.leftcol;


ALTER TABLE public.results_addresses OWNER TO vinalia;

--
-- Name: wines_statistics; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_statistics AS
    SELECT wines.wine_id, mad((COALESCE(scores.score, (0.0)::real))::double precision) AS mad, stddev_samp(COALESCE(scores.score, (0.0)::real)) AS stddev FROM (wines LEFT JOIN scores USING (wine_id)) GROUP BY wines.wine_id;


ALTER TABLE public.wines_statistics OWNER TO vinalia;

--
-- Name: results_per_variety; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW results_per_variety AS
    SELECT wines.wine_id AS id, producers.family_name AS producer_family_name, producers.name AS producer_name, producers.address AS producer_address, varieties.name AS variety, colors.name AS color, attributes.name AS attribute, categories.name AS category, wines."year", wines.note, wines.sort_value, wines_scores.score, CASE WHEN (wines_scores.score >= (90)::double precision) THEN 'ZM'::text WHEN ((wines_scores.score >= (85)::double precision) AND (wines_scores.score < (90)::double precision)) THEN 'SM'::text WHEN ((wines_scores.score >= (75)::double precision) AND (wines_scores.score < (85)::double precision)) THEN 'BM'::text ELSE ''::text END AS medal, varieties.catalog_order FROM (((((((wines LEFT JOIN producers USING (producer_id)) LEFT JOIN varieties USING (variety_id)) LEFT JOIN colors USING (color_id)) LEFT JOIN attributes USING (attribute_id)) LEFT JOIN categories USING (category_id)) LEFT JOIN wines_scores USING (wine_id)) LEFT JOIN wines_statistics USING (wine_id)) ORDER BY varieties.catalog_order, wines_scores.score DESC, wines_statistics.mad, wines_statistics.stddev;


ALTER TABLE public.results_per_variety OWNER TO vinalia;

--
-- Name: scores_score_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE scores_score_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.scores_score_id_seq OWNER TO vinalia;

--
-- Name: scores_score_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE scores_score_id_seq OWNED BY scores.score_id;


--
-- Name: varieties_total; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW varieties_total AS
    SELECT wines_summary.variety, count(*) AS total FROM wines_summary GROUP BY wines_summary.variety ORDER BY count(*) DESC, wines_summary.variety;


ALTER TABLE public.varieties_total OWNER TO vinalia;

--
-- Name: simple_variety_wines; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW simple_variety_wines AS
    SELECT wines_summary.variety, wines_summary.id, wines_summary.color FROM (wines_summary LEFT JOIN varieties_total USING (variety)) ORDER BY varieties_total.total DESC, wines_summary.variety, wines_summary.color;


ALTER TABLE public.simple_variety_wines OWNER TO vinalia;

--
-- Name: startup_list; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW startup_list AS
    SELECT wines.wine_id, varieties.name AS varietyname, colors.name AS colorname, attributes.name AS attributename, categories.name AS categoryname, wines."year", wines.note FROM ((((wines LEFT JOIN varieties USING (variety_id)) LEFT JOIN colors USING (color_id)) LEFT JOIN attributes USING (attribute_id)) LEFT JOIN categories USING (category_id)) ORDER BY varieties.catalog_order;


ALTER TABLE public.startup_list OWNER TO vinalia;

--
-- Name: tmp_producers; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW tmp_producers AS
    SELECT producers.producer_id, (((producers.family_name)::text || ' '::text) || (producers.name)::text) AS producer FROM producers ORDER BY producers.family_name;


ALTER TABLE public.tmp_producers OWNER TO vinalia;

--
-- Name: tmp_varieties; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW tmp_varieties AS
    SELECT varieties.variety_id, varieties.name FROM varieties ORDER BY varieties.name;


ALTER TABLE public.tmp_varieties OWNER TO vinalia;

--
-- Name: top12; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW top12 AS
    SELECT wines_summary.id, wines_summary.producer_family_name, wines_summary.producer_name, wines_summary.producer_address, wines_summary.variety, wines_summary.color, wines_summary.attribute, wines_summary.category, wines_summary."year", wines_summary.note, wines_summary.sort_value, wines_summary.score, wines_summary.medal FROM wines_summary ORDER BY wines_summary.score DESC, wines_summary.producer_family_name LIMIT 12;


ALTER TABLE public.top12 OWNER TO vinalia;

--
-- Name: top_group_wines; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW top_group_wines AS
    SELECT wines.group_id, wines_scores.wine_id, wines_scores.score FROM ((wines_scores JOIN wines USING (wine_id)) JOIN (SELECT wines.group_id, max(wines_scores.score) AS score FROM (wines_scores JOIN wines USING (wine_id)) GROUP BY wines.group_id) top_scores USING (group_id, score)) ORDER BY wines.group_id, wines_scores.wine_id;


ALTER TABLE public.top_group_wines OWNER TO vinalia;

--
-- Name: top_wines; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW top_wines AS
    SELECT wines_summary.id, wines_summary.producer_family_name, wines_summary.producer_name, wines_summary.producer_address, wines_summary.variety, wines_summary.color, wines_summary.attribute, wines_summary.category, wines_summary."year", wines_summary.note, wines_summary.sort_value, wines_summary.score, wines_summary.medal, round((wines_statistics.mad)::numeric, 2) AS mad, round((wines_statistics.stddev)::numeric, 2) AS stddev FROM (wines_summary LEFT JOIN wines_statistics ON ((wines_summary.id = wines_statistics.wine_id))) WHERE (wines_summary.score >= (90)::double precision) ORDER BY wines_summary.score DESC, wines_statistics.mad, wines_statistics.stddev, wines_summary.producer_family_name;


ALTER TABLE public.top_wines OWNER TO vinalia;

--
-- Name: varieties_variety_id_seq; Type: SEQUENCE; Schema: public; Owner: vinalia
--

CREATE SEQUENCE varieties_variety_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.varieties_variety_id_seq OWNER TO vinalia;

--
-- Name: varieties_variety_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vinalia
--

ALTER SEQUENCE varieties_variety_id_seq OWNED BY varieties.variety_id;


--
-- Name: variety_wines; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW variety_wines AS
    SELECT wines_summary.id, wines_summary.producer_family_name, wines_summary.producer_name, wines_summary.producer_address, wines_summary.variety, wines_summary.color, wines_summary.attribute, wines_summary.category, wines_summary."year", wines_summary.note, wines_summary.sort_value, wines_summary.score, wines_summary.medal FROM (wines_summary LEFT JOIN varieties_total USING (variety)) ORDER BY varieties_total.total DESC, varieties_total.variety, wines_summary.producer_family_name;


ALTER TABLE public.variety_wines OWNER TO vinalia;

--
-- Name: wines_average; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_average AS
    SELECT wines.wine_id, avg(scores.score) AS score FROM (wines LEFT JOIN scores USING (wine_id)) GROUP BY wines.wine_id;


ALTER TABLE public.wines_average OWNER TO vinalia;

--
-- Name: wines_averages; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_averages AS
    SELECT wines.wine_id, avg(scores.score) AS score FROM (wines LEFT JOIN scores USING (wine_id)) GROUP BY wines.wine_id;


ALTER TABLE public.wines_averages OWNER TO vinalia;

--
-- Name: wines_gaudium; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_gaudium AS
    SELECT wines.wine_id AS id, producers.family_name AS producer_family_name, producers.name AS producer_name, producers.street AS producer_street, producers.address AS producer_address, producers.phone AS producer_phone, varieties.name AS variety, colors.name AS color, attributes.name AS attribute, categories.name AS category, wines."year", wines_scores.score, CASE WHEN (wines_scores.score >= (90)::double precision) THEN 'ZM'::text WHEN ((wines_scores.score >= (85)::double precision) AND (wines_scores.score < (90)::double precision)) THEN 'SM'::text WHEN ((wines_scores.score >= (75)::double precision) AND (wines_scores.score < (85)::double precision)) THEN 'BM'::text ELSE ''::text END AS medal FROM ((((((wines LEFT JOIN producers USING (producer_id)) LEFT JOIN varieties USING (variety_id)) LEFT JOIN colors USING (color_id)) LEFT JOIN attributes USING (attribute_id)) LEFT JOIN categories USING (category_id)) LEFT JOIN wines_scores USING (wine_id)) ORDER BY wines.wine_id;


ALTER TABLE public.wines_gaudium OWNER TO vinalia;

--
-- Name: wines_groups; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_groups AS
    SELECT groups.name AS group_name, wines.wine_id, varieties.name AS wine_name, categories.name AS category_name, wines."year" AS wine_year FROM (((wines LEFT JOIN varieties USING (variety_id)) LEFT JOIN categories USING (category_id)) LEFT JOIN groups USING (group_id)) ORDER BY groups.sort, varieties.catalog_order, categories.sort, wines."year" DESC;


ALTER TABLE public.wines_groups OWNER TO vinalia;

--
-- Name: wines_medians; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_medians AS
    SELECT wines.wine_id, median((COALESCE(scores.score, (0.0)::real))::double precision) AS score FROM (wines LEFT JOIN scores USING (wine_id)) GROUP BY wines.wine_id;


ALTER TABLE public.wines_medians OWNER TO vinalia;

--
-- Name: wines_noscores; Type: VIEW; Schema: public; Owner: vinalia
--

CREATE VIEW wines_noscores AS
    SELECT variety_wines.id, variety_wines.variety, variety_wines."year", COALESCE(scores_per_wine.score_count, (0)::bigint) AS scores, COALESCE(judges_per_wine.judge_count, (0)::bigint) AS judges FROM ((variety_wines LEFT JOIN (SELECT scores.wine_id AS id, count(*) AS score_count FROM scores GROUP BY scores.wine_id) scores_per_wine USING (id)) LEFT JOIN (SELECT wines.wine_id AS id, count(*) AS judge_count FROM (wines JOIN judges USING (group_id)) GROUP BY wines.wine_id) judges_per_wine USING (id)) WHERE (COALESCE(scores_per_wine.score_count, (0)::bigint) <> COALESCE(judges_per_wine.judge_count, (0)::bigint)) ORDER BY variety_wines.id;


ALTER TABLE public.wines_noscores OWNER TO vinalia;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE __rekallobjects ALTER COLUMN id SET DEFAULT nextval('__rekallobjects_id_seq'::regclass);


--
-- Name: attribute_id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE attributes ALTER COLUMN attribute_id SET DEFAULT nextval('attributes_attribute_id_seq'::regclass);


--
-- Name: category_id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE categories ALTER COLUMN category_id SET DEFAULT nextval('categories_category_id_seq'::regclass);


--
-- Name: color_id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE colors ALTER COLUMN color_id SET DEFAULT nextval('colors_color_id_seq'::regclass);


--
-- Name: group_id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE groups ALTER COLUMN group_id SET DEFAULT nextval('groups_group_id_seq'::regclass);


--
-- Name: judge_id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE judges ALTER COLUMN judge_id SET DEFAULT nextval('judges_judge_id_seq'::regclass);


--
-- Name: producer_id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE producers ALTER COLUMN producer_id SET DEFAULT nextval('producers_producer_id_seq'::regclass);


--
-- Name: score_id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE scores ALTER COLUMN score_id SET DEFAULT nextval('scores_score_id_seq'::regclass);


--
-- Name: variety_id; Type: DEFAULT; Schema: public; Owner: vinalia
--

ALTER TABLE varieties ALTER COLUMN variety_id SET DEFAULT nextval('varieties_variety_id_seq'::regclass);


--
-- Name: ___re_27685_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY __rekallobjects
    ADD CONSTRAINT ___re_27685_pkey PRIMARY KEY (id);


--
-- Name: attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY attributes
    ADD CONSTRAINT attributes_pkey PRIMARY KEY (attribute_id);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: colors_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY colors
    ADD CONSTRAINT colors_pkey PRIMARY KEY (color_id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (group_id);


--
-- Name: judges_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY judges
    ADD CONSTRAINT judges_pkey PRIMARY KEY (judge_id);


--
-- Name: producers_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY producers
    ADD CONSTRAINT producers_pkey PRIMARY KEY (producer_id);


--
-- Name: scores_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (score_id);


--
-- Name: varieties_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY varieties
    ADD CONSTRAINT varieties_pkey PRIMARY KEY (variety_id);


--
-- Name: wines_pkey; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY wines
    ADD CONSTRAINT wines_pkey PRIMARY KEY (wine_id);


--
-- Name: wines_sort_value_key; Type: CONSTRAINT; Schema: public; Owner: vinalia; Tablespace: 
--

ALTER TABLE ONLY wines
    ADD CONSTRAINT wines_sort_value_key UNIQUE (sort_value);


--
-- Name: judges_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY judges
    ADD CONSTRAINT judges_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(group_id);


--
-- Name: scores_judge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT scores_judge_id_fkey FOREIGN KEY (judge_id) REFERENCES judges(judge_id);


--
-- Name: scores_wine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT scores_wine_id_fkey FOREIGN KEY (wine_id) REFERENCES wines(wine_id);


--
-- Name: varieties_color_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY varieties
    ADD CONSTRAINT varieties_color_id_fkey FOREIGN KEY (color_id) REFERENCES colors(color_id);


--
-- Name: wines_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY wines
    ADD CONSTRAINT wines_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES attributes(attribute_id);


--
-- Name: wines_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY wines
    ADD CONSTRAINT wines_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(category_id);


--
-- Name: wines_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY wines
    ADD CONSTRAINT wines_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(group_id);


--
-- Name: wines_producer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY wines
    ADD CONSTRAINT wines_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES producers(producer_id);


--
-- Name: wines_variety_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vinalia
--

ALTER TABLE ONLY wines
    ADD CONSTRAINT wines_variety_id_fkey FOREIGN KEY (variety_id) REFERENCES varieties(variety_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: install_rcmd(text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION install_rcmd(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION install_rcmd(text) FROM postgres;
GRANT ALL ON FUNCTION install_rcmd(text) TO postgres;


--
-- Name: plr_environ(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION plr_environ() FROM PUBLIC;
REVOKE ALL ON FUNCTION plr_environ() FROM postgres;
GRANT ALL ON FUNCTION plr_environ() TO postgres;


--
-- PostgreSQL database dump complete
--

