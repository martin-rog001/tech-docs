# System Design: Requirements & Planning

## Overview

Requirements gathering and planning are the foundation of any system design. This phase sets clear expectations, defines success metrics, and guides all architectural decisions. For SRE interviews, demonstrating a structured approach to requirements shows engineering maturity and prevents costly rework later.

---

## 1. Functional Requirements

### What are Functional Requirements?

**Description:** Functional requirements define WHAT the system should do - the specific features, behaviors, and capabilities users need. They describe the business logic and user interactions. Being explicit about functional requirements helps scope the system and prevents feature creep during design.

**How to Gather:**
1. Ask clarifying questions about core features
2. Identify the primary use cases
3. Distinguish between must-have (MVP) and nice-to-have features
4. Document user workflows
5. Define API contracts and data models

**Example Questions for Interviews:**
- "What are the core features this system must support?"
- "Who are the users and what actions do they perform?"
- "Are there any features out of scope for this design?"
- "What's the MVP vs future enhancements?"
- "What data does the system need to store and process?"

### Common System Examples

**URL Shortener:**
- Create short URL from long URL
- Redirect short URL to original URL
- Track click analytics (optional)
- Custom aliases (optional)
- Expiration/TTL (optional)

**Social Media Feed:**
- Post creation (text, images, videos)
- View personalized feed
- Like, comment, share
- Follow/unfollow users
- Notifications

**E-commerce Platform:**
- Product catalog browsing
- Search and filtering
- Shopping cart management
- Order placement
- Payment processing
- Order tracking
- Inventory management

**Video Streaming Service:**
- Video upload and encoding
- Video playback with adaptive bitrate
- Search and recommendations
- User profiles and watch history
- Subscription management

**Chat Application:**
- One-on-one messaging
- Group chats
- Message history
- Read receipts
- Online/offline status
- File sharing (optional)

### Best Practices

✅ **Start simple** - Focus on core features first (MVP)
✅ **Be explicit** - Don't assume; ask clarifying questions
✅ **Prioritize** - Distinguish P0 (must-have) from P1/P2 features
✅ **Think APIs** - Define key API endpoints early
✅ **Consider data** - What entities and relationships exist?

❌ **Avoid scope creep** - Don't design every possible feature
❌ **Don't be vague** - "Social media site" is too broad; specify features

---

## 2. Non-Functional Requirements (NFRs)

### What are Non-Functional Requirements?

**Description:** Non-functional requirements define HOW WELL the system should perform - the quality attributes like performance, reliability, scalability, and security. NFRs drive architectural decisions and determine technology choices. In SRE interviews, NFRs are critical as they directly impact system reliability.

### Key NFR Categories

#### A. Performance Requirements

**Latency:**
- **Definition:** Time to process a single request
- **Measurement:** p50, p95, p99, p999 latency
- **Examples:**
  - API responses: < 100ms p99
  - Database queries: < 50ms p95
  - Page load: < 2 seconds
  - Real-time messaging: < 100ms

**Throughput:**
- **Definition:** Number of requests processed per unit time
- **Measurement:** Requests per second (RPS/QPS), transactions per second (TPS)
- **Examples:**
  - Read requests: 10,000 QPS
  - Write requests: 1,000 QPS
  - Video streams: 100,000 concurrent streams
  - Messages: 1M messages/second

**Bandwidth:**
- **Definition:** Amount of data transferred
- **Measurement:** MB/s, GB/s, TB/month
- **Examples:**
  - Video streaming: 5 Mbps per stream
  - Image uploads: 10 MB per image
  - Total bandwidth: 10 TB/month

#### B. Availability Requirements

**Availability:**
- **Definition:** Percentage of time system is operational and accessible
- **Measurement:** Uptime percentage (99.9%, 99.99%, 99.999%)
- **Downtime allowance:**
  - 99% (2 nines): 3.65 days/year, 7.2 hours/month
  - 99.9% (3 nines): 8.76 hours/year, 43.2 minutes/month
  - 99.95%: 4.38 hours/year, 21.6 minutes/month
  - 99.99% (4 nines): 52.56 minutes/year, 4.32 minutes/month
  - 99.999% (5 nines): 5.26 minutes/year, 25.9 seconds/month

**Examples:**
- Critical systems (payments, healthcare): 99.99% - 99.999%
- Business applications: 99.9% - 99.95%
- Internal tools: 99% - 99.9%

#### C. Scalability Requirements

