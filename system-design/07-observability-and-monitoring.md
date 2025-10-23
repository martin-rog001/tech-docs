# Observability & Monitoring - System Design Cheatsheet

## Overview

**Observability** is the ability to understand the internal state of a system by examining its external outputs. **Monitoring** is the practice of collecting, analyzing, and acting on telemetry data.

### The Three Pillars of Observability

1. **Metrics**: Numeric measurements over time (CPU, latency, request rate)
2. **Logs**: Discrete events with contextual information
3. **Traces**: Request flow across distributed systems

### Why Observability Matters

- Detect issues before customers notice
- Diagnose root causes quickly (reduce MTTR)
- Validate SLOs and error budgets
- Inform capacity planning
- Enable data-driven decisions

---

## 1. Metrics

### Types of Metrics

#### RED Metrics (for Request-driven Services)

- **Rate**: Requests per second
- **Errors**: Failed requests per second
- **Duration**: Latency/response time

```python
# Prometheus metrics in Flask
from prometheus_client import Counter, Histogram, generate_latest
from flask import Flask, Response
import time

app = Flask(__name__)

# RED metrics
request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

request_errors = Counter(
    'http_requests_errors_total',
    'Total HTTP errors',
    ['method', 'endpoint', 'error_type']
)

@app.route('/api/users')
def get_users():
    start_time = time.time()
    try:
        users = fetch_users_from_db()
        request_count.labels('GET', '/api/users', '200').inc()
        return users, 200
    except Exception as e:
        request_errors.labels('GET', '/api/users', type(e).__name__).inc()
        request_count.labels('GET', '/api/users', '500').inc()
        return {'error': str(e)}, 500
    finally:
        duration = time.time() - start_time
        request_duration.labels('GET', '/api/users').observe(duration)

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype='text/plain')
```

#### USE Metrics (for Resource-driven Services)

- **Utilization**: Percentage of time resource is busy
- **Saturation**: Amount of queued work
- **Errors**: Count of error events

```yaml
# CloudWatch Dashboard - USE Metrics
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization", {"stat": "Average"}],
          [".", "NetworkIn", {"stat": "Sum"}],
          [".", "NetworkOut", {"stat": "Sum"}]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "EC2 Utilization"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "TargetResponseTime", {"stat": "Average"}],
          [".", "RequestCount", {"stat": "Sum"}],
          [".", "HTTPCode_Target_5XX_Count", {"stat": "Sum"}]
        ],
        "period": 60,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ALB Metrics"
      }
    }
  ]
}
```

#### Custom Business Metrics

```python
# Track business KPIs
from prometheus_client import Counter, Gauge

# Revenue metrics
orders_total = Counter('orders_total', 'Total orders', ['product_type'])
revenue_total = Counter('revenue_dollars_total', 'Total revenue in USD')
cart_abandonment = Counter('cart_abandonment_total', 'Abandoned carts')

# User engagement
active_users = Gauge('active_users', 'Currently active users')
signup_funnel = Counter('signup_funnel', 'Signup funnel', ['step'])

def complete_purchase(order):
    orders_total.labels(order.product_type).inc()
    revenue_total.inc(order.amount_usd)

def track_signup_step(step_name):
    signup_funnel.labels(step_name).inc()
```

### Metric Aggregation

#### Percentiles vs Averages

```python
# Why percentiles matter
requests = [10, 12, 11, 13, 15, 14, 11, 500]  # ms

average = sum(requests) / len(requests)  # 73ms - misleading!

# Percentiles give better picture
import numpy as np
p50 = np.percentile(requests, 50)  # 12.5ms (median)
p95 = np.percentile(requests, 95)  # 320ms
p99 = np.percentile(requests, 99)  # 476ms

# In production: track p50, p95, p99
request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    buckets=(0.01, 0.05, 0.1, 0.5, 1.0, 2.5, 5.0, 10.0)
)
```

