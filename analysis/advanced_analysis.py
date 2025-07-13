from python.db_connection import DatabaseConnection

class AdvancedAnalysis:

    def find_similar_reviews(self, review_id: int, top_n: int = 5):
        """
        Поиск отзывов, похожих на заданный по embedding_vector (через pgvector <=>)
        """
        with DatabaseConnection() as conn:
            with conn.cursor() as cursor:
                query = """
                    SELECT r.review_id, r.review_text, ve.similarity
                    FROM (
                        SELECT re2.review_id,
                               1 - (re1.embedding_vector <=> re2.embedding_vector) AS similarity
                        FROM review_embeddings re1
                        JOIN review_embeddings re2 ON re1.review_id != re2.review_id
                        WHERE re1.review_id = %s
                        ORDER BY re1.embedding_vector <=> re2.embedding_vector
                        LIMIT %s
                    ) AS ve
                    JOIN reviews r ON r.review_id = ve.review_id
                """
                cursor.execute(query, (review_id, top_n))
                return cursor.fetchall()

    def detect_anomalous_reviews(self, threshold: float = 0.6):
        """
        Поиск аномальных отзывов с низким "средним" сходством к другим (редкие/необычные отзывы)
        """
        with DatabaseConnection() as conn:
            with conn.cursor() as cursor:
                query = """
                    SELECT re1.review_id, r.review_text, AVG(1 - (re1.embedding_vector <=> re2.embedding_vector)) as avg_similarity
                    FROM review_embeddings re1
                    JOIN review_embeddings re2 ON re1.review_id != re2.review_id
                    JOIN reviews r ON r.review_id = re1.review_id
                    GROUP BY re1.review_id, r.review_text
                    HAVING AVG(1 - (re1.embedding_vector <=> re2.embedding_vector)) < %s
                    ORDER BY avg_similarity ASC
                    LIMIT 10
                """
                cursor.execute(query, (threshold,))
                return cursor.fetchall()


if __name__ == "__main__":
    analysis = AdvancedAnalysis()

    print("\n🔍 Похожие отзывы:")
    similar = analysis.find_similar_reviews(review_id=1)
    for row in similar:
        print(row)

    print("\n🚨 Аномальные отзывы:")
    anomalies = analysis.detect_anomalous_reviews()
    for row in anomalies:
        print(row)