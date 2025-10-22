# Redis Cheat Sheet

Complete guide to Redis features, commands, and patterns.

---

## What is Redis?

**Redis** (REmote DIctionary Server) is an open-source, in-memory data structure store used as a database, cache, message broker, and streaming engine. It supports various data structures and provides high performance with sub-millisecond latency.

**Key Characteristics:**
- In-memory storage with optional persistence
- Single-threaded with atomic operations
- Supports multiple data structures
- Built-in replication and clustering
- Pub/Sub messaging
- Lua scripting support

---

## Connection and Server

### Connection Commands
```bash
# Connect to Redis
redis-cli                                 # Connect to localhost:6379
redis-cli -h host -p port                 # Connect to specific host/port
redis-cli -a password                     # Connect with password
redis-cli --user username --pass password # With username and password

# Test connection
PING                                      # Returns PONG if connected
ECHO "Hello"                              # Echo message

# Authentication
AUTH password                             # Authenticate
AUTH username password                    # Authenticate with username (Redis 6+)

# Select database
SELECT 0                                  # Select database (0-15 by default)

# Close connection
QUIT                                      # Close connection
```

### Server Information
```bash
INFO                                      # All server information
INFO server                               # Server info
INFO stats                                # Statistics
INFO memory                               # Memory usage
INFO cpu                                  # CPU usage
INFO replication                          # Replication info
INFO clients                              # Connected clients

DBSIZE                                    # Number of keys in current database
TIME                                      # Server time
LASTSAVE                                  # Last save timestamp
```

### Server Management
```bash
# Save data
SAVE                                      # Synchronous save (blocks)
BGSAVE                                    # Background save (non-blocking)

# Flush data
FLUSHDB                                   # Clear current database
FLUSHALL                                  # Clear all databases

# Configuration
CONFIG GET parameter                      # Get config parameter
CONFIG SET parameter value                # Set config parameter
CONFIG REWRITE                            # Write config to file

# Shutdown
SHUTDOWN                                  # Shutdown server (save data)
SHUTDOWN NOSAVE                           # Shutdown without saving
```

---

## Essential Features

### 1. Strings

**Description:** Strings are the most fundamental and versatile data type in Redis. They can store any kind of data - text strings, integers, floating point numbers, serialized JSON objects, or even binary data like images (up to 512MB). Strings support atomic operations like increment/decrement, making them perfect for counters and numeric values. All string operations are O(1) time complexity, providing consistent performance regardless of value size.

```bash
# Set/Get
SET key value                             # Set key to value
GET key                                   # Get value by key
MSET key1 val1 key2 val2                  # Set multiple keys
MGET key1 key2                            # Get multiple values

# Set with options
SET key value EX 60                       # Set with 60 second expiration
SET key value PX 60000                    # Set with milliseconds expiration
SET key value NX                          # Set only if key doesn't exist
SET key value XX                          # Set only if key exists
SETEX key 60 value                        # Set with expiration (seconds)
PSETEX key 60000 value                    # Set with expiration (milliseconds)
SETNX key value                           # Set if not exists

# Get and Set
GETSET key newvalue                       # Set new value, return old value
GETEX key EX 60                           # Get value and set expiration
GETDEL key                                # Get value and delete key

# Append
APPEND key value                          # Append to existing value
STRLEN key                                # Get length of value

# Substring
GETRANGE key start end                    # Get substring
SETRANGE key offset value                 # Set substring

# Increment/Decrement
INCR key                                  # Increment by 1
INCRBY key increment                      # Increment by amount
INCRBYFLOAT key increment                 # Increment by float
DECR key                                  # Decrement by 1
DECRBY key decrement                      # Decrement by amount
```

**Use Cases:**
- **Session storage**: Store user session data with automatic expiration
- **Caching HTML fragments**: Cache rendered HTML or API responses to reduce server load
- **Counters and rate limiting**: Track API calls, page views, or implement rate limiters using atomic INCR
- **Distributed locks**: Implement mutex locks across distributed systems using SET with NX and EX options

**Example Usage:**
```bash
# API rate limiting - allow 100 requests per minute
SET rate:user:123 0 EX 60 NX
INCR rate:user:123
# Check if value <= 100

# Session storage with 30 minute expiration
SET session:abc123 '{"user_id":456,"name":"John"}' EX 1800

# Page view counter
INCR pageviews:homepage

# Cache API response for 1 hour
SET cache:api:users:list '[{"id":1,"name":"John"}]' EX 3600
```

---

### 2. Lists

**Description:** Lists are ordered collections of strings implemented as linked lists, allowing efficient insertion and deletion at both ends (head and tail) with O(1) complexity. They maintain insertion order and allow duplicate elements. Lists are ideal for implementing queues, stacks, or maintaining chronological data like activity feeds. You can access elements by index, but middle insertions/deletions are O(N). Lists can contain up to 2^32 - 1 elements (over 4 billion).

```bash
# Push
LPUSH key value1 value2                   # Push to left (head)
RPUSH key value1 value2                   # Push to right (tail)
LPUSHX key value                          # Push to left if key exists
RPUSHX key value                          # Push to right if key exists

# Pop
LPOP key                                  # Pop from left
RPOP key                                  # Pop from right
LPOP key count                            # Pop multiple from left
RPOP key count                            # Pop multiple from right

# Blocking pop
BLPOP key timeout                         # Block until element available
BRPOP key timeout                         # Block until element available
BLPOP key1 key2 timeout                   # From multiple lists

# Get
LINDEX key index                          # Get element by index
LRANGE key start stop                     # Get range of elements
LRANGE key 0 -1                           # Get all elements
LLEN key                                  # Get list length

# Set
LSET key index value                      # Set element at index

# Insert
LINSERT key BEFORE|AFTER pivot value      # Insert before/after element

# Remove
LREM key count value                      # Remove elements
LTRIM key start stop                      # Trim to range

# Move
RPOPLPUSH source destination              # Pop from right, push to left of another
LMOVE source dest LEFT|RIGHT LEFT|RIGHT   # Move element between lists
BLMOVE source dest LEFT|RIGHT LEFT|RIGHT timeout  # Blocking move
```

**Use Cases:**
- **Message queues**: Implement FIFO queues using LPUSH/RPOP or reliable queues with blocking operations
- **Activity feeds**: Store user activities, social media feeds with most recent items at the head
- **Recent items lists**: Track recently viewed products, search history with LTRIM to limit size
- **Task queues**: Background job processing with multiple consumers using BRPOP for blocking

