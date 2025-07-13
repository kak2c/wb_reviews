-- ФУНКЦИЯ: Обновление ts_vector
CREATE OR REPLACE FUNCTION update_review_tsvector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ts_vector := setweight(to_tsvector('russian', COALESCE(NEW.review_text, '')), 'A');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для ts_vector
CREATE TRIGGER trigger_update_review_tsvector
BEFORE INSERT OR UPDATE OF review_text ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_review_tsvector();

-- ФУНКЦИЯ: Извлечение ключевых фраз на Python
CREATE OR REPLACE FUNCTION extract_key_phrases(
    text TEXT,
    max_phrases INTEGER DEFAULT 5
)
RETURNS TEXT[] AS $$
import sys
import re
import nltk
from sklearn.feature_extraction.text import TfidfVectorizer

# Пути до пакетов (можно адаптировать под вашу систему)
sys.path.insert(0, '/usr/local/lib/python3.11/dist-packages')
nltk.data.path.append('/var/lib/postgresql/nltk_dat')

# Загружаем стоп-слова (один раз)
if 'stop_words' not in SD:
    from nltk.corpus import stopwords
    SD['stop_words'] = set(stopwords.words('russian'))

# Очистка текста
def preprocess(text):
    text = re.sub(r'[^а-яА-Яa-zA-Z\s]', '', text.lower())
    tokens = text.split()
    tokens = [t for t in tokens if t not in SD['stop_words'] and len(t) > 2]
    return tokens

tokens = preprocess(text)
if not tokens:
    return []

doc = [' '.join(tokens)]

try:
    vectorizer = TfidfVectorizer(ngram_range=(1,2), max_features=max_phrases * 2)
    X = vectorizer.fit_transform(doc)
    features = vectorizer.get_feature_names_out()
    scores = X.toarray()[0]
    ranked = sorted(zip(features, scores), key=lambda x: x[1], reverse=True)
    phrases = [phrase for phrase, score in ranked[:max_phrases]]
    return phrases
except Exception as e:
    plpy.warning(f"TF-IDF error: {str(e)}")
    return []
$$ LANGUAGE plpython3u;

-- ФУНКЦИЯ: Анализ тональности через Transformers
CREATE OR REPLACE FUNCTION analyze_sentiment_transformers(
    review_text TEXT,
    model_name TEXT DEFAULT 'blanchefort/rubert-base-cased-sentiment'
)
RETURNS TABLE(sentiment_score FLOAT, sentiment_label TEXT) AS $$
import sys
sys.path.insert(0, '/usr/local/lib/python3.11/dist-packages')

import torch
from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification

if 'sentiment_model' not in GD:
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(model_name)
    device = 0 if torch.cuda.is_available() else -1
    if device == 0:
        model = model.cuda()

    sentiment_analyzer = pipeline(
        "sentiment-analysis",
        model=model,
        tokenizer=tokenizer,
        device=device
    )

    GD['sentiment_model'] = sentiment_analyzer

try:
    result = GD['sentiment_model'](review_text)[0]
    label = result['label'].lower()
    score = result['score']
    if label == 'positive':
        sentiment_score = score
    elif label == 'negative':
        sentiment_score = -score
    else:
        sentiment_score = 0
    yield (sentiment_score, label)
except Exception as e:
    yield (0.0, 'neutral')
$$ LANGUAGE plpython3u;

-- ФУНКЦИЯ: Генерация эмбеддингов через SentenceTransformer
CREATE OR REPLACE FUNCTION generate_text_embeddings(
    input_text TEXT,
    model_name TEXT DEFAULT 'sentence-transformers/all-MiniLM-L6-v2'
)
RETURNS FLOAT[] AS $$
import sys
sys.path.insert(0, '/usr/local/lib/python3.11/dist-packages')  # или путь к site-packages внутри контейнера

# Проверка и загрузка модели
if 'embedding_model' not in GD:
    try:
        from sentence_transformers import SentenceTransformer
        GD['embedding_model'] = SentenceTransformer(model_name)
    except Exception as e:
        plpy.error(f"Ошибка загрузки модели: {str(e)}")

try:
    embedding = GD['embedding_model'].encode(input_text)
    return [float(x) for x in embedding]
except Exception as e:
    plpy.error(f"Ошибка генерации эмбеддинга: {str(e)}")
$$ LANGUAGE plpython3u;