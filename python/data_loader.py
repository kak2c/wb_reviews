import os
import csv
from psycopg2.extras import execute_batch
from dotenv import load_dotenv
from tqdm import tqdm

from python.db_connection import DatabaseConnection

# Загружаем переменные окружения
load_dotenv(dotenv_path=os.path.abspath(os.path.join("config", ".env")))


class DataLoader:
    def __init__(self, csv_file_path, batch_size=1000):
        self.csv_file_path = csv_file_path
        self.batch_size = batch_size

    def _get_user_id(self, cursor, user_name):
        query = """
            INSERT INTO users (user_name)
            VALUES (%s)
            ON CONFLICT (user_name) DO UPDATE SET user_name = EXCLUDED.user_name
            RETURNING user_id;
        """
        cursor.execute(query, (user_name,))
        return cursor.fetchone()[0]

    def _get_product_id(self, cursor, product_name):
        query = """
            INSERT INTO products (product_name)
            VALUES (%s)
            ON CONFLICT (product_name) DO UPDATE SET product_name = EXCLUDED.product_name
            RETURNING product_id;
        """
        cursor.execute(query, (product_name,))
        return cursor.fetchone()[0]

    def load_data(self):
        if not os.path.exists(self.csv_file_path):
            print(f"❌ Файл {self.csv_file_path} не найден.")
            return

        with DatabaseConnection() as conn, open(self.csv_file_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            total = sum(1 for _ in reader)
            f.seek(0)
            next(reader)

            with conn.cursor() as cursor:
                batch = []
                for row in tqdm(reader, total=total, desc="Загрузка отзывов"):
                    try:
                        product_id = self._get_product_id(cursor, row["name"])
                        user_id = self._get_user_id(cursor, row["reviewerName"])
                        review_text = row["text"]
                        rating = float(row["mark"])
                        batch.append((product_id, user_id, review_text, rating))
                    except Exception as e:
                        print("Ошибка в строке:", row)
                        print("Причина:", e)
                        conn.rollback()

                    if len(batch) >= self.batch_size:
                        self._insert_reviews(cursor, batch)
                        batch.clear()

                if batch:
                    self._insert_reviews(cursor, batch)

    def _insert_reviews(self, cursor, batch):
        query = """
            INSERT INTO reviews (product_id, user_id, review_text, rating)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT DO NOTHING;
        """
        execute_batch(cursor, query, batch)


if __name__ == "__main__":
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    csv_path = os.path.join(BASE_DIR, "database", "sample_data.csv")
    loader = DataLoader(csv_path)
    loader.load_data()