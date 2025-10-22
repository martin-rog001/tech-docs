# AWS SQS (Simple Queue Service) Cheatsheet

## What is AWS SQS?

**Amazon SQS** is a fully managed message queuing service that enables you to decouple and scale microservices, distributed systems, and serverless applications. It eliminates the complexity of managing message-oriented middleware and provides reliable, highly scalable hosted queues for storing messages as they travel between applications or microservices. SQS offers two types of queues: Standard (best-effort ordering, at-least-once delivery, unlimited throughput) and FIFO (exactly-once processing, strict ordering, up to 3000 messages/second).

**Key Characteristics:**
- Fully managed, no infrastructure to maintain
- Unlimited throughput and queues (Standard queues)
- Pay-per-use pricing model
- At-least-once delivery (Standard) or exactly-once (FIFO)
- Message retention from 1 minute to 14 days
- Built-in redundancy and high availability
- Integration with AWS services (Lambda, EC2, ECS, etc.)
- Server-side encryption for security
- Dead Letter Queues for failed messages

---

## Queue Types

### Standard Queues

**Description:** Standard queues provide maximum throughput, best-effort ordering, and at-least-once delivery. They support nearly unlimited number of transactions per second and are ideal for high-throughput scenarios where occasional message duplication or out-of-order delivery is acceptable. Messages are distributed across multiple SQS servers for redundancy and high availability. Standard queues are perfect for decoupling application components, buffering requests, and handling asynchronous workflows where strict ordering isn't required.

**Key Features:**
- **Unlimited Throughput**: Nearly unlimited API calls per second
- **At-Least-Once Delivery**: Messages delivered at least once, duplicates possible
- **Best-Effort Ordering**: Messages generally delivered in order sent, but not guaranteed
- **High Availability**: Messages stored redundantly across multiple servers
- **Message Size**: Up to 256KB per message (extended to S3 for larger)
- **Retention**: 1 minute to 14 days (default 4 days)
- **Visibility Timeout**: 0 seconds to 12 hours (default 30 seconds)

**When to Use:**
- High throughput requirements (>3000 msgs/sec)
- Order doesn't matter or handled by application
- Duplicate handling in consumer logic
- Cost-sensitive applications (cheaper than FIFO)
- Distributed, loosely-coupled systems

**Example Usage:**
```bash
# Create Standard Queue (AWS CLI)
aws sqs create-queue \
  --queue-name my-standard-queue \
  --attributes '{
    "DelaySeconds": "0",
    "MessageRetentionPeriod": "345600",
    "VisibilityTimeout": "30"
  }'

# Send message
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/my-standard-queue \
  --message-body "Order processing request" \
  --message-attributes '{
    "OrderId": {"DataType": "String", "StringValue": "12345"},
    "Priority": {"DataType": "Number", "StringValue": "1"}
  }'

# Receive message
aws sqs receive-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/my-standard-queue \
  --max-number-of-messages 10 \
  --wait-time-seconds 20

# Delete message after processing
aws sqs delete-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/my-standard-queue \
  --receipt-handle "AQEBwJnKy..."
```

**Use Cases:**
- **Microservices communication**: Async messaging between services
- **Work queues**: Distribute tasks to worker processes
- **Event-driven architectures**: Trigger Lambda functions from events
- **Request buffering**: Buffer API requests during traffic spikes
- **Log aggregation**: Collect logs from multiple sources

---

### FIFO Queues

**Description:** FIFO (First-In-First-Out) queues provide strict message ordering and exactly-once processing. Messages are processed in the exact order they are sent, and each message is delivered once and remains available until a consumer processes and deletes it. FIFO queues support message groups to allow ordered processing of multiple independent workflows. Deduplication ensures that duplicate messages within a 5-minute window are rejected. FIFO queues are essential for applications where order and exactness matter, like financial transactions or inventory management.

**Key Features:**
- **Strict Ordering**: Messages processed in exact order sent
- **Exactly-Once Processing**: Each message delivered once, no duplicates
- **Message Groups**: Multiple ordered message groups in single queue
- **Deduplication**: Automatic deduplication within 5-minute window
- **Throughput**: Up to 3,000 messages/second (300 msg/sec with batching disabled)
- **High Throughput Mode**: Up to 30,000 messages/second (3,000 msg/sec per group)
- **Content-Based Deduplication**: Use message body hash as dedup ID
- **Queue Name**: Must end with .fifo suffix