**Example Usage:**
```bash
# Task queue - producer adds tasks, consumer processes
LPUSH task:queue '{"job":"send_email","user":123}'
BRPOP task:queue 5  # Consumer blocks for 5 seconds waiting for task

# Activity feed - show last 50 activities
LPUSH feed:user:123 '{"action":"posted","time":"2024-01-15"}'
LTRIM feed:user:123 0 49  # Keep only 50 most recent
LRANGE feed:user:123 0 9  # Get 10 most recent activities

# Recent searches (max 10)
LPUSH recent:searches:user:123 "laptop"
LTRIM recent:searches:user:123 0 9

# Simple stack (LIFO)
LPUSH stack item1
LPOP stack  # Returns item1
```

---

### 3. Sets

**Description:** Sets are unordered collections of unique strings with no duplicate elements. They provide O(1) time complexity for adding, removing, and checking membership, making them extremely fast for uniqueness operations. Sets excel at mathematical set operations like unions, intersections, and differences. They're implemented using hash tables internally, providing constant-time performance regardless of set size. Perfect for scenarios requiring uniqueness and set-based calculations.

```bash
# Add/Remove
SADD key member1 member2                  # Add members
SREM key member1 member2                  # Remove members
SPOP key                                  # Remove and return random member
SPOP key count                            # Remove and return multiple random

# Get
SMEMBERS key                              # Get all members
SCARD key                                 # Get number of members
SISMEMBER key member                      # Check if member exists
SMISMEMBER key member1 member2            # Check multiple members
SRANDMEMBER key                           # Get random member
SRANDMEMBER key count                     # Get multiple random members

# Set operations
SINTER key1 key2                          # Intersection
SINTERSTORE dest key1 key2                # Store intersection
SUNION key1 key2                          # Union
SUNIONSTORE dest key1 key2                # Store union
SDIFF key1 key2                           # Difference
SDIFFSTORE dest key1 key2                 # Store difference

# Move
SMOVE source dest member                  # Move member between sets

# Scan
SSCAN key cursor                          # Iterate over members
```

**Use Cases:**
- **Tags for blog posts**: Store unique tags per article, quickly find articles with specific tags
- **Unique visitors tracking**: Track unique visitors using user IDs, no duplicates
- **Social network relationships**: Store followers/following with fast lookup and set operations for mutual friends
- **Permission systems**: Store user permissions, check access rights with O(1) lookup

**Example Usage:**
```bash
# Blog post tags
SADD post:123:tags "redis" "database" "nosql"
SISMEMBER post:123:tags "redis"  # Check if post has tag
SMEMBERS post:123:tags  # Get all tags

# Track unique daily visitors
SADD visitors:2024-01-15 user:123 user:456 user:789
SCARD visitors:2024-01-15  # Count unique visitors

# Social network - find mutual friends
SADD friends:alice bob charlie david
SADD friends:bob alice charlie emily
SINTER friends:alice friends:bob  # Returns: alice, charlie

# Find users who follow A but not B
SDIFF followers:alice followers:bob

# User permissions
SADD user:123:permissions "read" "write" "delete"
SISMEMBER user:123:permissions "admin"  # Fast permission check
```

---

### 4. Sorted Sets (ZSets)

**Description:** Sorted Sets combine the uniqueness of sets with automatic ordering by a numeric score. Each member is associated with a floating-point score, and members are always sorted by this score. Operations like adding, removing, and updating scores are O(log N), while accessing elements by rank or score range is very efficient. Sorted sets are implemented using a skip list and hash table, providing both ordered access and fast lookups. They're perfect for ranking systems, priority queues, and time-series data where you need both fast access and ordered retrieval.

```bash
# Add/Update
ZADD key score member                     # Add member with score
ZADD key NX score member                  # Add only if doesn't exist
ZADD key XX score member                  # Update only if exists
ZADD key GT score member                  # Update only if new score is greater
ZADD key LT score member                  # Update only if new score is less
ZADD key score1 member1 score2 member2    # Add multiple

# Remove
ZREM key member                           # Remove member
ZPOPMIN key                               # Remove and return lowest score
ZPOPMAX key                               # Remove and return highest score
ZPOPMIN key count                         # Remove multiple lowest
ZPOPMAX key count                         # Remove multiple highest
BZPOPMIN key timeout                      # Blocking pop min
BZPOPMAX key timeout                      # Blocking pop max

# Get by rank
ZRANGE key start stop                     # Get by rank (ascending)
ZRANGE key start stop WITHSCORES          # With scores
ZREVRANGE key start stop                  # Get by rank (descending)
ZRANGE key start stop BYSCORE             # Get by score range
ZRANGEBYSCORE key min max                 # Get by score range
ZREVRANGEBYSCORE key max min              # Reverse by score

# Get by score
ZCOUNT key min max                        # Count in score range
ZRANGEBYSCORE key min max LIMIT offset count  # With limit
ZRANGEBYSCORE key -inf +inf               # All (negative/positive infinity)

# Rank and Score
ZRANK key member                          # Get rank (ascending)
ZREVRANK key member                       # Get rank (descending)
ZSCORE key member                         # Get score
ZCARD key                                 # Get number of members

# Increment
ZINCRBY key increment member              # Increment score

# Remove by rank/score
ZREMRANGEBYRANK key start stop            # Remove by rank range
ZREMRANGEBYSCORE key min max              # Remove by score range

# Set operations
ZINTER numkeys key1 key2                  # Intersection
ZINTERSTORE dest numkeys key1 key2        # Store intersection
ZUNION numkeys key1 key2                  # Union
ZUNIONSTORE dest numkeys key1 key2        # Store union
ZDIFF numkeys key1 key2                   # Difference
ZDIFFSTORE dest numkeys key1 key2         # Store difference

# Scan
ZSCAN key cursor                          # Iterate over members
```

**Use Cases:**
- **Leaderboards**: Game rankings, user scores with automatic ordering and fast rank lookups
- **Priority queues**: Task prioritization based on urgency scores, job scheduling
- **Rate limiters with sliding windows**: Track requests with timestamps for precise rate limiting
- **Auto-complete systems**: Store suggestions with popularity scores for ranked results
- **Time-series data**: Store events with timestamps, query by time ranges efficiently

