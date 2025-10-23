# Common System Design Patterns - System Design Cheatsheet

## Overview

This cheatsheet covers common system design interview questions with practical solutions and AWS implementations.

---

## 1. URL Shortener (like bit.ly)

### Requirements

**Functional:**
- Generate short URL from long URL
- Redirect short URL to original URL
- Custom aliases (optional)
- Expiration (optional)

**Non-Functional:**
- 100M URLs per day
- Low latency (< 100ms)
- 99.9% availability
- Read-heavy (100:1 read/write ratio)

### High-Level Design

```
┌─────────┐      ┌─────────────┐      ┌──────────┐      ┌──────────┐
│ Client  │─────▶│   ALB/CDN   │─────▶│   API    │─────▶│ DynamoDB │
└─────────┘      └─────────────┘      └──────────┘      └──────────┘
                                              │
                                              ▼
                                       ┌──────────┐
                                       │  Redis   │
                                       │  Cache   │
                                       └──────────┘
```

### URL Encoding

```python
import hashlib
import base62

class URLShortener:
    def __init__(self):
        self.base_url = "https://short.io/"
        self.counter = 0  # For sequential IDs

    # Method 1: Hash-based (MD5 + Base62)
    def shorten_hash(self, long_url: str) -> str:
        # MD5 hash (128 bits)
        hash_digest = hashlib.md5(long_url.encode()).hexdigest()

        # Take first 7 characters after base62 encoding
        short_code = base62.encode(int(hash_digest[:16], 16))[:7]

        # Store mapping
        db.put_item(
            TableName='urls',
            Item={
                'short_code': short_code,
                'long_url': long_url,
                'created_at': int(time.time()),
                'clicks': 0
            }
        )

        return f"{self.base_url}{short_code}"

    # Method 2: Sequential ID + Base62 (better)
    def shorten_sequential(self, long_url: str) -> str:
        # Get next ID from counter
        self.counter += 1
        id = self.counter

        # Convert to base62 (0-9, a-z, A-Z)
        short_code = base62.encode(id)  # e.g., 125 → "27"

        db.put_item(
            TableName='urls',
            Item={
                'short_code': short_code,
                'long_url': long_url,
                'created_at': int(time.time()),
                'expiration': int(time.time()) + 30*24*3600,  # 30 days
                'clicks': 0
            }
        )

        return f"{self.base_url}{short_code}"

    def redirect(self, short_code: str) -> str:
        # Check cache first
        cached_url = cache.get(f"url:{short_code}")
        if cached_url:
            return cached_url

        # Get from database
        response = db.get_item(
            TableName='urls',
            Key={'short_code': short_code}
        )

        if 'Item' not in response:
            raise NotFoundError("URL not found")

        long_url = response['Item']['long_url']

        # Cache for 24 hours
        cache.setex(f"url:{short_code}", 86400, long_url)

        # Increment click count (async)
        db.update_item(
            TableName='urls',
            Key={'short_code': short_code},
            UpdateExpression='SET clicks = clicks + :inc',
            ExpressionAttributeValues={':inc': 1}
        )

        return long_url
```

### Infrastructure

```yaml
# DynamoDB Table
Resources:
  URLsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: urls
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: short_code
          AttributeType: S
        - AttributeName: user_id
          AttributeType: S
      KeySchema:
        - AttributeName: short_code
          KeyType: HASH
      GlobalSecondaryIndexes:
        - IndexName: UserIndex
          KeySchema:
            - AttributeName: user_id
              KeyType: HASH
          Projection:
            ProjectionType: ALL
      TimeToLiveSpecification:
        AttributeName: expiration
        Enabled: true

  # ElastiCache Redis
  RedisCluster:
    Type: AWS::ElastiCache::CacheCluster
    Properties:
      CacheNodeType: cache.r6g.large
      Engine: redis
      NumCacheNodes: 1

  # CloudFront for global distribution
  Distribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        DefaultCacheBehavior:
          TargetOriginId: api
          ViewerProtocolPolicy: redirect-to-https
          CachePolicyId: 4135ea2d-6df8-44a3-9df3-4b5a84be39ad  # CachingDisabled
```

### Capacity Estimation

```
Writes: 100M URLs/day = 1,157 writes/sec
Reads: 100:1 ratio = 115,700 reads/sec

Storage:
- 100M URLs/day × 500 bytes = 50GB/day
- 5 years = 50GB × 365 × 5 = 91TB

DynamoDB:
- Write capacity: 1,200 WCU (with buffer)
- Read capacity: 116,000 RCU (with cache, much lower)
- With 99% cache hit rate: 1,160 RCU

Cost (monthly):
- DynamoDB on-demand: ~$2,500
- ElastiCache r6g.large: ~$200
- Total: ~$2,700/month
```

