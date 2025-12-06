# Детальная спецификация микросервисов ИИ-агентов для событийной индустрии

---

## 1. ORCHESTRATION SERVICE (Maestro Agent)

### Функциональность
- Intent Classification (определение намерения пользователя)
- Routing (маршрутизация к нужным агентам)
- Context Management (управление контекстом диалога)
- Result Aggregation (агрегация результатов)
- Quality Control (контроль качества ответов)
- Error Handling & Fallback (обработка ошибок)

### Технология
```
Language: Python 3.11
Framework: FastAPI
LLM: GigaChat 2.0 API
Dependencies:
  - langchain >= 0.1.0
  - llamaindex >= 0.9.0
  - pydantic >= 2.0
  - aiohttp >= 3.9.0
```

### API Endpoints

```
POST /api/v1/orchestration/process
  Input: {
    user_id: string,
    message: string,
    context: object (optional)
  }
  Output: {
    intent: string,
    confidence: float,
    agents_used: [string],
    results: object,
    execution_time_ms: int
  }

POST /api/v1/orchestration/intent-classify
  Input: {
    text: string
  }
  Output: {
    intent: string,
    entities: {
      event_type?: string,
      date?: string,
      guests_count?: int,
      budget?: float,
      location?: string
    },
    confidence: float
  }

GET /api/v1/orchestration/health
  Output: {
    status: string,
    gigachat_api: string,
    uptime_seconds: int,
    requests_processed: int
  }
```

### Примеры использования

**Пример 1: Создание плана события**
```
Request:
POST /api/v1/orchestration/process
{
  "user_id": "user-123",
  "message": "Создай план свадьбы на 150 человек 15 апреля"
}

Response:
{
  "intent": "create_event_plan",
  "confidence": 0.98,
  "agents_used": ["planning", "finance", "vendor"],
  "results": {
    "plan": { ... timeline, tasks ... },
    "budget": { ... estimated costs ... },
    "vendors": [ ... recommendations ... ]
  },
  "execution_time_ms": 2341
}
```

**Пример 2: Анализ конверсии**
```
Request:
POST /api/v1/orchestration/process
{
  "user_id": "user-123",
  "message": "Почему у нас регистрировалось 1000, а пришло 100?"
}

Response:
{
  "intent": "analyze_conversion",
  "confidence": 0.95,
  "agents_used": ["analytics", "social_media", "communication"],
  "results": {
    "hypotheses": [
      {
        "hypothesis": "Слабое напоминание за день до события",
        "probability": 0.72,
        "evidence": "80% no-shows получили письмо в 23:45"
      },
      {
        "hypothesis": "Конкурирующее событие в тот же день",
        "probability": 0.55,
        "evidence": "Трендит похожее событие в VK"
      }
    ],
    "recommendations": [ ... ]
  },
  "execution_time_ms": 3567
}
```

### Конфигурация

```yaml
# orchestration-config.yaml
gigachat:
  api_key: ${GIGACHAT_API_KEY}
  model: "GigaChat"
  temperature: 0.5
  max_tokens: 2000
  timeout_seconds: 30

agents:
  planning:
    endpoint: "http://planning-service:8080"
    timeout_seconds: 15
    retry_attempts: 2
  finance:
    endpoint: "http://finance-service:8080"
    timeout_seconds: 20
    retry_attempts: 2
  vendor:
    endpoint: "http://vendor-service:8080"
    timeout_seconds: 15
    retry_attempts: 2
  communication:
    endpoint: "http://communication-service:8080"
    timeout_seconds: 10
    retry_attempts: 3
  analytics:
    endpoint: "http://analytics-service:8080"
    timeout_seconds: 30
    retry_attempts: 2
  social_media:
    endpoint: "http://social-media-service:8080"
    timeout_seconds: 15
    retry_attempts: 2

kafka:
  brokers: ["kafka-1:9092", "kafka-2:9092", "kafka-3:9092"]
  group_id: "orchestration-service"
  topics:
    - "event.created"
    - "budget.created"
    - "vendor.selected"
    - "communication.sent"
    - "analytics.updated"
    - "social_media.monitored"

redis:
  host: "redis"
  port: 6379
  db: 0
  ttl_seconds: 300

logging:
  level: "INFO"
  format: "JSON"
  elasticsearch_host: "elasticsearch:9200"
```