**Example Usage:**
```bash
# Game leaderboard
ZADD leaderboard 1500 "player:alice" 2300 "player:bob" 1800 "player:charlie"
ZREVRANGE leaderboard 0 9 WITHSCORES  # Top 10 players
ZREVRANK leaderboard "player:alice"  # Get player's rank (0-indexed)
ZINCRBY leaderboard 50 "player:alice"  # Add points

# Priority task queue (higher score = higher priority)
ZADD tasks 10 "task:email" 50 "task:backup" 100 "task:critical_bug"
ZPOPMAX tasks  # Get and remove highest priority task

# Sliding window rate limiter (allow 100 requests per minute)
SET now = timestamp
ZADD ratelimit:user:123 $now $now
ZREMRANGEBYSCORE ratelimit:user:123 0 ($now - 60)  # Remove old entries
ZCARD ratelimit:user:123  # Check if <= 100

# Time-series events
ZADD events:user:123 1705334400 "login" 1705334500 "purchase"
ZRANGEBYSCORE events:user:123 1705334000 1705420399  # Events in date range

# Auto-complete with popularity
ZADD autocomplete 1500 "redis" 2000 "python" 800 "postgres"
ZREVRANGE autocomplete 0 4  # Top 5 suggestions
```

---

### 5. Hashes

**Description:** Hashes are maps of field-value pairs, similar to objects or dictionaries in programming languages. They're optimized for representing objects with multiple attributes, storing them efficiently in a single key. Operations on individual fields are O(1), making them extremely fast for accessing or updating specific attributes. Hashes use less memory than storing each field as a separate string key, making them ideal for storing objects like user profiles, product details, or session data. Each hash can store up to 2^32 - 1 field-value pairs.

```bash
# Set/Get
HSET key field value                      # Set field
HGET key field                            # Get field value
HMSET key field1 val1 field2 val2         # Set multiple fields (deprecated)
HMGET key field1 field2                   # Get multiple fields
HGETALL key                               # Get all fields and values
HKEYS key                                 # Get all field names
HVALS key                                 # Get all values

# Set if not exists
HSETNX key field value                    # Set if field doesn't exist

# Delete
HDEL key field1 field2                    # Delete fields

# Exists
HEXISTS key field                         # Check if field exists
HLEN key                                  # Get number of fields

# Increment
HINCRBY key field increment               # Increment field (integer)
HINCRBYFLOAT key field increment          # Increment field (float)

# Get length
HSTRLEN key field                         # Get field value length

# Random field
HRANDFIELD key                            # Get random field
HRANDFIELD key count                      # Get multiple random fields

# Scan
HSCAN key cursor                          # Iterate over fields
```

**Use Cases:**
- **User profiles**: Store user data with multiple fields (name, email, age) in single key
- **Session storage**: Store session attributes efficiently with per-field access and updates
- **Object caching**: Cache database objects or API responses with structured data
- **Shopping carts**: Store cart items with quantities, prices as individual fields
- **Configuration storage**: Application settings with fast field-level access

**Example Usage:**
```bash
# User profile
HSET user:123 name "John Doe" email "john@example.com" age 30 country "US"
HGET user:123 email  # Get single field
HMGET user:123 name email  # Get multiple fields
HGETALL user:123  # Get all fields and values
HINCRBY user:123 login_count 1  # Increment counter

# Session storage
HSET session:xyz user_id 123 ip "192.168.1.1" last_activity 1705334400
EXPIRE session:xyz 1800  # 30 minute session timeout
HGET session:xyz user_id

# Shopping cart
HSET cart:456 product:1 2 product:5 1 product:12 3  # product_id: quantity
HINCRBY cart:456 product:1 1  # Add one more of product 1
HDEL cart:456 product:5  # Remove product from cart
HLEN cart:456  # Number of unique products

# Application config
HSET config:app debug true max_connections 100 timeout 30
HGET config:app max_connections

# Product catalog
HSET product:789 name "Laptop" price 999.99 stock 50 category "Electronics"
HINCRBYFLOAT product:789 price -50.00  # Apply discount
HINCRBY product:789 stock -1  # Decrease stock
```

---

### 6. Bitmaps

**Description:** Bitmaps are not a separate data type but a set of bit-oriented operations on the String type. They allow you to treat a string as an array of bits, with each bit representing a boolean value (0 or 1). Bitmaps are extremely memory efficient - you can store information about 4 billion users in just 512MB. Operations are very fast at O(1) for getting/setting individual bits. Perfect for tracking binary states like user activity, feature flags, or permissions where memory efficiency is crucial.

```bash
# Set/Get bit
SETBIT key offset value                   # Set bit (0 or 1)
GETBIT key offset                         # Get bit value

# Bit operations
BITCOUNT key                              # Count set bits (1s)
BITCOUNT key start end                    # Count in byte range
BITPOS key bit                            # Find first bit set to 0 or 1
BITPOS key bit start end                  # In byte range

# Bit operations between keys
BITOP AND destkey key1 key2               # Bitwise AND
BITOP OR destkey key1 key2                # Bitwise OR
BITOP XOR destkey key1 key2               # Bitwise XOR
BITOP NOT destkey key                     # Bitwise NOT

# Bit field
BITFIELD key GET type offset              # Get bit field
BITFIELD key SET type offset value        # Set bit field
BITFIELD key INCRBY type offset increment # Increment bit field
```

**Use Cases:**
- **Real-time analytics**: Track daily/monthly active users with minimal memory footprint
- **Feature flags**: Enable/disable features per user with single bit per feature
- **Permissions and access control**: Store permission bits for millions of users efficiently
- **Tracking user actions**: Mark if user completed action (login, purchase, email open)
- **Bloom filters**: Implement probabilistic data structures for set membership testing

**Example Usage:**
```bash
# Daily active users - user_id as bit offset
SETBIT active:2024-01-15 123 1  # User 123 was active
SETBIT active:2024-01-15 456 1  # User 456 was active
BITCOUNT active:2024-01-15  # Count active users today

# Users active on both days
BITOP AND active:both active:2024-01-15 active:2024-01-16
BITCOUNT active:both

# Feature flags per user (bit 0=premium, bit 1=beta, bit 2=admin)
SETBIT user:123:flags 0 1  # Enable premium
SETBIT user:123:flags 2 1  # Enable admin
GETBIT user:123:flags 1  # Check if beta enabled

# Track which products user viewed (product_id as offset)
SETBIT user:123:viewed 10 1
SETBIT user:123:viewed 25 1
BITCOUNT user:123:viewed  # Number of products viewed

# Email campaign tracking
SETBIT email:campaign:123:opened 456 1  # User 456 opened email
SETBIT email:campaign:123:clicked 456 1  # User 456 clicked link
BITCOUNT email:campaign:123:opened  # How many opened
```

