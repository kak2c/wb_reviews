# 🧠 WB Reviews NLP Pipeline

Это проект по анализу отзывов с Wildberries с использованием PostgreSQL, PL/Python и современных NLP-инструментов.

---

## 🚀 Возможности

- 🔍 Анализ тональности отзывов (на русском языке)
- 🗝 Извлечение ключевых фраз
- 🔄 Автоматическая загрузка и обновление отзывов
- 🧠 Генерация векторных представлений (эмбеддингов)
- 📊 SQL- и Python-анализ отзывов
- 🧾 Логирование, триггеры, защита от дубликатов

---

## 📁 Структура проекта

```bash
├── analysis/                 # SQL и Python-анализ
│   ├── basic_analysis.sql
│   └── advanced_analysis.py
├── config/                  # Конфигурации
│   ├── .env
│   └── requirements.txt
├── database/                # SQL-скрипты и данные
│   ├── 01_tables.sql
│   ├── 02_functions.sql
│   ├── 03_triggers.sql
│   └── sample_data.csv
├── python/                  # Основная логика на Python
│   ├── data_loader.py
│   ├── db_connection.py
│   ├── init_db.py
│   ├── nlp_processor.py
│   └── embedding_generator.py
├── Dockerfile               # Сборка контейнера PostgreSQL + Python
└── README.md