---

## 2. PLANNING SERVICE

### Функциональность
- Создание event-планов и таймлайнов
- Генерация To-Do списков
- Управление этапами проекта
- Создание и применение шаблонов
- Управление зависимостями задач
- Создание критических путей (critical path)

### Технология
```
Language: Java 21
Framework: Spring Boot 3.2 + Spring Cloud
LLM: GigaChat 2.0
Dependencies:
  - spring-boot-starter-web
  - spring-boot-starter-data-jpa
  - spring-kafka
  - resttemplate
  - lombok
  - mapstruct
```

### API Endpoints

```
POST /api/v1/planning/events
  Input: EventCreateRequest
  Output: EventResponse

POST /api/v1/planning/events/{eventId}/plan
  Input: PlanGenerateRequest
  Output: PlanResponse

GET /api/v1/planning/events/{eventId}/timeline
  Output: TimelineResponse

GET /api/v1/planning/events/{eventId}/tasks
  Output: TaskListResponse

POST /api/v1/planning/tasks
  Input: TaskCreateRequest
  Output: TaskResponse

PUT /api/v1/planning/tasks/{taskId}
  Input: TaskUpdateRequest
  Output: TaskResponse

GET /api/v1/planning/templates
  Output: TemplateListResponse

GET /api/v1/planning/templates/{templateId}
  Output: TemplateResponse
```

### Структура данных

```java
@Entity
public class Event {
    @Id
    private String id;
    
    @Column(nullable = false)
    private String name;
    
    private String description;
    
    @Enumerated(EnumType.STRING)
    private EventType type;  // WEDDING, CONFERENCE, CORPORATE, etc.
    
    @Column(nullable = false)
    private LocalDateTime eventDate;
    
    private LocalDateTime eventEndDate;
    
    @Column(nullable = false)
    private String location;
    
    private Integer expectedGuests;
    
    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Task> tasks;
    
    @OneToOne(cascade = CascadeType.ALL)
    private Timeline timeline;
    
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;
}

@Entity
public class Task {
    @Id
    private String id;
    
    @Column(nullable = false)
    private String title;
    
    private String description;
    
    @Enumerated(EnumType.STRING)
    private TaskStatus status;  // NOT_STARTED, IN_PROGRESS, COMPLETED
    
    @Enumerated(EnumType.STRING)
    private TaskPriority priority;  // LOW, MEDIUM, HIGH, CRITICAL
    
    private String assignedTo;  // User ID
    
    private LocalDateTime dueDate;
    
    private Integer estimatedDaysToComplete;
    
    @ManyToMany
    private List<Task> dependencies;
    
    private Integer completionPercentage;
}

@Entity
public class Timeline {
    @Id
    private String id;
    
    @OneToMany(cascade = CascadeType.ALL)
    private List<TimelinePhase> phases;
    
    private LocalDateTime projectStartDate;
    
    private LocalDateTime projectEndDate;
    
    private Integer totalDaysNeeded;
}
```

### LLM Prompt Template

```
You are an expert event planner assistant. Generate a comprehensive event plan.

EVENT DETAILS:
- Name: {event_name}
- Type: {event_type}
- Date: {event_date}
- Location: {location}
- Expected Guests: {guest_count}
- Budget: {budget}

INSTRUCTIONS:
1. Create a detailed timeline from today until the event date
2. Break down into clear phases (pre-planning, venue selection, logistics, final preparations)
3. Generate specific, actionable tasks for each phase
4. Identify dependencies between tasks
5. Mark critical path items
6. Estimate time for each task

OUTPUT FORMAT:
{
  "timeline_phases": [
    {
      "phase_name": "",
      "start_date": "",
      "end_date": "",
      "description": "",
      "tasks": [
        {
          "title": "",
          "description": "",
          "priority": "HIGH|MEDIUM|LOW",
          "estimated_days": 0,
          "dependencies": []
        }
      ]
    }
  ],
  "critical_path_items": [],
  "recommendations": []
}

Generate realistic, practical, and detailed plan.
```