---

### 7. HyperLogLog

**Description:** HyperLogLog is a probabilistic algorithm for counting unique elements (cardinality estimation) with incredible memory efficiency. It uses only 12KB of memory regardless of whether you're counting 1 million or 1 billion unique items. The tradeoff is a small error rate (standard error of 0.81%), which is acceptable for most analytics use cases. Perfect for counting unique visitors, unique search queries, or any scenario where exact counts aren't critical but memory efficiency is paramount. Operations are O(1) for adding and O(N) for counting (where N is the number of HyperLogLogs being merged).

```bash
# Add
PFADD key element1 element2               # Add elements

# Count
PFCOUNT key                               # Get approximate count
PFCOUNT key1 key2                         # Combined count

# Merge
PFMERGE destkey sourcekey1 sourcekey2     # Merge HyperLogLogs
```

**Use Cases:**
- **Unique visitors counting**: Count unique daily/monthly visitors without storing IDs
- **Unique search queries**: Track unique search terms with minimal memory
- **Cardinality estimation**: Estimate unique items in streams or large datasets
- **Large-scale analytics**: Analytics at scale where approximate counts are acceptable

**Example Usage:**
```bash
# Daily unique visitors
PFADD visitors:2024-01-15 user:123 user:456 user:789
PFADD visitors:2024-01-15 user:123  # Duplicate, won't increase count
PFCOUNT visitors:2024-01-15  # Get approximate unique count

# Unique visitors across multiple days
PFCOUNT visitors:2024-01-15 visitors:2024-01-16 visitors:2024-01-17

# Merge multiple days into one
PFMERGE visitors:week visitors:2024-01-15 visitors:2024-01-16 visitors:2024-01-17
PFCOUNT visitors:week  # Unique visitors for the week

# Track unique IPs accessing API endpoint
PFADD api:endpoint:users:ips 192.168.1.1 10.0.0.5 172.16.0.1
PFCOUNT api:endpoint:users:ips  # Unique IP count

# Unique product views
PFADD product:123:unique_viewers user:1 user:5 user:12
PFCOUNT product:123:unique_viewers  # How many unique users viewed

# Compare: Traditional set vs HyperLogLog
# Set: SADD takes memory proportional to number of unique elements
# HyperLogLog: Always 12KB, but ~0.81% error rate
```

---

### 8. Geospatial

**Description:** Geospatial indexes allow you to store geographic coordinates (longitude, latitude) and perform radius-based queries to find nearby locations. Internally implemented using sorted sets with geohash encoding, providing efficient O(log(N) + M) complexity for radius queries (N is total elements, M is results). Supports distances in meters, kilometers, miles, and feet. Perfect for location-based services, finding nearby places, or implementing features like "stores near me". Handles Earth's curvature using the Haversine formula for accurate distance calculations.

```bash
# Add locations
GEOADD key longitude latitude member      # Add location
GEOADD key lon1 lat1 member1 lon2 lat2 member2  # Add multiple

# Get position
GEOPOS key member                         # Get coordinates
GEOPOS key member1 member2                # Get multiple

# Distance
GEODIST key member1 member2 M             # Distance in meters
GEODIST key member1 member2 KM            # Distance in kilometers
GEODIST key member1 member2 MI            # Distance in miles
GEODIST key member1 member2 FT            # Distance in feet

# Radius search
GEORADIUS key lon lat radius M            # Search by radius
GEORADIUS key lon lat radius KM WITHDIST  # With distance
GEORADIUS key lon lat radius KM WITHCOORD # With coordinates
GEORADIUS key lon lat radius KM COUNT 10  # Limit results

GEORADIUSBYMEMBER key member radius KM    # Search from member location

# Search (Redis 6.2+)
GEOSEARCH key FROMMEMBER member BYRADIUS 100 KM
GEOSEARCH key FROMLONLAT lon lat BYRADIUS 100 KM
GEOSEARCH key FROMMEMBER member BYBOX width height KM

# Hash
GEOHASH key member                        # Get geohash string
```

**Use Cases:**
- **Location-based services**: Find restaurants, gas stations, or points of interest nearby
- **Nearby places search**: "Find stores within 5km" functionality
- **Delivery tracking**: Track delivery vehicles and calculate distances to destinations
- **Ride-sharing applications**: Match drivers with passengers based on proximity
- **Store locators**: Help users find nearest store locations

**Example Usage:**
```bash
# Add store locations (longitude, latitude, store_id)
GEOADD stores -122.4194 37.7749 "store:sf" -118.2437 34.0522 "store:la"
GEOADD stores -73.9352 40.7306 "store:nyc"

# Get coordinates of a store
GEOPOS stores "store:sf"  # Returns: -122.4194, 37.7749

# Calculate distance between two stores
GEODIST stores "store:sf" "store:la" KM  # Returns distance in kilometers

# Find stores within 100km of coordinates
GEORADIUS stores -122.4194 37.7749 100 KM WITHDIST WITHCOORD
# Returns stores with distances and coordinates

# Find stores within 50km of another store
GEORADIUSBYMEMBER stores "store:sf" 50 KM COUNT 5 ASC
# Returns 5 closest stores, sorted by distance

# Modern search API (Redis 6.2+)
GEOSEARCH stores FROMLONLAT -122.4194 37.7749 BYRADIUS 100 KM WITHDIST

# Delivery tracking - update driver locations
GEOADD drivers:online -122.41 37.78 "driver:123" -122.43 37.76 "driver:456"
GEOSEARCH drivers:online FROMLONLAT -122.42 37.77 BYRADIUS 2 KM
# Find drivers within 2km of pickup location

# Geohash for approximate locations
GEOHASH stores "store:sf"  # Returns geohash string for external use
```

---

### 9. Streams

**Description:** Redis Streams is a sophisticated append-only log data structure, similar to Apache Kafka, designed for high-throughput message queuing and event streaming. Each entry has an auto-generated unique ID (timestamp-sequence) and contains multiple field-value pairs. Streams support consumer groups for distributed processing, allowing multiple consumers to process different messages concurrently with automatic load balancing. Features include message acknowledgment, pending message tracking, and the ability to claim abandoned messages. Perfect for event sourcing, activity feeds, and building real-time data pipelines with at-least-once delivery guarantees.