### AWS CloudWatch Metrics

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

# Put custom metrics
cloudwatch.put_metric_data(
    Namespace='MyApp',
    MetricData=[
        {
            'MetricName': 'OrdersCompleted',
            'Value': 1,
            'Unit': 'Count',
            'Timestamp': datetime.now(),
            'Dimensions': [
                {'Name': 'Environment', 'Value': 'production'},
                {'Name': 'Region', 'Value': 'us-east-1'}
            ]
        },
        {
            'MetricName': 'OrderValue',
            'Value': 99.99,
            'Unit': 'None',
            'Timestamp': datetime.now(),
            'StorageResolution': 1  # High-resolution (1-second)
        }
    ]
)

# Get metrics with statistics
response = cloudwatch.get_metric_statistics(
    Namespace='AWS/ApplicationELB',
    MetricName='TargetResponseTime',
    Dimensions=[
        {'Name': 'LoadBalancer', 'Value': 'app/my-alb/1234567890'}
    ],
    StartTime=datetime.now() - timedelta(hours=1),
    EndTime=datetime.now(),
    Period=60,
    Statistics=['Average', 'Maximum', 'p99'],
    ExtendedStatistics=['p95', 'p99']
)
```

---

## 2. Logs

### Structured Logging

Always use structured logs (JSON) for easy parsing.

```python
import json
import logging
from datetime import datetime

class StructuredLogger:
    def __init__(self, service_name):
        self.service_name = service_name
        self.logger = logging.getLogger(service_name)

    def log(self, level, message, **kwargs):
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'service': self.service_name,
            'level': level,
            'message': message,
            **kwargs
        }
        self.logger.log(getattr(logging, level), json.dumps(log_entry))

logger = StructuredLogger('order-service')

# Usage
logger.log('INFO', 'Order created',
    order_id='ord_123',
    user_id='usr_456',
    amount=99.99,
    duration_ms=250
)

# Output:
# {
#   "timestamp": "2025-10-23T10:30:00.123Z",
#   "service": "order-service",
#   "level": "INFO",
#   "message": "Order created",
#   "order_id": "ord_123",
#   "user_id": "usr_456",
#   "amount": 99.99,
#   "duration_ms": 250
# }
```

### Log Levels

```python
# Use appropriate log levels
logger.debug('Cache key generated', key='user:123')  # Development only
logger.info('User logged in', user_id='123')         # Normal operation
logger.warning('Rate limit approaching', current=950, limit=1000)
logger.error('Database connection failed', error=str(e), retry_count=3)
logger.critical('Service unrecoverable', reason='All DB replicas down')
```

### Correlation IDs

Track requests across services.

```python
from flask import Flask, request, g
import uuid

app = Flask(__name__)

@app.before_request
def set_correlation_id():
    # Get from header or generate new
    g.correlation_id = request.headers.get('X-Correlation-ID', str(uuid.uuid4()))

@app.after_request
def add_correlation_id(response):
    response.headers['X-Correlation-ID'] = g.correlation_id
    return response

def log_with_context(message, **kwargs):
    logger.log('INFO', message,
        correlation_id=g.get('correlation_id'),
        request_id=g.get('request_id'),
        user_id=g.get('user_id'),
        **kwargs
    )

@app.route('/api/orders')
def create_order():
    log_with_context('Creating order', cart_items=3)
    # ... create order ...

    # Pass correlation_id to downstream services
    response = requests.post('http://payment-service/charge',
        headers={'X-Correlation-ID': g.correlation_id},
        json={'amount': 100}
    )

    log_with_context('Order created', order_id='ord_123')
    return {'order_id': 'ord_123'}
```

### AWS CloudWatch Logs

```python
import boto3

logs = boto3.client('logs')

# Create log group and stream
logs.create_log_group(logGroupName='/aws/lambda/my-function')
logs.create_log_stream(
    logGroupName='/aws/lambda/my-function',
    logStreamName='2025/10/23/instance-i-1234567890'
)