**When to Use:**
- Strict ordering required
- No tolerance for duplicates
- Financial transactions
- Inventory management
- Command processing with dependencies
- State machine workflows

**Example Usage:**
```bash
# Create FIFO Queue (AWS CLI)
aws sqs create-queue \
  --queue-name my-queue.fifo \
  --attributes '{
    "FifoQueue": "true",
    "ContentBasedDeduplication": "true",
    "DelaySeconds": "0",
    "MessageRetentionPeriod": "345600"
  }'

# Send message with MessageGroupId
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/my-queue.fifo \
  --message-body "Process order 12345" \
  --message-group-id "order-processing" \
  --message-deduplication-id "order-12345-v1"

# Send batch
aws sqs send-message-batch \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/my-queue.fifo \
  --entries '[
    {
      "Id": "1",
      "MessageBody": "Order 1",
      "MessageGroupId": "group1",
      "MessageDeduplicationId": "msg1"
    },
    {
      "Id": "2",
      "MessageBody": "Order 2",
      "MessageGroupId": "group1",
      "MessageDeduplicationId": "msg2"
    }
  ]'

# Receive messages
aws sqs receive-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/my-queue.fifo \
  --max-number-of-messages 10 \
  --wait-time-seconds 20 \
  --attribute-names All \
  --message-attribute-names All
```

**Message Groups:**
```python
# Different message groups processed in parallel
# Messages within same group processed in order

import boto3
sqs = boto3.client('sqs')

# Group 1: User 123 orders
sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='Order A',
    MessageGroupId='user-123',
    MessageDeduplicationId='user-123-order-a'
)

# Group 2: User 456 orders (parallel processing)
sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='Order X',
    MessageGroupId='user-456',
    MessageDeduplicationId='user-456-order-x'
)

# Group 1 messages processed in order
# Group 2 messages processed in order
# Groups processed in parallel
```

**Use Cases:**
- **E-commerce order processing**: Process orders in exact sequence
- **Financial transactions**: Ensure correct transaction order
- **Inventory updates**: Apply inventory changes in order
- **Workflow orchestration**: Execute steps in specific order
- **Command execution**: Process commands sequentially per entity

---

## Core Concepts

### Message Attributes

**Description:** Message attributes are optional metadata attached to messages, providing additional information without modifying the message body. They consist of name, type, and value, and can be used for filtering, routing, or providing context. Attributes don't count toward the 256KB message size limit (up to 10 attributes allowed). They're useful for message filtering in SNS subscriptions, conditional processing, or tracking message metadata like timestamps, priorities, or correlation IDs.

**Supported Data Types:**
- `String`: Text values
- `Number`: Numeric values
- `Binary`: Binary data
- `String.Array`, `Number.Array`, `Binary.Array`: Arrays (custom types)

**Example Usage:**
```python
import boto3
import json

sqs = boto3.client('sqs')

response = sqs.send_message(
    QueueUrl=queue_url,
    MessageBody=json.dumps({'order_id': 12345, 'amount': 99.99}),
    MessageAttributes={
        'OrderType': {
            'StringValue': 'priority',
            'DataType': 'String'
        },
        'CustomerId': {
            'StringValue': '12345',
            'DataType': 'String'
        },
        'Priority': {
            'StringValue': '1',
            'DataType': 'Number'
        },
        'Timestamp': {
            'StringValue': '2024-01-15T10:30:00Z',
            'DataType': 'String'
        },
        'Region': {
            'StringValue': 'us-east-1',
            'DataType': 'String'
        }
    }
)

# Receive with attributes
response = sqs.receive_message(
    QueueUrl=queue_url,
    MessageAttributeNames=['All'],  # or ['OrderType', 'Priority']
    MaxNumberOfMessages=10
)

for message in response.get('Messages', []):
    attributes = message.get('MessageAttributes', {})
    order_type = attributes.get('OrderType', {}).get('StringValue')
    priority = attributes.get('Priority', {}).get('StringValue')
    print(f'Order Type: {order_type}, Priority: {priority}')
```

**Use Cases:**
- **Message filtering**: Route based on attributes in SNS
- **Priority handling**: Process high-priority messages first
- **Tracing/correlation**: Track requests across systems
- **Metadata**: Store timestamps, versions, sources
- **Conditional processing**: Handle messages differently based on attributes

---

### Visibility Timeout

