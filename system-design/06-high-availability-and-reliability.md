# High Availability & Reliability - System Design Cheatsheet

## Overview

High availability (HA) ensures systems remain operational and accessible despite failures. Reliability means systems consistently perform their intended function correctly.

**Key Metrics:**
- **Availability**: Percentage of time system is operational (e.g., 99.99% = 52.56 minutes downtime/year)
- **RTO (Recovery Time Objective)**: Maximum acceptable downtime
- **RPO (Recovery Point Objective)**: Maximum acceptable data loss
- **MTBF (Mean Time Between Failures)**: Average time between failures
- **MTTR (Mean Time To Recovery)**: Average time to recover from failure

**Availability Levels:**
```
99%       = Two nines    = 3.65 days/year downtime
99.9%     = Three nines  = 8.76 hours/year downtime
99.99%    = Four nines   = 52.56 minutes/year downtime
99.999%   = Five nines   = 5.26 minutes/year downtime
99.9999%  = Six nines    = 31.5 seconds/year downtime
```

---

## 1. Multi-AZ Architecture

### What is Multi-AZ?

Deploying resources across multiple Availability Zones within a region for fault tolerance.

**How it Works:**
- AWS AZs are physically separate data centers with independent power, cooling, networking
- Typically 2-6 AZs per region, connected by low-latency links
- Synchronous replication between AZs for data consistency

### Example: Multi-AZ Web Application

```yaml
# CloudFormation - Multi-AZ Application
Resources:
  # VPC with subnets across 3 AZs
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs '']

  PublicSubnet3:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.3.0/24
      AvailabilityZone: !Select [2, !GetAZs '']

  # Application Load Balancer across AZs
  ALB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
        - !Ref PublicSubnet3
      Type: application

  # Auto Scaling Group distributes instances
  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      VPCZoneIdentifier:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
        - !Ref PublicSubnet3
      MinSize: 3
      MaxSize: 9
      DesiredCapacity: 6
      TargetGroupARNs:
        - !Ref TargetGroup
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300

  # RDS Multi-AZ
  DBInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      Engine: postgres
      MultiAZ: true  # Automatic synchronous replication
      DBSubnetGroupName: !Ref DBSubnetGroup
```

**Benefits:**
- Automatic failover (RDS: 60-120 seconds)
- No data loss with synchronous replication
- Survives AZ-level failures

**Limitations:**
- Higher cost (2x resources minimum)
- Slight latency increase for cross-AZ replication
- Still vulnerable to region-wide outages

---

## 2. Multi-Region Architecture

### Active-Active vs Active-Passive

#### Active-Active (Multi-Master)

Both regions actively serve traffic simultaneously.

```python
# Route 53 Geolocation Routing - Active-Active
{
  "ResourceRecordSets": [
    {
      "Name": "api.example.com",
      "Type": "A",
      "SetIdentifier": "US-East",
      "GeoLocation": {"ContinentCode": "NA"},
      "AliasTarget": {
        "DNSName": "us-east-alb.amazonaws.com",
        "HostedZoneId": "Z123456"
      }
    },
    {
      "Name": "api.example.com",
      "Type": "A",
      "SetIdentifier": "EU-West",
      "GeoLocation": {"ContinentCode": "EU"},
      "AliasTarget": {
        "DNSName": "eu-west-alb.amazonaws.com",
        "HostedZoneId": "Z789012"
      }
    }
  ]
}
```

**Use Cases:**
- Global applications with regional traffic
- Low latency requirements worldwide
- Maximum availability (99.99%+)

**Challenges:**
- Data consistency across regions
- Conflict resolution for writes
- Higher complexity and cost

#### Active-Passive (Warm Standby)

Primary region serves traffic; secondary region on standby.

```python
# Route 53 Failover Routing - Active-Passive
{
  "ResourceRecordSets": [
    {
      "Name": "api.example.com",
      "Type": "A",
      "SetIdentifier": "Primary",
      "Failover": "PRIMARY",
      "HealthCheckId": "abc123",
      "AliasTarget": {
        "DNSName": "us-east-alb.amazonaws.com",
        "HostedZoneId": "Z123456"
      }
    },
    {
      "Name": "api.example.com",
      "Type": "A",
      "SetIdentifier": "Secondary",
      "Failover": "SECONDARY",
      "AliasTarget": {
        "DNSName": "eu-west-alb.amazonaws.com",
        "HostedZoneId": "Z789012"
      }
    }
  ]
}
```

