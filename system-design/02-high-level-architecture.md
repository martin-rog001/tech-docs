# System Design: High-Level Architecture

## Overview

High-level architecture provides a bird's-eye view of the system, showing major components, their interactions, and data flow. This phase translates requirements into an architectural blueprint. For SRE interviews, demonstrating clear architectural thinking and the ability to communicate complex systems simply is crucial.

---

## 1. Architecture Fundamentals

### What is High-Level Architecture?

**Description:** High-level architecture defines the major building blocks of a system and how they interact. It focuses on components, not implementation details. Think "what and how they connect" not "how implemented internally." The goal is to show you can decompose a complex problem into manageable, scalable pieces.

**Key Elements:**
- **Components:** Distinct functional units (web servers, databases, caches)
- **Connections:** How components communicate (REST, gRPC, message queues)
- **Data Flow:** How data moves through the system
- **External Dependencies:** Third-party services (payment gateway, CDN)
- **Infrastructure:** Hosting approach (cloud regions, availability zones)

**Why Start High-Level:**
- Establishes common understanding with interviewer
- Identifies major technical decisions early
- Provides framework for deep dives
- Shows ability to abstract and organize complexity

---

## 2. Common Architecture Patterns

### Monolithic Architecture

**Description:** Single unified application where all components are tightly coupled and run as one unit. All code deployed together in a single process.

**Structure:**
```
                    ┌─────────────────────────────┐
                    │     Load Balancer (ALB)     │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
         ┌──────────▼─────────┐       ┌──────────▼─────────┐
         │  Monolithic App    │       │  Monolithic App    │
         │  ┌──────────────┐  │       │  ┌──────────────┐  │
         │  │ UI Layer     │  │       │  │ UI Layer     │  │
         │  │ Business     │  │       │  │ Business     │  │
         │  │ Logic        │  │       │  │ Logic        │  │
         │  │ Data Access  │  │       │  │ Data Access  │  │
         │  └──────────────┘  │       │  └──────────────┘  │
         └──────────┬─────────┘       └──────────┬─────────┘
                    │                             │
                    └──────────────┬──────────────┘
                                   │
                         ┌─────────▼─────────┐
                         │   Database (RDS)  │
                         └───────────────────┘
```

**Pros:**
- Simple to develop and deploy
- Easy to test (single codebase)
- Straightforward debugging
- No network latency between components
- ACID transactions across all operations