**Description:** Visibility timeout is the period during which a message is invisible to other consumers after being received by one consumer. This prevents multiple consumers from processing the same message simultaneously. If the consumer fails to delete the message before the timeout expires, the message becomes visible again for reprocessing. The default is 30 seconds, configurable from 0 seconds to 12 hours. Consumers can extend the timeout if they need more processing time using ChangeMessageVisibility.

**How It Works:**
1. Consumer receives message from queue
2. Message becomes invisible to other consumers
3. Consumer processes message
4. If successful: Consumer deletes message
5. If failed: Message becomes visible again after timeout
6. Can extend timeout if more time needed

**Example Usage:**
```python
import boto3
import time

sqs = boto3.client('sqs')

# Receive message (default visibility timeout)
response = sqs.receive_message(
    QueueUrl=queue_url,
    MaxNumberOfMessages=1,
    VisibilityTimeout=60  # Override queue default
)

message = response['Messages'][0]
receipt_handle = message['ReceiptHandle']

try:
    # Start processing
    process_message(message)

    # Need more time? Extend visibility timeout
    sqs.change_message_visibility(
        QueueUrl=queue_url,
        ReceiptHandle=receipt_handle,
        VisibilityTimeout=120  # Extend by another 60 seconds
    )

    # Continue processing
    continue_processing(message)

    # Success - delete message
    sqs.delete_message(
        QueueUrl=queue_url,
        ReceiptHandle=receipt_handle
    )

except Exception as e:
    # On error, message becomes visible again after timeout
    print(f'Processing failed: {e}')
    # Optionally make visible immediately
    sqs.change_message_visibility(
        QueueUrl=queue_url,
        ReceiptHandle=receipt_handle,
        VisibilityTimeout=0
    )
```

**Batch Visibility Update:**
```python
# Change visibility for multiple messages
sqs.change_message_visibility_batch(
    QueueUrl=queue_url,
    Entries=[
        {
            'Id': '1',
            'ReceiptHandle': receipt_handle_1,
            'VisibilityTimeout': 120
        },
        {
            'Id': '2',
            'ReceiptHandle': receipt_handle_2,
            'VisibilityTimeout': 120
        }
    ]
)
```

**Best Practices:**
- Set timeout longer than expected processing time
- Extend timeout for long-running tasks
- Use shorter timeouts for quick retries
- Monitor visibility timeout expirations
- Make visible immediately on unrecoverable errors

**Use Cases:**
- **Long processing tasks**: Extend timeout for complex operations
- **Failure handling**: Auto-retry after timeout
- **Crash recovery**: Message reappears if consumer crashes
- **Load management**: Prevent overwhelming slow consumers
- **Idempotent processing**: Handle duplicate deliveries gracefully

---

### Dead Letter Queues (DLQ)

**Description:** Dead Letter Queues are special queues used to isolate messages that can't be processed successfully after a specified number of attempts. When a message's receive count exceeds the maxReceiveCount threshold (1-1000), SQS automatically moves it to the configured DLQ. This prevents poison messages from blocking queue processing and allows for separate analysis and handling of failed messages. DLQs are essential for robust error handling, debugging, and maintaining system reliability.

**Key Features:**
- Automatic message redrive after max receives
- Separate queue for failed messages
- Same type as source (Standard DLQ for Standard, FIFO for FIFO)
- Configurable maxReceiveCount (1-1000)
- Can be monitored and alarmed on
- Messages can be redriven back to source queue

**Configuration:**
```python
import boto3
import json

sqs = boto3.client('sqs')

# Create DLQ
dlq_response = sqs.create_queue(
    QueueName='my-queue-dlq',
    Attributes={
        'MessageRetentionPeriod': '1209600'  # 14 days
    }
)
dlq_url = dlq_response['QueueUrl']

# Get DLQ ARN
dlq_attributes = sqs.get_queue_attributes(
    QueueUrl=dlq_url,
    AttributeNames=['QueueArn']
)
dlq_arn = dlq_attributes['Attributes']['QueueArn']

# Configure main queue with DLQ
sqs.set_queue_attributes(
    QueueUrl=main_queue_url,
    Attributes={
        'RedrivePolicy': json.dumps({
            'deadLetterTargetArn': dlq_arn,
            'maxReceiveCount': '3'  # Move to DLQ after 3 failed attempts
        })
    }
)
```