**Use Cases:**
- Disaster recovery
- Cost-sensitive applications
- Simpler data consistency requirements

**Recovery Time:**
- DNS TTL (typically 60-300 seconds)
- Application warmup time
- Data synchronization lag

### Data Replication Strategies

#### Aurora Global Database

```sql
-- Create Aurora Global Database
CREATE GLOBAL DATABASE my_global_db;

-- Add primary cluster (us-east-1)
CREATE DB CLUSTER my_primary_cluster
  ENGINE aurora-postgresql
  GLOBAL_CLUSTER_IDENTIFIER my_global_db;

-- Add secondary cluster (eu-west-1)
CREATE DB CLUSTER my_secondary_cluster
  ENGINE aurora-postgresql
  GLOBAL_CLUSTER_IDENTIFIER my_global_db
  SOURCE_REGION us-east-1;
```

**Characteristics:**
- Replication lag: < 1 second
- RPO: Typically 1 second
- RTO: < 1 minute (promote secondary to primary)
- Read access from all regions

#### DynamoDB Global Tables

```python
import boto3

dynamodb = boto3.client('dynamodb')

# Create global table
response = dynamodb.create_global_table(
    GlobalTableName='users',
    ReplicationGroup=[
        {'RegionName': 'us-east-1'},
        {'RegionName': 'eu-west-1'},
        {'RegionName': 'ap-southeast-1'}
    ]
)

# Write in one region, automatically replicates
table = boto3.resource('dynamodb', region_name='us-east-1').Table('users')
table.put_item(Item={'user_id': '123', 'name': 'Alice'})

# Read from any region
table_eu = boto3.resource('dynamodb', region_name='eu-west-1').Table('users')
user = table_eu.get_item(Key={'user_id': '123'})
```

**Characteristics:**
- Multi-master (writes to any region)
- Eventual consistency across regions
- Automatic conflict resolution (last-writer-wins)
- Replication lag: Typically < 1 second

#### S3 Cross-Region Replication

```json
{
  "Role": "arn:aws:iam::account-id:role/s3-replication-role",
  "Rules": [
    {
      "Status": "Enabled",
      "Priority": 1,
      "Filter": {"Prefix": ""},
      "Destination": {
        "Bucket": "arn:aws:s3:::backup-bucket-eu-west",
        "ReplicationTime": {
          "Status": "Enabled",
          "Time": {"Minutes": 15}
        },
        "Metrics": {
          "Status": "Enabled",
          "EventThreshold": {"Minutes": 15}
        }
      }
    }
  ]
}
```

---

## 3. Disaster Recovery Strategies

### DR Strategy Comparison

| Strategy | RTO | RPO | Cost | Complexity |
|----------|-----|-----|------|------------|
| **Backup & Restore** | Hours-Days | Hours | Low | Low |
| **Pilot Light** | 10s of minutes | Minutes | Medium | Medium |
| **Warm Standby** | Minutes | Seconds | Medium-High | Medium-High |
| **Multi-Site Active-Active** | Real-time | Near-zero | High | High |

### 1. Backup & Restore

```python
# AWS Backup - Automated backup plan
import boto3

backup = boto3.client('backup')

# Create backup plan
backup.create_backup_plan(
    BackupPlan={
        'BackupPlanName': 'DailyBackup',
        'Rules': [
            {
                'RuleName': 'DailyBackupRule',
                'TargetBackupVaultName': 'Default',
                'ScheduleExpression': 'cron(0 2 * * ? *)',  # 2 AM daily
                'StartWindowMinutes': 60,
                'CompletionWindowMinutes': 120,
                'Lifecycle': {
                    'DeleteAfterDays': 30,
                    'MoveToColdStorageAfterDays': 7
                }
            }
        ]
    }
)

# Assign resources to backup
backup.create_backup_selection(
    BackupPlanId='plan-id',
    BackupSelection={
        'SelectionName': 'DatabaseBackup',
        'IamRoleArn': 'arn:aws:iam::account:role/BackupRole',
        'Resources': [
            'arn:aws:rds:us-east-1:account:db:mydb',
            'arn:aws:dynamodb:us-east-1:account:table/mytable'
        ]
    }
)
```

