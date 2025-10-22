# System Design: Data & Storage Layer

## Overview

The Data & Storage Layer is the foundation of your application - where persistent data lives. This layer encompasses databases, caches, object storage, message queues, and search engines. For SRE interviews, demonstrating understanding of data modeling, consistency models, and storage trade-offs is crucial.

---

## 1. Database Selection

### Decision Framework

**Questions to Ask:**
```
1. Data Structure:
   - Structured (tables/rows) or unstructured (documents/JSON)?
   - Fixed schema or flexible schema?
   - Relationships between entities?

2. Access Patterns:
   - Read-heavy, write-heavy, or balanced?
   - Query complexity (simple key-value or complex joins)?
   - Need for transactions?

3. Scale Requirements:
   - Data size (GB, TB, PB)?
   - Query throughput (QPS)?
   - Latency requirements?

4. Consistency Needs:
   - Strong consistency or eventual consistency acceptable?
   - ACID transactions required?

5. Operational:
   - Managed service or self-hosted?
   - Team expertise?
   - Multi-region requirements?
```

**Selection Matrix:**
```
┌─────────────────┬──────────────────────────────────────┐
│ Use Case        │ Recommended Database                 │
├─────────────────┼──────────────────────────────────────┤
│ Transactions    │ RDS (PostgreSQL/MySQL), Aurora       │
│ High scale      │ DynamoDB, Cassandra                  │
│ Analytics       │ Redshift, Athena                     │
│ Time-series     │ Timestream, InfluxDB                 │
│ Graph           │ Neptune                              │
│ Document store  │ DocumentDB, DynamoDB                 │
│ Search          │ OpenSearch, Elasticsearch            │
│ Cache           │ ElastiCache (Redis/Memcached)        │
│ Data warehouse  │ Redshift, BigQuery                   │
└─────────────────┴──────────────────────────────────────┘
```

---

## 2. Relational Databases (RDBMS)

### Amazon RDS

**Description:** Managed relational database service supporting PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server. AWS handles patching, backups, and infrastructure.

**Key Features:**
- Automated backups (point-in-time recovery up to 5 minutes)
- Multi-AZ for high availability
- Read replicas for read scaling (up to 15)
- Automated patching and upgrades
- Encryption at rest and in transit
- Performance Insights for query optimization
- Storage auto-scaling

**Multi-AZ Deployment:**
```
Primary AZ (us-east-1a)          Standby AZ (us-east-1b)
┌────────────────────┐           ┌────────────────────┐
│   RDS Primary      │           │   RDS Standby      │
│   (Read/Write)     │◄─Sync────►│   (No traffic)     │
└──────────┬─────────┘           └────────────────────┘
           │
           │ Automatic failover
           │ (60-120 seconds)
           │
    ┌──────▼──────┐
    │  Application│
    │   (Single   │
    │  Endpoint)  │
    └─────────────┘

Benefits:
- Automatic failover
- No manual intervention
- Zero data loss
- RTO: 60-120 seconds
- RPO: 0 (synchronous replication)

Cost: ~2x (duplicate instance)
```

**Read Replicas:**
```
                    ┌──────────────┐
                    │ RDS Primary  │
                    │ (Read/Write) │
                    └──────┬───────┘
                           │
                ┌──────────┼──────────┐
                │          │          │
      ┌─────────▼──┐  ┌────▼──────┐ ┌▼─────────┐
      │Read Replica│  │Read Replica│ │Read Rep. │
      │  (Read)    │  │  (Read)    │ │ (Read)   │
      └────────────┘  └────────────┘ └──────────┘

Replication: Asynchronous
Lag: Typically < 1 second
Use cases:
- Scale read traffic
- Analytics queries
- Cross-region disaster recovery
- Offload reporting

Can promote replica to standalone DB
```