**Scalability:**
- **Definition:** Ability to handle growth in users, data, and traffic
- **Types:**
  - **Horizontal scaling:** Add more machines (scale out)
  - **Vertical scaling:** Add more resources to existing machines (scale up)

**Considerations:**
- Current scale: 1K users, 100K requests/day
- Expected growth: 10x in 1 year, 100x in 3 years
- Peak vs average load: 5x traffic during peak hours
- Seasonal spikes: Black Friday, holidays (10x normal)

**Examples:**
- "System should handle 1M daily active users"
- "Scale to 100K concurrent connections"
- "Support 10TB of data with sub-second queries"
- "Handle 10x traffic spikes without degradation"

#### D. Durability & Data Retention

**Durability:**
- **Definition:** Guarantee that data won't be lost
- **Measurement:** Number of nines (99.999999999% = 11 nines)
- **Examples:**
  - Critical data (financial, medical): 11 nines (S3 standard)
  - User content: 9-11 nines
  - Temporary data: Lower durability acceptable

**Data Retention:**
- **Definition:** How long data must be kept
- **Examples:**
  - Transaction records: 7 years (compliance)
  - User activity logs: 90 days
  - Metrics: 30 days detailed, 1 year aggregated
  - Backups: Daily for 30 days, weekly for 1 year

#### E. Consistency Requirements

**Consistency Models:**
- **Strong consistency:** Read reflects all previous writes (ACID databases)
- **Eventual consistency:** Reads may be stale temporarily but converge (NoSQL)
- **Causal consistency:** Related operations maintain order

**CAP Theorem:**
- **C**onsistency: All nodes see same data
- **A**vailability: System responds to requests
- **P**artition tolerance: System works despite network failures
- **Reality:** Can only guarantee 2 of 3

**Examples:**
- Financial transactions: Strong consistency required
- Social media feeds: Eventual consistency acceptable
- Shopping cart: Session consistency (read your own writes)
- Analytics: Eventual consistency fine

#### F. Security & Compliance

**Security Requirements:**
- Authentication and authorization
- Data encryption (at rest and in transit)
- Network isolation and firewalls
- Audit logging
- Vulnerability management

**Compliance:**
- GDPR (data privacy - EU)
- HIPAA (healthcare - US)
- PCI-DSS (payment cards)
- SOC 2 (security controls)
- Regional data residency requirements

**Examples:**
- "All PII must be encrypted at rest"
- "Data must not leave EU region (GDPR)"
- "Audit logs retained for 7 years"
- "Support user data deletion within 30 days"

### NFR Template for Interviews

```
Performance:
- Latency: < 200ms p99 for API calls
- Throughput: 50,000 requests/second peak
- Bandwidth: 100 TB/month

Availability:
- Target: 99.95% uptime (21.6 min/month downtime)
- Recovery Time Objective (RTO): < 5 minutes
- Recovery Point Objective (RPO): < 1 minute

Scalability:
- Support 10M daily active users
- Handle 5x traffic spikes
- Scale to 100TB data over 3 years

Durability:
- 99.999999999% durability for user data
- Backups: Daily (30 days), Weekly (1 year)

Consistency:
- Strong consistency for transactions
- Eventual consistency for feed/timeline

Security:
- TLS 1.3 for all traffic
- AES-256 encryption at rest
- PCI-DSS compliant for payments
- Data residency per region
```

---

## 3. Capacity Planning & Estimation

### Why Capacity Planning Matters

**Description:** Capacity planning involves calculating the resources (compute, storage, bandwidth) needed to meet requirements. This demonstrates analytical thinking and prevents over/under-provisioning. In interviews, showing the math proves you understand real-world constraints.

### Estimation Framework

#### Step 1: Define Scale
```
Users:
- Total users: 100M
- Daily Active Users (DAU): 20M (20% of total)
- Peak concurrent users: 2M (10% of DAU)
- Requests per user per day: 50

Traffic:
- Daily requests: 20M users × 50 requests = 1B requests/day
- Requests per second (avg): 1B / 86,400 seconds ≈ 11,600 QPS
- Peak QPS: 11,600 × 3 (peak multiplier) = 35,000 QPS
- Read:Write ratio: 100:1 (typical social media)
```