---

## 2. Rate Limiter

### Requirements

- Limit requests per user/IP
- Multiple rate limit tiers
- Distributed system
- Low latency (< 10ms overhead)

### Algorithms

#### 1. Token Bucket

```python
import time

class TokenBucket:
    def __init__(self, capacity: int, refill_rate: float):
        """
        capacity: Maximum tokens in bucket
        refill_rate: Tokens added per second
        """
        self.capacity = capacity
        self.refill_rate = refill_rate
        self.tokens = capacity
        self.last_refill = time.time()

    def allow_request(self) -> bool:
        # Refill tokens based on time passed
        now = time.time()
        elapsed = now - self.last_refill
        tokens_to_add = elapsed * self.refill_rate

        self.tokens = min(self.capacity, self.tokens + tokens_to_add)
        self.last_refill = now

        # Check if request allowed
        if self.tokens >= 1:
            self.tokens -= 1
            return True
        else:
            return False
```

#### 2. Fixed Window Counter

```python
class FixedWindowCounter:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window_seconds = window_seconds

    def allow_request(self, user_id: str) -> bool:
        current_window = int(time.time() / self.window_seconds)
        key = f"rate_limit:{user_id}:{current_window}"

        # Increment counter
        count = cache.incr(key)

        if count == 1:
            # First request in window, set expiration
            cache.expire(key, self.window_seconds)

        return count <= self.limit
```

#### 3. Sliding Window Log

```python
class SlidingWindowLog:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window_seconds = window_seconds

    def allow_request(self, user_id: str) -> bool:
        key = f"rate_limit:{user_id}"
        now = time.time()
        window_start = now - self.window_seconds

        # Remove old entries
        cache.zremrangebyscore(key, 0, window_start)

        # Count requests in window
        count = cache.zcard(key)

        if count < self.limit:
            # Add current request
            cache.zadd(key, {str(now): now})
            cache.expire(key, self.window_seconds)
            return True
        else:
            return False
```

#### 4. Sliding Window Counter (Hybrid - Best)

```python
class SlidingWindowCounter:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window_seconds = window_seconds

    def allow_request(self, user_id: str) -> bool:
        now = time.time()
        current_window = int(now / self.window_seconds)
        previous_window = current_window - 1

        current_key = f"rate_limit:{user_id}:{current_window}"
        previous_key = f"rate_limit:{user_id}:{previous_window}"

        # Get counts
        current_count = int(cache.get(current_key) or 0)
        previous_count = int(cache.get(previous_key) or 0)

        # Calculate weight for previous window
        elapsed_time_in_current = now % self.window_seconds
        weight = 1 - (elapsed_time_in_current / self.window_seconds)

        # Approximate count
        approximate_count = current_count + (previous_count * weight)

        if approximate_count < self.limit:
            cache.incr(current_key)
            cache.expire(current_key, self.window_seconds * 2)
            return True
        else:
            return False
```

### Distributed Rate Limiter (Redis)

```python
import redis
import hashlib

class DistributedRateLimiter:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client

    def is_allowed(self, user_id: str, limit: int, window: int) -> bool:
        """
        Sliding window rate limiter using Redis
        """
        key = f"rate_limit:{user_id}"
        now = time.time()
        window_start = now - window

        pipe = self.redis.pipeline()

        # Remove old entries
        pipe.zremrangebyscore(key, 0, window_start)

        # Count requests in window
        pipe.zcard(key)

        # Add current timestamp
        pipe.zadd(key, {f"{now}:{hashlib.md5(str(now).encode()).hexdigest()[:8]}": now})

        # Set expiration
        pipe.expire(key, window)

        results = pipe.execute()
        count = results[1]

        return count < limit

# Middleware
from flask import Flask, request, jsonify

app = Flask(__name__)
rate_limiter = DistributedRateLimiter(redis.Redis())

@app.before_request
def check_rate_limit():
    user_id = request.headers.get('X-User-ID') or request.remote_addr

    # Different limits per endpoint
    limits = {
        '/api/search': (100, 60),      # 100 requests per minute
        '/api/upload': (10, 60),       # 10 requests per minute
        '/api/download': (1000, 3600)  # 1000 requests per hour
    }

    endpoint = request.path
    limit, window = limits.get(endpoint, (1000, 60))  # Default

    if not rate_limiter.is_allowed(user_id, limit, window):
        return jsonify({
            'error': 'Rate limit exceeded',
            'retry_after': window
        }), 429
```

### Infrastructure

