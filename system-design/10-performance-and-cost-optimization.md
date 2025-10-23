# Performance & Cost Optimization - System Design Cheatsheet

## Overview

Performance optimization ensures systems meet latency and throughput requirements. Cost optimization reduces spend while maintaining performance and reliability.

**Key Principle:** Optimize for cost without sacrificing user experience.

---

## 1. Performance Optimization

### Latency vs Throughput

- **Latency**: Time to complete a single request (milliseconds)
- **Throughput**: Requests handled per second (RPS)

```python
# Example: Optimizing for latency vs throughput
import concurrent.futures
import time

# Sequential (low throughput, consistent latency)
def process_sequential(items):
    results = []
    for item in items:
        results.append(expensive_operation(item))
    return results

# Parallel (high throughput, variable latency)
def process_parallel(items, workers=10):
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        results = list(executor.map(expensive_operation, items))
    return results

# Batching (balance throughput and latency)
def process_batched(items, batch_size=100):
    results = []
    for i in range(0, len(items), batch_size):
        batch = items[i:i+batch_size]
        results.extend(batch_process(batch))  # Single API call
    return results
```

### Caching Strategies

#### 1. Cache-Aside (Lazy Loading)

```python
import redis
import json

cache = redis.Redis(host='localhost', port=6379, db=0)

def get_user(user_id: str):
    # Check cache first
    cached = cache.get(f'user:{user_id}')
    if cached:
        return json.loads(cached)

    # Cache miss - fetch from DB
    user = db.users.find_one({'id': user_id})

    # Store in cache (TTL 1 hour)
    cache.setex(f'user:{user_id}', 3600, json.dumps(user))

    return user

def update_user(user_id: str, data: dict):
    # Update database
    db.users.update_one({'id': user_id}, {'$set': data})

    # Invalidate cache
    cache.delete(f'user:{user_id}')
```

#### 2. Write-Through Cache

```python
def update_user_write_through(user_id: str, data: dict):
    # Update database
    db.users.update_one({'id': user_id}, {'$set': data})

    # Update cache immediately
    user = db.users.find_one({'id': user_id})
    cache.setex(f'user:{user_id}', 3600, json.dumps(user))
```

#### 3. Write-Behind (Write-Back) Cache

```python
import queue
import threading

write_queue = queue.Queue()

def update_user_write_behind(user_id: str, data: dict):
    # Update cache immediately
    user = data.copy()
    user['id'] = user_id
    cache.setex(f'user:{user_id}', 3600, json.dumps(user))

    # Queue database write
    write_queue.put(('user', user_id, data))

# Background worker
def database_writer():
    while True:
        table, id, data = write_queue.get()
        try:
            if table == 'user':
                db.users.update_one({'id': id}, {'$set': data})
        except Exception as e:
            logger.error(f'Failed to write {table}:{id}', error=str(e))
            # Re-queue or DLQ

threading.Thread(target=database_writer, daemon=True).start()
```

#### 4. Multi-Level Caching

```python
# L1: Local in-memory cache (fastest)
# L2: Redis (fast, shared)
# L3: Database (slowest)

from functools import lru_cache

# L1 cache (in-process, 1000 items)
@lru_cache(maxsize=1000)
def get_user_l1(user_id: str):
    # L2 cache (Redis)
    cached = cache.get(f'user:{user_id}')
    if cached:
        return json.loads(cached)

    # L3 cache (database)
    user = db.users.find_one({'id': user_id})
    cache.setex(f'user:{user_id}', 3600, json.dumps(user))

    return user
```

### Database Optimization

#### Indexing

```sql
-- Query without index (slow)
SELECT * FROM orders WHERE user_id = '123' AND status = 'pending';
-- Scans entire table: 10,000ms

-- Create composite index
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
-- Query now takes: 5ms

-- Index statistics
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = '123' AND status = 'pending';

-- Result:
-- Index Scan using idx_orders_user_status on orders (cost=0.43..8.45 rows=1)
```