#### Step 2: Storage Estimation
```
Data per user:
- Profile data: 1 KB
- Posts per user per day: 2
- Post size: 500 bytes (text) + 2 MB (image average)
- Total per user per day: 4 MB

Daily storage:
- 20M DAU × 4 MB = 80 TB/day
- Monthly: 80 TB × 30 = 2.4 PB/month
- Yearly: 2.4 PB × 12 = 28.8 PB/year

Storage over 3 years: ~87 PB
Add 20% buffer: ~105 PB needed
```

#### Step 3: Bandwidth Estimation
```
Upload bandwidth:
- 20M users × 4 MB/day = 80 TB/day
- Per second: 80 TB / 86,400 ≈ 925 MB/s ≈ 7.4 Gbps

Download bandwidth (100:1 read:write ratio):
- 7.4 Gbps × 100 = 740 Gbps

Peak bandwidth (3x multiplier):
- Upload: 7.4 × 3 = 22 Gbps
- Download: 740 × 3 = 2.2 Tbps
```

#### Step 4: Compute Estimation
```
Application servers:
- Peak QPS: 35,000
- Requests per server: 500 QPS (assume 50ms latency, 25 threads)
- Servers needed: 35,000 / 500 = 70 servers
- Add 50% buffer: 105 servers
- Add redundancy (multi-AZ): 105 × 2 = 210 servers

Instance type: c5.xlarge (4 vCPU, 8 GB RAM)
- Assumption: 200 concurrent connections per server
- Memory per connection: ~10 MB
- 200 × 10 MB = 2 GB, leaving 6 GB for app
```

#### Step 5: Database Estimation
```
Database sizing:
- Total data: 105 PB
- Hot data (recent 30 days): 2.4 PB
- Cache layer: 5% of hot data = 120 TB

Database approach:
- Primary DB: Aurora PostgreSQL (hot data)
- Archive: S3 Glacier (cold data)
- Cache: ElastiCache Redis (frequently accessed)

Database sharding:
- Max single DB size: 10 TB
- Shards needed: 2.4 PB / 10 TB = 240 shards
- Shard by user_id (consistent hashing)
```

### Quick Reference Numbers (Back-of-Envelope)

**Time:**
- 1 second = 1,000 milliseconds (ms)
- 1 ms = 1,000 microseconds (μs)
- 1 day = 86,400 seconds ≈ 100K seconds

**Storage:**
- 1 KB = 1,000 bytes
- 1 MB = 1,000 KB
- 1 GB = 1,000 MB
- 1 TB = 1,000 GB
- 1 PB = 1,000 TB

**Latency:**
- L1 cache: 1 ns
- L2 cache: 10 ns
- RAM access: 100 ns
- SSD read: 100 μs
- HDD seek: 10 ms
- Network within datacenter: 0.5 ms
- Network cross-continent: 150 ms

**Throughput:**
- SSD: 500 MB/s read, 300 MB/s write
- HDD: 100 MB/s
- Network (1 Gbps): 125 MB/s
- Network (10 Gbps): 1.25 GB/s

### Typical Conversion Ratios

- **Daily Active Users:** 20-30% of total users
- **Peak concurrent:** 10% of DAU
- **Peak traffic multiplier:** 2-5x average
- **Read:Write ratio:** 100:1 (social), 10:1 (e-commerce), 1:1 (chat)
- **Cache hit rate:** 80-90% for hot data
- **Storage growth:** 2-5x per year for user-generated content

---

## 4. SLAs, SLOs, and SLIs

### What are SLAs, SLOs, and SLIs?

**Description:** These are the contracts and measurements that define reliability. They're fundamental to SRE practice and demonstrate your understanding of operational excellence.

#### SLA (Service Level Agreement)

**Definition:** A contract with customers defining consequences if service doesn't meet targets.

**Components:**
- Uptime commitment (e.g., 99.9%)
- Financial penalties/credits if breached
- Measurement methodology
- Exclusions (maintenance windows, force majeure)

**Examples:**
- "99.95% uptime or 10% monthly credit"
- "API latency < 200ms p99 or SLA breach"
- "Data durability 99.999999999% or liability up to $X"

**AWS SLA Examples:**
- EC2: 99.99% monthly uptime
- S3: 99.9% uptime, 99.999999999% durability
- RDS Multi-AZ: 99.95% monthly uptime

#### SLO (Service Level Objective)

**Definition:** Internal target for service reliability; stricter than SLA to provide buffer.

**Why SLO < SLA:**
- SLO: 99.95% (internal target)
- SLA: 99.9% (customer commitment)
- Buffer: 0.05% protects against SLA breach