**Configuration:**
```yaml
Resources:
  DBInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: myapp-db
      Engine: postgres
      EngineVersion: 14.6
      DBInstanceClass: db.r6g.xlarge
      AllocatedStorage: 100
      MaxAllocatedStorage: 1000  # Auto-scaling up to 1TB
      StorageType: gp3
      StorageEncrypted: true
      KmsKeyId: !Ref KMSKey

      # Multi-AZ
      MultiAZ: true

      # Network
      DBSubnetGroupName: !Ref DBSubnetGroup
      VPCSecurityGroups:
        - !Ref DBSecurityGroup
      PubliclyAccessible: false

      # Credentials
      MasterUsername: admin
      MasterUserPassword: !Sub '{{resolve:secretsmanager:${DBSecret}:SecretString:password}}'

      # Backup
      BackupRetentionPeriod: 7
      PreferredBackupWindow: "03:00-04:00"
      CopyTagsToSnapshot: true
      DeleteAutomatedBackups: false

      # Maintenance
      PreferredMaintenanceWindow: "sun:04:00-sun:05:00"
      AutoMinorVersionUpgrade: true

      # Monitoring
      EnableCloudwatchLogsExports:
        - postgresql
      MonitoringInterval: 60
      MonitoringRoleArn: !GetAtt MonitoringRole.Arn
      EnablePerformanceInsights: true
      PerformanceInsightsRetentionPeriod: 7

      # Parameters
      DBParameterGroupName: !Ref DBParameterGroup

  ReadReplica:
    Type: AWS::RDS::DBInstance
    Properties:
      SourceDBInstanceIdentifier: !Ref DBInstance
      DBInstanceClass: db.r6g.large
      PubliclyAccessible: false
```

**When to Use RDS:**
- Need ACID transactions
- Complex queries with JOINs
- Existing relational data model
- Team familiar with SQL
- Moderate scale (< 10TB, < 100K QPS)

---

### Amazon Aurora

**Description:** AWS-built database compatible with PostgreSQL and MySQL. 5x faster than MySQL, 3x faster than PostgreSQL. Auto-scaling storage up to 128TB.

**Architecture:**
```
┌──────────────────────────────────────────┐
│         Aurora Cluster                    │
│                                           │
│  ┌──────────────┐     ┌──────────────┐   │
│  │   Primary    │     │  Read Replica│   │
│  │   Instance   │────►│  (Read-only) │   │
│  │ (Read/Write) │     └──────────────┘   │
│  └──────┬───────┘                         │
│         │                                 │
│         ▼                                 │
│  ┌─────────────────────────────────────┐ │
│  │     Shared Storage Volume           │ │
│  │   (6 copies across 3 AZs)           │ │
│  │   - Auto-scales to 128TB            │ │
│  │   - Self-healing                    │ │
│  │   - Continuous backup to S3         │ │
│  └─────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

**Key Features:**
- **Storage auto-scaling:** 10GB to 128TB automatically
- **High availability:** 6 copies across 3 AZs
- **Fast recovery:** < 30 seconds failover
- **Up to 15 read replicas:** Low-latency replication
- **Backtrack:** Rewind database to specific point in time (no restore needed)
- **Global Database:** < 1 second replication across regions
- **Serverless:** Auto-scaling compute (Aurora Serverless v2)

**Aurora Serverless v2:**
```yaml
Resources:
  AuroraCluster:
    Type: AWS::RDS::DBCluster
    Properties:
      Engine: aurora-postgresql
      EngineVersion: 14.6
      EngineMode: provisioned  # v2 uses provisioned mode
      DatabaseName: myapp
      MasterUsername: admin
      MasterUserPassword: !Sub '{{resolve:secretsmanager:${DBSecret}:SecretString:password}}'

      # Serverless scaling
      ServerlessV2ScalingConfiguration:
        MinCapacity: 0.5  # ACUs (Aurora Capacity Units)
        MaxCapacity: 16

      DBSubnetGroupName: !Ref DBSubnetGroup
      VPCSecurityGroupIds:
        - !Ref DBSecurityGroup

      BackupRetentionPeriod: 7
      EnableCloudwatchLogsExports:
        - postgresql

  ServerlessInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      Engine: aurora-postgresql
      DBInstanceClass: db.serverless
      DBClusterIdentifier: !Ref AuroraCluster