# Put log events
logs.put_log_events(
    logGroupName='/aws/lambda/my-function',
    logStreamName='2025/10/23/instance-i-1234567890',
    logEvents=[
        {
            'timestamp': int(datetime.now().timestamp() * 1000),
            'message': json.dumps({
                'level': 'ERROR',
                'message': 'Payment failed',
                'order_id': 'ord_123',
                'error': 'Insufficient funds'
            })
        }
    ]
)

# Query logs with CloudWatch Logs Insights
response = logs.start_query(
    logGroupName='/aws/lambda/my-function',
    startTime=int((datetime.now() - timedelta(hours=1)).timestamp()),
    endTime=int(datetime.now().timestamp()),
    queryString='''
        fields @timestamp, message.order_id, message.error
        | filter message.level = "ERROR"
        | stats count() by message.error
    '''
)

# Get query results
query_id = response['queryId']
result = logs.get_query_results(queryId=query_id)
```

### Log Aggregation Patterns

```yaml
# ECS Task Definition - Send logs to CloudWatch
{
  "family": "web-app",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "myapp:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/web-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

```yaml
# Kubernetes - Fluent Bit sidecar to OpenSearch
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: logs
      mountPath: /var/log/app
  - name: fluent-bit
    image: amazon/aws-for-fluent-bit:latest
    env:
    - name: AWS_REGION
      value: us-east-1
    - name: OPENSEARCH_ENDPOINT
      value: https://my-domain.us-east-1.es.amazonaws.com
    volumeMounts:
    - name: logs
      mountPath: /var/log/app
      readOnly: true
  volumes:
  - name: logs
    emptyDir: {}
```

---

## 3. Distributed Tracing

### Concepts

- **Trace**: End-to-end journey of a request
- **Span**: Single operation within a trace
- **Context Propagation**: Passing trace IDs across services

### AWS X-Ray

```python
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware
from flask import Flask
import requests

app = Flask(__name__)
XRayMiddleware(app, xray_recorder)

@app.route('/api/orders')
@xray_recorder.capture('create_order')
def create_order():
    # Automatic instrumentation of HTTP calls
    user = requests.get('http://user-service/users/123').json()

    # Custom subsegment
    with xray_recorder.capture('validate_inventory') as subsegment:
        subsegment.put_annotation('product_id', 'prod_456')
        subsegment.put_metadata('inventory_count', 10)
        inventory = check_inventory('prod_456')

    # Capture exceptions
    try:
        payment = charge_payment(user, 99.99)
    except Exception as e:
        xray_recorder.current_subsegment().add_exception(e)
        raise

    return {'order_id': 'ord_123'}

# Instrument boto3
from aws_xray_sdk.core import patch_all
patch_all()  # Auto-instrument AWS SDK calls
```

**X-Ray Trace Example:**
```
Trace ID: 1-67890abc-12345678901234567890abcd

├─ API Gateway (100ms)
│  └─ Lambda: OrderFunction (95ms)
│     ├─ DynamoDB: GetItem Users (15ms)
│     ├─ HTTP: Payment Service (60ms)
│     │  ├─ DynamoDB: GetItem PaymentMethods (10ms)
│     │  └─ External: Stripe API (45ms)
│     └─ SQS: SendMessage OrderQueue (5ms)
```

### OpenTelemetry (Cloud-Agnostic)

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Setup tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Export to collector (Jaeger, Tempo, X-Ray, etc.)
otlp_exporter = OTLPSpanExporter(endpoint="http://localhost:4317")
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

# Auto-instrument
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

@app.route('/api/orders')
def create_order():
    # Manual span
    with tracer.start_as_current_span("create_order") as span:
        span.set_attribute("order.id", "ord_123")
        span.set_attribute("order.amount", 99.99)

        # Child spans automatically linked
        user = fetch_user(123)
        payment = process_payment(user, 99.99)

        span.add_event("order_created", {
            "order_id": "ord_123",
            "processing_time_ms": 150
        })

    return {'order_id': 'ord_123'}
```

### Sampling Strategies

```python
# Always sample errors, sample 10% of success
from opentelemetry.sdk.trace.sampling import TraceIdRatioBased, ParentBased

class ErrorAwareSampler:
    def __init__(self, base_sampler):
        self.base_sampler = base_sampler

    def should_sample(self, context, trace_id, name, attributes):
        # Always sample if there's an error
        if attributes and attributes.get('error'):
            return Decision.RECORD_AND_SAMPLE

        # Otherwise use base sampler (e.g., 10%)
        return self.base_sampler.should_sample(
            context, trace_id, name, attributes
        )

sampler = ParentBased(root=ErrorAwareSampler(TraceIdRatioBased(0.1)))
```

---

## 4. Alerting

### Alert Design Principles

1. **Actionable**: Alert should require human action
2. **Timely**: Alert before customers notice
3. **Context-rich**: Include enough info to debug
4. **Avoid fatigue**: Don't alert on noise

### SLO-Based Alerting

```python
# Alert on error budget burn rate
# SLO: 99.9% availability (0.1% error budget)

# Fast burn (2% in 1 hour) = 43 hours to exhaustion
fast_burn_rate = 2.0
fast_burn_window = '1h'

# Slow burn (5% in 6 hours) = 5 days to exhaustion
slow_burn_rate = 5.0
slow_burn_window = '6h'

# CloudWatch Alarm - Fast burn
{
  "AlarmName": "SLO-ErrorBudget-FastBurn",
  "MetricName": "ErrorRate",
  "Namespace": "MyApp",
  "Statistic": "Average",
  "Period": 3600,  # 1 hour
  "EvaluationPeriods": 1,
  "Threshold": 2.0,  # 2% error rate
  "ComparisonOperator": "GreaterThanThreshold",
  "AlarmDescription": "Error budget burning fast - 43 hours to exhaustion",
  "AlarmActions": ["arn:aws:sns:us-east-1:123456789012:pagerduty-critical"]
}
```

### Multi-Window Multi-Burn-Rate Alerts

```yaml
# Prometheus AlertManager rules
groups:
- name: slo_alerts
  rules:
  # Page: Fast burn (2% in 1h, 2% in 5m)
  - alert: ErrorBudgetBurnFast
    expr: |
      (
        sum(rate(http_requests_total{status=~"5.."}[1h]))
        / sum(rate(http_requests_total[1h]))
      ) > 0.02
      and
      (
        sum(rate(http_requests_total{status=~"5.."}[5m]))
        / sum(rate(http_requests_total[5m]))
      ) > 0.02
    labels:
      severity: critical
    annotations:
      summary: "Error budget burning fast (43h to exhaustion)"

  # Ticket: Slow burn (5% in 6h, 5% in 30m)
  - alert: ErrorBudgetBurnSlow
    expr: |
      (
        sum(rate(http_requests_total{status=~"5.."}[6h]))
        / sum(rate(http_requests_total[6h]))
      ) > 0.005
      and
      (
        sum(rate(http_requests_total{status=~"5.."}[30m]))
        / sum(rate(http_requests_total[30m]))
      ) > 0.005
    labels:
      severity: warning
    annotations:
      summary: "Error budget burning slowly (5 days to exhaustion)"
```

### CloudWatch Composite Alarms

```yaml
Resources:
  # Individual alarms
  HighErrorRateAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: HighErrorRate
      MetricName: 5XXError
      Threshold: 10
      ComparisonOperator: GreaterThanThreshold

  HighLatencyAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: HighLatency
      MetricName: TargetResponseTime
      Threshold: 1.0
      ComparisonOperator: GreaterThanThreshold

  # Composite alarm (AND condition)
  ServiceDegradedAlarm:
    Type: AWS::CloudWatch::CompositeAlarm
    Properties:
      AlarmName: ServiceDegraded
      AlarmRule: "ALARM(HighErrorRateAlarm) AND ALARM(HighLatencyAlarm)"
      AlarmActions:
        - !Ref SNSTopic
```

### Alert Routing

```python
# SNS with message filtering
import boto3

sns = boto3.client('sns')

# Publish with attributes
sns.publish(
    TopicArn='arn:aws:sns:us-east-1:123456789012:alerts',
    Message='High error rate detected',
    Subject='CRITICAL: Service Degraded',
    MessageAttributes={
        'severity': {'DataType': 'String', 'StringValue': 'critical'},
        'service': {'DataType': 'String', 'StringValue': 'payment-service'},
        'environment': {'DataType': 'String', 'StringValue': 'production'}
    }
)

# Subscription filter policy
subscription_filter = {
    "severity": ["critical"],
    "environment": ["production"]
}

sns.set_subscription_attributes(
    SubscriptionArn='arn:aws:sns:...:subscription-id',
    AttributeName='FilterPolicy',
    AttributeValue=json.dumps(subscription_filter)
)
```

---

## 5. Dashboards

### Layered Dashboard Approach

#### 1. Executive Dashboard (Business Metrics)

```json
// CloudWatch Dashboard - Executive View
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "title": "Orders per Minute",
        "metrics": [
          ["MyApp", "OrdersCompleted", {"stat": "Sum", "period": 60}]
        ]
      }
    },
    {
      "type": "metric",
      "properties": {
        "title": "Revenue (USD)",
        "metrics": [
          ["MyApp", "Revenue", {"stat": "Sum", "period": 300}]
        ]
      }
    },
    {
      "type": "metric",
      "properties": {
        "title": "SLO Compliance",
        "metrics": [
          ["MyApp", "AvailabilityPercent", {"stat": "Average"}]
        ],
        "yAxis": {"left": {"min": 99.5, "max": 100}}
      }
    }
  ]
}
```

#### 2. Service Dashboard (RED Metrics)

```yaml
# Grafana Dashboard JSON
{
  "dashboard": {
    "title": "Order Service - RED Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (endpoint)"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))"
          }
        ]
      },
      {
        "title": "Latency (p50, p95, p99)",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p50"
          },
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p95"
          },
          {
            "expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p99"
          }
        ]
      }
    ]
  }
}
```

#### 3. Infrastructure Dashboard (USE Metrics)

```python
# CloudWatch Dashboard - Infrastructure
dashboard_body = {
    "widgets": [
        # CPU Utilization
        {
            "type": "metric",
            "properties": {
                "title": "EC2 CPU Utilization",
                "metrics": [
                    ["AWS/EC2", "CPUUtilization", {"stat": "Average"}]
                ],
                "annotations": {
                    "horizontal": [
                        {"value": 80, "label": "Scale Up Threshold", "color": "#ff7f0e"}
                    ]
                }
            }
        },
        # Saturation - Queue Depth
        {
            "type": "metric",
            "properties": {
                "title": "SQS Queue Depth",
                "metrics": [
                    ["AWS/SQS", "ApproximateNumberOfMessagesVisible"],
                    [".", "ApproximateAgeOfOldestMessage"]
                ]
            }
        },
        # Errors
        {
            "type": "metric",
            "properties": {
                "title": "ALB Target Errors",
                "metrics": [
                    ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", {"stat": "Sum"}],
                    [".", "UnHealthyHostCount", {"stat": "Average"}]
                ]
            }
        }
    ]
}

