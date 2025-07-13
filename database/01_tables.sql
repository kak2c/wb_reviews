-- Расширения
CREATE EXTENSION IF NOT EXISTS plpython3u;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Таблица продуктов
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица пользователей
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    user_name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица отзывов
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products (product_id),
    user_id INTEGER NOT NULL REFERENCES users (user_id),
    review_text TEXT NOT NULL,
    rating FLOAT CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ts_vector tsvector
);

-- Таблица анализа тональности
CREATE TABLE sentiment_analysis (
    review_id INTEGER PRIMARY KEY REFERENCES reviews (review_id) ON DELETE CASCADE,
    sentiment_score FLOAT NOT NULL CHECK (sentiment_score BETWEEN -1 AND 1),
    sentiment_label VARCHAR(20) NOT NULL CHECK (
        sentiment_label IN ('positive', 'neutral', 'negative')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица ключевых фраз
CREATE TABLE key_phrases (
    review_id INTEGER REFERENCES reviews (review_id) ON DELETE CASCADE,
    phrases TEXT[] NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id, phrases)
);

-- Таблица эмбеддингов
CREATE TABLE review_embeddings (
    review_id INTEGER PRIMARY KEY REFERENCES reviews (review_id) ON DELETE CASCADE,
    embedding_vector VECTOR(384) NOT NULL,
    model_version VARCHAR(100) DEFAULT 'sentence-transformers/all-MiniLM-L6-v2',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Таблица с логами
CREATE TABLE review_logs (
  log_id SERIAL PRIMARY KEY,
  review_id INTEGER REFERENCES reviews(review_id),
  old_text TEXT,
  new_text TEXT,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Индексы
CREATE INDEX idx_reviews_product_id ON reviews (product_id);
CREATE INDEX idx_reviews_user_id ON reviews (user_id);
CREATE INDEX idx_reviews_rating ON reviews (rating);
CREATE INDEX idx_reviews_created_at ON reviews (created_at);
CREATE INDEX idx_reviews_tsvector ON reviews USING gin(ts_vector);
CREATE INDEX idx_embedding_vector ON review_embeddings USING ivfflat (embedding_vector vector_l2_ops)
WITH (lists = 100);
