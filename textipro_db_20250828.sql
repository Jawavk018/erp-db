--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 17.2 (Ubuntu 17.2-1.pgdg22.04+1)

-- Started on 2025-08-28 16:59:25 IST

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
-- TOC entry 6 (class 2615 OID 235681)
-- Name: masters; Type: SCHEMA; Schema: -; Owner: textipro_admin
--

CREATE SCHEMA masters;


ALTER SCHEMA masters OWNER TO textipro_admin;

--
-- TOC entry 368 (class 1255 OID 238681)
-- Name: generate_sales_order_numbers(); Type: FUNCTION; Schema: masters; Owner: textipro_admin
--

CREATE FUNCTION masters.generate_sales_order_numbers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    ext_seq_val INTEGER;
    int_seq_val INTEGER;
    current_year TEXT;
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;
    
    -- Generate sales_order_no (external) with proper error handling
    BEGIN
        SELECT nextval('masters.sales_order_ext_seq'::regclass) INTO ext_seq_val;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to get next value from sales_order_ext_seq: %', SQLERRM;
    END;
    
    NEW.sales_order_no := 'SO-JVT' || current_year || '-' || LPAD(ext_seq_val::TEXT, 4, '0');
    
    -- Generate internal_order_no with proper error handling
    BEGIN
        SELECT nextval('masters.sales_order_int_seq'::regclass) INTO int_seq_val;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to get next value from sales_order_int_seq: %', SQLERRM;
    END;
    
    NEW.internal_order_no := 'JVT-' || LPAD(int_seq_val::TEXT, 4, '0');
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION masters.generate_sales_order_numbers() OWNER TO textipro_admin;

--
-- TOC entry 366 (class 1255 OID 235682)
-- Name: get_fabric_details_by_fabric_type_id(bigint); Type: FUNCTION; Schema: masters; Owner: textipro_admin
--

CREATE FUNCTION masters.get_fabric_details_by_fabric_type_id(p_fabric_type_id bigint) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result jsonb;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', wfm.id,
            'fabric_code', wfm.fabric_code,
            'fabric_name', wfm.fabric_name,
            'weave', wfm.weave,
            'fabric_quality', wfm.fabric_quality,
            'uom', wfm.uom,
            'epi', wfm.epi,
            'ppi', wfm.ppi,
            'greige_code', wfm.greige_code,
            'total_ends', wfm.total_ends,
            'gsm', wfm.gsm,
            'glm', wfm.glm,
            'igst', wfm.igst,
            'cgst', wfm.cgst,
            'sgst', wfm.sgst,
            'fabric_image_url', wfm.fabric_image_url,
            'product_category_id', wfm.product_category_id,
            'fabric_category_id', wfm.fabric_category_id
        )
    )
    INTO result
    FROM masters.woven_fabric_master wfm
    WHERE wfm.fabric_type_id = p_fabric_type_id;

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$;


ALTER FUNCTION masters.get_fabric_details_by_fabric_type_id(p_fabric_type_id bigint) OWNER TO textipro_admin;

--
-- TOC entry 367 (class 1255 OID 235683)
-- Name: get_fabric_details_by_id(jsonb); Type: FUNCTION; Schema: masters; Owner: textipro_admin
--

CREATE FUNCTION masters.get_fabric_details_by_id(p_fabric_id jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'fabric_master', to_jsonb(fm),

        'warp_details', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'warp_detail_id', fwd.id,
                    'yarn_id', fwd.yarn_id,
                    'color', fwd.color,
                    'shrinkage_percent', fwd.shrinkage_percent,
                    'grams_per_meter', fwd.grams_per_meter,
                    'yarn_name', yw.yarn_name,
                    'count_sno', yw.count_sno,
                    'count_name', sc.sub_category_name,
--                     'units', yw.units,
                    'types', yw.types,
                    'conversion', yw.conversion,
                    'active_flag', yw.active_flag
                )
            )
            FROM masters.fabric_warp_detail fwd
            JOIN masters.yarn_master yw ON fwd.yarn_id = yw.id
            LEFT JOIN masters.sub_category sc ON yw.count_sno = sc.id
            WHERE fwd.fabric_id = fm.id
        ),

        'weft_details', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'weft_detail_id', fwt.id,
                    'yarn_id', fwt.yarn_id,
                    'color', fwt.color,
                    'shrinkage_percent', fwt.shrinkage_percent,
                    'grams_per_meter', fwt.grams_per_meter,
                    'yarn_name', ywf.yarn_name,
                    'count_sno', ywf.count_sno,
                    'count_name', sc2.sub_category_name,
--                     'units', ywf.units,
                    'types', ywf.types,
                    'conversion', ywf.conversion,
                    'active_flag', ywf.active_flag
                )
            )
            FROM masters.fabric_weft_detail fwt
            JOIN masters.yarn_master ywf ON fwt.yarn_id = ywf.id
            LEFT JOIN masters.sub_category sc2 ON ywf.count_sno = sc2.id
            WHERE fwt.fabric_id = fm.id
        )
    )
    INTO result
    FROM masters.woven_fabric_master fm
    WHERE fm.id = p_fabric_id;

    RETURN result;
END;
$$;


ALTER FUNCTION masters.get_fabric_details_by_id(p_fabric_id jsonb) OWNER TO textipro_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 210 (class 1259 OID 235684)
-- Name: address; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.address (
    id bigint NOT NULL,
    line1 text NOT NULL,
    line2 text,
    country_id bigint,
    state_id bigint,
    city_id bigint,
    active_flag boolean DEFAULT true NOT NULL,
    pin_code bigint
);


ALTER TABLE masters.address OWNER TO textipro_admin;

--
-- TOC entry 211 (class 1259 OID 235690)
-- Name: address_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.address_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4244 (class 0 OID 0)
-- Dependencies: 211
-- Name: address_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.address_id_seq OWNED BY masters.address.id;


--
-- TOC entry 336 (class 1259 OID 238683)
-- Name: beam_inward; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.beam_inward (
    id bigint NOT NULL,
    beam_inward_no character varying(255),
    consignee_id bigint,
    payment_terms_id bigint,
    remarks text,
    sizing_plan_id bigint,
    sizing_rate double precision,
    terms_conditions_id bigint,
    vendor_id bigint
);


ALTER TABLE masters.beam_inward OWNER TO textipro_admin;

--
-- TOC entry 338 (class 1259 OID 238692)
-- Name: beam_inward_beam_details; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.beam_inward_beam_details (
    id bigint NOT NULL,
    empty_beam_id bigint,
    expected_fabric_meter bigint,
    sales_order_id bigint,
    shrinkage bigint,
    weaving_contract_id bigint,
    wrap_meters bigint,
    beam_inward_id bigint
);


ALTER TABLE masters.beam_inward_beam_details OWNER TO textipro_admin;

--
-- TOC entry 337 (class 1259 OID 238691)
-- Name: beam_inward_beam_details_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.beam_inward_beam_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.beam_inward_beam_details_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4245 (class 0 OID 0)
-- Dependencies: 337
-- Name: beam_inward_beam_details_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.beam_inward_beam_details_id_seq OWNED BY masters.beam_inward_beam_details.id;


--
-- TOC entry 335 (class 1259 OID 238682)
-- Name: beam_inward_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.beam_inward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.beam_inward_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4246 (class 0 OID 0)
-- Dependencies: 335
-- Name: beam_inward_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.beam_inward_id_seq OWNED BY masters.beam_inward.id;


--
-- TOC entry 340 (class 1259 OID 238699)
-- Name: beam_inward_quality_details; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.beam_inward_quality_details (
    id bigint NOT NULL,
    actual_ends bigint,
    ends_per_part bigint,
    parts bigint,
    quality character varying(255),
    sord_ends bigint,
    wrap_meters bigint,
    yarn_id bigint,
    beam_inward_id bigint
);


ALTER TABLE masters.beam_inward_quality_details OWNER TO textipro_admin;

--
-- TOC entry 339 (class 1259 OID 238698)
-- Name: beam_inward_quality_details_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.beam_inward_quality_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.beam_inward_quality_details_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4247 (class 0 OID 0)
-- Dependencies: 339
-- Name: beam_inward_quality_details_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.beam_inward_quality_details_id_seq OWNED BY masters.beam_inward_quality_details.id;