---

## 3. FINANCE SERVICE

### Функциональность
- Расчет и анализ смет
- ROI анализ
- Прогноз окупаемости
- Оптимизация цен
- Контроль бюджета (план/факт)
- Финансовые рекомендации

### Технология
```
Language: Java 21
Framework: Spring Boot 3.2
LLM: T-Pro API
Database: PostgreSQL + Numeric types
Analytics: Elasticsearch

Dependencies:
  - spring-boot-starter-data-jpa
  - spring-kafka
  - postgresql driver
  - elasticsearch-java
  - decimal4j (for financial calculations)
```

### API Endpoints

```
POST /api/v1/finance/events/{eventId}/budget
  Input: BudgetCalculationRequest
  Output: BudgetResponse

GET /api/v1/finance/events/{eventId}/budget
  Output: BudgetResponse

PUT /api/v1/finance/events/{eventId}/budget
  Input: BudgetUpdateRequest
  Output: BudgetResponse

POST /api/v1/finance/events/{eventId}/roi-analysis
  Input: ROIAnalysisRequest
  Output: ROIAnalysisResponse

GET /api/v1/finance/pricing-optimization
  Input: PricingOptimizationRequest
  Output: PricingOptimizationResponse

POST /api/v1/finance/budget-forecast
  Input: ForecastRequest
  Output: ForecastResponse

GET /api/v1/finance/budget-status/{eventId}
  Output: BudgetStatusResponse
```

### Примеры расчетов

**Смета на свадьбу 150 гостей:**
```
Категория                      План      Факт    Статус
─────────────────────────────────────────────────────────
Площадка                    250,000  250,000    ✓
Кейтеринг (150 x 2,000)     300,000  310,000    +10K
Декорация                   150,000  145,000    -5K
Музыка/DJ                    80,000   80,000    ✓
Фотография/видео            120,000  120,000    ✓
Цветы                        80,000   85,000    +5K
Приглашения/печать           30,000   28,000    -2K
─────────────────────────────────────────────────────────
ИТОГО:                    1,010,000 1,018,000  +8K (0.8%)
```

**ROI анализ:**
```
Event: Свадьба 150 человек
─────────────────────────────────────────────────────────
Инвестиции:              1,010,000 ₽
Цена билета:                 7,000 ₽
Ожидаемая явка:         140 человек
Доход:                 980,000 ₽
Net Profit:            -30,000 ₽ (LOSS)
ROI: -2.97%

RECOMMENDATION:
Увеличить цену до 8,000 ₽
Ожидаемая явка: 120 человек
Доход: 960,000 ₽
Net Profit: -50,000 ₽ (STILL LOSS)

OPTIMAL PRICE: 8,500 ₽ → Profit +200,000 ₽
```

---

## 4. VENDOR SERVICE

### Функциональность
- Поиск подрядчиков по параметрам
- Анализ и сравнение предложений
- Оценка качества поставщиков
- Ведение переговоров
- Управление контрактами

### Технология
```
Language: Node.js 20 LTS
Framework: NestJS
LLM: YandexGPT-4
Database: PostgreSQL + Elasticsearch

Dependencies:
  - @nestjs/common
  - typeorm
  - elasticsearch
  - axios
  - joi (validation)
```

### API Endpoints