cloudwatch.put_dashboard(
    DashboardName='Infrastructure',
    DashboardBody=json.dumps(dashboard_body)
)
```

---

## 6. Service Level Indicators (SLIs)

### Defining Good SLIs

```python
# SLI Examples

# 1. Availability SLI
availability_sli = """
    (total_requests - failed_requests) / total_requests

    Good: 99.9% of requests succeed
    Measurement: Count 2xx/3xx vs 5xx responses
"""

# 2. Latency SLI
latency_sli = """
    count(requests with latency < 500ms) / total_requests

    Good: 99% of requests complete in < 500ms
    Measurement: p99 latency from ALB metrics
"""

# 3. Freshness SLI (for data pipelines)
freshness_sli = """
    (data_points_within_sla) / total_data_points

    Good: 95% of data points processed within 5 minutes
    Measurement: Timestamp diff between ingestion and processing
"""

# 4. Durability SLI (for storage)
durability_sli = """
    1 - (data_lost / data_stored)

    Good: 99.999999999% (11 nines) data durability
    Measurement: S3 provides this by default
"""
```

### SLI Implementation

```python
# Calculate SLI from CloudWatch metrics
import boto3
from datetime import datetime, timedelta

cloudwatch = boto3.client('cloudwatch')

def calculate_availability_sli(start_time, end_time):
    # Get total requests
    total_response = cloudwatch.get_metric_statistics(
        Namespace='AWS/ApplicationELB',
        MetricName='RequestCount',
        Dimensions=[{'Name': 'LoadBalancer', 'Value': 'app/my-alb/123'}],
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,
        Statistics=['Sum']
    )
    total_requests = sum(dp['Sum'] for dp in total_response['Datapoints'])

    # Get error requests
    error_response = cloudwatch.get_metric_statistics(
        Namespace='AWS/ApplicationELB',
        MetricName='HTTPCode_Target_5XX_Count',
        Dimensions=[{'Name': 'LoadBalancer', 'Value': 'app/my-alb/123'}],
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,
        Statistics=['Sum']
    )
    error_requests = sum(dp['Sum'] for dp in error_response['Datapoints'])

    # Calculate SLI
    sli = (total_requests - error_requests) / total_requests * 100
    return sli

