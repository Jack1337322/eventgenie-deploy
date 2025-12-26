# Инструкция по развертыванию EventGenie на внешнем сервере

## 📋 Требования

- **ОС**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / RHEL 8+
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Git**: 2.20+
- **Минимальные ресурсы**:
  - RAM: 4GB
  - CPU: 2 cores
  - Диск: 20GB свободного места
  - Сеть: стабильное интернет-соединение

## 🚀 Быстрый старт

### Шаг 1: Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# Проверка установки
docker --version
docker-compose --version
```

### Шаг 2: Клонирование репозитория развертывания

```bash
# Создание директории для проекта
mkdir -p /opt/eventgenie
cd /opt/eventgenie

# Клонирование репозитория eventgenie-deploy
git clone https://github.com/Jack1337322/eventgenie-deploy.git .
```

### Шаг 3: Настройка переменных окружения

```bash
# Копирование примера конфигурации
cp .env.example .env

# Редактирование .env файла
nano .env
```

**Обязательные переменные для заполнения:**

```bash
# Сервер
SERVER_HOST=your-domain.com  # или IP адрес

# База данных (ОБЯЗАТЕЛЬНО измените пароль!)
POSTGRES_PASSWORD=your_secure_password_here

# GigaChat API (получите на https://developers.sber.ru/portal/products/gigachat)
GIGACHAT_CLIENT_ID=your_client_id
GIGACHAT_CLIENT_SECRET=your_client_secret

# JWT Secret (сгенерируйте: openssl rand -base64 32)
JWT_SECRET=your_jwt_secret_minimum_32_characters

# Frontend API URL
VITE_API_URL=http://your-domain.com:8080
```

### Шаг 4: Развертывание

```bash
# Сделать скрипт исполняемым
chmod +x deploy.sh

# Запуск развертывания
./deploy.sh
```

Или используйте Makefile:

```bash
make deploy
```

Скрипт автоматически:
1. ✅ Клонирует/обновит все репозитории (backend, frontend, agents)
2. ✅ Соберет Docker образы
3. ✅ Запустит все сервисы

### Шаг 5: Проверка статуса

```bash
# Проверка статуса контейнеров
make status
# или
docker-compose -f docker-compose.prod.yml ps

# Проверка здоровья сервисов
make health

# Просмотр логов
make logs
```

## 📊 Управление сервисами

### Основные команды

```bash
# Просмотр статуса
make status

# Просмотр логов
make logs              # Все сервисы
make logs-backend      # Только backend
make logs-agents       # Только agents
make logs-frontend     # Только frontend

# Управление сервисами
make start             # Запустить все
make stop              # Остановить все
make restart           # Перезапустить все
make restart-backend   # Перезапустить только backend

# Обновление
make update            # Обновить репозитории и пересобрать
make pull-repos        # Только обновить репозитории
```

### Ручное управление через Docker Compose

```bash
# Запуск
docker-compose -f docker-compose.prod.yml up -d

# Остановка
docker-compose -f docker-compose.prod.yml down

# Перезапуск конкретного сервиса
docker-compose -f docker-compose.prod.yml restart backend-service