**Examples:**
- "API latency: 99% of requests < 100ms (SLO)"
- "Error rate: < 0.1% of all requests"
- "Data pipeline: 99.9% of jobs complete within 30 minutes"

**Setting SLOs:**
```
Start with customer expectations:
- What latency is acceptable?
- How much downtime is tolerable?
- What error rate impacts user experience?

Set realistic targets:
- Historical performance
- Cost of improving reliability
- User impact of failures

Example SLO:
- Availability: 99.95% (measured per month)
- Latency: 95% < 200ms, 99% < 500ms
- Error rate: < 0.1%
```

#### SLI (Service Level Indicator)

**Definition:** Actual measurements that indicate service health; metrics used to calculate SLO compliance.

**Common SLIs:**
- **Availability:** % of successful requests (200-299 status codes)
- **Latency:** Distribution of response times (p50, p95, p99)
- **Error rate:** % of requests returning errors (5xx)
- **Throughput:** Requests per second
- **Durability:** % of data not lost

**SLI Examples:**
```
Availability SLI:
- Measure: HTTP status codes
- Success: 2xx and 3xx responses
- Formula: (successful_requests / total_requests) × 100
- Example: 999,500 success / 1,000,000 total = 99.95%

Latency SLI:
- Measure: Response time histogram
- Target: p99 < 200ms
- Formula: Percentage of requests below threshold
- Example: 99.2% of requests < 200ms

Error Rate SLI:
- Measure: 5xx status codes + timeouts
- Target: < 0.1%
- Formula: (error_requests / total_requests) × 100
- Example: 500 errors / 1,000,000 total = 0.05%
```

### Error Budget

**Definition:** The allowed amount of unreliability based on SLO.

**Calculation:**
```
SLO: 99.95% availability
Error budget: 100% - 99.95% = 0.05%

Monthly (30 days = 43,200 minutes):
- Allowed downtime: 43,200 × 0.05% = 21.6 minutes/month

If already down for 15 minutes:
- Remaining budget: 21.6 - 15 = 6.6 minutes
- % consumed: 15 / 21.6 = 69.4%
```

**Using Error Budget:**
- **Budget remaining:** Continue feature releases
- **Budget exhausted:** Freeze releases, focus on reliability
- **Budget healthy:** Increase velocity, take calculated risks

**Example Policy:**
```
Error Budget Policy:
- 100-75% remaining: Normal release velocity
- 75-50% remaining: Increase monitoring, reduce risk
- 50-25% remaining: Feature freeze for risky changes
- 25-0% remaining: Full feature freeze, reliability only
- 0% (exhausted): Incident postmortem, improvement plan
```

---

## 5. Trade-offs and Constraints

### Common System Design Trade-offs

**Description:** Every design decision involves trade-offs. Explicitly discussing them shows engineering maturity and prevents choosing technology for technology's sake.

#### Consistency vs Availability (CAP Theorem)

**Trade-off:**
- **Choose Consistency (CP):** System may be unavailable during network partition
- **Choose Availability (AP):** System may return stale data during partition

**When to choose CP:**
- Financial transactions
- Inventory management
- Booking systems

**When to choose AP:**
- Social media feeds
- Product catalogs
- Analytics dashboards

**Example:**
```
Shopping cart design:
- Option 1 (CP): Strong consistency, may be unavailable during failures
  - Use: RDS with multi-AZ
- Option 2 (AP): Available but eventual consistency
  - Use: DynamoDB with eventual reads
- Hybrid: Session consistency (read your own writes)
  - Use: DynamoDB with consistent reads for user's own cart
```

#### Latency vs Throughput

**Trade-off:**
- **Optimize for latency:** Lower per-request time but may limit throughput
- **Optimize for throughput:** Higher total requests/sec but may increase latency

**Examples:**
- **Low latency:** Disable batching, use fast storage (NVMe SSD), add caching
- **High throughput:** Enable batching, compress data, use connection pooling

```
API design:
- Individual requests: Lower latency (50ms), lower throughput (1K QPS)
- Batch requests: Higher latency (200ms), higher throughput (10K QPS)

Choice depends on use case:
- Real-time chat: Choose low latency
- Analytics ingestion: Choose high throughput
```

#### Normalization vs Denormalization

**Trade-off:**
- **Normalized:** No duplication, complex joins, slower reads
- **Denormalized:** Data duplication, simple queries, faster reads

