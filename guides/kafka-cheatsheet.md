# Apache Kafka Cheatsheet

## What is Kafka?

**Apache Kafka** is a distributed event streaming platform designed for high-throughput, fault-tolerant, real-time data pipelines and streaming applications. It acts as a distributed commit log where producers write messages to topics, and consumers read from those topics. Kafka excels at handling millions of events per second with low latency and provides durability through replication.

**Key Characteristics:**
- Distributed, partitioned, replicated commit log service
- Publish-subscribe messaging with persistence
- High throughput (millions of messages/second)
- Horizontal scalability across clusters
- Built-in fault tolerance and replication
- Message ordering within partitions
- Consumer groups for parallel processing
- Event streaming and processing capabilities

---

## Core Concepts

### Topics and Partitions

**Topics** are categories or feed names to which records are published. Topics are split into **partitions** for parallelism and scalability.

**Description:** A topic is a logical channel for messages, similar to a database table or folder. Each topic is divided into one or more partitions, which are ordered, immutable sequences of records. Partitions allow Kafka to scale horizontally - different partitions can be on different brokers, and multiple consumers can read from different partitions in parallel. Messages within a partition are ordered and assigned a sequential ID called an offset. The partition a message goes to is determined by the message key (or round-robin if no key).

**Key Points:**
- Topics are multi-subscriber (many consumers can read)
- Partitions provide parallelism and ordering guarantees
- Messages are retained for a configurable time (default 7 days)
- Each partition is replicated across brokers for fault tolerance
- Partition count determines maximum parallelism

**Example Usage:**
```bash
# Create topic with 3 partitions and replication factor 2
kafka-topics.sh --create \
  --topic orders \
  --partitions 3 \
  --replication-factor 2 \
  --bootstrap-server localhost:9092

# List all topics
kafka-topics.sh --list --bootstrap-server localhost:9092

# Describe topic (shows partitions, replicas, ISR)
kafka-topics.sh --describe \
  --topic orders \
  --bootstrap-server localhost:9092

# Increase partitions (can't decrease)
kafka-topics.sh --alter \
  --topic orders \
  --partitions 5 \
  --bootstrap-server localhost:9092

# Delete topic
kafka-topics.sh --delete \
  --topic orders \
  --bootstrap-server localhost:9092
```

**Use Cases:**
- **Event logs**: Store application events, audit logs
- **Metrics streams**: Collect system metrics, monitoring data
- **User activity**: Track clicks, page views, user actions
- **Database change streams**: CDC (Change Data Capture) from databases
- **IoT sensor data**: Collect readings from devices

---

### Producers

**Description:** Producers are clients that publish (write) records to Kafka topics. They send data to the Kafka cluster and can choose which partition within a topic to send to. Producers can send messages synchronously (wait for acknowledgment) or asynchronously (fire and forget). They support batching for efficiency, compression to reduce network usage, and can implement custom partitioning strategies. Producers handle connection failures automatically and can retry failed sends. The producer decides the partition based on the message key using a hash function, or uses round-robin if no key is provided.

**Key Configuration:**
- `bootstrap.servers`: Kafka broker addresses
- `key.serializer`: How to serialize message keys
- `value.serializer`: How to serialize message values
- `acks`: Acknowledgment level (0, 1, all)
- `compression.type`: gzip, snappy, lz4, zstd
- `batch.size`: Batch size in bytes
- `linger.ms`: Wait time before sending batch
- `retries`: Number of retry attempts
- `enable.idempotence`: Exactly-once semantics

**Example Usage:**
```bash
# Console producer (interactive)
kafka-console-producer.sh \
  --topic orders \
  --bootstrap-server localhost:9092

# Producer with key:value pairs
kafka-console-producer.sh \
  --topic orders \
  --property "parse.key=true" \
  --property "key.separator=:" \
  --bootstrap-server localhost:9092

# Example messages:
# user123:{"product":"laptop","price":999}
# user456:{"product":"phone","price":699}
```