**Monitoring DLQ:**
```python
# Check DLQ depth
response = sqs.get_queue_attributes(
    QueueUrl=dlq_url,
    AttributeNames=['ApproximateNumberOfMessages']
)
dlq_count = int(response['Attributes']['ApproximateNumberOfMessages'])
print(f'Messages in DLQ: {dlq_count}')

# Receive from DLQ for analysis
response = sqs.receive_message(
    QueueUrl=dlq_url,
    MaxNumberOfMessages=10,
    MessageAttributeNames=['All'],
    AttributeNames=['All']
)

for message in response.get('Messages', []):
    # Analyze failed message
    print(f'Failed message: {message["Body"]}')
    receive_count = message['Attributes']['ApproximateReceiveCount']
    print(f'Receive count: {receive_count}')
```

**Redrive Messages:**
```python
# Redrive messages from DLQ back to source queue
sqs.start_message_move_task(
    SourceArn=dlq_arn,
    DestinationArn=main_queue_arn,
    MaxNumberOfMessagesPerSecond=10  # Rate limit
)

# Check redrive status
response = sqs.list_message_move_tasks(SourceArn=dlq_arn)
```

**CloudWatch Alarms:**
```bash
# Create alarm for DLQ messages
aws cloudwatch put-metric-alarm \
  --alarm-name dlq-messages-alarm \
  --alarm-description "Alert when messages in DLQ" \
  --metric-name ApproximateNumberOfMessagesVisible \
  --namespace AWS/SQS \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=QueueName,Value=my-queue-dlq \
  --evaluation-periods 1
```

**Use Cases:**
- **Poison message isolation**: Prevent bad messages from blocking queue
- **Error analysis**: Debug why messages failed
- **Manual review**: Human review of problematic messages
- **Retry logic**: Reprocess after fixing issues
- **Monitoring**: Alert on system problems

---

### Long Polling

**Description:** Long polling is a technique to reduce the number of empty responses by allowing SQS to wait for messages to arrive if the queue is empty. Instead of returning immediately with no messages, SQS waits up to 20 seconds for messages to become available. This reduces costs (fewer API calls), decreases latency (messages received faster), and is more efficient than short polling. Long polling can be enabled at the queue level (ReceiveMessageWaitTimeSeconds) or per-request (WaitTimeSeconds parameter).

**Short Polling vs Long Polling:**
- **Short Polling (default)**: Returns immediately, even if no messages (frequent empty responses)
- **Long Polling**: Waits up to 20 seconds for messages, reduces empty responses by up to 90%

**Benefits:**
- Reduced cost (fewer API calls)
- Lower latency (faster message delivery)
- More efficient use of connections
- Better for low-traffic queues

**Configuration:**
```bash
# Enable long polling at queue level
aws sqs set-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/my-queue \
  --attributes ReceiveMessageWaitTimeSeconds=20

# Or create queue with long polling
aws sqs create-queue \
  --queue-name my-queue \
  --attributes ReceiveMessageWaitTimeSeconds=20
```

**Example Usage:**
```python
import boto3

sqs = boto3.client('sqs')

# Long polling per request (overrides queue setting)
response = sqs.receive_message(
    QueueUrl=queue_url,
    MaxNumberOfMessages=10,
    WaitTimeSeconds=20,  # Long poll for up to 20 seconds
    MessageAttributeNames=['All']
)

messages = response.get('Messages', [])
if messages:
    for message in messages:
        # Process message
        process(message)
        # Delete after processing
        sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message['ReceiptHandle']
        )
else:
    print('No messages available')
```

**Continuous Polling:**
```python
def poll_queue_continuously():
    while True:
        response = sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=20,  # Long poll
            MessageAttributeNames=['All']
        )

        messages = response.get('Messages', [])
        if not messages:
            continue  # No messages, loop continues immediately

        for message in messages:
            try:
                process_message(message)
                sqs.delete_message(
                    QueueUrl=queue_url,
                    ReceiptHandle=message['ReceiptHandle']
                )
            except Exception as e:
                print(f'Error processing message: {e}')
```

**Use Cases:**
- **Cost optimization**: Reduce API call costs
- **Real-time processing**: Lower latency for message delivery
- **Worker processes**: Efficient polling for background jobs
- **Low-traffic queues**: Avoid frequent empty polls
- **Event-driven architectures**: React quickly to events

---

## Advanced Features

### Delay Queues

**Description:** Delay queues postpone the delivery of new messages to consumers for a specified time period (0 to 15 minutes). When a message is sent to a delay queue, it remains invisible to consumers during the delay period. This is useful for implementing delayed jobs, scheduled tasks, or cooling-off periods. Delay can be set at the queue level (applies to all messages) or per-message level (overrides queue default). Standard and FIFO queues both support delays.