```
GET /api/v1/vendors/search?category=catering&budget=500000&location=Moscow
  Output: VendorListResponse

GET /api/v1/vendors/{vendorId}
  Output: VendorDetailResponse

POST /api/v1/vendors/{vendorId}/request-quote
  Input: QuoteRequestRequest
  Output: QuoteResponse

GET /api/v1/vendors/comparison
  Input: { vendor_ids: [string] }
  Output: VendorComparisonResponse

POST /api/v1/vendors/contracts
  Input: ContractCreateRequest
  Output: ContractResponse

GET /api/v1/vendors/contracts/{contractId}
  Output: ContractResponse

PUT /api/v1/vendors/contracts/{contractId}/sign
  Input: ContractSignRequest
  Output: ContractResponse
```

### Категории подрядчиков

```
1. VENUE (Площадки)
   - Concert Halls
   - Banquet Halls
   - Outdoor Venues
   - Studios

2. CATERING (Кейтеринг)
   - Fine Dining
   - Casual Catering
   - Dessert Specialists
   - Beverage Services

3. DECORATION (Декор)
   - Florists
   - Design Studios
   - Lighting Specialists
   - Theme Designers

4. ENTERTAINMENT (Развлечение)
   - DJ Services
   - Live Bands
   - Photographers
   - Videographers
   - Animation Specialists

5. LOGISTICS (Логистика)
   - Transport Services
   - Equipment Rental
   - Setup Services
   - Cleanup Services

6. TECHNICAL (Техника)
   - Sound Systems
   - Lighting Equipment
   - Video Projection
   - Microphone Systems
```

---

## 5. COMMUNICATION SERVICE

### Функциональность
- Чат с клиентами (24/7)
- Генерация коммерческих предложений
- Создание маркетинговых текстов
- Email и рассылки
- Управление FAQ

### Технология
```
Language: Node.js 20 LTS
Framework: NestJS
LLM: Cotype
Real-time: Socket.io
Message Queue: RabbitMQ

Dependencies:
  - @nestjs/websockets
  - @nestjs/microservices
  - socket.io
  - amqplib
  - nodemailer
```

### API Endpoints

```
WS /ws/chat/{sessionId}
  Events:
    - message_new
    - message_read
    - typing_indicator
    - agent_joined
    - agent_left

POST /api/v1/communication/chat
  Input: ChatMessageRequest
  Output: ChatMessageResponse

GET /api/v1/communication/messages
  Query: ?session_id=&limit=50&offset=0
  Output: ChatHistoryResponse

POST /api/v1/communication/proposals
  Input: ProposalGenerateRequest
  Output: ProposalResponse

POST /api/v1/communication/email-send
  Input: EmailRequest
  Output: EmailResponse

GET /api/v1/communication/faq
  Output: FAQListResponse

POST /api/v1/communication/faq
  Input: FAQCreateRequest
  Output: FAQResponse
```

### Chat Flow

```
┌─────────────────────────────┐
│ User sends message via chat │
└────────────┬────────────────┘
             │
             ▼
     ┌──────────────────┐
     │ Communication   │
     │ Service        │ ← WebSocket
     └────────┬────────┘
              │
              ▼
     ┌──────────────────────────┐
     │ Maestro Agent            │
     │ Intent Classification    │
     └────┬─────────┬───────┬──┘
          │         │       │
    ┌─────▼─┐  ┌───▼──┐  ┌─▼────┐
    │ FAQ?  │  │Issue?│  │Query?│
    │YES    │  │YES   │  │YES   │
    └─┬─────┘  └───┬──┘  └──┬───┘
      │            │        │
      ▼            ▼        ▼
    FAQ        Ticket   Route to
    Answer     Created  Agent/Bot
      │            │        │
      └────────┬───┴────┬───┘
               │        │
               ▼        ▼
        ┌───────────────────┐
        │ Generate Response │
        │ (Cotype LLM)      │
        └────────┬──────────┘
                 │
                 ▼
        ┌───────────────────┐
        │ Save to DB &      │
        │ Send to User      │
        │ WebSocket         │
        └───────────────────┘
```

---

## 6. ANALYTICS SERVICE

### Функциональность
- Анализ ROI и эффективности
- Анализ конверсии (воронка)
- Генерация гипотез
- Аномалия-детекция
- Прогнозирование результатов