**Example Code (Python with confluent-kafka):**
```python
from confluent_kafka import Producer

# Producer configuration
config = {
    'bootstrap.servers': 'localhost:9092',
    'client.id': 'python-producer',
    'acks': 'all',
    'compression.type': 'snappy',
    'enable.idempotence': True
}

producer = Producer(config)

# Delivery callback
def delivery_report(err, msg):
    if err:
        print(f'Delivery failed: {err}')
    else:
        print(f'Message delivered to {msg.topic()} [{msg.partition()}]')

# Produce message with key
producer.produce(
    topic='orders',
    key='user123',
    value='{"product":"laptop","price":999}',
    callback=delivery_report
)

# Flush to ensure delivery
producer.flush()
```

**Example Code (Java):**
```java
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("acks", "all");
props.put("enable.idempotence", true);

Producer<String, String> producer = new KafkaProducer<>(props);

ProducerRecord<String, String> record =
    new ProducerRecord<>("orders", "user123", "{\"product\":\"laptop\"}");

producer.send(record, (metadata, exception) -> {
    if (exception == null) {
        System.out.printf("Sent to partition %d with offset %d%n",
            metadata.partition(), metadata.offset());
    }
});

producer.close();
```

**Use Cases:**
- **Application logging**: Send logs to centralized Kafka cluster
- **Event sourcing**: Publish domain events from microservices
- **Data ingestion**: Stream data from databases, APIs, files
- **IoT data collection**: Collect sensor readings, device telemetry
- **User activity tracking**: Send clickstream, analytics events

---

### Consumers and Consumer Groups

**Description:** Consumers are clients that read (subscribe to) records from Kafka topics. They pull messages from brokers rather than brokers pushing to them, allowing consumers to control their read rate. Consumer Groups enable parallel consumption - multiple consumer instances form a group, and Kafka distributes partitions among them. Each partition is consumed by exactly one consumer in a group, providing load balancing and fault tolerance. If a consumer fails, its partitions are automatically reassigned to other group members (rebalancing). Consumers track their position using offsets, which can be committed automatically or manually for precise control.

**Key Configuration:**
- `bootstrap.servers`: Kafka broker addresses
- `group.id`: Consumer group identifier
- `key.deserializer`: How to deserialize keys
- `value.deserializer`: How to deserialize values
- `auto.offset.reset`: earliest, latest, none
- `enable.auto.commit`: Auto-commit offsets
- `max.poll.records`: Max records per poll
- `session.timeout.ms`: Consumer heartbeat timeout
- `fetch.min.bytes`: Minimum data to fetch
- `isolation.level`: read_uncommitted, read_committed

**Example Usage:**
```bash
# Console consumer (from beginning)
kafka-console-consumer.sh \
  --topic orders \
  --from-beginning \
  --bootstrap-server localhost:9092

# Consumer with group
kafka-console-consumer.sh \
  --topic orders \
  --group order-processors \
  --bootstrap-server localhost:9092

# Consumer showing key and value
kafka-console-consumer.sh \
  --topic orders \
  --property print.key=true \
  --property key.separator=":" \
  --bootstrap-server localhost:9092

# Consumer from specific offset
kafka-console-consumer.sh \
  --topic orders \
  --partition 0 \
  --offset 100 \
  --bootstrap-server localhost:9092
```

**Example Code (Python):**
```python
from confluent_kafka import Consumer

config = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'order-processors',
    'auto.offset.reset': 'earliest',
    'enable.auto.commit': False  # Manual commit for reliability
}

consumer = Consumer(config)
consumer.subscribe(['orders'])

try:
    while True:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            continue
        if msg.error():
            print(f'Consumer error: {msg.error()}')
            continue

        # Process message
        print(f'Received: {msg.key()}: {msg.value()}')

        # Manual commit after processing
        consumer.commit(msg)

except KeyboardInterrupt:
    pass
finally:
    consumer.close()
```

**Example Code (Java):**
```java
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
props.put("group.id", "order-processors");
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("enable.auto.commit", "false");
props.put("auto.offset.reset", "earliest");

KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
consumer.subscribe(Arrays.asList("orders"));

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(1000));

    for (ConsumerRecord<String, String> record : records) {
        System.out.printf("Partition: %d, Offset: %d, Key: %s, Value: %s%n",
            record.partition(), record.offset(), record.key(), record.value());

        // Process message
    }

    // Manual commit
    consumer.commitSync();
}
```