**Best For:** Cost-sensitive, non-critical systems
**RTO:** 4-24 hours
**RPO:** 24 hours (depending on backup frequency)

### 2. Pilot Light

Minimal version of environment always running in DR region.

```yaml
# Terraform - Pilot Light DR Setup
# Primary Region (us-east-1) - Full environment
module "primary" {
  source = "./modules/app"
  region = "us-east-1"

  rds_instance_class = "db.r5.2xlarge"
  asg_min_size = 4
  asg_max_size = 20
  cache_node_type = "cache.r5.large"
}

# DR Region (eu-west-1) - Pilot light
module "dr" {
  source = "./modules/app"
  region = "eu-west-1"

  # Minimal compute (scaled up during failover)
  rds_instance_class = "db.r5.large"  # Smaller instance
  rds_read_replica = true              # Read replica only
  asg_min_size = 0                     # No running instances
  asg_max_size = 20
  cache_node_type = "cache.r5.small"

  # AMIs and launch templates ready
  ami_id = data.aws_ami.latest.id
}
```

**Failover Process:**
1. Promote RDS read replica to primary
2. Scale up ASG from 0 to desired capacity
3. Update DNS to point to DR region

**Best For:** Moderate RTO requirements
**RTO:** 10-30 minutes
**RPO:** Minutes

### 3. Warm Standby

Scaled-down but fully functional environment.

```python
# Auto Scaling - Warm Standby with scheduled scaling
import boto3

autoscaling = boto3.client('autoscaling')

# Normal operation - small capacity
autoscaling.put_scheduled_update_group_action(
    AutoScalingGroupName='dr-asg',
    ScheduledActionName='WarmStandby',
    Recurrence='0 0 * * *',  # Daily
    MinSize=2,
    MaxSize=10,
    DesiredCapacity=2
)

# Failover - scale up to full capacity
def failover_to_dr():
    autoscaling.set_desired_capacity(
        AutoScalingGroupName='dr-asg',
        DesiredCapacity=10,
        HonorCooldown=False
    )

    # Promote RDS read replica
    rds = boto3.client('rds')
    rds.promote_read_replica(
        DBInstanceIdentifier='dr-db-replica'
    )

    # Update Route 53
    route53 = boto3.client('route53')
    route53.change_resource_record_sets(
        HostedZoneId='Z123456',
        ChangeBatch={
            'Changes': [{
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': 'api.example.com',
                    'Type': 'A',
                    'SetIdentifier': 'DR',
                    'Weight': 100,
                    'AliasTarget': {
                        'DNSName': 'dr-alb.amazonaws.com',
                        'HostedZoneId': 'Z789012'
                    }
                }
            }]
        }
    )
```

**Best For:** Business-critical applications
**RTO:** 5-10 minutes
**RPO:** Seconds

---

## 4. Auto Scaling

### Horizontal Scaling (Scale Out/In)

Add/remove instances based on demand.

#### Target Tracking Scaling

```yaml
# ECS Service Auto Scaling - Target Tracking
Resources:
  ServiceScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      ServiceNamespace: ecs
      ResourceId: service/my-cluster/my-service
      ScalableDimension: ecs:service:DesiredCount
      MinCapacity: 2
      MaxCapacity: 20

  CPUScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref ServiceScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        TargetValue: 70.0
        PredefinedMetricSpecification:
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        ScaleInCooldown: 300
        ScaleOutCooldown: 60

  RequestCountScaling:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref ServiceScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        TargetValue: 1000
        PredefinedMetricSpecification:
          PredefinedMetricType: ALBRequestCountPerTarget
          ResourceLabel: !GetAtt ALB.LoadBalancerFullName
```

#### Step Scaling

```json
{
  "PolicyName": "StepScalingPolicy",
  "PolicyType": "StepScaling",
  "StepScalingPolicyConfiguration": {
    "AdjustmentType": "PercentChangeInCapacity",
    "Cooldown": 300,
    "MetricAggregationType": "Average",
    "StepAdjustments": [
      {
        "MetricIntervalLowerBound": 0,
        "MetricIntervalUpperBound": 20,
        "ScalingAdjustment": 10
      },
      {
        "MetricIntervalLowerBound": 20,
        "MetricIntervalUpperBound": 40,
        "ScalingAdjustment": 20
      },
      {
        "MetricIntervalLowerBound": 40,
        "ScalingAdjustment": 30
      }
    ]
  }
}
```

