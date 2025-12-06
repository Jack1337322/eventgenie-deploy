# Архитектура многоагентной системы ИИ для событийной индустрии
## Микросервисная архитектура с оркестрацией агентов

---

## СОДЕРЖАНИЕ
1. [Обзор архитектуры](#обзор-архитектуры)
2. [Компоненты системы](#компоненты-системы)
3. [Микросервисы](#микросервисы)
4. [Многоагентная система](#многоагентная-система)
5. [Потоки данных](#потоки-данных)
6. [Развертывание](#развертывание)
7. [Мониторинг и логирование](#мониторинг-и-логирование)

---

## ОБЗОР АРХИТЕКТУРЫ

### Общая структура

```
┌─────────────────────────────────────────────────────────────┐
│                   CLIENT LAYER (Web/Mobile)                 │
│              React.js | PWA | API Clients                  │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS/gRPC
┌────────────────────────▼────────────────────────────────────┐
│              API GATEWAY & AUTH LAYER                        │
│   Kong/NGINX | OAuth 2.0 | JWT | Rate Limiting             │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌───────▼────────┐ ┌────▼──────────┐ ┌──▼───────────────┐
│  ORCHESTRATION │ │  MICROSERVICES│ │ MESSAGE QUEUE    │
│  LAYER         │ │  LAYER        │ │                  │
│                │ │               │ │ Apache Kafka     │
│ Maestro Agent  │ │ Planning      │ │ RabbitMQ         │
│ (GigaChat 2.0) │ │ Finance       │ │                  │
│                │ │ Vendor        │ │ Real-time sync   │
│ Intent Parse   │ │ Communication │ │                  │
│ Routing        │ │ Analytics     │ │                  │
│ Aggregation    │ │ Social Media  │ │                  │
└─┬──────────────┘ └───┬──────┬────┘ └──┬───────────────┘
  │                    │      │         │
  └────────────────┬───┘      └──┬──────┘
                   │             │
        ┌──────────▼─────────────▼──────────┐
        │     AI & LLM LAYER                │
        │  GigaChat 2.0          │
        │               │
        └──────────────┬─────────────────────┘
                       │
        ┌──────────────▼──────────────────┐
        │    DATA LAYER                   │
        ├─────────────────────────────────┤
        │ PostgreSQL | Redis | Elasticsearch
        │ S3 Storage | Backups            │
        └─────────────────────────────────┘
                       │
        ┌──────────────▼──────────────────┐
        │  EXTERNAL INTEGRATIONS          │
        ├─────────────────────────────────┤
        │ CRM | Payments | Calendars      │
        │ Social Networks | Analytics     │
        └─────────────────────────────────┘
```

---

## КОМПОНЕНТЫ СИСТЕМЫ

### 1. Слой оркестрации (Maestro Agent)

**Ответственность:**
- Парсинг намерений пользователя (Intent Classification)
- Маршрутизация к нужным агентам
- Управление контекстом диалога
- Агрегация результатов от разных микросервисов
- Контроль качества ответов
- Обработка ошибок и fallback-логика

**Технология:**
- **Основа:** GigaChat 2.0 API
- **Framework:** LangChain / LlamaIndex
- **Язык:** Python (FastAPI) или Java (Spring Boot)
- **Ответственный микросервис:** `orchestration-service`

**Логика маршрутизации:**

```python
# Maestro Agent Routing Logic
if intent == "create_plan":
    agents = [planning_agent, finance_agent, vendor_agent]
    mode = "parallel"
elif intent == "analyze_conversion":
    agents = [analytics_agent, social_media_agent, communication_agent]
    mode = "parallel"
elif intent == "chat":
    agents = [communication_agent]
    mode = "sequential"
elif intent == "optimize_pricing":
    agents = [finance_agent]
    mode = "sequential"
else:
    agents = [default_agent]  # GigaChat 2.0
    mode = "sequential"

results = orchestrate_agents(agents, mode=mode, context=user_context)
```

### 2. Слой микросервисов

#### 2.1 Planning Service

**Функции:**
- Создание event-планов и таймлайнов
- Генерация списков задач (To-Do)
- Управление этапами проекта
- Создание шаблонов мероприятий

**API Endpoints:**
```
POST   /api/v1/planning/events/{id}/plan
GET    /api/v1/planning/events/{id}/timeline
GET    /api/v1/planning/tasks
POST   /api/v1/planning/tasks
PUT    /api/v1/planning/tasks/{id}
```

**Используемые LLM:**
- Primary: GigaChat 2.0

**Стек технологий:**
- Backend: Java Spring Boot / Python FastAPI
- Database: PostgreSQL
- Cache: Redis
- Message Queue: Kafka

---

#### 2.2 Finance Service

**Функции:**
- Расчет и анализ смет
- ROI анализ
- Прогноз окупаемости
- Оптимизация цен
- Контроль бюджета (план/факт)

**API Endpoints:**
```
POST   /api/v1/finance/events/{id}/budget
GET    /api/v1/finance/events/{id}/budget
PUT    /api/v1/finance/events/{id}/budget
POST   /api/v1/finance/events/{id}/roi-analysis
GET    /api/v1/finance/pricing-optimization
POST   /api/v1/finance/pricing-optimization
```

**Используемые LLM:**
- Primary: T-Pro (специализирован на аналитике)
- Secondary: GigaChat 2.0 (для текстовых пояснений)

**Стек технологий:**
- Backend: Java Spring Boot (для расчетов и производительности)
- Database: PostgreSQL с расширениями (numeric, jsonb)
- Cache: Redis (для кеширования результатов расчетов)
- Analytics: Elasticsearch (для аналитических запросов)

---

#### 2.3 Vendor Service

**Функции:**
- Поиск подрядчиков по параметрам
- Анализ и сравнение предложений
- Оценка качества поставщиков
- Ведение переговоров
- Управление контрактами

**API Endpoints:**
```
GET    /api/v1/vendors/search
GET    /api/v1/vendors/{id}
POST   /api/v1/vendors/request-quote
GET    /api/v1/vendors/comparison
POST   /api/v1/vendors/contracts
GET    /api/v1/vendors/contracts/{id}
```

**Используемые LLM:**
- Primary: GigaChat 2.0 

**Стек технологий:**
- Backend: Java Spring Boot / Node.js NestJS
- Database: PostgreSQL + Elasticsearch (для полнотекстового поиска)
- Caching: Redis
- Integration: REST API коннекторы к CRM

---

#### 2.4 Communication Service

**Функции:**
- Чат с клиентами (24/7)
- Генерация коммерческих предложений
- Создание маркетинговых текстов
- Email и рассылки
- Обработка FAQ
- Управление обратной связью

**API Endpoints:**
```
POST   /api/v1/communication/chat
GET    /api/v1/communication/messages
POST   /api/v1/communication/proposals
POST   /api/v1/communication/marketing-texts
POST   /api/v1/communication/email-send
GET    /api/v1/communication/faq
```

**Используемые LLM:**
- Primary: Cotype (оптимален для диалогов)
- Secondary: GigaChat 2.0 (для финального качества)

**Стек технологий:**
- Backend: Node.js NestJS (для быстрых итераций, WebSocket поддержка)
- Database: PostgreSQL
- Real-time: WebSocket (для чата)
- Message Queue: RabbitMQ (для email очереди)
- Integration: SendGrid / Mailgun API

---

#### 2.5 Analytics Service

**Функции:**
- Анализ ROI и эффективности
- Анализ конверсии (воронка)
- Генерация гипотез для улучшений
- Аномалия-детекция
- Прогнозирование результатов

**API Endpoints:**
```
GET    /api/v1/analytics/events/{id}/roi
GET    /api/v1/analytics/events/{id}/conversion-funnel
GET    /api/v1/analytics/events/{id}/hypotheses
GET    /api/v1/analytics/events/{id}/anomalies
GET    /api/v1/analytics/predictions
POST   /api/v1/analytics/custom-report
```

**Используемые LLM:**
- Primary: T-Pro (специализирован на аналитике и прогнозах)
- Secondary: Qwen-3-235B (для сложной аналитики)

**Стек технологий:**
- Backend: Java Spring Boot / Python (для ML)
- Database: PostgreSQL + Timescale
- Analytics: Elasticsearch, InfluxDB
- ML: TensorFlow / Scikit-learn (для предсказаний)
- Visualization: Apache Superset / Grafana

---

#### 2.6 Social Media Service

**Функции:**
- Мониторинг упоминаний в соцсетях
- Sentiment-анализ (позитив/негатив)
- Выявление ключевых тем обсуждения
- Создание аналитических отчетов
- Управление репутацией

**API Endpoints:**
```
GET    /api/v1/social-media/events/{id}/mentions
GET    /api/v1/social-media/events/{id}/sentiment
GET    /api/v1/social-media/events/{id}/trending-topics
POST   /api/v1/social-media/monitoring-start
GET    /api/v1/social-media/reports/{id}
```

**Используемые LLM:**
- Primary: GigaChat MultiModal (поддержка текста и изображений)
- Secondary: Cotype (для анализа диалогов)

**Стек технологий:**
- Backend: Python FastAPI (для ML интеграции)
- Database: PostgreSQL
- Search: Elasticsearch
- ML: Hugging Face Transformers (для sentiment-анализа)
- Integrations: VK API, Facebook Graph API, Instagram API, Telegram API
- Message Queue: Kafka (для потока событий из соцсетей)

---

### 3. Слой LLM & Embeddings

```
┌─────────────────────────────────────────────────────┐
│           LLM ORCHESTRATION LAYER                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  PRIMARY LLM:                                       │
│  ┌─────────────────────────────────────────────┐   │
│  │ GigaChat 2.0 (Sber)                         │   │
│  │ • 128K tokens context                       │   │
│  │ • Multimodal (text + image)                 │   │
│  │ • Russian & multilingual                    │   │
│  │ • Best for planning, generation, chat       │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│             │
│                                                     │
│  EMBEDDING MODEL:                                   │
│  └─ Multilingual-E5 (for semantic search)          │
│                                                     │
│  FALLBACK STRATEGY:                                 │
│  └─ Llama-3.1 (Local, for privacy-sensitive)       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Конфигурация LLM параметров:**

| Параметр | Planning | Finance | Vendor | Communication | Analytics |
|----------|----------|---------|--------|---------------|-----------|
| Temperature | 0.5 | 0.3 | 0.7 | 0.6 | 0.4 |
| Max Tokens | 2000 | 1000 | 1500 | 1200 | 4000 |
| Top-p | 0.9 | 0.8 | 0.9 | 0.85 | 0.8 |
| Frequency Penalty | 0.2 | 0 | 0.3 | 0.2 | 0.1 |

---

## МНОГОАГЕНТНАЯ СИСТЕМА

### Архитектура агентов

```
┌─────────────────────────────────────────────────────────┐
│                  MAESTRO AGENT                          │
│              (GigaChat 2.0 + LangChain)                │
│         Intent Classification + Routing                 │
└────┬────────────────┬──────────────┬──────────┬────────┘
     │                │              │          │
     ▼                ▼              ▼          ▼
┌──────────┐   ┌──────────┐   ┌──────────┐  ┌──────────┐
│Planning  │   │Finance   │   │Vendor    │  │Communication
│Agent     │   │Agent     │   │Agent     │  │Agent
├──────────┤   ├──────────┤   ├──────────┤  ├──────────┤
│GigaChat  │   │T-Pro     │   │YandexGPT │  │Cotype
│2.0       │   │          │   │4         │  │
└──────────┘   └──────────┘   └──────────┘  └──────────┘
     │              │              │          │
     └──────────────┼──────────────┼──────────┘
                    │
                    ▼
         ┌─────────────────────┐
         │   Analytics Agent   │
         │   (T-Pro + Qwen-3)  │
         └─────────────────────┘
                    │
                    ▼
         ┌─────────────────────┐
         │ Social Media Agent  │
         │ (GigaChat ML)       │
         └─────────────────────┘
```

### Lifecycle агента

```
1. ИНИЦИАЛИЗАЦИЯ
   ├─ Загрузка конфигурации
   ├─ Подключение к LLM
   ├─ Инициализация памяти (контекста)
   └─ Регистрация в Maestro

2. ПОЛУЧЕНИЕ ЗАПРОСА
   ├─ Maestro парсит intent
   ├─ Определяет нужные агенты
   └─ Отправляет задачу

3. ВЫПОЛНЕНИЕ
   ├─ Загрузка данных из DB
   ├─ Формирование prompt'а
   ├─ Вызов LLM
   ├─ Обработка результата
   └─ Кеширование результата

4.返回 РЕЗУЛЬТАТА
   ├─ Форматирование ответа
   ├─ Отправка в Kafka
   └─ Сохранение в DB

5. МОНИТОРИНГ
   ├─ Трекинг метрик (latency, success rate)
   ├─ Логирование операций
   └─ Alert'ы при проблемах
```

### Примеры агентов

#### Planning Agent

```python
class PlanningAgent:
    def __init__(self):
        self.llm = GigaChat2_0()
        self.db = PostgreSQL()
        self.kafka = KafkaProducer()
    
    async def create_event_plan(self, event_input):
        # 1. Validate input
        validated = self.validate(event_input)
        
        # 2. Load templates
        templates = self.db.get_templates(validated.type)
        
        # 3. Generate plan using LLM
        prompt = self.format_prompt(validated, templates)
        plan = await self.llm.generate(prompt, temperature=0.5)
        
        # 4. Enrich with structured data
        enriched_plan = self.enrich(plan, validated)
        
        # 5. Save and publish
        event_id = self.db.save_event(enriched_plan)
        self.kafka.publish("event.created", 
                          {"event_id": event_id, "plan": enriched_plan})
        
        return {"success": True, "event_id": event_id, "plan": enriched_plan}
```

#### Finance Agent

```python
class FinanceAgent:
    def __init__(self):
        self.llm = TPro()
        self.db = PostgreSQL()
        self.kafka = KafkaProducer()
    
    async def calculate_budget(self, event_id):
        # 1. Load event details
        event = self.db.get_event(event_id)
        
        # 2. Calculate costs
        costs = self.calculate_costs(
            guests=event.guests,
            duration=event.duration,
            location=event.location,
            type=event.type
        )
        
        # 3. Generate budget using LLM (for explanations)
        prompt = self.format_budget_prompt(costs, event)
        budget_analysis = await self.llm.analyze(prompt)
        
        # 4. Create budget object
        budget = {
            "event_id": event_id,
            "costs": costs,
            "analysis": budget_analysis,
            "created_at": datetime.now()
        }
        
        # 5. Save and publish
        budget_id = self.db.save_budget(budget)
        self.kafka.publish("budget.created",
                          {"event_id": event_id, "budget_id": budget_id})
        
        return budget
```

#### Analytics Agent

```python
class AnalyticsAgent:
    def __init__(self):
        self.llm = TPro()  # For analytics
        self.db = PostgreSQL()
        self.elasticsearch = Elasticsearch()
    
    async def analyze_conversion(self, event_id):
        # 1. Load conversion data
        data = self.load_conversion_data(event_id)
        
        # 2. Calculate metrics
        metrics = self.calculate_metrics(data)
        
        # 3. Generate hypotheses using LLM
        prompt = self.format_analysis_prompt(metrics, data)
        hypotheses = await self.llm.generate_hypotheses(prompt)
        
        # 4. Detect anomalies
        anomalies = self.detect_anomalies(data)
        
        # 5. Create report
        report = {
            "event_id": event_id,
            "metrics": metrics,
            "hypotheses": hypotheses,
            "anomalies": anomalies,
            "recommendations": self.generate_recommendations(
                hypotheses, anomalies
            )
        }
        
        # 6. Index for search
        self.elasticsearch.index(report)
        
        return report
```

---

## ПОТОКИ ДАННЫХ

### 1. Поток создания события

```
┌─────────────┐
│ Пользователь│
│ заполняет   │
│ форму       │
└────────┬────┘
         │
         ▼
    ┌──────────────┐
    │ API Gateway  │ → Валидация, Аутентификация
    └────────┬─────┘
             │
             ▼
    ┌─────────────────────────────────┐
    │ Maestro Agent (GigaChat)        │
    │ • Parse intent: "create_event"  │
    │ • Determine agents:             │
    │   [Planning, Finance, Vendor]   │
    │ • Mode: PARALLEL                │
    └────────┬────────────────────────┘
             │
    ┌────────┼────────┬──────────┐
    │        │        │          │
    ▼        ▼        ▼          ▼
┌────────┐┌──────┐┌──────┐┌──────────┐
│Planning││Finance││Vendor││Parallel
│Service ││Service││Service
└────┬───┘└──┬───┘└──┬───┘
     │       │       │
     ▼       ▼       ▼
  Timline  Budget  Vendors
  Tasks    Plan    Recs
     │       │       │
     └───────┼───────┘
             │
             ▼
     ┌──────────────────┐
     │ Kafka Topics     │
     │ • event.created  │
     │ • budget.created │
     │ • vendors.recs   │
     └────────┬─────────┘
              │
              ▼
     ┌──────────────────┐
     │ PostgreSQL       │
     │ • Save event     │
     │ • Save budget    │
     │ • Save tasks     │
     └────────┬─────────┘
              │
              ▼
     ┌──────────────────┐
     │ User Interface   │
     │ Display results  │
     └──────────────────┘
```

### 2. Поток коммуникации с клиентом

```
┌─────────────────┐
│ Клиент отправляет│
│ сообщение       │
└────────┬────────┘
         │
         ▼
    ┌─────────────────┐
    │ Communication   │
    │ Service         │ ← WebSocket / REST
    └────────┬────────┘
             │
             ▼
    ┌─────────────────────┐
    │ Maestro Agent       │
    │ (Cotype)            │
    │ Parse user intent   │
    └────────┬────────────┘
             │
    ┌────────▼────────┐
    │ Is FAQ?         │
    ├─────┬──────────┤
    │ Yes │    No    │
    │  │  │          │
    │  ▼  ▼          ▼
    │ FAQ │ Route to │
    │Ans │ other    │
    │     │ agents  │
    └─────┴──────────┘
             │
             ▼
    ┌─────────────────┐
    │ Generate        │
    │ Response        │
    │ (GigaChat)      │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Save to DB      │
    │ Publish to      │
    │ Kafka           │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Send to Client  │
    │ WebSocket       │
    └─────────────────┘
```

### 3. Поток аналитики

```
┌────────────────────┐
│ Event завершено    │
│ (Kafka trigger)    │
└────────┬───────────┘
         │
         ▼
    ┌────────────────────┐
    │ Analytics Service  │
    │ Subscribe to       │
    │ "event.completed"  │
    └────────┬───────────┘
             │
    ┌────────▼─────────────────┐
    │ Load Data:              │
    │ • Registration data     │
    │ • Attendance data       │
    │ • Budget data           │
    │ • Feedback data         │
    │ • Social mentions       │
    └────────┬────────────────┘
             │
             ▼
    ┌────────────────────┐
    │ T-Pro Agent        │
    │ (Analytics)        │
    │ • Calculate metrics│
    │ • Generate         │
    │   hypotheses       │
    │ • Predict trends   │
    └────────┬───────────┘
             │
             ▼
    ┌────────────────────┐
    │ Save Results:      │
    │ • PostgreSQL       │
    │ • Elasticsearch    │
    │ • Publish to Kafka │
    └────────┬───────────┘
             │
             ▼
    ┌────────────────────┐
    │ Display in         │
    │ Analytics          │
    │ Dashboard          │
    └────────────────────┘
```

---

## РАЗВЕРТЫВАНИЕ

### Инфраструктура (Yandex Cloud / Selectel)

```
┌─────────────────────────────────────────────────────┐
│        KUBERNETES CLUSTER (3 nodes)                  │
│                                                     │
│  ┌────────────────┐  ┌────────────────┐            │
│  │  Node 1        │  │  Node 2        │            │
│  │ (Master/API)   │  │ (Worker)       │            │
│  │ • API Server   │  │ • Pods         │            │
│  │ • Controller   │  │ • Services     │            │
│  └────────────────┘  └────────────────┘            │
│                                                     │
│  ┌────────────────┐                                │
│  │  Node 3        │                                │
│  │ (Worker)       │                                │
│  │ • Pods         │                                │
│  │ • Services     │                                │
│  └────────────────┘                                │
│                                                     │
│  ┌─────────────────────────────────────────┐      │
│  │ SERVICES IN KUBERNETES                  │      │
│  ├─────────────────────────────────────────┤      │
│  │ • Orchestration Service  (1 replica)   │      │
│  │ • Planning Service       (2 replicas)  │      │
│  │ • Finance Service        (2 replicas)  │      │
│  │ • Vendor Service         (2 replicas)  │      │
│  │ • Communication Service  (3 replicas)  │      │
│  │ • Analytics Service      (2 replicas)  │      │
│  │ • Social Media Service   (1 replica)   │      │
│  │ • API Gateway            (2 replicas)  │      │
│  │ • PostgreSQL             (HA mode)     │      │
│  │ • Redis                  (Cluster)     │      │
│  │ • Elasticsearch          (Cluster)     │      │
│  │ • Kafka                  (3 brokers)   │      │
│  └─────────────────────────────────────────┘      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Docker Compose для локальной разработки

```yaml
version: '3.8'

services:
  # API Gateway
  api-gateway:
    image: kong:latest
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: postgres
    ports:
      - "8000:8000"
      - "8443:8443"
    depends_on:
      - postgres

  # Orchestration Service
  orchestration-service:
    build:
      context: ./services/orchestration
      dockerfile: Dockerfile
    environment:
      GIGACHAT_API_KEY: ${GIGACHAT_API_KEY}
      KAFKA_BROKERS: kafka:9092
      POSTGRES_URL: postgresql://user:pass@postgres:5432/events
      REDIS_URL: redis://redis:6379
    ports:
      - "8001:8080"
    depends_on:
      - postgres
      - redis
      - kafka

  # Planning Service
  planning-service:
    build:
      context: ./services/planning
      dockerfile: Dockerfile
    environment:
      GIGACHAT_API_KEY: ${GIGACHAT_API_KEY}
      KAFKA_BROKERS: kafka:9092
      POSTGRES_URL: postgresql://user:pass@postgres:5432/events
    ports:
      - "8002:8080"
    depends_on:
      - postgres
      - kafka

  # Finance Service
  finance-service:
    build:
      context: ./services/finance
      dockerfile: Dockerfile
    environment:
      TPRO_API_KEY: ${TPRO_API_KEY}
      KAFKA_BROKERS: kafka:9092
      POSTGRES_URL: postgresql://user:pass@postgres:5432/events
    ports:
      - "8003:8080"
    depends_on:
      - postgres
      - kafka

  # Vendor Service
  vendor-service:
    build:
      context: ./services/vendor
      dockerfile: Dockerfile
    environment:
      YANDEXGPT_API_KEY: ${YANDEXGPT_API_KEY}
      KAFKA_BROKERS: kafka:9092
      POSTGRES_URL: postgresql://user:pass@postgres:5432/events
      ELASTICSEARCH_HOST: elasticsearch:9200
    ports:
      - "8004:8080"
    depends_on:
      - postgres
      - kafka
      - elasticsearch

  # Communication Service
  communication-service:
    build:
      context: ./services/communication
      dockerfile: Dockerfile
    environment:
      COTYPE_API_KEY: ${COTYPE_API_KEY}
      KAFKA_BROKERS: kafka:9092
      POSTGRES_URL: postgresql://user:pass@postgres:5432/events
      SENDGRID_API_KEY: ${SENDGRID_API_KEY}
    ports:
      - "8005:8080"
    depends_on:
      - postgres
      - kafka

  # Analytics Service
  analytics-service:
    build:
      context: ./services/analytics
      dockerfile: Dockerfile
    environment:
      TPRO_API_KEY: ${TPRO_API_KEY}
      KAFKA_BROKERS: kafka:9092
      POSTGRES_URL: postgresql://user:pass@postgres:5432/events
      ELASTICSEARCH_HOST: elasticsearch:9200
    ports:
      - "8006:8080"
    depends_on:
      - postgres
      - kafka
      - elasticsearch

  # Social Media Service
  social-media-service:
    build:
      context: ./services/social-media
      dockerfile: Dockerfile
    environment:
      GIGACHAT_API_KEY: ${GIGACHAT_API_KEY}
      KAFKA_BROKERS: kafka:9092
      POSTGRES_URL: postgresql://user:pass@postgres:5432/events
      ELASTICSEARCH_HOST: elasticsearch:9200
      VK_API_TOKEN: ${VK_API_TOKEN}
      FACEBOOK_API_TOKEN: ${FACEBOOK_API_TOKEN}
    ports:
      - "8007:8080"
    depends_on:
      - postgres
      - kafka
      - elasticsearch

  # PostgreSQL
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: events
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # Elasticsearch
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.5.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data

  # Kafka
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    ports:
      - "9092:9092"
    depends_on:
      - zookeeper

  # Zookeeper (for Kafka)
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    ports:
      - "2181:2181"

  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    depends_on:
      - api-gateway

volumes:
  postgres_data:
  redis_data:
  elasticsearch_data:
```

---

## МОНИТОРИНГ И ЛОГИРОВАНИЕ

### Метрики

```
┌────────────────────────────────────────┐
│ PROMETHEUS METRICS                     │
├────────────────────────────────────────┤
│ Per Microservice:                      │
│ • Request latency (p50, p95, p99)      │
│ • Request count (total, by status)     │
│ • Error rate                           │
│ • Cache hit/miss ratio                 │
│ • Database query time                  │
│                                        │
│ Per Agent:                             │
│ • Agent execution time                 │
│ • LLM API latency                      │
│ • Token usage (input/output)           │
│ • Success/failure rate                 │
│ • Fallback triggered count             │
│                                        │
│ System:                                │
│ • CPU usage                            │
│ • Memory usage                         │
│ • Disk I/O                             │
│ • Network bandwidth                    │
│ • Active connections                   │
└────────────────────────────────────────┘
```

### Логирование (ELK Stack)

```
┌──────────────────────────────────────┐
│ APPLICATION LOGS (JSON format)       │
├──────────────────────────────────────┤
│ {                                    │
│   "timestamp": "2025-12-04T...",    │
│   "level": "INFO",                   │
│   "service": "planning-service",     │
│   "agent": "planning-agent",         │
│   "user_id": "user-123",             │
│   "event_id": "event-456",           │
│   "message": "Event plan created",   │
│   "latency_ms": 1250,                │
│   "llm_model": "GigaChat 2.0",       │
│   "tokens_used": 450,                │
│   "status": "success"                │
│ }                                    │
│                      ↓               │
│ ┌─────────────────────────────────┐  │
│ │ Logstash (Processing)           │  │
│ └─────────────────────────────────┘  │
│                      ↓               │
│ ┌─────────────────────────────────┐  │
│ │ Elasticsearch (Storage)         │  │
│ │ • Index per service             │  │
│ │ • TTL: 30 days                  │  │
│ └─────────────────────────────────┘  │
│                      ↓               │
│ ┌─────────────────────────────────┐  │
│ │ Kibana (Visualization)          │  │
│ │ • Dashboards                    │  │
│ │ • Alerts                        │  │
│ │ • Analysis                      │  │
│ └─────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Алерты

```
Критические алерты:
  • Service unavailable (HTTP 503)
  • High error rate (>5%)
  • High latency (p95 > 5s)
  • LLM API error
  • Database connection failed
  • Message queue lag (Kafka)

Предупреждения:
  • High memory usage (>80%)
  • High CPU usage (>75%)
  • Slow query detected (>2s)
  • High cache miss rate (>30%)
  • Fallback LLM triggered

Информационные:
  • Service deployment
  • Configuration change
  • Scheduled maintenance
  • Scale event (auto-scaling)
```

---

## ИТОГОВАЯ ТАБЛИЦА КОМПОНЕНТОВ

| Компонент | Язык | Framework | БД | LLM | Масштаб |
|-----------|------|-----------|-----|-----|---------|
| API Gateway | Go/Lua | Kong | - | - | 2 реплики |
| Orchestration | Python | FastAPI | Redis | GigaChat | 1 реплика |
| Planning | Java | Spring Boot | PostgreSQL | GigaChat | 2 реплики |
| Finance | Java | Spring Boot | PostgreSQL | T-Pro | 2 реплики |
| Vendor | Node.js | NestJS | PostgreSQL + ES | YandexGPT | 2 реплики |
| Communication | Node.js | NestJS | PostgreSQL | Cotype | 3 реплики |
| Analytics | Python | FastAPI | PostgreSQL + ES | T-Pro | 2 реплики |
| Social Media | Python | FastAPI | PostgreSQL + ES | GigaChat | 1 реплика |

---

## БЕЗОПАСНОСТЬ

### Аутентификация и авторизация

```
OAuth 2.0 + JWT
  • Social login (VK, Google)
  • API keys for integrations
  • RBAC (Role-Based Access Control)
  • Rate limiting per user/API key

Шифрование:
  • TLS 1.3 для всех сетевых соединений
  • Encryption at rest для БД
  • API key encryption in transit

Compliance:
  • GDPR (данные пользователей)
  • PCI-DSS (платежная информация)
  • Audit logging всех действий
```

---

## CONCLUSION

Архитектура многоагентной системы обеспечивает:

✅ **Масштабируемость** — микросервисы можно масштабировать независимо  
✅ **Надежность** — redundancy и fallback механизмы  
✅ **Гибкость** — легко добавлять новых агентов  
✅ **Производительность** — параллельная обработка, кеширование  
✅ **Наблюдаемость** — полное логирование и мониторинг  
✅ **Безопасность** — OAuth 2.0, TLS, аудит  

Эта архитектура готова к production и может масштабироваться до миллионов событий в год.