```bash
# Add to stream
XADD stream * field1 value1 field2 value2 # Add entry (auto ID)
XADD stream 1234567890-0 field value      # Add with specific ID
XADD stream MAXLEN 1000 * field value     # With max length
XADD stream MAXLEN ~ 1000 * field value   # Approximate max length

# Read from stream
XREAD COUNT 2 STREAMS stream 0            # Read 2 entries from start
XREAD BLOCK 5000 STREAMS stream $         # Block for new entries
XREAD COUNT 10 STREAMS stream1 stream2 0-0 0-0  # Multiple streams

# Read range
XRANGE stream start end                   # Read range
XRANGE stream start end COUNT 10          # Limited
XREVRANGE stream end start                # Reverse order

# Length
XLEN stream                               # Get stream length

# Delete
XDEL stream ID                            # Delete entry
XTRIM stream MAXLEN 1000                  # Trim stream

# Info
XINFO STREAM stream                       # Stream info
XINFO GROUPS stream                       # Consumer groups info
XINFO CONSUMERS stream group              # Consumers info

# Consumer Groups
XGROUP CREATE stream group ID             # Create consumer group
XGROUP CREATE stream group $ MKSTREAM     # Create group and stream
XGROUP DESTROY stream group               # Delete group
XGROUP SETID stream group ID              # Set last delivered ID

XREADGROUP GROUP group consumer STREAMS stream >  # Read new
XREADGROUP GROUP group consumer COUNT 10 STREAMS stream >
XACK stream group ID                      # Acknowledge message
XPENDING stream group                     # Pending messages
XCLAIM stream group consumer min-idle-time ID  # Claim pending message
```

**Use Cases:**
- **Event sourcing**: Store all events as immutable log for audit trails and replay
- **Activity feeds**: User activity streams with multiple consumers processing different aspects
- **Message queues with consumer groups**: Distributed task processing with load balancing
- **Real-time analytics**: Stream processing for metrics, monitoring, and analytics
- **Log aggregation**: Collect and process logs from multiple services

**Example Usage:**
```bash
# Producer: Add events to stream
XADD events:user:activity * user_id 123 action "login" ip "192.168.1.1"
# Returns: "1705334400000-0" (timestamp-sequence ID)

XADD events:user:activity * user_id 123 action "purchase" product_id 456
XADD events:user:activity * user_id 789 action "logout"

# Consumer: Read from stream
XREAD COUNT 10 STREAMS events:user:activity 0  # Read from beginning
XREAD COUNT 10 STREAMS events:user:activity $  # Read only new entries

# Blocking read (wait for new messages)
XREAD BLOCK 5000 STREAMS events:user:activity $  # Wait 5 seconds

# Consumer Groups: Multiple consumers process stream
XGROUP CREATE events:user:activity analytics $ MKSTREAM  # Create group

# Consumer 1 reads messages
XREADGROUP GROUP analytics consumer1 COUNT 1 STREAMS events:user:activity >
# Returns: message with ID

# Acknowledge processed message
XACK events:user:activity analytics 1705334400000-0

# Consumer 2 reads different messages (load balancing)
XREADGROUP GROUP analytics consumer2 COUNT 1 STREAMS events:user:activity >

# Check pending messages (not yet acknowledged)
XPENDING events:user:activity analytics

# Claim stale messages from failed consumer
XCLAIM events:user:activity analytics consumer2 3600000 1705334400000-0

# Read range of messages
XRANGE events:user:activity 1705334000000 1705420399999  # By time range
XRANGE events:user:activity - +  # All messages

# Stream info
XLEN events:user:activity  # Number of entries
XINFO STREAM events:user:activity  # Detailed info
XINFO GROUPS events:user:activity  # Consumer group info

# Trim stream to prevent unlimited growth
XTRIM events:user:activity MAXLEN 10000  # Keep last 10,000 entries
```

---

## Advanced Features

### 10. Transactions

**Description:** Redis transactions allow you to group multiple commands together for atomic execution - either all commands execute or none do. Commands are queued during MULTI and executed atomically with EXEC. While queued, commands aren't actually executed, so you can't use results from one command in another within the same transaction. Transactions provide isolation (other clients' commands won't interleave) but not rollback on errors - if one command fails, others still execute. Use WATCH for optimistic locking to implement check-and-set operations. Transactions are useful for maintaining data consistency when updating multiple keys.

```bash
# Transaction
MULTI                                     # Start transaction
# ... commands ...
EXEC                                      # Execute transaction
DISCARD                                   # Cancel transaction

# Watch (optimistic locking)
WATCH key1 key2                           # Watch keys for changes
UNWATCH                                   # Stop watching

# Example:
WATCH balance
MULTI
DECRBY balance 100
INCRBY other_balance 100
EXEC
```

**Use Cases:**
- **Bank transfers**: Transfer money between accounts atomically
- **Atomic updates of multiple keys**: Update related data consistently (user stats, counters)
- **Inventory management**: Decrement stock and create order atomically
- **Optimistic locking**: Check-and-set operations with WATCH to prevent race conditions

**Example Usage:**
```bash
# Simple transaction - transfer funds
MULTI
DECRBY account:1:balance 100
INCRBY account:2:balance 100
EXEC  # Both execute atomically

# Transaction with multiple operations
MULTI
SET user:123:name "John"
HSET user:123:profile age 30 city "NYC"
SADD users:active 123
INCR stats:total_users
EXEC

# Optimistic locking with WATCH
WATCH account:1:balance  # Monitor key for changes
balance = GET account:1:balance
if balance >= 100:
    MULTI
    DECRBY account:1:balance 100
    INCRBY account:2:balance 100
    EXEC  # Returns nil if account:1:balance was modified
else:
    UNWATCH

# Check-and-set pattern
WATCH inventory:product:123
stock = GET inventory:product:123
if stock > 0:
    MULTI
    DECR inventory:product:123
    LPUSH orders:pending "order_details"
    EXEC
else:
    UNWATCH  # Cancel watch

# Cancel transaction
MULTI
SET key1 value1
SET key2 value2
DISCARD  # Abort, commands won't execute
```

---

### 11. Pub/Sub