**Consumer Groups:**
```bash
# List consumer groups
kafka-consumer-groups.sh --list --bootstrap-server localhost:9092

# Describe consumer group (shows lag, offsets)
kafka-consumer-groups.sh \
  --describe \
  --group order-processors \
  --bootstrap-server localhost:9092

# Reset offsets to earliest
kafka-consumer-groups.sh \
  --reset-offsets \
  --to-earliest \
  --group order-processors \
  --topic orders \
  --execute \
  --bootstrap-server localhost:9092

# Reset to specific offset
kafka-consumer-groups.sh \
  --reset-offsets \
  --to-offset 100 \
  --group order-processors \
  --topic orders:0 \
  --execute \
  --bootstrap-server localhost:9092
```

**Use Cases:**
- **Real-time analytics**: Process streams for dashboards, metrics
- **Microservices communication**: Subscribe to events from other services
- **Data pipelines**: Move data between systems (ETL)
- **Alerting systems**: Monitor streams and trigger alerts
- **Search indexing**: Update search indexes from data streams

---

### Offsets and Offset Management

**Description:** Offsets are sequential IDs assigned to messages within a partition, starting from 0. They represent the position of a message in the partition log and are crucial for tracking consumer progress. Consumers commit offsets to Kafka (stored in internal `__consumer_offsets` topic) to remember their position. This allows consumers to resume from where they left off after restarts or failures. Offset management strategies include auto-commit (periodic automatic commits), manual commit (explicit control), and at-least-once vs exactly-once semantics. Understanding offset management is critical for achieving desired delivery guarantees and preventing data loss or duplication.

**Key Points:**
- Offsets are per-partition sequential numbers
- Consumer groups track their offset per partition
- Offsets are stored in internal `__consumer_offsets` topic
- Auto-commit can lead to message loss or duplication
- Manual commit provides precise control
- Can seek to specific offsets or timestamps

**Example Usage:**
```python
# Manual offset commit (at-least-once)
consumer.commit()  # Commit all
consumer.commit(msg)  # Commit specific message

# Synchronous commit (blocks until acknowledged)
consumer.commit(asynchronous=False)

# Get current position
partitions = consumer.assignment()
for partition in partitions:
    position = consumer.position([partition])
    print(f'Partition {partition.partition}: offset {position[0].offset}')

# Seek to specific offset
from confluent_kafka import TopicPartition
tp = TopicPartition('orders', 0, 100)  # topic, partition, offset
consumer.assign([tp])

# Seek to beginning/end
consumer.seek_to_beginning(partitions)
consumer.seek_to_end(partitions)

# Committed offsets
committed = consumer.committed(partitions)
```

**Offset Reset Strategies:**
- `earliest`: Start from beginning of partition
- `latest`: Start from end (only new messages)
- `none`: Throw exception if no offset found

**Use Cases:**
- **Reprocessing**: Reset offsets to replay historical data
- **Skip bad data**: Move offset forward to skip corrupted messages
- **Time-based replay**: Seek to timestamp to replay from specific time
- **Monitoring lag**: Track how far behind consumers are
- **Disaster recovery**: Restore processing from last committed offset

---

## Advanced Features

### Kafka Streams

**Description:** Kafka Streams is a client library for building real-time stream processing applications that transform data in Kafka topics. It provides a high-level DSL for common operations (map, filter, join, aggregate) and a low-level Processor API for custom logic. Streams applications are stateful, scalable (can run multiple instances), and fault-tolerant. They process data one record at a time with millisecond latency. Kafka Streams handles partitioning, distribution, and state management automatically. It supports windowing operations for time-based aggregations and exactly-once processing semantics.

**Key Features:**
- Stream-table duality (streams and tables)
- Stateful operations with local state stores
- Windowing (tumbling, hopping, sliding, session)
- Joins (stream-stream, stream-table, table-table)
- Exactly-once processing semantics
- Interactive queries on state stores
- Fault tolerance through changelog topics

**Example Code (Java):**
```java
Properties props = new Properties();
props.put(StreamsConfig.APPLICATION_ID_CONFIG, "word-count-app");
props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");

StreamsBuilder builder = new StreamsBuilder();

// Word count example
KStream<String, String> textLines = builder.stream("input-topic");

KTable<String, Long> wordCounts = textLines
    .flatMapValues(line -> Arrays.asList(line.toLowerCase().split("\\s+")))
    .groupBy((key, word) -> word)
    .count();

wordCounts.toStream().to("word-counts", Produced.with(Serdes.String(), Serdes.Long()));

KafkaStreams streams = new KafkaStreams(builder.build(), props);
streams.start();
```