```python
# MongoDB indexing
from pymongo import IndexModel, ASCENDING, DESCENDING

# Create indexes
db.orders.create_index([
    ('user_id', ASCENDING),
    ('status', ASCENDING)
])

# Compound index with sort optimization
db.orders.create_index([
    ('user_id', ASCENDING),
    ('created_at', DESCENDING)
])

# Analyze query performance
db.orders.find({
    'user_id': '123',
    'status': 'pending'
}).explain('executionStats')
```

#### Query Optimization

```sql
-- Bad: N+1 queries
SELECT * FROM orders WHERE user_id = '123';
-- Then for each order:
SELECT * FROM order_items WHERE order_id = ?;

-- Good: JOIN (1 query)
SELECT o.*, oi.*
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
WHERE o.user_id = '123';

-- Bad: SELECT *
SELECT * FROM users WHERE id = '123';

-- Good: SELECT specific fields
SELECT id, name, email FROM users WHERE id = '123';

-- Use LIMIT for pagination
SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 50 OFFSET 0;
```

#### Connection Pooling

```python
import psycopg2.pool

# Create connection pool
db_pool = psycopg2.pool.ThreadedConnectionPool(
    minconn=5,      # Minimum connections
    maxconn=20,     # Maximum connections
    host='localhost',
    database='mydb',
    user='user',
    password='password'
)

def get_user(user_id: str):
    conn = db_pool.getconn()
    try:
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM users WHERE id = %s', (user_id,))
        return cursor.fetchone()
    finally:
        db_pool.putconn(conn)  # Return to pool
```

### API Optimization

#### GraphQL DataLoader (Batch + Cache)

```javascript
const DataLoader = require('dataloader');

// Batch loader for users
const userLoader = new DataLoader(async (userIds) => {
  // Single database query for all users
  const users = await db.users.find({
    id: { $in: userIds }
  });

  // Return in same order as requested
  const userMap = new Map(users.map(u => [u.id, u]));
  return userIds.map(id => userMap.get(id));
});

// Usage in GraphQL resolver
const resolvers = {
  Order: {
    user: (order) => userLoader.load(order.userId)
  }
};

// Result:
// Instead of 100 queries for 100 orders, makes 1 query
```

#### Pagination

```python
from flask import request

# Cursor-based pagination (better for large datasets)
@app.route('/api/orders')
def get_orders():
    cursor = request.args.get('cursor')
    limit = int(request.args.get('limit', 50))

    query = {'user_id': g.user_id}
    if cursor:
        query['_id'] = {'$gt': ObjectId(cursor)}

    orders = db.orders.find(query).sort('_id', 1).limit(limit + 1)
    orders_list = list(orders)

    has_more = len(orders_list) > limit
    if has_more:
        orders_list = orders_list[:limit]

    next_cursor = str(orders_list[-1]['_id']) if has_more else None

    return {
        'data': orders_list,
        'pagination': {
            'next_cursor': next_cursor,
            'has_more': has_more
        }
    }
```

### CDN Optimization

```javascript
// CloudFront configuration
{
  "DistributionConfig": {
    "CacheBehaviors": {
      "Items": [
        {
          "PathPattern": "/api/*",
          "TargetOriginId": "api-origin",
          "ViewerProtocolPolicy": "redirect-to-https",
          "AllowedMethods": ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"],
          "CachedMethods": ["GET", "HEAD", "OPTIONS"],
          "CachePolicyId": "4135ea2d-6df8-44a3-9df3-4b5a84be39ad",  // CachingDisabled
          "OriginRequestPolicyId": "216adef6-5c7f-47e4-b989-5492eafa07d3"  // AllViewer
        },
        {
          "PathPattern": "/static/*",
          "TargetOriginId": "s3-origin",
          "ViewerProtocolPolicy": "redirect-to-https",
          "Compress": true,  // Enable compression
          "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",  // CachingOptimized
          "ResponseHeadersPolicyId": "60669652-455b-4ae9-85a7-c6744c27f682"  // CORS-with-preflight
        }
      ]
    },
    "CustomErrorResponses": {
      "Items": [
        {
          "ErrorCode": 404,
          "ResponseCode": 200,
          "ResponsePagePath": "/index.html",  // SPA routing
          "ErrorCachingMinTTL": 300
        }
      ]
    }
  }
}
```

