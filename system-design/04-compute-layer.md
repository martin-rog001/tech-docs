# System Design: Compute Layer

## Overview

The Compute Layer is where your application logic executes. This layer processes requests, runs business logic, and orchestrates workflows. For SRE interviews, understanding compute options, scaling strategies, and container orchestration demonstrates your ability to build reliable, scalable systems.

---

## 1. Compute Service Options

### EC2 (Elastic Compute Cloud)

**Description:** Virtual machines (instances) with full operating system control. Most flexible compute option but requires the most management.

**Key Characteristics:**
- Full control over OS, runtime, and software
- Various instance types (general purpose, compute optimized, memory optimized, GPU)
- Multiple pricing models (On-Demand, Reserved, Spot, Savings Plans)
- Persistent or ephemeral storage
- Manual or auto scaling
- Requires patching, monitoring, maintenance

**Instance Types:**
```
General Purpose (t3, m5, m6i):
- Balanced CPU/Memory
- Use: Web servers, dev environments
- Example: t3.medium (2 vCPU, 4 GB RAM)

Compute Optimized (c5, c6i):
- High CPU performance
- Use: Batch processing, gaming servers, ML inference
- Example: c5.xlarge (4 vCPU, 8 GB RAM)

Memory Optimized (r5, r6i, x2):
- High memory-to-CPU ratio
- Use: Databases, in-memory caches, big data
- Example: r5.large (2 vCPU, 16 GB RAM)

Storage Optimized (i3, d2):
- High disk I/O, large local storage
- Use: NoSQL databases, data warehousing
- Example: i3.xlarge (4 vCPU, 30 GB RAM, 950 GB NVMe SSD)

GPU Instances (p3, p4, g4):
- Graphics processing, ML training
- Use: Deep learning, video encoding
- Example: p3.2xlarge (8 vCPU, 61 GB RAM, 1 GPU)
```

**Pricing Models:**
```
On-Demand:
- Pay per hour/second
- No commitment
- Most expensive
- Use: Unpredictable workloads, short-term

Reserved Instances (1 or 3 year):
- 30-75% discount vs on-demand
- Commit to instance type/region
- Use: Steady-state workloads

Spot Instances:
- Up to 90% discount
- Can be interrupted with 2-minute notice
- Use: Fault-tolerant, flexible workloads (batch, big data)

Savings Plans:
- Commit to $ amount per hour (1 or 3 year)
- Flexible across instance families
- Up to 72% discount
```

**Auto Scaling Group:**
```yaml
Resources:
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateName: web-server-template
      LaunchTemplateData:
        ImageId: ami-12345678
        InstanceType: t3.medium
        SecurityGroupIds:
          - !Ref WebServerSecurityGroup
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            yum update -y
            yum install -y docker
            systemctl start docker
            docker run -d -p 80:80 myapp:latest

  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      MinSize: 2
      MaxSize: 10
      DesiredCapacity: 4
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      VPCZoneIdentifier:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
      TargetGroupARNs:
        - !Ref TargetGroup
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300

  ScaleUpPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AutoScalingGroupName: !Ref AutoScalingGroup
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 70.0
```

**When to Use EC2:**
- Need full OS control
- Custom software/drivers
- Persistent local storage
- Specific compliance requirements
- Legacy applications
- High-performance computing

**Pros:**
- Maximum flexibility
- Can run any software
- Persistent instances
- Large instance variety

**Cons:**
- Manual OS/software management
- Patching responsibility
- Longer startup time (minutes)
- Fixed capacity (pay even if idle)

---

### ECS (Elastic Container Service)

**Description:** AWS-managed container orchestration service for Docker containers. Choose between Fargate (serverless) or EC2 launch type.

**Key Concepts:**
- **Cluster:** Logical grouping of tasks/services
- **Task Definition:** Blueprint for container(s) - image, CPU, memory, ports
- **Task:** Running instance of task definition
- **Service:** Maintains desired count of tasks, integrates with load balancer
- **Fargate:** Serverless compute for containers (no EC2 management)
- **EC2 Launch Type:** You manage EC2 instances, ECS manages containers

**Task Definition:**
```json
{
  "family": "web-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "nginx",
      "image": "nginx:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:db-password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/web-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "nginx"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost/ || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      }
    }
  ]
}
```