**Windowing Example:**
```java
// Tumbling window (fixed, non-overlapping)
KTable<Windowed<String>, Long> windowedCounts = stream
    .groupByKey()
    .windowedBy(TimeWindows.of(Duration.ofMinutes(5)))
    .count();

// Hopping window (fixed size, overlapping)
KTable<Windowed<String>, Long> hoppingCounts = stream
    .groupByKey()
    .windowedBy(TimeWindows.of(Duration.ofMinutes(5))
                           .advanceBy(Duration.ofMinutes(1)))
    .count();

// Session window (activity-based)
KTable<Windowed<String>, Long> sessionCounts = stream
    .groupByKey()
    .windowedBy(SessionWindows.with(Duration.ofMinutes(5)))
    .count();
```

**Joins Example:**
```java
// Stream-stream join (within time window)
KStream<String, String> joined = stream1.join(
    stream2,
    (value1, value2) -> value1 + ":" + value2,
    JoinWindows.of(Duration.ofMinutes(5))
);

// Stream-table join (enrich stream with table data)
KTable<String, String> table = builder.table("user-table");
KStream<String, String> enriched = stream.join(
    table,
    (streamValue, tableValue) -> streamValue + ":" + tableValue
);
```

**Use Cases:**
- **Real-time analytics**: Count, aggregate, filter events in real-time
- **Data enrichment**: Join streams with reference data tables
- **Anomaly detection**: Detect patterns and outliers in streams
- **ETL pipelines**: Transform and route data between topics
- **Sessionization**: Group events by user sessions

---

### Kafka Connect

**Description:** Kafka Connect is a framework for scalably and reliably streaming data between Kafka and external systems like databases, key-value stores, search indexes, and file systems. It provides pre-built connectors for common systems and a plugin architecture for custom connectors. Connect runs in distributed mode for scalability and fault tolerance, or standalone mode for development. Source connectors read from external systems into Kafka, while sink connectors write from Kafka to external systems. Connect handles parallelism, fault tolerance, offset management, and schemas automatically.

**Key Features:**
- Distributed, scalable, fault-tolerant
- Pre-built connectors for popular systems
- Automatic offset management
- REST API for management
- Exactly-once delivery support
- Schema registry integration
- Transforms for lightweight data manipulation

**Connector Types:**
- **Source Connectors**: Database (JDBC, Debezium CDC), Files, Message queues, Cloud services (S3, GCS)
- **Sink Connectors**: Databases (JDBC), Elasticsearch, HDFS, S3, Cloud data warehouses

**Example Configuration (JDBC Source Connector):**
```json
{
  "name": "jdbc-source-connector",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
    "connection.url": "jdbc:postgresql://localhost:5432/mydb",
    "connection.user": "user",
    "connection.password": "password",
    "table.whitelist": "users,orders",
    "mode": "incrementing",
    "incrementing.column.name": "id",
    "topic.prefix": "db-",
    "poll.interval.ms": 1000,
    "tasks.max": 3
  }
}
```

**Example Configuration (Elasticsearch Sink Connector):**
```json
{
  "name": "elasticsearch-sink",
  "config": {
    "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "connection.url": "http://localhost:9200",
    "type.name": "_doc",
    "topics": "orders,users",
    "key.ignore": "false",
    "schema.ignore": "true",
    "tasks.max": 2
  }
}
```

**REST API Commands:**
```bash
# List connectors
curl -X GET http://localhost:8083/connectors

# Create connector
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connector-config.json

# Get connector status
curl -X GET http://localhost:8083/connectors/jdbc-source-connector/status

# Pause connector
curl -X PUT http://localhost:8083/connectors/jdbc-source-connector/pause

# Resume connector
curl -X PUT http://localhost:8083/connectors/jdbc-source-connector/resume

# Delete connector
curl -X DELETE http://localhost:8083/connectors/jdbc-source-connector

# Restart failed task
curl -X POST http://localhost:8083/connectors/jdbc-source-connector/tasks/0/restart
```