```yaml
Resources:
  # Redis for distributed rate limiting
  RedisCluster:
    Type: AWS::ElastiCache::ReplicationGroup
    Properties:
      ReplicationGroupDescription: Rate limiter cache
      Engine: redis
      CacheNodeType: cache.r6g.xlarge
      NumCacheClusters: 3
      AutomaticFailoverEnabled: true
      MultiAZEnabled: true

  # API Gateway with built-in rate limiting
  ApiGateway:
    Type: AWS::ApiGatewayV2::Api
    Properties:
      Name: MyAPI
      ProtocolType: HTTP

  # Usage plan
  UsagePlan:
    Type: AWS::ApiGateway::UsagePlan
    Properties:
      UsagePlanName: StandardPlan
      Throttle:
        BurstLimit: 200    # Max concurrent requests
        RateLimit: 100     # Sustained requests per second
      Quota:
        Limit: 1000000     # Total requests per period
        Period: MONTH
```

---

## 3. Distributed Cache

### Cache Patterns

#### Cache-Aside with Automatic Expiration

```python
import functools
import pickle
import hashlib

def cached(ttl=3600, key_prefix=''):
    """Decorator for caching function results"""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key
            key_data = f"{key_prefix}:{func.__name__}:{args}:{kwargs}"
            cache_key = hashlib.md5(key_data.encode()).hexdigest()

            # Check cache
            cached_result = cache.get(cache_key)
            if cached_result:
                return pickle.loads(cached_result)

            # Execute function
            result = func(*args, **kwargs)

            # Store in cache
            cache.setex(cache_key, ttl, pickle.dumps(result))

            return result
        return wrapper
    return decorator

# Usage
@cached(ttl=3600, key_prefix='user')
def get_user_profile(user_id: str):
    return db.users.find_one({'id': user_id})
```

#### Cache Warming

```python
def warm_cache():
    """Pre-populate cache with hot data"""

    # Most popular products
    popular_products = db.products.find().sort('views', -1).limit(100)
    for product in popular_products:
        cache.setex(
            f"product:{product['id']}",
            3600,
            json.dumps(product)
        )

    # Recent users
    recent_users = db.users.find().sort('last_login', -1).limit(1000)
    for user in recent_users:
        cache.setex(
            f"user:{user['id']}",
            3600,
            json.dumps(user)
        )

# Run on application startup or scheduled
```

#### Cache Invalidation Strategies

```python
# 1. Time-based (TTL)
cache.setex('key', 3600, value)  # Expires in 1 hour

# 2. Event-based (invalidate on update)
def update_user(user_id, data):
    db.users.update_one({'id': user_id}, {'$set': data})
    cache.delete(f'user:{user_id}')  # Invalidate cache

# 3. Tag-based (invalidate related items)
def update_product(product_id, data):
    db.products.update_one({'id': product_id}, {'$set': data})

    # Invalidate product cache
    cache.delete(f'product:{product_id}')

    # Invalidate category cache
    category_id = db.products.find_one({'id': product_id})['category_id']
    cache.delete(f'category:{category_id}:products')

# 4. Versioning (avoid stale data)
def get_user_with_version(user_id):
    version = cache.get(f'user:{user_id}:version') or 0
    key = f'user:{user_id}:v{version}'

    cached = cache.get(key)
    if cached:
        return json.loads(cached)

    user = db.users.find_one({'id': user_id})
    cache.setex(key, 3600, json.dumps(user))
    return user

def update_user_with_version(user_id, data):
    db.users.update_one({'id': user_id}, {'$set': data})

    # Increment version (invalidates old cache)
    cache.incr(f'user:{user_id}:version')
```

### Multi-Level Caching

```
┌─────────────┐
│   Browser   │  L1: Browser Cache (max-age)
└──────┬──────┘
       │
┌──────▼──────┐
│ CloudFront  │  L2: CDN Edge Cache
└──────┬──────┘
       │
┌──────▼──────┐
│  API Server │  L3: In-Memory Cache (Node.js)
└──────┬──────┘
       │
┌──────▼──────┐
│    Redis    │  L4: Distributed Cache
└──────┬──────┘
       │
┌──────▼──────┐
│  Database   │  L5: Source of Truth
└─────────────┘
```

---

## 4. Notification System

### Requirements

- Multiple channels: Push, Email, SMS
- 10M notifications per day
- Prioritization
- Retry on failure
- User preferences

### Architecture

```
┌──────────────┐      ┌──────────┐      ┌─────────────┐
│   Services   │─────▶│   SQS    │─────▶│   Lambda    │
│ (API, Cron)  │      │  Queue   │      │  Processor  │
└──────────────┘      └──────────┘      └──────┬──────┘
                                                │
                      ┌─────────────────────────┼─────────────────┐
                      │                         │                 │
                 ┌────▼────┐              ┌────▼────┐      ┌────▼────┐
                 │   SNS   │              │   SES   │      │  Twilio │
                 │  Push   │              │  Email  │      │   SMS   │
                 └─────────┘              └─────────┘      └─────────┘
```