**ECS Service:**
```yaml
Resources:
  ECSService:
    Type: AWS::ECS::Service
    Properties:
      ServiceName: web-service
      Cluster: !Ref ECSCluster
      TaskDefinition: !Ref TaskDefinition
      DesiredCount: 4
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: DISABLED
          SecurityGroups:
            - !Ref ContainerSecurityGroup
          Subnets:
            - !Ref PrivateSubnet1
            - !Ref PrivateSubnet2
      LoadBalancers:
        - ContainerName: nginx
          ContainerPort: 80
          TargetGroupArn: !Ref TargetGroup
      HealthCheckGracePeriodSeconds: 60
      DeploymentConfiguration:
        MaximumPercent: 200
        MinimumHealthyPercent: 100
        DeploymentCircuitBreaker:
          Enable: true
          Rollback: true

  ServiceAutoScaling:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: 10
      MinCapacity: 2
      ResourceId: !Sub service/${ECSCluster}/${ECSService.Name}
      RoleARN: !GetAtt AutoScalingRole.Arn
      ScalableDimension: ecs:service:DesiredCount
      ServiceNamespace: ecs

  ScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: cpu-scaling
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref ServiceAutoScaling
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        TargetValue: 70.0
```

**Fargate vs EC2 Launch Type:**
```
Fargate (Serverless):
- No EC2 management
- Pay per vCPU/memory/second
- Faster to start
- Less control over underlying infrastructure
- Higher per-task cost
- Use: Microservices, batch jobs, minimal operations

EC2 Launch Type:
- You manage EC2 instances
- Pay for EC2 instances (can use Spot/Reserved)
- More control (instance type, AMI, SSH access)
- Lower per-task cost at scale
- Use: Large scale, cost optimization, need EC2 features
```

**When to Use ECS:**
- Containerized applications
- Microservices architecture
- Want AWS-native orchestration
- Fargate for serverless containers
- Deep AWS integration (IAM, CloudWatch, etc.)

**Pros:**
- Deep AWS integration
- No orchestrator to manage (managed control plane)
- Fargate option (serverless)
- Good performance
- Lower complexity than Kubernetes

**Cons:**
- AWS-specific (not portable)
- Less feature-rich than Kubernetes
- Smaller ecosystem
- Limited multi-cloud support

---

### EKS (Elastic Kubernetes Service)

**Description:** Managed Kubernetes service. AWS handles Kubernetes control plane, you manage worker nodes (or use Fargate).

**Key Concepts:**
- **Control Plane:** Kubernetes API server, etcd, scheduler (AWS managed)
- **Worker Nodes:** EC2 instances or Fargate running pods
- **Pod:** Smallest deployable unit (one or more containers)
- **Deployment:** Manages replica sets and pod templates
- **Service:** Exposes pods to network (ClusterIP, NodePort, LoadBalancer)
- **Ingress:** HTTP routing to services
- **Namespace:** Virtual clusters for resource isolation

**Deployment Manifest:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 4
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        env:
        - name: ENV
          value: "production"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: production
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
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
```

**Node Groups:**
```yaml
# Managed Node Group (AWS managed)
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: my-cluster
  region: us-east-1

managedNodeGroups:
  - name: ng-general
    instanceType: m5.large
    minSize: 2
    maxSize: 10
    desiredCapacity: 4
    volumeSize: 50
    ssh:
      allow: true
      publicKeyName: my-key
    labels:
      role: general
    tags:
      nodegroup-role: general
    iam:
      withAddonPolicies:
        autoScaler: true
        cloudWatch: true
        ebs: true

  - name: ng-spot
    instanceTypes: ["m5.large", "m5a.large", "m4.large"]
    minSize: 0
    maxSize: 20
    desiredCapacity: 5
    spot: true
    labels:
      role: worker
      lifecycle: spot
```

**Fargate Profile (Serverless Pods):**
```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: my-cluster
  region: us-east-1

fargateProfiles:
  - name: fp-default
    selectors:
      - namespace: default
      - namespace: kube-system
        labels:
          k8s-app: kube-dns
  - name: fp-production
    selectors:
      - namespace: production
        labels:
          compute: fargate
