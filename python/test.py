from python.db_connection import DatabaseConnection

def show_reviews(limit=5):
    query = """
        SELECT r.review_id, p.product_name, u.user_name, r.review_text, r.rating
        FROM reviews r
        JOIN products p ON r.product_id = p.product_id
        JOIN users u ON r.user_id = u.user_id
        LIMIT %s;
    """

    with DatabaseConnection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(query, (limit,))
            for row in cursor.fetchall():
                print("\n---")
                print(f"🛍️ Товар: {row[1]}")
                print(f"👤 Пользователь: {row[2]}")
                print(f"⭐ Оценка: {row[4]}")
                print(f"💬 Отзыв:\n{row[3]}\n")

if __name__ == "__main__":
    show_reviews()