**Configuration:**
```bash
# Create queue with default delay
aws sqs create-queue \
  --queue-name delayed-queue \
  --attributes DelaySeconds=300  # 5 minute default delay

# Set delay on existing queue
aws sqs set-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/delayed-queue \
  --attributes DelaySeconds=600  # 10 minutes
```

**Per-Message Delay:**
```python
import boto3

sqs = boto3.client('sqs')

# Send message with specific delay (overrides queue default)
sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='Process this in 5 minutes',
    DelaySeconds=300  # 5 minutes
)

# Different messages with different delays
sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='Immediate processing',
    DelaySeconds=0
)

sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='Process in 15 minutes',
    DelaySeconds=900  # Max 15 minutes
)
```

**Use Cases:**
- **Scheduled tasks**: Execute jobs at future time
- **Retry with backoff**: Delay retries exponentially
- **Cooling-off periods**: Delay after specific events
- **Batch window**: Wait for more messages before processing
- **Rate limiting**: Slow down processing rate

**Example - Exponential Backoff:**
```python
def send_with_retry(message, attempt=0):
    max_attempts = 5
    base_delay = 60  # 1 minute

    if attempt >= max_attempts:
        # Send to DLQ or log
        return

    try:
        process(message)
    except Exception as e:
        # Exponential backoff: 1min, 2min, 4min, 8min, 15min (max)
        delay = min(base_delay * (2 ** attempt), 900)

        sqs.send_message(
            QueueUrl=retry_queue_url,
            MessageBody=message,
            DelaySeconds=delay,
            MessageAttributes={
                'RetryAttempt': {
                    'StringValue': str(attempt + 1),
                    'DataType': 'Number'
                }
            }
        )
```

---

### Message Timers (FIFO Deduplication)

**Description:** FIFO queues provide automatic message deduplication within a 5-minute window to prevent duplicate processing. Deduplication is based on a deduplication ID - if two messages with the same ID arrive within 5 minutes, the second is rejected. You can explicitly provide a deduplication ID or enable content-based deduplication (uses SHA-256 hash of message body). This ensures exactly-once processing without application-level deduplication logic.

**Deduplication Methods:**

**1. Explicit Deduplication ID:**
```python
import boto3
import uuid

sqs = boto3.client('sqs')

# Send with explicit deduplication ID
sqs.send_message(
    QueueUrl=fifo_queue_url,
    MessageBody='Order 12345',
    MessageGroupId='orders',
    MessageDeduplicationId='order-12345-v1'  # Explicit ID
)

# Duplicate within 5 minutes - rejected
sqs.send_message(
    QueueUrl=fifo_queue_url,
    MessageBody='Order 12345',
    MessageGroupId='orders',
    MessageDeduplicationId='order-12345-v1'  # Same ID - rejected
)

# Different ID - accepted
sqs.send_message(
    QueueUrl=fifo_queue_url,
    MessageBody='Order 12345',
    MessageGroupId='orders',
    MessageDeduplicationId='order-12345-v2'  # Different ID - accepted
)
```

**2. Content-Based Deduplication:**
```bash
# Enable content-based deduplication
aws sqs set-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/123456789/my-queue.fifo \
  --attributes ContentBasedDeduplication=true
```

```python
# No need to provide deduplication ID
# SQS uses SHA-256 hash of message body
sqs.send_message(
    QueueUrl=fifo_queue_url,
    MessageBody='{"order_id": 12345, "amount": 99.99}',
    MessageGroupId='orders'
    # No MessageDeduplicationId needed
)

# Exact same body within 5 minutes - rejected
# Different body - accepted
```

**Use Cases:**
- **Prevent duplicates**: Avoid processing same order twice
- **Idempotency**: Ensure operations execute exactly once
- **Retry safety**: Safe to retry without creating duplicates
- **Event deduplication**: Filter duplicate events from multiple sources

---

### Batch Operations

**Description:** Batch operations allow you to send, receive, or delete up to 10 messages in a single API call, reducing costs and improving throughput. Batching amortizes the overhead of API calls across multiple messages. Each message in a batch has an ID for tracking individual success/failure. Failed messages in a batch don't affect successful ones. Batching is especially important for high-throughput applications to optimize performance and reduce costs.

