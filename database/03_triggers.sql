
-- Автоматическое обновление created_at при UPDATE
CREATE TRIGGER trg_update_reviews_timestamp
BEFORE UPDATE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_sentiment_timestamp
BEFORE UPDATE ON sentiment_analysis
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_embeddings_timestamp
BEFORE UPDATE ON review_embeddings
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Автоматическая обработка новых отзывов
CREATE OR REPLACE FUNCTION process_new_review()
RETURNS TRIGGER AS $$
BEGIN
  -- Тональность
  INSERT INTO sentiment_analysis (review_id, sentiment_score, sentiment_label)
  SELECT NEW.review_id, s.sentiment_score, s.sentiment_label
  FROM analyze_sentiment_transformers(NEW.review_text) AS s;

  -- Ключевые фразы
  INSERT INTO key_phrases (review_id, phrases)
  VALUES (
    NEW.review_id,
    extract_key_phrases(NEW.review_text)
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_process_review
AFTER INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION process_new_review();

-- Логирование изменений

CREATE OR REPLACE FUNCTION log_review_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.review_text IS DISTINCT FROM OLD.review_text THEN
    INSERT INTO review_logs (review_id, old_text, new_text)
    VALUES (OLD.review_id, OLD.review_text, NEW.review_text);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_review_change
AFTER UPDATE ON reviews
FOR EACH ROW
WHEN (OLD.review_text IS DISTINCT FROM NEW.review_text)
EXECUTE FUNCTION log_review_update();

-- Проверка на дубликаты
CREATE OR REPLACE FUNCTION prevent_duplicate_reviews()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
  SELECT 1 FROM reviews
  WHERE product_id = NEW.product_id AND review_text = NEW.review_text
) THEN
  RETURN NULL;
END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_duplicates
BEFORE INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_reviews();