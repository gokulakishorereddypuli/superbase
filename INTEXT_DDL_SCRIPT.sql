-- Ensure the schema exists (optional but safe)
CREATE SCHEMA IF NOT EXISTS intext;

-- Create the sequence the default uses (if it doesn't already exist)
CREATE SEQUENCE IF NOT EXISTS intext.employee_employee_id_seq
  AS integer
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

-- Create the table (matches your CREATE TABLE ...)
CREATE TABLE IF NOT EXISTS intext.employee (
  "employee_id" integer NOT NULL DEFAULT nextval('intext.employee_employee_id_seq'::regclass),
  "first_name" character varying NULL,
  "last_name" character varying NULL,
  "email" character varying NULL,
  "hire_date" date NULL DEFAULT CURRENT_DATE,
  "job_title" character varying NULL,
  "salary" numeric NULL,
  "is_active" boolean NULL DEFAULT true,
  "staged_at" timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "employee_pkey" PRIMARY KEY ("employee_id")
);

-- Tie the sequence to the table column (harmless if already set)
ALTER SEQUENCE intext.employee_employee_id_seq
  OWNED BY intext.employee."employee_id";


----------------------------------------------------------------------------------------------

-- Ensure the schema exists (optional but safe)
CREATE SCHEMA IF NOT EXISTS intext;

-- Create the sequence the default uses (if it doesn't already exist)
CREATE SEQUENCE IF NOT EXISTS intext.employee_stg_employee_id_seq
  AS integer
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

-- Create the staging table
CREATE TABLE IF NOT EXISTS intext.employee_stg (
  "employee_id" integer NOT NULL DEFAULT nextval('intext.employee_stg_employee_id_seq'::regclass),
  "first_name" character varying NULL,
  "last_name" character varying NULL,
  "email" character varying NULL,
  "hire_date" date NULL DEFAULT CURRENT_DATE,
  "job_title" character varying NULL,
  "salary" numeric NULL,
  "is_active" boolean NULL DEFAULT true,
  "staged_at" timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "employee_stg_pkey" PRIMARY KEY ("employee_id")
);

-- Tie the sequence to the table column (harmless if already set)
ALTER SEQUENCE intext.employee_stg_employee_id_seq
  OWNED BY intext.employee_stg."employee_id";


----------------------------------------------------------------------------------------------

-- Ensure the schema exists (optional but safe)
CREATE SCHEMA IF NOT EXISTS intext;

-- Create the sequence the default uses (if it doesn't already exist)
CREATE SEQUENCE IF NOT EXISTS intext.integration_logs_log_id_seq
  AS integer
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

-- Create the table
CREATE TABLE IF NOT EXISTS intext.integration_logs (
  "log_id" integer NOT NULL DEFAULT nextval('intext.integration_logs_log_id_seq'::regclass),
  "rice_id" text NULL,
  "integration_name" text NULL,
  "integration_identifier" text NULL,
  "integration_version" text NULL,
  "instance_id" text NULL,
  "invoked_by" text NULL,
  "service_instance_name" text NULL,
  "oic_base_url" text NULL,
  "integration_status" text NULL,
  "log_timestamp" timestamp without time zone NULL DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::text) + '05:30:00'::interval),
  "db_user" text NULL DEFAULT CURRENT_USER,
  "login_role" text NULL DEFAULT SESSION_USER,
  "database_name" text NULL DEFAULT current_database(),
  "client_ip" inet NULL DEFAULT inet_client_addr(),
  "client_port" integer NULL DEFAULT inet_client_port(),
  "server_ip" inet NULL DEFAULT inet_server_addr(),
  "server_port" integer NULL DEFAULT inet_server_port(),
  "backend_pid" integer NULL DEFAULT pg_backend_pid(),
  "application_name" text NULL DEFAULT current_setting('application_name'::text),
  CONSTRAINT "integration_logs_pkey" PRIMARY KEY ("log_id")
);

-- Tie the sequence to the table column (harmless if already set)
ALTER SEQUENCE intext.integration_logs_log_id_seq
  OWNED BY intext.integration_logs."log_id";