```python
# Set proper cache headers
from flask import Flask, send_file, make_response

@app.route('/static/<path:filename>')
def serve_static(filename):
    response = make_response(send_file(f'static/{filename}'))

    # Cache static assets for 1 year
    if filename.endswith(('.jpg', '.png', '.css', '.js')):
        response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'

    # Cache HTML for 5 minutes
    elif filename.endswith('.html'):
        response.headers['Cache-Control'] = 'public, max-age=300, must-revalidate'

    return response
```

### Compression

```python
from flask import Flask
from flask_compress import Compress

app = Flask(__name__)
Compress(app)  # Enable gzip compression

# Configure
app.config['COMPRESS_MIMETYPES'] = [
    'text/html',
    'text/css',
    'text/xml',
    'application/json',
    'application/javascript'
]
app.config['COMPRESS_LEVEL'] = 6  # 1-9 (higher = more compression, slower)
app.config['COMPRESS_MIN_SIZE'] = 500  # Only compress responses > 500 bytes
```

### Async I/O

```python
import asyncio
import aiohttp
import aioboto3

# Sequential (slow)
def get_user_data_sync(user_id):
    user = requests.get(f'http://user-service/users/{user_id}').json()
    orders = requests.get(f'http://order-service/orders?user_id={user_id}').json()
    payments = requests.get(f'http://payment-service/payments?user_id={user_id}').json()
    return {'user': user, 'orders': orders, 'payments': payments}
# Takes: 300ms (3 x 100ms)

# Parallel (fast)
async def get_user_data_async(user_id):
    async with aiohttp.ClientSession() as session:
        user_task = session.get(f'http://user-service/users/{user_id}')
        orders_task = session.get(f'http://order-service/orders?user_id={user_id}')
        payments_task = session.get(f'http://payment-service/payments?user_id={user_id}')

        user_resp, orders_resp, payments_resp = await asyncio.gather(
            user_task, orders_task, payments_task
        )

        return {
            'user': await user_resp.json(),
            'orders': await orders_resp.json(),
            'payments': await payments_resp.json()
        }
# Takes: 100ms (parallel execution)
```

---

## 2. Cost Optimization

### AWS Cost Optimization Strategies

#### 1. Right-Sizing

```python
import boto3
from datetime import datetime, timedelta

cloudwatch = boto3.client('cloudwatch')
ec2 = boto3.client('ec2')

def analyze_instance_utilization(instance_id):
    """Identify over-provisioned instances"""

    # Get CPU utilization for last 30 days
    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/EC2',
        MetricName='CPUUtilization',
        Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
        StartTime=datetime.now() - timedelta(days=30),
        EndTime=datetime.now(),
        Period=3600,
        Statistics=['Average', 'Maximum']
    )

    avg_cpu = sum(dp['Average'] for dp in response['Datapoints']) / len(response['Datapoints'])
    max_cpu = max(dp['Maximum'] for dp in response['Datapoints'])

    # Recommend downsize if consistently under-utilized
    if avg_cpu < 20 and max_cpu < 50:
        print(f"Instance {instance_id} is under-utilized (avg: {avg_cpu}%, max: {max_cpu}%)")
        print(f"Recommendation: Downsize to save ~30-50% on costs")

        # Get current instance type
        instance = ec2.describe_instances(InstanceIds=[instance_id])
        current_type = instance['Reservations'][0]['Instances'][0]['InstanceType']

        # Suggest smaller instance
        size_map = {
            't3.xlarge': 't3.large',
            't3.large': 't3.medium',
            'm5.2xlarge': 'm5.xlarge',
            'm5.xlarge': 'm5.large'
        }
        recommended = size_map.get(current_type, 'Review manually')
        print(f"Current: {current_type} → Recommended: {recommended}")
```

#### 2. Reserved Instances & Savings Plans