**Use Cases:**
- **Database CDC**: Stream database changes to Kafka (Debezium)
- **Data lake ingestion**: Stream Kafka data to S3, HDFS
- **Search indexing**: Keep Elasticsearch in sync with Kafka
- **Data warehouse loading**: Stream to BigQuery, Snowflake, Redshift
- **System integration**: Connect legacy systems to Kafka

---

### Schema Registry

**Description:** Schema Registry is a centralized repository for managing schemas (Avro, Protobuf, JSON Schema) used in Kafka messages. It provides versioning, compatibility checking, and schema evolution capabilities. When producers send messages, they register schemas with the registry and include only a schema ID in the message, reducing payload size. Consumers use the schema ID to retrieve the schema and deserialize messages. Schema Registry enforces compatibility rules (backward, forward, full) to prevent breaking changes and ensure smooth schema evolution over time.

**Key Features:**
- Centralized schema management
- Schema versioning and evolution
- Compatibility checking (backward, forward, full, none)
- Multiple format support (Avro, Protobuf, JSON)
- REST API for management
- Subject naming strategies
- Schema validation

**Compatibility Modes:**
- **Backward**: New schema can read old data (default)
- **Forward**: Old schema can read new data
- **Full**: Both backward and forward compatible
- **None**: No compatibility checking

**Example (Avro Producer with Schema Registry):**
```python
from confluent_kafka import avro
from confluent_kafka.avro import AvroProducer

value_schema = avro.loads('''
{
  "type": "record",
  "name": "User",
  "fields": [
    {"name": "id", "type": "int"},
    {"name": "name", "type": "string"},
    {"name": "email", "type": "string"}
  ]
}
''')

config = {
    'bootstrap.servers': 'localhost:9092',
    'schema.registry.url': 'http://localhost:8081'
}

producer = AvroProducer(config, default_value_schema=value_schema)

user = {
    'id': 123,
    'name': 'John Doe',
    'email': 'john@example.com'
}

producer.produce(topic='users', value=user)
producer.flush()
```

**REST API Commands:**
```bash
# List subjects
curl -X GET http://localhost:8081/subjects

# Get schema versions for subject
curl -X GET http://localhost:8081/subjects/users-value/versions

# Get specific schema version
curl -X GET http://localhost:8081/subjects/users-value/versions/1

# Register new schema
curl -X POST http://localhost:8081/subjects/users-value/versions \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{"schema": "{\"type\":\"record\",\"name\":\"User\",\"fields\":[{\"name\":\"id\",\"type\":\"int\"}]}"}'

# Check compatibility
curl -X POST http://localhost:8081/compatibility/subjects/users-value/versions/latest \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{"schema": "..."}'

# Update compatibility mode
curl -X PUT http://localhost:8081/config/users-value \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{"compatibility": "BACKWARD"}'

# Delete schema version
curl -X DELETE http://localhost:8081/subjects/users-value/versions/1
```

**Use Cases:**
- **Schema evolution**: Safely evolve message schemas over time
- **Contract enforcement**: Ensure producers and consumers agree on format
- **Documentation**: Central registry of all data formats
- **Payload optimization**: Store schema once, reference by ID
- **Multi-language support**: Shared schemas across different languages

---

### Exactly-Once Semantics (EOS)

**Description:** Exactly-Once Semantics ensures that messages are processed exactly once, even in the presence of failures - no duplicates, no data loss. Kafka achieves this through idempotent producers (prevent duplicates), transactional producers (atomic multi-partition writes), and transactional consumers (read committed messages only). EOS requires coordination between producer idempotence, transactions, and consumer isolation level. While it adds some latency overhead, it's critical for use cases requiring strict correctness guarantees like financial transactions or inventory management.

**How It Works:**
1. **Idempotent Producer**: Assigns sequence numbers to prevent duplicates
2. **Transactions**: Atomic writes across multiple partitions/topics
3. **Transactional Coordinator**: Manages transaction state
4. **Consumer Isolation**: Read only committed messages
5. **Offset Commits in Transactions**: Commit offsets atomically with output

**Producer Configuration:**
```python
config = {
    'bootstrap.servers': 'localhost:9092',
    'enable.idempotence': True,  # Required for EOS
    'transactional.id': 'my-transactional-id',  # Unique per producer instance
    'acks': 'all',
    'max.in.flight.requests.per.connection': 5
}
```

