FROM postgres:15

# Установим pgvector и поддержку PL/Python
RUN apt-get update && \
    apt-get install -y \
        postgresql-15-pgvector \
        postgresql-plpython3-15 \
        python3-pip \
        python3-dev \
        libpq-dev \
        gcc \
        wget \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Обновим pip и установим Python-библиотеки для NLP
RUN pip3 install --upgrade pip && \
    pip3 install psycopg2-binary python-dotenv tqdm torch transformers scikit-learn nltk sentence-transformers \

# Скачаем русские стоп-слова в нужный каталог для NLTK
RUN mkdir -p /var/lib/postgresql/nltk_data && \
    python3 -m nltk.downloader stopwords -d /var/lib/postgresql/nltk_data

# Открываем порт для PostgreSQL
EXPOSE 5432