### Implementation

```python
import boto3
import json

sqs = boto3.client('sqs')
sns = boto3.client('sns')
ses = boto3.client('ses')

class NotificationService:
    def __init__(self):
        self.queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789012/notifications'

    def send_notification(self, user_id: str, notification: dict):
        """Queue notification for processing"""

        # Get user preferences
        user = db.users.find_one({'id': user_id})
        preferences = user.get('notification_preferences', {})

        # Check if user wants this notification type
        if not preferences.get(notification['type'], True):
            return

        # Add to queue
        sqs.send_message(
            QueueUrl=self.queue_url,
            MessageBody=json.dumps({
                'user_id': user_id,
                'notification': notification,
                'channels': user.get('channels', ['push', 'email']),
                'priority': notification.get('priority', 'normal')
            }),
            MessageAttributes={
                'priority': {
                    'StringValue': notification.get('priority', 'normal'),
                    'DataType': 'String'
                }
            }
        )

    def process_notifications(self, event, context):
        """Lambda function to process SQS messages"""

        for record in event['Records']:
            message = json.loads(record['body'])
            user_id = message['user_id']
            notification = message['notification']
            channels = message['channels']

            # Send to each channel
            for channel in channels:
                try:
                    if channel == 'push':
                        self.send_push(user_id, notification)
                    elif channel == 'email':
                        self.send_email(user_id, notification)
                    elif channel == 'sms':
                        self.send_sms(user_id, notification)

                    # Log success
                    db.notification_logs.insert_one({
                        'user_id': user_id,
                        'notification_id': notification['id'],
                        'channel': channel,
                        'status': 'sent',
                        'timestamp': time.time()
                    })

                except Exception as e:
                    logger.error(f"Failed to send {channel} notification", error=str(e))

                    # Retry logic (DLQ handled by SQS)
                    if record['ApproximateReceiveCount'] < 3:
                        raise  # Re-queue

    def send_push(self, user_id: str, notification: dict):
        """Send push notification via SNS"""
        user = db.users.find_one({'id': user_id})
        device_token = user.get('device_token')

        if not device_token:
            return

        sns.publish(
            TargetArn=device_token,
            Message=json.dumps({
                'default': notification['message'],
                'APNS': json.dumps({
                    'aps': {
                        'alert': notification['message'],
                        'sound': 'default',
                        'badge': 1
                    },
                    'data': notification.get('data', {})
                }),
                'GCM': json.dumps({
                    'notification': {
                        'title': notification['title'],
                        'body': notification['message']
                    },
                    'data': notification.get('data', {})
                })
            }),
            MessageStructure='json'
        )

    def send_email(self, user_id: str, notification: dict):
        """Send email via SES"""
        user = db.users.find_one({'id': user_id})

        ses.send_email(
            Source='notifications@example.com',
            Destination={'ToAddresses': [user['email']]},
            Message={
                'Subject': {'Data': notification['title']},
                'Body': {
                    'Html': {'Data': notification['html_body']},
                    'Text': {'Data': notification['text_body']}
                }
            }
        )

    def send_sms(self, user_id: str, notification: dict):
        """Send SMS via SNS"""
        user = db.users.find_one({'id': user_id})
        phone = user.get('phone')

        if not phone:
            return

        sns.publish(
            PhoneNumber=phone,
            Message=notification['message']
        )
```

### Priority Queues

```yaml
Resources:
  # High priority queue
  HighPriorityQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: notifications-high-priority
      VisibilityTimeout: 30
      MessageRetentionPeriod: 86400
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt DLQ.Arn
        maxReceiveCount: 3

  # Normal priority queue
  NormalPriorityQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: notifications-normal-priority
      VisibilityTimeout: 30
      MessageRetentionPeriod: 86400
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt DLQ.Arn
        maxReceiveCount: 3

  # Lambda to process high priority (higher concurrency)
  HighPriorityProcessor:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: notification-processor-high
      ReservedConcurrentExecutions: 100
      Events:
        SQSEvent:
          Type: SQS
          Properties:
            Queue: !GetAtt HighPriorityQueue.Arn
            BatchSize: 10

  # Lambda to process normal priority (lower concurrency)
  NormalPriorityProcessor:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: notification-processor-normal
      ReservedConcurrentExecutions: 50
      Events:
        SQSEvent:
          Type: SQS
          Properties:
            Queue: !GetAtt NormalPriorityQueue.Arn
            BatchSize: 10
```

---

## 5. News Feed / Social Feed

### Requirements