```python
# Cost comparison
pricing = {
    'on_demand': {
        't3.large': 0.0832,  # per hour
        'm5.xlarge': 0.192
    },
    'reserved_1yr': {
        't3.large': 0.0499,  # 40% savings
        'm5.xlarge': 0.115   # 40% savings
    },
    'reserved_3yr': {
        't3.large': 0.0333,  # 60% savings
        'm5.xlarge': 0.077   # 60% savings
    }
}

# Calculate annual savings
instance_count = 10
hours_per_year = 8760

on_demand_cost = pricing['on_demand']['m5.xlarge'] * instance_count * hours_per_year
reserved_1yr_cost = pricing['reserved_1yr']['m5.xlarge'] * instance_count * hours_per_year
reserved_3yr_cost = pricing['reserved_3yr']['m5.xlarge'] * instance_count * hours_per_year

print(f"On-Demand: ${on_demand_cost:,.2f}/year")
print(f"1-Year Reserved: ${reserved_1yr_cost:,.2f}/year (Save ${on_demand_cost - reserved_1yr_cost:,.2f})")
print(f"3-Year Reserved: ${reserved_3yr_cost:,.2f}/year (Save ${on_demand_cost - reserved_3yr_cost:,.2f})")

# Output:
# On-Demand: $16,819.20/year
# 1-Year Reserved: $10,074.00/year (Save $6,745.20)
# 3-Year Reserved: $6,745.20/year (Save $10,074.00)
```

#### 3. Spot Instances

```yaml
# ECS with Fargate Spot (70% cheaper)
Resources:
  ECSService:
    Type: AWS::ECS::Service
    Properties:
      Cluster: !Ref ECSCluster
      TaskDefinition: !Ref TaskDefinition
      DesiredCount: 10
      CapacityProviderStrategy:
        - CapacityProvider: FARGATE_SPOT
          Weight: 70  # 70% on Spot
          Base: 0
        - CapacityProvider: FARGATE
          Weight: 30  # 30% on On-Demand (for stability)
          Base: 2     # Minimum 2 tasks on On-Demand
```

```yaml
# Kubernetes with Spot instances
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot", "on-demand"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["m5.large", "m5.xlarge"]

  # Prefer Spot instances
  weight: 100

  # Spot instance interruption handling
  ttlSecondsAfterEmpty: 30
  ttlSecondsUntilExpired: 604800

---
# Deployment tolerates Spot interruptions
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 10
  template:
    spec:
      tolerations:
      - key: karpenter.sh/capacity-type
        value: spot
        operator: Equal
        effect: NoSchedule
```

#### 4. Auto Scaling

```python
# Scale down during off-hours
import boto3
from datetime import datetime

autoscaling = boto3.client('autoscaling')

def schedule_scaling():
    current_hour = datetime.now().hour

    # Business hours: 9 AM - 6 PM
    if 9 <= current_hour < 18:
        desired_capacity = 10
    # Off-hours
    else:
        desired_capacity = 2

    autoscaling.set_desired_capacity(
        AutoScalingGroupName='web-app-asg',
        DesiredCapacity=desired_capacity,
        HonorCooldown=False
    )

# Save ~60% on compute costs during off-hours
```

#### 5. S3 Storage Classes

```python
import boto3

s3 = boto3.client('s3')

# Set lifecycle policy
s3.put_bucket_lifecycle_configuration(
    Bucket='my-bucket',
    LifecycleConfiguration={
        'Rules': [
            {
                'Id': 'Archive old data',
                'Status': 'Enabled',
                'Filter': {'Prefix': 'logs/'},
                'Transitions': [
                    {
                        'Days': 30,
                        'StorageClass': 'STANDARD_IA'  # Save 50%
                    },
                    {
                        'Days': 90,
                        'StorageClass': 'GLACIER_IR'  # Save 68%
                    },
                    {
                        'Days': 180,
                        'StorageClass': 'DEEP_ARCHIVE'  # Save 95%
                    }
                ],
                'Expiration': {
                    'Days': 365  # Delete after 1 year
                }
            },
            {
                'Id': 'Delete incomplete multipart uploads',
                'Status': 'Enabled',
                'AbortIncompleteMultipartUpload': {
                    'DaysAfterInitiation': 7
                }
            }
        ]
    }
)

# Cost comparison (per GB per month)
storage_classes = {
    'STANDARD': 0.023,
    'INTELLIGENT_TIERING': 0.023,  # Auto-optimizes
    'STANDARD_IA': 0.0125,  # 46% cheaper
    'GLACIER_INSTANT_RETRIEVAL': 0.004,  # 83% cheaper
    'GLACIER_FLEXIBLE_RETRIEVAL': 0.0036,  # 84% cheaper
    'GLACIER_DEEP_ARCHIVE': 0.00099  # 96% cheaper
}
```

