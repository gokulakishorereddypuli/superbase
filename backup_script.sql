-- Schema (optional)
CREATE SCHEMA IF NOT EXISTS "intext";

-- 1) intext.employee
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

-- 2) intext.employee_stg
CREATE TABLE IF NOT EXISTS "intext"."employee_stg" (
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

-- 3) intext.part_config
CREATE TABLE IF NOT EXISTS "intext"."part_config" (
  "parent_table" text NOT NULL,
  "control" text NULL,
  "time_encoder" text NULL,
  "time_decoder" text NULL,
  "partition_interval" text NULL,
  "partition_type" text NULL,
  "premake" integer NOT NULL DEFAULT 4,
  "automatic_maintenance" text NULL DEFAULT 'on'::text,
  "template_table" text NULL,
  "retention" text NULL,
  "retention_schema" text NULL,
  "retention_keep_index" boolean NULL DEFAULT true,
  "retention_keep_table" boolean NULL DEFAULT true,
  "epoch" text NULL DEFAULT 'none'::text,
  "constraint_cols" text[] NULL,
  "optimize_constraint" integer NULL DEFAULT 30,
  "infinite_time_partitions" boolean NULL DEFAULT false,
  "datetime_string" text NULL,
  "jobmon" boolean NULL DEFAULT true,
  "sub_partition_set_full" boolean NULL DEFAULT false,
  "undo_in_progress" boolean NULL DEFAULT false,
  "inherit_privileges" boolean NULL DEFAULT false,
  "constraint_valid" boolean NULL DEFAULT true,
  "ignore_default_data" boolean NULL DEFAULT true,
  "date_trunc_interval" text NULL,
  "maintenance_order" integer NULL,
  "retention_keep_publication" boolean NULL DEFAULT false,
  "maintenance_last_run" timestamp with time zone NULL,
  "async_partitioning_in_progress" text NULL,
  CONSTRAINT "part_config_pkey" PRIMARY KEY ("parent_table"),
  CONSTRAINT "part_config_partition_type_check"
    CHECK ("partition_type" IS NULL OR intext.check_partition_type("partition_type")),
  CONSTRAINT "part_config_premake_check" CHECK ("premake" > 0),
  CONSTRAINT "part_config_automatic_maintenance_check"
    CHECK (intext.check_automatic_maintenance_value("automatic_maintenance")),
  CONSTRAINT "part_config_retention_schema_check"
    CHECK ("retention_schema" IS NULL OR "retention_schema" <> ''::text),
  CONSTRAINT "part_config_epoch_check"
    CHECK (intext.check_epoch_type("epoch")),
  CONSTRAINT "part_config_ignore_default_data_check" CHECK (true)
);

-- 4) intext.part_config_sub
CREATE TABLE IF NOT EXISTS "intext"."part_config_sub" (
  "sub_parent" text NOT NULL,
  "sub_control" text NULL,
  "sub_time_encoder" text NULL,
  "sub_time_decoder" text NULL,
  "sub_partition_interval" text NULL,
  "sub_partition_type" text NULL,
  "sub_premake" integer NOT NULL DEFAULT 4,
  "sub_automatic_maintenance" text NULL DEFAULT 'on'::text,
  "sub_template_table" text NULL,
  "sub_retention" text NULL,
  "sub_retention_schema" text NULL,
  "sub_retention_keep_index" boolean NULL DEFAULT true,
  "sub_retention_keep_table" boolean NULL DEFAULT true,
  "sub_epoch" text NULL DEFAULT 'none'::text,
  "sub_constraint_cols" text[] NULL,
  "sub_optimize_constraint" integer NULL DEFAULT 30,
  "sub_infinite_time_partitions" boolean NULL DEFAULT false,
  "sub_jobmon" boolean NULL DEFAULT true,
  "sub_inherit_privileges" boolean NULL DEFAULT false,
  "sub_constraint_valid" boolean NULL DEFAULT true,
  "sub_ignore_default_data" boolean NULL DEFAULT true,
  "sub_default_table" boolean NULL DEFAULT true,
  "sub_date_trunc_interval" text NULL,
  "sub_maintenance_order" integer NULL,
  "sub_retention_keep_publication" boolean NULL DEFAULT false,
  "sub_control_not_null" boolean NULL DEFAULT true,
  CONSTRAINT "part_config_sub_pkey" PRIMARY KEY ("sub_parent"),
  CONSTRAINT "part_config_sub_sub_partition_type_check"
    CHECK ("sub_partition_type" IS NULL OR intext.check_partition_type("sub_partition_type")),
  CONSTRAINT "part_config_sub_sub_premake_check" CHECK ("sub_premake" > 0),
  CONSTRAINT "part_config_sub_sub_automatic_maintenance_check"
    CHECK (intext.check_automatic_maintenance_value("sub_automatic_maintenance")),
  CONSTRAINT "part_config_sub_sub_retention_schema_check"
    CHECK ("sub_retention_schema" IS NULL OR "sub_retention_schema" <> ''::text),
  CONSTRAINT "part_config_sub_sub_epoch_check"
    CHECK (intext.check_epoch_type("sub_epoch"))
);

-- FK for sub -> parent
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'part_config_sub_sub_parent_fkey'
  ) THEN
    ALTER TABLE "intext"."part_config_sub"
      ADD CONSTRAINT "part_config_sub_sub_parent_fkey"
      FOREIGN KEY ("sub_parent")
      REFERENCES "intext"."part_config" ("parent_table");
  END IF;
END $$;

-- 5) intext.integration_logs
CREATE TABLE IF NOT EXISTS "intext"."integration_logs" (
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

-- 6) intext.integration_common_logs
CREATE TABLE IF NOT EXISTS "intext"."integration_common_logs" (
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
  CONSTRAINT "integration_common_logs_pkey" PRIMARY KEY ("log_id")
);

-- Optional: comments (only intext.integration_common_logs has a comment)
-- COMMENT ON TABLE "intext"."integration_common_logs" IS 'Common Logs Table';