```

**When to Use EKS:**
- Already using Kubernetes
- Multi-cloud or hybrid cloud
- Complex orchestration needs
- Large microservices architecture
- Need Kubernetes ecosystem (Helm, operators, etc.)
- Want portability

**Pros:**
- Industry standard (portable)
- Rich ecosystem (Helm, Istio, Prometheus, etc.)
- Powerful orchestration features
- Multi-cloud compatible
- Large community

**Cons:**
- Steep learning curve
- More complex operations
- Control plane cost ($0.10/hour = $73/month)
- More moving parts
- Requires Kubernetes expertise

**ECS vs EKS Decision:**
```
Choose ECS if:
- AWS-only deployment
- Simpler orchestration needs
- Want less operational overhead
- Smaller team, less Kubernetes expertise
- Cost-sensitive (no control plane cost)

Choose EKS if:
- Need Kubernetes specifically
- Multi-cloud or hybrid cloud
- Complex orchestration requirements
- Large microservices ecosystem
- Team has Kubernetes expertise
- Want ecosystem tools (Helm, Istio, etc.)
```

---

### Lambda (Serverless Functions)

**Description:** Event-driven, serverless compute service. Run code without managing servers. Pay only for execution time.

**Key Characteristics:**
- No server management
- Auto-scaling (0 to thousands of concurrent executions)
- Pay-per-invocation and duration
- 15-minute maximum execution time
- Stateless (ephemeral storage /tmp up to 10GB)
- Event-driven (API Gateway, S3, DynamoDB, SNS, etc.)
- Multiple runtimes (Python, Node.js, Java, Go, .NET, Ruby, custom)

**Lambda Function:**
```python
# lambda_function.py
import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    """
    Process API Gateway request
    """
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        user_id = event['requestContext']['authorizer']['claims']['sub']

        # Business logic
        item = {
            'id': body['id'],
            'user_id': user_id,
            'data': body['data'],
            'timestamp': datetime.utcnow().isoformat()
        }

        # Store in DynamoDB
        table.put_item(Item=item)

        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Success',
                'id': item['id']
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
```

**Lambda Configuration:**
```yaml
Resources:
  Function:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: process-order
      Runtime: python3.11
      Handler: lambda_function.lambda_handler
      Code:
        S3Bucket: my-lambda-code
        S3Key: function.zip
      Role: !GetAtt LambdaExecutionRole.Arn
      Timeout: 30
      MemorySize: 512
      Environment:
        Variables:
          TABLE_NAME: !Ref DynamoDBTable
          ENVIRONMENT: production
      ReservedConcurrentExecutions: 100
      DeadLetterConfig:
        TargetArn: !GetAtt DLQueue.Arn
      VpcConfig:
        SecurityGroupIds:
          - !Ref LambdaSecurityGroup
        SubnetIds:
          - !Ref PrivateSubnet1
          - !Ref PrivateSubnet2

  # Trigger from API Gateway
  ApiGatewayInvokePermission:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref Function
      Action: lambda:InvokeFunction
      Principal: apigateway.amazonaws.com
      SourceArn: !Sub arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${ApiGateway}/*

  # Auto-scaling (Provisioned Concurrency)
  ProvisionedConcurrency:
    Type: AWS::Lambda::Alias
    Properties:
      FunctionName: !Ref Function
      FunctionVersion: !GetAtt FunctionVersion.Version
      Name: live
      ProvisionedConcurrencyConfig:
        ProvisionedConcurrentExecutions: 5
```

**Event Sources:**
```
Synchronous (wait for response):
- API Gateway (REST/HTTP API)
- ALB (Application Load Balancer)
- Cognito
- Alexa
- CloudFront (Lambda@Edge)

Asynchronous (fire and forget):
- S3 (object created/deleted)
- SNS (message published)
- EventBridge (scheduled/event-driven)
- SES (email received)
- CloudFormation (custom resources)

Stream-based (batch processing):
- DynamoDB Streams
- Kinesis Data Streams
- SQS (polling)
- Kafka (MSK)
```

**Cold Start Optimization:**
```python
# Initialize outside handler (reused across invocations)
import boto3
import os

# Initialize clients once
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
s3 = boto3.client('s3')

# Global variables reused
CACHE = {}

def lambda_handler(event, context):
    """
    This runs on each invocation
    """
    # Use pre-initialized clients
    result = table.get_item(Key={'id': event['id']})

    # Use cache
    if event['id'] in CACHE:
        return CACHE[event['id']]

    # Process and cache
    data = process(result)
    CACHE[event['id']] = data
    return data
```

**Provisioned Concurrency (Eliminate Cold Starts):**
```
Regular Lambda:
- Cold start: 100-1000ms (first request)
- Warm start: <10ms (subsequent requests)

Provisioned Concurrency:
- Pre-initialized instances always warm
- No cold starts
- Additional cost (~$0.015/hour per instance)
- Use for latency-sensitive APIs
```

**When to Use Lambda:**
- Event-driven workloads
- Microservices/API backends
- Scheduled tasks (cron jobs)
- Data transformation (ETL)
- Variable/unpredictable load
- Short-lived tasks (< 15 minutes)

**Pros:**
- No server management
- Auto-scaling (zero to millions)
- Pay-per-use (very cost-effective for low/variable traffic)
- Fast deployment
- Built-in high availability

**Cons:**
- 15-minute execution limit
- Cold starts (latency)
- Stateless (need external state)
- Limited runtime options
- Difficult to debug/test
- Vendor lock-in (AWS-specific)

---

## 2. Load Balancing

### Application Load Balancer (ALB)

**Description:** Layer 7 (HTTP/HTTPS) load balancer. Routes traffic based on content (path, headers, query strings).

**Key Features:**
- HTTP/HTTPS/HTTP2 support
- WebSocket support
- Path-based routing (`/api/*` → Service A, `/images/*` → Service B)
- Host-based routing (`api.example.com` → API, `www.example.com` → Web)
- Query string routing
- Header-based routing
- Fixed response (return static response)
- Redirect (301/302)
- Authentication (Cognito, OIDC)
- Slow start mode
- Sticky sessions (cookie-based)

**Architecture:**
```
                  Internet
                      │
              ┌───────▼────────┐
              │      ALB       │
              │  (Multi-AZ)    │
              └───────┬────────┘
                      │
          ┌───────────┼───────────┐
          │                       │
    ┌─────▼──────┐          ┌─────▼──────┐
    │  Target    │          │  Target    │
    │  Group 1   │          │  Group 2   │
    │            │          │            │
    │ /api/*     │          │ /web/*     │
    └─────┬──────┘          └─────┬──────┘
          │                       │
    ┌─────┴──────┐          ┌─────┴──────┐
    │   ECS      │          │   ECS      │
    │ Task 1-4   │          │ Task 1-4   │
    └────────────┘          └────────────┘
```

**CloudFormation Configuration:**
```yaml
Resources:
  ALB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: web-alb
      Type: application
      Scheme: internet-facing
      IpAddressType: ipv4
      SecurityGroups:
        - !Ref ALBSecurityGroup
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      Tags:
        - Key: Name
          Value: web-alb

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: web-targets
      Port: 80
      Protocol: HTTP
      VpcId: !Ref VPC
      TargetType: ip  # for Fargate, or 'instance' for EC2
      HealthCheckEnabled: true
      HealthCheckProtocol: HTTP
      HealthCheckPath: /health
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 3
      Matcher:
        HttpCode: 200-299
      TargetGroupAttributes:
        - Key: deregistration_delay.timeout_seconds
          Value: 30
        - Key: stickiness.enabled
          Value: true
        - Key: stickiness.type
          Value: lb_cookie
        - Key: stickiness.lb_cookie.duration_seconds
          Value: 86400

  Listener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref ALB
      Port: 443
      Protocol: HTTPS
      SslPolicy: ELBSecurityPolicy-TLS-1-2-2017-01
      Certificates:
        - CertificateArn: !Ref Certificate
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup

  # Path-based routing
  ApiListenerRule:
    Type: AWS::ElasticLoadBalancingV2::ListenerRule
    Properties:
      ListenerArn: !Ref Listener
      Priority: 1
      Conditions:
        - Field: path-pattern
          Values:
            - /api/*
      Actions:
        - Type: forward
          TargetGroupArn: !Ref ApiTargetGroup

  # Host-based routing
  AdminListenerRule:
    Type: AWS::ElasticLoadBalancingV2::ListenerRule
    Properties:
      ListenerArn: !Ref Listener
      Priority: 2
      Conditions:
        - Field: host-header
          Values:
            - admin.example.com
      Actions:
        - Type: forward
          TargetGroupArn: !Ref AdminTargetGroup

  # Fixed response (maintenance mode)
  MaintenanceRule:
    Type: AWS::ElasticLoadBalancingV2::ListenerRule
    Properties:
      ListenerArn: !Ref Listener
      Priority: 3
      Conditions:
        - Field: path-pattern
          Values:
            - /maintenance
      Actions:
        - Type: fixed-response
          FixedResponseConfig:
            StatusCode: 503
            ContentType: text/html
            MessageBody: |
              <html><body><h1>Under Maintenance</h1></body></html>
```

**Health Checks:**
```
Configuration:
- Path: /health
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2 consecutive successes
- Unhealthy threshold: 3 consecutive failures

Target marked healthy:
- Receives traffic

Target marked unhealthy:
- Removed from rotation
- Continues health checks
- Added back when healthy
```

---

### Network Load Balancer (NLB)

**Description:** Layer 4 (TCP/UDP/TLS) load balancer. Ultra-high performance, preserves source IP, supports static IPs.

**Key Features:**
- Millions of requests per second
- Ultra-low latency (~100 microseconds)
- Static IP addresses (one per AZ)
- Preserves source IP
- TCP, UDP, TLS support
- PrivateLink support
- Zonal isolation

**When to Use NLB:**
- Non-HTTP protocols (TCP, UDP)
- Need static IPs
- Extreme performance requirements
- Preserve source IP address
- gRPC applications
- Gaming servers
- IoT applications

**Configuration:**
```yaml
Resources:
  NLB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: api-nlb
      Type: network
      Scheme: internet-facing
      IpAddressType: ipv4
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: api-targets
      Port: 443
      Protocol: TCP
      VpcId: !Ref VPC
      TargetType: ip
      HealthCheckEnabled: true
      HealthCheckProtocol: TCP
      HealthCheckIntervalSeconds: 30
      HealthyThresholdCount: 3
      UnhealthyThresholdCount: 3

  Listener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref NLB
      Port: 443
      Protocol: TCP
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup
```

---

### Gateway Load Balancer (GWLB)

**Description:** Layer 3 (network/IP) load balancer for deploying, scaling, and managing third-party virtual appliances (firewalls, IDS/IPS).

**Use Cases:**
- Firewall appliances
- Intrusion detection/prevention systems
- Deep packet inspection
- Network traffic analysis

---

## 3. Auto Scaling

### EC2 Auto Scaling

**Description:** Automatically adjusts EC2 instance count based on demand. Maintains application availability and optimizes costs.

**Scaling Policies:**

**Target Tracking:**
```yaml
# Scale to maintain target metric
ScalingPolicy:
  Type: AWS::AutoScaling::ScalingPolicy
  Properties:
    AutoScalingGroupName: !Ref AutoScalingGroup
    PolicyType: TargetTrackingScaling
    TargetTrackingConfiguration:
      PredefinedMetricSpecification:
        PredefinedMetricType: ASGAverageCPUUtilization
      TargetValue: 70.0

# Available metrics:
# - ASGAverageCPUUtilization
# - ASGAverageNetworkIn
# - ASGAverageNetworkOut
# - ALBRequestCountPerTarget
```

**Step Scaling:**
```yaml
# Add capacity in steps based on alarm
ScaleUpPolicy:
  Type: AWS::AutoScaling::ScalingPolicy
  Properties:
    AutoScalingGroupName: !Ref AutoScalingGroup
    PolicyType: StepScaling
    AdjustmentType: ChangeInCapacity
    MetricAggregationType: Average
    StepAdjustments:
      - MetricIntervalLowerBound: 0
        MetricIntervalUpperBound: 10
        ScalingAdjustment: 1
      - MetricIntervalLowerBound: 10
        MetricIntervalUpperBound: 20
        ScalingAdjustment: 2
      - MetricIntervalLowerBound: 20
        ScalingAdjustment: 3

# Example:
# CPU 70-80%: Add 1 instance
# CPU 80-90%: Add 2 instances
# CPU 90%+: Add 3 instances
```

**Scheduled Scaling:**
```yaml
# Scale at specific times
ScheduledAction:
  Type: AWS::AutoScaling::ScheduledAction
  Properties:
    AutoScalingGroupName: !Ref AutoScalingGroup
    DesiredCapacity: 20
    MinSize: 10
    MaxSize: 30
    Recurrence: "0 9 * * MON-FRI"  # 9 AM weekdays

# Scale down at night
NightSchedule:
  Type: AWS::AutoScaling::ScheduledAction
  Properties:
    AutoScalingGroupName: !Ref AutoScalingGroup
    DesiredCapacity: 4
    MinSize: 2
    MaxSize: 10
    Recurrence: "0 20 * * *"  # 8 PM daily
```

**Predictive Scaling:**
```
AWS analyzes historical load patterns
Predicts future traffic
Pre-scales before traffic arrives
Useful for regular patterns (daily/weekly cycles)
```

---

### ECS Service Auto Scaling

**Description:** Automatically adjusts ECS task count based on CloudWatch metrics.

**Target Tracking:**
```yaml
ScalableTarget:
  Type: AWS::ApplicationAutoScaling::ScalableTarget
  Properties:
    MaxCapacity: 10
    MinCapacity: 2
    ResourceId: !Sub service/${ECSCluster}/${ECSService.Name}
    RoleARN: !GetAtt AutoScalingRole.Arn
    ScalableDimension: ecs:service:DesiredCount
    ServiceNamespace: ecs

CPUScaling:
  Type: AWS::ApplicationAutoScaling::ScalingPolicy
  Properties:
    PolicyName: cpu-scaling
    PolicyType: TargetTrackingScaling
    ScalingTargetId: !Ref ScalableTarget
    TargetTrackingScalingPolicyConfiguration:
      PredefinedMetricSpecification:
        PredefinedMetricType: ECSServiceAverageCPUUtilization
      TargetValue: 70.0
      ScaleInCooldown: 300
      ScaleOutCooldown: 60

MemoryScaling:
  Type: AWS::ApplicationAutoScaling::ScalingPolicy
  Properties:
    PolicyName: memory-scaling
    PolicyType: TargetTrackingScaling
    ScalingTargetId: !Ref ScalableTarget
    TargetTrackingScalingPolicyConfiguration:
      PredefinedMetricSpecification:
        PredefinedMetricType: ECSServiceAverageMemoryUtilization
      TargetValue: 80.0

ALBRequestScaling:
  Type: AWS::ApplicationAutoScaling::ScalingPolicy
  Properties:
    PolicyName: alb-request-scaling
    PolicyType: TargetTrackingScaling
    ScalingTargetId: !Ref ScalableTarget
    TargetTrackingScalingPolicyConfiguration:
      PredefinedMetricSpecification:
        PredefinedMetricType: ALBRequestCountPerTarget
        ResourceLabel: !Sub
          - "${LB}/${TG}"
          - LB: !GetAtt ALB.LoadBalancerFullName
            TG: !GetAtt TargetGroup.TargetGroupFullName
      TargetValue: 1000.0  # 1000 requests per target
```

---

### Kubernetes HPA (Horizontal Pod Autoscaler)

**Description:** Automatically scales pod replicas based on CPU, memory, or custom metrics.

**CPU/Memory Scaling:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
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

**Custom Metrics (SQS Queue Length):**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: worker-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: worker
  minReplicas: 1
  maxReplicas: 50
  metrics:
  - type: External
    external:
      metric:
        name: sqs_queue_messages_visible
        selector:
          matchLabels:
            queue_name: my-queue
      target:
        type: AverageValue
        averageValue: "30"  # 30 messages per pod
```

**Cluster Autoscaler (Node Scaling):**
```yaml
# Automatically adds/removes nodes based on pod scheduling needs
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.25.0
        name: cluster-autoscaler
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/my-cluster
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
```

---

## 4. Service Mesh

### What is a Service Mesh?

**Description:** Infrastructure layer that handles service-to-service communication in microservices. Provides observability, traffic management, security without changing application code.

**Key Capabilities:**
- **Traffic Management:** Load balancing, retries, timeouts, circuit breaking
- **Security:** mTLS encryption, authentication, authorization
- **Observability:** Metrics, logs, distributed tracing
- **Resilience:** Retries, timeouts, circuit breakers, rate limiting

### AWS App Mesh

**Description:** AWS-managed service mesh for microservices on ECS, EKS, EC2, and Fargate.

**Architecture:**
```
Service A                Service B
┌─────────┐             ┌─────────┐
│ App     │             │ App     │
│Container│             │Container│
└────┬────┘             └────┬────┘
     │                       │
┌────▼────┐             ┌────▼────┐
│ Envoy   │◄──────────►│ Envoy   │
│ Proxy   │   mTLS     │ Proxy   │
└────┬────┘             └────┬────┘
     │                       │
     └───────────┬───────────┘
                 │
          ┌──────▼──────┐
          │  App Mesh   │
          │ Control     │
          │   Plane     │
          └─────────────┘
```

**App Mesh Configuration:**
```yaml
# Virtual Service (logical name for service)
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualService
metadata:
  name: web-service
  namespace: production
spec:
  awsName: web-service.production.svc.cluster.local
  provider:
    virtualRouter:
      virtualRouterRef:
        name: web-router

# Virtual Router (routes traffic)
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualRouter
metadata:
  name: web-router
  namespace: production
spec:
  listeners:
    - portMapping:
        port: 80
        protocol: http
  routes:
    - name: web-route
      httpRoute:
        match:
          prefix: /
        action:
          weightedTargets:
            - virtualNodeRef:
                name: web-v1
              weight: 90
            - virtualNodeRef:
                name: web-v2
              weight: 10  # Canary 10% traffic

# Virtual Node (actual service endpoints)
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualNode
metadata:
  name: web-v1
  namespace: production
spec:
  awsName: web-v1
  podSelector:
    matchLabels:
      app: web
      version: v1
  listeners:
    - portMapping:
        port: 80
        protocol: http
      healthCheck:
        protocol: http
        path: /health
        healthyThreshold: 2
        unhealthyThreshold: 2
        timeoutMillis: 2000
        intervalMillis: 5000
  serviceDiscovery:
    dns:
      hostname: web-v1.production.svc.cluster.local
  backends:
    - virtualService:
        virtualServiceRef:
          name: api-service
```

**Traffic Policies:**
```yaml
# Retry policy
httpRoute:
  match:
    prefix: /api
  action:
    weightedTargets:
      - virtualNodeRef:
          name: api-service
        weight: 100
  retryPolicy:
    maxRetries: 3
    perRetryTimeout:
      value: 2
      unit: s
    httpRetryEvents:
      - server-error
      - gateway-error
    tcpRetryEvents:
      - connection-error

# Timeout policy
httpRoute:
  match:
    prefix: /slow
  timeout:
    perRequest:
      value: 15
      unit: s
    idle:
      value: 30
      unit: s
```

---

### Istio (Open Source Service Mesh)

**Description:** Popular open-source service mesh for Kubernetes. More feature-rich than App Mesh but more complex.

**Traffic Management:**
```yaml
# Virtual Service (routing rules)
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: web-service
spec:
  hosts:
  - web-service
  http:
  - match:
    - headers:
        user-agent:
          regex: ".*Mobile.*"
    route:
    - destination:
        host: web-service
        subset: mobile
  - route:
    - destination:
        host: web-service
        subset: desktop

# Destination Rule (traffic policies per subset)
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: web-service
spec:
  host: web-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 1
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
    loadBalancer:
      simple: LEAST_REQUEST
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
```

**Circuit Breaker:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-circuit-breaker
spec:
  host: api-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutiveErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
```

---

## 5. Interview Tips

### Discussing Compute Layer

**Structure:**

1. **Start with requirements:**
   - "Given we need to run containerized microservices with auto-scaling..."

2. **Compare options:**
   - "We could use ECS Fargate for serverless containers, or EKS for Kubernetes..."

3. **Make recommendation:**
   - "I'd choose ECS Fargate because team doesn't have Kubernetes expertise, and we want minimal operational overhead..."

4. **Discuss scaling:**
   - "ECS service auto-scaling based on CPU and ALB request count..."

5. **Load balancing:**
   - "Application Load Balancer for path-based routing to microservices..."

**Trade-offs:**
- EC2 vs Containers vs Lambda (control vs management)
- ECS vs EKS (simplicity vs features)
- Fargate vs EC2 (cost vs control)
- ALB vs NLB (features vs performance)

---

## Summary

**Key Takeaways:**

1. **EC2:** Maximum control, manual management, good for legacy/custom workloads
2. **ECS:** AWS-native containers, simpler than K8s, Fargate option
3. **EKS:** Managed Kubernetes, portable, powerful but complex
4. **Lambda:** Serverless, auto-scaling, event-driven, 15-min limit
5. **ALB:** Layer 7, content-based routing, best for HTTP/HTTPS
6. **NLB:** Layer 4, ultra-high performance, static IPs
7. **Auto Scaling:** Target tracking simplest, scheduled for predictable patterns
8. **Service Mesh:** App Mesh or Istio for microservices observability and traffic management

**Choose based on:**
- Team expertise
- Operational complexity tolerance
- Performance requirements
- Cost constraints
- Portability needs

The compute layer is where your business logic runs. Choose the right compute option and scaling strategy to build reliable, cost-effective systems!