#### 6. Database Optimization

```python
# Aurora Serverless v2 (scale to zero)
{
  "Engine": "aurora-postgresql",
  "EngineVersion": "14.6",
  "DBClusterIdentifier": "my-cluster",
  "ServerlessV2ScalingConfiguration": {
    "MinCapacity": 0.5,  # 0.5 ACU = $0.06/hour
    "MaxCapacity": 16    # 16 ACU = $1.92/hour
  }
}

# RDS: Use storage auto-scaling
{
  "AllocatedStorage": 100,
  "MaxAllocatedStorage": 1000,  # Auto-scale up to 1TB
  "StorageType": "gp3"  # 20% cheaper than gp2
}

# ElastiCache: Use reserved nodes
# 1 year reserved: 30% savings
# 3 year reserved: 55% savings
```

#### 7. Lambda Optimization

```python
import boto3

lambda_client = boto3.client('lambda')

# Optimize memory allocation (impacts CPU and cost)
def optimize_lambda_memory(function_name):
    """Find optimal memory configuration"""

    memory_configs = [128, 256, 512, 1024, 2048, 3008]
    results = {}

    for memory in memory_configs:
        # Update function memory
        lambda_client.update_function_configuration(
            FunctionName=function_name,
            MemorySize=memory
        )

        # Invoke function and measure
        response = lambda_client.invoke(
            FunctionName=function_name,
            InvocationType='RequestResponse'
        )

        duration = response['ResponseMetadata']['HTTPHeaders']['x-amz-function-duration']
        billed_duration = response['ResponseMetadata']['HTTPHeaders']['x-amz-billed-duration']

        # Calculate cost
        price_per_gb_second = 0.0000166667
        cost = (memory / 1024) * (int(billed_duration) / 1000) * price_per_gb_second

        results[memory] = {
            'duration': duration,
            'cost': cost
        }

    # Find cheapest configuration
    optimal = min(results.items(), key=lambda x: x[1]['cost'])
    print(f"Optimal memory: {optimal[0]} MB (${optimal[1]['cost']:.6f} per invocation)")

# Use ARM (Graviton2) for 20% cost savings
lambda_client.update_function_configuration(
    FunctionName='my-function',
    Architectures=['arm64']  # 20% cheaper than x86_64
)
```

#### 8. Data Transfer Optimization

```python
# Avoid data transfer costs
# - Same region: FREE
# - Cross-region: $0.02/GB
# - Internet egress: $0.09/GB

# Use VPC endpoints to avoid NAT Gateway costs
# NAT Gateway: $0.045/hour + $0.045/GB processed = ~$50/month
# VPC Endpoint: $0.01/hour = ~$7/month (saves $43/month)

# CloudFront reduces data transfer costs
# Origin to CloudFront: $0.02/GB
# CloudFront to Internet: $0.085/GB (first 10TB)
# Direct S3 to Internet: $0.09/GB

# Use S3 Transfer Acceleration for uploads
s3.upload_file(
    'large-file.zip',
    'my-bucket',
    'large-file.zip',
    Config=TransferConfig(use_threads=True),
    ExtraArgs={
        'ContentType': 'application/zip',
        'StorageClass': 'INTELLIGENT_TIERING'
    }
)
```

### Cost Monitoring

