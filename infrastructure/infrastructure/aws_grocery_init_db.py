import json
import os
import time
import psycopg2


def get_db_config():
    # Liest das von RDS generierte Secret aus der Umgebungsvariable
    db_secret_raw = os.environ.get("DB_SECRET")
    if db_secret_raw:
        secret = json.loads(db_secret_raw)
        return {
            "host": secret["host"],
            "port": secret.get("port", 5432),  # TODO make variable
            "dbname": secret.get("dbname", "grocerymate_db"),  # TODO make variable
            "user": secret["username"],
            "password": secret["password"],
        }
    raise RuntimeError("DB_SECRET environment variable is missing!")


def init_database():
    cfg = get_db_config()

    # Warten, bis RDS wirklich Verbindungen annimmt (Retry-Schleife)
    conn = None
    for attempt in range(10):
        try:
            conn = psycopg2.connect(**cfg)
            break
        except psycopg2.OperationalError as e:
            print(f"Waiting for database (attempt {attempt + 1}/10)... {e}")
            time.sleep(3)

    if not conn:
        raise RuntimeError("Could not connect to RDS database.")

    conn.autocommit = True
    cur = conn.cursor()

    # Prüfen, ob 'users' schon existiert (Idempotenz bei Container-Neustarts)
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'users'
        );
    """)
    already_initialized = cur.fetchone()

    if not already_initialized:
        print("Database is empty. Importing app/sqlite_dump_clean.sql...")
        sql_path = os.path.join(
            os.path.dirname(__file__), "app", "sqlite_dump_clean.sql"
        )
        with open(sql_path, "r", encoding="utf-8") as f:
            cur.execute(f.read())
        print("SQL dump imported successfully!")
    else:
        print("Database already initialized. Skipping SQL dump.")

    # Deine Kontrollabfragen (erscheinen in CloudWatch Logs)
    print("--- Verifying 'users' table ---")
    cur.execute("SELECT * FROM users;")
    for row in cur.fetchall():
        print(row)

    print("--- Verifying 'products' table ---")
    cur.execute("SELECT * FROM products;")
    for row in cur.fetchall():
        print(row)

    cur.close()
    conn.close()


if __name__ == "__main__":
    init_database()
