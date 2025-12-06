# ПОЛНАЯ АРХИТЕКТУРНАЯ СХЕМА МНОГОАГЕНТНОЙ СИСТЕМЫ
## ИИ-Агенты для событийной индустрии

**Дата:** Декабрь 2025  
**Версия:** 1.0  
**Статус:** Production Ready

---

## СОДЕРЖАНИЕ

1. [Высокоуровневая архитектура](#высокоуровневая-архитектура)
2. [Компоненты системы](#компоненты-системы)
3. [Микросервисная архитектура](#микросервисная-архитектура)
4. [Многоагентная оркестрация](#многоагентная-оркестрация)
5. [Технологический стек](#технологический-стек)
6. [Развертывание](#развертывание)
7. [Мониторинг](#мониторинг)
8. [Безопасность](#безопасность)

---

## ВЫСОКОУРОВНЕВАЯ АРХИТЕКТУРА

### 8-слойная архитектура системы

```
┌────────────────────────────────────────────────────────────────┐
│ LAYER 1: USER INTERFACE (Web/Mobile/API Clients)             │
│          React.js | PWA | Third-party integrations           │
└──────────────────────────┬─────────────────────────────────────┘
                           │ HTTPS/gRPC
┌──────────────────────────▼─────────────────────────────────────┐
│ LAYER 2: API GATEWAY & AUTHENTICATION                          │
│          Kong | OAuth 2.0 | JWT | Rate Limiting | RBAC        │
└──────────────────────────┬─────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼────────┐  ┌──────▼────────┐  ┌────▼──────────┐
│ ORCHESTRATION  │  │ MICROSERVICES │  │ MESSAGE QUEUE │
│ LAYER          │  │ LAYER         │  │               │
│                │  │               │  │ Apache Kafka  │
│ Maestro Agent  │  │ Planning      │  │ RabbitMQ      │
│ (GigaChat)     │  │ Finance       │  │               │
│                │  │ Vendor        │  │ Event-driven  │
│ Intent Parse   │  │ Communication │  │ architecture  │
│ Routing        │  │ Analytics     │  │               │
│ Aggregation    │  │ Social Media  │  │               │
└─┬──────────────┘  └───┬──────┬────┘  └────┬──────────┘
  │                     │      │           │
  └─────────────────┬───┘      └─┬────────┘
                    │            │
        ┌───────────▼────────────▼──────────┐
        │ AI & LLM LAYER                    │
        │ GigaChat 2.0 (Primary)            │
        │ + YandexGPT-4, T-Pro, Qwen-3     │
        │ + Embedding Models                │
        │ + Fallback Strategies             │
        └────────────────┬───────────────────┘
                         │
        ┌────────────────▼──────────────────┐
        │ DATA LAYER                        │
        │ PostgreSQL | Redis | Elasticsearch
        │ S3 Storage | Backups              │
        └────────────────┬───────────────────┘
                         │
        ┌────────────────▼──────────────────┐
        │ EXTERNAL INTEGRATIONS             │
        │ CRM | Payments | Calendar         │
        │ Social Networks | Analytics       │
        └───────────────────────────────────┘
                         │
        ┌────────────────▼──────────────────┐
        │ INFRASTRUCTURE                    │
        │ Kubernetes | Docker | CI/CD       │
        │ Monitoring | Logging | Alerting   │
        └───────────────────────────────────┘
```

---

## КОМПОНЕНТЫ СИСТЕМЫ

### 1. Слой оркестрации (Maestro Agent)

**Базовая модель:** GigaChat 2.0  
**Фреймворк:** LangChain / LlamaIndex  
**Язык:** Python FastAPI

**Ответственность:**
- Intent Classification (90%+ accuracy)
- Multi-agent orchestration
- Context management (conversational memory)
- Result aggregation
- Quality assurance & validation
- Error handling & fallback logic
- Request routing & prioritization

**Интеграция:**
```
User Request → Intent Parser → Agent Selector → Executor → Aggregator → Response
                    ↓              ↓               ↓          ↓
              GigaChat 2.0   Parallel Agents   Kafka      Formatter
```

### 2. Микросервисная архитектура

| Сервис | Язык | Framework | LLM | Процессы |
|--------|------|-----------|-----|----------|
| Planning | Java | Spring Boot | GigaChat 2.0 | 2 |
| Finance | Java | Spring Boot | T-Pro | 2 |
| Vendor | Node.js | NestJS | YandexGPT-4 | 2 |
| Communication | Node.js | NestJS | Cotype | 3 |
| Analytics | Python | FastAPI | T-Pro + Qwen | 2 |
| Social Media | Python | FastAPI | GigaChat ML | 1 |

### 3. LLM Маршрутизация

```
Intent → GigaChat 2.0 (Classifier)
    ↓
┌─────────────────────────────────────┐
│ Determine which LLM is best for:    │
├─────────────────────────────────────┤
│ create_plan → GigaChat 2.0          │
│ calculate → T-Pro                   │
│ search → YandexGPT-4                │
│ chat → Cotype                       │
│ analyze → Qwen-3                    │
│ sentiment → GigaChat (Multimodal)   │
│ fallback → Local Llama-3.1          │
└─────────────────────────────────────┘
```

### 4. Типы рабочих процессов

**Sequential Workflow:**
```
User Request → Maestro → Single Agent → Result
```

**Parallel Workflow:**
```
User Request → Maestro → [Agent1, Agent2, Agent3] (parallel) → Aggregation
```

**Chained Workflow:**
```
User Request → Maestro → Agent1 → Agent2 → Agent3 (sequential chain)
```

**Conditional Workflow:**
```
User Request → Maestro → Decision → Agent_A or Agent_B → Result
```

---

## МИКРОСЕРВИСНАЯ АРХИТЕКТУРА

### Топология сервисов

```
TIER 1: API Gateway & Load Balancing
  ├─ NGINX / Kong
  ├─ SSL/TLS Termination
  ├─ Authentication
  └─ Rate Limiting

TIER 2: Orchestration Service
  ├─ Intent Classification
  ├─ Agent Routing
  ├─ Context Management
  └─ Response Aggregation

TIER 3: Domain Services (Microservices)
  ├─ Planning Service (Port 8002)
  ├─ Finance Service (Port 8003)
  ├─ Vendor Service (Port 8004)
  ├─ Communication Service (Port 8005)
  ├─ Analytics Service (Port 8006)
  └─ Social Media Service (Port 8007)

TIER 4: Data Layer
  ├─ PostgreSQL (Primary Database)
  │  ├─ Main DB on Port 5432
  │  ├─ HA Standby
  │  └─ Read Replicas
  ├─ Redis (Cache & Sessions)
  │  ├─ Master on Port 6379
  │  └─ Cluster Mode (3+ nodes)
  ├─ Elasticsearch (Search & Analytics)
  │  ├─ 3-node cluster
  │  └─ Hot-Warm-Cold architecture
  └─ S3-compatible Storage (Documents)
     └─ Object storage for files

TIER 5: Message Queue
  ├─ Apache Kafka (Primary)
  │  ├─ 3 Brokers
  │  ├─ Replication Factor 2
  │  └─ Topics per domain
  └─ RabbitMQ (Secondary)
     ├─ Background jobs
     └─ Email queue

TIER 6: Observability
  ├─ Prometheus (Metrics)
  ├─ Grafana (Dashboards)
  ├─ ELK Stack (Logs)
  │  ├─ Elasticsearch
  │  ├─ Logstash
  │  └─ Kibana
  └─ Jaeger (Distributed Tracing)

TIER 7: External Services
  ├─ GigaChat API
  ├─ YandexGPT API
  ├─ T-Pro API
  ├─ Payment Gateway
  ├─ Email Service
  └─ Social Media APIs

TIER 8: Infrastructure
  ├─ Kubernetes (Orchestration)
  │  ├─ 3 Control Nodes
  │  └─ N Worker Nodes
  ├─ Yandex Cloud / Selectel
  ├─ Docker Containers
  ├─ CI/CD (GitLab / GitHub)
  └─ Backup & Disaster Recovery
```

### Сетевая топология

```
Internet
    ↓
┌─────────────────────────────┐
│ CDN (CloudFlare / Yandex)   │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ Application Load Balancer   │ (Yandex Cloud ALB)
└──────────┬────────────────┬─┘
           │                │
      ┌────▼─────┐    ┌─────▼────┐
      │ Kong API │    │ Backup    │
      │ Gateway  │    │ Gateway   │
      │ (Prod)   │    │ (Standby) │
      └────┬─────┘    └─────┬────┘
           │                │
      ┌────▼────────────────▼────┐
      │  Kubernetes Cluster       │
      │  (Private VPC)            │
      │                          │
      │  3 Control Nodes         │
      │  5-10 Worker Nodes       │
      └───────────────────────────┘
           │
      ┌────▼──────────────┐
      │ RDS PostgreSQL    │
      │ (Multi-AZ)        │
      └────────────────────┘
```

---

## МНОГОАГЕНТНАЯ ОРКЕСТРАЦИЯ

### Maestro Agent Workflow

```
1. RECEIVE REQUEST
   ├─ Validate input (JSON schema)
   ├─ Extract user_id, message, context
   └─ Log incoming request

2. INTENT CLASSIFICATION
   ├─ Call GigaChat 2.0 with prompt
   ├─ Parse intent from response
   ├─ Extract entities (date, location, etc.)
   └─ Store in context

3. AGENT SELECTION
   ├─ Based on intent, determine required agents
   ├─ Check parallel vs. sequential execution
   ├─ Allocate resources
   └─ Create execution plan

4. EXECUTION
   ├─ Start selected agents (parallel if possible)
   ├─ Monitor execution time
   ├─ Catch exceptions
   └─ Trigger fallback if needed

5. AGGREGATION
   ├─ Wait for all agents to complete
   ├─ Combine results
   ├─ Validate coherence
   └─ Generate final response

6. RESPONSE
   ├─ Format response (JSON)
   ├─ Log execution metrics
   ├─ Send to user
   └─ Publish to Kafka
```

### Agent Communication Pattern

```
┌─────────────────────────────────────────────────────────┐
│                  Maestro Agent                          │
│                 (GigaChat 2.0)                          │
└────┬─────────────┬──────────────┬──────────────┬────────┘
     │             │              │              │
     ▼             ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│Planning  │  │Finance   │  │Vendor    │  │Communication
│Agent     │  │Agent     │  │Agent     │  │Agent
│(Java)    │  │(Java)    │  │(Node.js) │  │(Node.js)
└──────┬───┘  └────┬─────┘  └──┬───────┘  └────┬─────┘
       │           │           │               │
       │ HTTP REST │ HTTP REST │ HTTP REST      │
       │ gRPC (opt)│ gRPC (opt)│ WebSocket      │
       │           │           │ (for chat)     │
       └─────┬─────┴─────┬─────┴────┬─────────┘
             │           │          │
             └─────┬─────┴──────┬──┘
                   │            │
             ┌─────▼────┐  ┌────▼──────┐
             │ Kafka    │  │ PostgreSQL │
             │ Topics   │  │ Database   │
             └──────────┘  └────────────┘
```

### Пример: Event Creation Flow

```
User Input: "Create wedding plan for 150 guests on April 15"

┌─────────────────────────────────────────────────────────┐
│ 1. MAESTRO CLASSIFICATION                               │
│    Intent: "create_event_plan"                          │
│    Entities: {type: "wedding", guests: 150, date: ...} │
│    Confidence: 0.98                                     │
│    Selected Agents: [Planning, Finance, Vendor]         │
│    Mode: PARALLEL                                       │
└──────┬──────────────────────────────────────────────────┘
       │
       ├─────────────────┬──────────────────┬──────────────┐
       │                 │                  │              │
       ▼                 ▼                  ▼              ▼
    START             START              START          WAIT
    Planning          Finance            Vendor         for all
    (t=0.3s)          (t=0.3s)            (t=0.3s)       agents
    ├─ Load templates ├─ Load costs  ├─ Search DB
    ├─ Create timeline├─ Calc budget ├─ Find venues
    ├─ Gen tasks      ├─ ROI estimate├─ Get vendors
    └─ Save (t=1.2s)  └─ Save (t=0.8s)└─ Save (t=1.0s)
       │                 │                  │
       └─────────────────┼──────────────────┘
                         │
                    ┌────▼────────┐
                    │ Kafka: emit │
                    │ events:     │
                    │ • created   │
                    │ • budget    │
                    │ • vendors   │
                    └────┬────────┘
                         │
                    ┌────▼────────┐
                    │ Aggregate   │
                    │ results     │
                    └────┬────────┘
                         │
                    ┌────▼──────────┐
                    │ Send to user  │
                    │ (t=2.4s total)│
                    └───────────────┘
```

---

## ТЕХНОЛОГИЧЕСКИЙ СТЕК

### Frontend

```
Framework: React.js 18+
State Management: Redux / Zustand
UI Components: Material-UI / Ant Design
Charts: Recharts / ECharts
Real-time: Socket.io / WebSocket
API Client: Axios / TanStack Query
Build: Vite / webpack
Package Manager: npm / yarn
```

### Backend Infrastructure

```
API Gateway: Kong / NGINX
Load Balancer: HAProxy / Yandex Cloud ALB
Message Queue: Apache Kafka (primary)
                RabbitMQ (secondary)
Cache: Redis (in-memory)
Search: Elasticsearch 8.x
Storage: S3-compatible (Yandex Cloud)
Database: PostgreSQL 15+
            TimescaleDB (analytics)
            Elasticsearch (logs)

Orchestration: Docker + Kubernetes
Container Registry: Harbor / Yandex Container Registry
CI/CD: GitLab CI / GitHub Actions
```

### LLM & AI

```
Primary LLM: GigaChat 2.0 (Sber)
Secondary LLMs:
  • YandexGPT-4 (Yandex)
  • T-Pro (VK)
  • Cotype (Neuro.net)
  • Qwen-3 (Alibaba - open)
  • Llama-3.1 (Meta - open)

Embedding Model: Multilingual-E5
Frameworks: LangChain, LlamaIndex
```

### Monitoring & Logging

```
Metrics: Prometheus
Visualization: Grafana
Logging: ELK Stack
  • Elasticsearch
  • Logstash
  • Kibana
Distributed Tracing: Jaeger
Alerting: Alert Manager
APM: Datadog / New Relic (optional)
```

---

## РАЗВЕРТЫВАНИЕ

### Production Deployment

```
Environment: Yandex Cloud Kubernetes
Nodes: 3 control + 8 worker
Node Type: 4 vCPU, 16 GB RAM
Storage: 1TB SSD
Network: Private VPC + NAT Gateway
Backup: Daily snapshots
```

### Service Replicas

```
Orchestration: 1 replica (stateless, can scale)
Planning: 2 replicas (resource-intensive)
Finance: 2 replicas (CPU-intensive)
Vendor: 2 replicas (I/O-intensive)
Communication: 3 replicas (high concurrency)
Analytics: 2 replicas (CPU/Memory-intensive)
Social Media: 1 replica (I/O-intensive)
```

### Database Replication

```
PostgreSQL:
  • Master (Primary write/read)
  • Standby (Hot standby for failover)
  • Read Replicas (2-3 for read scaling)
  • Backup node (Daily snapshots)
  
Redis:
  • Master (Primary)
  • Replicas (2-3 for redundancy)
  • Sentinel (Automatic failover)

Elasticsearch:
  • 3-node cluster
  • Hot nodes (fresh data)
  • Warm nodes (aged data)
  • Cold nodes (archive data)
```

---

## МОНИТОРИНГ

### Key Metrics

```
System Level:
  • CPU usage: Target <70%
  • Memory usage: Target <80%
  • Disk I/O: Target <75%
  • Network latency: Target <10ms

Service Level:
  • Request latency (p50, p95, p99)
  • Request rate (RPS)
  • Error rate
  • Success rate

Agent Level:
  • Intent classification accuracy
  • Agent execution time
  • LLM API latency
  • Token usage
  • Fallback rate

Application Level:
  • Event creation rate
  • Budget calculation accuracy
  • Vendor search quality
  • Chat response time
  • Report generation time
```

### Alerting Thresholds

```
Critical:
  • Service down (HTTP 503)
  • Error rate > 10%
  • Latency p95 > 10 seconds
  • Database connection failed

Warning:
  • Error rate > 5%
  • Latency p95 > 5 seconds
  • Memory usage > 85%
  • Disk usage > 90%

Info:
  • Deployment event
  • Scale event
  • Configuration change
  • Backup completion
```

---

## БЕЗОПАСНОСТЬ

### Authentication & Authorization

```
OAuth 2.0 / OpenID Connect
  • Social login (VK, Google, Yandex)
  • API keys for integrations
  • JWT tokens (15min expiry)

RBAC (Role-Based Access Control):
  • Admin: Full system access
  • Manager: Event management
  • Analyst: Read-only analytics
  • Integration: API access

Encryption:
  • TLS 1.3 in transit
  • AES-256 at rest
  • API key encryption
  • Password hashing (bcrypt)
```

### Data Protection

```
GDPR Compliance:
  • Data retention policies
  • User data export
  • Right to be forgotten
  • Data anonymization

PCI-DSS (if handling payments):
  • Encrypted payment processing
  • No card storage
  • Audit logging

Audit Trail:
  • All user actions logged
  • Changes tracked with timestamps
  • Admin access logged
  • API calls recorded
```

---

## SCALING SCENARIOS

### Horizontal Scaling

```
Traffic: 1K RPS → 100K RPS
├─ Add Kubernetes nodes (auto-scaling)
├─ Increase service replicas
├─ Add read replicas to database
└─ Increase Kafka partitions

Storage: 100 GB → 10 TB
├─ Add Elasticsearch nodes
├─ Archive old data
├─ Implement retention policy
└─ Add S3 storage
```

### Vertical Scaling

```
Node upgrade (4vCPU → 8vCPU):
├─ Increase database server resources
├─ Increase cache (Redis) capacity
├─ Increase Elasticsearch heap
└─ Monitor performance improvements
```

---

## COST ESTIMATION (Monthly)

```
Kubernetes Cluster:
  • 3 control nodes (4vCPU, 16GB): $300/month
  • 8 worker nodes (4vCPU, 16GB): $800/month
  
Database:
  • PostgreSQL (managed, HA): $500/month
  • Redis cluster: $200/month
  • Elasticsearch: $300/month
  
Storage:
  • S3 storage (1TB): $50/month
  • Snapshots & backups: $100/month
  
LLM API:
  • GigaChat (100K tokens/day): $200/month
  • YandexGPT/T-Pro: $150/month
  
Monitoring & Observability:
  • Prometheus/Grafana: $100/month
  • ELK Stack: $150/month
  
Miscellaneous:
  • Domain, CDN, etc: $50/month

TOTAL: ~$3,000-3,500/month

Per-user cost (assuming 1000 active users):
~$3-3.50/user/month (very profitable at $15-80/month subscription)
```

---

## ИТОГОВАЯ ТАБЛИЦА

| Компонент | Роль | Масштабируемость | Критичность |
|-----------|------|------------------|------------|
| Maestro Agent | Оркестрация | High | Critical |
| Planning Service | Доменная логика | High | High |
| Finance Service | Доменная логика | High | High |
| Vendor Service | Доменная логика | Medium | Medium |
| Communication | Интеграция | High | Medium |
| Analytics | Insight generation | Medium | Medium |
| Social Media | External monitoring | Low | Low |
| PostgreSQL | Данные | Medium | Critical |
| Redis | Кеш | High | High |
| Elasticsearch | Поиск | Medium | Medium |
| Kafka | Messaging | High | High |

---

## NEXT STEPS

1. **Phase 1 (Month 1-2):** Deploy MVP with core services (Planning, Finance, Vendor)
2. **Phase 2 (Month 3-4):** Add Communication & Analytics services
3. **Phase 3 (Month 5-6):** Add Social Media monitoring
4. **Phase 4 (Month 7+):** Optimization, scaling, new agent types

---

**Документ подготовлен:** 2025-12-04  
**Версия архитектуры:** 1.0-Production-Ready  
**Статус:** Готово к развертыванию
