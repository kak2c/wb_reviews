-- 📊 Средний рейтинг по товарам
SELECT
    p.product_id,
    p.product_name,
    COUNT(r.review_id) AS num_reviews,
    ROUND(AVG(r.mark), 2) AS avg_rating
FROM reviews r
JOIN products p ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY avg_rating DESC;


-- 🔠 Частотность слов в отзывах (больше 3 символов, не пустые)
SELECT
    LOWER(word) AS word,
    COUNT(*) AS count
FROM (
    SELECT UNNEST(
        STRING_TO_ARRAY(
            REGEXP_REPLACE(r.review_text, '[^А-Яа-яA-Za-z0-9 ]', '', 'g'),
            ' '
        )
    ) AS word
    FROM reviews r
) AS words
WHERE LENGTH(word) > 3 AND word IS NOT NULL AND word <> ''
GROUP BY word
ORDER BY count DESC
LIMIT 100;


-- 🧭 Распределение тональности по категориям
SELECT
    c.category_name,
    sa.sentiment_label,
    COUNT(*) AS review_count
FROM reviews r
JOIN sentiment_analysis sa ON r.review_id = sa.review_id
JOIN products p ON r.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name, sa.sentiment_label
ORDER BY c.category_name, sa.sentiment_label;


-- 🗝 Часто встречающиеся ключевые фразы
SELECT
    LOWER(UNNEST(phrases)) AS phrase,
    COUNT(*) AS count
FROM key_phrases
GROUP BY phrase
HAVING LENGTH(phrase) > 3
ORDER BY count DESC
LIMIT 100;