**Cons:**
- Tight coupling makes changes risky
- Single point of failure
- Must scale entire application (can't scale parts independently)
- Limited technology choices (one language/framework)
- Large team coordination overhead
- Slow CI/CD (entire app deployed each time)

**When to Use:**
- Small teams (< 10 developers)
- Simple applications
- Early-stage startups (MVP)
- Well-defined, stable requirements
- Limited scale (< 10K DAU)

**AWS Implementation:**
- EC2 instances with Auto Scaling Group
- Application Load Balancer
- RDS (PostgreSQL/MySQL)
- ElastiCache for caching
- S3 for static assets

---

### Microservices Architecture

**Description:** Application decomposed into small, independent services that communicate over the network. Each service owns its data and business logic for a specific domain.

**Structure:**
```
                         ┌─────────────────┐
                         │   API Gateway   │
                         │  (API Gateway)  │
                         └────────┬────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
   ┌────▼─────┐            ┌─────▼──────┐          ┌──────▼─────┐
   │  User    │            │   Order    │          │  Payment   │
   │ Service  │            │  Service   │          │  Service   │
   └────┬─────┘            └─────┬──────┘          └──────┬─────┘
        │                        │                        │
   ┌────▼─────┐            ┌─────▼──────┐          ┌──────▼─────┐
   │ User DB  │            │  Order DB  │          │ Payment DB │
   │(DynamoDB)│            │   (RDS)    │          │   (RDS)    │
   └──────────┘            └────────────┘          └────────────┘
```

**Pros:**
- Independent deployment (service by service)
- Technology flexibility (polyglot)
- Independent scaling (scale what's needed)
- Fault isolation (failure contained to service)
- Team autonomy (own service end-to-end)
- Better for large teams

**Cons:**
- Increased complexity (distributed system)
- Network latency and failures
- Distributed transactions hard (eventual consistency)
- Testing more difficult (integration tests)
- Operational overhead (more services to monitor)
- Data consistency challenges

**When to Use:**
- Large teams (> 10 developers)
- Complex domains with clear boundaries
- Need independent scaling of components
- High availability requirements
- Rapid iteration needed
- Large scale (> 100K DAU)

**AWS Implementation:**
- ECS/EKS for container orchestration
- API Gateway for unified entry point
- Multiple RDS/DynamoDB per service
- SQS/SNS for async communication
- Service Mesh (App Mesh) for service discovery
- CloudWatch for distributed tracing (X-Ray)

---

### Event-Driven Architecture

**Description:** Components communicate through events published to message brokers. Services react to events asynchronously, enabling loose coupling and high scalability.

**Structure:**
```
  ┌───────────┐         ┌─────────────────┐         ┌───────────┐
  │  Order    │  Event  │   Event Bus     │  Event  │  Email    │
  │  Service  ├────────►│  (SNS/EventB.)  ├────────►│  Service  │
  └───────────┘         └────────┬────────┘         └───────────┘
                                 │
                          Event  │
                                 │
                        ┌────────▼────────┐
                        │  Inventory      │
                        │  Service        │
                        └─────────────────┘
```

**Pros:**
- Loose coupling (producers don't know consumers)
- High scalability (async processing)
- Resilience (failures don't block producers)
- Flexibility (easy to add new consumers)
- Natural fit for complex workflows

**Cons:**
- Eventual consistency
- Debugging is harder (trace across events)
- Event versioning and schema evolution
- Potential for event storms
- Ordering guarantees complex

**When to Use:**
- Complex workflows with many steps
- Need to notify multiple systems
- High throughput requirements
- Decoupled services important
- Async processing acceptable

**AWS Implementation:**
- EventBridge for event routing
- SNS/SQS for pub/sub messaging
- Kinesis for streaming data
- Lambda for event processing
- Step Functions for workflow orchestration
- DynamoDB Streams for database events

---

### Serverless Architecture

**Description:** Application built using managed services and functions-as-a-service (FaaS). No server management; cloud provider handles scaling and infrastructure.

**Structure:**
```
  ┌──────────┐      ┌─────────────┐      ┌──────────┐
  │  Client  ├─────►│ API Gateway ├─────►│  Lambda  │
  └──────────┘      └─────────────┘      │ Function │
                                          └────┬─────┘
                                               │
                    ┌──────────────────────────┼────────┐
                    │                          │        │
              ┌─────▼──────┐         ┌─────────▼─────┐ │
              │ DynamoDB   │         │      S3       │ │
              └────────────┘         └───────────────┘ │
                                                        │
                                             ┌──────────▼──────┐
                                             │  SQS Queue      │
                                             └─────────────────┘
```

**Pros:**
- No server management
- Auto-scaling (zero to millions)
- Pay-per-use (cost-efficient for variable load)
- High availability built-in
- Fast time to market

**Cons:**
- Cold start latency
- Vendor lock-in
- Limited execution time (15 min Lambda)
- Debugging harder
- Stateless (need external state storage)
- Potential cost at high constant load

**When to Use:**
- Variable or unpredictable traffic
- Event-driven workflows
- Rapid prototyping
- Cost optimization priority
- Small to medium complexity

**AWS Implementation:**
- Lambda for compute
- API Gateway for HTTP APIs
- DynamoDB for database
- S3 for storage
- SQS/SNS for messaging
- EventBridge for event routing
- Step Functions for orchestration

---

### Layered Architecture (N-Tier)

**Description:** Application organized into logical layers, each with specific responsibility. Classic pattern: Presentation → Business Logic → Data Access → Database.

**Structure:**
```
  ┌─────────────────────────────────────────┐
  │     Presentation Layer (Web/Mobile)     │
  │         CloudFront + S3 / ALB           │
  └──────────────────┬──────────────────────┘
                     │
  ┌──────────────────▼──────────────────────┐
  │       Application Layer (API)           │
  │         EC2 / ECS / Lambda              │
  │  ┌────────────────────────────────────┐ │
  │  │      Business Logic Layer          │ │
  │  └────────────────────────────────────┘ │
  └──────────────────┬──────────────────────┘
                     │
  ┌──────────────────▼──────────────────────┐
  │       Data Access Layer (DAL)           │
  │         ORM / Database Client           │
  └──────────────────┬──────────────────────┘
                     │
  ┌──────────────────▼──────────────────────┐
  │         Data Layer (Database)           │
  │      RDS / DynamoDB / ElastiCache       │
  └─────────────────────────────────────────┘
```

**Pros:**
- Clear separation of concerns
- Easy to understand
- Testable (mock each layer)
- Reusable layers
- Security boundaries at each layer

**Cons:**
- Can become rigid
- Performance overhead (multiple layers)
- Changes may ripple across layers
- May lead to god objects

**When to Use:**
- Traditional web applications
- Clear layer responsibilities
- Team organized by specialty (frontend, backend, DB)
- CRUD-heavy applications

---

## 3. Component Design

### Client Layer

**Description:** User-facing interface (web, mobile, desktop) that interacts with backend services.

**Types:**
- **Web Browser:** HTML/CSS/JavaScript (React, Vue, Angular)
- **Mobile Native:** iOS (Swift), Android (Kotlin)
- **Mobile Hybrid:** React Native, Flutter
- **Desktop:** Electron, native apps

**Considerations:**
- **State Management:** Client-side caching, session management
- **API Communication:** REST, GraphQL, WebSocket
- **Offline Support:** Service workers, local storage
- **Performance:** Code splitting, lazy loading, CDN
- **Security:** HTTPS, CSP, XSS protection

**AWS Services:**
- **Static Hosting:** S3 + CloudFront
- **SPA Deployment:** Amplify, CloudFront
- **Mobile Backend:** Amplify, AppSync
- **CDN:** CloudFront for global distribution

---

### API Gateway / Load Balancer

**Description:** Entry point for all client requests. Routes traffic, handles SSL, provides unified interface.

**Responsibilities:**
- Request routing to backend services
- SSL termination
- Rate limiting and throttling
- Authentication/authorization
- Request/response transformation
- API versioning
- CORS handling
- Caching

**AWS Options:**

**API Gateway:**
- REST API, HTTP API, WebSocket API
- Built-in throttling, caching, authorization
- Request/response transformation
- API keys and usage plans
- Integration with Lambda, HTTP endpoints
- **Use when:** Need API management features, serverless

**Application Load Balancer (ALB):**
- Layer 7 load balancing (HTTP/HTTPS)
- Path-based and host-based routing
- WebSocket support
- Integration with ECS, EKS, EC2
- Health checks and auto-scaling
- **Use when:** Traditional server-based apps, containers

**Network Load Balancer (NLB):**
- Layer 4 load balancing (TCP/UDP)
- Ultra-high performance (millions of requests/sec)
- Static IP support
- **Use when:** Non-HTTP protocols, extreme performance needs

**Classic Load Balancer (CLB):**
- Legacy, not recommended for new designs

**Example Architecture:**
```
  Internet
     │
     ▼
┌─────────────┐
│ CloudFront  │ (CDN, static assets)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ API Gateway │ (REST API, auth, throttling)
└──────┬──────┘
       │
       ├──────► Lambda Functions (serverless)
       │
       └──────► ALB ──► ECS/EKS (containers)
```

---

### Application Servers / Compute

**Description:** Business logic execution layer. Processes requests, enforces rules, orchestrates workflows.

**AWS Compute Options:**

**EC2 (Elastic Compute Cloud):**
- Virtual machines with full OS control
- **Pros:** Flexibility, full control, any software
- **Cons:** Manual management, patching, scaling
- **Use when:** Custom runtime, legacy apps, need full control

**ECS (Elastic Container Service):**
- Container orchestration (Docker)
- **Fargate:** Serverless containers (no EC2 management)
- **EC2 Launch Type:** More control, lower cost
- **Use when:** Containerized apps, microservices

**EKS (Elastic Kubernetes Service):**
- Managed Kubernetes
- **Pros:** Kubernetes ecosystem, portability
- **Cons:** Complexity, learning curve
- **Use when:** Already using K8s, multi-cloud, complex orchestration

**Lambda:**
- Functions-as-a-Service (FaaS)
- **Pros:** No servers, auto-scale, pay-per-use
- **Cons:** Cold starts, 15 min limit, stateless
- **Use when:** Event-driven, variable load, microservices

**Elastic Beanstalk:**
- PaaS - upload code, AWS handles infra
- **Use when:** Simple deployment, less control needed

**Comparison:**
```
┌──────────┬──────────┬───────────┬───────────┬───────────┐
│          │   EC2    │    ECS    │    EKS    │  Lambda   │
├──────────┼──────────┼───────────┼───────────┼───────────┤
│ Control  │  High    │  Medium   │   High    │   Low     │
│ Mgmt     │  Manual  │  Low      │   Medium  │   None    │
│ Scale    │  Manual  │  Auto     │   Auto    │   Auto    │
│ Cost     │  Fixed   │  Moderate │  Moderate │  Per-use  │
│ Startup  │  Minutes │  Seconds  │  Seconds  │   Ms      │
└──────────┴──────────┴───────────┴───────────┴───────────┘
```

---

### Data Stores

**Description:** Persistent storage for application data. Choice depends on data model, access patterns, and consistency needs.

**Relational Databases (RDBMS):**

**RDS (Relational Database Service):**
- Managed PostgreSQL, MySQL, MariaDB, Oracle, SQL Server
- **Pros:** ACID, joins, complex queries, strong consistency
- **Cons:** Vertical scaling limits, less flexible schema
- **Use when:** Complex relationships, transactions, existing SQL apps
- **Features:** Multi-AZ, read replicas, automated backups

**Aurora:**
- AWS-built MySQL/PostgreSQL compatible
- **Pros:** 5x MySQL performance, auto-scaling storage (up to 128TB)
- **Cons:** AWS-only, higher cost
- **Use when:** High performance needed, MySQL/PostgreSQL workloads
- **Features:** Serverless option, global databases, parallel query

**NoSQL Databases:**

**DynamoDB:**
- Managed key-value and document database
- **Pros:** Fully managed, auto-scale, single-digit ms latency, serverless
- **Cons:** Limited querying, eventual consistency by default, learning curve
- **Use when:** High scale, flexible schema, key-value access patterns
- **Features:** Streams, global tables, on-demand pricing

**DocumentDB:**
- MongoDB-compatible document database
- **Use when:** Need MongoDB, want AWS management

**Neptune:**
- Graph database (property graph, RDF)
- **Use when:** Social networks, recommendation engines, fraud detection

**Keyspaces:**
- Managed Apache Cassandra
- **Use when:** Wide-column store needs, Cassandra migration

**In-Memory Stores:**

**ElastiCache:**
- **Redis:** Rich data structures, pub/sub, persistence options
- **Memcached:** Simple key-value cache, multi-threaded
- **Use when:** Sub-ms latency, caching, session storage, real-time analytics

**Database Selection Framework:**
```
Need ACID & Joins? ──► Yes ──► RDS / Aurora
         │
         No
         │
         ▼
High throughput,    ──► Yes ──► DynamoDB
flexible schema?
         │
         No
         │
         ▼
Graph relationships? ──► Yes ──► Neptune
         │
         No
         │
         ▼
Document store?     ──► Yes ──► DocumentDB / DynamoDB
```

---

### Caching Layer

**Description:** Stores frequently accessed data in fast storage (memory) to reduce latency and database load.

**Caching Strategies:**

**Cache-Aside (Lazy Loading):**
```
1. App checks cache
2. If miss, read from DB
3. Write to cache
4. Return data

Pros: Only cache what's needed
Cons: Initial requests slow (cache miss)
```

**Write-Through:**
```
1. Write to cache
2. Write to DB
3. Return success

Pros: Cache always up-to-date
Cons: Slower writes, cache unused data
```

**Write-Behind (Write-Back):**
```
1. Write to cache
2. Return success
3. Async write to DB

Pros: Fast writes
Cons: Risk of data loss, complexity
```

**Cache Invalidation:**
- **TTL:** Expire after time (simple, may serve stale)
- **Event-driven:** Invalidate on updates (complex, accurate)
- **Manual:** App explicitly invalidates (full control)

**What to Cache:**
- Database query results
- API responses
- Session data
- Computed/aggregated data
- Static content (HTML fragments)

**AWS Services:**
- **ElastiCache Redis:** Rich features, persistence, pub/sub
- **ElastiCache Memcached:** Simple, fast, distributed
- **CloudFront:** CDN caching at edge locations
- **API Gateway:** API response caching
- **DAX:** DynamoDB Accelerator (microsecond latency)

**Example Architecture:**
```
Client
   │
   ▼
CloudFront (edge cache, static assets)
   │
   ▼
API Gateway (API response cache)
   │
   ▼
App Server
   │
   ├──► ElastiCache (data cache)
   │         │
   │         ▼
   └──────► RDS (primary data)
```

---

### Message Queues / Asynchronous Processing

**Description:** Decouple components using queues for asynchronous communication. Improves reliability, scalability, and fault tolerance.

**AWS Services:**

**SQS (Simple Queue Service):**
- Managed message queue
- **Standard:** At-least-once, best-effort ordering, unlimited throughput
- **FIFO:** Exactly-once, strict ordering, 3K msg/sec (30K with batching)
- **Use when:** Decouple services, buffer requests, distribute tasks

**SNS (Simple Notification Service):**
- Pub/sub messaging
- Fan-out to multiple subscribers (SQS, Lambda, HTTP, email)
- **Use when:** Broadcast events, notifications to multiple consumers

**Kinesis:**
- **Data Streams:** Real-time streaming (like Kafka)
- **Firehose:** Load streams to S3, Redshift, Elasticsearch
- **Analytics:** Real-time analytics on streams
- **Use when:** Real-time data processing, analytics, logs

**EventBridge:**
- Event bus for event-driven architecture
- Route events from AWS services, custom apps, SaaS
- Schema registry, rules for routing
- **Use when:** Complex event routing, AWS service integrations

**Patterns:**

**Task Queue:**
```
Producer ──► SQS ──► Consumer (Lambda / EC2)

Use: Background jobs, async processing
Example: Image resize, email sending
```

**Pub/Sub:**
```
Publisher ──► SNS ──┬──► SQS (Service A)
                    ├──► Lambda (Service B)
                    └──► HTTP (Service C)

Use: Event broadcasting, notifications
Example: Order placed → update inventory, send email, log analytics
```

**Stream Processing:**
```
Producers ──► Kinesis Stream ──► Consumers (Lambda / KCL)
                    │
                    └──► Kinesis Firehose ──► S3 (archive)

Use: Real-time analytics, log aggregation
Example: IoT sensors, clickstream analysis
```

---

## 4. Data Flow Diagrams

### Request-Response Flow

**Typical Web Request:**
```
1. Client           2. CDN              3. LB               4. App
   │                   │                   │                   │
   ├──GET /page──────►│                   │                   │
   │                   │                   │                   │
   │            Cache  │                   │                   │
   │◄─────────miss─────┤                   │                   │
   │                   │                   │                   │
   │                   ├───forward────────►│                   │
   │                   │                   │                   │
   │                   │                   ├────route─────────►│
   │                   │                   │                   │
   │                   │                   │                   ├──► Cache
   │                   │                   │                   │    (check)
   │                   │                   │                   │      │
   │                   │                   │                   │   miss
   │                   │                   │                   │      │
   │                   │                   │                   ├────►DB
   │                   │                   │                   │◄─────┤
   │                   │                   │                   │
   │                   │                   │                   ├──► Cache
   │                   │                   │                   │    (write)
   │                   │                   │◄─────response─────┤
   │                   │◄────response──────┤                   │
   │                   ├─cache response    │                   │
   │◄────response──────┤                   │                   │
   │                   │                   │                   │

Cache path: CDN → App Cache → Database
```

### Write Flow with Async Processing

**E-commerce Order Flow:**
```
1. Client    2. API      3. Queue    4. Workers        5. DB
   │            │            │            │               │
   ├──POST──►   │            │            │               │
   │  order     │            │            │               │
   │            │            │            │               │
   │            ├──validate  │            │               │
   │            │            │            │               │
   │            ├─write DB───┼───────────►│───────────────►
   │            │            │            │               │
   │            ├─send msg───┼───────────►│               │
   │            │            │            │               │
   │◄──202──────┤            │            │               │
   │  Accepted  │            │            │               │
   │            │            │            │               │
   │            │            │            ├──process      │
   │            │            │            │  payment      │
   │            │            │            │               │
   │            │            │            ├──update───────►
   │            │            │            │  inventory    │
   │            │            │            │               │
   │            │            │            ├──send────►SNS (notifications)
   │            │            │            │  event        │
   │            │            │            │               │

Async: Order accepted immediately, processing happens in background
```

---

## 5. Technology Stack Decisions

### Selection Criteria

**Evaluation Framework:**
```
1. Functional Requirements
   - Does it meet feature needs?
   - Performance characteristics?
   - Scalability limits?

2. Non-Functional Requirements
   - Availability guarantees?
   - Consistency model?
   - Security features?

3. Operational Concerns
   - Ease of deployment?
   - Monitoring and logging?
   - Backup and recovery?
   - Team expertise?

4. Cost
   - Initial cost?
   - Scaling cost?
   - Operational overhead?

5. Ecosystem
   - Community support?
   - Documentation?
   - Third-party integrations?
   - Future viability?
```

### Example Stack Decisions

**Startup (MVP, < 10K users):**
```
Frontend: React (S3 + CloudFront)
API: Lambda + API Gateway (serverless)
Database: DynamoDB (NoSQL, auto-scale)
Auth: Cognito
Storage: S3
Monitoring: CloudWatch

Rationale:
- Fast to market (serverless, managed services)
- Low initial cost (pay-per-use)
- Auto-scaling built-in
- Minimal operations
```

**Enterprise (Millions of users):**
```
Frontend: React (S3 + CloudFront)
API Gateway: ALB
Compute: EKS (Kubernetes)
Database: Aurora (RDS) + DynamoDB
Cache: ElastiCache Redis
Message Queue: SQS/SNS + Kafka (MSK)
Storage: S3
Monitoring: CloudWatch + Prometheus/Grafana
Security: WAF, GuardDuty, Security Hub

Rationale:
- High availability (multi-AZ, multi-region)
- Independent scaling (microservices)
- Mature monitoring and observability
- Strong consistency where needed (Aurora)
- High throughput messaging (Kafka)
```

---

## 6. Multi-Region Architecture

### Why Multi-Region?

**Benefits:**
- **Low Latency:** Serve users from nearest region
- **High Availability:** Survive region failures
- **Compliance:** Data residency requirements
- **Disaster Recovery:** Geographic redundancy

**Challenges:**
- **Data Consistency:** Cross-region replication lag
- **Cost:** Data transfer between regions expensive
- **Complexity:** Routing, failover, conflict resolution

### Active-Active vs Active-Passive

**Active-Passive (Disaster Recovery):**
```
Primary Region (us-east-1)          Standby Region (us-west-2)
┌─────────────────────┐             ┌─────────────────────┐
│  Route 53           │             │                     │
│  (Primary)          │             │                     │
└──────────┬──────────┘             │                     │
           │                        │                     │
       ┌───▼────┐                   │    ┌─────────┐      │
       │  ALB   │                   │    │ ALB     │      │
       └───┬────┘                   │    │(Standby)│      │
           │                        │    └────┬────┘      │
       ┌───▼────┐                   │         │           │
       │  App   │                   │    ┌────▼─────┐     │
       └───┬────┘                   │    │   App    │     │
           │                        │    │(Standby) │     │
       ┌───▼────┐    Replication    │    └────┬─────┘     │
       │  RDS   ├───────────────────┼────────►│           │
       │Primary │                   │    │ RDS │           │
       └────────┘                   │    │Read │           │
                                    │    │Replica│         │
                                    └────┴───────┴─────────┘

Failover: Manual or automated (Route 53 health checks)
RTO: Minutes to hours
RPO: Seconds to minutes (replication lag)
Cost: Lower (standby on smaller instances)
```

**Active-Active (Global Load Balancing):**
```
                    ┌──────────────────┐
                    │    Route 53      │
                    │ (Geolocation/    │
                    │  Latency routing)│
                    └────────┬─────────┘
                             │
            ┌────────────────┼────────────────┐
            │                                 │
    Region: us-east-1              Region: eu-west-1
    ┌───────▼────────┐              ┌───────▼────────┐
    │      ALB       │              │      ALB       │
    └───────┬────────┘              └───────┬────────┘
            │                                │
    ┌───────▼────────┐              ┌───────▼────────┐
    │      App       │              │      App       │
    └───────┬────────┘              └───────┬────────┘
            │                                │
    ┌───────▼────────┐              ┌───────▼────────┐
    │  Aurora Global │◄─Replication─┤ Aurora Global  │
    │   (Primary)    │              │  (Secondary)   │
    └────────────────┘              └────────────────┘

Traffic: Both regions serve live traffic
Failover: Automatic (Route 53 health checks)
RTO: Seconds
RPO: Seconds (Aurora Global sub-second lag)
Cost: Higher (all resources active)
```

**AWS Multi-Region Services:**
- **Route 53:** Global DNS with health checks, geolocation routing
- **CloudFront:** Global CDN, automatic failover
- **Aurora Global Database:** < 1 second replication lag
- **DynamoDB Global Tables:** Multi-region, multi-master
- **S3 Cross-Region Replication:** Automatic object replication

---

## 7. Interview Approach

### How to Present High-Level Architecture

**Step-by-Step:**

**1. Start with User/Client (5 mins)**
```
"Users access the system through web and mobile clients.
The web app is a React SPA hosted on S3 behind CloudFront
for global distribution and caching of static assets."

[Draw client box and CDN]
```

**2. Entry Point / API Gateway (5 mins)**
```
"Requests hit an API Gateway that handles authentication
via Cognito, rate limiting, and routes to backend services.
For high throughput, I'd use an ALB instead of API Gateway."

[Draw API Gateway/ALB, connect to clients]
```

**3. Compute Layer (5 mins)**
```
"Backend runs as microservices on EKS for container
orchestration. Each service is independently deployable
and scalable. For simpler MVP, Lambda would work great."

[Draw compute boxes, multiple services]
```

**4. Data Layer (5 mins)**
```
"We'll use Aurora PostgreSQL for transactional data
(orders, users) with read replicas for scaling reads.
DynamoDB for high-throughput data like sessions and
product catalog. ElastiCache Redis for caching hot data."

[Draw databases, cache layer]
```

**5. Async Processing (5 mins)**
```
"For async workflows like order processing and notifications,
we use SQS queues consumed by Lambda or ECS workers.
SNS for fan-out to multiple subscribers."

[Draw queues, workers]
```

**6. Storage & CDN (3 mins)**
```
"S3 for object storage (images, videos, backups).
CloudFront for global CDN with edge caching."

[Draw S3, connect to CloudFront]
```

**7. Connect Components (5 mins)**
```
Draw arrows showing data flow:
- Request path (client → CDN → ALB → app → cache/DB)
- Async path (app → SQS → workers → DB)
- Storage path (app → S3 → CloudFront)

Add annotations:
- "REST API" on arrows
- "Pub/Sub" on SNS
- "Read/Write" on DB connections
```

### Architecture Diagram Template

```
                  ┌───────────────────┐
                  │     Internet      │
                  └─────────┬─────────┘
                            │
                  ┌─────────▼─────────┐
                  │   CloudFront CDN  │
                  │  (Static Assets)  │
                  └─────────┬─────────┘
                            │
           ┌────────────────┴────────────────┐
           │                                 │
    ┌──────▼──────┐                 ┌───────▼────────┐
    │   S3 SPA    │                 │  API Gateway/  │
    │  (Static)   │                 │      ALB       │
    └─────────────┘                 └───────┬────────┘
                                            │
                                    ┌───────┴───────┐
                                    │               │
                            ┌───────▼────┐   ┌──────▼──────┐
                            │  Service A │   │  Service B  │
                            │    (EKS)   │   │   (EKS)     │
                            └───────┬────┘   └──────┬──────┘
                                    │               │
                    ┌───────────────┼───────────────┼──────┐
                    │               │               │      │
         ┌──────────▼──┐    ┌──────▼──────┐  ┌─────▼────┐│
         │ElastiCache  │    │   Aurora    │  │   SQS    ││
         │   Redis     │    │  PostgreSQL │  │  Queue   ││
         └─────────────┘    └─────────────┘  └─────┬────┘│
                                                    │     │
                                             ┌──────▼───┐ │
                                             │  Lambda  │ │
                                             │ Workers  │ │
                                             └──────────┘ │
                                                          │
                                             ┌────────────▼┐
                                             │     S3      │
                                             │  (Objects)  │
                                             └─────────────┘
```

---

## 8. Common Mistakes to Avoid

❌ **Too much detail too soon**
- Don't design internal service logic in high-level phase

❌ **Forgetting to connect components**
- Show how components communicate (REST, gRPC, queues)

❌ **Ignoring data flow**
- Trace a request end-to-end to validate architecture

❌ **Not explaining choices**
- Always justify: "I chose X because..."

❌ **Over-complicating**
- Start simple, add complexity when justified by requirements

❌ **Missing single points of failure**
- Point out and mitigate SPOFs (single DB, no LB, etc.)

❌ **Forgetting about operational concerns**
- How is this monitored? Deployed? Debugged?

---

## 9. Summary Checklist

```markdown
High-Level Architecture Checklist:

□ Client layer defined (web, mobile, protocols)
□ Entry point identified (API Gateway, ALB, CDN)
□ Compute approach chosen (EC2, ECS, EKS, Lambda)
□ Database(s) selected with rationale
□ Caching strategy defined
□ Async processing mechanism (if needed)
□ Storage solution for objects/files
□ Components connected with protocols
□ Data flow traced end-to-end
□ Single points of failure identified and addressed
□ Multi-AZ or multi-region considered
□ Security boundaries noted (VPC, subnets)
□ Monitoring/logging mentioned
□ Justifications provided for major decisions
```

**Key Takeaways:**
1. **Start simple** - Build up complexity incrementally
2. **Show connections** - How do components talk?
3. **Trace data flow** - Walk through a request
4. **Justify decisions** - Why this tech over alternatives?
5. **Think operationally** - How is this run in production?
6. **Identify trade-offs** - What are you optimizing for?

This architecture is your blueprint. Get it right, and the deep dives become natural conversations about implementation details.
