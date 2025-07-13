FROM postgres:15

# Установка расширений
RUN apt-get update && \
    apt-get install -y \
        postgresql-15-pgvector \
        postgresql-plpython3-15 \
        python3-pip \
        python3-dev \
        build-essential \
        git \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Копируем зависимости и устанавливаем Python-библиотеки
COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Копируем весь проект в /app
COPY . /app
WORKDIR /app

# Устанавливаем переменные окружения
ENV PYTHONUNBUFFERED=1

# Открываем порт PostgreSQL
EXPOSE 5432

# Запускаем Python-инициализацию
CMD ["python3", "python/init_db.py"]