### Технология
```
Language: Python 3.11
Framework: FastAPI
LLM: T-Pro + Qwen-3
ML: TensorFlow, Scikit-learn
Database: PostgreSQL + Timescale

Dependencies:
  - fastapi
  - sqlalchemy
  - scikit-learn
  - tensorflow
  - elasticsearch
  - pandas
  - numpy
```

### API Endpoints

```
GET /api/v1/analytics/events/{eventId}/roi
  Output: ROIAnalysisResponse

GET /api/v1/analytics/events/{eventId}/conversion-funnel
  Output: ConversionFunnelResponse

GET /api/v1/analytics/events/{eventId}/hypotheses
  Output: HypothesesResponse

GET /api/v1/analytics/events/{eventId}/anomalies
  Output: AnomaliesResponse

GET /api/v1/analytics/predictions
  Input: PredictionRequest
  Output: PredictionResponse

POST /api/v1/analytics/custom-report
  Input: CustomReportRequest
  Output: ReportResponse
```

### Примеры анализа

**Конверсия:**
```
Регистрации: 1000
Отправлено напоминания: 900 (90%)
Открыли письмо: 720 (80% from sent)
Кликнули по ссылке: 540 (75% from opened)
Пришли: 100 (18.5% from clicked)

Funnel:
1000 → 900 → 720 → 540 → 100

Основные drop-points:
1. Регистрация → Напоминание: 10% (100 loss) - OK
2. Письмо → Open: 20% (180 loss) - NEEDS WORK
3. Click → Arrival: 81.5% (440 loss) - CRITICAL

Гипотезы:
- Плохой subject line письма
- Неправильное время отправки
- Конкурирующее событие
- Неверная целевая аудитория
```

---

## 7. SOCIAL MEDIA SERVICE

### Функциональность
- Мониторинг упоминаний в соцсетях
- Sentiment-анализ
- Выявление ключевых тем
- Создание отчетов
- Управление репутацией

### Технология
```
Language: Python 3.11
Framework: FastAPI
LLM: GigaChat MultiModal
ML: Hugging Face Transformers
Database: PostgreSQL + Elasticsearch

Dependencies:
  - fastapi
  - vk-api
  - facebook-sdk
  - tweepy (Twitter)
  - transformers (HuggingFace)
  - kafka-python
```

### API Endpoints

```
GET /api/v1/social-media/events/{eventId}/mentions
  Query: ?source=vk,facebook,instagram&sentiment=all
  Output: MentionListResponse

GET /api/v1/social-media/events/{eventId}/sentiment
  Output: SentimentAnalysisResponse

GET /api/v1/social-media/events/{eventId}/trending-topics
  Output: TrendingTopicsResponse

POST /api/v1/social-media/monitoring-start
  Input: MonitoringRequest
  Output: MonitoringResponse

GET /api/v1/social-media/reports/{reportId}
  Output: ReportResponse

POST /api/v1/social-media/alerts
  Input: AlertConfigRequest
  Output: AlertResponse
```

### Sentiment Analysis Example

```
Event: "Конференция по AI"
Monitoring Period: 7 дней

Total Mentions: 1,247

Sentiment Breakdown:
├─ Positive: 892 (71.5%) ✓
│  └─ "Отличная конференция!"
│  └─ "Спасибо за уникальное событие"
│
├─ Neutral: 285 (22.8%)
│  └─ "Был на конференции"
│  └─ "Информация о времени..."
│
└─ Negative: 70 (5.6%) ⚠️
   └─ "Очень дорого"
   └─ "Плохая организация"
   └─ "Долгие перерывы"

Trending Topics:
1. "#AI2025" (342 mentions)
2. "machine learning" (198 mentions)
3. "neural networks" (156 mentions)
4. "speakers" (89 mentions)

Key Issues to Address:
1. Price sensitivity (mentioned 23 times)
2. Organization & timing (mentioned 18 times)
3. Venue issues (mentioned 12 times)
```

---