#### Predictive Scaling

```python
# EC2 Auto Scaling - Predictive Scaling
import boto3

autoscaling = boto3.client('autoscaling')

response = autoscaling.put_scaling_policy(
    AutoScalingGroupName='my-asg',
    PolicyName='PredictiveScaling',
    PolicyType='PredictiveScaling',
    PredictiveScalingConfiguration={
        'MetricSpecifications': [
            {
                'TargetValue': 70.0,
                'PredefinedMetricPairSpecification': {
                    'PredefinedMetricType': 'ASGCPUUtilization'
                }
            }
        ],
        'Mode': 'ForecastAndScale',  # or 'ForecastOnly'
        'SchedulingBufferTime': 600  # 10 minutes ahead
    }
)
```

### Vertical Scaling (Scale Up/Down)

Increase/decrease instance size.

```python
# Lambda Function - Automated vertical scaling
import boto3

def scale_rds_vertically(event, context):
    rds = boto3.client('rds')
    cloudwatch = boto3.client('cloudwatch')

    # Get current CPU utilization
    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        MetricName='CPUUtilization',
        Dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': 'mydb'}],
        StartTime=datetime.now() - timedelta(hours=1),
        EndTime=datetime.now(),
        Period=3600,
        Statistics=['Average']
    )

    avg_cpu = response['Datapoints'][0]['Average']

    # Scale up if high CPU
    if avg_cpu > 80:
        rds.modify_db_instance(
            DBInstanceIdentifier='mydb',
            DBInstanceClass='db.r5.4xlarge',  # Scale up
            ApplyImmediately=True
        )
    # Scale down if low CPU
    elif avg_cpu < 30:
        rds.modify_db_instance(
            DBInstanceIdentifier='mydb',
            DBInstanceClass='db.r5.xlarge',  # Scale down
            ApplyImmediately=False  # During maintenance window
        )
```

**Considerations:**
- Requires downtime (RDS: 1-5 minutes)
- Use for databases, single large instances
- Combine with horizontal scaling for best results

### Kubernetes HPA + Cluster Autoscaler

```yaml
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 3
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 4
        periodSeconds: 30
      selectPolicy: Max
```

---

## 5. Health Checks & Circuit Breakers

### Health Check Types

#### 1. Liveness Probe

Determines if container should be restarted.

```yaml
# Kubernetes Liveness Probe
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  containers:
  - name: app
    image: myapp:latest
    livenessProbe:
      httpGet:
        path: /health/live
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
```

```python
# Flask endpoint
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health/live')
def liveness():
    # Check critical dependencies
    try:
        # Verify app is not deadlocked
        return jsonify({"status": "alive"}), 200
    except Exception:
        return jsonify({"status": "dead"}), 500
```

#### 2. Readiness Probe

Determines if container can receive traffic.

```yaml
# Kubernetes Readiness Probe
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  successThreshold: 1
  failureThreshold: 3
```

```python
@app.route('/health/ready')
def readiness():
    checks = {
        'database': check_database(),
        'cache': check_cache(),
        'dependencies': check_external_apis()
    }

    if all(checks.values()):
        return jsonify({"status": "ready", "checks": checks}), 200
    else:
        return jsonify({"status": "not_ready", "checks": checks}), 503

def check_database():
    try:
        db.execute('SELECT 1')
        return True
    except:
        return False
```

#### 3. ALB Health Checks

```yaml
# Application Load Balancer Target Group
Resources:
  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      HealthCheckEnabled: true
      HealthCheckProtocol: HTTP
      HealthCheckPath: /health
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 10
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 3
      Matcher:
        HttpCode: 200-299
```

### Circuit Breaker Pattern

Prevents cascading failures by failing fast.

```python
# Python Circuit Breaker with pybreaker
from pybreaker import CircuitBreaker

# Configure circuit breaker
db_breaker = CircuitBreaker(
    fail_max=5,           # Open after 5 failures
    timeout_duration=60,  # Stay open for 60 seconds
    expected_exception=DatabaseException
)

@db_breaker
def get_user_from_db(user_id):
    # This will be protected by circuit breaker
    return database.query(f"SELECT * FROM users WHERE id={user_id}")

def get_user(user_id):
    try:
        return get_user_from_db(user_id)
    except CircuitBreakerError:
        # Circuit is open, return from cache
        return cache.get(f"user:{user_id}")
```