- Generate personalized feed
- Real-time updates
- Millions of users
- Low latency (< 200ms)
- Handle viral posts

### Architecture

#### Fan-out on Write (Push Model)

```
User A posts → Write to all followers' feeds (100 writes)
User B reads feed → Read own feed (1 read)

Good for: Users with few followers
Bad for: Celebrities (millions of writes per post)
```

```python
class FeedService:
    def create_post(self, user_id: str, content: str):
        # Create post
        post_id = str(uuid.uuid4())
        post = {
            'id': post_id,
            'user_id': user_id,
            'content': content,
            'created_at': time.time()
        }
        db.posts.insert_one(post)

        # Get all followers
        followers = db.followers.find({'following_id': user_id})

        # Fan-out: Write to each follower's feed
        for follower in followers:
            cache.zadd(
                f"feed:{follower['user_id']}",
                {post_id: post['created_at']}
            )

            # Keep only latest 1000 posts
            cache.zremrangebyrank(f"feed:{follower['user_id']}", 0, -1001)

    def get_feed(self, user_id: str, limit=50):
        # Read from pre-computed feed
        post_ids = cache.zrevrange(f"feed:{user_id}", 0, limit-1)

        # Fetch post details
        posts = db.posts.find({'id': {'$in': post_ids}})

        return sorted(posts, key=lambda x: x['created_at'], reverse=True)
```

#### Fan-out on Read (Pull Model)

```
User A posts → Write to own timeline (1 write)
User B reads feed → Fetch posts from all following (100 reads)

Good for: Celebrities
Bad for: Many followers (slow read)
```

```python
def get_feed_pull(self, user_id: str, limit=50):
    # Get all users I'm following
    following = db.followers.find({'user_id': user_id})
    following_ids = [f['following_id'] for f in following]

    # Fetch recent posts from all
    posts = db.posts.find({
        'user_id': {'$in': following_ids}
    }).sort('created_at', -1).limit(limit)

    return list(posts)
```

#### Hybrid Approach (Best)

```python
class HybridFeedService:
    CELEBRITY_THRESHOLD = 1000000  # 1M followers

    def create_post(self, user_id: str, content: str):
        post_id = str(uuid.uuid4())
        post = {
            'id': post_id,
            'user_id': user_id,
            'content': content,
            'created_at': time.time()
        }
        db.posts.insert_one(post)

        # Check if user is celebrity
        follower_count = db.followers.count_documents({'following_id': user_id})

        if follower_count < self.CELEBRITY_THRESHOLD:
            # Fan-out on write for normal users
            followers = db.followers.find({'following_id': user_id})
            for follower in followers:
                cache.zadd(
                    f"feed:{follower['user_id']}",
                    {post_id: post['created_at']}
                )
        else:
            # For celebrities, don't fan-out (pull on read)
            cache.zadd(f"celebrity_posts:{user_id}", {post_id: post['created_at']})

    def get_feed(self, user_id: str, limit=50):
        # Get pre-computed feed (normal users)
        post_ids = cache.zrevrange(f"feed:{user_id}", 0, limit-1)

        # Get posts from celebrities I follow (pull)
        following = db.followers.find({'user_id': user_id})
        celebrity_posts = []
        for follow in following:
            follower_count = db.followers.count_documents({'following_id': follow['following_id']})
            if follower_count >= self.CELEBRITY_THRESHOLD:
                celeb_posts = cache.zrevrange(
                    f"celebrity_posts:{follow['following_id']}",
                    0, 10
                )
                celebrity_posts.extend(celeb_posts)

        # Merge and sort
        all_post_ids = list(set(post_ids + celebrity_posts))
        posts = db.posts.find({'id': {'$in': all_post_ids}})

        return sorted(posts, key=lambda x: x['created_at'], reverse=True)[:limit]
```

### Ranking Algorithm

```python
def calculate_score(post):
    """Rank posts by engagement + recency"""

    age_hours = (time.time() - post['created_at']) / 3600

    # Engagement score
    engagement = (
        post.get('likes', 0) * 1 +
        post.get('comments', 0) * 2 +
        post.get('shares', 0) * 3
    )

    # Time decay (exponential)
    time_decay = 1 / (1 + age_hours)

    # User affinity (how much you interact with this user)
    affinity = get_user_affinity(current_user_id, post['user_id'])

    score = engagement * time_decay * affinity

    return score

def get_ranked_feed(user_id: str, limit=50):
    # Get candidate posts (2x limit for ranking)
    posts = get_feed(user_id, limit=limit*2)

    # Calculate scores
    scored_posts = [(post, calculate_score(post)) for post in posts]

    # Sort by score
    ranked_posts = sorted(scored_posts, key=lambda x: x[1], reverse=True)

    return [post for post, score in ranked_posts[:limit]]
```

