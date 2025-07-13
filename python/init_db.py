import os

from python.db_connection import DatabaseConnection

# Абсолютный путь к корню проекта
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SQL_FILES = ["01_tables.sql", "02_functions.sql", "03_triggers.sql"]

def execute_sql_file(conn, file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        sql = f.read()
    with conn.cursor() as cursor:
        cursor.execute(sql)
        conn.commit()
        print(f"✅ Выполнен файл: {file_path}")


def main():
    try:
        with DatabaseConnection() as conn:
            for sql_file in SQL_FILES:
                path = os.path.join(BASE_DIR, "database", sql_file)
                execute_sql_file(conn, path)
            print("✅ Все SQL-скрипты успешно выполнены.")
    except Exception as e:
        print("❌ Ошибка при инициализации БД:", e)


if __name__ == "__main__":
    main()