**Circuit States:**
- **Closed**: Normal operation, requests pass through
- **Open**: Threshold breached, all requests fail immediately
- **Half-Open**: Testing recovery, limited requests allowed

```python
# Advanced Circuit Breaker with Istio
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: user-service-circuit-breaker
spec:
  host: user-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 60s
      maxEjectionPercent: 50
      minHealthPercent: 50
```

---

## 6. Deployment Strategies

### Blue/Green Deployment

Two identical environments, switch traffic instantly.

```python
# Blue/Green with CodeDeploy
{
  "version": 0.0,
  "Resources": [
    {
      "TargetService": {
        "Type": "AWS::ECS::Service",
        "Properties": {
          "TaskDefinition": "arn:aws:ecs:region:account:task-definition/app:2",
          "LoadBalancerInfo": {
            "ContainerName": "web",
            "ContainerPort": 80
          }
        }
      }
    }
  ],
  "Hooks": [
    {
      "BeforeInstall": "LambdaFunctionToValidateBeforeInstall"
    },
    {
      "AfterInstall": "LambdaFunctionToValidateAfterInstall"
    },
    {
      "AfterAllowTestTraffic": "LambdaFunctionToValidateTestTraffic"
    },
    {
      "BeforeAllowTraffic": "LambdaFunctionToValidateBeforeAllowTraffic"
    },
    {
      "AfterAllowTraffic": "LambdaFunctionToValidateAfterAllowTraffic"
    }
  ]
}
```

**Pros:**
- Instant rollback (switch back to blue)
- Zero downtime
- Full testing of green before cutover

**Cons:**
- 2x infrastructure cost during deployment
- Database migration complexity
- Not suitable for stateful applications

### Canary Deployment

Gradually shift traffic to new version.

```yaml
# Kubernetes Flagger - Canary with metrics
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: web-app
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 10
    maxWeight: 50
    stepWeight: 5
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
    webhooks:
    - name: load-test
      url: http://load-tester/
      timeout: 5s
      metadata:
        cmd: "hey -z 1m -q 10 -c 2 http://web-app-canary/"
```

**Traffic Shift Example:**
```
Initial:  Primary 100%, Canary 0%
Step 1:   Primary 95%,  Canary 5%   (monitor for 1 min)
Step 2:   Primary 90%,  Canary 10%  (monitor for 1 min)
...
Step 10:  Primary 50%,  Canary 50%  (final state)
Promote:  Primary 0%,   Canary 100% (canary becomes primary)
```

### Rolling Deployment

Update instances one at a time.

```yaml
# Kubernetes Rolling Update
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2        # Max 2 extra pods during update
      maxUnavailable: 1  # Max 1 pod can be unavailable
  template:
    spec:
      containers:
      - name: app
        image: myapp:v2
```

**Timeline:**
```
Initial: 10 pods running v1
Step 1:  Create 2 new pods (v2) → 12 total
Step 2:  Terminate 1 old pod (v1) → 11 total (9 v1, 2 v2)
Step 3:  Create 2 new pods (v2) → 13 total (9 v1, 4 v2)
Step 4:  Terminate 1 old pod (v1) → 12 total (8 v1, 4 v2)
...
Final:   10 pods running v2
```

### Feature Flags

Decouple deployment from release.

```python
# Feature flag with LaunchDarkly
import ldclient
from ldclient.config import Config

ldclient.set_config(Config("sdk-key"))
client = ldclient.get()

def process_payment(user, amount):
    # Check feature flag
    use_new_processor = client.variation(
        "new-payment-processor",
        {"key": user.id, "email": user.email},
        False  # Default value
    )

    if use_new_processor:
        return new_payment_processor.charge(user, amount)
    else:
        return legacy_payment_processor.charge(user, amount)

# Gradual rollout
# 1% → 5% → 10% → 25% → 50% → 100%
```

---

## 7. Chaos Engineering

Test system resilience by intentionally introducing failures.

### AWS Fault Injection Simulator

