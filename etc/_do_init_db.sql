\set ON_ERROR_STOP on
\getenv grocery_user_password GROCERY_USER_PASSWORD

\connect postgres

-- Delete databse completely
DROP DATABASE IF EXISTS grocerymate_db;

-- Delete, if role grocery_user already exists
SELECT CASE
         WHEN EXISTS (
           SELECT 1 FROM pg_roles WHERE rolname = 'grocery_user'
         )
         THEN 'true'
         ELSE 'false'
       END AS role_exists
\gset

\if :role_exists
REASSIGN OWNED BY grocery_user TO postgres;
DROP OWNED BY grocery_user;
\endif

-- Move stuff belonging to grocery_user to postgres
\if :{?role_exists}
REASSIGN OWNED BY grocery_user TO postgres;
DROP OWNED BY grocery_user;
\endif

-- Now grocery_user can be dropped
DROP ROLE IF EXISTS grocery_user;

-- Initialize database from anew
CREATE ROLE grocery_user LOGIN
  PASSWORD :'grocery_user_password';

CREATE DATABASE grocerymate_db;

\connect grocerymate_db

GRANT USAGE, CREATE ON SCHEMA public TO grocery_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO grocery_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO grocery_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO grocery_user;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON TABLES TO grocery_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON SEQUENCES TO grocery_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON FUNCTIONS TO grocery_user;

\dn+ public
\ddp