--
-- TOC entry 212 (class 1259 OID 235691)
-- Name: category; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.category (
    id bigint NOT NULL,
    category_name character varying(100) NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.category OWNER TO textipro_admin;

--
-- TOC entry 213 (class 1259 OID 235695)
-- Name: category_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.category_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4248 (class 0 OID 0)
-- Dependencies: 213
-- Name: category_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.category_id_seq OWNED BY masters.category.id;


--
-- TOC entry 214 (class 1259 OID 235696)
-- Name: city; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.city (
    id bigint NOT NULL,
    country_sno bigint NOT NULL,
    state_sno bigint NOT NULL,
    city_name character varying(100) NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.city OWNER TO textipro_admin;

--
-- TOC entry 215 (class 1259 OID 235700)
-- Name: city_city_sno_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.city_city_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.city_city_sno_seq OWNER TO textipro_admin;

--
-- TOC entry 4249 (class 0 OID 0)
-- Dependencies: 215
-- Name: city_city_sno_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.city_city_sno_seq OWNED BY masters.city.id;


--
-- TOC entry 216 (class 1259 OID 235701)
-- Name: consignee; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.consignee (
    id bigint NOT NULL,
    consignee_name character varying(100) NOT NULL,
    gstno text NOT NULL,
    pancard text NOT NULL,
    mobileno text NOT NULL,
    email text NOT NULL,
    address_id bigint,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.consignee OWNER TO textipro_admin;

--
-- TOC entry 217 (class 1259 OID 235707)
-- Name: consignee_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.consignee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.consignee_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4250 (class 0 OID 0)
-- Dependencies: 217
-- Name: consignee_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.consignee_id_seq OWNED BY masters.consignee.id;


--
-- TOC entry 218 (class 1259 OID 235708)
-- Name: country; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.country (
    id bigint NOT NULL,
    country_name character varying(100) NOT NULL,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE masters.country OWNER TO textipro_admin;

--
-- TOC entry 219 (class 1259 OID 235712)
-- Name: country_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.country_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.country_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4251 (class 0 OID 0)
-- Dependencies: 219
-- Name: country_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.country_id_seq OWNED BY masters.country.id;


--
-- TOC entry 220 (class 1259 OID 235713)
-- Name: currency_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.currency_master (
    id bigint NOT NULL,
    currency_code character varying(10) NOT NULL,
    currency_name character varying(50) NOT NULL,
    symbol character varying(10) NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.currency_master OWNER TO textipro_admin;

--
-- TOC entry 221 (class 1259 OID 235717)
-- Name: currency_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.currency_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.currency_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4252 (class 0 OID 0)
-- Dependencies: 221
-- Name: currency_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.currency_master_id_seq OWNED BY masters.currency_master.id;


--
-- TOC entry 222 (class 1259 OID 235718)
-- Name: customer; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.customer (
    id bigint NOT NULL,
    gstno text NOT NULL,
    pancard text NOT NULL,
    mobileno text NOT NULL,
    email text NOT NULL,
    address_id bigint,
    active_flag boolean DEFAULT true,
    customer_name character varying(100) NOT NULL,
    iec_code character varying(100),
    cin_no character varying(100),
    tin_no character varying(100),
    msme_udyam character varying(100)
);


ALTER TABLE masters.customer OWNER TO textipro_admin;

--
-- TOC entry 223 (class 1259 OID 235724)
-- Name: customer_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.customer_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4253 (class 0 OID 0)
-- Dependencies: 223
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.customer_id_seq OWNED BY masters.customer.id;


--
-- TOC entry 342 (class 1259 OID 238716)
-- Name: customer_international; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.customer_international (
    id bigint NOT NULL,
    customer_name character varying(100) NOT NULL,
    mobileno text NOT NULL,
    email text NOT NULL,
    address_id bigint,
    iec_code character varying(100),
    cin_no character varying(100),
    tin_no character varying(100),
    irc_no character varying(100),
    bin_no character varying(100),
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.customer_international OWNER TO textipro_admin;

--
-- TOC entry 341 (class 1259 OID 238715)
-- Name: customer_international_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.customer_international_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.customer_international_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4254 (class 0 OID 0)
-- Dependencies: 341
-- Name: customer_international_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.customer_international_id_seq OWNED BY masters.customer_international.id;


--
-- TOC entry 350 (class 1259 OID 261276)
-- Name: defect_master; Type: TABLE; Schema: masters; Owner: qbox_admin
--

CREATE TABLE masters.defect_master (
    id bigint NOT NULL,
    defect_code character varying(50) NOT NULL,
    defect_name character varying(100) NOT NULL,
    description text,
    active_flag boolean DEFAULT true,
    defect_pont smallint
);


ALTER TABLE masters.defect_master OWNER TO qbox_admin;

--
-- TOC entry 349 (class 1259 OID 261275)
-- Name: defect_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: qbox_admin
--

CREATE SEQUENCE masters.defect_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.defect_master_id_seq OWNER TO qbox_admin;

--
-- TOC entry 4255 (class 0 OID 0)
-- Dependencies: 349
-- Name: defect_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: qbox_admin
--

ALTER SEQUENCE masters.defect_master_id_seq OWNED BY masters.defect_master.id;


--
-- TOC entry 224 (class 1259 OID 235725)
-- Name: dyeing_work_order; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.dyeing_work_order (
    id bigint NOT NULL,
    dyeing_work_order_no character varying(50),
    process_contact_date date,
    delivery_date date,
    vendor_id bigint,
    sales_order_id bigint,
    consignee_id bigint,
    lap_dip_status_id bigint,
    first_yardage_id bigint,
    total_amount double precision,
    remarks text,
    active_flag boolean DEFAULT true,
    sales_order_no bigint
);


ALTER TABLE masters.dyeing_work_order OWNER TO textipro_admin;

--
-- TOC entry 225 (class 1259 OID 235731)
-- Name: dyeing_work_order_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.dyeing_work_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.dyeing_work_order_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4256 (class 0 OID 0)
-- Dependencies: 225
-- Name: dyeing_work_order_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.dyeing_work_order_id_seq OWNED BY masters.dyeing_work_order.id;


--
-- TOC entry 226 (class 1259 OID 235732)
-- Name: dyeing_work_order_items; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.dyeing_work_order_items (
    id bigint NOT NULL,
    dyeing_work_order_id bigint,
    finished_fabric_code_id bigint,
    finished_fabric_name character varying(100),
    greige_fabric_code_id bigint,
    greige_fabric_name character varying(100),
    quantity double precision,
    cost_per_pound double precision,
    total_amount double precision,
    color_id bigint,
    pantone character varying(100),
    finished_weight double precision,
    greige_width integer,
    req_finished_width integer,
    uom_id bigint,
    remarks text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.dyeing_work_order_items OWNER TO textipro_admin;

--
-- TOC entry 227 (class 1259 OID 235738)
-- Name: dyeing_work_order_items_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.dyeing_work_order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.dyeing_work_order_items_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4257 (class 0 OID 0)
-- Dependencies: 227
-- Name: dyeing_work_order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.dyeing_work_order_items_id_seq OWNED BY masters.dyeing_work_order_items.id;


--
-- TOC entry 228 (class 1259 OID 235739)
-- Name: empty_beam_issue; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.empty_beam_issue (
    id bigint NOT NULL,
    vendor_id bigint NOT NULL,
    consignee_id bigint NOT NULL,
    vechile_no character varying(50) NOT NULL,
    empty_beam_issue_date timestamp(6) without time zone,
    empty_beam_no character varying(50)
);


ALTER TABLE masters.empty_beam_issue OWNER TO textipro_admin;

--
-- TOC entry 229 (class 1259 OID 235742)
-- Name: empty_beam_issue_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.empty_beam_issue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.empty_beam_issue_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4258 (class 0 OID 0)
-- Dependencies: 229
-- Name: empty_beam_issue_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.empty_beam_issue_id_seq OWNED BY masters.empty_beam_issue.id;


--
-- TOC entry 230 (class 1259 OID 235743)
-- Name: empty_beam_issue_item; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.empty_beam_issue_item (
    id bigint NOT NULL,
    empty_beam_issue_id bigint NOT NULL,
    flange_id bigint NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.empty_beam_issue_item OWNER TO textipro_admin;

--
-- TOC entry 231 (class 1259 OID 235747)
-- Name: empty_beam_issue_item_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.empty_beam_issue_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.empty_beam_issue_item_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4259 (class 0 OID 0)
-- Dependencies: 231
-- Name: empty_beam_issue_item_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.empty_beam_issue_item_id_seq OWNED BY masters.empty_beam_issue_item.id;


--
-- TOC entry 232 (class 1259 OID 235748)
-- Name: fabric_category; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.fabric_category (
    id bigint NOT NULL,
    fabric_category_name character varying(100) NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.fabric_category OWNER TO textipro_admin;

--
-- TOC entry 233 (class 1259 OID 235752)
-- Name: fabric_category_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.fabric_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.fabric_category_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4260 (class 0 OID 0)
-- Dependencies: 233
-- Name: fabric_category_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.fabric_category_id_seq OWNED BY masters.fabric_category.id;


--
-- TOC entry 234 (class 1259 OID 235753)
-- Name: fabric_dispatch_for_dyeing; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.fabric_dispatch_for_dyeing (
    id bigint NOT NULL,
    fabric_dispatch_date date,
    vendor_id bigint,
    dyeing_work_order_id bigint,
    order_quantity double precision,
    dispatched_quantity double precision,
    received_quantity double precision,
    balance_quantity double precision,
    cost_per_pound double precision,
    total_amount double precision,
    color_id bigint,
    pantone character varying(100),
    finishing_id bigint,
    sales_order_id bigint,
    shipment_mode_id bigint,
    lot_id bigint,
    remarks text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.fabric_dispatch_for_dyeing OWNER TO textipro_admin;

--
-- TOC entry 235 (class 1259 OID 235759)
-- Name: fabric_dispatch_for_dyeing_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.fabric_dispatch_for_dyeing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.fabric_dispatch_for_dyeing_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4261 (class 0 OID 0)
-- Dependencies: 235
-- Name: fabric_dispatch_for_dyeing_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.fabric_dispatch_for_dyeing_id_seq OWNED BY masters.fabric_dispatch_for_dyeing.id;


--
-- TOC entry 236 (class 1259 OID 235760)
-- Name: fabric_inspection; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.fabric_inspection (
    id bigint NOT NULL,
    inspection_date date,
    loom_no double precision,
    vendor_id bigint,
    fabric_quality character varying(100),
    doff_meters double precision,
    doff_weight bigint,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.fabric_inspection OWNER TO textipro_admin;

--
-- TOC entry 237 (class 1259 OID 235764)
-- Name: fabric_inspection_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.fabric_inspection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.fabric_inspection_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4262 (class 0 OID 0)
-- Dependencies: 237
-- Name: fabric_inspection_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.fabric_inspection_id_seq OWNED BY masters.fabric_inspection.id;


--
-- TOC entry 238 (class 1259 OID 235765)
-- Name: woven_fabric_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.woven_fabric_master (
    id bigint NOT NULL,
    fabric_type_id smallint NOT NULL,
    fabric_code character varying(100) NOT NULL,
    fabric_name character varying(100) NOT NULL,
    weave smallint NOT NULL,
    fabric_quality character varying(150),
    uom character varying(50),
    epi integer,
    ppi integer,
    greige_code character varying(100),
    total_ends integer,
    gsm numeric(38,2),
    glm numeric(38,2),
    igst numeric(38,2),
    cgst numeric(38,2),
    sgst numeric(38,2),
    fabric_image_url text,
    product_category_id bigint,
    fabric_category_id smallint,
    content character varying(100),
    woven_fabric_id bigint,
    std_value numeric(38,2)
);


ALTER TABLE masters.woven_fabric_master OWNER TO textipro_admin;

--
-- TOC entry 239 (class 1259 OID 235770)
-- Name: fabric_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.fabric_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.fabric_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4263 (class 0 OID 0)
-- Dependencies: 239
-- Name: fabric_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.fabric_master_id_seq OWNED BY masters.woven_fabric_master.id;


--
-- TOC entry 240 (class 1259 OID 235771)
-- Name: fabric_type; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.fabric_type (
    id bigint NOT NULL,
    fabric_type_name character varying(100) NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.fabric_type OWNER TO textipro_admin;

--
-- TOC entry 241 (class 1259 OID 235775)
-- Name: fabric_type_fabric_type_sno_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.fabric_type_fabric_type_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.fabric_type_fabric_type_sno_seq OWNER TO textipro_admin;

--
-- TOC entry 4264 (class 0 OID 0)
-- Dependencies: 241
-- Name: fabric_type_fabric_type_sno_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.fabric_type_fabric_type_sno_seq OWNED BY masters.fabric_type.id;


--
-- TOC entry 242 (class 1259 OID 235776)
-- Name: fabric_warp_detail; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.fabric_warp_detail (
    id bigint NOT NULL,
    fabric_id bigint NOT NULL,
    yarn_id bigint NOT NULL,
    color smallint NOT NULL,
    shrinkage_percent numeric(38,2) NOT NULL,
    grams_per_meter numeric(38,2) NOT NULL
);


ALTER TABLE masters.fabric_warp_detail OWNER TO textipro_admin;

--
-- TOC entry 243 (class 1259 OID 235779)
-- Name: fabric_warp_detail_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.fabric_warp_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.fabric_warp_detail_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4265 (class 0 OID 0)
-- Dependencies: 243
-- Name: fabric_warp_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.fabric_warp_detail_id_seq OWNED BY masters.fabric_warp_detail.id;


--
-- TOC entry 244 (class 1259 OID 235780)
-- Name: fabric_weft_detail; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.fabric_weft_detail (
    id bigint NOT NULL,
    fabric_id bigint NOT NULL,
    yarn_id bigint NOT NULL,
    color smallint NOT NULL,
    shrinkage_percent numeric(38,2) NOT NULL,
    grams_per_meter numeric(38,2) NOT NULL
);


ALTER TABLE masters.fabric_weft_detail OWNER TO textipro_admin;

--
-- TOC entry 245 (class 1259 OID 235783)
-- Name: fabric_weft_detail_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.fabric_weft_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.fabric_weft_detail_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4266 (class 0 OID 0)
-- Dependencies: 245
-- Name: fabric_weft_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.fabric_weft_detail_id_seq OWNED BY masters.fabric_weft_detail.id;


--
-- TOC entry 344 (class 1259 OID 261225)
-- Name: finish_fabric_receive; Type: TABLE; Schema: masters; Owner: qbox_admin
--

CREATE TABLE masters.finish_fabric_receive (
    id bigint NOT NULL,
    fabric_fabric_receive_date date,
    vendor_id bigint,
    dyeing_work_order_id bigint,
    order_quantity double precision,
    cost_per_pound double precision,
    total_amount double precision,
    color_id bigint,
    pantone character varying(100),
    finishing_id bigint,
    sales_order_id bigint,
    purchase_inward_id bigint,
    dispatched_quantity double precision,
    received_quantity double precision,
    balance_quantity double precision,
    remarks text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.finish_fabric_receive OWNER TO qbox_admin;

--
-- TOC entry 346 (class 1259 OID 261235)
-- Name: finish_fabric_receive_items; Type: TABLE; Schema: masters; Owner: qbox_admin
--

CREATE TABLE masters.finish_fabric_receive_items (
    id bigint NOT NULL,
    finished_fabric_code character varying(100),
    roll_no character varying(100),
    roll_yards character varying(100),
    weight character varying(100),
    grade_id bigint,
    warehouse_id bigint,
    active_flag boolean DEFAULT true,
    finish_fabric_receive_id bigint
);


ALTER TABLE masters.finish_fabric_receive_items OWNER TO qbox_admin;

--
-- TOC entry 343 (class 1259 OID 261224)
-- Name: finish_fabric_recive_id_seq; Type: SEQUENCE; Schema: masters; Owner: qbox_admin
--

CREATE SEQUENCE masters.finish_fabric_recive_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.finish_fabric_recive_id_seq OWNER TO qbox_admin;

--
-- TOC entry 4267 (class 0 OID 0)
-- Dependencies: 343
-- Name: finish_fabric_recive_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: qbox_admin
--

ALTER SEQUENCE masters.finish_fabric_recive_id_seq OWNED BY masters.finish_fabric_receive.id;


--
-- TOC entry 345 (class 1259 OID 261234)
-- Name: finish_fabric_recive_items_id_seq; Type: SEQUENCE; Schema: masters; Owner: qbox_admin
--

CREATE SEQUENCE masters.finish_fabric_recive_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.finish_fabric_recive_items_id_seq OWNER TO qbox_admin;

--
-- TOC entry 4268 (class 0 OID 0)
-- Dependencies: 345
-- Name: finish_fabric_recive_items_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: qbox_admin
--

ALTER SEQUENCE masters.finish_fabric_recive_items_id_seq OWNED BY masters.finish_fabric_receive_items.id;


--
-- TOC entry 246 (class 1259 OID 235784)
-- Name: finish_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.finish_master (
    id bigint NOT NULL,
    finish_name character varying(50) NOT NULL,
    finish_code character varying(50) NOT NULL,
    description text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.finish_master OWNER TO textipro_admin;

--
-- TOC entry 247 (class 1259 OID 235790)
-- Name: finish_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.finish_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.finish_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4269 (class 0 OID 0)
-- Dependencies: 247
-- Name: finish_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.finish_master_id_seq OWNED BY masters.finish_master.id;


--
-- TOC entry 248 (class 1259 OID 235791)
-- Name: flange_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.flange_master (
    id bigint NOT NULL,
    flange_no character varying(100) NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.flange_master OWNER TO textipro_admin;

--
-- TOC entry 249 (class 1259 OID 235795)
-- Name: flange_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.flange_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.flange_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4270 (class 0 OID 0)
-- Dependencies: 249
-- Name: flange_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.flange_master_id_seq OWNED BY masters.flange_master.id;


--
-- TOC entry 250 (class 1259 OID 235796)
-- Name: generate_invoice; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.generate_invoice (
    id bigint NOT NULL,
    manufacture_id bigint,
    invoice_date date,
    sales_order_id bigint,
    company_bank_id bigint,
    terms_conditions_id bigint,
    payment_terms_id bigint,
    ship_to_id bigint,
    shipment_mode bigint,
    customer_id bigint,
    consginee_id bigint,
    tax_amount numeric(38,2),
    total_amount numeric(38,2),
    comments text,
    active_flag boolean DEFAULT true,
    invoice_no character varying(255)
);


ALTER TABLE masters.generate_invoice OWNER TO textipro_admin;

--
-- TOC entry 251 (class 1259 OID 235802)
-- Name: generate_invoice_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.generate_invoice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.generate_invoice_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4271 (class 0 OID 0)
-- Dependencies: 251
-- Name: generate_invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.generate_invoice_id_seq OWNED BY masters.generate_invoice.id;


--
-- TOC entry 324 (class 1259 OID 236579)
-- Name: generate_packing; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.generate_packing (
    id bigint NOT NULL,
    packing_date timestamp(6) without time zone,
    buyer_id bigint,
    sales_order_id bigint,
    warehouse_id bigint,
    tare_weight character varying(50),
    gross_weight character varying(50),
    packing_slip_no character varying(255)
);


ALTER TABLE masters.generate_packing OWNER TO textipro_admin;

--
-- TOC entry 323 (class 1259 OID 236578)
-- Name: generate_packing_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.generate_packing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.generate_packing_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4272 (class 0 OID 0)
-- Dependencies: 323
-- Name: generate_packing_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.generate_packing_id_seq OWNED BY masters.generate_packing.id;


--
-- TOC entry 326 (class 1259 OID 236603)
-- Name: generate_packing_item; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.generate_packing_item (
    id bigint NOT NULL,
    generated_packing_id bigint NOT NULL,
    roll_no character varying(50),
    length double precision,
    uom_id bigint,
    pounds double precision,
    lot_id bigint
);


ALTER TABLE masters.generate_packing_item OWNER TO textipro_admin;

--
-- TOC entry 325 (class 1259 OID 236602)
-- Name: generate_packing_item_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.generate_packing_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.generate_packing_item_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4273 (class 0 OID 0)
-- Dependencies: 325
-- Name: generate_packing_item_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.generate_packing_item_id_seq OWNED BY masters.generate_packing_item.id;


--
-- TOC entry 348 (class 1259 OID 261266)
-- Name: grade_master; Type: TABLE; Schema: masters; Owner: qbox_admin
--

CREATE TABLE masters.grade_master (
    id bigint NOT NULL,
    grade_code character varying(50) NOT NULL,
    grade_name character varying(100) NOT NULL,
    description text,
    active_flag boolean DEFAULT true,
    max_point smallint,
    min_point smallint
);


ALTER TABLE masters.grade_master OWNER TO qbox_admin;

--
-- TOC entry 347 (class 1259 OID 261265)
-- Name: grade_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: qbox_admin
--

CREATE SEQUENCE masters.grade_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.grade_master_id_seq OWNER TO qbox_admin;

--
-- TOC entry 4274 (class 0 OID 0)
-- Dependencies: 347
-- Name: grade_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: qbox_admin
--

ALTER SEQUENCE masters.grade_master_id_seq OWNED BY masters.grade_master.id;


--
-- TOC entry 252 (class 1259 OID 235803)
-- Name: gst_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.gst_master (
    id bigint NOT NULL,
    gst_name character varying(100) NOT NULL,
    description text,
    active_flag boolean DEFAULT true,
    cgst_rate character varying(255) NOT NULL,
    igst_rate character varying(255) NOT NULL,
    sgst_rate character varying(255) NOT NULL
);


ALTER TABLE masters.gst_master OWNER TO textipro_admin;

--
-- TOC entry 253 (class 1259 OID 235809)
-- Name: gst_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.gst_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.gst_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4275 (class 0 OID 0)
-- Dependencies: 253
-- Name: gst_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.gst_master_id_seq OWNED BY masters.gst_master.id;


--
-- TOC entry 254 (class 1259 OID 235810)
-- Name: inspection_dtl; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.inspection_dtl (
    id bigint NOT NULL,
    fabric_inspection_id bigint,
    roll_no character varying(100) NOT NULL,
    doff_meters double precision,
    inspected_meters double precision,
    weight double precision,
    total_defect_points double precision,
    defect_counts double precision,
    grade character varying(100),
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.inspection_dtl OWNER TO textipro_admin;

--
-- TOC entry 255 (class 1259 OID 235814)
-- Name: inspection_dtl_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.inspection_dtl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.inspection_dtl_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4276 (class 0 OID 0)
-- Dependencies: 255
-- Name: inspection_dtl_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.inspection_dtl_id_seq OWNED BY masters.inspection_dtl.id;


--
-- TOC entry 256 (class 1259 OID 235815)
-- Name: inspection_entry; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.inspection_entry (
    id bigint NOT NULL,
    fabric_inspection_id bigint,
    defected_meters double precision,
    from_meters double precision,
    to_meters double precision,
    defect_type_id bigint,
    defect_points double precision,
    inspection_id bigint,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.inspection_entry OWNER TO textipro_admin;

--
-- TOC entry 257 (class 1259 OID 235819)
-- Name: inspection_entry_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.inspection_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.inspection_entry_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4277 (class 0 OID 0)
-- Dependencies: 257
-- Name: inspection_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.inspection_entry_id_seq OWNED BY masters.inspection_entry.id;


--
-- TOC entry 258 (class 1259 OID 235820)
-- Name: jobwork_fabric_receive; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.jobwork_fabric_receive (
    id bigint NOT NULL,
    weaving_contract_id bigint NOT NULL,
    vendor_id bigint NOT NULL,
    job_fabric_receive_date date DEFAULT CURRENT_DATE NOT NULL,
    remarks text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.jobwork_fabric_receive OWNER TO textipro_admin;

--
-- TOC entry 259 (class 1259 OID 235827)
-- Name: jobwork_fabric_receive_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.jobwork_fabric_receive_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.jobwork_fabric_receive_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4278 (class 0 OID 0)
-- Dependencies: 259
-- Name: jobwork_fabric_receive_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.jobwork_fabric_receive_id_seq OWNED BY masters.jobwork_fabric_receive.id;


--
-- TOC entry 260 (class 1259 OID 235828)
-- Name: jobwork_fabric_receive_item; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.jobwork_fabric_receive_item (
    id bigint NOT NULL,
    jobwork_fabric_receive_id bigint NOT NULL,
    weaving_contract_item_id bigint NOT NULL,
    quantity_received numeric(38,2) NOT NULL,
    price numeric(38,2),
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE masters.jobwork_fabric_receive_item OWNER TO textipro_admin;

--
-- TOC entry 261 (class 1259 OID 235832)
-- Name: jobwork_fabric_receive_item_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.jobwork_fabric_receive_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.jobwork_fabric_receive_item_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4279 (class 0 OID 0)
-- Dependencies: 261
-- Name: jobwork_fabric_receive_item_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.jobwork_fabric_receive_item_id_seq OWNED BY masters.jobwork_fabric_receive_item.id;


--
-- TOC entry 320 (class 1259 OID 236556)
-- Name: knitted_fabric_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.knitted_fabric_master (
    id bigint NOT NULL,
    composition character varying(255),
    fabric_category_id smallint,
    fabric_code character varying(255),
    fabric_name character varying(255),
    fabric_type_id smallint,
    gsm numeric(38,2),
    knitted_fabric_id bigint,
    remarks character varying(255),
    shrinkage character varying(255),
    width character varying(255)
);


ALTER TABLE masters.knitted_fabric_master OWNER TO textipro_admin;

--
-- TOC entry 319 (class 1259 OID 236555)
-- Name: knitted_fabric_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.knitted_fabric_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.knitted_fabric_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4280 (class 0 OID 0)
-- Dependencies: 319
-- Name: knitted_fabric_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.knitted_fabric_master_id_seq OWNED BY masters.knitted_fabric_master.id;


--
-- TOC entry 262 (class 1259 OID 235833)
-- Name: lot_entry; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.lot_entry (
    id bigint NOT NULL,
    inward_item_id bigint NOT NULL,
    lot_number character varying(100),
    quantity numeric(38,2),
    rejected_quantity numeric(38,2),
    cost numeric(38,2),
    remarks text,
    active_flag boolean DEFAULT true,
    warehouse_id bigint
);


ALTER TABLE masters.lot_entry OWNER TO textipro_admin;

--
-- TOC entry 263 (class 1259 OID 235839)
-- Name: lot_entry_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.lot_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.lot_entry_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4281 (class 0 OID 0)
-- Dependencies: 263
-- Name: lot_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.lot_entry_id_seq OWNED BY masters.lot_entry.id;


--
-- TOC entry 352 (class 1259 OID 261286)
-- Name: lot_outward; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.lot_outward (
    id bigint NOT NULL,
    active_flag boolean,
    created_at timestamp(6) without time zone,
    created_by character varying(100),
    lot_entry_id bigint NOT NULL,
    outward_date date NOT NULL,
    outward_type character varying(50) NOT NULL,
    quantity numeric(38,2) NOT NULL,
    reference_id bigint,
    reference_type character varying(50),
    remarks character varying(255),
    updated_at timestamp(6) without time zone
);


ALTER TABLE masters.lot_outward OWNER TO textipro_admin;

--
-- TOC entry 351 (class 1259 OID 261285)
-- Name: lot_outward_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.lot_outward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.lot_outward_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4282 (class 0 OID 0)
-- Dependencies: 351
-- Name: lot_outward_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.lot_outward_id_seq OWNED BY masters.lot_outward.id;


--
-- TOC entry 264 (class 1259 OID 235840)
-- Name: payment_terms; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.payment_terms (
    id bigint NOT NULL,
    term_name character varying(50) NOT NULL,
    description text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.payment_terms OWNER TO textipro_admin;

--
-- TOC entry 265 (class 1259 OID 235846)
-- Name: payment_terms_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.payment_terms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.payment_terms_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4283 (class 0 OID 0)
-- Dependencies: 265
-- Name: payment_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.payment_terms_id_seq OWNED BY masters.payment_terms.id;


--
-- TOC entry 266 (class 1259 OID 235847)
-- Name: piece_entry; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.piece_entry (
    id bigint NOT NULL,
    jobwork_fabric_receive_item_id bigint NOT NULL,
    piece_number character varying(100),
    quantity numeric(38,2),
    weight numeric(38,2),
    cost numeric(38,2),
    remarks text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.piece_entry OWNER TO textipro_admin;

--
-- TOC entry 267 (class 1259 OID 235853)
-- Name: piece_entry_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.piece_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.piece_entry_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4284 (class 0 OID 0)
-- Dependencies: 267
-- Name: piece_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.piece_entry_id_seq OWNED BY masters.piece_entry.id;


--
-- TOC entry 268 (class 1259 OID 235854)
-- Name: po_type_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.po_type_master (
    id bigint NOT NULL,
    po_type_name character varying(100) NOT NULL,
    description text,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE masters.po_type_master OWNER TO textipro_admin;

--
-- TOC entry 269 (class 1259 OID 235860)
-- Name: po_type_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.po_type_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.po_type_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4285 (class 0 OID 0)
-- Dependencies: 269
-- Name: po_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.po_type_master_id_seq OWNED BY masters.po_type_master.id;


--
-- TOC entry 354 (class 1259 OID 272518)
-- Name: process_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.process_master (
    id bigint NOT NULL,
    active_flag boolean,
    description text,
    process_name character varying(100) NOT NULL
);


ALTER TABLE masters.process_master OWNER TO textipro_admin;

--
-- TOC entry 353 (class 1259 OID 272517)
-- Name: process_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.process_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.process_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4286 (class 0 OID 0)
-- Dependencies: 353
-- Name: process_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.process_master_id_seq OWNED BY masters.process_master.id;


--
-- TOC entry 270 (class 1259 OID 235861)
-- Name: product_category; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.product_category (
    id bigint NOT NULL,
    po_type_id bigint NOT NULL,
    product_category_name character varying(150) NOT NULL,
    fabric_code character varying(50) NOT NULL,
    fabric_quality character varying(150),
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE masters.product_category OWNER TO textipro_admin;

--
-- TOC entry 271 (class 1259 OID 235865)
-- Name: product_category_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.product_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.product_category_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4287 (class 0 OID 0)
-- Dependencies: 271
-- Name: product_category_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.product_category_id_seq OWNED BY masters.product_category.id;


--
-- TOC entry 272 (class 1259 OID 235866)
-- Name: purchase_inward; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.purchase_inward (
    id bigint NOT NULL,
    po_id bigint NOT NULL,
    inward_date timestamp without time zone DEFAULT CURRENT_DATE NOT NULL,
    remarks text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.purchase_inward OWNER TO textipro_admin;

--
-- TOC entry 273 (class 1259 OID 235873)
-- Name: purchase_inward_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.purchase_inward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.purchase_inward_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4288 (class 0 OID 0)
-- Dependencies: 273
-- Name: purchase_inward_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.purchase_inward_id_seq OWNED BY masters.purchase_inward.id;


--
-- TOC entry 274 (class 1259 OID 235874)
-- Name: purchase_inward_item; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.purchase_inward_item (
    id bigint NOT NULL,
    inward_id bigint NOT NULL,
    po_item_id bigint NOT NULL,
    quantity_received numeric(38,2) NOT NULL,
    price numeric(38,2),
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE masters.purchase_inward_item OWNER TO textipro_admin;

--
-- TOC entry 275 (class 1259 OID 235878)
-- Name: purchase_inward_item_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.purchase_inward_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.purchase_inward_item_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4289 (class 0 OID 0)
-- Dependencies: 275
-- Name: purchase_inward_item_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.purchase_inward_item_id_seq OWNED BY masters.purchase_inward_item.id;


--
-- TOC entry 276 (class 1259 OID 235879)
-- Name: purchase_orders; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.purchase_orders (
    id bigint NOT NULL,
    po_type_id bigint NOT NULL,
    po_date date NOT NULL,
    vendor_id bigint NOT NULL,
    tax_id bigint NOT NULL,
    active_flag boolean DEFAULT true,
    po_no character varying(50)
);


ALTER TABLE masters.purchase_orders OWNER TO textipro_admin;

--
-- TOC entry 277 (class 1259 OID 235883)
-- Name: purchase_order_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.purchase_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.purchase_order_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4290 (class 0 OID 0)
-- Dependencies: 277
-- Name: purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.purchase_order_id_seq OWNED BY masters.purchase_orders.id;


--
-- TOC entry 278 (class 1259 OID 235884)
-- Name: purchase_order_item; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.purchase_order_item (
    id bigint NOT NULL,
    po_id bigint NOT NULL,
    product_category_id bigint NOT NULL,
    quantity numeric(38,2) NOT NULL,
    unit character varying(20) NOT NULL,
    price numeric(38,2) NOT NULL,
    net_amount numeric(38,2),
    delivery_date timestamp without time zone NOT NULL,
    remarks text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.purchase_order_item OWNER TO textipro_admin;

--
-- TOC entry 279 (class 1259 OID 235890)
-- Name: purchase_order_item_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.purchase_order_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.purchase_order_item_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4291 (class 0 OID 0)
-- Dependencies: 279
-- Name: purchase_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.purchase_order_item_id_seq OWNED BY masters.purchase_order_item.id;


--
-- TOC entry 280 (class 1259 OID 235891)
-- Name: sales_order; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sales_order (
    id bigint NOT NULL,
    order_date timestamp(6) without time zone NOT NULL,
    buyer_customer_id bigint NOT NULL,
    buyer_po_no character varying(50),
    deliver_to_id bigint NOT NULL,
    currency_id bigint NOT NULL,
    exchange_rate double precision,
    mode_of_shipment_id bigint,
    shipment_terms_id bigint,
    terms_conditions_id bigint,
    active_flag boolean DEFAULT true,
    sales_order_no character varying(255),
    payment_terms_id bigint,
    internal_order_no character varying(255),
    packing_type_id smallint
);


ALTER TABLE masters.sales_order OWNER TO textipro_admin;

--
-- TOC entry 333 (class 1259 OID 238679)
-- Name: sales_order_ext_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sales_order_ext_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sales_order_ext_seq OWNER TO textipro_admin;

--
-- TOC entry 281 (class 1259 OID 235897)
-- Name: sales_order_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sales_order_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sales_order_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4292 (class 0 OID 0)
-- Dependencies: 281
-- Name: sales_order_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sales_order_id_seq OWNED BY masters.sales_order.id;


--
-- TOC entry 334 (class 1259 OID 238680)
-- Name: sales_order_int_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sales_order_int_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sales_order_int_seq OWNER TO textipro_admin;

--
-- TOC entry 282 (class 1259 OID 235898)
-- Name: sales_order_item; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sales_order_item (
    id bigint NOT NULL,
    sales_order_id bigint NOT NULL,
    fabric_type_id bigint NOT NULL,
    quality character varying(100) NOT NULL,
    buyer_product character varying(100),
    order_qty integer NOT NULL,
    price_per_unit double precision NOT NULL,
    uom_id bigint,
    total_amount double precision,
    gst_percent double precision,
    gst_amount double precision,
    final_amount double precision,
    delivery_date timestamp without time zone,
    remarks text,
    active_flag boolean DEFAULT true,
    fabric_master_type_id smallint,
    fabric_category_id smallint,
    fabric_master_id bigint
);


ALTER TABLE masters.sales_order_item OWNER TO textipro_admin;

--
-- TOC entry 283 (class 1259 OID 235904)
-- Name: sales_order_item_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sales_order_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sales_order_item_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4293 (class 0 OID 0)
-- Dependencies: 283
-- Name: sales_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sales_order_item_id_seq OWNED BY masters.sales_order_item.id;


--
-- TOC entry 284 (class 1259 OID 235905)
-- Name: shipment_mode; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.shipment_mode (
    id bigint NOT NULL,
    mode_name character varying(50) NOT NULL,
    description text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.shipment_mode OWNER TO textipro_admin;

--
-- TOC entry 285 (class 1259 OID 235911)
-- Name: shipment_mode_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.shipment_mode_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.shipment_mode_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4294 (class 0 OID 0)
-- Dependencies: 285
-- Name: shipment_mode_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.shipment_mode_id_seq OWNED BY masters.shipment_mode.id;


--
-- TOC entry 286 (class 1259 OID 235912)
-- Name: shipment_terms; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.shipment_terms (
    id bigint NOT NULL,
    term_name character varying(50) NOT NULL,
    description text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.shipment_terms OWNER TO textipro_admin;

--
-- TOC entry 287 (class 1259 OID 235918)
-- Name: shipment_terms_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.shipment_terms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.shipment_terms_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4295 (class 0 OID 0)
-- Dependencies: 287
-- Name: shipment_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.shipment_terms_id_seq OWNED BY masters.shipment_terms.id;


--
-- TOC entry 288 (class 1259 OID 235919)
-- Name: sizing_beam_details; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sizing_beam_details (
    id bigint NOT NULL,
    sizing_plan_id bigint NOT NULL,
    weaving_contract_id bigint NOT NULL,
    sales_order_id bigint NOT NULL,
    empty_beam_id bigint NOT NULL,
    wrap_meters bigint,
    shrinkage bigint,
    expected_fabric_meter bigint
);


ALTER TABLE masters.sizing_beam_details OWNER TO textipro_admin;

--
-- TOC entry 289 (class 1259 OID 235922)
-- Name: sizing_beam_details_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sizing_beam_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sizing_beam_details_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4296 (class 0 OID 0)
-- Dependencies: 289
-- Name: sizing_beam_details_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sizing_beam_details_id_seq OWNED BY masters.sizing_beam_details.id;


--
-- TOC entry 290 (class 1259 OID 235923)
-- Name: sizing_plan; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sizing_plan (
    id bigint NOT NULL,
    vendor_id bigint NOT NULL,
    terms_conditions_id bigint NOT NULL,
    consignee_id bigint NOT NULL,
    payment_terms_id bigint NOT NULL,
    sizing_rate double precision,
    remarks text,
    sizing_plan_no character varying(50)
);


ALTER TABLE masters.sizing_plan OWNER TO textipro_admin;

--
-- TOC entry 291 (class 1259 OID 235928)
-- Name: sizing_plan_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sizing_plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sizing_plan_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4297 (class 0 OID 0)
-- Dependencies: 291
-- Name: sizing_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sizing_plan_id_seq OWNED BY masters.sizing_plan.id;


--
-- TOC entry 292 (class 1259 OID 235929)
-- Name: sizing_quality_details; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sizing_quality_details (
    id bigint NOT NULL,
    sizing_plan_id bigint NOT NULL,
    quality character varying(255) NOT NULL,
    yarn_id bigint NOT NULL,
    sord_ends bigint NOT NULL,
    actual_ends bigint,
    parts bigint,
    ends_per_part bigint,
    wrap_meters bigint
);


ALTER TABLE masters.sizing_quality_details OWNER TO textipro_admin;

--
-- TOC entry 293 (class 1259 OID 235932)
-- Name: sizing_quality_details_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sizing_quality_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sizing_quality_details_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4298 (class 0 OID 0)
-- Dependencies: 293
-- Name: sizing_quality_details_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sizing_quality_details_id_seq OWNED BY masters.sizing_quality_details.id;


--
-- TOC entry 330 (class 1259 OID 238631)
-- Name: sizing_yarn_issue; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sizing_yarn_issue (
    id bigint NOT NULL,
    sizing_yarn_issue_entry_id bigint,
    lot_id bigint,
    yarn_name character varying(100) NOT NULL,
    available_req_qty numeric(38,2),
    issue_qty numeric(38,2),
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.sizing_yarn_issue OWNER TO textipro_admin;

--
-- TOC entry 328 (class 1259 OID 238587)
-- Name: sizing_yarn_issue_entry; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sizing_yarn_issue_entry (
    id bigint NOT NULL,
    vendor_id bigint NOT NULL,
    sizing_plan_id bigint NOT NULL,
    transportation_dtl text NOT NULL,
    terms_conditions_id bigint NOT NULL,
    fabric_dtl text,
    sizing_yarn_issue_date date,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.sizing_yarn_issue_entry OWNER TO textipro_admin;

--
-- TOC entry 327 (class 1259 OID 238586)
-- Name: sizing_yarn_issue_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sizing_yarn_issue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sizing_yarn_issue_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4299 (class 0 OID 0)
-- Dependencies: 327
-- Name: sizing_yarn_issue_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sizing_yarn_issue_id_seq OWNED BY masters.sizing_yarn_issue_entry.id;


--
-- TOC entry 329 (class 1259 OID 238630)
-- Name: sizing_yarn_issue_id_seq1; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sizing_yarn_issue_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sizing_yarn_issue_id_seq1 OWNER TO textipro_admin;

--
-- TOC entry 4300 (class 0 OID 0)
-- Dependencies: 329
-- Name: sizing_yarn_issue_id_seq1; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sizing_yarn_issue_id_seq1 OWNED BY masters.sizing_yarn_issue.id;


--
-- TOC entry 332 (class 1259 OID 238666)
-- Name: sizing_yarn_requirement; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sizing_yarn_requirement (
    id bigint NOT NULL,
    sizing_yarn_issue_entry_id bigint,
    yarn_name character varying(100) NOT NULL,
    yarn_count bigint,
    grams_per_meter numeric(38,2),
    total_req_qty numeric(38,2),
    total_issue_qty numeric(38,2),
    balance_to_issue numeric(38,2),
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.sizing_yarn_requirement OWNER TO textipro_admin;

--
-- TOC entry 331 (class 1259 OID 238665)
-- Name: sizing_yarn_requirement_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sizing_yarn_requirement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sizing_yarn_requirement_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4301 (class 0 OID 0)
-- Dependencies: 331
-- Name: sizing_yarn_requirement_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sizing_yarn_requirement_id_seq OWNED BY masters.sizing_yarn_requirement.id;


--
-- TOC entry 294 (class 1259 OID 235933)
-- Name: state; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.state (
    id bigint NOT NULL,
    country_sno bigint NOT NULL,
    state_name character varying(100) NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.state OWNER TO textipro_admin;

--
-- TOC entry 295 (class 1259 OID 235937)
-- Name: state_state_sno_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.state_state_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.state_state_sno_seq OWNER TO textipro_admin;

--
-- TOC entry 4302 (class 0 OID 0)
-- Dependencies: 295
-- Name: state_state_sno_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.state_state_sno_seq OWNED BY masters.state.id;


--
-- TOC entry 296 (class 1259 OID 235938)
-- Name: sub_category; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.sub_category (
    id bigint NOT NULL,
    category_sno bigint NOT NULL,
    sub_category_name character varying(100) NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.sub_category OWNER TO textipro_admin;

--
-- TOC entry 297 (class 1259 OID 235942)
-- Name: sub_category_sub_category_sno_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.sub_category_sub_category_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.sub_category_sub_category_sno_seq OWNER TO textipro_admin;

--
-- TOC entry 4303 (class 0 OID 0)
-- Dependencies: 297
-- Name: sub_category_sub_category_sno_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.sub_category_sub_category_sno_seq OWNED BY masters.sub_category.id;


--
-- TOC entry 298 (class 1259 OID 235943)
-- Name: tax_type; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.tax_type (
    id bigint NOT NULL,
    tax_type_name character varying(50) NOT NULL,
    description text,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE masters.tax_type OWNER TO textipro_admin;

--
-- TOC entry 299 (class 1259 OID 235949)
-- Name: tax_type_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.tax_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.tax_type_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4304 (class 0 OID 0)
-- Dependencies: 299
-- Name: tax_type_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.tax_type_id_seq OWNED BY masters.tax_type.id;


--
-- TOC entry 300 (class 1259 OID 235950)
-- Name: terms_conditions; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.terms_conditions (
    id bigint DEFAULT nextval('masters.shipment_terms_id_seq'::regclass) NOT NULL,
    terms_conditions_name character varying(50) NOT NULL,
    description text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.terms_conditions OWNER TO textipro_admin;

--
-- TOC entry 301 (class 1259 OID 235957)
-- Name: uom; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.uom (
    id bigint NOT NULL,
    uom_code character varying(10) NOT NULL,
    uom_name character varying(50) NOT NULL,
    description text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.uom OWNER TO textipro_admin;

--
-- TOC entry 302 (class 1259 OID 235963)
-- Name: uom_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.uom_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.uom_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4305 (class 0 OID 0)
-- Dependencies: 302
-- Name: uom_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.uom_id_seq OWNED BY masters.uom.id;


--
-- TOC entry 303 (class 1259 OID 235964)
-- Name: vendor; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.vendor (
    id bigint NOT NULL,
    vendor_name character varying(100) NOT NULL,
    gstno text NOT NULL,
    pancard text NOT NULL,
    mobileno text NOT NULL,
    email text NOT NULL,
    address_id bigint,
    active_flag boolean DEFAULT true,
    photo_url text
);


ALTER TABLE masters.vendor OWNER TO textipro_admin;

--
-- TOC entry 304 (class 1259 OID 235970)
-- Name: vendor_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.vendor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.vendor_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4306 (class 0 OID 0)
-- Dependencies: 304
-- Name: vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.vendor_id_seq OWNED BY masters.vendor.id;


--
-- TOC entry 322 (class 1259 OID 236572)
-- Name: warehouse_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.warehouse_master (
    id bigint NOT NULL,
    active_flag boolean,
    warehouse_name character varying(100) NOT NULL
);


ALTER TABLE masters.warehouse_master OWNER TO textipro_admin;

--
-- TOC entry 321 (class 1259 OID 236571)
-- Name: warehouse_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.warehouse_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.warehouse_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4307 (class 0 OID 0)
-- Dependencies: 321
-- Name: warehouse_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.warehouse_master_id_seq OWNED BY masters.warehouse_master.id;


--
-- TOC entry 305 (class 1259 OID 235971)
-- Name: weaving_contract; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.weaving_contract (
    id bigint NOT NULL,
    sales_order_no bigint NOT NULL,
    vendor_id bigint,
    terms_conditions_id bigint,
    payment_terms_id bigint,
    remarks text,
    active_flag boolean DEFAULT true,
    weaving_contract_no character varying(255) NOT NULL
);


ALTER TABLE masters.weaving_contract OWNER TO textipro_admin;

--
-- TOC entry 306 (class 1259 OID 235977)
-- Name: weaving_contract_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.weaving_contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.weaving_contract_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4308 (class 0 OID 0)
-- Dependencies: 306
-- Name: weaving_contract_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.weaving_contract_id_seq OWNED BY masters.weaving_contract.id;


--
-- TOC entry 307 (class 1259 OID 235978)
-- Name: weaving_contract_item; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.weaving_contract_item (
    id bigint NOT NULL,
    weaving_contract_id bigint NOT NULL,
    fabric_code_id bigint NOT NULL,
    fabric_quality_id bigint NOT NULL,
    quantity numeric(38,2),
    pick_cost numeric(38,2),
    planned_start_date date,
    planned_end_date date,
    daily_target numeric(38,2),
    number_of_looms integer,
    warp_length numeric(38,2),
    warp_crimp_percentage numeric(38,2),
    piece_length numeric(38,2),
    number_of_pieces integer,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.weaving_contract_item OWNER TO textipro_admin;

--
-- TOC entry 308 (class 1259 OID 235982)
-- Name: weaving_contract_item_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.weaving_contract_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.weaving_contract_item_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4309 (class 0 OID 0)
-- Dependencies: 308
-- Name: weaving_contract_item_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.weaving_contract_item_id_seq OWNED BY masters.weaving_contract_item.id;


--
-- TOC entry 309 (class 1259 OID 235983)
-- Name: weaving_yarn_issue; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.weaving_yarn_issue (
    id bigint NOT NULL,
    vendor_id bigint NOT NULL,
    weaving_contract_id bigint NOT NULL,
    transportation_dtl text NOT NULL,
    terms_conditions_id bigint NOT NULL,
    fabric_dtl text,
    yarn_issue_date date,
    yarn_issue_challan_no text,
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.weaving_yarn_issue OWNER TO textipro_admin;

--
-- TOC entry 310 (class 1259 OID 235989)
-- Name: weaving_yarn_issue_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.weaving_yarn_issue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.weaving_yarn_issue_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4310 (class 0 OID 0)
-- Dependencies: 310
-- Name: weaving_yarn_issue_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.weaving_yarn_issue_id_seq OWNED BY masters.weaving_yarn_issue.id;


--
-- TOC entry 311 (class 1259 OID 235990)
-- Name: weaving_yarn_requirement; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.weaving_yarn_requirement (
    id bigint NOT NULL,
    weaving_yarn_issue_id bigint,
    yarn_name character varying(100) NOT NULL,
    yarn_count bigint,
    grams_per_meter numeric(38,2),
    total_req_qty numeric(38,2),
    total_issue_qty numeric(38,2),
    balance_to_issue numeric(38,2),
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.weaving_yarn_requirement OWNER TO textipro_admin;

--
-- TOC entry 312 (class 1259 OID 235994)
-- Name: weaving_yarn_requirement_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.weaving_yarn_requirement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.weaving_yarn_requirement_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4311 (class 0 OID 0)
-- Dependencies: 312
-- Name: weaving_yarn_requirement_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.weaving_yarn_requirement_id_seq OWNED BY masters.weaving_yarn_requirement.id;


--
-- TOC entry 313 (class 1259 OID 235995)
-- Name: yarn_issue; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.yarn_issue (
    id bigint NOT NULL,
    weaving_yarn_requirement_id bigint,
    lot_id bigint,
    yarn_name character varying(100) NOT NULL,
    available_req_qty numeric(38,2),
    issue_qty numeric(38,2),
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.yarn_issue OWNER TO textipro_admin;

--
-- TOC entry 314 (class 1259 OID 235999)
-- Name: yarn_issue_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.yarn_issue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.yarn_issue_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4312 (class 0 OID 0)
-- Dependencies: 314
-- Name: yarn_issue_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.yarn_issue_id_seq OWNED BY masters.yarn_issue.id;


--
-- TOC entry 315 (class 1259 OID 236000)
-- Name: yarn_master; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.yarn_master (
    id bigint NOT NULL,
    yarn_name character varying(50) NOT NULL,
    count_sno smallint NOT NULL,
    types character varying(50) NOT NULL,
    conversion double precision NOT NULL,
    active_flag boolean DEFAULT true,
    unit_sno smallint,
    content character varying(50)
);


ALTER TABLE masters.yarn_master OWNER TO textipro_admin;

--
-- TOC entry 316 (class 1259 OID 236004)
-- Name: yarn_master_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.yarn_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.yarn_master_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4313 (class 0 OID 0)
-- Dependencies: 316
-- Name: yarn_master_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.yarn_master_id_seq OWNED BY masters.yarn_master.id;


--
-- TOC entry 317 (class 1259 OID 236005)
-- Name: yarn_requirement; Type: TABLE; Schema: masters; Owner: textipro_admin
--

CREATE TABLE masters.yarn_requirement (
    id bigint NOT NULL,
    weaving_contract_id bigint NOT NULL,
    yarn_type character varying(10),
    yarn_count character varying(50),
    grams_per_meter numeric(38,2),
    total_weaving_order_qty numeric(38,2),
    total_required_qty numeric(38,2),
    total_available_qty numeric(38,2),
    active_flag boolean DEFAULT true
);


ALTER TABLE masters.yarn_requirement OWNER TO textipro_admin;

--
-- TOC entry 318 (class 1259 OID 236009)
-- Name: yarn_requirement_id_seq; Type: SEQUENCE; Schema: masters; Owner: textipro_admin
--

CREATE SEQUENCE masters.yarn_requirement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE masters.yarn_requirement_id_seq OWNER TO textipro_admin;

--
-- TOC entry 4314 (class 0 OID 0)
-- Dependencies: 318
-- Name: yarn_requirement_id_seq; Type: SEQUENCE OWNED BY; Schema: masters; Owner: textipro_admin
--

ALTER SEQUENCE masters.yarn_requirement_id_seq OWNED BY masters.yarn_requirement.id;


--
-- TOC entry 3565 (class 2604 OID 236010)
-- Name: address id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.address ALTER COLUMN id SET DEFAULT nextval('masters.address_id_seq'::regclass);


--
-- TOC entry 3680 (class 2604 OID 238686)
-- Name: beam_inward id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.beam_inward ALTER COLUMN id SET DEFAULT nextval('masters.beam_inward_id_seq'::regclass);


--
-- TOC entry 3681 (class 2604 OID 238695)
-- Name: beam_inward_beam_details id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.beam_inward_beam_details ALTER COLUMN id SET DEFAULT nextval('masters.beam_inward_beam_details_id_seq'::regclass);


--
-- TOC entry 3682 (class 2604 OID 238702)
-- Name: beam_inward_quality_details id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.beam_inward_quality_details ALTER COLUMN id SET DEFAULT nextval('masters.beam_inward_quality_details_id_seq'::regclass);


--
-- TOC entry 3567 (class 2604 OID 236011)
-- Name: category id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.category ALTER COLUMN id SET DEFAULT nextval('masters.category_id_seq'::regclass);


--
-- TOC entry 3569 (class 2604 OID 236012)
-- Name: city id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.city ALTER COLUMN id SET DEFAULT nextval('masters.city_city_sno_seq'::regclass);


--
-- TOC entry 3571 (class 2604 OID 236013)
-- Name: consignee id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.consignee ALTER COLUMN id SET DEFAULT nextval('masters.consignee_id_seq'::regclass);


--
-- TOC entry 3573 (class 2604 OID 236014)
-- Name: country id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.country ALTER COLUMN id SET DEFAULT nextval('masters.country_id_seq'::regclass);


--
-- TOC entry 3575 (class 2604 OID 236015)
-- Name: currency_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.currency_master ALTER COLUMN id SET DEFAULT nextval('masters.currency_master_id_seq'::regclass);


--
-- TOC entry 3577 (class 2604 OID 236016)
-- Name: customer id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.customer ALTER COLUMN id SET DEFAULT nextval('masters.customer_id_seq'::regclass);


--
-- TOC entry 3683 (class 2604 OID 238719)
-- Name: customer_international id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.customer_international ALTER COLUMN id SET DEFAULT nextval('masters.customer_international_id_seq'::regclass);


--
-- TOC entry 3691 (class 2604 OID 261279)
-- Name: defect_master id; Type: DEFAULT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.defect_master ALTER COLUMN id SET DEFAULT nextval('masters.defect_master_id_seq'::regclass);


--
-- TOC entry 3579 (class 2604 OID 236017)
-- Name: dyeing_work_order id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.dyeing_work_order ALTER COLUMN id SET DEFAULT nextval('masters.dyeing_work_order_id_seq'::regclass);


--
-- TOC entry 3581 (class 2604 OID 236018)
-- Name: dyeing_work_order_items id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.dyeing_work_order_items ALTER COLUMN id SET DEFAULT nextval('masters.dyeing_work_order_items_id_seq'::regclass);


--
-- TOC entry 3583 (class 2604 OID 236019)
-- Name: empty_beam_issue id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.empty_beam_issue ALTER COLUMN id SET DEFAULT nextval('masters.empty_beam_issue_id_seq'::regclass);


--
-- TOC entry 3584 (class 2604 OID 236020)
-- Name: empty_beam_issue_item id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.empty_beam_issue_item ALTER COLUMN id SET DEFAULT nextval('masters.empty_beam_issue_item_id_seq'::regclass);


--
-- TOC entry 3586 (class 2604 OID 236021)
-- Name: fabric_category id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_category ALTER COLUMN id SET DEFAULT nextval('masters.fabric_category_id_seq'::regclass);


--
-- TOC entry 3588 (class 2604 OID 236022)
-- Name: fabric_dispatch_for_dyeing id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_dispatch_for_dyeing ALTER COLUMN id SET DEFAULT nextval('masters.fabric_dispatch_for_dyeing_id_seq'::regclass);


--
-- TOC entry 3590 (class 2604 OID 236023)
-- Name: fabric_inspection id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_inspection ALTER COLUMN id SET DEFAULT nextval('masters.fabric_inspection_id_seq'::regclass);


--
-- TOC entry 3593 (class 2604 OID 236024)
-- Name: fabric_type id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_type ALTER COLUMN id SET DEFAULT nextval('masters.fabric_type_fabric_type_sno_seq'::regclass);


--
-- TOC entry 3595 (class 2604 OID 236025)
-- Name: fabric_warp_detail id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_warp_detail ALTER COLUMN id SET DEFAULT nextval('masters.fabric_warp_detail_id_seq'::regclass);


--
-- TOC entry 3596 (class 2604 OID 236026)
-- Name: fabric_weft_detail id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_weft_detail ALTER COLUMN id SET DEFAULT nextval('masters.fabric_weft_detail_id_seq'::regclass);


--
-- TOC entry 3685 (class 2604 OID 261228)
-- Name: finish_fabric_receive id; Type: DEFAULT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.finish_fabric_receive ALTER COLUMN id SET DEFAULT nextval('masters.finish_fabric_recive_id_seq'::regclass);


--
-- TOC entry 3687 (class 2604 OID 261238)
-- Name: finish_fabric_receive_items id; Type: DEFAULT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.finish_fabric_receive_items ALTER COLUMN id SET DEFAULT nextval('masters.finish_fabric_recive_items_id_seq'::regclass);


--
-- TOC entry 3597 (class 2604 OID 236027)
-- Name: finish_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.finish_master ALTER COLUMN id SET DEFAULT nextval('masters.finish_master_id_seq'::regclass);


--
-- TOC entry 3599 (class 2604 OID 236028)
-- Name: flange_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.flange_master ALTER COLUMN id SET DEFAULT nextval('masters.flange_master_id_seq'::regclass);


--
-- TOC entry 3601 (class 2604 OID 236029)
-- Name: generate_invoice id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_invoice ALTER COLUMN id SET DEFAULT nextval('masters.generate_invoice_id_seq'::regclass);


--
-- TOC entry 3672 (class 2604 OID 236582)
-- Name: generate_packing id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing ALTER COLUMN id SET DEFAULT nextval('masters.generate_packing_id_seq'::regclass);


--
-- TOC entry 3673 (class 2604 OID 236606)
-- Name: generate_packing_item id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing_item ALTER COLUMN id SET DEFAULT nextval('masters.generate_packing_item_id_seq'::regclass);


--
-- TOC entry 3689 (class 2604 OID 261269)
-- Name: grade_master id; Type: DEFAULT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.grade_master ALTER COLUMN id SET DEFAULT nextval('masters.grade_master_id_seq'::regclass);


--
-- TOC entry 3603 (class 2604 OID 236030)
-- Name: gst_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.gst_master ALTER COLUMN id SET DEFAULT nextval('masters.gst_master_id_seq'::regclass);


--
-- TOC entry 3605 (class 2604 OID 236031)
-- Name: inspection_dtl id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.inspection_dtl ALTER COLUMN id SET DEFAULT nextval('masters.inspection_dtl_id_seq'::regclass);


--
-- TOC entry 3607 (class 2604 OID 236032)
-- Name: inspection_entry id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.inspection_entry ALTER COLUMN id SET DEFAULT nextval('masters.inspection_entry_id_seq'::regclass);


--
-- TOC entry 3609 (class 2604 OID 236033)
-- Name: jobwork_fabric_receive id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.jobwork_fabric_receive ALTER COLUMN id SET DEFAULT nextval('masters.jobwork_fabric_receive_id_seq'::regclass);


--
-- TOC entry 3612 (class 2604 OID 236034)
-- Name: jobwork_fabric_receive_item id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.jobwork_fabric_receive_item ALTER COLUMN id SET DEFAULT nextval('masters.jobwork_fabric_receive_item_id_seq'::regclass);


--
-- TOC entry 3670 (class 2604 OID 236559)
-- Name: knitted_fabric_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.knitted_fabric_master ALTER COLUMN id SET DEFAULT nextval('masters.knitted_fabric_master_id_seq'::regclass);


--
-- TOC entry 3614 (class 2604 OID 236035)
-- Name: lot_entry id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.lot_entry ALTER COLUMN id SET DEFAULT nextval('masters.lot_entry_id_seq'::regclass);


--
-- TOC entry 3693 (class 2604 OID 261289)
-- Name: lot_outward id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.lot_outward ALTER COLUMN id SET DEFAULT nextval('masters.lot_outward_id_seq'::regclass);


--
-- TOC entry 3616 (class 2604 OID 236036)
-- Name: payment_terms id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.payment_terms ALTER COLUMN id SET DEFAULT nextval('masters.payment_terms_id_seq'::regclass);


--
-- TOC entry 3618 (class 2604 OID 236037)
-- Name: piece_entry id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.piece_entry ALTER COLUMN id SET DEFAULT nextval('masters.piece_entry_id_seq'::regclass);


--
-- TOC entry 3620 (class 2604 OID 236038)
-- Name: po_type_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.po_type_master ALTER COLUMN id SET DEFAULT nextval('masters.po_type_master_id_seq'::regclass);


--
-- TOC entry 3694 (class 2604 OID 272521)
-- Name: process_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.process_master ALTER COLUMN id SET DEFAULT nextval('masters.process_master_id_seq'::regclass);


--
-- TOC entry 3622 (class 2604 OID 236039)
-- Name: product_category id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.product_category ALTER COLUMN id SET DEFAULT nextval('masters.product_category_id_seq'::regclass);


--
-- TOC entry 3624 (class 2604 OID 236040)
-- Name: purchase_inward id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_inward ALTER COLUMN id SET DEFAULT nextval('masters.purchase_inward_id_seq'::regclass);


--
-- TOC entry 3627 (class 2604 OID 236041)
-- Name: purchase_inward_item id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_inward_item ALTER COLUMN id SET DEFAULT nextval('masters.purchase_inward_item_id_seq'::regclass);


--
-- TOC entry 3631 (class 2604 OID 236042)
-- Name: purchase_order_item id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_order_item ALTER COLUMN id SET DEFAULT nextval('masters.purchase_order_item_id_seq'::regclass);


--
-- TOC entry 3629 (class 2604 OID 236043)
-- Name: purchase_orders id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_orders ALTER COLUMN id SET DEFAULT nextval('masters.purchase_order_id_seq'::regclass);


--
-- TOC entry 3633 (class 2604 OID 236044)
-- Name: sales_order id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order ALTER COLUMN id SET DEFAULT nextval('masters.sales_order_id_seq'::regclass);


--
-- TOC entry 3635 (class 2604 OID 236045)
-- Name: sales_order_item id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order_item ALTER COLUMN id SET DEFAULT nextval('masters.sales_order_item_id_seq'::regclass);


--
-- TOC entry 3637 (class 2604 OID 236046)
-- Name: shipment_mode id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.shipment_mode ALTER COLUMN id SET DEFAULT nextval('masters.shipment_mode_id_seq'::regclass);


--
-- TOC entry 3639 (class 2604 OID 236047)
-- Name: shipment_terms id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.shipment_terms ALTER COLUMN id SET DEFAULT nextval('masters.shipment_terms_id_seq'::regclass);


--
-- TOC entry 3641 (class 2604 OID 236048)
-- Name: sizing_beam_details id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_beam_details ALTER COLUMN id SET DEFAULT nextval('masters.sizing_beam_details_id_seq'::regclass);


--
-- TOC entry 3642 (class 2604 OID 236049)
-- Name: sizing_plan id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_plan ALTER COLUMN id SET DEFAULT nextval('masters.sizing_plan_id_seq'::regclass);


--
-- TOC entry 3643 (class 2604 OID 236050)
-- Name: sizing_quality_details id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_quality_details ALTER COLUMN id SET DEFAULT nextval('masters.sizing_quality_details_id_seq'::regclass);


--
-- TOC entry 3676 (class 2604 OID 238634)
-- Name: sizing_yarn_issue id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue ALTER COLUMN id SET DEFAULT nextval('masters.sizing_yarn_issue_id_seq1'::regclass);


--
-- TOC entry 3674 (class 2604 OID 238590)
-- Name: sizing_yarn_issue_entry id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue_entry ALTER COLUMN id SET DEFAULT nextval('masters.sizing_yarn_issue_id_seq'::regclass);


--
-- TOC entry 3678 (class 2604 OID 238669)
-- Name: sizing_yarn_requirement id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_requirement ALTER COLUMN id SET DEFAULT nextval('masters.sizing_yarn_requirement_id_seq'::regclass);


--
-- TOC entry 3644 (class 2604 OID 236051)
-- Name: state id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.state ALTER COLUMN id SET DEFAULT nextval('masters.state_state_sno_seq'::regclass);


--
-- TOC entry 3646 (class 2604 OID 236052)
-- Name: sub_category id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sub_category ALTER COLUMN id SET DEFAULT nextval('masters.sub_category_sub_category_sno_seq'::regclass);


--
-- TOC entry 3648 (class 2604 OID 236053)
-- Name: tax_type id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.tax_type ALTER COLUMN id SET DEFAULT nextval('masters.tax_type_id_seq'::regclass);


--
-- TOC entry 3652 (class 2604 OID 236054)
-- Name: uom id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.uom ALTER COLUMN id SET DEFAULT nextval('masters.uom_id_seq'::regclass);


--
-- TOC entry 3654 (class 2604 OID 236055)
-- Name: vendor id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.vendor ALTER COLUMN id SET DEFAULT nextval('masters.vendor_id_seq'::regclass);


--
-- TOC entry 3671 (class 2604 OID 236575)
-- Name: warehouse_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.warehouse_master ALTER COLUMN id SET DEFAULT nextval('masters.warehouse_master_id_seq'::regclass);


--
-- TOC entry 3656 (class 2604 OID 236056)
-- Name: weaving_contract id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract ALTER COLUMN id SET DEFAULT nextval('masters.weaving_contract_id_seq'::regclass);


--
-- TOC entry 3658 (class 2604 OID 236057)
-- Name: weaving_contract_item id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract_item ALTER COLUMN id SET DEFAULT nextval('masters.weaving_contract_item_id_seq'::regclass);


--
-- TOC entry 3660 (class 2604 OID 236058)
-- Name: weaving_yarn_issue id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_yarn_issue ALTER COLUMN id SET DEFAULT nextval('masters.weaving_yarn_issue_id_seq'::regclass);


--
-- TOC entry 3662 (class 2604 OID 236059)
-- Name: weaving_yarn_requirement id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_yarn_requirement ALTER COLUMN id SET DEFAULT nextval('masters.weaving_yarn_requirement_id_seq'::regclass);


--
-- TOC entry 3592 (class 2604 OID 236060)
-- Name: woven_fabric_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.woven_fabric_master ALTER COLUMN id SET DEFAULT nextval('masters.fabric_master_id_seq'::regclass);


--
-- TOC entry 3664 (class 2604 OID 236061)
-- Name: yarn_issue id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_issue ALTER COLUMN id SET DEFAULT nextval('masters.yarn_issue_id_seq'::regclass);


--
-- TOC entry 3666 (class 2604 OID 236062)
-- Name: yarn_master id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_master ALTER COLUMN id SET DEFAULT nextval('masters.yarn_master_id_seq'::regclass);


--
-- TOC entry 3668 (class 2604 OID 236063)
-- Name: yarn_requirement id; Type: DEFAULT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_requirement ALTER COLUMN id SET DEFAULT nextval('masters.yarn_requirement_id_seq'::regclass);


--
-- TOC entry 4094 (class 0 OID 235684)
-- Dependencies: 210
-- Data for Name: address; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (1, 'Thiruvalluvar street', 'Govindasalai', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (2, 'nehru street', 'gk nagar', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (3, 'dsfs', 'dfdsfs', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (4, 'kannan street', 'string', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (5, 'Nehru Street', 'string', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (6, 'Govindasalai', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (7, 'Govindasalai', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (8, 'Govindasalai', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (9, 'Govindasalai', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (10, 'Govindasalai', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (11, 'Govin nagar', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (12, 'nehru street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (13, 'nehru street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (14, 'nehru street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (15, 'nehru street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (16, 'Ganga Street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (17, 'Nehru Street', 'string', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (18, 'nehri street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (19, 'nehru street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (20, 'nehru street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (21, 'nehri street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (22, 'sample1', 'sample2', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (23, 'sad', 'sad', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (24, 'sad', 'sad', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (25, 'sad', 'sad', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (26, 'sad', 'sad', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (27, 'sadsad', 'sad', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (28, 'sdff', 'stsdfsring', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (29, 'sdff', 'stsdfsring', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (30, 'sdfsdf', 'sdfsdf', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (32, 'sdfsdf', 'sdfsdf', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (31, 'sdfsdf', 'sdfsdf', 1, 1, 4, true, 605011);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (33, 'nehru street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (34, 'nehru street', '', 1, 1, 4, true, NULL);
INSERT INTO masters.address (id, line1, line2, country_id, state_id, city_id, active_flag, pin_code) VALUES (35, 'ewr', 'werew', 1, 1, 4, true, 9876567);


--
-- TOC entry 4220 (class 0 OID 238683)
-- Dependencies: 336
-- Data for Name: beam_inward; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.beam_inward (id, beam_inward_no, consignee_id, payment_terms_id, remarks, sizing_plan_id, sizing_rate, terms_conditions_id, vendor_id) VALUES (1, 'BI-2025-0001', 3, 2, 'Beam Inward', 5, 2, 5, 1);
INSERT INTO masters.beam_inward (id, beam_inward_no, consignee_id, payment_terms_id, remarks, sizing_plan_id, sizing_rate, terms_conditions_id, vendor_id) VALUES (5, 'BI-20250802-9653', 3, 2, 'Test remarks', NULL, 12.5, 5, 1);


--
-- TOC entry 4222 (class 0 OID 238692)
-- Dependencies: 338
-- Data for Name: beam_inward_beam_details; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.beam_inward_beam_details (id, empty_beam_id, expected_fabric_meter, sales_order_id, shrinkage, weaving_contract_id, wrap_meters, beam_inward_id) VALUES (1, 9, 100, 29, 100, 1, 100, 1);
INSERT INTO masters.beam_inward_beam_details (id, empty_beam_id, expected_fabric_meter, sales_order_id, shrinkage, weaving_contract_id, wrap_meters, beam_inward_id) VALUES (6, 9, 1450, 29, 2, 1, NULL, 5);


--
-- TOC entry 4224 (class 0 OID 238699)
-- Dependencies: 340
-- Data for Name: beam_inward_quality_details; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.beam_inward_quality_details (id, actual_ends, ends_per_part, parts, quality, sord_ends, wrap_meters, yarn_id, beam_inward_id) VALUES (1, 100, 100, 100, '100', 100, 100, 1, 1);
INSERT INTO masters.beam_inward_quality_details (id, actual_ends, ends_per_part, parts, quality, sord_ends, wrap_meters, yarn_id, beam_inward_id) VALUES (6, 790, 200, 4, 'Premium Cotton', 800, NULL, 1, 5);


--
-- TOC entry 4096 (class 0 OID 235691)
-- Dependencies: 212
-- Data for Name: category; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.category (id, category_name, active_flag) VALUES (1, 'Colour', true);
INSERT INTO masters.category (id, category_name, active_flag) VALUES (2, 'Counts', true);
INSERT INTO masters.category (id, category_name, active_flag) VALUES (3, 'Weave', true);


--
-- TOC entry 4098 (class 0 OID 235696)
-- Dependencies: 214
-- Data for Name: city; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.city (id, country_sno, state_sno, city_name, active_flag) VALUES (4, 1, 1, 'Chennai', true);
INSERT INTO masters.city (id, country_sno, state_sno, city_name, active_flag) VALUES (13, 1, 1, 'Madurai', true);


--
-- TOC entry 4100 (class 0 OID 235701)
-- Dependencies: 216
-- Data for Name: consignee; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.consignee (id, consignee_name, gstno, pancard, mobileno, email, address_id, active_flag) VALUES (2, 'Karthi', 'ABCDE1234ABCDE12456', 'ABCDE1234FABCDE1234F', '7897656781', 'karthi@gmail.com', 11, true);
INSERT INTO masters.consignee (id, consignee_name, gstno, pancard, mobileno, email, address_id, active_flag) VALUES (3, 'Selvi', 'ABCDE1234ABCDE12456', 'ABCDE1234F', '9876543210', 'selvi@gmail.com', 16, true);


--
-- TOC entry 4102 (class 0 OID 235708)
-- Dependencies: 218
-- Data for Name: country; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.country (id, country_name, active_flag) VALUES (1, 'India', true);
INSERT INTO masters.country (id, country_name, active_flag) VALUES (2, 'USA', true);
INSERT INTO masters.country (id, country_name, active_flag) VALUES (9, 'Zimbabwe', true);


--
-- TOC entry 4104 (class 0 OID 235713)
-- Dependencies: 220
-- Data for Name: currency_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.currency_master (id, currency_code, currency_name, symbol, active_flag) VALUES (2, 'USD', 'US Dollar', '$', true);
INSERT INTO masters.currency_master (id, currency_code, currency_name, symbol, active_flag) VALUES (4, 'EUR', 'Euro', '€', true);
INSERT INTO masters.currency_master (id, currency_code, currency_name, symbol, active_flag) VALUES (1, 'INR', 'Indian Rupee', '₹', true);


--
-- TOC entry 4106 (class 0 OID 235718)
-- Dependencies: 222
-- Data for Name: customer; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.customer (id, gstno, pancard, mobileno, email, address_id, active_flag, customer_name, iec_code, cin_no, tin_no, msme_udyam) VALUES (4, 'ABCDE1234F', '27ABCDE1234F1Z5', '3456789543', 'jeeva@gmail.com', 2, true, 'Jeeva', NULL, NULL, NULL, NULL);
INSERT INTO masters.customer (id, gstno, pancard, mobileno, email, address_id, active_flag, customer_name, iec_code, cin_no, tin_no, msme_udyam) VALUES (5, 'dsfdssd', 'ABCDE1234F', '06383864180', 'padhujds@gmail.com', 3, true, 'padmini l', NULL, NULL, NULL, NULL);
INSERT INTO masters.customer (id, gstno, pancard, mobileno, email, address_id, active_flag, customer_name, iec_code, cin_no, tin_no, msme_udyam) VALUES (1, '27ABCDE1234F1Z5', 'ABCDE1234F', '1234567890', 'padhu@gmail.com', 1, true, 'Padmini', NULL, NULL, NULL, NULL);
INSERT INTO masters.customer (id, gstno, pancard, mobileno, email, address_id, active_flag, customer_name, iec_code, cin_no, tin_no, msme_udyam) VALUES (11, 'ABCDE1234ABCDE12456', 'ABCDE1234FABCDE1234F', '06383864180', 'muthu@gmail.com', 34, true, 'Muthu', 'fsdfsdf', 'sdf', 'sdfsdfsd', 'ddfsdfdsf');


--
-- TOC entry 4226 (class 0 OID 238716)
-- Dependencies: 342
-- Data for Name: customer_international; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--



--
-- TOC entry 4234 (class 0 OID 261276)
-- Dependencies: 350
-- Data for Name: defect_master; Type: TABLE DATA; Schema: masters; Owner: qbox_admin
--

INSERT INTO masters.defect_master (id, defect_code, defect_name, description, active_flag, defect_pont) VALUES (1, 'A', 'Defect A', 'Defect A Description', true, 10);
INSERT INTO masters.defect_master (id, defect_code, defect_name, description, active_flag, defect_pont) VALUES (2, 'B', 'Defect B', 'Defect Description B', true, 20);
INSERT INTO masters.defect_master (id, defect_code, defect_name, description, active_flag, defect_pont) VALUES (4, 'C', 'Defect C', 'Defect Description C', true, 30);


--
-- TOC entry 4108 (class 0 OID 235725)
-- Dependencies: 224
-- Data for Name: dyeing_work_order; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.dyeing_work_order (id, dyeing_work_order_no, process_contact_date, delivery_date, vendor_id, sales_order_id, consignee_id, lap_dip_status_id, first_yardage_id, total_amount, remarks, active_flag, sales_order_no) VALUES (1, 'DWO-20250529-00001', '2025-05-29', '2025-05-29', 1, NULL, 1, 1, 1, 100, 'dfgfdgfdgd', true, 1);
INSERT INTO masters.dyeing_work_order (id, dyeing_work_order_no, process_contact_date, delivery_date, vendor_id, sales_order_id, consignee_id, lap_dip_status_id, first_yardage_id, total_amount, remarks, active_flag, sales_order_no) VALUES (2, 'DWO-20250529-00002', '2025-05-29', '2025-05-29', 1, NULL, 1, 1, 1, 100, 'dfgfdgfdgd', true, 1);
INSERT INTO masters.dyeing_work_order (id, dyeing_work_order_no, process_contact_date, delivery_date, vendor_id, sales_order_id, consignee_id, lap_dip_status_id, first_yardage_id, total_amount, remarks, active_flag, sales_order_no) VALUES (4, 'DWO-20250601-00004', '2025-06-04', '2025-06-05', 1, NULL, 2, 1, 1, 1000, 'sad', true, 49);


--
-- TOC entry 4110 (class 0 OID 235732)
-- Dependencies: 226
-- Data for Name: dyeing_work_order_items; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.dyeing_work_order_items (id, dyeing_work_order_id, finished_fabric_code_id, finished_fabric_name, greige_fabric_code_id, greige_fabric_name, quantity, cost_per_pound, total_amount, color_id, pantone, finished_weight, greige_width, req_finished_width, uom_id, remarks, active_flag) VALUES (1, 1, 1, 'sdffdsfsd', 1, 'stsfdsfsdfsdring', 10, 10, 100, 1, 'sdfdstring', 10, 10, 10, 1, 'stdfgfdring', true);
INSERT INTO masters.dyeing_work_order_items (id, dyeing_work_order_id, finished_fabric_code_id, finished_fabric_name, greige_fabric_code_id, greige_fabric_name, quantity, cost_per_pound, total_amount, color_id, pantone, finished_weight, greige_width, req_finished_width, uom_id, remarks, active_flag) VALUES (2, 2, 1, 'sdffdsfsd', 1, 'stsfdsfsdfsdring', 10, 10, 100, 1, 'sdfdstring', 10, 10, 10, 1, 'stdfgfdring', true);
INSERT INTO masters.dyeing_work_order_items (id, dyeing_work_order_id, finished_fabric_code_id, finished_fabric_name, greige_fabric_code_id, greige_fabric_name, quantity, cost_per_pound, total_amount, color_id, pantone, finished_weight, greige_width, req_finished_width, uom_id, remarks, active_flag) VALUES (4, 4, 2, 'Poly Cotton Knits', 2, 'Poly Cotton Knits', 10, 23, 32, 1, '23', 32, 32, 32, 2, 'Edit Dyeing Work Order', true);


--
-- TOC entry 4112 (class 0 OID 235739)
-- Dependencies: 228
-- Data for Name: empty_beam_issue; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.empty_beam_issue (id, vendor_id, consignee_id, vechile_no, empty_beam_issue_date, empty_beam_no) VALUES (10, 1, 2, 'TN0001', '2025-07-26 05:30:00', 'EBN-20250726-1796');
INSERT INTO masters.empty_beam_issue (id, vendor_id, consignee_id, vechile_no, empty_beam_issue_date, empty_beam_no) VALUES (9, 1, 2, 'TN777867', '2025-07-15 05:30:00', 'EBN-20250723-1796	');
INSERT INTO masters.empty_beam_issue (id, vendor_id, consignee_id, vechile_no, empty_beam_issue_date, empty_beam_no) VALUES (11, 1, 2, 'TN000112', '2025-08-02 05:30:00', 'EBN-20250802-6039');
INSERT INTO masters.empty_beam_issue (id, vendor_id, consignee_id, vechile_no, empty_beam_issue_date, empty_beam_no) VALUES (12, 1, 2, 'TN0001', '2025-08-13 05:30:00', 'EBN-20250813-1951');
INSERT INTO masters.empty_beam_issue (id, vendor_id, consignee_id, vechile_no, empty_beam_issue_date, empty_beam_no) VALUES (13, 2, 2, 'TN0001', '2025-08-13 05:30:00', 'EBN-20250813-6717');


--
-- TOC entry 4114 (class 0 OID 235743)
-- Dependencies: 230
-- Data for Name: empty_beam_issue_item; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.empty_beam_issue_item (id, empty_beam_issue_id, flange_id, active_flag) VALUES (12, 9, 1, true);
INSERT INTO masters.empty_beam_issue_item (id, empty_beam_issue_id, flange_id, active_flag) VALUES (13, 10, 1, true);
INSERT INTO masters.empty_beam_issue_item (id, empty_beam_issue_id, flange_id, active_flag) VALUES (15, 11, 1, true);
INSERT INTO masters.empty_beam_issue_item (id, empty_beam_issue_id, flange_id, active_flag) VALUES (16, 12, 1, true);
INSERT INTO masters.empty_beam_issue_item (id, empty_beam_issue_id, flange_id, active_flag) VALUES (17, 13, 1, true);


--
-- TOC entry 4116 (class 0 OID 235748)
-- Dependencies: 232
-- Data for Name: fabric_category; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.fabric_category (id, fabric_category_name, active_flag) VALUES (1, 'Yarn Dyed', true);
INSERT INTO masters.fabric_category (id, fabric_category_name, active_flag) VALUES (2, 'Greige', true);
INSERT INTO masters.fabric_category (id, fabric_category_name, active_flag) VALUES (3, 'RFD', true);
INSERT INTO masters.fabric_category (id, fabric_category_name, active_flag) VALUES (4, 'Piece Dyed', true);


--
-- TOC entry 4118 (class 0 OID 235753)
-- Dependencies: 234
-- Data for Name: fabric_dispatch_for_dyeing; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.fabric_dispatch_for_dyeing (id, fabric_dispatch_date, vendor_id, dyeing_work_order_id, order_quantity, dispatched_quantity, received_quantity, balance_quantity, cost_per_pound, total_amount, color_id, pantone, finishing_id, sales_order_id, shipment_mode_id, lot_id, remarks, active_flag) VALUES (1, '2025-07-28', 1, 1, 123, NULL, 0, 123, 100, 1000, 1, '13', 2, 12, 2, NULL, 'asdsa', true);
INSERT INTO masters.fabric_dispatch_for_dyeing (id, fabric_dispatch_date, vendor_id, dyeing_work_order_id, order_quantity, dispatched_quantity, received_quantity, balance_quantity, cost_per_pound, total_amount, color_id, pantone, finishing_id, sales_order_id, shipment_mode_id, lot_id, remarks, active_flag) VALUES (3, '2025-07-28', 1, 1, 123, NULL, 0, 123, 100, 1000, 1, '13', 2, 12, 2, NULL, 'asdsa', true);


--
-- TOC entry 4120 (class 0 OID 235760)
-- Dependencies: 236
-- Data for Name: fabric_inspection; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.fabric_inspection (id, inspection_date, loom_no, vendor_id, fabric_quality, doff_meters, doff_weight, active_flag) VALUES (1, '2025-05-12', 1, 1, 'fgdf', 100, 100, true);
INSERT INTO masters.fabric_inspection (id, inspection_date, loom_no, vendor_id, fabric_quality, doff_meters, doff_weight, active_flag) VALUES (2, '2025-05-12', 1, 1, 'fgdf', 100, 100, true);
INSERT INTO masters.fabric_inspection (id, inspection_date, loom_no, vendor_id, fabric_quality, doff_meters, doff_weight, active_flag) VALUES (4, '2025-05-12', 12, 4, 'Permium', 12, 12, true);
INSERT INTO masters.fabric_inspection (id, inspection_date, loom_no, vendor_id, fabric_quality, doff_meters, doff_weight, active_flag) VALUES (3, '2025-05-12', 1, 1, 'Update fabric inspect', 10, 10, true);
INSERT INTO masters.fabric_inspection (id, inspection_date, loom_no, vendor_id, fabric_quality, doff_meters, doff_weight, active_flag) VALUES (5, '2025-07-25', 123, 1, '123', 213, 321, true);
INSERT INTO masters.fabric_inspection (id, inspection_date, loom_no, vendor_id, fabric_quality, doff_meters, doff_weight, active_flag) VALUES (6, '2025-07-26', 23423, 5, '23423', 234, 23423, true);


--
-- TOC entry 4124 (class 0 OID 235771)
-- Dependencies: 240
-- Data for Name: fabric_type; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.fabric_type (id, fabric_type_name, active_flag) VALUES (1, 'Greige', true);
INSERT INTO masters.fabric_type (id, fabric_type_name, active_flag) VALUES (2, 'Finished', true);
INSERT INTO masters.fabric_type (id, fabric_type_name, active_flag) VALUES (3, 'Finished Shade', true);


--
-- TOC entry 4126 (class 0 OID 235776)
-- Dependencies: 242
-- Data for Name: fabric_warp_detail; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.fabric_warp_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (8, 10, 1, 1, 10.00, 10.00);
INSERT INTO masters.fabric_warp_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (9, 11, 1, 1, 10.00, 10.00);
INSERT INTO masters.fabric_warp_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (13, 16, 2, 1, 100.00, 100.00);
INSERT INTO masters.fabric_warp_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (14, 18, 2, 1, 100.00, 100.00);
INSERT INTO masters.fabric_warp_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (17, 24, 1, 1, 21.00, 213.00);
INSERT INTO masters.fabric_warp_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (18, 25, 3, 6, 23.00, 23.00);
INSERT INTO masters.fabric_warp_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (20, 32, 1, 1, 100.00, 100.00);
INSERT INTO masters.fabric_warp_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (21, 39, 1, 10, 100.00, 100.00);


--
-- TOC entry 4128 (class 0 OID 235780)
-- Dependencies: 244
-- Data for Name: fabric_weft_detail; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.fabric_weft_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (5, 10, 1, 1, 10.00, 10.00);
INSERT INTO masters.fabric_weft_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (6, 11, 1, 1, 10.00, 10.00);
INSERT INTO masters.fabric_weft_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (8, 16, 3, 1, 100.00, 100.00);
INSERT INTO masters.fabric_weft_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (9, 18, 1, 1, 100.00, 100.00);
INSERT INTO masters.fabric_weft_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (12, 24, 1, 1, 123.00, 123.00);
INSERT INTO masters.fabric_weft_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (13, 25, 5, 1, 23.00, 23.00);
INSERT INTO masters.fabric_weft_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (14, 32, 1, 1, 100.00, 100.00);
INSERT INTO masters.fabric_weft_detail (id, fabric_id, yarn_id, color, shrinkage_percent, grams_per_meter) VALUES (15, 39, 2, 10, 100.00, 100.00);


--
-- TOC entry 4228 (class 0 OID 261225)
-- Dependencies: 344
-- Data for Name: finish_fabric_receive; Type: TABLE DATA; Schema: masters; Owner: qbox_admin
--

INSERT INTO masters.finish_fabric_receive (id, fabric_fabric_receive_date, vendor_id, dyeing_work_order_id, order_quantity, cost_per_pound, total_amount, color_id, pantone, finishing_id, sales_order_id, purchase_inward_id, dispatched_quantity, received_quantity, balance_quantity, remarks, active_flag) VALUES (1, '2025-08-10', 1, 1, 100, 100, 10000, 1, 'asd', 1, 34, 1, 100, 100, 100, 'finsishFabricReceive', true);
INSERT INTO masters.finish_fabric_receive (id, fabric_fabric_receive_date, vendor_id, dyeing_work_order_id, order_quantity, cost_per_pound, total_amount, color_id, pantone, finishing_id, sales_order_id, purchase_inward_id, dispatched_quantity, received_quantity, balance_quantity, remarks, active_flag) VALUES (2, '2025-08-11', 1, 1, 123, 100, 1000, 10, '13', 1, 49, 1, 123, 123, 0, 'asdsad', NULL);


--
-- TOC entry 4230 (class 0 OID 261235)
-- Dependencies: 346
-- Data for Name: finish_fabric_receive_items; Type: TABLE DATA; Schema: masters; Owner: qbox_admin
--

INSERT INTO masters.finish_fabric_receive_items (id, finished_fabric_code, roll_no, roll_yards, weight, grade_id, warehouse_id, active_flag, finish_fabric_receive_id) VALUES (1, 'F-0001', 'Roll01', 'Yard001', '100', 1, 1, true, NULL);
INSERT INTO masters.finish_fabric_receive_items (id, finished_fabric_code, roll_no, roll_yards, weight, grade_id, warehouse_id, active_flag, finish_fabric_receive_id) VALUES (2, NULL, '1000', '1000', '1000', NULL, 1, NULL, NULL);


--
-- TOC entry 4130 (class 0 OID 235784)
-- Dependencies: 246
-- Data for Name: finish_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.finish_master (id, finish_name, finish_code, description, active_flag) VALUES (2, 'FinishMaster2', 'FinishCode2', 'FinishDescription2', true);
INSERT INTO masters.finish_master (id, finish_name, finish_code, description, active_flag) VALUES (1, 'FinishMaster1', 'FinishCode1', 'FinishDescription2', true);


--
-- TOC entry 4132 (class 0 OID 235791)
-- Dependencies: 248
-- Data for Name: flange_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.flange_master (id, flange_no, active_flag) VALUES (1, 'F01', true);


--
-- TOC entry 4134 (class 0 OID 235796)
-- Dependencies: 250
-- Data for Name: generate_invoice; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (1, 1, '2025-05-12', 1, 1, 1, 1, 1, 1, 1, 1, 100.00, 100.00, 'ewrwerwrew', true, NULL);
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (2, 1, '2025-05-12', 28, 0, 5, 2, 0, 2, 4, 1, 0.00, 1000.00, '', true, NULL);
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (3, 1, '2025-05-12', 34, 0, 5, 2, 0, 2, 4, 1, 0.00, 1000.00, '', true, NULL);
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (4, 1, '2025-05-12', 28, 0, 5, 2, 0, 2, 4, 1, 0.00, 1000.00, '', true, 'INV25050001');
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (5, 1, '2025-08-01', 49, 0, 0, 0, 0, 0, 0, 0, 0.00, 139968.00, '', true, 'INV25080001');
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (6, 1, '2025-08-02', 49, 0, 5, 2, 0, 2, 4, 2, 0.00, 139968.00, '', true, 'INV25080001');
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (7, 1, '2025-08-02', 49, 0, 5, 2, 0, 2, 4, 2, 0.00, 139968.00, '', true, 'INV25080001');
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (8, 1, '2025-08-02', 49, 0, 5, 2, 0, 2, 4, 2, 0.00, 139968.00, '', true, 'INV25080001');
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (9, 1, '2025-08-02', 49, 0, 5, 2, 0, 2, 4, 2, 0.00, 139968.00, '', true, 'INV25080001');
INSERT INTO masters.generate_invoice (id, manufacture_id, invoice_date, sales_order_id, company_bank_id, terms_conditions_id, payment_terms_id, ship_to_id, shipment_mode, customer_id, consginee_id, tax_amount, total_amount, comments, active_flag, invoice_no) VALUES (10, 1, '2025-08-02', 49, 0, 5, 2, 2, 2, 5, 2, 0.00, 139968.00, '', true, 'INV25080001');


--
-- TOC entry 4208 (class 0 OID 236579)
-- Dependencies: 324
-- Data for Name: generate_packing; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.generate_packing (id, packing_date, buyer_id, sales_order_id, warehouse_id, tare_weight, gross_weight, packing_slip_no) VALUES (7, '2025-07-29 16:00:59.842', 1, 34, 1, '1000', '1000', 'PSNO-20250727-8684	');
INSERT INTO masters.generate_packing (id, packing_date, buyer_id, sales_order_id, warehouse_id, tare_weight, gross_weight, packing_slip_no) VALUES (9, '2025-07-29 05:30:00', 4, 34, 1, '1000', '1000', 'PSNO-20250729-1965');
INSERT INTO masters.generate_packing (id, packing_date, buyer_id, sales_order_id, warehouse_id, tare_weight, gross_weight, packing_slip_no) VALUES (10, '2025-07-29 05:30:00', 4, 34, 1, '1000', '1000', 'PSNO-20250729-5209');


--
-- TOC entry 4210 (class 0 OID 236603)
-- Dependencies: 326
-- Data for Name: generate_packing_item; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.generate_packing_item (id, generated_packing_id, roll_no, length, uom_id, pounds, lot_id) VALUES (1, 7, '1000', 1000, 1, 23, 1);
INSERT INTO masters.generate_packing_item (id, generated_packing_id, roll_no, length, uom_id, pounds, lot_id) VALUES (10, 10, 'Roll-001', 1000, 3, 1000, NULL);
INSERT INTO masters.generate_packing_item (id, generated_packing_id, roll_no, length, uom_id, pounds, lot_id) VALUES (12, 9, 'Roll-004', 1000, 2, 1000, NULL);


--
-- TOC entry 4232 (class 0 OID 261266)
-- Dependencies: 348
-- Data for Name: grade_master; Type: TABLE DATA; Schema: masters; Owner: qbox_admin
--

INSERT INTO masters.grade_master (id, grade_code, grade_name, description, active_flag, max_point, min_point) VALUES (2, 'A', 'Grade A', 'Grade A Description', true, 10, 0);
INSERT INTO masters.grade_master (id, grade_code, grade_name, description, active_flag, max_point, min_point) VALUES (4, 'B', 'Grade B', 'Grade Description B', true, 20, 11);
INSERT INTO masters.grade_master (id, grade_code, grade_name, description, active_flag, max_point, min_point) VALUES (7, 'C', 'Grade C', 'Grade C Description', true, 30, 21);


--
-- TOC entry 4136 (class 0 OID 235803)
-- Dependencies: 252
-- Data for Name: gst_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.gst_master (id, gst_name, description, active_flag, cgst_rate, igst_rate, sgst_rate) VALUES (2, 'GST 5%', 'Essential goods and services', true, '2.50', '5.00', '2.50');
INSERT INTO masters.gst_master (id, gst_name, description, active_flag, cgst_rate, igst_rate, sgst_rate) VALUES (3, 'GST 12%', 'Standard rate for some goods', true, '6.00', '12.00', '6.00');
INSERT INTO masters.gst_master (id, gst_name, description, active_flag, cgst_rate, igst_rate, sgst_rate) VALUES (5, 'GST 18%', 'General GST rate', true, '9.00', '18.00', '9.00');
INSERT INTO masters.gst_master (id, gst_name, description, active_flag, cgst_rate, igst_rate, sgst_rate) VALUES (1, 'GST 0%	', 'Exempted Goods and Services', true, '0.00', '0.00', '0.00');


--
-- TOC entry 4138 (class 0 OID 235810)
-- Dependencies: 254
-- Data for Name: inspection_dtl; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.inspection_dtl (id, fabric_inspection_id, roll_no, doff_meters, inspected_meters, weight, total_defect_points, defect_counts, grade, active_flag) VALUES (1, 1, 'RN2505120001', 100, 100, 100, 100, 100, 'A', true);
INSERT INTO masters.inspection_dtl (id, fabric_inspection_id, roll_no, doff_meters, inspected_meters, weight, total_defect_points, defect_counts, grade, active_flag) VALUES (2, 2, 'RN2505120001', 100, 100, 100, 100, 100, 'A', true);
INSERT INTO masters.inspection_dtl (id, fabric_inspection_id, roll_no, doff_meters, inspected_meters, weight, total_defect_points, defect_counts, grade, active_flag) VALUES (4, 4, 'RN2505120002', NULL, NULL, NULL, NULL, NULL, '', true);
INSERT INTO masters.inspection_dtl (id, fabric_inspection_id, roll_no, doff_meters, inspected_meters, weight, total_defect_points, defect_counts, grade, active_flag) VALUES (5, 3, 'RN2505120001', 10, 10, 10, 10, 10, 'dfs', true);
INSERT INTO masters.inspection_dtl (id, fabric_inspection_id, roll_no, doff_meters, inspected_meters, weight, total_defect_points, defect_counts, grade, active_flag) VALUES (6, 5, 'RN2507250001', 123, 213, 231, 213, 231, '231', true);
INSERT INTO masters.inspection_dtl (id, fabric_inspection_id, roll_no, doff_meters, inspected_meters, weight, total_defect_points, defect_counts, grade, active_flag) VALUES (7, 6, 'RN2507260001', 324324, 2342, 342, 34234, 234, '234', true);


--
-- TOC entry 4140 (class 0 OID 235815)
-- Dependencies: 256
-- Data for Name: inspection_entry; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.inspection_entry (id, fabric_inspection_id, defected_meters, from_meters, to_meters, defect_type_id, defect_points, inspection_id, active_flag) VALUES (1, 1, 100, 100, 10, 1, 1, 1, true);
INSERT INTO masters.inspection_entry (id, fabric_inspection_id, defected_meters, from_meters, to_meters, defect_type_id, defect_points, inspection_id, active_flag) VALUES (2, 2, 100, 100, 10, 1, 1, 1, true);
INSERT INTO masters.inspection_entry (id, fabric_inspection_id, defected_meters, from_meters, to_meters, defect_type_id, defect_points, inspection_id, active_flag) VALUES (4, 4, 21, 3, 21, 1, 123, 4, true);
INSERT INTO masters.inspection_entry (id, fabric_inspection_id, defected_meters, from_meters, to_meters, defect_type_id, defect_points, inspection_id, active_flag) VALUES (5, 3, 10, 10, 10, 10, 10, 10, true);
INSERT INTO masters.inspection_entry (id, fabric_inspection_id, defected_meters, from_meters, to_meters, defect_type_id, defect_points, inspection_id, active_flag) VALUES (6, 5, 213, 213, 123, 1, 213, 4, true);
INSERT INTO masters.inspection_entry (id, fabric_inspection_id, defected_meters, from_meters, to_meters, defect_type_id, defect_points, inspection_id, active_flag) VALUES (7, 6, 324, 32423, 4, 1, 234, 4, true);


--
-- TOC entry 4142 (class 0 OID 235820)
-- Dependencies: 258
-- Data for Name: jobwork_fabric_receive; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (6, 1, 1, '2025-05-12', 'string', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (7, 1, 1, '2025-05-12', '', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (8, 1, 1, '2025-05-12', '', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (9, 1, 1, '2025-05-12', '', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (10, 3, 1, '2025-06-01', 'Purchase Order ', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (13, 3, 1, '2025-07-25', 'Jobwork Fabric Receive', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (14, 3, 1, '2025-07-25', 'Jobwork Fabric Receive', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (18, 1, 2, '2025-08-16', 'Jobwork Fabric Receive', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (19, 1, 2, '2025-08-16', '', true);
INSERT INTO masters.jobwork_fabric_receive (id, weaving_contract_id, vendor_id, job_fabric_receive_date, remarks, active_flag) VALUES (20, 1, 2, '2025-08-16', '', true);


--
-- TOC entry 4144 (class 0 OID 235828)
-- Dependencies: 260
-- Data for Name: jobwork_fabric_receive_item; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (5, 6, 1, 100.00, 100.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (6, 7, 1, 50.00, 100.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (7, 8, 1, 50.00, 100.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (8, 9, 1, 0.00, 0.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (9, 10, 3, 10.00, 20.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (12, 13, 3, 10.00, 100.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (13, 14, 3, 10.00, 100.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (17, 18, 1, 100.00, 100.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (18, 19, 1, 100.00, 100.00, true);
INSERT INTO masters.jobwork_fabric_receive_item (id, jobwork_fabric_receive_id, weaving_contract_item_id, quantity_received, price, active_flag) VALUES (19, 20, 1, 100.00, 100.00, true);


--
-- TOC entry 4204 (class 0 OID 236556)
-- Dependencies: 320
-- Data for Name: knitted_fabric_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.knitted_fabric_master (id, composition, fabric_category_id, fabric_code, fabric_name, fabric_type_id, gsm, knitted_fabric_id, remarks, shrinkage, width) VALUES (2, '100', 1, 'FAB-CODE-100', 'Pure Cotton', 1, 150.00, NULL, 'Knitted Fabric', '100', '100');


--
-- TOC entry 4146 (class 0 OID 235833)
-- Dependencies: 262
-- Data for Name: lot_entry; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (1, 4, 'lo-0001', 100.00, 20.00, 100.00, 'sdfdsfsdf', true, NULL);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (2, 5, 'lo-0001', 100.00, 20.00, 100.00, 'sdfdsfsdf', true, NULL);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (3, 6, 'lo-0001', 100.00, 20.00, 100.00, 'sdfdsfsdf', true, NULL);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (4, 7, 'sdsdf', 100.00, 20.00, 100.00, 'dsfsdfsdf', true, NULL);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (5, 8, 'LOT-0001', 5.00, 1.00, 100.00, 'dsfsd', true, NULL);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (6, 9, 'Lot-1', 30.00, 0.00, 100.00, 'lot1', true, NULL);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (7, 9, 'Lot-2', 20.00, 0.00, 100.00, 'lot2', true, NULL);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (8, 10, 'Lot-1', 30.00, 0.00, 100.00, 'lot1', true, NULL);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (15, 14, NULL, 10.00, 0.00, 100.00, 'LOT-1234', true, 1);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (18, 16, 'LOT-20250813-8922', 0.00, 0.00, 100.00, 'lot-01', true, 1);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (17, 15, 'LOT-20250813-9661', 0.00, 0.00, 100.00, 'LOT-02', true, 3);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (16, 15, 'LOT-20250813-8463', 0.00, 0.00, 100.00, 'LOT-01', true, 1);
INSERT INTO masters.lot_entry (id, inward_item_id, lot_number, quantity, rejected_quantity, cost, remarks, active_flag, warehouse_id) VALUES (9, 10, 'Lot-2', 0.00, 0.00, 100.00, 'lot2', true, NULL);


--
-- TOC entry 4236 (class 0 OID 261286)
-- Dependencies: 352
-- Data for Name: lot_outward; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.lot_outward (id, active_flag, created_at, created_by, lot_entry_id, outward_date, outward_type, quantity, reference_id, reference_type, remarks, updated_at) VALUES (1, true, '2025-08-15 16:28:07.230508', NULL, 18, '2025-08-15', 'YARN_ISSUE', 100.00, 13, 'WEAVING_YARN_ISSUE', 'Weaving yarn issue - YICNO-20250815-3825', '2025-08-15 16:28:07.230562');
INSERT INTO masters.lot_outward (id, active_flag, created_at, created_by, lot_entry_id, outward_date, outward_type, quantity, reference_id, reference_type, remarks, updated_at) VALUES (2, true, '2025-08-15 18:12:34.058895', NULL, 17, '2025-08-15', 'YARN_ISSUE', 50.00, 14, 'WEAVING_YARN_ISSUE', 'Weaving yarn issue - YICNO-20250815-3596', '2025-08-15 18:12:34.058916');
INSERT INTO masters.lot_outward (id, active_flag, created_at, created_by, lot_entry_id, outward_date, outward_type, quantity, reference_id, reference_type, remarks, updated_at) VALUES (3, true, '2025-08-15 18:51:54.297893', NULL, 16, '2025-08-15', 'YARN_ISSUE', 50.00, 18, 'WEAVING_YARN_ISSUE', 'Weaving yarn issue - YICNO-20250815-3985', '2025-08-15 18:51:54.297908');
INSERT INTO masters.lot_outward (id, active_flag, created_at, created_by, lot_entry_id, outward_date, outward_type, quantity, reference_id, reference_type, remarks, updated_at) VALUES (4, true, '2025-08-18 10:47:59.999084', NULL, 9, '2025-08-18', 'YARN_ISSUE', 20.00, 19, 'WEAVING_YARN_ISSUE', 'Weaving yarn issue - string', '2025-08-18 10:47:59.999121');


--
-- TOC entry 4148 (class 0 OID 235840)
-- Dependencies: 264
-- Data for Name: payment_terms; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.payment_terms (id, term_name, description, active_flag) VALUES (2, 'FOB', 'Free on Board - Seller delivers goods to the port, buyer assumes risk from there', true);


--
-- TOC entry 4150 (class 0 OID 235847)
-- Dependencies: 266
-- Data for Name: piece_entry; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (3, 5, 'P-01', 10.00, 10.00, 100.00, 'string', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (4, 6, 'P-01', 50.00, 10.00, 100.00, '', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (5, 7, 'P-01', 50.00, 10.00, 100.00, '', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (6, 8, 'qwe', 231.00, 123.00, 213.00, '', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (7, 9, 'PNO-01', 10.00, 10.00, 10.00, 'adad', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (8, 9, 'PNO-02', 10.00, 10.00, 10.00, 'sdfd', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (13, 12, 'p1-2025', 10.00, 100.00, 100.00, '', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (14, 13, 'p1-2025', 10.00, 100.00, 100.00, '', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (17, 17, 'P-1', 100.00, 100.00, 100.00, 'piece', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (18, 18, 'P-1', 100.00, 100.00, 100.00, 'Piece', true);
INSERT INTO masters.piece_entry (id, jobwork_fabric_receive_item_id, piece_number, quantity, weight, cost, remarks, active_flag) VALUES (19, 19, 'P-1', 100.00, 100.00, 100.00, 'Piece -1', true);


--
-- TOC entry 4152 (class 0 OID 235854)
-- Dependencies: 268
-- Data for Name: po_type_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.po_type_master (id, po_type_name, description, active_flag) VALUES (1, 'Yarn', NULL, true);
INSERT INTO masters.po_type_master (id, po_type_name, description, active_flag) VALUES (2, 'Knitted Fabric', NULL, true);
INSERT INTO masters.po_type_master (id, po_type_name, description, active_flag) VALUES (3, 'Woven Fabric', NULL, true);


--
-- TOC entry 4238 (class 0 OID 272518)
-- Dependencies: 354
-- Data for Name: process_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.process_master (id, active_flag, description, process_name) VALUES (1, true, 'Process1 description', 'Process1');


--
-- TOC entry 4154 (class 0 OID 235861)
-- Dependencies: 270
-- Data for Name: product_category; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.product_category (id, po_type_id, product_category_name, fabric_code, fabric_quality, active_flag) VALUES (2, 1, 'Poly Cotton Knits', 'FK002', '60% Cotton / 40% Poly', true);
INSERT INTO masters.product_category (id, po_type_id, product_category_name, fabric_code, fabric_quality, active_flag) VALUES (1, 1, 'Cotton Knits', 'FK001', '100% Cotton, Soft Finish', true);


--
-- TOC entry 4156 (class 0 OID 235866)
-- Dependencies: 272
-- Data for Name: purchase_inward; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (1, 23, '2025-04-10 02:21:18.578757', 'jklkjlkjlk', true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (2, 23, '2025-04-10 02:21:53.269993', 'jklkjlkjlk', true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (3, 23, '2025-04-10 02:22:41.984373', 'jklkjlkjlk', true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (4, 23, '2025-04-10 02:28:16.232602', 'fdsfsdfsd', true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (5, 13, '2025-04-13 12:01:30.138634', NULL, true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (6, 30, '2025-05-10 15:26:09.399009', NULL, true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (7, 30, '2025-05-10 15:27:41.222397', NULL, true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (13, 23, '2025-08-13 17:40:12.404626', NULL, true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (14, 25, '2025-08-13 17:45:05.250349', NULL, true);
INSERT INTO masters.purchase_inward (id, po_id, inward_date, remarks, active_flag) VALUES (15, 25, '2025-08-13 17:54:08.799233', 'dsfsdfsdfsd', true);


--
-- TOC entry 4158 (class 0 OID 235874)
-- Dependencies: 274
-- Data for Name: purchase_inward_item; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (4, 1, 7, 100.00, 100.00, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (5, 2, 7, 100.00, 100.00, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (6, 3, 7, 100.00, 100.00, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (7, 4, 7, 100.00, 100.00, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (8, 5, 4, 5.00, 100.50, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (9, 6, 11, 50.00, 100.00, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (10, 7, 11, 50.00, 100.00, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (14, 13, 7, 10.00, 100.00, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (15, 14, 8, 0.00, 100.00, true);
INSERT INTO masters.purchase_inward_item (id, inward_id, po_item_id, quantity_received, price, active_flag) VALUES (16, 15, 8, 0.00, 100.00, true);


--
-- TOC entry 4162 (class 0 OID 235884)
-- Dependencies: 278
-- Data for Name: purchase_order_item; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (4, 13, 1, 10.00, 'kg', 100.50, 1005.00, '2025-04-10 00:00:00', 'Urgent', true);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (5, 13, 2, 5.00, 'pcs', 200.00, 1000.00, '2025-04-12 00:00:00', 'Standard', true);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (7, 23, 2, 10.00, '1', 100.00, 1000.00, '2025-04-12 00:00:00', 'purchase order', NULL);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (8, 25, 1, 100.00, 'Nos', 100.00, 1000.00, '2025-04-11 14:32:35.469', 'dsfsdfsdfsd', true);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (9, 26, 2, 200.00, 'Mtrs', 500.00, 100000.00, '2025-04-11 15:14:05.84', '1lakh', true);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (11, 30, 2, 100.00, '1', 100.00, 10000.00, '2025-05-12 00:00:00', 'Purchase Order', NULL);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (13, 32, 2, 10.00, '1', 234.00, 332423.00, '2025-05-30 22:35:45.419', 'Purchase Order', true);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (14, 33, 2, 10.00, '2', 100.00, 1000.00, '2025-06-02 00:00:00', 'purchas order', NULL);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (15, 34, 1, 10.00, '1', 100.00, 1000.00, '2025-07-28 00:00:00', 'Purchase Order', NULL);
INSERT INTO masters.purchase_order_item (id, po_id, product_category_id, quantity, unit, price, net_amount, delivery_date, remarks, active_flag) VALUES (16, 35, 1, 10.00, '1', 100.00, 1000.00, '2025-07-28 00:00:00', 'Purchase Order 123213213', true);


--
-- TOC entry 4160 (class 0 OID 235879)
-- Dependencies: 276
-- Data for Name: purchase_orders; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (23, 1, '2025-04-09', 2, 1, true, 'PO-0002');
INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (25, 1, '2025-04-11', 2, 1, true, 'PO-0003');
INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (26, 1, '2025-04-11', 2, 1, true, 'PO-0004');
INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (30, 1, '2025-05-08', 1, 1, true, 'PO-20250508-9387');
INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (32, 1, '2025-05-30', 1, 1, true, 'string');
INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (33, 1, '2025-05-31', 1, 1, true, 'PO-20250531-8092');
INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (34, 2, '2025-07-16', 2, 2, true, 'PO-20250531-1402');
INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (35, 2, '2025-07-16', 2, 2, true, 'PO-20250531-2834');
INSERT INTO masters.purchase_orders (id, po_type_id, po_date, vendor_id, tax_id, active_flag, po_no) VALUES (13, 1, '2025-04-06', 1, 1, true, NULL);


--
-- TOC entry 4164 (class 0 OID 235891)
-- Dependencies: 280
-- Data for Name: sales_order; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sales_order (id, order_date, buyer_customer_id, buyer_po_no, deliver_to_id, currency_id, exchange_rate, mode_of_shipment_id, shipment_terms_id, terms_conditions_id, active_flag, sales_order_no, payment_terms_id, internal_order_no, packing_type_id) VALUES (49, '2025-05-29 05:30:00', 4, 'PO_1234', 2, 1, 100, 2, 4, 6, true, 'SO-20250531-6858', NULL, NULL, NULL);
INSERT INTO masters.sales_order (id, order_date, buyer_customer_id, buyer_po_no, deliver_to_id, currency_id, exchange_rate, mode_of_shipment_id, shipment_terms_id, terms_conditions_id, active_flag, sales_order_no, payment_terms_id, internal_order_no, packing_type_id) VALUES (59, '2025-07-13 05:30:00', 4, 'PO_12342', 2, 2, 100, 2, 4, 5, true, 'SO-JVT2025-01', 2, 'JVT-02', NULL);
INSERT INTO masters.sales_order (id, order_date, buyer_customer_id, buyer_po_no, deliver_to_id, currency_id, exchange_rate, mode_of_shipment_id, shipment_terms_id, terms_conditions_id, active_flag, sales_order_no, payment_terms_id, internal_order_no, packing_type_id) VALUES (28, '2025-04-11 05:30:00', 1, 'PO_1234', 1, 1, 100, 2, 2, 5, true, 'SO-20250431-6858', NULL, NULL, NULL);
INSERT INTO masters.sales_order (id, order_date, buyer_customer_id, buyer_po_no, deliver_to_id, currency_id, exchange_rate, mode_of_shipment_id, shipment_terms_id, terms_conditions_id, active_flag, sales_order_no, payment_terms_id, internal_order_no, packing_type_id) VALUES (29, '2025-04-11 05:30:00', 1, 'PO_12345', 1, 1, 100, 2, 2, 5, true, 'SO-20250411-6811', NULL, NULL, NULL);
INSERT INTO masters.sales_order (id, order_date, buyer_customer_id, buyer_po_no, deliver_to_id, currency_id, exchange_rate, mode_of_shipment_id, shipment_terms_id, terms_conditions_id, active_flag, sales_order_no, payment_terms_id, internal_order_no, packing_type_id) VALUES (34, '2025-04-12 05:30:00', 4, 'PO-9876', 4, 1, 100, 2, 4, 5, true, 'SO-20250412-6158', NULL, NULL, NULL);
INSERT INTO masters.sales_order (id, order_date, buyer_customer_id, buyer_po_no, deliver_to_id, currency_id, exchange_rate, mode_of_shipment_id, shipment_terms_id, terms_conditions_id, active_flag, sales_order_no, payment_terms_id, internal_order_no, packing_type_id) VALUES (75, '2025-08-13 05:30:00', 4, 'PO-98761', 2, 2, 100, 2, 4, 5, true, 'SO-JVT-20250813-3316', 2, 'JVT-20250813-8044', NULL);
INSERT INTO masters.sales_order (id, order_date, buyer_customer_id, buyer_po_no, deliver_to_id, currency_id, exchange_rate, mode_of_shipment_id, shipment_terms_id, terms_conditions_id, active_flag, sales_order_no, payment_terms_id, internal_order_no, packing_type_id) VALUES (78, '2025-08-13 05:30:00', 4, 'PO-9871', 2, 2, 100, 2, 4, 5, true, 'SO-JVT-20250813-33', 2, 'JVT-20250813-80', NULL);


--
-- TOC entry 4166 (class 0 OID 235898)
-- Dependencies: 282
-- Data for Name: sales_order_item; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sales_order_item (id, sales_order_id, fabric_type_id, quality, buyer_product, order_qty, price_per_unit, uom_id, total_amount, gst_percent, gst_amount, final_amount, delivery_date, remarks, active_flag, fabric_master_type_id, fabric_category_id, fabric_master_id) VALUES (27, 49, 3, '324', '324', 432, 324, 1, 32, 4, 324, 32, '2025-05-29 05:30:00', '32', true, NULL, NULL, NULL);
INSERT INTO masters.sales_order_item (id, sales_order_id, fabric_type_id, quality, buyer_product, order_qty, price_per_unit, uom_id, total_amount, gst_percent, gst_amount, final_amount, delivery_date, remarks, active_flag, fabric_master_type_id, fabric_category_id, fabric_master_id) VALUES (36, 28, 2, 'Permiam', 'Yarn', 100, 10, 2, 1000, 10, 10, 1200, '2025-04-11 05:30:00', 'New Sales Order111111', true, NULL, NULL, NULL);
INSERT INTO masters.sales_order_item (id, sales_order_id, fabric_type_id, quality, buyer_product, order_qty, price_per_unit, uom_id, total_amount, gst_percent, gst_amount, final_amount, delivery_date, remarks, active_flag, fabric_master_type_id, fabric_category_id, fabric_master_id) VALUES (37, 28, 1, 'high', 'yarn', 1000, 1000, 1, 1000, 2, 1000, 1000, '2025-07-08 05:30:00', 'sales_order newwwwww', true, NULL, NULL, NULL);
INSERT INTO masters.sales_order_item (id, sales_order_id, fabric_type_id, quality, buyer_product, order_qty, price_per_unit, uom_id, total_amount, gst_percent, gst_amount, final_amount, delivery_date, remarks, active_flag, fabric_master_type_id, fabric_category_id, fabric_master_id) VALUES (39, 59, 1, '100', '100', 100, 100, 1, 100, 2, 100, 100, '2025-07-15 05:30:00', 'Sales order 2025', true, NULL, NULL, NULL);
INSERT INTO masters.sales_order_item (id, sales_order_id, fabric_type_id, quality, buyer_product, order_qty, price_per_unit, uom_id, total_amount, gst_percent, gst_amount, final_amount, delivery_date, remarks, active_flag, fabric_master_type_id, fabric_category_id, fabric_master_id) VALUES (40, 29, 2, 'Permiam', 'Yarn', 100, 10, 2, 1000, 10, 10, 1200, '2025-04-11 05:30:00', 'New Sales Order', true, NULL, NULL, NULL);
INSERT INTO masters.sales_order_item (id, sales_order_id, fabric_type_id, quality, buyer_product, order_qty, price_per_unit, uom_id, total_amount, gst_percent, gst_amount, final_amount, delivery_date, remarks, active_flag, fabric_master_type_id, fabric_category_id, fabric_master_id) VALUES (50, 34, 2, 'Premium', 'yarn', 10, 100, 1, 200, 5, 10000, 5000, '2025-04-16 05:30:00', 'Sales Order ', true, NULL, NULL, NULL);
INSERT INTO masters.sales_order_item (id, sales_order_id, fabric_type_id, quality, buyer_product, order_qty, price_per_unit, uom_id, total_amount, gst_percent, gst_amount, final_amount, delivery_date, remarks, active_flag, fabric_master_type_id, fabric_category_id, fabric_master_id) VALUES (57, 78, 2, '100', 'Fabric', 100, 100, NULL, 100, 2, 100, 100, '2025-08-15 05:30:00', 'Sales Order New update', true, 1, 1, 25);


--
-- TOC entry 4168 (class 0 OID 235905)
-- Dependencies: 284
-- Data for Name: shipment_mode; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.shipment_mode (id, mode_name, description, active_flag) VALUES (2, 'Air', 'Fastest mode of shipment via air transport', true);


--
-- TOC entry 4170 (class 0 OID 235912)
-- Dependencies: 286
-- Data for Name: shipment_terms; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.shipment_terms (id, term_name, description, active_flag) VALUES (4, 'Net 60', 'sadsadsad', true);
INSERT INTO masters.shipment_terms (id, term_name, description, active_flag) VALUES (2, 'Net 30', 'Payment due within 30 days from invoice date', true);


--
-- TOC entry 4172 (class 0 OID 235919)
-- Dependencies: 288
-- Data for Name: sizing_beam_details; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sizing_beam_details (id, sizing_plan_id, weaving_contract_id, sales_order_id, empty_beam_id, wrap_meters, shrinkage, expected_fabric_meter) VALUES (3, 5, 1, 29, 9, 1500, 2, 1450);
INSERT INTO masters.sizing_beam_details (id, sizing_plan_id, weaving_contract_id, sales_order_id, empty_beam_id, wrap_meters, shrinkage, expected_fabric_meter) VALUES (11, 9, 1, 29, 9, NULL, 2, 1450);
INSERT INTO masters.sizing_beam_details (id, sizing_plan_id, weaving_contract_id, sales_order_id, empty_beam_id, wrap_meters, shrinkage, expected_fabric_meter) VALUES (12, 10, 1, 29, 9, NULL, 2, 1450);


--
-- TOC entry 4174 (class 0 OID 235923)
-- Dependencies: 290
-- Data for Name: sizing_plan; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sizing_plan (id, vendor_id, terms_conditions_id, consignee_id, payment_terms_id, sizing_rate, remarks, sizing_plan_no) VALUES (5, 1, 5, 3, 2, 12.5, 'Test remarks', 'SPN-001');
INSERT INTO masters.sizing_plan (id, vendor_id, terms_conditions_id, consignee_id, payment_terms_id, sizing_rate, remarks, sizing_plan_no) VALUES (9, 1, 5, 3, 2, 12.5, 'Test remarks', 'SP-20250802-9799');
INSERT INTO masters.sizing_plan (id, vendor_id, terms_conditions_id, consignee_id, payment_terms_id, sizing_rate, remarks, sizing_plan_no) VALUES (10, 1, 5, 3, 2, 12.5, 'Test remarks', 'SP-20250802-6537');
INSERT INTO masters.sizing_plan (id, vendor_id, terms_conditions_id, consignee_id, payment_terms_id, sizing_rate, remarks, sizing_plan_no) VALUES (11, 1, 5, 2, 2, 12.5, 'Sizing Plan Entry 1', 'SP-20250819-4977');
INSERT INTO masters.sizing_plan (id, vendor_id, terms_conditions_id, consignee_id, payment_terms_id, sizing_rate, remarks, sizing_plan_no) VALUES (12, 1, 5, 2, 2, 12.5, 'Sizing Plan Entry', 'SP-20250827-3958');
INSERT INTO masters.sizing_plan (id, vendor_id, terms_conditions_id, consignee_id, payment_terms_id, sizing_rate, remarks, sizing_plan_no) VALUES (13, 2, 6, 2, 2, 12.5, 'Sizing Plan Entry 2', 'SP-20250827-6466');


--
-- TOC entry 4176 (class 0 OID 235929)
-- Dependencies: 292
-- Data for Name: sizing_quality_details; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sizing_quality_details (id, sizing_plan_id, quality, yarn_id, sord_ends, actual_ends, parts, ends_per_part, wrap_meters) VALUES (1, 5, 'Premium Cotton', 1, 800, 790, 4, 200, 1500);
INSERT INTO masters.sizing_quality_details (id, sizing_plan_id, quality, yarn_id, sord_ends, actual_ends, parts, ends_per_part, wrap_meters) VALUES (6, 9, 'Premium Cotton', 1, 800, 790, 4, 200, NULL);
INSERT INTO masters.sizing_quality_details (id, sizing_plan_id, quality, yarn_id, sord_ends, actual_ends, parts, ends_per_part, wrap_meters) VALUES (7, 10, 'Premium Cotton', 1, 800, 790, 4, 200, NULL);
INSERT INTO masters.sizing_quality_details (id, sizing_plan_id, quality, yarn_id, sord_ends, actual_ends, parts, ends_per_part, wrap_meters) VALUES (8, 11, '11', 1, 100, 100, 100, 100, 100);
INSERT INTO masters.sizing_quality_details (id, sizing_plan_id, quality, yarn_id, sord_ends, actual_ends, parts, ends_per_part, wrap_meters) VALUES (9, 12, '24', 1, 100, 100, 100, 100, 100);
INSERT INTO masters.sizing_quality_details (id, sizing_plan_id, quality, yarn_id, sord_ends, actual_ends, parts, ends_per_part, wrap_meters) VALUES (11, 13, '25', 1, 1234, 1234, 1234, 1234, 1234);


--
-- TOC entry 4214 (class 0 OID 238631)
-- Dependencies: 330
-- Data for Name: sizing_yarn_issue; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sizing_yarn_issue (id, sizing_yarn_issue_entry_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (1, 4, 1, 'Yarn1', 100.00, 100.00, true);
INSERT INTO masters.sizing_yarn_issue (id, sizing_yarn_issue_entry_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (2, 5, 1, 'Yarn 1', 80.00, 1000.00, true);
INSERT INTO masters.sizing_yarn_issue (id, sizing_yarn_issue_entry_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (3, 6, 9, 'Yarn 9', 20.00, 20.00, true);
INSERT INTO masters.sizing_yarn_issue (id, sizing_yarn_issue_entry_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (4, 7, 8, 'Yarn 8', 30.00, 30.00, true);
INSERT INTO masters.sizing_yarn_issue (id, sizing_yarn_issue_entry_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (5, 8, 8, 'Yarn 8', 30.00, 30.00, true);


--
-- TOC entry 4212 (class 0 OID 238587)
-- Dependencies: 328
-- Data for Name: sizing_yarn_issue_entry; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sizing_yarn_issue_entry (id, vendor_id, sizing_plan_id, transportation_dtl, terms_conditions_id, fabric_dtl, sizing_yarn_issue_date, active_flag) VALUES (4, 1, 5, 'TEST1', 5, 'FHJH001', '2025-07-30', true);
INSERT INTO masters.sizing_yarn_issue_entry (id, vendor_id, sizing_plan_id, transportation_dtl, terms_conditions_id, fabric_dtl, sizing_yarn_issue_date, active_flag) VALUES (5, 1, 5, 'Transection 0001', 5, NULL, '2025-08-02', true);
INSERT INTO masters.sizing_yarn_issue_entry (id, vendor_id, sizing_plan_id, transportation_dtl, terms_conditions_id, fabric_dtl, sizing_yarn_issue_date, active_flag) VALUES (6, 1, 5, 'Transection 0001', 5, NULL, '2025-08-15', true);
INSERT INTO masters.sizing_yarn_issue_entry (id, vendor_id, sizing_plan_id, transportation_dtl, terms_conditions_id, fabric_dtl, sizing_yarn_issue_date, active_flag) VALUES (7, 1, 5, 'Transection 0001', 5, NULL, '2025-08-19', true);
INSERT INTO masters.sizing_yarn_issue_entry (id, vendor_id, sizing_plan_id, transportation_dtl, terms_conditions_id, fabric_dtl, sizing_yarn_issue_date, active_flag) VALUES (8, 1, 5, 'Transection 0002', 5, NULL, '2025-08-19', true);


--
-- TOC entry 4216 (class 0 OID 238666)
-- Dependencies: 332
-- Data for Name: sizing_yarn_requirement; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sizing_yarn_requirement (id, sizing_yarn_issue_entry_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (1, 4, 'Yarn1', 2, 100.00, 100.00, 100.00, 100.00, true);
INSERT INTO masters.sizing_yarn_requirement (id, sizing_yarn_issue_entry_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (2, 5, 'Warp', 10, 10.00, 500.00, 0.00, 500.00, true);
INSERT INTO masters.sizing_yarn_requirement (id, sizing_yarn_issue_entry_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (3, 5, 'Weft', 10, 10.00, 500.00, 0.00, 500.00, true);
INSERT INTO masters.sizing_yarn_requirement (id, sizing_yarn_issue_entry_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (4, 6, 'Premium Cotton', 1, 0.00, 800.00, 0.00, 800.00, true);
INSERT INTO masters.sizing_yarn_requirement (id, sizing_yarn_issue_entry_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (5, 7, 'Premium Cotton', 1, 0.00, 800.00, 0.00, 800.00, true);
INSERT INTO masters.sizing_yarn_requirement (id, sizing_yarn_issue_entry_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (6, 8, 'Premium Cotton', 1, 0.00, 800.00, 0.00, 800.00, true);


--
-- TOC entry 4178 (class 0 OID 235933)
-- Dependencies: 294
-- Data for Name: state; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.state (id, country_sno, state_name, active_flag) VALUES (1, 1, 'Tamil Nadu', true);
INSERT INTO masters.state (id, country_sno, state_name, active_flag) VALUES (2, 2, 'America', true);
INSERT INTO masters.state (id, country_sno, state_name, active_flag) VALUES (4, 1, 'Keranataka', true);
INSERT INTO masters.state (id, country_sno, state_name, active_flag) VALUES (5, 1, 'Kerala', true);


--
-- TOC entry 4180 (class 0 OID 235938)
-- Dependencies: 296
-- Data for Name: sub_category; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.sub_category (id, category_sno, sub_category_name, active_flag) VALUES (2, 2, '10', true);
INSERT INTO masters.sub_category (id, category_sno, sub_category_name, active_flag) VALUES (3, 3, 'Twills', true);
INSERT INTO masters.sub_category (id, category_sno, sub_category_name, active_flag) VALUES (4, 3, 'Satin', true);
INSERT INTO masters.sub_category (id, category_sno, sub_category_name, active_flag) VALUES (5, 3, 'Plain', true);
INSERT INTO masters.sub_category (id, category_sno, sub_category_name, active_flag) VALUES (8, 2, '20', true);
INSERT INTO masters.sub_category (id, category_sno, sub_category_name, active_flag) VALUES (10, 1, 'Red', true);
INSERT INTO masters.sub_category (id, category_sno, sub_category_name, active_flag) VALUES (11, 1, 'Green', true);
INSERT INTO masters.sub_category (id, category_sno, sub_category_name, active_flag) VALUES (12, 1, 'Yellow', true);


--
-- TOC entry 4182 (class 0 OID 235943)
-- Dependencies: 298
-- Data for Name: tax_type; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.tax_type (id, tax_type_name, description, active_flag) VALUES (1, 'CGST', 'Central GST	', true);
INSERT INTO masters.tax_type (id, tax_type_name, description, active_flag) VALUES (2, 'SGST', 'State GST	', true);
INSERT INTO masters.tax_type (id, tax_type_name, description, active_flag) VALUES (3, 'IGST', 'Integrated GST	', true);


--
-- TOC entry 4184 (class 0 OID 235950)
-- Dependencies: 300
-- Data for Name: terms_conditions; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.terms_conditions (id, terms_conditions_name, description, active_flag) VALUES (5, 'Standard Payment Terms', 'Payment to be made within 30 days from the date of invoice. Late payment will incur an interest of 2% per month.', true);
INSERT INTO masters.terms_conditions (id, terms_conditions_name, description, active_flag) VALUES (6, 'Delivery and Shipping', 'All goods must be delivered to the specified address within the stipulated delivery period. Delays beyond 7 days may attract penalty.', true);


--
-- TOC entry 4185 (class 0 OID 235957)
-- Dependencies: 301
-- Data for Name: uom; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.uom (id, uom_code, uom_name, description, active_flag) VALUES (1, 'KG', 'Kilogram', 'Weight', true);
INSERT INTO masters.uom (id, uom_code, uom_name, description, active_flag) VALUES (2, 'Nos', 'Numbers', 'Numbers', true);
INSERT INTO masters.uom (id, uom_code, uom_name, description, active_flag) VALUES (3, 'Pc', 'Piece', 'Countable Units', true);


--
-- TOC entry 4187 (class 0 OID 235964)
-- Dependencies: 303
-- Data for Name: vendor; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.vendor (id, vendor_name, gstno, pancard, mobileno, email, address_id, active_flag, photo_url) VALUES (1, 'Kannan', 'sdfdsf', 'dsfdsfsd', '8765678987', 'kannan@gmail.com', 1, true, NULL);
INSERT INTO masters.vendor (id, vendor_name, gstno, pancard, mobileno, email, address_id, active_flag, photo_url) VALUES (2, 'Muthu', 'dsfsd', 'sdfsd', '9876789876', 'muthu@gmail.com', 4, true, 'string');
INSERT INTO masters.vendor (id, vendor_name, gstno, pancard, mobileno, email, address_id, active_flag, photo_url) VALUES (3, 'Aathi', 'ABCDE1234F', 'ABCDE1234F', '8667807043', 'aathi@gmail.com', 21, true, NULL);


--
-- TOC entry 4206 (class 0 OID 236572)
-- Dependencies: 322
-- Data for Name: warehouse_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.warehouse_master (id, active_flag, warehouse_name) VALUES (1, true, 'Warehouse1');
INSERT INTO masters.warehouse_master (id, active_flag, warehouse_name) VALUES (3, true, 'Warehouse2');


--
-- TOC entry 4189 (class 0 OID 235971)
-- Dependencies: 305
-- Data for Name: weaving_contract; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.weaving_contract (id, sales_order_no, vendor_id, terms_conditions_id, payment_terms_id, remarks, active_flag, weaving_contract_no) VALUES (1, 28, 1, 5, 2, 'string', true, 'WC-20250417-8263');
INSERT INTO masters.weaving_contract (id, sales_order_no, vendor_id, terms_conditions_id, payment_terms_id, remarks, active_flag, weaving_contract_no) VALUES (3, 29, 1, 5, 2, '213', true, 'WC-20250419-6465');
INSERT INTO masters.weaving_contract (id, sales_order_no, vendor_id, terms_conditions_id, payment_terms_id, remarks, active_flag, weaving_contract_no) VALUES (5, 29, 1, 5, 2, '', true, 'WC-20250510-5411');
INSERT INTO masters.weaving_contract (id, sales_order_no, vendor_id, terms_conditions_id, payment_terms_id, remarks, active_flag, weaving_contract_no) VALUES (6, 29, 1, 5, 2, '', true, 'WC-20250510-3319');


--
-- TOC entry 4191 (class 0 OID 235978)
-- Dependencies: 307
-- Data for Name: weaving_contract_item; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.weaving_contract_item (id, weaving_contract_id, fabric_code_id, fabric_quality_id, quantity, pick_cost, planned_start_date, planned_end_date, daily_target, number_of_looms, warp_length, warp_crimp_percentage, piece_length, number_of_pieces, active_flag) VALUES (1, 1, 10, 10, 100.00, 100.00, '2025-04-16', '2025-04-18', 20.00, 20, 10.00, 10.00, 10.00, 10, true);
INSERT INTO masters.weaving_contract_item (id, weaving_contract_id, fabric_code_id, fabric_quality_id, quantity, pick_cost, planned_start_date, planned_end_date, daily_target, number_of_looms, warp_length, warp_crimp_percentage, piece_length, number_of_pieces, active_flag) VALUES (3, 3, 10, 10, 123.00, 213.00, '2025-04-19', '2025-04-13', 213.00, 213, 213.00, 321.00, 321.00, 321, true);
INSERT INTO masters.weaving_contract_item (id, weaving_contract_id, fabric_code_id, fabric_quality_id, quantity, pick_cost, planned_start_date, planned_end_date, daily_target, number_of_looms, warp_length, warp_crimp_percentage, piece_length, number_of_pieces, active_flag) VALUES (4, 3, 11, 11, 321.00, 32.00, '2025-04-19', '2025-04-20', 21.00, 321, 32.00, 321.00, 231.00, 32, true);
INSERT INTO masters.weaving_contract_item (id, weaving_contract_id, fabric_code_id, fabric_quality_id, quantity, pick_cost, planned_start_date, planned_end_date, daily_target, number_of_looms, warp_length, warp_crimp_percentage, piece_length, number_of_pieces, active_flag) VALUES (6, 5, 10, 10, 100.00, 100.00, '2025-05-10', '2025-05-12', 20.00, 10, 10.00, 10.00, 10.00, 100, true);
INSERT INTO masters.weaving_contract_item (id, weaving_contract_id, fabric_code_id, fabric_quality_id, quantity, pick_cost, planned_start_date, planned_end_date, daily_target, number_of_looms, warp_length, warp_crimp_percentage, piece_length, number_of_pieces, active_flag) VALUES (7, 6, 16, 16, 10.00, 213.00, '2025-05-10', '2025-05-12', 123.00, 123, 213.00, 231.00, 3213.00, 21, true);


--
-- TOC entry 4193 (class 0 OID 235983)
-- Dependencies: 309
-- Data for Name: weaving_yarn_issue; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (1, 1, 1, 'Transt01', 5, 'sadasdasdsa', '2025-05-11', 'string', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (2, 1, 1, 'Trans-002', 5, NULL, '2025-05-11', 'YICNO-20250511-5866', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (3, 1, 1, 'Trans-002', 5, NULL, '2025-06-01', 'YICNO-20250531-9965', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (4, 1, 6, 'Transection 0001', 5, NULL, '2025-07-26', 'YICNO-20250726-5671', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (9, 1, 1, 'Transection 0001', 5, NULL, '2025-08-15', 'YICNO-20250815-7013', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (10, 1, 1, 'Transection 0001', 5, NULL, '2025-08-15', 'YICNO-20250815-3459', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (13, 1, 1, 'Transection 0001', 5, NULL, '2025-08-15', 'YICNO-20250815-3825', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (14, 1, 1, 'Transection 0001', 5, NULL, '2025-08-15', 'YICNO-20250815-3596', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (15, 1, 1, 'Transection 0001', 5, '', '2025-08-15', 'YICNO-20250815-3596', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (17, 3, 5, 'Transection 0001', 6, NULL, '2025-08-15', 'YICNO-20250815-1067', false);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (18, 1, 1, 'Transection 0001', 6, NULL, '2025-08-15', 'YICNO-20250815-3985', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (16, 1, 1, 'Transection 0001', 6, '', '2025-08-15', 'YICNO-20250815-5868', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (19, 1, 1, 'Transection 0002', 5, 'F-001', '2025-08-18', 'string', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (20, 1, 1, 'Transection 0009', 5, NULL, '2025-08-18', 'YICNO-20250818-5170', true);
INSERT INTO masters.weaving_yarn_issue (id, vendor_id, weaving_contract_id, transportation_dtl, terms_conditions_id, fabric_dtl, yarn_issue_date, yarn_issue_challan_no, active_flag) VALUES (21, 1, 1, 'Transection 0001', 5, NULL, '2025-08-18', 'YICNO-20250818-7683', true);


--
-- TOC entry 4195 (class 0 OID 235990)
-- Dependencies: 311
-- Data for Name: weaving_yarn_requirement; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (2, 2, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (3, 3, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (4, 4, 'Warp', 10, 100.00, 213.00, 0.00, 213.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (5, 4, 'Weft', 10, 100.00, 213.00, 0.00, 213.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (6, 9, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (7, 10, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (10, 13, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (11, 14, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (12, 15, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (15, 17, 'Warp', 10, 10.00, 500.00, 0.00, 500.00, true);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (16, 17, 'Weft', 10, 10.00, 500.00, 0.00, 500.00, true);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (17, 18, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (18, 16, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (19, 19, 'Yarn1', 20, 100.00, 100.00, 100.00, 100.00, true);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (20, 1, 'Yarn', 10, 10.00, 10.00, 0.00, 10.00, false);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (21, 20, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, true);
INSERT INTO masters.weaving_yarn_requirement (id, weaving_yarn_issue_id, yarn_name, yarn_count, grams_per_meter, total_req_qty, total_issue_qty, balance_to_issue, active_flag) VALUES (22, 21, 'Yarn1', 20, 100.00, 100.00, 0.00, 100.00, true);


--
-- TOC entry 4122 (class 0 OID 235765)
-- Dependencies: 238
-- Data for Name: woven_fabric_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (24, 2, 'CTN1908', 'Cotton', 3, 'High', 'Meters', 80, 75, 'GR123', 5000, 150.00, 200.00, 5.00, 2.50, 2.50, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (25, 2, 'CTN12334', 'Cotton', 3, 'High', 'Meters', 80, 75, 'GR123', 5000, 150.00, 200.00, 5.00, 2.50, 2.50, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (16, 2, 'CTN123', 'Cotton', 3, 'High', 'Meters', 80, 75, 'GR123', 5000, 150.00, 200.00, 50.00, 2.50, 2.50, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (18, 2, 'CTN1234', 'Cotton', 4, 'High', 'Meters', 80, 75, 'GR123', 5000, 150.00, 200.00, 5.00, 2.50, 2.50, NULL, 2, NULL, NULL, NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (11, 2, 'FAB-CODE-101', 'Polyester Silk', 3, 'High', 'Meters', 10, 10, 'GR123778', 10, 10.00, 10.00, 10.00, 10.00, 10.00, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (10, 2, 'FAB-CODE-100', 'Pure Cotton', 3, 'Premium', 'Meters', 10, 10, 'GR123', 10, 10.00, 10.00, 10.00, 10.00, 10.00, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (29, 2, 'CTN22345', 'Yarn', 3, 'High', '1', 100, 100, 'GR1231', 100, 100.00, 100.00, 100.00, 100.00, 100.00, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (32, 1, 'CT6788', 'Yarn', 3, 'High', '1', 100, 100, 'GT678', 100, 100.00, 100.00, 100.00, 100.00, 100.00, 'string', 1, 1, NULL, NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (39, 1, 'FAB-CODE-111', 'Fabric Name 1', 3, 'High', '1', 10, 10, 'sdfsd', 5000, 150.00, 200.00, 10.00, 2.50, 2.50, NULL, NULL, 1, '100', NULL, NULL);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (42, 1, 'FAB-CODE-1001', 'Pure Cotton', 3, 'High', '1', 10, 10, 'GR123', 5000, 150.00, 200.00, 10.00, 2.50, 2.50, NULL, NULL, 1, '100', NULL, 12.00);
INSERT INTO masters.woven_fabric_master (id, fabric_type_id, fabric_code, fabric_name, weave, fabric_quality, uom, epi, ppi, greige_code, total_ends, gsm, glm, igst, cgst, sgst, fabric_image_url, product_category_id, fabric_category_id, content, woven_fabric_id, std_value) VALUES (44, 2, 'FAB-CODE-900', 'Pure Cotton', 3, 'Premium', '1', 10, 10, 'GR12341', 5000, 150.00, 200.00, 10.00, 2.50, 2.50, NULL, NULL, 1, '100', 24, 12.00);


--
-- TOC entry 4197 (class 0 OID 235995)
-- Dependencies: 313
-- Data for Name: yarn_issue; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (2, 2, NULL, 'Yarn 1', 80.00, 0.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (3, 3, NULL, 'Yarn 1', 80.00, 0.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (4, 4, 1, 'Yarn 1', 80.00, 100.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (5, 4, 2, 'Yarn 2', 80.00, 100.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (6, 5, 1, 'Yarn 1', 80.00, 100.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (7, 5, 2, 'Yarn 2', 80.00, 100.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (8, 6, 18, 'Yarn 18', 100.00, 100.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (9, 7, 18, 'Yarn 18', 100.00, 100.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (12, 10, 18, 'Yarn 18', 100.00, 100.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (13, 11, 17, 'Yarn 17', 50.00, 50.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (14, 17, 16, 'Yarn 16', 50.00, 50.00, false);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (15, 19, 9, 'Yarn1', 20.00, 20.00, true);
INSERT INTO masters.yarn_issue (id, weaving_yarn_requirement_id, lot_id, yarn_name, available_req_qty, issue_qty, active_flag) VALUES (16, 20, 1, 'Yarn', 10.00, 10.00, false);


--
-- TOC entry 4199 (class 0 OID 236000)
-- Dependencies: 315
-- Data for Name: yarn_master; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.yarn_master (id, yarn_name, count_sno, types, conversion, active_flag, unit_sno, content) VALUES (1, 'Yarn 1', 2, 'type1', 154, true, NULL, NULL);
INSERT INTO masters.yarn_master (id, yarn_name, count_sno, types, conversion, active_flag, unit_sno, content) VALUES (4, 'Yarn 4', 2, 'type3', 134.9, true, NULL, NULL);
INSERT INTO masters.yarn_master (id, yarn_name, count_sno, types, conversion, active_flag, unit_sno, content) VALUES (5, 'Yarn 5', 2, 'type5', 134.9, true, NULL, NULL);
INSERT INTO masters.yarn_master (id, yarn_name, count_sno, types, conversion, active_flag, unit_sno, content) VALUES (2, 'Yarn 2', 2, 'type1', 154, true, NULL, NULL);
INSERT INTO masters.yarn_master (id, yarn_name, count_sno, types, conversion, active_flag, unit_sno, content) VALUES (3, 'Yarn 3', 2, 'type3', 134.9, true, 2, '100');


--
-- TOC entry 4201 (class 0 OID 236005)
-- Dependencies: 317
-- Data for Name: yarn_requirement; Type: TABLE DATA; Schema: masters; Owner: textipro_admin
--

INSERT INTO masters.yarn_requirement (id, weaving_contract_id, yarn_type, yarn_count, grams_per_meter, total_weaving_order_qty, total_required_qty, total_available_qty, active_flag) VALUES (1, 1, 'Yarn1', '20', 100.00, 200.00, 100.00, 400.00, true);
INSERT INTO masters.yarn_requirement (id, weaving_contract_id, yarn_type, yarn_count, grams_per_meter, total_weaving_order_qty, total_required_qty, total_available_qty, active_flag) VALUES (4, 5, 'Warp', '10', 10.00, 0.00, 500.00, 100.00, true);
INSERT INTO masters.yarn_requirement (id, weaving_contract_id, yarn_type, yarn_count, grams_per_meter, total_weaving_order_qty, total_required_qty, total_available_qty, active_flag) VALUES (5, 5, 'Weft', '10', 10.00, 0.00, 500.00, 100.00, true);
INSERT INTO masters.yarn_requirement (id, weaving_contract_id, yarn_type, yarn_count, grams_per_meter, total_weaving_order_qty, total_required_qty, total_available_qty, active_flag) VALUES (6, 6, 'Warp', '10', 100.00, 0.00, 213.00, 100.00, true);
INSERT INTO masters.yarn_requirement (id, weaving_contract_id, yarn_type, yarn_count, grams_per_meter, total_weaving_order_qty, total_required_qty, total_available_qty, active_flag) VALUES (7, 6, 'Weft', '10', 100.00, 0.00, 213.00, 100.00, true);


--
-- TOC entry 4315 (class 0 OID 0)
-- Dependencies: 211
-- Name: address_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.address_id_seq', 35, true);


--
-- TOC entry 4316 (class 0 OID 0)
-- Dependencies: 337
-- Name: beam_inward_beam_details_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.beam_inward_beam_details_id_seq', 6, true);


--
-- TOC entry 4317 (class 0 OID 0)
-- Dependencies: 335
-- Name: beam_inward_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.beam_inward_id_seq', 5, true);


--
-- TOC entry 4318 (class 0 OID 0)
-- Dependencies: 339
-- Name: beam_inward_quality_details_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.beam_inward_quality_details_id_seq', 6, true);


--
-- TOC entry 4319 (class 0 OID 0)
-- Dependencies: 213
-- Name: category_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.category_id_seq', 7, true);


--
-- TOC entry 4320 (class 0 OID 0)
-- Dependencies: 215
-- Name: city_city_sno_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.city_city_sno_seq', 14, true);


--
-- TOC entry 4321 (class 0 OID 0)
-- Dependencies: 217
-- Name: consignee_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.consignee_id_seq', 4, true);


--
-- TOC entry 4322 (class 0 OID 0)
-- Dependencies: 219
-- Name: country_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.country_id_seq', 14, true);


--
-- TOC entry 4323 (class 0 OID 0)
-- Dependencies: 221
-- Name: currency_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.currency_master_id_seq', 6, true);


--
-- TOC entry 4324 (class 0 OID 0)
-- Dependencies: 223
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.customer_id_seq', 16, true);


--
-- TOC entry 4325 (class 0 OID 0)
-- Dependencies: 341
-- Name: customer_international_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.customer_international_id_seq', 1, true);


--
-- TOC entry 4326 (class 0 OID 0)
-- Dependencies: 349
-- Name: defect_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: qbox_admin
--

SELECT pg_catalog.setval('masters.defect_master_id_seq', 4, true);


--
-- TOC entry 4327 (class 0 OID 0)
-- Dependencies: 225
-- Name: dyeing_work_order_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.dyeing_work_order_id_seq', 6, true);


--
-- TOC entry 4328 (class 0 OID 0)
-- Dependencies: 227
-- Name: dyeing_work_order_items_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.dyeing_work_order_items_id_seq', 9, true);


--
-- TOC entry 4329 (class 0 OID 0)
-- Dependencies: 229
-- Name: empty_beam_issue_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.empty_beam_issue_id_seq', 13, true);


--
-- TOC entry 4330 (class 0 OID 0)
-- Dependencies: 231
-- Name: empty_beam_issue_item_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.empty_beam_issue_item_id_seq', 17, true);


--
-- TOC entry 4331 (class 0 OID 0)
-- Dependencies: 233
-- Name: fabric_category_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.fabric_category_id_seq', 5, true);


--
-- TOC entry 4332 (class 0 OID 0)
-- Dependencies: 235
-- Name: fabric_dispatch_for_dyeing_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.fabric_dispatch_for_dyeing_id_seq', 4, true);


--
-- TOC entry 4333 (class 0 OID 0)
-- Dependencies: 237
-- Name: fabric_inspection_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.fabric_inspection_id_seq', 6, true);


--
-- TOC entry 4334 (class 0 OID 0)
-- Dependencies: 239
-- Name: fabric_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.fabric_master_id_seq', 44, true);


--
-- TOC entry 4335 (class 0 OID 0)
-- Dependencies: 241
-- Name: fabric_type_fabric_type_sno_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.fabric_type_fabric_type_sno_seq', 5, true);


--
-- TOC entry 4336 (class 0 OID 0)
-- Dependencies: 243
-- Name: fabric_warp_detail_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.fabric_warp_detail_id_seq', 21, true);


--
-- TOC entry 4337 (class 0 OID 0)
-- Dependencies: 245
-- Name: fabric_weft_detail_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.fabric_weft_detail_id_seq', 15, true);


--
-- TOC entry 4338 (class 0 OID 0)
-- Dependencies: 343
-- Name: finish_fabric_recive_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: qbox_admin
--

SELECT pg_catalog.setval('masters.finish_fabric_recive_id_seq', 2, true);


--
-- TOC entry 4339 (class 0 OID 0)
-- Dependencies: 345
-- Name: finish_fabric_recive_items_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: qbox_admin
--

SELECT pg_catalog.setval('masters.finish_fabric_recive_items_id_seq', 2, true);


--
-- TOC entry 4340 (class 0 OID 0)
-- Dependencies: 247
-- Name: finish_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.finish_master_id_seq', 3, true);


--
-- TOC entry 4341 (class 0 OID 0)
-- Dependencies: 249
-- Name: flange_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.flange_master_id_seq', 3, true);


--
-- TOC entry 4342 (class 0 OID 0)
-- Dependencies: 251
-- Name: generate_invoice_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.generate_invoice_id_seq', 10, true);


--
-- TOC entry 4343 (class 0 OID 0)
-- Dependencies: 323
-- Name: generate_packing_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.generate_packing_id_seq', 12, true);


--
-- TOC entry 4344 (class 0 OID 0)
-- Dependencies: 325
-- Name: generate_packing_item_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.generate_packing_item_id_seq', 15, true);


--
-- TOC entry 4345 (class 0 OID 0)
-- Dependencies: 347
-- Name: grade_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: qbox_admin
--

SELECT pg_catalog.setval('masters.grade_master_id_seq', 7, true);


--
-- TOC entry 4346 (class 0 OID 0)
-- Dependencies: 253
-- Name: gst_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.gst_master_id_seq', 6, true);


--
-- TOC entry 4347 (class 0 OID 0)
-- Dependencies: 255
-- Name: inspection_dtl_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.inspection_dtl_id_seq', 7, true);


--
-- TOC entry 4348 (class 0 OID 0)
-- Dependencies: 257
-- Name: inspection_entry_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.inspection_entry_id_seq', 7, true);


--
-- TOC entry 4349 (class 0 OID 0)
-- Dependencies: 259
-- Name: jobwork_fabric_receive_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.jobwork_fabric_receive_id_seq', 20, true);


--
-- TOC entry 4350 (class 0 OID 0)
-- Dependencies: 261
-- Name: jobwork_fabric_receive_item_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.jobwork_fabric_receive_item_id_seq', 19, true);


--
-- TOC entry 4351 (class 0 OID 0)
-- Dependencies: 319
-- Name: knitted_fabric_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.knitted_fabric_master_id_seq', 2, true);


--
-- TOC entry 4352 (class 0 OID 0)
-- Dependencies: 263
-- Name: lot_entry_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.lot_entry_id_seq', 18, true);


--
-- TOC entry 4353 (class 0 OID 0)
-- Dependencies: 351
-- Name: lot_outward_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.lot_outward_id_seq', 4, true);


--
-- TOC entry 4354 (class 0 OID 0)
-- Dependencies: 265
-- Name: payment_terms_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.payment_terms_id_seq', 2, true);


--
-- TOC entry 4355 (class 0 OID 0)
-- Dependencies: 267
-- Name: piece_entry_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.piece_entry_id_seq', 19, true);


--
-- TOC entry 4356 (class 0 OID 0)
-- Dependencies: 269
-- Name: po_type_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.po_type_master_id_seq', 6, true);


--
-- TOC entry 4357 (class 0 OID 0)
-- Dependencies: 353
-- Name: process_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.process_master_id_seq', 2, true);


--
-- TOC entry 4358 (class 0 OID 0)
-- Dependencies: 271
-- Name: product_category_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.product_category_id_seq', 3, true);


--
-- TOC entry 4359 (class 0 OID 0)
-- Dependencies: 273
-- Name: purchase_inward_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.purchase_inward_id_seq', 15, true);


--
-- TOC entry 4360 (class 0 OID 0)
-- Dependencies: 275
-- Name: purchase_inward_item_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.purchase_inward_item_id_seq', 16, true);


--
-- TOC entry 4361 (class 0 OID 0)
-- Dependencies: 277
-- Name: purchase_order_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.purchase_order_id_seq', 38, true);


--
-- TOC entry 4362 (class 0 OID 0)
-- Dependencies: 279
-- Name: purchase_order_item_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.purchase_order_item_id_seq', 19, true);


--
-- TOC entry 4363 (class 0 OID 0)
-- Dependencies: 333
-- Name: sales_order_ext_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sales_order_ext_seq', 1, false);


--
-- TOC entry 4364 (class 0 OID 0)
-- Dependencies: 281
-- Name: sales_order_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sales_order_id_seq', 78, true);


--
-- TOC entry 4365 (class 0 OID 0)
-- Dependencies: 334
-- Name: sales_order_int_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sales_order_int_seq', 1, false);


--
-- TOC entry 4366 (class 0 OID 0)
-- Dependencies: 283
-- Name: sales_order_item_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sales_order_item_id_seq', 57, true);


--
-- TOC entry 4367 (class 0 OID 0)
-- Dependencies: 285
-- Name: shipment_mode_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.shipment_mode_id_seq', 4, true);


--
-- TOC entry 4368 (class 0 OID 0)
-- Dependencies: 287
-- Name: shipment_terms_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.shipment_terms_id_seq', 6, true);


--
-- TOC entry 4369 (class 0 OID 0)
-- Dependencies: 289
-- Name: sizing_beam_details_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sizing_beam_details_id_seq', 12, true);


--
-- TOC entry 4370 (class 0 OID 0)
-- Dependencies: 291
-- Name: sizing_plan_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sizing_plan_id_seq', 13, true);


--
-- TOC entry 4371 (class 0 OID 0)
-- Dependencies: 293
-- Name: sizing_quality_details_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sizing_quality_details_id_seq', 11, true);


--
-- TOC entry 4372 (class 0 OID 0)
-- Dependencies: 327
-- Name: sizing_yarn_issue_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sizing_yarn_issue_id_seq', 8, true);


--
-- TOC entry 4373 (class 0 OID 0)
-- Dependencies: 329
-- Name: sizing_yarn_issue_id_seq1; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sizing_yarn_issue_id_seq1', 5, true);


--
-- TOC entry 4374 (class 0 OID 0)
-- Dependencies: 331
-- Name: sizing_yarn_requirement_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sizing_yarn_requirement_id_seq', 6, true);


--
-- TOC entry 4375 (class 0 OID 0)
-- Dependencies: 295
-- Name: state_state_sno_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.state_state_sno_seq', 5, true);


--
-- TOC entry 4376 (class 0 OID 0)
-- Dependencies: 297
-- Name: sub_category_sub_category_sno_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.sub_category_sub_category_sno_seq', 12, true);


--
-- TOC entry 4377 (class 0 OID 0)
-- Dependencies: 299
-- Name: tax_type_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.tax_type_id_seq', 3, true);


--
-- TOC entry 4378 (class 0 OID 0)
-- Dependencies: 302
-- Name: uom_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.uom_id_seq', 5, true);


--
-- TOC entry 4379 (class 0 OID 0)
-- Dependencies: 304
-- Name: vendor_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.vendor_id_seq', 4, true);


--
-- TOC entry 4380 (class 0 OID 0)
-- Dependencies: 321
-- Name: warehouse_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.warehouse_master_id_seq', 4, true);


--
-- TOC entry 4381 (class 0 OID 0)
-- Dependencies: 306
-- Name: weaving_contract_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.weaving_contract_id_seq', 12, true);


--
-- TOC entry 4382 (class 0 OID 0)
-- Dependencies: 308
-- Name: weaving_contract_item_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.weaving_contract_item_id_seq', 18, true);


--
-- TOC entry 4383 (class 0 OID 0)
-- Dependencies: 310
-- Name: weaving_yarn_issue_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.weaving_yarn_issue_id_seq', 21, true);


--
-- TOC entry 4384 (class 0 OID 0)
-- Dependencies: 312
-- Name: weaving_yarn_requirement_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.weaving_yarn_requirement_id_seq', 22, true);


--
-- TOC entry 4385 (class 0 OID 0)
-- Dependencies: 314
-- Name: yarn_issue_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.yarn_issue_id_seq', 16, true);


--
-- TOC entry 4386 (class 0 OID 0)
-- Dependencies: 316
-- Name: yarn_master_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.yarn_master_id_seq', 5, true);


--
-- TOC entry 4387 (class 0 OID 0)
-- Dependencies: 318
-- Name: yarn_requirement_id_seq; Type: SEQUENCE SET; Schema: masters; Owner: textipro_admin
--

SELECT pg_catalog.setval('masters.yarn_requirement_id_seq', 23, true);


--
-- TOC entry 3696 (class 2606 OID 236065)
-- Name: address address_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (id);


--
-- TOC entry 3852 (class 2606 OID 238697)
-- Name: beam_inward_beam_details beam_inward_beam_details_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.beam_inward_beam_details
    ADD CONSTRAINT beam_inward_beam_details_pkey PRIMARY KEY (id);


--
-- TOC entry 3850 (class 2606 OID 238690)
-- Name: beam_inward beam_inward_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.beam_inward
    ADD CONSTRAINT beam_inward_pkey PRIMARY KEY (id);


--
-- TOC entry 3854 (class 2606 OID 238704)
-- Name: beam_inward_quality_details beam_inward_quality_details_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.beam_inward_quality_details
    ADD CONSTRAINT beam_inward_quality_details_pkey PRIMARY KEY (id);


--
-- TOC entry 3698 (class 2606 OID 236067)
-- Name: category category_category_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.category
    ADD CONSTRAINT category_category_name_key UNIQUE (category_name);


--
-- TOC entry 3700 (class 2606 OID 236069)
-- Name: category category_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);


--
-- TOC entry 3702 (class 2606 OID 236071)
-- Name: city cit_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.city
    ADD CONSTRAINT cit_pkey PRIMARY KEY (id);


--
-- TOC entry 3704 (class 2606 OID 236073)
-- Name: consignee consignee_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.consignee
    ADD CONSTRAINT consignee_pkey PRIMARY KEY (id);


--
-- TOC entry 3706 (class 2606 OID 236075)
-- Name: country country_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (id);


--
-- TOC entry 3708 (class 2606 OID 236077)
-- Name: currency_master currency_master_currency_code_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.currency_master
    ADD CONSTRAINT currency_master_currency_code_key UNIQUE (currency_code);


--
-- TOC entry 3710 (class 2606 OID 236079)
-- Name: currency_master currency_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.currency_master
    ADD CONSTRAINT currency_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3856 (class 2606 OID 238724)
-- Name: customer_international customer_international_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.customer_international
    ADD CONSTRAINT customer_international_pkey PRIMARY KEY (id);


--
-- TOC entry 3712 (class 2606 OID 236081)
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- TOC entry 3864 (class 2606 OID 261284)
-- Name: defect_master defect_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.defect_master
    ADD CONSTRAINT defect_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3716 (class 2606 OID 236083)
-- Name: dyeing_work_order_items dyeing_work_order_items_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.dyeing_work_order_items
    ADD CONSTRAINT dyeing_work_order_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3714 (class 2606 OID 236085)
-- Name: dyeing_work_order dyeing_work_order_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.dyeing_work_order
    ADD CONSTRAINT dyeing_work_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3720 (class 2606 OID 236087)
-- Name: empty_beam_issue_item empty_beam_issue_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.empty_beam_issue_item
    ADD CONSTRAINT empty_beam_issue_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3718 (class 2606 OID 236089)
-- Name: empty_beam_issue empty_beam_issue_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.empty_beam_issue
    ADD CONSTRAINT empty_beam_issue_pkey PRIMARY KEY (id);


--
-- TOC entry 3722 (class 2606 OID 236091)
-- Name: fabric_category fabric_category_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_category
    ADD CONSTRAINT fabric_category_pkey PRIMARY KEY (id);


--
-- TOC entry 3724 (class 2606 OID 236093)
-- Name: fabric_dispatch_for_dyeing fabric_dispatch_for_dyeing_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_dispatch_for_dyeing
    ADD CONSTRAINT fabric_dispatch_for_dyeing_pkey PRIMARY KEY (id);


--
-- TOC entry 3726 (class 2606 OID 236095)
-- Name: fabric_inspection fabric_inspection_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_inspection
    ADD CONSTRAINT fabric_inspection_pkey PRIMARY KEY (id);


--
-- TOC entry 3728 (class 2606 OID 236097)
-- Name: woven_fabric_master fabric_master_fabric_code_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.woven_fabric_master
    ADD CONSTRAINT fabric_master_fabric_code_key UNIQUE (fabric_code);


--
-- TOC entry 3730 (class 2606 OID 236099)
-- Name: woven_fabric_master fabric_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.woven_fabric_master
    ADD CONSTRAINT fabric_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3732 (class 2606 OID 236101)
-- Name: fabric_type fabric_type_fabric_type_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_type
    ADD CONSTRAINT fabric_type_fabric_type_name_key UNIQUE (fabric_type_name);


--
-- TOC entry 3734 (class 2606 OID 236103)
-- Name: fabric_type fabric_type_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_type
    ADD CONSTRAINT fabric_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3736 (class 2606 OID 236105)
-- Name: fabric_warp_detail fabric_warp_detail_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_warp_detail
    ADD CONSTRAINT fabric_warp_detail_pkey PRIMARY KEY (id);


--
-- TOC entry 3738 (class 2606 OID 236107)
-- Name: fabric_weft_detail fabric_weft_detail_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_weft_detail
    ADD CONSTRAINT fabric_weft_detail_pkey PRIMARY KEY (id);


--
-- TOC entry 3860 (class 2606 OID 261241)
-- Name: finish_fabric_receive_items finish_fabric_recive_items_pkey; Type: CONSTRAINT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.finish_fabric_receive_items
    ADD CONSTRAINT finish_fabric_recive_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3858 (class 2606 OID 261233)
-- Name: finish_fabric_receive finish_fabric_recive_pkey; Type: CONSTRAINT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.finish_fabric_receive
    ADD CONSTRAINT finish_fabric_recive_pkey PRIMARY KEY (id);


--
-- TOC entry 3740 (class 2606 OID 236109)
-- Name: finish_master finish_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.finish_master
    ADD CONSTRAINT finish_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3742 (class 2606 OID 236111)
-- Name: flange_master flange_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.flange_master
    ADD CONSTRAINT flange_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3744 (class 2606 OID 236113)
-- Name: generate_invoice generate_invoice_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_invoice
    ADD CONSTRAINT generate_invoice_pkey PRIMARY KEY (id);


--
-- TOC entry 3842 (class 2606 OID 236608)
-- Name: generate_packing_item generate_packing_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing_item
    ADD CONSTRAINT generate_packing_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3840 (class 2606 OID 236584)
-- Name: generate_packing generate_packing_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing
    ADD CONSTRAINT generate_packing_pkey PRIMARY KEY (id);


--
-- TOC entry 3862 (class 2606 OID 261274)
-- Name: grade_master grade_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.grade_master
    ADD CONSTRAINT grade_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3746 (class 2606 OID 236115)
-- Name: gst_master gst_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.gst_master
    ADD CONSTRAINT gst_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3748 (class 2606 OID 236117)
-- Name: inspection_dtl inspection_dtl_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.inspection_dtl
    ADD CONSTRAINT inspection_dtl_pkey PRIMARY KEY (id);


--
-- TOC entry 3750 (class 2606 OID 236119)
-- Name: inspection_entry inspection_entry_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.inspection_entry
    ADD CONSTRAINT inspection_entry_pkey PRIMARY KEY (id);


--
-- TOC entry 3754 (class 2606 OID 236121)
-- Name: jobwork_fabric_receive_item jobwork_fabric_receive_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.jobwork_fabric_receive_item
    ADD CONSTRAINT jobwork_fabric_receive_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3752 (class 2606 OID 236123)
-- Name: jobwork_fabric_receive jobwork_fabric_receive_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.jobwork_fabric_receive
    ADD CONSTRAINT jobwork_fabric_receive_pkey PRIMARY KEY (id);


--
-- TOC entry 3836 (class 2606 OID 236563)
-- Name: knitted_fabric_master knitted_fabric_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.knitted_fabric_master
    ADD CONSTRAINT knitted_fabric_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3756 (class 2606 OID 236125)
-- Name: lot_entry lot_entry_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.lot_entry
    ADD CONSTRAINT lot_entry_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3866 (class 2606 OID 261291)
-- Name: lot_outward lot_outward_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.lot_outward
    ADD CONSTRAINT lot_outward_pkey PRIMARY KEY (id);


--
-- TOC entry 3758 (class 2606 OID 236127)
-- Name: payment_terms payment_terms_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.payment_terms
    ADD CONSTRAINT payment_terms_pkey PRIMARY KEY (id);


--
-- TOC entry 3760 (class 2606 OID 236129)
-- Name: payment_terms payment_terms_term_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.payment_terms
    ADD CONSTRAINT payment_terms_term_name_key UNIQUE (term_name);


--
-- TOC entry 3762 (class 2606 OID 236131)
-- Name: piece_entry piece_entry_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.piece_entry
    ADD CONSTRAINT piece_entry_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3764 (class 2606 OID 236133)
-- Name: po_type_master po_type_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.po_type_master
    ADD CONSTRAINT po_type_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3766 (class 2606 OID 236135)
-- Name: po_type_master po_type_master_po_type_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.po_type_master
    ADD CONSTRAINT po_type_master_po_type_name_key UNIQUE (po_type_name);


--
-- TOC entry 3868 (class 2606 OID 272525)
-- Name: process_master process_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.process_master
    ADD CONSTRAINT process_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3768 (class 2606 OID 236137)
-- Name: product_category product_category_fabric_code_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.product_category
    ADD CONSTRAINT product_category_fabric_code_key UNIQUE (fabric_code);


--
-- TOC entry 3770 (class 2606 OID 236139)
-- Name: product_category product_category_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.product_category
    ADD CONSTRAINT product_category_pkey PRIMARY KEY (id);


--
-- TOC entry 3774 (class 2606 OID 236141)
-- Name: purchase_inward_item purchase_inward_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_inward_item
    ADD CONSTRAINT purchase_inward_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3772 (class 2606 OID 236143)
-- Name: purchase_inward purchase_inward_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_inward
    ADD CONSTRAINT purchase_inward_pkey PRIMARY KEY (id);


--
-- TOC entry 3778 (class 2606 OID 236145)
-- Name: purchase_order_item purchase_order_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_order_item
    ADD CONSTRAINT purchase_order_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3776 (class 2606 OID 236147)
-- Name: purchase_orders purchase_order_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_orders
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3782 (class 2606 OID 236149)
-- Name: sales_order_item sales_order_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order_item
    ADD CONSTRAINT sales_order_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3780 (class 2606 OID 236151)
-- Name: sales_order sales_order_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order
    ADD CONSTRAINT sales_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3784 (class 2606 OID 236153)
-- Name: shipment_mode shipment_mode_mode_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.shipment_mode
    ADD CONSTRAINT shipment_mode_mode_name_key UNIQUE (mode_name);


--
-- TOC entry 3786 (class 2606 OID 236155)
-- Name: shipment_mode shipment_mode_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.shipment_mode
    ADD CONSTRAINT shipment_mode_pkey PRIMARY KEY (id);


--
-- TOC entry 3788 (class 2606 OID 236157)
-- Name: shipment_terms shipment_terms_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.shipment_terms
    ADD CONSTRAINT shipment_terms_pkey PRIMARY KEY (id);


--
-- TOC entry 3790 (class 2606 OID 236159)
-- Name: shipment_terms shipment_terms_term_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.shipment_terms
    ADD CONSTRAINT shipment_terms_term_name_key UNIQUE (term_name);


--
-- TOC entry 3792 (class 2606 OID 236161)
-- Name: sizing_beam_details sizing_beam_details_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_beam_details
    ADD CONSTRAINT sizing_beam_details_pkey PRIMARY KEY (id);


--
-- TOC entry 3794 (class 2606 OID 236163)
-- Name: sizing_plan sizing_plan_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_plan
    ADD CONSTRAINT sizing_plan_pkey PRIMARY KEY (id);


--
-- TOC entry 3796 (class 2606 OID 236165)
-- Name: sizing_quality_details sizing_quality_details_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_quality_details
    ADD CONSTRAINT sizing_quality_details_pkey PRIMARY KEY (id);


--
-- TOC entry 3844 (class 2606 OID 238595)
-- Name: sizing_yarn_issue_entry sizing_yarn_issue_entry_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue_entry
    ADD CONSTRAINT sizing_yarn_issue_entry_pkey PRIMARY KEY (id);


--
-- TOC entry 3846 (class 2606 OID 238637)
-- Name: sizing_yarn_issue sizing_yarn_issue_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue
    ADD CONSTRAINT sizing_yarn_issue_pkey PRIMARY KEY (id);


--
-- TOC entry 3848 (class 2606 OID 238672)
-- Name: sizing_yarn_requirement sizing_yarn_requirement_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_requirement
    ADD CONSTRAINT sizing_yarn_requirement_pkey PRIMARY KEY (id);


--
-- TOC entry 3798 (class 2606 OID 236167)
-- Name: state state_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.state
    ADD CONSTRAINT state_pkey PRIMARY KEY (id);


--
-- TOC entry 3800 (class 2606 OID 236169)
-- Name: sub_category sub_category_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sub_category
    ADD CONSTRAINT sub_category_pkey PRIMARY KEY (id);


--
-- TOC entry 3802 (class 2606 OID 236171)
-- Name: sub_category sub_category_sub_category_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sub_category
    ADD CONSTRAINT sub_category_sub_category_name_key UNIQUE (sub_category_name);


--
-- TOC entry 3804 (class 2606 OID 236173)
-- Name: tax_type tax_type_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.tax_type
    ADD CONSTRAINT tax_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3806 (class 2606 OID 236175)
-- Name: tax_type tax_type_tax_type_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.tax_type
    ADD CONSTRAINT tax_type_tax_type_name_key UNIQUE (tax_type_name);


--
-- TOC entry 3808 (class 2606 OID 236177)
-- Name: terms_conditions terms_conditions_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.terms_conditions
    ADD CONSTRAINT terms_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 3810 (class 2606 OID 236179)
-- Name: terms_conditions terms_conditions_terms_conditions_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.terms_conditions
    ADD CONSTRAINT terms_conditions_terms_conditions_name_key UNIQUE (terms_conditions_name);


--
-- TOC entry 3818 (class 2606 OID 236181)
-- Name: weaving_contract uk_judvrnk48j28fc0ymg7s6ql13; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract
    ADD CONSTRAINT uk_judvrnk48j28fc0ymg7s6ql13 UNIQUE (weaving_contract_no);


--
-- TOC entry 3812 (class 2606 OID 236183)
-- Name: uom uom_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.uom
    ADD CONSTRAINT uom_pkey PRIMARY KEY (id);


--
-- TOC entry 3814 (class 2606 OID 236185)
-- Name: uom uom_uom_code_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.uom
    ADD CONSTRAINT uom_uom_code_key UNIQUE (uom_code);


--
-- TOC entry 3816 (class 2606 OID 236187)
-- Name: vendor vendor_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.vendor
    ADD CONSTRAINT vendor_pkey PRIMARY KEY (id);


--
-- TOC entry 3838 (class 2606 OID 236577)
-- Name: warehouse_master warehouse_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.warehouse_master
    ADD CONSTRAINT warehouse_master_pkey PRIMARY KEY (id);


--
-- TOC entry 3822 (class 2606 OID 236189)
-- Name: weaving_contract_item weaving_contract_item_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract_item
    ADD CONSTRAINT weaving_contract_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3820 (class 2606 OID 236191)
-- Name: weaving_contract weaving_contract_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract
    ADD CONSTRAINT weaving_contract_pkey PRIMARY KEY (id);


--
-- TOC entry 3824 (class 2606 OID 236193)
-- Name: weaving_yarn_issue weaving_yarn_issue_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_yarn_issue
    ADD CONSTRAINT weaving_yarn_issue_pkey PRIMARY KEY (id);


--
-- TOC entry 3826 (class 2606 OID 236195)
-- Name: weaving_yarn_requirement weaving_yarn_requirement_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_yarn_requirement
    ADD CONSTRAINT weaving_yarn_requirement_pkey PRIMARY KEY (id);


--
-- TOC entry 3828 (class 2606 OID 236197)
-- Name: yarn_issue yarn_issue_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_issue
    ADD CONSTRAINT yarn_issue_pkey PRIMARY KEY (id);


--
-- TOC entry 3830 (class 2606 OID 236199)
-- Name: yarn_master yarn_master_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_master
    ADD CONSTRAINT yarn_master_pkey PRIMARY KEY (id) INCLUDE (id);


--
-- TOC entry 3832 (class 2606 OID 236201)
-- Name: yarn_master yarn_master_yarn_name_key; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_master
    ADD CONSTRAINT yarn_master_yarn_name_key UNIQUE (yarn_name);


--
-- TOC entry 3834 (class 2606 OID 236203)
-- Name: yarn_requirement yarn_requirement_pkey; Type: CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_requirement
    ADD CONSTRAINT yarn_requirement_pkey PRIMARY KEY (id);


--
-- TOC entry 3869 (class 2606 OID 236204)
-- Name: address address_city_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.address
    ADD CONSTRAINT address_city_id_fkey FOREIGN KEY (city_id) REFERENCES masters.city(id) NOT VALID;


--
-- TOC entry 3870 (class 2606 OID 236209)
-- Name: address address_country_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.address
    ADD CONSTRAINT address_country_id_fkey FOREIGN KEY (country_id) REFERENCES masters.country(id) NOT VALID;


--
-- TOC entry 3871 (class 2606 OID 236214)
-- Name: address address_state_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.address
    ADD CONSTRAINT address_state_id_fkey FOREIGN KEY (state_id) REFERENCES masters.state(id) NOT VALID;


--
-- TOC entry 3872 (class 2606 OID 236219)
-- Name: city city_country_sno_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.city
    ADD CONSTRAINT city_country_sno_fkey FOREIGN KEY (country_sno) REFERENCES masters.country(id) NOT VALID;


--
-- TOC entry 3873 (class 2606 OID 236224)
-- Name: city city_state_sno_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.city
    ADD CONSTRAINT city_state_sno_fkey FOREIGN KEY (state_sno) REFERENCES masters.state(id);


--
-- TOC entry 3874 (class 2606 OID 236229)
-- Name: consignee consignee_address_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.consignee
    ADD CONSTRAINT consignee_address_id_fkey FOREIGN KEY (address_id) REFERENCES masters.address(id);


--
-- TOC entry 3875 (class 2606 OID 236234)
-- Name: customer customer_address_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.customer
    ADD CONSTRAINT customer_address_id_fkey FOREIGN KEY (address_id) REFERENCES masters.address(id) NOT VALID;


--
-- TOC entry 3953 (class 2606 OID 238725)
-- Name: customer_international customer_international_address_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.customer_international
    ADD CONSTRAINT customer_international_address_id_fkey FOREIGN KEY (address_id) REFERENCES masters.address(id);


--
-- TOC entry 3877 (class 2606 OID 236239)
-- Name: empty_beam_issue empty_beam_issue_consignee_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.empty_beam_issue
    ADD CONSTRAINT empty_beam_issue_consignee_id_fkey FOREIGN KEY (consignee_id) REFERENCES masters.consignee(id) NOT VALID;


--
-- TOC entry 3916 (class 2606 OID 236244)
-- Name: sizing_plan empty_beam_issue_consignee_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_plan
    ADD CONSTRAINT empty_beam_issue_consignee_id_fkey FOREIGN KEY (consignee_id) REFERENCES masters.consignee(id);


--
-- TOC entry 3879 (class 2606 OID 236249)
-- Name: empty_beam_issue_item empty_beam_issue_item_empty_beam_issue_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.empty_beam_issue_item
    ADD CONSTRAINT empty_beam_issue_item_empty_beam_issue_id_fkey FOREIGN KEY (empty_beam_issue_id) REFERENCES masters.empty_beam_issue(id) NOT VALID;


--
-- TOC entry 3880 (class 2606 OID 236254)
-- Name: empty_beam_issue_item empty_beam_issue_item_flange_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.empty_beam_issue_item
    ADD CONSTRAINT empty_beam_issue_item_flange_id_fkey FOREIGN KEY (flange_id) REFERENCES masters.flange_master(id) NOT VALID;


--
-- TOC entry 3878 (class 2606 OID 236259)
-- Name: empty_beam_issue empty_beam_issue_vendor_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.empty_beam_issue
    ADD CONSTRAINT empty_beam_issue_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES masters.vendor(id) NOT VALID;


--
-- TOC entry 3917 (class 2606 OID 236264)
-- Name: sizing_plan empty_beam_issue_vendor_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_plan
    ADD CONSTRAINT empty_beam_issue_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES masters.vendor(id);


--
-- TOC entry 3881 (class 2606 OID 236269)
-- Name: woven_fabric_master fabric_master_fabric_category_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.woven_fabric_master
    ADD CONSTRAINT fabric_master_fabric_category_id_fkey FOREIGN KEY (fabric_category_id) REFERENCES masters.fabric_category(id) NOT VALID;


--
-- TOC entry 3882 (class 2606 OID 236274)
-- Name: woven_fabric_master fabric_master_fabric_type_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.woven_fabric_master
    ADD CONSTRAINT fabric_master_fabric_type_fkey FOREIGN KEY (fabric_type_id) REFERENCES masters.fabric_type(id) NOT VALID;


--
-- TOC entry 3883 (class 2606 OID 236279)
-- Name: fabric_warp_detail fabric_warp_detail_fabric_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_warp_detail
    ADD CONSTRAINT fabric_warp_detail_fabric_id_fkey FOREIGN KEY (fabric_id) REFERENCES masters.woven_fabric_master(id) NOT VALID;


--
-- TOC entry 3884 (class 2606 OID 236284)
-- Name: fabric_warp_detail fabric_warp_detail_yarn_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_warp_detail
    ADD CONSTRAINT fabric_warp_detail_yarn_id_fkey FOREIGN KEY (yarn_id) REFERENCES masters.yarn_master(id) NOT VALID;


--
-- TOC entry 3885 (class 2606 OID 236289)
-- Name: fabric_weft_detail fabric_weft_detail_fabric_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_weft_detail
    ADD CONSTRAINT fabric_weft_detail_fabric_id_fkey FOREIGN KEY (fabric_id) REFERENCES masters.woven_fabric_master(id) NOT VALID;


--
-- TOC entry 3886 (class 2606 OID 236294)
-- Name: fabric_weft_detail fabric_weft_detail_yarn_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.fabric_weft_detail
    ADD CONSTRAINT fabric_weft_detail_yarn_id_fkey FOREIGN KEY (yarn_id) REFERENCES masters.yarn_master(id) NOT VALID;


--
-- TOC entry 3954 (class 2606 OID 261242)
-- Name: finish_fabric_receive_items finish_fabric_receive_items_finish_fabric_receive_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: qbox_admin
--

ALTER TABLE ONLY masters.finish_fabric_receive_items
    ADD CONSTRAINT finish_fabric_receive_items_finish_fabric_receive_id_fkey FOREIGN KEY (finish_fabric_receive_id) REFERENCES masters.finish_fabric_receive(id) NOT VALID;


--
-- TOC entry 3951 (class 2606 OID 238705)
-- Name: beam_inward_beam_details fk62fmh73fuevdusg6bn5wqix8v; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.beam_inward_beam_details
    ADD CONSTRAINT fk62fmh73fuevdusg6bn5wqix8v FOREIGN KEY (beam_inward_id) REFERENCES masters.beam_inward(id);


--
-- TOC entry 3923 (class 2606 OID 236299)
-- Name: sub_category fk702l3khdt8eu1i5qdnsi916d0; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sub_category
    ADD CONSTRAINT fk702l3khdt8eu1i5qdnsi916d0 FOREIGN KEY (category_sno) REFERENCES masters.category(id);


--
-- TOC entry 3935 (class 2606 OID 236304)
-- Name: weaving_yarn_requirement fkds9yuqcfvgbhmepheg0xbdp3y; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_yarn_requirement
    ADD CONSTRAINT fkds9yuqcfvgbhmepheg0xbdp3y FOREIGN KEY (weaving_yarn_issue_id) REFERENCES masters.weaving_yarn_issue(id);


--
-- TOC entry 3936 (class 2606 OID 236309)
-- Name: yarn_issue fkgwpnpileo73ukuydhg435d4py; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_issue
    ADD CONSTRAINT fkgwpnpileo73ukuydhg435d4py FOREIGN KEY (weaving_yarn_requirement_id) REFERENCES masters.weaving_yarn_requirement(id);


--
-- TOC entry 3888 (class 2606 OID 236314)
-- Name: inspection_entry fkoiafcbkg65k9sn484hko68lk0; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.inspection_entry
    ADD CONSTRAINT fkoiafcbkg65k9sn484hko68lk0 FOREIGN KEY (fabric_inspection_id) REFERENCES masters.fabric_inspection(id);


--
-- TOC entry 3876 (class 2606 OID 236319)
-- Name: dyeing_work_order_items fkophaedyg79woea12sdoe6dkgi; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.dyeing_work_order_items
    ADD CONSTRAINT fkophaedyg79woea12sdoe6dkgi FOREIGN KEY (dyeing_work_order_id) REFERENCES masters.dyeing_work_order(id);


--
-- TOC entry 3952 (class 2606 OID 238710)
-- Name: beam_inward_quality_details fkslfxyoh05ch7mc3ty795ahgpr; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.beam_inward_quality_details
    ADD CONSTRAINT fkslfxyoh05ch7mc3ty795ahgpr FOREIGN KEY (beam_inward_id) REFERENCES masters.beam_inward(id);


--
-- TOC entry 3939 (class 2606 OID 236585)
-- Name: generate_packing generate_packing_buyer_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing
    ADD CONSTRAINT generate_packing_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES masters.customer(id) NOT VALID;


--
-- TOC entry 3942 (class 2606 OID 236609)
-- Name: generate_packing_item generate_packing_item_generated_packing_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing_item
    ADD CONSTRAINT generate_packing_item_generated_packing_id_fkey FOREIGN KEY (generated_packing_id) REFERENCES masters.generate_packing(id) NOT VALID;


--
-- TOC entry 3943 (class 2606 OID 236619)
-- Name: generate_packing_item generate_packing_item_lot_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing_item
    ADD CONSTRAINT generate_packing_item_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES masters.lot_entry(id) NOT VALID;


--
-- TOC entry 3944 (class 2606 OID 236614)
-- Name: generate_packing_item generate_packing_item_uom_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing_item
    ADD CONSTRAINT generate_packing_item_uom_id_fkey FOREIGN KEY (uom_id) REFERENCES masters.uom(id) NOT VALID;


--
-- TOC entry 3940 (class 2606 OID 236590)
-- Name: generate_packing generate_packing_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing
    ADD CONSTRAINT generate_packing_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES masters.sales_order(id) NOT VALID;


--
-- TOC entry 3941 (class 2606 OID 236595)
-- Name: generate_packing generate_packing_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.generate_packing
    ADD CONSTRAINT generate_packing_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES masters.warehouse_master(id) NOT VALID;


--
-- TOC entry 3887 (class 2606 OID 236324)
-- Name: inspection_dtl inspection_dtl_fabric_inspection_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.inspection_dtl
    ADD CONSTRAINT inspection_dtl_fabric_inspection_id_fkey FOREIGN KEY (fabric_inspection_id) REFERENCES masters.fabric_inspection(id) NOT VALID;


--
-- TOC entry 3891 (class 2606 OID 236329)
-- Name: jobwork_fabric_receive_item jobwork_fabric_receive_item_jobwork_fabric_receive_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.jobwork_fabric_receive_item
    ADD CONSTRAINT jobwork_fabric_receive_item_jobwork_fabric_receive_id_fkey FOREIGN KEY (jobwork_fabric_receive_id) REFERENCES masters.jobwork_fabric_receive(id) NOT VALID;


--
-- TOC entry 3892 (class 2606 OID 236334)
-- Name: jobwork_fabric_receive_item jobwork_fabric_receive_item_weaving_contract_item_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.jobwork_fabric_receive_item
    ADD CONSTRAINT jobwork_fabric_receive_item_weaving_contract_item_id_fkey FOREIGN KEY (weaving_contract_item_id) REFERENCES masters.weaving_contract_item(id) NOT VALID;


--
-- TOC entry 3889 (class 2606 OID 236339)
-- Name: jobwork_fabric_receive jobwork_fabric_receive_vendor_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.jobwork_fabric_receive
    ADD CONSTRAINT jobwork_fabric_receive_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES masters.vendor(id) NOT VALID;


--
-- TOC entry 3890 (class 2606 OID 236344)
-- Name: jobwork_fabric_receive jobwork_fabric_receive_weaving_contract_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.jobwork_fabric_receive
    ADD CONSTRAINT jobwork_fabric_receive_weaving_contract_id_fkey FOREIGN KEY (weaving_contract_id) REFERENCES masters.weaving_contract(id) NOT VALID;


--
-- TOC entry 3893 (class 2606 OID 236349)
-- Name: lot_entry lot_entry_inward_item_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.lot_entry
    ADD CONSTRAINT lot_entry_inward_item_id_fkey FOREIGN KEY (inward_item_id) REFERENCES masters.purchase_inward_item(id) NOT VALID;


--
-- TOC entry 3894 (class 2606 OID 236354)
-- Name: piece_entry piece_entry_jobwork_fabric_receive_item_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.piece_entry
    ADD CONSTRAINT piece_entry_jobwork_fabric_receive_item_id_fkey FOREIGN KEY (jobwork_fabric_receive_item_id) REFERENCES masters.jobwork_fabric_receive_item(id) NOT VALID;


--
-- TOC entry 3895 (class 2606 OID 236359)
-- Name: product_category product_category_po_type_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.product_category
    ADD CONSTRAINT product_category_po_type_id_fkey FOREIGN KEY (po_type_id) REFERENCES masters.po_type_master(id) NOT VALID;


--
-- TOC entry 3897 (class 2606 OID 236364)
-- Name: purchase_inward_item purchase_inward_item_inward_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_inward_item
    ADD CONSTRAINT purchase_inward_item_inward_id_fkey FOREIGN KEY (inward_id) REFERENCES masters.purchase_inward(id) NOT VALID;


--
-- TOC entry 3898 (class 2606 OID 236369)
-- Name: purchase_inward_item purchase_inward_item_po_item_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_inward_item
    ADD CONSTRAINT purchase_inward_item_po_item_id_fkey FOREIGN KEY (po_item_id) REFERENCES masters.purchase_order_item(id) NOT VALID;


--
-- TOC entry 3896 (class 2606 OID 236374)
-- Name: purchase_inward purchase_inward_po_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_inward
    ADD CONSTRAINT purchase_inward_po_id_fkey FOREIGN KEY (po_id) REFERENCES masters.purchase_orders(id) NOT VALID;


--
-- TOC entry 3902 (class 2606 OID 236379)
-- Name: purchase_order_item purchase_order_item_po_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_order_item
    ADD CONSTRAINT purchase_order_item_po_id_fkey FOREIGN KEY (po_id) REFERENCES masters.purchase_orders(id) NOT VALID;


--
-- TOC entry 3903 (class 2606 OID 236384)
-- Name: purchase_order_item purchase_order_item_product_category_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_order_item
    ADD CONSTRAINT purchase_order_item_product_category_id_fkey FOREIGN KEY (product_category_id) REFERENCES masters.product_category(id) NOT VALID;


--
-- TOC entry 3899 (class 2606 OID 236389)
-- Name: purchase_orders purchase_order_po_type_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_orders
    ADD CONSTRAINT purchase_order_po_type_id_fkey FOREIGN KEY (po_type_id) REFERENCES masters.po_type_master(id) NOT VALID;


--
-- TOC entry 3900 (class 2606 OID 236394)
-- Name: purchase_orders purchase_order_tax_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_orders
    ADD CONSTRAINT purchase_order_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES masters.tax_type(id) NOT VALID;


--
-- TOC entry 3901 (class 2606 OID 236399)
-- Name: purchase_orders purchase_order_vendor_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.purchase_orders
    ADD CONSTRAINT purchase_order_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES masters.vendor(id) NOT VALID;


--
-- TOC entry 3904 (class 2606 OID 236404)
-- Name: sales_order sales_order_buyer_customer_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order
    ADD CONSTRAINT sales_order_buyer_customer_id_fkey FOREIGN KEY (buyer_customer_id) REFERENCES masters.customer(id) NOT VALID;


--
-- TOC entry 3905 (class 2606 OID 236409)
-- Name: sales_order sales_order_currency_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order
    ADD CONSTRAINT sales_order_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES masters.currency_master(id) NOT VALID;


--
-- TOC entry 3909 (class 2606 OID 236414)
-- Name: sales_order_item sales_order_item_fabric_type_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order_item
    ADD CONSTRAINT sales_order_item_fabric_type_id_fkey FOREIGN KEY (fabric_type_id) REFERENCES masters.fabric_type(id) NOT VALID;


--
-- TOC entry 3910 (class 2606 OID 236419)
-- Name: sales_order_item sales_order_item_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order_item
    ADD CONSTRAINT sales_order_item_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES masters.sales_order(id) NOT VALID;


--
-- TOC entry 3911 (class 2606 OID 236424)
-- Name: sales_order_item sales_order_item_uom_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order_item
    ADD CONSTRAINT sales_order_item_uom_id_fkey FOREIGN KEY (uom_id) REFERENCES masters.uom(id) NOT VALID;


--
-- TOC entry 3906 (class 2606 OID 236429)
-- Name: sales_order sales_order_mode_of_shipment_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order
    ADD CONSTRAINT sales_order_mode_of_shipment_id_fkey FOREIGN KEY (mode_of_shipment_id) REFERENCES masters.shipment_mode(id) NOT VALID;


--
-- TOC entry 3907 (class 2606 OID 236434)
-- Name: sales_order sales_order_shipment_terms_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order
    ADD CONSTRAINT sales_order_shipment_terms_id_fkey FOREIGN KEY (shipment_terms_id) REFERENCES masters.shipment_terms(id) NOT VALID;


--
-- TOC entry 3908 (class 2606 OID 236439)
-- Name: sales_order sales_order_terms_conditions_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sales_order
    ADD CONSTRAINT sales_order_terms_conditions_id_fkey FOREIGN KEY (terms_conditions_id) REFERENCES masters.terms_conditions(id) NOT VALID;


--
-- TOC entry 3912 (class 2606 OID 236444)
-- Name: sizing_beam_details sizing_beam_details_empty_beam_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_beam_details
    ADD CONSTRAINT sizing_beam_details_empty_beam_id_fkey FOREIGN KEY (empty_beam_id) REFERENCES masters.empty_beam_issue(id) NOT VALID;


--
-- TOC entry 3913 (class 2606 OID 236449)
-- Name: sizing_beam_details sizing_beam_details_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_beam_details
    ADD CONSTRAINT sizing_beam_details_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES masters.sales_order(id) NOT VALID;


--
-- TOC entry 3914 (class 2606 OID 236454)
-- Name: sizing_beam_details sizing_beam_details_sizing_plan_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_beam_details
    ADD CONSTRAINT sizing_beam_details_sizing_plan_id_fkey FOREIGN KEY (sizing_plan_id) REFERENCES masters.sizing_plan(id) NOT VALID;


--
-- TOC entry 3915 (class 2606 OID 236459)
-- Name: sizing_beam_details sizing_beam_details_weaving_contract_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_beam_details
    ADD CONSTRAINT sizing_beam_details_weaving_contract_id_fkey FOREIGN KEY (weaving_contract_id) REFERENCES masters.weaving_contract(id) NOT VALID;


--
-- TOC entry 3918 (class 2606 OID 236464)
-- Name: sizing_plan sizing_plan_payment_terms_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_plan
    ADD CONSTRAINT sizing_plan_payment_terms_id_fkey FOREIGN KEY (payment_terms_id) REFERENCES masters.payment_terms(id) NOT VALID;


--
-- TOC entry 3919 (class 2606 OID 236469)
-- Name: sizing_plan sizing_plan_terms_conditions_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_plan
    ADD CONSTRAINT sizing_plan_terms_conditions_id_fkey FOREIGN KEY (terms_conditions_id) REFERENCES masters.terms_conditions(id) NOT VALID;


--
-- TOC entry 3920 (class 2606 OID 236474)
-- Name: sizing_quality_details sizing_quality_details_sizing_plan_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_quality_details
    ADD CONSTRAINT sizing_quality_details_sizing_plan_id_fkey FOREIGN KEY (sizing_plan_id) REFERENCES masters.sizing_plan(id);


--
-- TOC entry 3921 (class 2606 OID 236479)
-- Name: sizing_quality_details sizing_quality_details_yarn_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_quality_details
    ADD CONSTRAINT sizing_quality_details_yarn_id_fkey FOREIGN KEY (yarn_id) REFERENCES masters.yarn_master(id);


--
-- TOC entry 3948 (class 2606 OID 238643)
-- Name: sizing_yarn_issue sizing_yarn_issue_lot_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue
    ADD CONSTRAINT sizing_yarn_issue_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES masters.lot_entry(id) NOT VALID;


--
-- TOC entry 3945 (class 2606 OID 238606)
-- Name: sizing_yarn_issue_entry sizing_yarn_issue_sizing_paln_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue_entry
    ADD CONSTRAINT sizing_yarn_issue_sizing_paln_id_fkey FOREIGN KEY (sizing_plan_id) REFERENCES masters.sizing_plan(id);


--
-- TOC entry 3949 (class 2606 OID 238638)
-- Name: sizing_yarn_issue sizing_yarn_issue_sizing_yarn_issue_entry_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue
    ADD CONSTRAINT sizing_yarn_issue_sizing_yarn_issue_entry_id_fkey FOREIGN KEY (sizing_yarn_issue_entry_id) REFERENCES masters.sizing_yarn_issue_entry(id) NOT VALID;


--
-- TOC entry 3946 (class 2606 OID 238596)
-- Name: sizing_yarn_issue_entry sizing_yarn_issue_terms_conditions_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue_entry
    ADD CONSTRAINT sizing_yarn_issue_terms_conditions_id_fkey FOREIGN KEY (terms_conditions_id) REFERENCES masters.terms_conditions(id);


--
-- TOC entry 3947 (class 2606 OID 238601)
-- Name: sizing_yarn_issue_entry sizing_yarn_issue_vendor_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_issue_entry
    ADD CONSTRAINT sizing_yarn_issue_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES masters.vendor(id);


--
-- TOC entry 3950 (class 2606 OID 238673)
-- Name: sizing_yarn_requirement sizing_yarn_requirement_sizing_yarn_issue_entry_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.sizing_yarn_requirement
    ADD CONSTRAINT sizing_yarn_requirement_sizing_yarn_issue_entry_id_fkey FOREIGN KEY (sizing_yarn_issue_entry_id) REFERENCES masters.sizing_yarn_issue_entry(id);


--
-- TOC entry 3922 (class 2606 OID 236484)
-- Name: state state_country_sno_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.state
    ADD CONSTRAINT state_country_sno_fkey FOREIGN KEY (country_sno) REFERENCES masters.country(id) NOT VALID;


--
-- TOC entry 3924 (class 2606 OID 236489)
-- Name: vendor vendor_address_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.vendor
    ADD CONSTRAINT vendor_address_id_fkey FOREIGN KEY (address_id) REFERENCES masters.address(id);


--
-- TOC entry 3929 (class 2606 OID 236494)
-- Name: weaving_contract_item weaving_contract_item_fabric_code_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract_item
    ADD CONSTRAINT weaving_contract_item_fabric_code_id_fkey FOREIGN KEY (fabric_code_id) REFERENCES masters.woven_fabric_master(id) NOT VALID;


--
-- TOC entry 3930 (class 2606 OID 236499)
-- Name: weaving_contract_item weaving_contract_item_fabric_quality_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract_item
    ADD CONSTRAINT weaving_contract_item_fabric_quality_id_fkey FOREIGN KEY (fabric_quality_id) REFERENCES masters.woven_fabric_master(id) NOT VALID;


--
-- TOC entry 3931 (class 2606 OID 236504)
-- Name: weaving_contract_item weaving_contract_item_weaving_contract_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract_item
    ADD CONSTRAINT weaving_contract_item_weaving_contract_id_fkey FOREIGN KEY (weaving_contract_id) REFERENCES masters.weaving_contract(id) NOT VALID;


--
-- TOC entry 3925 (class 2606 OID 236509)
-- Name: weaving_contract weaving_contract_payment_terms_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract
    ADD CONSTRAINT weaving_contract_payment_terms_id_fkey FOREIGN KEY (payment_terms_id) REFERENCES masters.payment_terms(id) NOT VALID;


--
-- TOC entry 3926 (class 2606 OID 236514)
-- Name: weaving_contract weaving_contract_sales_order_no_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract
    ADD CONSTRAINT weaving_contract_sales_order_no_fkey FOREIGN KEY (sales_order_no) REFERENCES masters.sales_order(id) NOT VALID;


--
-- TOC entry 3927 (class 2606 OID 236519)
-- Name: weaving_contract weaving_contract_terms_conditions_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract
    ADD CONSTRAINT weaving_contract_terms_conditions_id_fkey FOREIGN KEY (terms_conditions_id) REFERENCES masters.terms_conditions(id) NOT VALID;


--
-- TOC entry 3928 (class 2606 OID 236524)
-- Name: weaving_contract weaving_contract_vendor_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_contract
    ADD CONSTRAINT weaving_contract_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES masters.vendor(id) NOT VALID;


--
-- TOC entry 3932 (class 2606 OID 236529)
-- Name: weaving_yarn_issue weaving_yarn_issue_terms_conditions_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_yarn_issue
    ADD CONSTRAINT weaving_yarn_issue_terms_conditions_id_fkey FOREIGN KEY (terms_conditions_id) REFERENCES masters.terms_conditions(id) NOT VALID;


--
-- TOC entry 3933 (class 2606 OID 236534)
-- Name: weaving_yarn_issue weaving_yarn_issue_vendor_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_yarn_issue
    ADD CONSTRAINT weaving_yarn_issue_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES masters.vendor(id) NOT VALID;


--
-- TOC entry 3934 (class 2606 OID 236539)
-- Name: weaving_yarn_issue weaving_yarn_issue_weaving_contract_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.weaving_yarn_issue
    ADD CONSTRAINT weaving_yarn_issue_weaving_contract_id_fkey FOREIGN KEY (weaving_contract_id) REFERENCES masters.weaving_contract(id) NOT VALID;


--
-- TOC entry 3937 (class 2606 OID 236544)
-- Name: yarn_master yarn_master_count_sno_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_master
    ADD CONSTRAINT yarn_master_count_sno_fkey FOREIGN KEY (count_sno) REFERENCES masters.sub_category(id) NOT VALID;


--
-- TOC entry 3938 (class 2606 OID 236549)
-- Name: yarn_requirement yarn_requirement_weaving_contract_id_fkey; Type: FK CONSTRAINT; Schema: masters; Owner: textipro_admin
--

ALTER TABLE ONLY masters.yarn_requirement
    ADD CONSTRAINT yarn_requirement_weaving_contract_id_fkey FOREIGN KEY (weaving_contract_id) REFERENCES masters.weaving_contract(id) NOT VALID;


-- Completed on 2025-08-28 16:59:25 IST

--
-- PostgreSQL database dump complete
--