# Просмотр логов
docker-compose -f docker-compose.prod.yml logs -f backend-service
```

## 🔧 Настройка Nginx (рекомендуется для продакшена)

Для продакшена рекомендуется использовать Nginx как reverse proxy:

### Установка Nginx

```bash
sudo apt install nginx
```

### Конфигурация Nginx

Создайте файл `/etc/nginx/sites-available/eventgenie`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support (если нужно)
    location /ws {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Активация конфигурации:

```bash
sudo ln -s /etc/nginx/sites-available/eventgenie /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Настройка SSL (Let's Encrypt)

```bash
# Установка Certbot
sudo apt install certbot python3-certbot-nginx

# Получение сертификата
sudo certbot --nginx -d your-domain.com

# Автоматическое обновление
sudo certbot renew --dry-run
```

## 💾 Резервное копирование

### Создание бэкапа базы данных

```bash
# Автоматический бэкап
make backup

# Ручной бэкап
docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U eventgenie eventgenie > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление из бэкапа

```bash
# Через Makefile
make restore FILE=backups/backup_20250101_120000.sql

# Ручное восстановление
docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U eventgenie eventgenie < backup_file.sql
```

### Автоматические бэкапы (cron)

Добавьте в crontab:

```bash
# Редактирование crontab
crontab -e

# Бэкап каждый день в 2:00
0 2 * * * cd /opt/eventgenie && make backup
```

## 🔍 Мониторинг и отладка

### Проверка здоровья сервисов

```bash
# Проверка всех сервисов
make health

# Проверка конкретных endpoints
curl http://localhost:8080/actuator/health  # Backend
curl http://localhost:8001/health            # Agents
curl http://localhost:3000                   # Frontend
```

### Просмотр логов

```bash
# Все сервисы
make logs

# Конкретный сервис
make logs-backend
make logs-agents

# Последние 100 строк
docker-compose -f docker-compose.prod.yml logs --tail=100 backend-service
```

### Отладка проблем

```bash
# Проверка файлов развертывания
make check

# Использование ресурсов
docker stats

# Проверка сетевых подключений
docker network inspect eventgenie_eventgenie-network

# Вход в контейнер
make shell-backend
make shell-agents
make shell-postgres
```

## 🔄 Обновление приложения

### Обновление всех компонентов

```bash
# Обновить репозитории и пересобрать
make update

# Или вручную
./deploy.sh
```

### Обновление конкретного сервиса

```bash
# Обновить только backend
cd repos/eventgenie-backend
git pull origin main
cd ../..
docker-compose -f docker-compose.prod.yml build backend-service
docker-compose -f docker-compose.prod.yml up -d backend-service
```

## 🛡️ Безопасность

### Рекомендации по безопасности

1. **Измените все пароли по умолчанию**:
   - `POSTGRES_PASSWORD`
   - `JWT_SECRET`

2. **Настройте файрвол**:
   ```bash
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 80/tcp     # HTTP
   sudo ufw allow 443/tcp   # HTTPS
   sudo ufw enable
   ```

3. **Ограничьте доступ к портам**:
   - Не открывайте порты 8080, 8001, 5432 наружу
   - Используйте Nginx как reverse proxy

4. **Регулярно обновляйте**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   docker-compose -f docker-compose.prod.yml pull
   ```

5. **Используйте секреты**:
   - Храните `.env` файл в безопасном месте
   - Не коммитьте `.env` в git
   - Используйте переменные окружения или секреты

## 🐛 Troubleshooting

### Проблемы с портами

```bash
# Проверка занятых портов
sudo netstat -tulpn | grep -E '3000|8080|8001|5432'

# Освобождение порта (если нужно)
sudo lsof -ti:8080 | xargs kill -9
```

### Проблемы с правами доступа

```bash
# Проверка прав на Docker
docker ps

# Если ошибка, добавьте пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker
```

### Проблемы с GigaChat API

```bash
# Проверка логов agents-service
make logs-agents | grep -i "error\|403\|401"

# Проверка переменных окружения
docker-compose -f docker-compose.prod.yml exec agents-service env | grep GIGACHAT
```

### Проблемы с базой данных

```bash
# Проверка подключения к БД
make shell-postgres

# Внутри psql:
\dt  # Список таблиц
SELECT * FROM events LIMIT 5;  # Проверка данных
```

### Очистка и пересборка

```bash
# Остановка и удаление контейнеров
make stop

# Очистка (ВНИМАНИЕ: удалит все данные!)
make clean

# Пересборка с нуля
make deploy
```

## 📞 Поддержка

При возникновении проблем:

1. Проверьте логи: `make logs`
2. Проверьте статус: `make status`
3. Проверьте здоровье: `make health`
4. Проверьте конфигурацию: `make check`

## 📚 Дополнительные ресурсы

- [Backend Repository](https://github.com/Jack1337322/eventgenie-backend)
- [Frontend Repository](https://github.com/Jack1337322/eventgenie-frontend)
- [Agents Repository](https://github.com/Jack1337322/eventgenie-agents)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