```yaml
# FIS Experiment Template
Resources:
  FISExperiment:
    Type: AWS::FIS::ExperimentTemplate
    Properties:
      Description: "Terminate random EC2 instances"
      Targets:
        ec2Instances:
          ResourceType: aws:ec2:instance
          SelectionMode: PERCENT(20)
          ResourceTags:
            Environment: production
          Filters:
            - Path: State.Name
              Values: ["running"]
      Actions:
        terminateInstances:
          ActionId: aws:ec2:terminate-instances
          Parameters:
            instancesTargetPercentage: "20"
          Targets:
            Instances: ec2Instances
      StopConditions:
        - Source: aws:cloudwatch:alarm
          Value: !GetAtt HighErrorRateAlarm.Arn
      RoleArn: !GetAtt FISRole.Arn
```

### Netflix Simian Army Principles

```python
# Chaos Monkey - Random instance termination
import random
import boto3
from datetime import datetime, time

ec2 = boto3.client('ec2')

def chaos_monkey():
    # Only run during business hours (9 AM - 5 PM)
    now = datetime.now().time()
    if not (time(9, 0) <= now <= time(17, 0)):
        return

    # Get instances with chaos-enabled tag
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:chaos-enabled', 'Values': ['true']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )

    instances = []
    for reservation in response['Reservations']:
        instances.extend([i['InstanceId'] for i in reservation['Instances']])

    if instances:
        # Terminate one random instance
        victim = random.choice(instances)
        print(f"Chaos Monkey terminating {victim}")
        ec2.terminate_instances(InstanceIds=[victim])
```

**Chaos Experiments:**
- **Latency Injection**: Add delays to network calls
- **Instance Failure**: Terminate random instances
- **AZ Failure**: Simulate entire AZ outage
- **Dependency Failure**: Block access to dependencies
- **Resource Exhaustion**: Max out CPU/memory/disk

---

## Interview Tips

### Discussing Availability

1. **Ask About Requirements:**
   - "What's the target SLA? 99.9% or 99.99%?"
   - "What's acceptable RTO and RPO?"
   - "Is this global or regional?"

2. **Start Simple, Then Add:**
   ```
   Level 1: Single AZ (99%)
   Level 2: Multi-AZ (99.9%)
   Level 3: Multi-Region Active-Passive (99.95%)
   Level 4: Multi-Region Active-Active (99.99%+)
   ```

3. **Discuss Trade-offs:**
   - Cost vs availability
   - Consistency vs availability (CAP theorem)
   - Complexity vs benefit

4. **Mention Monitoring:**
   - "We'd need CloudWatch alarms for automatic failover"
   - "Health checks every 30 seconds"
   - "Runbooks for manual intervention"

### Common Mistakes

- ❌ Over-engineering (99.999% when 99.9% is sufficient)
- ❌ Forgetting about data consistency in multi-region
- ❌ Not considering failover testing
- ❌ Ignoring cost implications
- ✅ Always discuss backup strategy
- ✅ Consider blast radius of failures
- ✅ Plan for graceful degradation

### Example Answer Flow

**Question:** "How would you design a highly available e-commerce platform?"

**Answer:**
1. **Requirements**: "First, let's define HA requirements. For e-commerce, I'd target 99.99% availability (52 min/year downtime) with RTO < 5 minutes and RPO near-zero."

2. **Multi-AZ**: "I'd deploy across 3 AZs with ALB distributing traffic. Auto Scaling ensures we have capacity. RDS Multi-AZ provides automatic database failover."

3. **Data Layer**: "For session data, use ElastiCache Redis in cluster mode across AZs. For product catalog, DynamoDB with on-demand scaling."

4. **Deployment**: "Blue/green deployments for zero-downtime releases. Canary deployments for high-risk changes."

5. **DR**: "Warm standby in second region. Aurora Global Database replicates data with < 1s lag. Route 53 health checks trigger automatic failover."

6. **Chaos Testing**: "Regular gamedays to test failover procedures. FIS experiments to validate auto-scaling and circuit breakers."

---

## Summary Checklist

- [ ] Multi-AZ deployment for 99.9% availability
- [ ] Multi-region for 99.99%+ and global users
- [ ] Appropriate DR strategy based on RTO/RPO
- [ ] Auto-scaling (horizontal and/or vertical)
- [ ] Health checks (liveness, readiness, ALB)
- [ ] Circuit breakers for dependency failures
- [ ] Safe deployment strategy (blue/green, canary, rolling)
- [ ] Chaos engineering to validate resilience
- [ ] Automated failover with Route 53
- [ ] Regular DR drills and gamedays