**Send Batch:**
```python
import boto3
import json

sqs = boto3.client('sqs')

# Send up to 10 messages in one call
response = sqs.send_message_batch(
    QueueUrl=queue_url,
    Entries=[
        {
            'Id': '1',
            'MessageBody': json.dumps({'order_id': 1001}),
            'MessageAttributes': {
                'Priority': {'StringValue': '1', 'DataType': 'Number'}
            }
        },
        {
            'Id': '2',
            'MessageBody': json.dumps({'order_id': 1002}),
            'DelaySeconds': 60
        },
        {
            'Id': '3',
            'MessageBody': json.dumps({'order_id': 1003})
        }
    ]
)

# Check results
for success in response.get('Successful', []):
    print(f"Message {success['Id']} sent: {success['MessageId']}")

for failure in response.get('Failed', []):
    print(f"Message {failure['Id']} failed: {failure['Message']}")
```

**Receive Batch:**
```python
# Receive up to 10 messages
response = sqs.receive_message(
    QueueUrl=queue_url,
    MaxNumberOfMessages=10,  # Max 10
    WaitTimeSeconds=20,
    MessageAttributeNames=['All']
)

messages = response.get('Messages', [])
print(f'Received {len(messages)} messages')

for message in messages:
    process(message)
```

**Delete Batch:**
```python
# Delete multiple messages at once
delete_entries = [
    {
        'Id': str(i),
        'ReceiptHandle': message['ReceiptHandle']
    }
    for i, message in enumerate(messages)
]

response = sqs.delete_message_batch(
    QueueUrl=queue_url,
    Entries=delete_entries
)

print(f"Deleted: {len(response.get('Successful', []))}")
print(f"Failed: {len(response.get('Failed', []))}")
```

**Best Practices:**
- Batch up to 10 messages per call (max allowed)
- Handle partial failures (some succeed, some fail)
- Retry failed messages individually or in smaller batches
- Monitor batch size and success rates
- Use batching for high-throughput scenarios

**Performance Comparison:**
- Individual sends: 10 messages = 10 API calls
- Batch sends: 10 messages = 1 API call (10x reduction)
- Cost savings: ~90% reduction in API costs
- Latency: Slightly higher per message, but better throughput

---

### Server-Side Encryption (SSE)

**Description:** SQS supports server-side encryption to protect message data at rest using AWS KMS (Key Management Service). When enabled, SQS encrypts messages before storing them and decrypts when messages are received. You can use AWS managed keys (free) or customer managed keys (more control, auditing). Encryption is transparent to applications - no code changes needed. Encryption adds minimal latency and doesn't affect throughput limits.

**Encryption Options:**
- **SSE-SQS**: AWS managed keys (default, free)
- **SSE-KMS**: Customer managed KMS keys (more control, costs apply)

**Configuration:**
```bash
# Enable SSE with AWS managed key
aws sqs create-queue \
  --queue-name encrypted-queue \
  --attributes SqsManagedSseEnabled=true

# Enable SSE with customer managed KMS key
aws sqs create-queue \
  --queue-name encrypted-queue \
  --attributes KmsMasterKeyId=alias/my-key,KmsDataKeyReusePeriodSeconds=300
```

```python
import boto3

sqs = boto3.client('sqs')

# Create queue with encryption
response = sqs.create_queue(
    QueueName='secure-queue',
    Attributes={
        'SqsManagedSseEnabled': 'true'
        # Or use KMS: 'KmsMasterKeyId': 'alias/my-kms-key'
    }
)

# Enable encryption on existing queue
sqs.set_queue_attributes(
    QueueUrl=queue_url,
    Attributes={
        'KmsMasterKeyId': 'arn:aws:kms:us-east-1:123456789:key/12345678-1234-1234-1234-123456789012',
        'KmsDataKeyReusePeriodSeconds': '300'  # 5 minutes (60-86400)
    }
)
```

**KMS Key Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sqs.amazonaws.com"
      },
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "*"
    }
  ]
}
```

**Use Cases:**
- **Compliance**: Meet regulatory requirements (HIPAA, PCI-DSS)
- **Sensitive data**: Protect PII, financial data, credentials
- **Security posture**: Defense in depth strategy
- **Audit requirements**: Track key usage with CloudTrail
- **Multi-tenancy**: Separate keys per tenant

---

## Integration with AWS Services

### Lambda Integration

**Description:** SQS integrates seamlessly with AWS Lambda for event-driven, serverless architectures. Lambda can poll SQS queues automatically and invoke functions with message batches. Lambda handles polling, scaling, error handling, and message deletion automatically. This eliminates the need for managing worker infrastructure and provides automatic scaling based on queue depth.

**Key Features:**
- Automatic polling and invocation
- Batch size: 1-10 messages per invocation (Standard), 1-10 per batch (FIFO)
- Concurrent execution scaling
- Automatic retry and DLQ integration
- No infrastructure management
- Pay-per-invocation pricing

**Configuration:**
```python
import boto3