# Calculate over last 30 days
end = datetime.now()
start = end - timedelta(days=30)
sli = calculate_availability_sli(start, end)

print(f"30-day availability SLI: {sli:.3f}%")

# Compare to SLO (99.9%)
slo = 99.9
error_budget_remaining = (sli - slo) / (100 - slo) * 100
print(f"Error budget remaining: {error_budget_remaining:.1f}%")
```

---

## 7. On-Call & Incident Response

### Runbooks

```markdown
# Runbook: High Error Rate Alert

## Alert Description
5XX error rate exceeds 1% for 5 minutes

## Severity
Critical - Page immediately

## Impact
Users experiencing service failures

## Investigation Steps

1. **Check Dashboard**
   - URL: https://grafana.company.com/d/service-overview
   - Look for: Request rate spike, latency increase

2. **Recent Deployments**
   ```bash
   kubectl rollout history deployment/web-app
   ```
   - If deployed in last hour, likely cause

3. **Check Dependencies**
   - Database: Check RDS CPU, connections
   - Cache: Check ElastiCache hit rate
   - External APIs: Check third-party status pages

4. **Check Logs**
   ```bash
   aws logs tail /aws/ecs/web-app --follow --format short
   ```
   - Look for exceptions, stack traces

## Mitigation

### If caused by bad deployment:
```bash
# Rollback to previous version
kubectl rollout undo deployment/web-app

# Verify
kubectl rollout status deployment/web-app
```

