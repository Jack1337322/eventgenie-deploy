# EventGenie Deployment Repository

Репозиторий для развертывания EventGenie на внешнем сервере.

## 📦 Что включает этот репозиторий

- `docker-compose.prod.yml` - Конфигурация Docker Compose для продакшена
- `deploy.sh` - Скрипт автоматического развертывания
- `.env.example` - Пример файла с переменными окружения
- `init.sql` - SQL скрипт для инициализации базы данных
- `Makefile` - Удобные команды для управления
- `DEPLOYMENT.md` - Подробная инструкция по развертыванию

## 🚀 Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/Jack1337322/eventgenie-deploy.git
cd eventgenie-deploy

# 2. Настроить переменные окружения
cp .env.example .env
nano .env  # Заполните все необходимые значения

# 3. Развернуть
chmod +x deploy.sh
./deploy.sh
```

## 📋 Зависимости

Этот репозиторий автоматически клонирует и собирает:

- [eventgenie-backend](https://github.com/Jack1337322/eventgenie-backend) - Spring Boot backend
- [eventgenie-frontend](https://github.com/Jack1337322/eventgenie-frontend) - React frontend
- [eventgenie-agents](https://github.com/Jack1337322/eventgenie-agents) - FastAPI agents service

## 🛠️ Основные команды

```bash
make deploy      # Развернуть приложение
make update      # Обновить и пересобрать
make logs        # Просмотр логов
make status      # Статус сервисов
make health      # Проверка здоровья
make backup      # Создать бэкап БД
make stop        # Остановить сервисы
make start       # Запустить сервисы
make help        # Показать все команды
```

## 📖 Документация

Подробная инструкция по развертыванию находится в [DEPLOYMENT.md](./DEPLOYMENT.md)

## 🔐 Безопасность

⚠️ **ВАЖНО**: После клонирования обязательно:

1. Создайте `.env` файл из `.env.example`
2. Измените все пароли по умолчанию
3. Настройте `JWT_SECRET` (минимум 32 символа)
4. Добавьте ваши GigaChat credentials

## 🏗️ Архитектура

```
┌─────────────┐
│  Frontend   │ (React, Port 3000)
│  (Nginx)    │
└──────┬──────┘
       │
┌──────▼──────┐
│   Backend   │ (Spring Boot, Port 8080)
│   Service   │
└──────┬──────┘
       │
┌──────▼──────┐     ┌─────────────┐
│   Agents    │────▶│  GigaChat   │
│   Service   │     │     API     │
│ (Port 8001) │     └─────────────┘
└──────┬──────┘
       │
┌──────▼──────┐
│ PostgreSQL  │ (Port 5432)
│  Database   │
└─────────────┘
```

## 📝 Лицензия

MIT

## 👥 Команда

Разработано для EventGenie Platform