**Transactional Producer Example:**
```python
from confluent_kafka import Producer

producer = Producer(config)

# Initialize transactions
producer.init_transactions()

try:
    # Begin transaction
    producer.begin_transaction()

    # Send messages
    producer.produce('topic1', key='key1', value='value1')
    producer.produce('topic2', key='key2', value='value2')

    # Commit transaction (all or nothing)
    producer.commit_transaction()

except Exception as e:
    # Abort on error
    producer.abort_transaction()
    raise
```

**Consumer Configuration:**
```python
config = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'my-group',
    'isolation.level': 'read_committed',  # Read only committed messages
    'enable.auto.commit': False
}
```

**Streams EOS Example:**
```java
Properties props = new Properties();
props.put(StreamsConfig.APPLICATION_ID_CONFIG, "my-app");
props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
props.put(StreamsConfig.PROCESSING_GUARANTEE_CONFIG, StreamsConfig.EXACTLY_ONCE_V2);

KafkaStreams streams = new KafkaStreams(builder.build(), props);
```

**Use Cases:**
- **Financial transactions**: Payment processing, account transfers
- **Inventory management**: Stock updates, order processing
- **Data deduplication**: Ensure no duplicate records in downstream systems
- **Critical business logic**: Any operation that must happen exactly once
- **Audit trails**: Accurate event logging without duplicates

---

### Partitioning Strategies

**Description:** Partitioning determines how messages are distributed across partitions within a topic. The strategy affects parallelism, ordering guarantees, and load distribution. With a key, messages with the same key go to the same partition (maintaining order for that key). Without a key, messages are distributed round-robin. Custom partitioners can implement business-specific logic. Choosing the right strategy is crucial for performance, scaling, and maintaining semantic guarantees.

**Default Strategies:**
1. **Key-based**: Hash of key determines partition (same key → same partition)
2. **Round-robin**: No key, distribute evenly across partitions
3. **Custom**: Implement custom partitioning logic

**Key-Based Partitioning:**
```python
# Messages with same key go to same partition
producer.produce(
    topic='orders',
    key='user123',  # All messages for user123 go to same partition
    value='order_data'
)

# Partition = hash(key) % number_of_partitions
```

**Custom Partitioner (Java):**
```java
public class CustomPartitioner implements Partitioner {
    @Override
    public int partition(String topic, Object key, byte[] keyBytes,
                        Object value, byte[] valueBytes, Cluster cluster) {
        List<PartitionInfo> partitions = cluster.partitionsForTopic(topic);
        int numPartitions = partitions.size();

        // Custom logic: VIP users to partition 0
        if (((String) key).startsWith("vip_")) {
            return 0;
        }

        // Others distributed evenly
        return Math.abs(key.hashCode()) % (numPartitions - 1) + 1;
    }
}

// Configure producer to use custom partitioner
props.put("partitioner.class", "com.example.CustomPartitioner");
```

**Considerations:**
- **Hot partitions**: Uneven key distribution can overload partitions
- **Ordering**: Only guaranteed within a partition
- **Scalability**: More partitions = more parallelism
- **Rebalancing**: Adding partitions changes key-to-partition mapping

**Use Cases:**
- **User-based ordering**: Partition by user ID to maintain order per user
- **Geographic routing**: Route to partitions based on region
- **Priority queues**: Route high-priority messages to specific partitions
- **Load balancing**: Distribute evenly for maximum throughput
- **Co-location**: Keep related data in same partition for joins

---

### Replication and Fault Tolerance

**Description:** Kafka replicates partitions across multiple brokers for fault tolerance. Each partition has one leader and multiple followers (replicas). Producers write to the leader, and followers replicate data. If a leader fails, a follower is elected as the new leader. In-Sync Replicas (ISR) are replicas that are caught up with the leader. The replication factor determines how many copies exist. Kafka guarantees no data loss if at least one ISR remains. Replication provides high availability but increases storage requirements and network traffic.

**Key Concepts:**
- **Leader**: Handles all reads and writes for partition
- **Followers**: Replicate data from leader
- **ISR (In-Sync Replicas)**: Replicas caught up with leader
- **Replication Factor**: Number of replicas (including leader)
- **min.insync.replicas**: Minimum ISR required for writes
- **Unclean leader election**: Allow non-ISR to become leader (data loss risk)