lambda_client = boto3.client('lambda')

# Create event source mapping
response = lambda_client.create_event_source_mapping(
    EventSourceArn='arn:aws:sqs:us-east-1:123456789:my-queue',
    FunctionName='my-processor-function',
    Enabled=True,
    BatchSize=10,  # Process up to 10 messages per invocation
    MaximumBatchingWindowInSeconds=5,  # Wait up to 5s to fill batch
    FunctionResponseTypes=['ReportBatchItemFailures']  # Partial batch support
)
```

**Lambda Function Example:**
```python
import json

def lambda_handler(event, context):
    # Event contains batch of SQS messages
    for record in event['Records']:
        message_id = record['messageId']
        body = json.loads(record['body'])
        attributes = record.get('messageAttributes', {})

        try:
            # Process message
            process_order(body)
            print(f'Processed message {message_id}')

        except Exception as e:
            print(f'Failed to process {message_id}: {e}')
            # Return failed message IDs for retry
            return {
                'batchItemFailures': [
                    {'itemIdentifier': message_id}
                ]
            }

    return {'statusCode': 200}
```

**CloudFormation/SAM:**
```yaml
Resources:
  MyQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: my-queue

  ProcessorFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: app.handler
      Runtime: python3.11
      Events:
        SQSEvent:
          Type: SQS
          Properties:
            Queue: !GetAtt MyQueue.Arn
            BatchSize: 10
            MaximumBatchingWindowInSeconds: 5
```

**Use Cases:**
- **Async processing**: Process orders, emails, notifications
- **Event handling**: React to system events
- **Data transformation**: ETL pipelines
- **API decoupling**: Async API responses
- **Scheduled tasks**: Trigger periodic jobs

---

### SNS to SQS Fanout

**Description:** SNS (Simple Notification Service) to SQS fanout pattern allows one message to be delivered to multiple SQS queues simultaneously. An SNS topic receives messages and fans them out to subscribed SQS queues. Each queue receives a copy of the message, enabling parallel processing by different consumers. This decouples producers from consumers and enables flexible message routing based on message attributes.

**Architecture:**
```
Producer → SNS Topic → Queue 1 (Email Processor)
                    → Queue 2 (SMS Processor)
                    → Queue 3 (Push Notification)
                    → Queue 4 (Analytics)
```

**Configuration:**
```python
import boto3
import json

sns = boto3.client('sns')
sqs = boto3.client('sqs')

# Create SNS topic
topic_response = sns.create_topic(Name='order-events')
topic_arn = topic_response['TopicArn']

# Create queues
email_queue = sqs.create_queue(QueueName='email-processor')['QueueUrl']
sms_queue = sqs.create_queue(QueueName='sms-processor')['QueueUrl']

# Get queue ARNs
email_arn = sqs.get_queue_attributes(
    QueueUrl=email_queue,
    AttributeNames=['QueueArn']
)['Attributes']['QueueArn']

# Subscribe queues to topic
sns.subscribe(
    TopicArn=topic_arn,
    Protocol='sqs',
    Endpoint=email_arn
)

# Allow SNS to send to SQS (queue policy)
policy = {
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {"Service": "sns.amazonaws.com"},
        "Action": "sqs:SendMessage",
        "Resource": email_arn,
        "Condition": {
            "ArnEquals": {"aws:SourceArn": topic_arn}
        }
    }]
}

sqs.set_queue_attributes(
    QueueUrl=email_queue,
    Attributes={'Policy': json.dumps(policy)}
)