---

## 6. Chat System / Messaging

### Requirements

- 1-on-1 and group chat
- Real-time delivery
- Message history
- Read receipts
- Typing indicators
- 100M daily active users

### Architecture

```
┌─────────┐     WebSocket      ┌─────────────┐     ┌──────────┐
│ Client  │◀──────────────────▶│  API Server │────▶│ DynamoDB │
└─────────┘                     └──────┬──────┘     └──────────┘
                                       │
                                       ▼
                                ┌──────────┐
                                │  Redis   │
                                │  Pub/Sub │
                                └──────────┘
```

### WebSocket Implementation

```python
from flask import Flask
from flask_socketio import SocketIO, emit, join_room, leave_room

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# Active connections
connections = {}  # {user_id: socket_id}

@socketio.on('connect')
def handle_connect(auth):
    user_id = auth['user_id']
    connections[user_id] = request.sid

    # Join user's personal room
    join_room(f"user:{user_id}")

    # Set online status
    cache.setex(f"online:{user_id}", 300, "true")

    # Notify friends
    friends = db.friendships.find({'user_id': user_id})
    for friend in friends:
        emit('user_online', {'user_id': user_id}, room=f"user:{friend['friend_id']}")

@socketio.on('disconnect')
def handle_disconnect():
    user_id = get_user_id_from_session()

    # Remove from active connections
    if user_id in connections:
        del connections[user_id]

    # Set offline
    cache.delete(f"online:{user_id}")

    # Update last seen
    db.users.update_one(
        {'id': user_id},
        {'$set': {'last_seen': time.time()}}
    )

@socketio.on('send_message')
def handle_message(data):
    sender_id = get_user_id_from_session()
    recipient_id = data['recipient_id']
    message_text = data['message']

    # Save message
    message = {
        'id': str(uuid.uuid4()),
        'conversation_id': get_conversation_id(sender_id, recipient_id),
        'sender_id': sender_id,
        'recipient_id': recipient_id,
        'message': message_text,
        'timestamp': time.time(),
        'read': False
    }
    db.messages.insert_one(message)

    # Send to recipient (if online)
    if recipient_id in connections:
        emit('new_message', message, room=f"user:{recipient_id}")

    # Send to sender (confirmation + sync across devices)
    emit('message_sent', message, room=f"user:{sender_id}")

    # Send push notification if offline
    if not cache.exists(f"online:{recipient_id}"):
        send_push_notification(recipient_id, {
            'title': f'New message from {sender_id}',
            'body': message_text
        })

@socketio.on('typing')
def handle_typing(data):
    sender_id = get_user_id_from_session()
    recipient_id = data['recipient_id']

    # Notify recipient
    emit('user_typing', {'user_id': sender_id}, room=f"user:{recipient_id}")

@socketio.on('mark_read')
def handle_mark_read(data):
    user_id = get_user_id_from_session()
    message_ids = data['message_ids']

    # Update messages
    db.messages.update_many(
        {'id': {'$in': message_ids}, 'recipient_id': user_id},
        {'$set': {'read': True, 'read_at': time.time()}}
    )

    # Notify sender
    for message_id in message_ids:
        message = db.messages.find_one({'id': message_id})
        emit('message_read', {
            'message_id': message_id,
            'read_by': user_id
        }, room=f"user:{message['sender_id']}")

def get_conversation_id(user1_id, user2_id):
    """Generate consistent conversation ID"""
    return ':'.join(sorted([user1_id, user2_id]))
```

### Message History

```python
def get_messages(conversation_id: str, before_timestamp=None, limit=50):
    """Paginate message history"""

    query = {'conversation_id': conversation_id}
    if before_timestamp:
        query['timestamp'] = {'$lt': before_timestamp}

    messages = db.messages.find(query).sort('timestamp', -1).limit(limit)

    return list(reversed(list(messages)))  # Return chronological order
```

### Group Chat

```python
@socketio.on('send_group_message')
def handle_group_message(data):
    sender_id = get_user_id_from_session()
    group_id = data['group_id']
    message_text = data['message']

    # Save message
    message = {
        'id': str(uuid.uuid4()),
        'group_id': group_id,
        'sender_id': sender_id,
        'message': message_text,
        'timestamp': time.time()
    }
    db.messages.insert_one(message)

    # Get group members
    group = db.groups.find_one({'id': group_id})
    members = group['members']

    # Send to all online members
    for member_id in members:
        if member_id != sender_id:  # Don't send to self
            emit('new_message', message, room=f"user:{member_id}")

    # Push notifications for offline members
    for member_id in members:
        if not cache.exists(f"online:{member_id}") and member_id != sender_id:
            send_push_notification(member_id, {
                'title': f'New message in {group["name"]}',
                'body': f'{sender_id}: {message_text}'
            })
```