```python
import boto3
from datetime import datetime, timedelta

ce = boto3.client('ce')  # Cost Explorer

def get_cost_breakdown():
    """Get cost breakdown by service"""

    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d'),
            'End': datetime.now().strftime('%Y-%m-%d')
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )

    costs = {}
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            costs[service] = cost

    # Sort by cost
    sorted_costs = sorted(costs.items(), key=lambda x: x[1], reverse=True)

    print("Cost Breakdown (Last 30 days):")
    total = 0
    for service, cost in sorted_costs[:10]:  # Top 10
        print(f"{service}: ${cost:.2f}")
        total += cost

    print(f"\nTotal: ${total:.2f}")

# Set budget alerts
budgets = boto3.client('budgets')

budgets.create_budget(
    AccountId='123456789012',
    Budget={
        'BudgetName': 'Monthly-Budget',
        'BudgetLimit': {
            'Amount': '10000',
            'Unit': 'USD'
        },
        'TimeUnit': 'MONTHLY',
        'BudgetType': 'COST'
    },
    NotificationsWithSubscribers=[
        {
            'Notification': {
                'NotificationType': 'ACTUAL',
                'ComparisonOperator': 'GREATER_THAN',
                'Threshold': 80,  # Alert at 80%
                'ThresholdType': 'PERCENTAGE'
            },
            'Subscribers': [
                {
                    'SubscriptionType': 'EMAIL',
                    'Address': 'team@example.com'
                }
            ]
        }
    ]
)
```

---

## 3. Load Testing

### Locust (Python)

```python
from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 5)  # Wait 1-5 seconds between requests

    def on_start(self):
        """Login once per user"""
        response = self.client.post('/api/auth/login', json={
            'email': 'test@example.com',
            'password': 'password'
        })
        self.token = response.json()['token']

    @task(3)  # Weight: 3x more likely than other tasks
    def view_products(self):
        self.client.get('/api/products', headers={
            'Authorization': f'Bearer {self.token}'
        })

    @task(2)
    def view_product_detail(self):
        self.client.get('/api/products/123', headers={
            'Authorization': f'Bearer {self.token}'
        })

    @task(1)
    def create_order(self):
        self.client.post('/api/orders', json={
            'product_id': '123',
            'quantity': 2
        }, headers={
            'Authorization': f'Bearer {self.token}'
        })

# Run load test
# locust -f loadtest.py --host=https://api.example.com --users=1000 --spawn-rate=10
```

### k6 (JavaScript)

```javascript
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Ramp up to 100 users
    { duration: '5m', target: 100 },   // Stay at 100
    { duration: '2m', target: 500 },   // Spike to 500
    { duration: '5m', target: 500 },   // Stay at 500
    { duration: '2m', target: 0 },     // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500', 'p(99)<1000'],  // 95% < 500ms
    'http_req_failed': ['rate<0.01'],  // Error rate < 1%
    'errors': ['rate<0.1'],
  },
};

const BASE_URL = __ENV.API_URL || 'https://api.example.com';

export default function () {
  // Login
  let loginRes = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
    email: 'test@example.com',
    password: 'password'
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  check(loginRes, {
    'login successful': (r) => r.status === 200,
  }) || errorRate.add(1);

  const token = loginRes.json('token');

  sleep(1);

  // Browse products
  group('browse products', function () {
    let productsRes = http.get(`${BASE_URL}/api/products`, {
      headers: { 'Authorization': `Bearer ${token}` },
    });

    check(productsRes, {
      'products loaded': (r) => r.status === 200,
      'has products': (r) => r.json('data').length > 0,
    }) || errorRate.add(1);
  });

  sleep(2);

  // Create order
  group('create order', function () {
    let orderRes = http.post(`${BASE_URL}/api/orders`, JSON.stringify({
      product_id: '123',
      quantity: 2
    }), {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
    });

    check(orderRes, {
      'order created': (r) => r.status === 201,
      'order has id': (r) => r.json('order_id') !== undefined,
    }) || errorRate.add(1);
  });

  sleep(1);
}
```

### Artillery (YAML)