# Publish to SNS (fans out to all queues)
sns.publish(
    TopicArn=topic_arn,
    Message=json.dumps({'order_id': 12345, 'status': 'completed'}),
    MessageAttributes={
        'event_type': {'DataType': 'String', 'StringValue': 'order_completed'}
    }
)
```

**Message Filtering:**
```python
# Subscribe with filter policy (selective fanout)
sns.subscribe(
    TopicArn=topic_arn,
    Protocol='sqs',
    Endpoint=high_priority_queue_arn,
    Attributes={
        'FilterPolicy': json.dumps({
            'priority': ['high', 'critical'],
            'event_type': ['order_completed']
        })
    }
)
```

**Use Cases:**
- **Multi-channel notifications**: Email, SMS, push notifications
- **Parallel processing**: Multiple services process same event
- **Event broadcasting**: Notify multiple microservices
- **Analytics**: Route events to analytics and processing pipelines
- **Backup/archival**: Send to archive while processing

---

## Best Practices

### Message Processing Patterns

**At-Least-Once Processing:**
```python
# Standard queue pattern - idempotent processing required
def process_message(message):
    message_id = message['MessageId']
    body = json.loads(message['Body'])

    # Check if already processed (idempotency)
    if already_processed(message_id):
        print(f'Skipping duplicate {message_id}')
        return True

    try:
        # Process
        result = perform_operation(body)

        # Record as processed
        mark_processed(message_id, result)

        return True

    except Exception as e:
        print(f'Error processing {message_id}: {e}')
        return False

# Receive and process
response = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=10)
for message in response.get('Messages', []):
    if process_message(message):
        sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message['ReceiptHandle']
        )
```

**Exactly-Once Processing (FIFO):**
```python
# FIFO queue - guaranteed exactly once
def process_fifo_message(message):
    # No duplicate check needed - FIFO guarantees exactly once
    body = json.loads(message['Body'])

    try:
        perform_operation(body)
        return True
    except Exception as e:
        print(f'Error: {e}')
        return False

# Process FIFO messages
response = sqs.receive_message(
    QueueUrl=fifo_queue_url,
    MaxNumberOfMessages=10,
    WaitTimeSeconds=20
)

for message in response.get('Messages', []):
    if process_fifo_message(message):
        sqs.delete_message(
            QueueUrl=fifo_queue_url,
            ReceiptHandle=message['ReceiptHandle']
        )
```

---

### Error Handling

**Retry Strategy:**
```python
def process_with_retry(message, max_retries=3):
    receive_count = int(message['Attributes']['ApproximateReceiveCount'])

    if receive_count >= max_retries:
        # Max retries exceeded - handle specially
        send_to_dlq(message)
        return False

    try:
        process(message)
        return True

    except RetryableError as e:
        # Transient error - let message return to queue
        print(f'Retryable error (attempt {receive_count}): {e}')
        return False

    except FatalError as e:
        # Permanent error - send directly to DLQ
        print(f'Fatal error: {e}')
        send_to_dlq(message)
        sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message['ReceiptHandle']
        )
        return False
```

---

### Monitoring and Alarms

**Key Metrics:**
```bash
# ApproximateNumberOfMessagesVisible - Messages available
# ApproximateNumberOfMessagesNotVisible - Messages in flight
# ApproximateNumberOfMessagesDelayed - Messages delayed
# NumberOfMessagesSent - Messages sent rate
# NumberOfMessagesReceived - Messages received rate
# NumberOfMessagesDeleted - Messages deleted rate
# ApproximateAgeOfOldestMessage - Age of oldest message

# Create CloudWatch alarm
aws cloudwatch put-metric-alarm \
  --alarm-name queue-depth-alarm \
  --alarm-description "Alert on high queue depth" \
  --metric-name ApproximateNumberOfMessagesVisible \
  --namespace AWS/SQS \
  --statistic Average \
  --period 300 \
  --threshold 1000 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=QueueName,Value=my-queue
```

---

### Cost Optimization

**Tips:**
1. Use long polling to reduce empty receives
2. Batch operations (send/receive/delete)
3. Use Standard queues when possible (cheaper than FIFO)
4. Set appropriate message retention
5. Delete messages after processing
6. Monitor and optimize queue depth
7. Use CloudWatch metrics to identify waste
8. Consider Lambda for serverless processing
9. Right-size visibility timeouts
10. Use message attributes instead of large bodies

---

## Common Use Cases

1. **Microservices Decoupling**: Async communication between services
2. **Load Leveling**: Buffer requests during traffic spikes
3. **Background Job Processing**: Offload long-running tasks
4. **Event-Driven Architectures**: React to system events
5. **Order Processing**: E-commerce order pipelines
6. **Image/Video Processing**: Async media processing
7. **Log Aggregation**: Collect logs from multiple sources
8. **Notification Systems**: Send emails, SMS, push notifications
9. **Data Pipeline**: ETL and data transformation workflows
10. **Workflow Orchestration**: Multi-step business processes