**Description:** Redis Pub/Sub implements the publisher/subscriber messaging pattern for real-time message broadcasting. Publishers send messages to channels without knowledge of subscribers, and subscribers receive all messages published to their subscribed channels. Messages are fire-and-forget - if no subscribers are listening, the message is lost. Pub/Sub is pattern-based, allowing subscriptions to multiple channels using wildcards (e.g., "news.*"). It's perfect for real-time notifications, chat systems, and event broadcasting. Note: Pub/Sub doesn't persist messages, so it's not suitable for reliable message queuing (use Streams for that).

```bash
# Subscribe
SUBSCRIBE channel1 channel2               # Subscribe to channels
PSUBSCRIBE pattern*                       # Subscribe to patterns

# Unsubscribe
UNSUBSCRIBE channel1                      # Unsubscribe from channels
PUNSUBSCRIBE pattern*                     # Unsubscribe from patterns

# Publish
PUBLISH channel message                   # Publish message

# Info
PUBSUB CHANNELS                           # List active channels
PUBSUB CHANNELS pattern*                  # List matching channels
PUBSUB NUMSUB channel1 channel2           # Number of subscribers
PUBSUB NUMPAT                             # Number of pattern subscriptions
```

**Use Cases:**
- **Real-time notifications**: Push notifications to connected users instantly
- **Chat applications**: Broadcast messages to chat room participants
- **Live updates**: Real-time sports scores, stock prices, or news updates
- **Event broadcasting**: Notify multiple services about system events
- **Distributed system coordination**: Signal cache invalidation or config changes across servers

**Example Usage:**
```bash
# Publisher: Send messages to channels
PUBLISH news:sports "Team A wins championship"
PUBLISH news:tech "New product launched"
PUBLISH alerts:critical "System maintenance in 5 minutes"

# Subscriber: Listen to specific channels
SUBSCRIBE news:sports news:tech
# Blocks and waits for messages
# Output: message from channel, message content

# Pattern-based subscription (wildcard)
PSUBSCRIBE news:*  # Subscribe to all news channels
PSUBSCRIBE alert:*  # Subscribe to all alert channels
PSUBSCRIBE user:123:*  # Subscribe to all channels for user 123

# Chat room example
# User joins room
SUBSCRIBE chat:room:42

# User sends message (from another connection)
PUBLISH chat:room:42 "user:123:Hello everyone!"

# Multiple users receive message instantly

# Real-time notifications
SUBSCRIBE notifications:user:123
# Publisher sends notification
PUBLISH notifications:user:123 '{"type":"message","from":"user:456"}'

# Event broadcasting for cache invalidation
SUBSCRIBE cache:invalidate
# When data changes
PUBLISH cache:invalidate "user:123"
# All servers clear their cache for user:123

# Check active channels and subscribers
PUBSUB CHANNELS  # List all active channels
PUBSUB CHANNELS news:*  # List matching channels
PUBSUB NUMSUB chat:room:42  # Number of subscribers to channel
PUBSUB NUMPAT  # Number of pattern subscriptions

# Unsubscribe
UNSUBSCRIBE news:sports
PUNSUBSCRIBE news:*
```

---

### 12. Lua Scripting

**Description:** Lua scripting allows you to execute complex operations atomically on the Redis server, combining multiple Redis commands into a single atomic script. Scripts run without interruption from other clients, ensuring data consistency. The main benefits are atomicity (entire script executes as one operation), reduced network round-trips (one call instead of many), and the ability to implement custom logic with conditions and loops. Scripts can be cached on the server using SHA1 hashes for efficient reuse. All Redis commands are available through redis.call() and redis.pcall(), with full Lua language support for conditional logic, loops, and data manipulation.

```bash
# Evaluate script
EVAL "return redis.call('SET', KEYS[1], ARGV[1])" 1 key value

# Example: Increment if exists
EVAL "if redis.call('EXISTS', KEYS[1]) == 1 then
  return redis.call('INCR', KEYS[1])
else
  return 0
end" 1 mykey

# Load script
SCRIPT LOAD "return redis.call('GET', KEYS[1])"  # Returns SHA1

# Execute loaded script
EVALSHA sha1 numkeys key1 key2 arg1 arg2

# Script management
SCRIPT EXISTS sha1                        # Check if script cached
SCRIPT FLUSH                              # Remove all scripts
SCRIPT KILL                               # Kill running script

# Example: Rate limiter
EVAL "local current = redis.call('INCR', KEYS[1])
if current == 1 then
  redis.call('EXPIRE', KEYS[1], ARGV[1])
end
if current > tonumber(ARGV[2]) then
  return 0
end
return 1" 1 rate_limit:user123 60 100
```

**Use Cases:**
- **Complex atomic operations**: Multi-step operations that must execute together atomically
- **Custom commands**: Create domain-specific operations combining multiple Redis commands
- **Rate limiting**: Implement sophisticated rate limiting with sliding windows
- **Conditional updates**: Check conditions and update only if criteria are met
- **Distributed locks**: Implement reliable distributed locking with expiration checks

**Example Usage:**
```bash
# Simple conditional increment
EVAL "
if redis.call('EXISTS', KEYS[1]) == 1 then
  return redis.call('INCR', KEYS[1])
else
  return 0
end
" 1 mykey

# Rate limiter with sliding window
EVAL "
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local current = redis.call('INCR', key)
if current == 1 then
  redis.call('EXPIRE', key, window)
end
if current > limit then
  return 0
else
  return 1
end
" 1 rate:user:123 100 60  # 100 requests per 60 seconds

# Distributed lock with timeout check
EVAL "
if redis.call('GET', KEYS[1]) == ARGV[1] then
  return redis.call('DEL', KEYS[1])
else
  return 0
end
" 1 lock:resource my-unique-token

# Atomic pop and push to different list
EVAL "
local value = redis.call('RPOP', KEYS[1])
if value then
  redis.call('LPUSH', KEYS[2], value)
  return value
else
  return nil
end
" 2 source:list dest:list

# Check and set with expiration
EVAL "
local current = redis.call('GET', KEYS[1])
if current == ARGV[1] then
  redis.call('SETEX', KEYS[1], ARGV[3], ARGV[2])
  return 1
else
  return 0
end
" 1 mykey expected_value new_value 3600

# Load script and execute by SHA
SCRIPT LOAD "return redis.call('GET', KEYS[1])"
# Returns: "6b1bf486c81ceb7edf3c093f4c48582e38c0e791"

# Execute loaded script
EVALSHA 6b1bf486c81ceb7edf3c093f4c48582e38c0e791 1 mykey

# Conditional multi-key update
EVAL "
local stock = tonumber(redis.call('GET', KEYS[1]))
local quantity = tonumber(ARGV[1])
if stock >= quantity then
  redis.call('DECRBY', KEYS[1], quantity)
  redis.call('HINCRBY', KEYS[2], 'orders', 1)
  redis.call('HINCRBY', KEYS[2], 'revenue', ARGV[2])
  return 1
else
  return 0
end
" 2 inventory:product:123 stats:shop 5 99.99

# Kill long-running script
SCRIPT KILL

# Clear script cache
SCRIPT FLUSH
```