### If caused by traffic spike:
```bash
# Scale up manually
kubectl scale deployment/web-app --replicas=20
```

### If caused by dependency failure:
- Enable circuit breaker
- Serve stale cache
- Enable degraded mode

## Escalation
If not resolved in 15 minutes:
- Escalate to: @platform-team
- Incident Commander: @on-call-manager

## Post-Incident
- Create incident report
- Schedule postmortem
- Update runbook with learnings
```

### Incident Severity Levels

| Level | Response Time | Example |
|-------|---------------|---------|
| **P0 - Critical** | Page immediately | Complete service outage |
| **P1 - High** | Page during business hours | Partial service degradation |
| **P2 - Medium** | Create ticket | Non-critical feature down |
| **P3 - Low** | Backlog | Minor bug, no user impact |

---

## 8. AWS Observability Services

### Amazon CloudWatch

- **Metrics**: Standard and custom metrics
- **Logs**: Log aggregation and analysis
- **Alarms**: Threshold and composite alarms
- **Dashboards**: Custom visualization
- **ServiceLens**: Service map with X-Ray
- **Synthetics**: Canary monitoring
- **RUM**: Real User Monitoring
- **Evidently**: Feature flags and A/B testing

### AWS X-Ray

- Distributed tracing
- Service map visualization
- Latency analysis
- Error and fault analysis

### Amazon Managed Grafana

- Managed Grafana service
- Query CloudWatch, Prometheus, X-Ray
- Built-in dashboards
- Alert management

### Amazon Managed Prometheus

- Managed Prometheus service
- PromQL queries
- Horizontal scaling
- Integrates with Grafana

### AWS OpenSearch

- Log analytics
- Full-text search
- Visualizations with Kibana
- Alerting with monitors

---

## Interview Tips

### Discussing Observability

1. **Start with SLOs:**
   - "What's the target availability? 99.9%?"
   - "What's acceptable latency? p99 < 500ms?"

2. **Three Pillars:**
   - Metrics for trends and alerts
   - Logs for debugging
   - Traces for distributed systems

3. **Practical Examples:**
   ```
   "I'd instrument RED metrics:
   - Request rate using ALB RequestCount
   - Error rate using 5XX count
   - Duration using TargetResponseTime

   Then set up alerts:
   - Page if error rate > 1% for 5 minutes
   - Ticket if p99 latency > 1 second"
   ```

4. **Cost Considerations:**
   - "CloudWatch has 5-minute granularity by default, 1-minute costs more"
   - "Log retention: 7 days hot, 30 days cold, 1 year archive"
   - "Sample traces (10% of requests) to reduce costs"

### Common Questions

**Q: How do you monitor a microservices architecture?**

**A:** "I'd use a multi-layer approach:
1. **Service mesh** (Istio) for automatic metrics collection
2. **Distributed tracing** (X-Ray) to follow requests across services
3. **Centralized logging** (OpenSearch) with correlation IDs
4. **Service-level dashboards** showing RED metrics per service
5. **SLO-based alerting** to catch issues before SLA breach"

**Q: How do you reduce alert fatigue?**

**A:** "Several strategies:
1. **SLO-based alerts** instead of threshold alerts
2. **Multi-window multi-burn-rate** to reduce false positives
3. **Composite alarms** requiring multiple conditions
4. **Smart routing** - pages for P0, tickets for P1
5. **Regular tuning** based on postmortem learnings
6. **Self-healing** - auto-scale before alerting"

**Q: Difference between monitoring and observability?**

**A:** "Monitoring tells you **what** is wrong (CPU is high). Observability tells you **why** it's wrong (this specific query is causing CPU spike). Observability is about understanding system internals from external outputs using metrics, logs, and traces."

---

## Summary Checklist

- [ ] Metrics: RED (requests, errors, duration) or USE (utilization, saturation, errors)
- [ ] Structured logging with correlation IDs
- [ ] Distributed tracing across services
- [ ] SLO-based alerting (avoid alert fatigue)
- [ ] Layered dashboards (executive, service, infrastructure)
- [ ] Define SLIs that map to user experience
- [ ] Runbooks for common incidents
- [ ] CloudWatch/Prometheus/X-Ray/OpenSearch setup
- [ ] Log retention and cost optimization
- [ ] Regular review and tuning of alerts