```

**Aurora Global Database:**
```
Primary Region (us-east-1)       Secondary Region (eu-west-1)
┌────────────────────┐           ┌────────────────────┐
│ Primary Cluster    │           │ Secondary Cluster  │
│ (Read/Write)       │           │ (Read-only)        │
│  - 1 Writer        ├──────────►│  - Read replicas   │
│  - N Readers       │ < 1 sec   │  - Promotion ready │
└────────────────────┘ latency   └────────────────────┘

Benefits:
- Global reads with low latency
- Disaster recovery (promote secondary in < 1 minute)
- Cross-region migration

Use cases:
- Global applications
- Multi-region high availability
- Read scaling across regions
```

**When to Use Aurora:**
- Need high performance (5x MySQL)
- Large databases (> 10TB)
- Need fast failover (< 30 seconds)
- Multi-region requirements
- High read throughput
- Team familiar with PostgreSQL/MySQL

**RDS vs Aurora:**
```
┌──────────────────┬──────────────┬──────────────┐
│ Feature          │ RDS          │ Aurora       │
├──────────────────┼──────────────┼──────────────┤
│ Performance      │ Standard     │ 5x faster    │
│ Max Storage      │ 64TB         │ 128TB        │
│ Failover Time    │ 60-120s      │ < 30s        │
│ Read Replicas    │ 5 (MySQL/PG) │ 15           │
│ Replication Lag  │ ~seconds     │ ~ms          │
│ Cost             │ Lower        │ 20% higher   │
│ Compatibility    │ 100%         │ Compatible   │
└──────────────────┴──────────────┴──────────────┘
```

---

## 3. NoSQL Databases

### Amazon DynamoDB

**Description:** Fully managed, serverless NoSQL key-value and document database. Single-digit millisecond latency at any scale. Auto-scales to handle millions of requests per second.

**Data Model:**
```
Table: Users
┌──────────────┬────────────┬──────────────────────────┐
│ Partition Key│ Sort Key   │ Attributes               │
├──────────────┼────────────┼──────────────────────────┤
│ user_id      │ -          │ name, email, created_at  │
│ (String)     │            │ (flexible schema)        │
└──────────────┴────────────┴──────────────────────────┘

Table: Orders
┌──────────────┬────────────┬──────────────────────────┐
│ Partition Key│ Sort Key   │ Attributes               │
├──────────────┼────────────┼──────────────────────────┤
│ user_id      │ order_date │ total, items, status     │
│ (String)     │ (String)   │                          │
└──────────────┴────────────┴──────────────────────────┘

Query patterns:
- Get user by user_id: Query by partition key
- Get user orders: Query by user_id, sort by order_date
- Get recent orders: Query user_id + condition on sort key
```

**Key Concepts:**

**Partition Key (Hash Key):**
- Determines physical partition
- Must be unique (for key-value) or shared (for composite key)
- Distribute evenly to avoid hot partitions

**Sort Key (Range Key):**
- Optional, used with partition key
- Enables range queries
- Items with same partition key stored together, sorted by sort key

**Capacity Modes:**
```
On-Demand:
- Pay per request ($1.25 per million writes, $0.25 per million reads)
- Auto-scales instantly
- No capacity planning
- Use: Unpredictable traffic, new applications

Provisioned:
- Specify RCU (Read Capacity Units) and WCU (Write Capacity Units)
- 1 RCU = 1 strongly consistent read/sec (4KB)
- 1 WCU = 1 write/sec (1KB)
- Auto-scaling available
- Cheaper at scale
- Use: Predictable traffic, cost optimization
```

**Global Secondary Index (GSI):**
```
Base Table: Users
PK: user_id, SK: -, Attributes: email, name, city

GSI: UsersByCity
PK: city, SK: name, Projected: email

Allows querying:
- All users in a city
- Users in city sorted by name

Considerations:
- Eventually consistent (slight delay)
- Separate capacity (RCU/WCU)
- Can be added after table creation
```

**Local Secondary Index (LSI):**
```
Base Table: Orders
PK: user_id, SK: order_date

LSI: OrdersByStatus
PK: user_id (same), SK: status, Projected: total, items

Allows querying:
- User orders by status instead of date

