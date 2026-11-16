\getenv grocery_user_password GROCERY_USER_PASSWORD

DROP DATABASE IF EXISTS grocerymate_db;
DROP ROLE IF EXISTS grocery_user;

CREATE ROLE grocery_user LOGIN PASSWORD :'grocery_user_password';
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

