INSERT INTO intext.integration_logs (
  rice_id,
  integration_name,
  integration_identifier,
  integration_version,
  instance_id,
  invoked_by,
  service_instance_name,
  oic_base_url,
  integration_status
) VALUES (
  #rice_id,
  #integration_name,
  #integration_identifier,
  #integration_version,
  #instance_id,
  #invoked_by,
  #service_instance_name,
  #oic_base_url,
  #integration_status
);


-----------------------------------------


CREATE TABLE IF NOT EXISTS intext.integration_logs (
    log_id SERIAL PRIMARY KEY,
    rice_id TEXT NOT NULL,
    integration_name TEXT NOT NULL,
    integration_identifier TEXT NOT NULL,
    integration_version TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    invoked_by TEXT NOT NULL,
    service_instance_name TEXT NOT NULL,
    oic_base_url TEXT NOT NULL,
    integration_status TEXT NOT NULL,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE intext.integration_logs;

select * from intext.integration_logs order by log_id desc;

truncate TABLE intext.integration_logs;


----------------------------------------------------

GRANT USAGE ON SCHEMA intext TO anon;
GRANT SELECT ON intext.employee_stg to anon;


GRANT USAGE ON SCHEMA intext TO authenticated;
GRANT SELECT ON intext.employee to authenticated;


GRANT USAGE ON SCHEMA intext TO public;
GRANT SELECT ON intext.employee to public;


----------------------------------------------------------

CREATE TABLE intext.employee_stg (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hire_date DATE DEFAULT CURRENT_DATE,
    job_title VARCHAR(50),
    salary NUMERIC(10, 2) CHECK (salary > 0),
    is_active BOOLEAN DEFAULT TRUE,
    staged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Track when it was staged
);


drop table intext.employee_stg;
rollback;
drop from intext.employee_stg;
select * from intext.employee_stg;
CREATE TABLE intext.employee_stg (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    hire_date DATE DEFAULT CURRENT_DATE,
    job_title VARCHAR(50),
    salary NUMERIC(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    staged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Track when it was staged
);


-- Create the type inside our "package" schema
CREATE TYPE intext.employee_input_t AS (
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    job_title VARCHAR(50),
    salary NUMERIC(10, 2)
);

CREATE OR REPLACE PROCEDURE intext.stage_employees_batch(
    IN p_employees intext.employee_input_t[],
    INOUT p_response_message TEXT DEFAULT ''
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inserted_count INT;
BEGIN
    -- Check if the input array is null or empty
    IF p_employees IS NULL OR array_length(p_employees, 1) IS NULL THEN
        p_response_message := 'FAILED: The input employee collection is empty.';
        RETURN;
    END IF;

    -- Unpack the array and bulk insert all records in one step
    INSERT INTO employee_stg (first_name, last_name, email, job_title, salary)
    SELECT 
        (emp).first_name, 
        (emp).last_name, 
        (emp).email, 
        (emp).job_title, 
        (emp).salary
    FROM unnest(p_employees) AS emp;

    -- Get the number of successfully inserted rows
    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

    p_response_message := 'SUCCESS: Successfully staged ' || v_inserted_count || ' employee records.';

EXCEPTION 
    WHEN unique_violation THEN
        p_response_message := 'FAILED: Transaction rolled back. One or more records violated the unique email constraint.';
    WHEN OTHERS THEN
        p_response_message := 'FAILED: An unexpected error occurred: ' || SQLERRM;
END;
$$;



DO $$
DECLARE
    v_batch intext.employee_input_t[];
    v_response TEXT;
BEGIN
    -- 1. Construct the collection of employee records
    v_batch := ARRAY[
        ROW('Alice', 'Johnson', 'alice.j@example.com', 'Cloud Architect', 115000.00)::intext.employee_input_t,
        ROW('Bob', 'Smith', 'bob.smith@example.com', 'DevOps Engineer', 98000.00)::intext.employee_input_t,
        ROW('Charlie', 'Brown', 'charlie.b@example.com', 'QA Lead', 85000.00)::intext.employee_input_t
    ];

    -- 2. Call the batch procedure
    CALL intext.stage_employees_batch(v_batch, v_response);
    
    -- 3. Print the execution response
    RAISE NOTICE '%', v_response;
END;
$$;


SELECT * FROM intext.employee_stg;


------------------------------------------------------------------------


DROP SCHEMA IF EXISTS hcm_integrations CASCADE;
CREATE SCHEMA hcm_integrations;
------------------------------------------------


CREATE OR REPLACE PROCEDURE intext.insert_integration_logs(
  p_rice_id                  text,
  p_integration_name        text,
  p_integration_identifier  text,
  p_integration_version     text,
  p_instance_id             text,
  p_invoked_by              text,
  p_service_instance_name   text,
  p_oic_base_url           text,
  p_integration_status     text
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO intext.integration_logs (
    rice_id,
    integration_name,
    integration_identifier,
    integration_version,
    instance_id,
    invoked_by,
    service_instance_name,
    oic_base_url,
    integration_status
  )
  VALUES (
    p_rice_id,
    p_integration_name,
    p_integration_identifier,
    p_integration_version,
    p_instance_id,
    p_invoked_by,
    p_service_instance_name,
    p_oic_base_url,
    p_integration_status
  );
END;
$$;



------------------------------------------------------

insert into intext.employee_stg select * from intext.employee;


select * from intext.employee;

commit;





----------------------------------------
SELECT *
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid()
    AND usename NOT IN ('supabase_admin', 'postgres', 'supabase_auth_admin', 'supabase_storage_admin', 'supabase_replication_admin');

SELECT *
FROM pg_stat_activity sa
JOIN pg_roles r ON sa.usename = r.rolname
WHERE sa.datname = current_database()
  AND sa.pid <> pg_backend_pid()
    AND r.rolsuper = false;







    -----------------------------

-- Create a table for public profiles
create table profiles (
  id uuid references auth.users on delete cascade not null primary key,
  updated_at timestamp with time zone,
  username text unique,
  full_name text,
  avatar_url text,
  website text,

  constraint username_length check (char_length(username) >= 3)
);
-- Set up Row Level Security (RLS)
-- See https://supabase.com/docs/guides/auth/row-level-security for more details.
alter table profiles
  enable row level security;

create policy "Public profiles are viewable by everyone." on profiles
  for select using (true);

create policy "Users can insert their own profile." on profiles
  for insert with check ((select auth.uid()) = id);

create policy "Users can update own profile." on profiles
  for update using ((select auth.uid()) = id);

-- This trigger automatically creates a profile entry when a new user signs up via Supabase Auth.
-- See https://supabase.com/docs/guides/auth/managing-user-data#using-triggers for more details.
create function public.handle_new_user()
returns trigger
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$ language plpgsql security definer;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Set up Storage!
insert into storage.buckets (id, name)
  values ('avatars', 'avatars');

-- Set up access controls for storage. Allows downloading object with public key
-- See https://supabase.com/docs/guides/storage/security/access-control#policy-examples for more details.
create policy "Avatar images are publicly accessible." on storage.objects
  for select using (bucket_id = 'avatars' and storage.allow_any_operation(array['object.get_authenticated_info', 'object.get_authenticated']));

create policy "Anyone can upload an avatar." on storage.objects
  for insert with check (bucket_id = 'avatars');







---------------------------------------------------------------


create schema hdlapp;

CREATE TABLE hdlapp.element_entry_with_costing_stg (
    metadata             VARCHAR(20),
    object_name          VARCHAR(100),
    effective_end_date   DATE,
    effective_start_date DATE,
    element_name         VARCHAR(200),
    assignment_number    VARCHAR(50),
    entry_type           CHAR(1),
    create_entry_sequence INTEGER,
    source_system_owner  VARCHAR(100),
    source_system_id     VARCHAR(100),
    input_value_name1    VARCHAR(100),
    screen_entry_value1  NUMERIC(12,2),
    segment4             VARCHAR(100)
);


INSERT INTO hdlapp.element_entry_with_costing_stg
(
    metadata,
    object_name,
    effective_end_date,
    effective_start_date,
    element_name,
    assignment_number,
    entry_type,
    create_entry_sequence,
    source_system_owner,
    source_system_id,
    input_value_name1,
    screen_entry_value1,
    segment4
)
VALUES
(
    'MERGE',
    'ElementEntryWithCosting',
    '2026-04-11',
    '2026-04-11',
    'Union Dues Amount',
    'E77',
    'E',
    1,
    NULL,
    NULL,
    'Amount',
    2500,
    NULL
),
(
    'MERGE',
    'ElementEntryWithCosting',
    '2026-04-11',
    '2026-04-11',
    'Tipped Worker Hours',
    'E78',
    'E',
    2,
    NULL,
    NULL,
    'Hours',
    12,
    NULL
);




------------------------------------------------------------------


-- 1. Grant usage on the package schema so the user can look inside it
GRANT USAGE ON SCHEMA intext TO "postgres";

-- 2. Grant permission to execute the batch procedure and use the custom type
GRANT EXECUTE ON PROCEDURE intext.stage_employees_batch(intext.employee_input_t[], text) TO "postgres";
GRANT USAGE ON TYPE intext.employee_input_t TO "postgres";

-- 3. Grant table permissions (Data Modification Liquidity)
-- Staging table requires INSERT, and potentially SELECT/UPDATE depending on application workflows
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE intext.employee_stg TO "postgres";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE intext.employee TO "postgres";

-- 4. Grant permission on auto-incrementing sequences (Required for SERIAL/identity columns)
GRANT USAGE, SELECT ON SEQUENCE intext.employee_stg_employee_id_seq TO "postgres";
GRANT USAGE, SELECT ON SEQUENCE intext.employee_employee_id_seq TO "postgres";



-------------------------------------------------------------------------

delete from intext.employee_stg;
delete from intext.employee_stg;

INSERT INTO intext.employee (first_name, last_name, email, hire_date, job_title, salary, is_active) VALUES
('David', 'Miller', 'david.miller@example.com', '2022-03-14', 'DevOps Engineer', 98000.00, TRUE),
('Sophia', 'Wilson', 'sophia.wilson@example.com', '2023-08-19', 'Product Manager', 110000.00, TRUE),
('James', 'Taylor', 'james.taylor@example.com', '2020-11-05', 'Senior Developer', 125000.00, TRUE),
('Olivia', 'Martinez', 'olivia.martinez@example.com', '2024-01-10', 'Data Scientist', 105000.00, TRUE),
('Robert', 'Anderson', 'robert.anderson@example.com', '2019-04-23', 'IT Director', 145000.00, TRUE),
('Isabella', 'Thomas', 'isabella.thomas@example.com', '2023-05-17', 'HR Specialist', 68000.00, TRUE),
('William', 'Jackson', 'william.jackson@example.com', '2021-09-01', 'Systems Administrator', 82000.00, TRUE),
('Mia', 'White', 'mia.white@example.com', '2025-02-14', 'Junior Frontend Developer', 60000.00, TRUE),
('Lucas', 'Harris', 'lucas.harris@example.com', '2022-07-30', 'Security Engineer', 112000.00, TRUE),
('Emma', 'Martin', 'emma.martin@example.com', '2023-12-01', 'Marketing Coordinator', 64000.00, FALSE);

commit;

------------------------------------------------------------------------------------

-- 1. Grant usage on the package schema so the user can look inside it
GRANT USAGE ON SCHEMA intext TO "postgres.lpqtnszwqyawpxoueamy";

-- 2. Grant permission to execute the batch procedure and use the custom type
GRANT EXECUTE ON PROCEDURE intext.stage_employees_batch(intext.employee_input_t[], text) TO "postgres.lpqtnszwqyawpxoueamy";
GRANT USAGE ON TYPE intext.employee_input_t TO "postgres.lpqtnszwqyawpxoueamy";

-- 3. Grant table permissions (Data Modification Liquidity)
-- Staging table requires INSERT, and potentially SELECT/UPDATE depending on application workflows
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE employee_stg TO "postgres.lpqtnszwqyawpxoueamy";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE employee TO "postgres.lpqtnszwqyawpxoueamy";

-- 4. Grant permission on auto-incrementing sequences (Required for SERIAL/identity columns)
GRANT USAGE, SELECT ON SEQUENCE employee_stg_employee_id_seq TO "postgres.lpqtnszwqyawpxoueamy";
GRANT USAGE, SELECT ON SEQUENCE employee_employee_id_seq TO "postgres.lpqtnszwqyawpxoueamy";