**Configuration:**
```bash
# Create topic with replication factor 3
kafka-topics.sh --create \
  --topic critical-data \
  --partitions 6 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --bootstrap-server localhost:9092

# min.insync.replicas=2 means at least 2 replicas must ack write
# With acks=all, ensures data in at least 2 replicas before success
```

**Producer Acknowledgments (acks):**
```python
# acks=0: Fire and forget (no guarantee, fastest)
producer = Producer({'acks': 0})

# acks=1: Leader acknowledges (default, balanced)
producer = Producer({'acks': 1})

# acks=all: All ISRs acknowledge (strongest guarantee, slowest)
producer = Producer({'acks': 'all'})
```

**Monitoring Replication:**
```bash
# Check under-replicated partitions
kafka-topics.sh --describe \
  --under-replicated-partitions \
  --bootstrap-server localhost:9092

# Check unavailable partitions
kafka-topics.sh --describe \
  --unavailable-partitions \
  --bootstrap-server localhost:9092

# Describe topic (shows leader, replicas, ISR)
kafka-topics.sh --describe \
  --topic orders \
  --bootstrap-server localhost:9092
```

**Preferred Leader Election:**
```bash
# Trigger preferred leader election (rebalance leaders)
kafka-leader-election.sh --election-type preferred \
  --all-topic-partitions \
  --bootstrap-server localhost:9092
```

**Use Cases:**
- **High availability**: Service continues if brokers fail
- **Data durability**: No data loss with proper replication
- **Disaster recovery**: Replicate across data centers
- **Zero downtime upgrades**: Rolling restarts with replicas
- **Read scaling**: Followers can serve reads (in some configs)

---

## Performance Tuning

### Producer Optimization

**Description:** Producer performance depends on batching, compression, acknowledgment settings, and network configuration. Tuning these parameters balances throughput, latency, and reliability.

**Key Parameters:**
```python
config = {
    # Batching (trade latency for throughput)
    'batch.size': 16384,  # Batch size in bytes (default 16KB)
    'linger.ms': 10,  # Wait up to 10ms to fill batch

    # Compression (reduce network/storage)
    'compression.type': 'snappy',  # snappy, gzip, lz4, zstd

    # Buffering
    'buffer.memory': 33554432,  # Total buffer memory (32MB default)
    'max.block.ms': 60000,  # How long send/partitionsFor blocks

    # Network
    'send.buffer.bytes': 131072,  # TCP send buffer (128KB)
    'max.request.size': 1048576,  # Max request size (1MB)

    # Throughput vs latency
    'acks': 1,  # 0=fastest, 1=balanced, all=most reliable
    'max.in.flight.requests.per.connection': 5,  # Pipeline requests

    # Reliability
    'retries': 2147483647,  # Max int (infinite retries)
    'delivery.timeout.ms': 120000,  # Total time for retries
    'enable.idempotence': True  # Prevent duplicates
}
```

**Tuning Guidelines:**
- Increase `batch.size` and `linger.ms` for higher throughput
- Use `snappy` or `lz4` compression for good balance
- `acks=1` for most use cases, `acks=all` for critical data
- Enable idempotence for reliability without duplicates
- Monitor producer metrics (record-send-rate, batch-size-avg)

---

### Consumer Optimization

**Description:** Consumer performance depends on fetch size, parallelism, and commit strategy. Proper tuning maximizes throughput while maintaining delivery guarantees.

**Key Parameters:**
```python
config = {
    # Fetch configuration
    'fetch.min.bytes': 1,  # Min data to fetch (default 1 byte)
    'fetch.max.wait.ms': 500,  # Max wait for fetch.min.bytes
    'max.partition.fetch.bytes': 1048576,  # Max per partition (1MB)
    'max.poll.records': 500,  # Max records per poll

    # Session/heartbeat
    'session.timeout.ms': 10000,  # Consumer failure detection
    'heartbeat.interval.ms': 3000,  # Heartbeat frequency
    'max.poll.interval.ms': 300000,  # Max time between polls

    # Network
    'receive.buffer.bytes': 65536,  # TCP receive buffer (64KB)

    # Offset management
    'enable.auto.commit': False,  # Manual commit for control
    'auto.commit.interval.ms': 5000,  # If auto-commit enabled
    'auto.offset.reset': 'earliest'  # earliest, latest, none
}
```