### Scaling WebSockets

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  WS #1   │     │  WS #2   │     │  WS #3   │
│(User A,B)│     │(User C,D)│     │(User E,F)│
└────┬─────┘     └────┬─────┘     └────┬─────┘
     │                │                │
     └────────────────┼────────────────┘
                      │
               ┌──────▼──────┐
               │    Redis    │
               │   Pub/Sub   │
               └─────────────┘
```

```python
import redis

redis_client = redis.Redis()
pubsub = redis_client.pubsub()

# Subscribe to user's channel
@socketio.on('connect')
def handle_connect(auth):
    user_id = auth['user_id']

    # Subscribe to Redis channel
    pubsub.subscribe(f"user:{user_id}")

    # Listen for messages from other WS servers
    def listen():
        for message in pubsub.listen():
            if message['type'] == 'message':
                data = json.loads(message['data'])
                emit('new_message', data, room=f"user:{user_id}")

    socketio.start_background_task(listen)

# Publish message to Redis (reaches all WS servers)
def send_message_to_user(user_id, message):
    redis_client.publish(
        f"user:{user_id}",
        json.dumps(message)
    )
```

---

## 7. Video Streaming (like YouTube)

### Requirements

- Upload videos (multi-GB files)
- Transcode to multiple formats/resolutions
- Stream with adaptive bitrate
- 1B views per day
- Global distribution

### Architecture

```
┌────────┐    ┌─────────┐    ┌──────────┐    ┌─────────┐
│ Upload │───▶│   S3    │───▶│MediaConvert───▶│S3(HLS)  │
└────────┘    └─────────┘    └──────────┘    └────┬────┘
                                                    │
                                             ┌──────▼──────┐
                                             │ CloudFront  │
                                             └──────┬──────┘
                                                    │
                                             ┌──────▼──────┐
                                             │   Viewer    │
                                             └─────────────┘
```

### Upload Flow

```python
import boto3

s3 = boto3.client('s3')
mediaconvert = boto3.client('mediaconvert')

def generate_upload_url(file_name: str, file_size: int):
    """Generate presigned URL for direct upload to S3"""

    video_id = str(uuid.uuid4())
    key = f"uploads/{video_id}/{file_name}"

    # Presigned URL (valid for 1 hour)
    upload_url = s3.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': 'video-uploads',
            'Key': key,
            'ContentType': 'video/mp4'
        },
        ExpiresIn=3600
    )

    # Create video record
    db.videos.insert_one({
        'id': video_id,
        'file_name': file_name,
        'file_size': file_size,
        's3_key': key,
        'status': 'uploading',
        'created_at': time.time()
    })

    return {'video_id': video_id, 'upload_url': upload_url}

# S3 event triggers Lambda on upload complete
def handle_upload_complete(event, context):
    """Triggered when video uploaded to S3"""

    # Get video info
    s3_key = event['Records'][0]['s3']['object']['key']
    video_id = s3_key.split('/')[1]

    # Update status
    db.videos.update_one(
        {'id': video_id},
        {'$set': {'status': 'transcoding'}}
    )

    # Start transcoding job
    start_transcoding(video_id, s3_key)

def start_transcoding(video_id: str, input_key: str):
    """Start AWS MediaConvert job"""

    job = mediaconvert.create_job(
        Role='arn:aws:iam::123456789012:role/MediaConvertRole',
        Settings={
            'Inputs': [{
                'FileInput': f's3://video-uploads/{input_key}',
                'AudioSelectors': {
                    'Audio Selector 1': {
                        'DefaultSelection': 'DEFAULT'
                    }
                }
            }],
            'OutputGroups': [
                {
                    # HLS output
                    'Name': 'Apple HLS',
                    'OutputGroupSettings': {
                        'Type': 'HLS_GROUP_SETTINGS',
                        'HlsGroupSettings': {
                            'Destination': f's3://video-transcoded/{video_id}/hls/',
                            'SegmentLength': 10,
                            'MinSegmentLength': 0
                        }
                    },
                    'Outputs': [
                        # 1080p
                        {
                            'NameModifier': '_1080p',
                            'VideoDescription': {
                                'Width': 1920,
                                'Height': 1080,
                                'CodecSettings': {
                                    'Codec': 'H_264',
                                    'H264Settings': {
                                        'Bitrate': 5000000
                                    }
                                }
                            }
                        },
                        # 720p
                        {
                            'NameModifier': '_720p',
                            'VideoDescription': {
                                'Width': 1280,
                                'Height': 720,
                                'CodecSettings': {
                                    'Codec': 'H_264',
                                    'H264Settings': {
                                        'Bitrate': 3000000
                                    }
                                }
                            }
                        },
                        # 480p
                        {
                            'NameModifier': '_480p',
                            'VideoDescription': {
                                'Width': 854,
                                'Height': 480,
                                'CodecSettings': {
                                    'Codec': 'H_264',
                                    'H264Settings': {
                                        'Bitrate': 1500000
                                    }
                                }
                            }
                        }
                    ]
                }
            ]
        }
    )

    # Store job ID
    db.videos.update_one(
        {'id': video_id},
        {'$set': {'transcoding_job_id': job['Job']['Id']}}
    )