---

### 13. Persistence

**Description:** Save in-memory data to disk. Two persistence options: RDB and AOF.

**RDB (Redis Database Backup):**
- Point-in-time snapshots
- Compact, fast to load
- Potential data loss between snapshots

```bash
# Configuration
save 900 1                                # Save after 900s if 1 key changed
save 300 10                               # Save after 300s if 10 keys changed
save 60 10000                             # Save after 60s if 10000 keys changed

# Manual save
SAVE                                      # Blocking save
BGSAVE                                    # Background save
LASTSAVE                                  # Last save timestamp
```

**AOF (Append Only File):**
- Logs every write operation
- More durable, less data loss
- Larger file size, slower restarts

```bash
# Configuration
appendonly yes                            # Enable AOF
appendfsync always                        # Sync every write
appendfsync everysec                      # Sync every second (default)
appendfsync no                            # Let OS decide

# Rewrite
BGREWRITEAOF                             # Rewrite AOF in background
```

**Use Cases:**
- Data durability
- Disaster recovery
- Database backups
- Point-in-time recovery

---

### 14. Replication

**Description:** Master-slave replication for high availability and read scaling.

```bash
# On slave
REPLICAOF host port                       # Set master (old: SLAVEOF)
REPLICAOF NO ONE                          # Promote to master

# Info
INFO replication                          # Replication status
ROLE                                      # Check role (master/slave)

# Configuration
replica-read-only yes                     # Read-only slave (default)
repl-diskless-sync yes                    # Diskless replication
```

**Features:**
- Asynchronous replication
- Automatic reconnection
- Partial resynchronization
- Read-only replicas
- Replication backlog

**Use Cases:**
- High availability
- Read scaling
- Data redundancy
- Geographic distribution

---

### 15. Sentinel

**Description:** High availability solution. Automatic failover and monitoring.

```bash
# Sentinel commands
SENTINEL masters                          # List monitored masters
SENTINEL master name                      # Master info
SENTINEL slaves name                      # Slaves info
SENTINEL sentinels name                   # Other sentinels
SENTINEL get-master-addr-by-name name     # Get master address
SENTINEL failover name                    # Force failover
SENTINEL reset pattern                    # Reset monitored instances
SENTINEL monitor name ip port quorum      # Monitor new master
SENTINEL remove name                      # Stop monitoring
```

**Features:**
- Monitoring
- Notification
- Automatic failover
- Configuration provider

**Use Cases:**
- Automatic master failover
- High availability clusters
- Zero-downtime upgrades
- Disaster recovery

---

### 16. Cluster

**Description:** Distributed Redis. Data sharding across multiple nodes. Horizontal scaling.

```bash
# Cluster info
CLUSTER INFO                              # Cluster state
CLUSTER NODES                             # List nodes
CLUSTER SLOTS                             # Slot distribution
CLUSTER MYID                              # Current node ID

# Cluster management
CLUSTER MEET ip port                      # Add node
CLUSTER FORGET node-id                    # Remove node
CLUSTER REPLICATE node-id                 # Set as replica
CLUSTER FAILOVER                          # Manual failover

# Slots
CLUSTER ADDSLOTS slot1 slot2              # Assign slots
CLUSTER DELSLOTS slot1 slot2              # Remove slots
CLUSTER SETSLOT slot NODE node-id         # Assign slot to node
CLUSTER KEYSLOT key                       # Get key's slot

# Keys
CLUSTER GETKEYSINSLOT slot count          # Get keys in slot
CLUSTER COUNTKEYSINSLOT slot              # Count keys in slot
```

**Features:**
- Automatic sharding (16384 slots)
- Multi-master architecture
- Automatic failover
- Horizontal scaling
- No single point of failure

**Use Cases:**
- Large-scale deployments
- High throughput requirements
- Horizontal scaling
- Multi-datacenter setups

---

### 17. Pipelining

**Description:** Send multiple commands without waiting for responses. Reduces round-trip time.

```bash
# Using redis-cli
echo -e "SET key1 value1\nGET key1\nSET key2 value2" | redis-cli --pipe

# In code (Python example)
pipe = redis.pipeline()
pipe.set('key1', 'value1')
pipe.get('key1')
pipe.set('key2', 'value2')
pipe.execute()
```

**Benefits:**
- Reduced network latency
- Higher throughput
- Better performance for bulk operations

**Use Cases:**
- Bulk data loading
- Mass updates
- High-throughput applications
- Reducing network overhead

---

### 18. Memory Management

**Description:** Eviction policies and memory optimization.

```bash
# Eviction policies
maxmemory 256mb                           # Max memory limit
maxmemory-policy allkeys-lru              # Eviction policy

# Policies:
# noeviction - Return error when memory limit reached
# allkeys-lru - Evict least recently used keys
# volatile-lru - Evict LRU keys with expiration set
# allkeys-random - Evict random keys
# volatile-random - Evict random keys with expiration
# volatile-ttl - Evict keys with shortest TTL
# allkeys-lfu - Evict least frequently used keys (Redis 4.0+)
# volatile-lfu - Evict LFU keys with expiration (Redis 4.0+)

# Memory info
MEMORY USAGE key                          # Memory used by key
MEMORY STATS                              # Memory statistics
MEMORY DOCTOR                             # Memory analysis
MEMORY MALLOC-STATS                       # Allocator info
```

**Use Cases:**
- Cache management
- Memory optimization
- Preventing OOM errors
- Cost optimization

---

### 19. Key Expiration and TTL

**Description:** Automatic key expiration for time-limited data.