**When to normalize:**
- Write-heavy workloads
- Frequent updates
- Storage is expensive
- Data consistency critical

**When to denormalize:**
- Read-heavy workloads (100:1 read:write)
- Query performance critical
- Storage is cheap
- Eventual consistency acceptable

**Example:**
```
E-commerce product catalog:
- Normalized: Products, categories, reviews in separate tables
  - Pros: Single source of truth, easy updates
  - Cons: Complex joins, slower queries
- Denormalized: Embed category and review summary in product
  - Pros: Single query, fast reads
  - Cons: Data duplication, update complexity
```

#### Strong vs Eventual Consistency

**Trade-off:**
- **Strong consistency:** Always correct data, lower availability, higher latency
- **Eventual consistency:** May be stale, higher availability, lower latency

**Examples:**
```
Social media likes:
- Strong: User sees accurate count immediately (slower)
- Eventual: Count may be slightly off (faster, scales better)
- Choice: Eventual (user experience not impacted)

Bank transfer:
- Strong: Balance always accurate (required)
- Eventual: Risk of overdraft (unacceptable)
- Choice: Strong consistency
```

#### Synchronous vs Asynchronous Processing

**Trade-off:**
- **Synchronous:** Immediate response, simpler debugging, limited scale
- **Asynchronous:** Higher throughput, better resilience, complex debugging

**When to choose sync:**
- User needs immediate confirmation
- Simple workflows
- Low volume

**When to choose async:**
- Long-running operations
- High volume
- Decoupled services
- Resilience to failures

**Example:**
```
Order processing:
- Synchronous:
  - User submits order → Process payment → Reserve inventory → Return confirmation
  - Pros: Immediate feedback
  - Cons: Slow if payment takes 5 seconds, entire flow fails if one step fails

- Asynchronous:
  - User submits order → Return "Order received" → Process async via queue
  - Pros: Fast response, resilient (retries), scales independently
  - Cons: Complex error handling, eventual confirmation
```

#### Cost vs Performance

**Trade-off:**
- **Optimize for cost:** May sacrifice performance, availability
- **Optimize for performance:** Higher costs for faster/more reliable service

**Examples:**
```
Database choice:
- DynamoDB on-demand: High cost, zero management, auto-scale
- RDS Reserved Instances: Lower cost, manual capacity planning
- Aurora Serverless: Pay per use, good for variable load

Caching:
- No cache: Low cost, slow responses, high DB load
- ElastiCache: Higher cost, fast responses, reduced DB load
- Trade-off: Cache for hot data only (80/20 rule)
```

### Constraint Categories

#### Technical Constraints
- Technology stack limitations (language, framework)
- Network bandwidth
- Legacy system integration
- Data center locations

#### Business Constraints
- Budget limitations
- Time to market
- Team expertise
- Vendor lock-in concerns

#### Regulatory Constraints
- Data residency (GDPR: data must stay in EU)
- Industry compliance (HIPAA, PCI-DSS)
- Audit requirements
- Data retention policies

### Interview Approach to Trade-offs

**Framework:**
1. **Identify the trade-off:** "We're choosing between X and Y"
2. **State pros/cons:** "X gives us A and B, but costs C. Y gives us D, but requires E"
3. **Consider context:** "Given our requirements of high availability and eventual consistency is acceptable..."
4. **Make decision:** "I recommend Y because..."
5. **Note alternatives:** "If requirements change to need X, we could adapt by..."

**Example:**
```
Interviewer: "How would you design the notification system?"

Candidate: "I see a trade-off between push and pull approaches.

Push (SNS/SQS):
- Pros: Real-time delivery, user doesn't poll
- Cons: Requires persistent connections, harder to scale

Pull (Periodic polling):
- Pros: Simpler, scales easily, works with firewalls
- Cons: Higher latency, wasted requests when no notifications

Given we need real-time notifications (<1 second) and expect millions
of users, I'd use a hybrid:
- Push for online users (WebSocket)
- Pull for offline (check on app open)
- Store in database for history

If battery life becomes a concern, we could switch to pull with
exponential backoff."
```

---

## 6. Interview Strategy

### How to Approach Requirements in Interviews

**Step-by-Step Process:**

**1. Clarify the Problem (5 minutes)**
```
Questions to ask:
- "What are the core features we need to support?"
- "Who are the users and what are they trying to achieve?"
- "Are there any features explicitly out of scope?"
- "What's the expected scale (users, QPS, data size)?"
```

