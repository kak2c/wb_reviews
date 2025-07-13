from python.db_connection import DatabaseConnection
from psycopg2.extras import execute_batch
from tqdm import tqdm


class EmbeddingGenerator:
    def generate_embeddings(self, batch_size: int = 100):
        with DatabaseConnection() as conn:
            with conn.cursor() as cursor:
                # Получаем количество отзывов без эмбеддингов
                cursor.execute("""
                    SELECT COUNT(*) FROM reviews r
                    LEFT JOIN review_embeddings e ON r.review_id = e.review_id
                    WHERE e.review_id IS NULL
                """)
                total_reviews = cursor.fetchone()[0]

                if total_reviews == 0:
                    print("Все эмбеддинги уже сгенерированы.")
                    return

                print(f"Всего отзывов для обработки: {total_reviews}")

                for offset in tqdm(range(0, total_reviews, batch_size), desc="Генерация эмбеддингов"):
                    cursor.execute("""
                        SELECT r.review_id, r.review_text
                        FROM reviews r
                        LEFT JOIN review_embeddings e ON r.review_id = e.review_id
                        WHERE e.review_id IS NULL
                        ORDER BY r.created_at DESC
                        LIMIT %s OFFSET %s
                    """, (batch_size, offset))

                    batch = cursor.fetchall()
                    embeddings_data = []

                    for review_id, review_text in batch:
                        # Вызываем SQL-функцию generate_text_embeddings
                        cursor.execute(
                            "SELECT generate_text_embeddings(%s)", (review_text,)
                        )
                        embedding = cursor.fetchone()[0]  # это массив float

                        embeddings_data.append((review_id, embedding))

                    # Сохраняем вектор в таблицу
                    execute_batch(
                        cursor,
                        """
                        INSERT INTO review_embeddings (review_id, embedding_vector)
                        VALUES (%s, %s)
                        ON CONFLICT (review_id) DO UPDATE SET embedding_vector = EXCLUDED.embedding_vector
                        """,
                        embeddings_data,
                    )

                    conn.commit()


if __name__ == "__main__":
    generator = EmbeddingGenerator()
    generator.generate_embeddings()