def handle_transcoding_complete(event, context):
    """Triggered when MediaConvert job completes"""

    job_id = event['detail']['jobId']
    video = db.videos.find_one({'transcoding_job_id': job_id})

    # Update status
    db.videos.update_one(
        {'id': video['id']},
        {'$set': {
            'status': 'ready',
            'hls_url': f"https://cdn.example.com/{video['id']}/hls/master.m3u8"
        }}
    )

    # Notify user
    send_notification(video['user_id'], {
        'title': 'Video ready!',
        'message': 'Your video has been processed and is ready to watch'
    })
```

### Streaming (HLS)

```html
<!-- Video.js player with HLS support -->
<!DOCTYPE html>
<html>
<head>
  <link href="https://vjs.zencdn.net/8.0.4/video-js.css" rel="stylesheet">
</head>
<body>
  <video id="player" class="video-js vjs-default-skin" controls preload="auto">
    <source src="https://cdn.example.com/video123/hls/master.m3u8" type="application/x-mpegURL">
  </video>

  <script src="https://vjs.zencdn.net/8.0.4/video.min.js"></script>
  <script>
    const player = videojs('player', {
      controls: true,
      autoplay: false,
      preload: 'auto'
    });

    // Track viewing progress
    player.on('timeupdate', function() {
      const currentTime = player.currentTime();
      const duration = player.duration();

      // Save progress every 10 seconds
      if (Math.floor(currentTime) % 10 === 0) {
        fetch('/api/videos/video123/progress', {
          method: 'POST',
          body: JSON.stringify({
            position: currentTime,
            duration: duration
          })
        });
      }
    });

    // Track completion
    player.on('ended', function() {
      fetch('/api/videos/video123/complete', {method: 'POST'});
    });
  </script>
</body>
</html>
```

### Analytics

```python
def track_view(video_id: str, user_id: str):
    """Track video view"""

    # Increment view count
    db.videos.update_one(
        {'id': video_id},
        {'$inc': {'views': 1}}
    )

    # Store detailed analytics
    db.video_analytics.insert_one({
        'video_id': video_id,
        'user_id': user_id,
        'timestamp': time.time(),
        'ip': request.remote_addr,
        'user_agent': request.headers.get('User-Agent'),
        'referrer': request.headers.get('Referer')
    })

    # Real-time analytics (Redis)
    cache.incr(f"views:{video_id}:today")
    cache.expire(f"views:{video_id}:today", 86400)

    # Update trending (sorted set by views)
    cache.zincrby('trending_videos', 1, video_id)
```

---

## Interview Tips

### Approach to System Design Questions

1. **Clarify Requirements (5 min)**
   - Functional requirements
   - Non-functional requirements (scale, latency, availability)
   - Out of scope

2. **Capacity Estimation (5 min)**
   - Users, traffic, storage
   - Calculate QPS, bandwidth, storage

3. **High-Level Design (10 min)**
   - Draw architecture diagram
   - Identify key components
   - Data flow

4. **Deep Dive (20 min)**
   - Database schema
   - API design
   - Scaling bottlenecks
   - Trade-offs

5. **Wrap Up (5 min)**
   - Monitoring, alerting
   - Future improvements

### Common Mistakes

- ❌ Jumping to solution without clarifying requirements
- ❌ Over-engineering for small scale
- ❌ Ignoring trade-offs
- ❌ Not considering failures
- ✅ Always ask clarifying questions
- ✅ Start simple, then scale
- ✅ Discuss trade-offs explicitly
- ✅ Consider monitoring from the start

---

## Summary Checklist

- [ ] URL Shortener: Base62 encoding, caching, DynamoDB
- [ ] Rate Limiter: Sliding window, Redis, distributed
- [ ] Distributed Cache: Multi-level, invalidation strategies
- [ ] Notifications: SQS, multiple channels, retry logic
- [ ] News Feed: Hybrid fan-out, ranking algorithm
- [ ] Chat System: WebSocket, Redis Pub/Sub, read receipts
- [ ] Video Streaming: S3, MediaConvert, HLS, CloudFront