```bash
# Set expiration
EXPIRE key seconds                        # Set expiration in seconds
PEXPIRE key milliseconds                  # Set expiration in milliseconds
EXPIREAT key timestamp                    # Expire at Unix timestamp
PEXPIREAT key milliseconds-timestamp      # Expire at timestamp (ms)

# Get TTL
TTL key                                   # Get TTL in seconds (-1 = no expiry, -2 = doesn't exist)
PTTL key                                  # Get TTL in milliseconds

# Remove expiration
PERSIST key                               # Remove expiration

# Set with expiration
SET key value EX 60                       # Set with 60s expiration
SETEX key 60 value                        # Set with expiration
```

**Use Cases:**
- Session management
- Temporary tokens
- Rate limiting windows
- Cache invalidation
- Time-limited features

---

### 20. Scan Operations

**Description:** Iterate over keys without blocking. Cursor-based iteration.

```bash
# Scan keys
SCAN cursor                               # Scan all keys
SCAN cursor MATCH pattern                 # Scan with pattern
SCAN cursor COUNT 100                     # Scan with count hint
SCAN 0 MATCH user:* COUNT 10              # Example

# Scan data structures
SSCAN key cursor                          # Scan set
HSCAN key cursor                          # Scan hash
ZSCAN key cursor                          # Scan sorted set
SSCAN key cursor MATCH pattern COUNT 10   # With options

# Example: Iterate all keys
SCAN 0
# Returns: cursor and keys
# Use returned cursor for next call until cursor is 0
```

**Benefits:**
- Non-blocking iteration
- Handles large datasets
- No KEYS command performance issues
- Safe for production

**Use Cases:**
- Large database iteration
- Background data processing
- Key migration
- Debugging and monitoring

---

## Key Management

### Key Operations
```bash
# Existence
EXISTS key                                # Check if key exists
EXISTS key1 key2 key3                     # Check multiple

# Delete
DEL key                                   # Delete key
DEL key1 key2 key3                        # Delete multiple
UNLINK key                                # Async delete (non-blocking)

# Rename
RENAME key newkey                         # Rename key
RENAMENX key newkey                       # Rename if new key doesn't exist

# Type
TYPE key                                  # Get key type
OBJECT ENCODING key                       # Get internal encoding

# Keys
KEYS pattern                              # Find keys (avoid in production)
KEYS *                                    # All keys
KEYS user:*                               # Pattern match
RANDOMKEY                                 # Get random key

# Copy
COPY source destination                   # Copy key (Redis 6.2+)
COPY source dest REPLACE                  # Copy and replace

# Dump/Restore
DUMP key                                  # Serialize key
RESTORE key ttl serialized-value          # Restore serialized key

# Move
MOVE key db                               # Move key to another database
```

---

## Common Patterns

### 1. Caching
```bash
# Get from cache or compute
GET cache_key
# If not exists:
# - Compute value
SET cache_key value EX 3600
```

### 2. Rate Limiting (Fixed Window)
```bash
SET rate:user:123:minute INCR
EXPIRE rate:user:123:minute 60
# Check if count > limit
```

### 3. Rate Limiting (Sliding Window)
```bash
# Using sorted set with timestamps
ZADD rate:user:123 timestamp timestamp
ZREMRANGEBYSCORE rate:user:123 0 (now-60)
ZCARD rate:user:123
# Check if count > limit
```

### 4. Distributed Lock
```bash
# Acquire lock
SET lock:resource "token" NX EX 30
# If returns OK, lock acquired

# Release lock (with Lua)
EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then
  return redis.call('DEL', KEYS[1])
else
  return 0
end" 1 lock:resource token
```

### 5. Session Store
```bash
# Store session
HSET session:uuid:123 user_id 456 name "John" email "john@example.com"
EXPIRE session:uuid:123 3600

# Get session
HGETALL session:uuid:123
```

### 6. Leaderboard
```bash
# Add scores
ZADD leaderboard 1000 player1 950 player2 1200 player3

# Get top 10
ZREVRANGE leaderboard 0 9 WITHSCORES

# Get player rank
ZREVRANK leaderboard player1

# Get player score
ZSCORE leaderboard player1
```

### 7. Real-time Analytics
```bash
# Track page views (HyperLogLog)
PFADD pageviews:2024-01-15 user123 user456 user789

# Count unique viewers
PFCOUNT pageviews:2024-01-15
```

### 8. Message Queue
```bash
# Producer
LPUSH queue:tasks task_data

# Consumer
BRPOP queue:tasks 5  # Block for 5 seconds
# Process task
```

---

## Performance Tips

1. **Use appropriate data structures** - Choose the right structure for your use case
2. **Use pipelining** - Batch commands to reduce network overhead
3. **Avoid KEYS command** - Use SCAN for iterating in production
4. **Set expiration** - Let Redis automatically clean up old data
5. **Use connection pooling** - Reuse connections
6. **Monitor slow queries** - Use SLOWLOG to identify bottlenecks
7. **Optimize memory** - Use memory-efficient data structures
8. **Consider persistence** - Balance durability vs. performance
9. **Use Lua scripts** - Reduce round trips for complex operations
10. **Monitor memory usage** - Set maxmemory and eviction policies

---

## Monitoring

```bash
# Slow log
SLOWLOG GET 10                            # Get last 10 slow queries
SLOWLOG LEN                               # Number of slow queries
SLOWLOG RESET                             # Clear slow log

# Monitor
MONITOR                                   # Stream all commands (debugging only)

# Client list
CLIENT LIST                               # List connected clients
CLIENT KILL ip:port                       # Kill client connection
CLIENT SETNAME name                       # Set client name
CLIENT GETNAME                            # Get client name

# Stats
INFO stats                                # Statistics
INFO commandstats                         # Per-command stats
```

---

## Quick Reference

### Most Used Commands
```bash
SET key value                # Store value
GET key                      # Retrieve value
DEL key                      # Delete key
EXISTS key                   # Check existence
EXPIRE key seconds           # Set expiration
TTL key                      # Get time to live
INCR key                     # Increment
LPUSH list value             # Add to list
SADD set member              # Add to set
ZADD zset score member       # Add to sorted set
HSET hash field value        # Set hash field
```

### Data Structure Selection
- **String**: Simple values, counters, flags
- **List**: Ordered sequences, queues, stacks
- **Set**: Unique items, tags, relationships
- **Sorted Set**: Rankings, priorities, time-series
- **Hash**: Objects, structured data
- **Bitmap**: Binary state, feature flags
- **HyperLogLog**: Cardinality estimation
- **Geo**: Location data
- **Stream**: Event logs, message queues

### Time Complexity
Most Redis operations are O(1) or O(log N), making Redis extremely fast for most use cases.