**2. Define Functional Requirements (5 minutes)**
```
List core features:
- Feature 1: User registration and authentication
- Feature 2: Create and view posts
- Feature 3: Follow/unfollow users
- Feature 4: Personalized feed

Prioritize:
- P0 (MVP): Features 1, 2, 3
- P1 (Nice to have): Feature 4
```

**3. Define Non-Functional Requirements (5 minutes)**
```
Cover key NFRs:
- Scale: 100M users, 50M DAU, 10K QPS peak
- Availability: 99.95% uptime
- Latency: < 200ms p99 for API, < 2s for feed
- Consistency: Eventual for feeds, strong for user data
- Security: Encrypted data, OAuth authentication
```

**4. Capacity Estimation (5 minutes)**
```
Quick calculations:
- Traffic: 50M users × 20 requests/day = 1B requests/day ≈ 12K QPS
- Storage: 50M users × 100 posts × 1KB = 5TB
- Bandwidth: Estimate uploads/downloads
- Servers: QPS / capacity_per_server
```

**5. Discuss Trade-offs (Throughout)**
```
Proactively mention:
- "I'm choosing eventual consistency for feeds because..."
- "We could use strong consistency but that would impact availability..."
- "The trade-off here is between latency and cost..."
```

### Common Mistakes to Avoid

❌ **Jumping to solution too quickly**
- Don't start designing before understanding requirements

❌ **Being too vague**
- "It should be fast" → Specify: "< 100ms p99 latency"
- "It should scale" → Specify: "10M DAU, 50K QPS"

❌ **Ignoring constraints**
- Not asking about budget, timeline, team expertise

❌ **Over-engineering**
- Don't design for 1B users if starting with 10K

❌ **Under-specifying**
- Forgetting to mention availability, consistency, or security

❌ **Not showing the math**
- Skipping capacity calculations shows lack of rigor

### Key Phrases for Interviews

✅ **Show structured thinking:**
- "Let me start by clarifying the functional requirements..."
- "For non-functional requirements, I'll cover performance, availability, and scalability..."
- "Let me do some back-of-envelope calculations..."

✅ **Demonstrate trade-off awareness:**
- "There's a trade-off between X and Y. Given our requirements, I'd choose X because..."
- "We could optimize for latency, but that would cost us throughput..."
- "If we need to change this assumption later, we could..."

✅ **Show SRE mindset:**
- "What's our SLA commitment? I'd set SLO at..."
- "We need to monitor this SLI to ensure we meet our targets..."
- "The error budget for 99.95% is 21.6 minutes per month..."

---

## 7. Quick Reference Template

### Requirements Checklist

```markdown
## Functional Requirements (What system does)
□ Core features identified and prioritized
□ User workflows defined
□ API contracts outlined
□ Data model sketched
□ Scope clearly defined (in/out of scope)

## Non-Functional Requirements (How well it performs)
□ Performance: Latency targets (p50/p95/p99)
□ Performance: Throughput targets (QPS/TPS)
□ Availability: Uptime target (99.X%)
□ Scalability: User/data growth projections
□ Durability: Data retention and backup requirements
□ Consistency: Strong vs eventual consistency needs
□ Security: Encryption, authentication, compliance

## Capacity Estimation
□ User scale (total, DAU, peak concurrent)
□ Traffic (QPS average and peak)
□ Storage (current and projected)
□ Bandwidth (upload/download)
□ Compute (servers needed)

## SLAs/SLOs/SLIs
□ SLA defined (customer commitment)
□ SLO defined (internal target, stricter than SLA)
□ SLIs identified (measurable metrics)
□ Error budget calculated

## Trade-offs & Constraints
□ Key trade-offs identified
□ Decisions justified with context
□ Alternatives mentioned
□ Constraints documented (technical, business, regulatory)
```

---

## Summary

**Key Takeaways for SRE Interviews:**

1. **Start with requirements** - Don't jump to solutions
2. **Be specific with NFRs** - Use numbers (99.95%, < 100ms p99, 10K QPS)
3. **Show the math** - Capacity estimation demonstrates rigor
4. **Define SLOs/SLIs** - Shows SRE mindset and operational thinking
5. **Discuss trade-offs** - Every decision has pros/cons; make them explicit
6. **Consider constraints** - Real-world systems have limitations
7. **Think like an operator** - How will this be monitored, deployed, debugged?

**Remember:** Requirements drive everything else. Get this right, and the rest of the design follows naturally.