## DEPLOYMENT CONFIGURATION

### Environment Variables

```bash
# Orchestration Service
GIGACHAT_API_KEY=your_key
GIGACHAT_TIMEOUT=30
LOG_LEVEL=INFO

# Planning Service
JAVA_OPTS=-Xmx2G -Xms1G
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/events
SPRING_DATASOURCE_USERNAME=user
SPRING_DATASOURCE_PASSWORD=pass

# Finance Service
TPRO_API_KEY=your_key
SPRING_ELASTICSEARCH_HOST=elasticsearch:9200

# Communication Service
COTYPE_API_KEY=your_key
SENDGRID_API_KEY=your_key
RABBIT_HOST=rabbitmq
RABBIT_PORT=5672

# Analytics Service
TIMESCALE_URL=postgresql://user:pass@postgres:5432/events
ELASTICSEARCH_HOST=elasticsearch:9200

# Social Media Service
VK_API_TOKEN=your_token
FACEBOOK_API_TOKEN=your_token
INSTAGRAM_API_TOKEN=your_token
TELEGRAM_API_TOKEN=your_token
```

---

## MONITORING & ALERTING

### Метрики по микросервису

```
orchestration-service:
  ├─ request_count{service="orchestration"}
  ├─ request_latency_ms{p50, p95, p99}
  ├─ intent_classification_accuracy
  ├─ agent_routing_success_rate
  ├─ gigachat_api_latency_ms
  ├─ error_rate

planning-service:
  ├─ event_creation_count
  ├─ plan_generation_latency_ms
  ├─ timeline_generation_accuracy
  ├─ db_query_latency_ms
  └─ kafka_publish_success_rate

finance-service:
  ├─ budget_calculation_count
  ├─ calculation_accuracy_percent
  ├─ roi_analysis_latency_ms
  ├─ price_optimization_requests
  └─ financial_data_consistency

vendor-service:
  ├─ vendor_search_count
  ├─ search_result_quality_score
  ├─ elasticsearch_query_latency_ms
  ├─ contract_management_count
  └─ vendor_database_size

communication-service:
  ├─ chat_messages_per_minute
  ├─ message_response_latency_ms
  ├─ proposal_generation_count
  ├─ email_send_success_rate
  ├─ websocket_active_connections
  └─ cotype_llm_latency_ms

analytics-service:
  ├─ report_generation_count
  ├─ analysis_latency_ms
  ├─ hypothesis_generation_count
  ├─ anomaly_detection_rate
  ├─ prediction_accuracy_percent
  └─ elasticsearch_indexing_latency_ms

social-media-service:
  ├─ mentions_scraped_per_hour
  ├─ sentiment_analysis_latency_ms
  ├─ api_integration_success_rate
  ├─ kafka_consumer_lag_seconds
  └─ database_storage_used_gb
```

### Alarms

```yaml
- name: HighLatency
  condition: request_latency_ms{p95} > 5000
  severity: WARNING
  action: notify_team

- name: HighErrorRate
  condition: error_rate > 0.05
  severity: CRITICAL
  action: page_oncall

- name: ServiceDown
  condition: up{job=~".*-service"} == 0
  severity: CRITICAL
  action: page_oncall, slack_notification

- name: LowAccuracy
  condition: intent_classification_accuracy < 0.85
  severity: WARNING
  action: notify_ml_team

- name: KafkaLag
  condition: kafka_consumer_lag_seconds > 300
  severity: WARNING
  action: investigate_message_queue
```

---

## ЗАКЛЮЧЕНИЕ

Архитектура микросервисов позволяет:

✅ Независимо масштабировать каждый сервис  
✅ Использовать оптимальный язык/фреймворк для каждой задачи  
✅ Быстро деплоить обновления отдельных сервисов  
✅ Изолировать ошибки и сбои  
✅ Параллельно развивать разные компоненты  
✅ Легко интегрировать новые ИИ-модели  

Все сервисы готовы к production-использованию и могут обрабатывать тысячи мероприятий в день.