**Parallelism:**
- Run multiple consumer instances (up to partition count)
- Each partition consumed by one consumer in group
- More partitions = more potential parallelism
- Monitor consumer lag: `kafka-consumer-groups.sh --describe`

**Tuning Guidelines:**
- Increase `max.poll.records` for higher throughput
- Increase `fetch.min.bytes` to reduce fetch requests
- Use manual commit for at-least-once or exactly-once
- Scale consumers based on lag and processing time
- Monitor consumer metrics (fetch-rate, records-lag-max)

---

## Monitoring and Operations

### Important Metrics

**Broker Metrics:**
- `UnderReplicatedPartitions`: Partitions not fully replicated
- `OfflinePartitionsCount`: Partitions without leader
- `ActiveControllerCount`: Should be 1 in cluster
- `RequestsPerSecond`: Request rate per broker
- `BytesInPerSecond` / `BytesOutPerSecond`: Network throughput
- `MessagesInPerSecond`: Message ingestion rate

**Producer Metrics:**
- `record-send-rate`: Records sent per second
- `record-error-rate`: Failed sends per second
- `request-latency-avg`: Average request latency
- `batch-size-avg`: Average batch size
- `compression-rate-avg`: Compression ratio

**Consumer Metrics:**
- `records-consumed-rate`: Records consumed per second
- `fetch-latency-avg`: Fetch request latency
- `records-lag-max`: Max lag across partitions
- `commit-latency-avg`: Commit latency

**Monitoring Commands:**
```bash
# Check cluster health
kafka-broker-api-versions.sh --bootstrap-server localhost:9092

# Check topic config
kafka-configs.sh --describe \
  --entity-type topics \
  --entity-name orders \
  --bootstrap-server localhost:9092

# Consumer group lag
kafka-consumer-groups.sh --describe \
  --group my-group \
  --bootstrap-server localhost:9092

# Log segment info
kafka-log-dirs.sh --describe \
  --bootstrap-server localhost:9092 \
  --topic-list orders
```

---

## Common Patterns

### Event Sourcing

Store all changes as events in Kafka, rebuild state by replaying events.

```python
# Store events
producer.produce('user-events',
    key='user123',
    value='{"event":"UserCreated","name":"John"}'
)
producer.produce('user-events',
    key='user123',
    value='{"event":"EmailUpdated","email":"john@new.com"}'
)

# Rebuild state by consuming from beginning
consumer.subscribe(['user-events'])
consumer.seek_to_beginning()
# Replay all events to rebuild current state
```

### Change Data Capture (CDC)

Capture database changes and stream to Kafka using Debezium.

```json
{
  "name": "postgres-cdc",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "localhost",
    "database.port": "5432",
    "database.user": "user",
    "database.password": "password",
    "database.dbname": "mydb",
    "database.server.name": "dbserver1",
    "table.include.list": "public.users,public.orders"
  }
}
```

### CQRS (Command Query Responsibility Segregation)

Separate read and write models using Kafka streams.

```java
// Write model: Commands to Kafka
producer.send(new ProducerRecord<>("commands", "CreateOrder", order));

// Read model: Materialize views from events
KTable<String, Order> orderTable = builder.table("orders");
orderTable.toStream().to("order-view");
```

### Dead Letter Queue

Handle failed messages by routing to DLQ topic.

```python
try:
    # Process message
    process(message)
    consumer.commit()
except Exception as e:
    # Send to DLQ
    producer.produce('orders-dlq',
        key=message.key(),
        value=message.value(),
        headers=[('error', str(e))]
    )
    consumer.commit()
```

---

## Best Practices

1. **Partitioning**: Choose partition count based on target throughput and consumer parallelism
2. **Replication**: Use replication factor 3 for production, min.insync.replicas=2
3. **Retention**: Set appropriate retention based on use case (default 7 days)
4. **Monitoring**: Monitor broker, producer, and consumer metrics continuously
5. **Schema Management**: Use Schema Registry for schema evolution
6. **Error Handling**: Implement retry logic and dead letter queues
7. **Security**: Enable SSL/TLS, SASL authentication, and ACLs
8. **Capacity Planning**: Plan for 2-3x expected peak load
9. **Testing**: Test failure scenarios (broker failures, network issues)
10. **Documentation**: Document topic schemas, retention policies, and owners