```yaml
config:
  target: "https://api.example.com"
  phases:
    - duration: 60
      arrivalRate: 10       # 10 users/second
      name: Warm up
    - duration: 300
      arrivalRate: 50       # 50 users/second
      name: Sustained load
    - duration: 120
      arrivalRate: 100      # Spike to 100 users/second
      name: Spike test

  processor: "./processor.js"

scenarios:
  - name: "Complete user journey"
    weight: 70
    flow:
      - post:
          url: "/api/auth/login"
          json:
            email: "test@example.com"
            password: "password"
          capture:
            - json: "$.token"
              as: "token"
      - get:
          url: "/api/products"
          headers:
            Authorization: "Bearer {{ token }}"
      - think: 3
      - post:
          url: "/api/orders"
          json:
            product_id: "123"
            quantity: 2
          headers:
            Authorization: "Bearer {{ token }}"
          expect:
            - statusCode: 201

  - name: "Read-only user"
    weight: 30
    flow:
      - get:
          url: "/api/products"
      - think: 2
      - get:
          url: "/api/products/{{ $randomNumber(1, 1000) }}"
```

---

## Interview Tips

### Discussing Performance

1. **Identify Bottlenecks:**
   ```
   "I'd start by profiling:
   - Application: APM tools (X-Ray, DataDog)
   - Database: Slow query logs, explain plans
   - Network: Latency between services
   - Cache hit rate: Redis INFO stats"
   ```

2. **Caching Strategy:**
   - Static content: CDN (CloudFront)
   - API responses: Redis (TTL based on data freshness)
   - Database queries: ElastiCache
   - Computed results: In-memory cache

3. **Database Optimization:**
   - Indexes for frequently queried fields
   - Connection pooling
   - Read replicas for read-heavy workloads
   - Denormalization for complex joins

### Discussing Cost

1. **Quick Wins:**
   - Delete unused resources (EBS volumes, snapshots, load balancers)
   - Right-size over-provisioned instances
   - Reserved instances for steady workloads
   - S3 lifecycle policies
   - Delete old CloudWatch logs

2. **Architecture Changes:**
   - Serverless for variable workloads (Lambda, Fargate)
   - Spot instances for fault-tolerant workloads
   - Aurora Serverless for dev/staging databases
   - S3 Intelligent-Tiering for unknown access patterns

3. **Cost Monitoring:**
   - AWS Cost Explorer for trends
   - Budget alerts at 80%, 100%
   - Tag resources by team/project
   - Regular cost review meetings

### Common Questions

**Q: How would you reduce API latency from 500ms to 100ms?**

**A:**
1. Add caching (Redis) for repeated queries
2. Database: Add indexes, optimize queries
3. CDN for static assets
4. Async processing for non-critical tasks
5. Database read replicas
6. Connection pooling
7. Reduce payload size (only return needed fields)

**Q: How would you reduce AWS costs by 30%?**

**A:**
1. Analyze spend (Cost Explorer)
2. Right-size instances (downsize under-utilized)
3. Reserved instances (40-60% savings)
4. Spot instances for batch jobs
5. S3 lifecycle policies (move to cheaper storage)
6. Delete unused resources
7. Aurora Serverless for non-prod
8. Turn off dev/staging during off-hours

**Q: How do you decide between caching and database optimization?**

**A:**
- **Cache** if: Data read > 10x writes, acceptable staleness
- **Database** if: Data changes frequently, need real-time consistency
- **Both** for: Complex queries that change infrequently

---

## Summary Checklist

### Performance
- [ ] Caching strategy (CDN, Redis, in-memory)
- [ ] Database indexes and query optimization
- [ ] Connection pooling
- [ ] Async I/O for parallel requests
- [ ] Compression (gzip/brotli)
- [ ] Pagination for large datasets
- [ ] Load testing before production

### Cost
- [ ] Right-sizing (analyze utilization)
- [ ] Reserved Instances / Savings Plans for steady workloads
- [ ] Spot Instances for fault-tolerant workloads
- [ ] Auto-scaling (scale down during off-hours)
- [ ] S3 lifecycle policies
- [ ] Delete unused resources
- [ ] Budget alerts
- [ ] Tag resources for cost tracking
- [ ] Use ARM (Graviton) where possible
- [ ] VPC endpoints to avoid NAT Gateway costs