Considerations:
- Same partition key as base table
- Strongly consistent
- Must be created with table (can't add later)
- Max 5 LSIs per table
```

**DynamoDB Streams:**
```
Table changes → DynamoDB Stream → Lambda
                                   │
                                   ├─► Update ElasticSearch
                                   ├─► Send notification
                                   └─► Trigger workflow

Stream records:
- INSERT: New item
- MODIFY: Updated item
- REMOVE: Deleted item

Retention: 24 hours
Use cases: CDC, aggregation, cross-region replication
```

**Global Tables (Multi-Region):**
```
Region: us-east-1           Region: eu-west-1
┌─────────────────┐          ┌─────────────────┐
│  DynamoDB Table │◄────────►│  DynamoDB Table │
│  (Read/Write)   │ Bi-dir   │  (Read/Write)   │
└─────────────────┘ Repl.    └─────────────────┘

Features:
- Multi-region, multi-master
- < 1 second replication
- Conflict resolution (last write wins)
- Active-active architecture

Use cases:
- Global applications
- Low-latency reads worldwide
- Multi-region disaster recovery
```

**Example: E-commerce Schema:**
```python
# Table: Products
{
  "product_id": "PROD-123",  # Partition Key
  "name": "Laptop",
  "price": 999.99,
  "category": "Electronics",
  "stock": 50,
  "description": "...",
  "created_at": "2024-01-15T10:00:00Z"
}

# Table: Orders
{
  "user_id": "USER-456",     # Partition Key
  "order_id": "ORD-789",     # Sort Key
  "order_date": "2024-01-15",
  "total": 999.99,
  "status": "shipped",
  "items": [
    {
      "product_id": "PROD-123",
      "quantity": 1,
      "price": 999.99
    }
  ]
}

# GSI: OrdersByStatus
# PK: status, SK: order_date
# Allows: Get all shipped orders sorted by date

# Query Examples:
import boto3
dynamodb = boto3.resource('dynamodb')

# Get user orders
table = dynamodb.Table('Orders')
response = table.query(
    KeyConditionExpression='user_id = :uid',
    ExpressionAttributeValues={':uid': 'USER-456'}
)

# Get recent orders (last 7 days)
from datetime import datetime, timedelta
week_ago = (datetime.now() - timedelta(days=7)).isoformat()
response = table.query(
    KeyConditionExpression='user_id = :uid AND order_date > :date',
    ExpressionAttributeValues={
        ':uid': 'USER-456',
        ':date': week_ago
    }
)

# Query GSI: Get shipped orders
response = table.query(
    IndexName='OrdersByStatus',
    KeyConditionExpression='#status = :status',
    ExpressionAttributeNames={'#status': 'status'},
    ExpressionAttributeValues={':status': 'shipped'}
)
```

**When to Use DynamoDB:**
- Need single-digit millisecond latency
- Unpredictable or variable traffic
- Simple key-value or document access patterns
- Need massive scale (millions of requests/sec)
- Want serverless (no infrastructure)
- Multi-region active-active

**When NOT to Use:**
- Complex queries with JOINs
- Aggregations (SUM, AVG, COUNT across large datasets)
- Ad-hoc queries (unknown access patterns)
- Transactions across multiple tables (limited support)

---

### Amazon DocumentDB

**Description:** MongoDB-compatible document database. Fully managed, scales storage automatically.

**When to Use:**
- Need MongoDB compatibility
- Migrating from MongoDB
- Document data model
- Want AWS management

**Architecture:**
```
DocumentDB Cluster
├── Primary Instance (Read/Write)
├── Read Replica 1 (Read)
├── Read Replica 2 (Read)
└── Shared Storage (auto-scales to 64TB)
```

---

### Amazon Keyspaces (Cassandra)

**Description:** Managed Apache Cassandra-compatible database. Serverless, scalable, highly available.

**When to Use:**
- Wide-column data model
- Need Cassandra compatibility
- High write throughput
- Time-series data
- IoT applications

**Data Model:**
```
Keyspace: myapp
  └── Table: sensor_data
      ├── Partition Key: sensor_id
      ├── Clustering Key: timestamp
      └── Columns: temperature, humidity, location
```

---

## 4. Caching Strategies

### Amazon ElastiCache

**Description:** Managed in-memory cache supporting Redis and Memcached. Sub-millisecond latency, reduces database load.

**Redis vs Memcached:**
```
┌──────────────────┬──────────────┬──────────────┐
│ Feature          │ Redis        │ Memcached    │
├──────────────────┼──────────────┼──────────────┤
│ Data Structures  │ Rich (lists, │ String only  │
│                  │ sets, sorted)│              │
│ Persistence      │ Yes (RDB,AOF)│ No           │
│ Replication      │ Yes          │ No           │
│ Pub/Sub          │ Yes          │ No           │
│ Transactions     │ Yes          │ No           │
│ Lua Scripting    │ Yes          │ No           │
│ Multi-threaded   │ Single       │ Yes          │
│ Max Item Size    │ 512MB        │ 1MB          │
│ Use Case         │ Complex cache│ Simple cache │
└──────────────────┴──────────────┴──────────────┘

Choose Redis: Rich features, persistence, pub/sub
Choose Memcached: Simple caching, multi-core utilization
```

**Redis Cluster Mode:**
```
Redis Cluster (Sharded)
├── Shard 1
│   ├── Primary (Read/Write)
│   └── Replica (Read)
├── Shard 2
│   ├── Primary (Read/Write)
│   └── Replica (Read)
└── Shard 3
    ├── Primary (Read/Write)
    └── Replica (Read)

Benefits:
- Horizontal scaling (up to 500 nodes)
- Partitioning (distribute data across shards)
- High availability (automatic failover)

Data distribution: Hash slot (CRC16 of key % 16384)
```

**Caching Patterns:**

**1. Cache-Aside (Lazy Loading):**
```python
def get_user(user_id):
    # Try cache first
    cached = redis.get(f"user:{user_id}")
    if cached:
        return json.loads(cached)

    # Cache miss - fetch from database
    user = db.query("SELECT * FROM users WHERE id = %s", user_id)

    # Write to cache
    redis.setex(
        f"user:{user_id}",
        3600,  # TTL: 1 hour
        json.dumps(user)
    )

    return user

Pros:
- Only cache what's needed
- Resilient (cache failure doesn't break app)

Cons:
- Cache miss penalty (3 network trips)
- Stale data possible
```

**2. Write-Through:**
```python
def update_user(user_id, data):
    # Update database
    db.query("UPDATE users SET ... WHERE id = %s", user_id, data)

    # Update cache immediately
    redis.setex(
        f"user:{user_id}",
        3600,
        json.dumps(data)
    )

Pros:
- Cache always up-to-date
- No stale data

Cons:
- Write latency (2 network calls)
- Wasted cache space (cache unused data)
```

**3. Write-Behind (Write-Back):**
```python
def update_user(user_id, data):
    # Write to cache immediately
    redis.setex(f"user:{user_id}", 3600, json.dumps(data))

    # Queue for async database write
    queue.send({
        'action': 'update_user',
        'user_id': user_id,
        'data': data
    })

    return "OK"

# Background worker
def worker():
    while True:
        msg = queue.receive()
        db.query("UPDATE users ...")
        queue.delete(msg)

Pros:
- Fast writes (1 network call)
- Batch database writes

Cons:
- Risk of data loss (if cache fails before write)
- Complex to implement
```

**Cache Invalidation:**
```python
# 1. TTL (Time-To-Live)
redis.setex("key", 300, value)  # Expire after 5 minutes

# 2. Event-driven (on update)
def update_user(user_id, data):
    db.update(user_id, data)
    redis.delete(f"user:{user_id}")  # Invalidate cache

# 3. Manual (admin action)
redis.delete(f"user:{user_id}")

# 4. Pattern-based (delete all related)
for key in redis.scan_iter("user:*"):
    redis.delete(key)
```

**Redis Data Structures:**
```python
# Strings
redis.set("key", "value")
redis.get("key")

# Hashes (objects)
redis.hset("user:123", mapping={
    "name": "John",
    "email": "john@example.com"
})
redis.hgetall("user:123")

# Lists (queues, activity feeds)
redis.lpush("feed:123", "post1")
redis.lrange("feed:123", 0, 9)  # Get 10 most recent

# Sets (unique items, tags)
redis.sadd("tags:post:123", "python", "redis", "cache")
redis.smembers("tags:post:123")

# Sorted Sets (leaderboards, rankings)
redis.zadd("leaderboard", {"player1": 1000, "player2": 1500})
redis.zrevrange("leaderboard", 0, 9, withscores=True)  # Top 10

# Pub/Sub (real-time messaging)
redis.publish("notifications", "New message")

# Streams (message queues, event logs)
redis.xadd("events", {"action": "login", "user": "123"})
```

---

### Amazon DAX (DynamoDB Accelerator)

**Description:** In-memory cache for DynamoDB. Microsecond latency, fully managed, compatible with DynamoDB APIs.

**Architecture:**
```
Application
    │
    ├──► DAX Cluster (cache)
    │      │
    │      ├─► Cache Hit (microseconds)
    │      │
    │      └─► Cache Miss
    │             │
    └─────────────▼
         DynamoDB (milliseconds)
```

**When to Use DAX:**
- DynamoDB read-heavy workload
- Need microsecond latency
- Repeated reads of same items
- Want transparent caching (no code changes for reads)

**DAX vs ElastiCache:**
```
DAX:
- DynamoDB-specific
- Transparent (same API as DynamoDB)
- Write-through cache
- Microsecond latency

ElastiCache:
- General-purpose cache
- Requires code changes
- More control over caching logic
- Sub-millisecond latency
```

---

## 5. Object Storage

### Amazon S3

**Description:** Object storage service with 99.999999999% (11 nines) durability. Stores any type of file. Infinitely scalable.

**Storage Classes:**
```
S3 Standard:
- Frequent access
- Millisecond latency
- 99.99% availability
- Cost: $0.023/GB/month
- Use: Active data, websites, content distribution

S3 Intelligent-Tiering:
- Auto-moves between access tiers
- No retrieval fees
- Cost: $0.023-$0.0125/GB + monitoring fee
- Use: Unknown or changing access patterns

S3 Standard-IA (Infrequent Access):
- Infrequent but rapid access
- Cost: $0.0125/GB/month + retrieval fee
- Use: Backups, disaster recovery

S3 One Zone-IA:
- Single AZ (less resilient)
- Cost: $0.01/GB/month + retrieval fee
- Use: Recreatable data, secondary backups

S3 Glacier Instant Retrieval:
- Archive, millisecond retrieval
- Cost: $0.004/GB/month + retrieval fee
- Use: Rarely accessed archives needing instant access

S3 Glacier Flexible Retrieval:
- Archive, minutes-hours retrieval
- Cost: $0.0036/GB/month + retrieval fee
- Use: Backups, archives

S3 Glacier Deep Archive:
- Long-term archive, 12-hour retrieval
- Cost: $0.00099/GB/month + retrieval fee
- Use: Compliance archives, 7-10 year retention
```

**Lifecycle Policies:**
```yaml
LifecycleConfiguration:
  Rules:
    # Transition to cheaper storage classes over time
    - Id: ArchiveOldData
      Status: Enabled
      Filter:
        Prefix: logs/
      Transitions:
        - Days: 30
          StorageClass: STANDARD_IA
        - Days: 90
          StorageClass: GLACIER_IR
        - Days: 365
          StorageClass: DEEP_ARCHIVE
      Expiration:
        Days: 2555  # 7 years, delete

    # Clean up incomplete multipart uploads
    - Id: CleanupMultipart
      Status: Enabled
      AbortIncompleteMultipartUpload:
        DaysAfterInitiation: 7

    # Delete old versions
    - Id: DeleteOldVersions
      Status: Enabled
      NoncurrentVersionExpiration:
        NoncurrentDays: 90
```

**S3 Features:**

**Versioning:**
```
Enabled: Every update creates new version
Benefits:
- Accidental deletion protection
- Rollback capability
- Audit trail

Cost: Storage for all versions

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled

# List versions
aws s3api list-object-versions --bucket my-bucket
```

**Replication:**
```yaml
# Cross-Region Replication (CRR) or Same-Region Replication (SRR)
ReplicationConfiguration:
  Role: arn:aws:iam::123456789:role/s3-replication
  Rules:
    - Id: ReplicateAll
      Status: Enabled
      Priority: 1
      Filter:
        Prefix: ''
      Destination:
        Bucket: arn:aws:s3:::backup-bucket
        ReplicationTime:
          Status: Enabled
          Time:
            Minutes: 15  # S3 RTC: replicate in 15 minutes
        Metrics:
          Status: Enabled
          EventThreshold:
            Minutes: 15
      DeleteMarkerReplication:
        Status: Enabled

Use cases:
- Disaster recovery
- Compliance (data residency)
- Lower latency access
- Backup to separate account
```

**S3 Performance:**
```
Throughput:
- 3,500 PUT/COPY/POST/DELETE per second per prefix
- 5,500 GET/HEAD per second per prefix

Prefix examples:
s3://bucket/folder1/  (prefix: folder1/)
s3://bucket/folder2/  (prefix: folder2/)

Parallelization:
- Use multiple prefixes for higher throughput
- 10 prefixes = 35,000 PUT/s, 55,000 GET/s

Multipart Upload:
- Recommended for files > 100MB
- Required for files > 5GB
- Parallel uploads of parts
- Faster, resilient to network issues

Transfer Acceleration:
- Upload to edge location, route via AWS backbone
- Up to 50-500% faster for long-distance uploads
- Cost: $0.04-$0.08/GB
```

**S3 Event Notifications:**
```yaml
NotificationConfiguration:
  LambdaFunctionConfigurations:
    - Id: ImageUploadProcessor
      LambdaFunctionArn: arn:aws:lambda:us-east-1:123:function:ProcessImage
      Events:
        - s3:ObjectCreated:*
      Filter:
        Key:
          FilterRules:
            - Name: suffix
              Value: .jpg

  QueueConfigurations:
    - Id: LogProcessor
      QueueArn: arn:aws:sqs:us-east-1:123:log-queue
      Events:
        - s3:ObjectCreated:*
      Filter:
        Key:
          FilterRules:
            - Name: prefix
              Value: logs/

Use cases:
- Trigger Lambda on upload (image resize, data processing)
- Send to SQS for async processing
- Notify SNS for email/SMS alerts
```

---

## 6. Message Queues & Streaming

### Amazon SQS (Simple Queue Service)

**Description:** Fully managed message queue. Decouple components, buffer requests, distribute tasks.

**Queue Types:**
```
Standard Queue:
- At-least-once delivery (duplicates possible)
- Best-effort ordering
- Unlimited throughput
- Use: High throughput, order not critical

FIFO Queue:
- Exactly-once processing
- Strict ordering
- Up to 3,000 msg/sec (300/sec per group)
- Use: Order critical, no duplicates allowed
```

**Message Lifecycle:**
```
Producer → SQS Queue → Consumer
                │
                └─► Visibility Timeout (message invisible)
                    │
                    ├─► Consumer processes successfully
                    │   └─► Consumer deletes message
                    │
                    └─► Timeout expires (consumer failed)
                        └─► Message visible again (retry)
```

**Dead Letter Queue:**
```yaml
Resources:
  MainQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: orders-queue
      VisibilityTimeout: 300
      MessageRetentionPeriod: 345600  # 4 days
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt DLQ.Arn
        maxReceiveCount: 3  # Move to DLQ after 3 failed attempts

  DLQ:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: orders-dlq
      MessageRetentionPeriod: 1209600  # 14 days

Use cases:
- Isolate poison messages
- Debug failed processing
- Manual review and reprocessing
```

---

### Amazon Kinesis

**Description:** Real-time data streaming service. Process logs, metrics, IoT data, clickstreams.

**Kinesis Data Streams:**
```
Producers                 Stream              Consumers
┌──────────┐             ┌─────────┐         ┌──────────┐
│ App logs │────────────►│ Shard 1 │────────►│ Lambda   │
│ IoT data │             ├─────────┤         │ KCL App  │
│ Metrics  │────────────►│ Shard 2 │────────►│ Firehose │
└──────────┘             ├─────────┤         └──────────┘
                         │ Shard N │
                         └─────────┘

Shard:
- 1 MB/sec input or 1,000 records/sec
- 2 MB/sec output
- Ordered within shard

Retention: 24 hours (default), up to 365 days
Replayable: Can reprocess historical data
```

**Kinesis Data Firehose:**
```
Sources → Firehose → Destinations
          │
          ├─► Transform (Lambda)
          ├─► Buffer (60s or 1MB)
          │
          ├─► S3 (common)
          ├─► Redshift
          ├─► OpenSearch
          └─► HTTP endpoint

Use: Load streaming data into data lakes/warehouses
No code, fully managed
```

---

### Amazon MSK (Managed Streaming for Kafka)

**Description:** Fully managed Apache Kafka. For teams already using Kafka or need Kafka features.

**When to Use MSK:**
- Need Kafka specifically
- Complex stream processing
- Team has Kafka expertise
- Integration with Kafka ecosystem

**MSK vs Kinesis:**
```
Kinesis:
- AWS-native, simpler
- Auto-scaling
- Pay-per-use
- Good for most use cases

MSK:
- Kafka compatibility
- More features (transactions, exactly-once)
- Manual scaling
- Use if need Kafka specifically
```

---

## 7. Search & Analytics

### Amazon OpenSearch (Elasticsearch)

**Description:** Managed search and analytics engine. Full-text search, log analytics, application monitoring.

**Use Cases:**
- **Full-text search:** Product catalog, documentation
- **Log analytics:** Centralized logging, troubleshooting
- **Application monitoring:** APM, traces, metrics
- **Security analytics:** SIEM, threat detection

**Architecture:**
```
Data Sources        OpenSearch          Visualization
┌──────────┐       ┌──────────┐        ┌──────────┐
│ App logs │──────►│ Ingest   │        │ Kibana   │
│ Metrics  │       │ Index    │◄──────►│Dashboards│
│ Events   │──────►│ Search   │        └──────────┘
└──────────┘       └──────────┘
```

**Index:**
```json
// Create index with mapping
PUT /products
{
  "mappings": {
    "properties": {
      "name": { "type": "text" },
      "description": { "type": "text" },
      "price": { "type": "float" },
      "category": { "type": "keyword" },
      "tags": { "type": "keyword" },
      "created_at": { "type": "date" }
    }
  }
}

// Search
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "description": "laptop" } }
      ],
      "filter": [
        { "range": { "price": { "lte": 1000 } } },
        { "term": { "category": "Electronics" } }
      ]
    }
  },
  "sort": [
    { "price": "asc" }
  ]
}
```

---

## 8. Interview Tips

### Data Modeling Questions

**Approach:**
1. **Understand access patterns:**
   - "How will data be queried?"
   - "Read-heavy or write-heavy?"

2. **Choose database:**
   - "For user profiles with complex queries, I'd use RDS PostgreSQL..."
   - "For high-throughput product catalog, DynamoDB with GSI..."

3. **Design schema:**
   - Explain partition key, sort key choices
   - Discuss indexes needed

4. **Caching strategy:**
   - "Cache user profiles in Redis for 1 hour..."
   - "Cache-aside pattern, invalidate on update..."

5. **Scaling approach:**
   - Read replicas, sharding, caching

---

## Summary

**Key Takeaways:**

1. **RDS/Aurora:** Relational, ACID, complex queries, moderate scale
2. **DynamoDB:** NoSQL, massive scale, simple access patterns, single-digit ms latency
3. **ElastiCache:** In-memory cache, sub-ms latency, reduce database load
4. **S3:** Object storage, 11 nines durability, lifecycle policies, versioning
5. **SQS:** Message queue, decouple components, reliable delivery
6. **Kinesis:** Real-time streaming, log/event processing, replay capability
7. **OpenSearch:** Full-text search, log analytics, complex queries

**Selection criteria:**
- Access patterns drive database choice
- Cache hot data for performance
- Use message queues for async, decoupling
- S3 for objects, backups, data lakes
- Choose consistency vs availability based on requirements

The data layer is the heart of your system. Choose wisely based on access patterns, scale, and consistency needs!
