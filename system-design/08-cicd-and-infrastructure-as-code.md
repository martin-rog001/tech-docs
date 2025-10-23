# CI/CD & Infrastructure as Code - System Design Cheatsheet

## Overview

**CI/CD** (Continuous Integration/Continuous Deployment) automates the software delivery process from code commit to production deployment.

**Infrastructure as Code (IaC)** manages infrastructure using code rather than manual processes.

### Benefits

- **Speed**: Deploy multiple times per day
- **Reliability**: Automated testing catches bugs early
- **Repeatability**: Consistent deployments across environments
- **Rollback**: Quick recovery from failures
- **Auditability**: Track all changes in version control

---

## 1. CI/CD Pipeline Stages

### Typical Pipeline Flow

```
Code Commit → Build → Unit Tests → Integration Tests → Security Scan →
Staging Deploy → E2E Tests → Production Deploy → Smoke Tests → Monitor
```

### Example Pipeline Configuration

#### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: myapp
  ECS_CLUSTER: production
  ECS_SERVICE: web-app

jobs:
  # Stage 1: Build and Test
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Unit tests
        run: npm test -- --coverage

      - name: Build
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build
          path: dist/

  # Stage 2: Security Scanning
  security:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v3

      - name: Run Snyk vulnerability scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

      - name: Run Trivy container scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'

  # Stage 3: Build Docker Image
  docker:
    runs-on: ubuntu-latest
    needs: [build, security]
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

  # Stage 4: Deploy to Staging
  deploy-staging:
    runs-on: ubuntu-latest
    needs: docker
    environment: staging
    steps:
      - name: Deploy to ECS Staging
        run: |
          aws ecs update-service \
            --cluster staging \
            --service web-app \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster staging \
            --services web-app

  # Stage 5: Integration Tests
  integration-tests:
    runs-on: ubuntu-latest
    needs: deploy-staging
    steps:
      - uses: actions/checkout@v3

      - name: Run integration tests
        run: npm run test:integration
        env:
          API_URL: https://staging.example.com

      - name: Run E2E tests
        uses: cypress-io/github-action@v5
        with:
          config: baseUrl=https://staging.example.com

  # Stage 6: Deploy to Production
  deploy-production:
    runs-on: ubuntu-latest
    needs: integration-tests
    environment: production
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to ECS Production
        run: |
          aws ecs update-service \
            --cluster production \
            --service web-app \
            --force-new-deployment \
            --deployment-configuration "minimumHealthyPercent=100,maximumPercent=200"

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster production \
            --services web-app

  # Stage 7: Smoke Tests
  smoke-tests:
    runs-on: ubuntu-latest
    needs: deploy-production
    steps:
      - name: Health check
        run: |
          for i in {1..5}; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.example.com/health)
            if [ $STATUS -eq 200 ]; then
              echo "Health check passed"
              exit 0
            fi
            echo "Health check failed, retrying..."
            sleep 10
          done
          exit 1

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment to production successful! :rocket:",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "Deployment *${{ github.sha }}* to production completed successfully"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

#### AWS CodePipeline

```yaml
# CloudFormation template for CodePipeline
Resources:
  Pipeline:
    Type: AWS::CodePipeline::Pipeline
    Properties:
      Name: MyAppPipeline
      RoleArn: !GetAtt PipelineRole.Arn
      ArtifactStore:
        Type: S3
        Location: !Ref ArtifactBucket
      Stages:
        # Stage 1: Source
        - Name: Source
          Actions:
            - Name: SourceAction
              ActionTypeId:
                Category: Source
                Owner: AWS
                Provider: CodeCommit
                Version: 1
              OutputArtifacts:
                - Name: SourceOutput
              Configuration:
                RepositoryName: myapp
                BranchName: main

        # Stage 2: Build
        - Name: Build
          Actions:
            - Name: BuildAction
              ActionTypeId:
                Category: Build
                Owner: AWS
                Provider: CodeBuild
                Version: 1
              InputArtifacts:
                - Name: SourceOutput
              OutputArtifacts:
                - Name: BuildOutput
              Configuration:
                ProjectName: !Ref CodeBuildProject

        # Stage 3: Deploy to Staging
        - Name: DeployStaging
          Actions:
            - Name: DeployToStaging
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: ECS
                Version: 1
              InputArtifacts:
                - Name: BuildOutput
              Configuration:
                ClusterName: staging
                ServiceName: web-app

        # Stage 4: Manual Approval
        - Name: ApprovalForProduction
          Actions:
            - Name: ManualApproval
              ActionTypeId:
                Category: Approval
                Owner: AWS
                Provider: Manual
                Version: 1
              Configuration:
                CustomData: "Please review staging deployment before promoting to production"
                NotificationArn: !Ref ApprovalTopic

        # Stage 5: Deploy to Production
        - Name: DeployProduction
          Actions:
            - Name: DeployToProduction
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: CodeDeployToECS
                Version: 1
              InputArtifacts:
                - Name: BuildOutput
              Configuration:
                ApplicationName: myapp
                DeploymentGroupName: production
                TaskDefinitionTemplateArtifact: BuildOutput
                AppSpecTemplateArtifact: BuildOutput

  # CodeBuild project
  CodeBuildProject:
    Type: AWS::CodeBuild::Project
    Properties:
      Name: MyAppBuild
      ServiceRole: !GetAtt CodeBuildRole.Arn
      Artifacts:
        Type: CODEPIPELINE
      Environment:
        Type: LINUX_CONTAINER
        ComputeType: BUILD_GENERAL1_SMALL
        Image: aws/codebuild/standard:5.0
        PrivilegedMode: true
        EnvironmentVariables:
          - Name: AWS_ACCOUNT_ID
            Value: !Ref AWS::AccountId
          - Name: IMAGE_REPO_NAME
            Value: myapp
      Source:
        Type: CODEPIPELINE
        BuildSpec: |
          version: 0.2
          phases:
            pre_build:
              commands:
                - echo Logging in to Amazon ECR...
                - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
                - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
                - IMAGE_TAG=${COMMIT_HASH:=latest}
            build:
              commands:
                - echo Build started on `date`
                - npm ci
                - npm test
                - npm run build
                - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
                - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
            post_build:
              commands:
                - echo Pushing Docker image...
                - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
                - printf '[{"name":"web-app","imageUri":"%s"}]' $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG > imagedefinitions.json
          artifacts:
            files: imagedefinitions.json
```

---

## 2. Infrastructure as Code (IaC)

### Terraform

#### Project Structure

```
terraform/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── rds/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
└── backend.tf
```

#### Example: VPC Module

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-${count.index + 1}"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-private-${count.index + 1}"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.environment}-nat-${count.index + 1}"
    Environment = var.environment
  }
}

# modules/vpc/variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
```

#### Example: ECS Module

```hcl
# modules/ecs/main.tf
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "LOG_LEVEL"
          value = var.log_level
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.environment}-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.app]

  tags = {
    Environment = var.environment
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
```

#### Environment-specific Configuration

```hcl
# environments/production/main.tf
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  environment        = "production"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

module "ecs" {
  source = "../../modules/ecs"

  environment         = "production"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  ecr_repository_url  = var.ecr_repository_url
  image_tag           = var.image_tag
  desired_count       = 6
  min_capacity        = 3
  max_capacity        = 20
  task_cpu            = "1024"
  task_memory         = "2048"
}

module "rds" {
  source = "../../modules/rds"

  environment           = "production"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  instance_class        = "db.r5.xlarge"
  allocated_storage     = 100
  multi_az              = true
  backup_retention_days = 30
}

# environments/production/terraform.tfvars
aws_region         = "us-east-1"
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp"
image_tag          = "v1.2.3"
```

#### Terraform Commands

```bash
# Initialize
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy infrastructure
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Workspace management (for environments)
terraform workspace list
terraform workspace new staging
terraform workspace select production
```

### AWS CloudFormation

```yaml
# cloudformation/application-stack.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'ECS Application Stack'

Parameters:
  Environment:
    Type: String
    Default: production
    AllowedValues:
      - staging
      - production

  ImageTag:
    Type: String
    Description: Docker image tag

  DesiredCount:
    Type: Number
    Default: 3
    Description: Desired number of tasks

Mappings:
  EnvironmentConfig:
    staging:
      TaskCPU: 512
      TaskMemory: 1024
      MinCapacity: 2
      MaxCapacity: 10
    production:
      TaskCPU: 1024
      TaskMemory: 2048
      MinCapacity: 3
      MaxCapacity: 20

Resources:
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub '${Environment}-cluster'
      ClusterSettings:
        - Name: containerInsights
          Value: enabled

  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Sub '${Environment}-app'
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      Cpu: !FindInMap [EnvironmentConfig, !Ref Environment, TaskCPU]
      Memory: !FindInMap [EnvironmentConfig, !Ref Environment, TaskMemory]
      ExecutionRoleArn: !GetAtt ExecutionRole.Arn
      TaskRoleArn: !GetAtt TaskRole.Arn
      ContainerDefinitions:
        - Name: app
          Image: !Sub '${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/myapp:${ImageTag}'
          Essential: true
          PortMappings:
            - ContainerPort: 8080
              Protocol: tcp
          Environment:
            - Name: ENVIRONMENT
              Value: !Ref Environment
          Secrets:
            - Name: DB_PASSWORD
              ValueFrom: !Ref DBPasswordSecret
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref LogGroup
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: ecs

  ECSService:
    Type: AWS::ECS::Service
    DependsOn: ALBListener
    Properties:
      ServiceName: !Sub '${Environment}-app-service'
      Cluster: !Ref ECSCluster
      TaskDefinition: !Ref TaskDefinition
      DesiredCount: !Ref DesiredCount
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          Subnets:
            - !ImportValue 'VPC-PrivateSubnet1'
            - !ImportValue 'VPC-PrivateSubnet2'
          SecurityGroups:
            - !Ref ECSSecurityGroup
      LoadBalancers:
        - ContainerName: app
          ContainerPort: 8080
          TargetGroupArn: !Ref TargetGroup
      DeploymentConfiguration:
        MaximumPercent: 200
        MinimumHealthyPercent: 100
        DeploymentCircuitBreaker:
          Enable: true
          Rollback: true

  # Auto Scaling
  AutoScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: !FindInMap [EnvironmentConfig, !Ref Environment, MaxCapacity]
      MinCapacity: !FindInMap [EnvironmentConfig, !Ref Environment, MinCapacity]
      ResourceId: !Sub 'service/${ECSCluster}/${ECSService.Name}'
      ScalableDimension: ecs:service:DesiredCount
      ServiceNamespace: ecs
      RoleARN: !Sub 'arn:aws:iam::${AWS::AccountId}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService'

  AutoScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: !Sub '${Environment}-cpu-scaling'
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref AutoScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        TargetValue: 70.0
        ScaleInCooldown: 300
        ScaleOutCooldown: 60

Outputs:
  ClusterName:
    Description: ECS Cluster Name
    Value: !Ref ECSCluster
    Export:
      Name: !Sub '${Environment}-ClusterName'

  ServiceName:
    Description: ECS Service Name
    Value: !GetAtt ECSService.Name
    Export:
      Name: !Sub '${Environment}-ServiceName'
```

```bash
# Deploy stack
aws cloudformation deploy \
  --template-file application-stack.yaml \
  --stack-name production-app \
  --parameter-overrides \
    Environment=production \
    ImageTag=v1.2.3 \
    DesiredCount=6 \
  --capabilities CAPABILITY_IAM

# Update stack
aws cloudformation update-stack \
  --stack-name production-app \
  --use-previous-template \
  --parameters ParameterKey=ImageTag,ParameterValue=v1.2.4

# Delete stack
aws cloudformation delete-stack --stack-name production-app

# Detect drift
aws cloudformation detect-stack-drift --stack-name production-app
```

---

## 3. GitOps

### ArgoCD

```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/mycompany/myapp
    targetRevision: main
    path: k8s/overlays/production

  destination:
    server: https://kubernetes.default.svc
    namespace: production

  syncPolicy:
    automated:
      prune: true      # Delete resources not in git
      selfHeal: true   # Force sync if cluster state differs
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m

  # Health checks
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas  # Ignore replica differences (HPA controls this)
```

#### Kustomize Structure

```
k8s/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
└── overlays/
    ├── staging/
    │   ├── kustomization.yaml
    │   └── patches.yaml
    └── production/
        ├── kustomization.yaml
        └── patches.yaml
```

```yaml
# k8s/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: web-app

# k8s/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: app
        image: myapp:latest
        ports:
        - containerPort: 8080
        env:
        - name: LOG_LEVEL
          value: info
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi

# k8s/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namePrefix: prod-

replicas:
  - name: web-app
    count: 10

images:
  - name: myapp
    newName: 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp
    newTag: v1.2.3

patches:
  - path: patches.yaml

# k8s/overlays/production/patches.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: LOG_LEVEL
          value: warn
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 2000m
            memory: 2Gi
```

### Flux CD

```yaml
# flux/production/kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: web-app
  namespace: flux-system
spec:
  interval: 5m
  path: ./k8s/overlays/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: myapp
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: web-app
      namespace: production
  timeout: 5m

# Image automation
---
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageRepository
metadata:
  name: myapp
  namespace: flux-system
spec:
  image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp
  interval: 1m

---
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImagePolicy
metadata:
  name: myapp
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: myapp
  policy:
    semver:
      range: 1.x.x  # Only auto-update patch versions

---
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: myapp
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxcd@example.com
        name: Flux CD
      messageTemplate: "Update image to {{range .Updated.Images}}{{println .}}{{end}}"
    push:
      branch: main
  update:
    path: ./k8s/overlays/production
    strategy: Setters
```

---

## 4. Automated Rollbacks

### AWS CodeDeploy

```yaml
# appspec.yml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "arn:aws:ecs:region:account:task-definition/app:REVISION"
        LoadBalancerInfo:
          ContainerName: "app"
          ContainerPort: 8080
        PlatformVersion: "LATEST"

Hooks:
  - BeforeInstall: "LambdaFunctionToValidateBeforeInstall"
  - AfterInstall: "LambdaFunctionToValidateAfterInstall"
  - AfterAllowTestTraffic: "LambdaFunctionToRunTestsOnTestTraffic"
  - BeforeAllowTraffic: "LambdaFunctionToValidateBeforeAllowingProductionTraffic"
  - AfterAllowTraffic: "LambdaFunctionToValidateAfterAllowingProductionTraffic"
```

```python
# Lambda hook for automated rollback
import boto3
import json

cloudwatch = boto3.client('cloudwatch')
codedeploy = boto3.client('codedeploy')

def lambda_handler(event, context):
    deployment_id = event['DeploymentId']
    lifecycle_event_hook_execution_id = event['LifecycleEventHookExecutionId']

    # Check metrics
    try:
        # Get error rate for last 5 minutes
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/ApplicationELB',
            MetricName='HTTPCode_Target_5XX_Count',
            Dimensions=[
                {'Name': 'LoadBalancer', 'Value': 'app/my-alb/123'}
            ],
            StartTime=datetime.now() - timedelta(minutes=5),
            EndTime=datetime.now(),
            Period=300,
            Statistics=['Sum']
        )

        errors = sum(dp['Sum'] for dp in response['Datapoints'])

        # Also check total requests
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/ApplicationELB',
            MetricName='RequestCount',
            Dimensions=[
                {'Name': 'LoadBalancer', 'Value': 'app/my-alb/123'}
            ],
            StartTime=datetime.now() - timedelta(minutes=5),
            EndTime=datetime.now(),
            Period=300,
            Statistics=['Sum']
        )

        total = sum(dp['Sum'] for dp in response['Datapoints'])

        # Calculate error rate
        error_rate = (errors / total * 100) if total > 0 else 0

        # Rollback if error rate > 1%
        if error_rate > 1.0:
            print(f"Error rate {error_rate}% exceeds threshold, failing deployment")
            codedeploy.put_lifecycle_event_hook_execution_status(
                DeploymentId=deployment_id,
                LifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
                Status='Failed'
            )
            return {'statusCode': 200, 'body': 'Deployment failed due to high error rate'}

        # Success
        print(f"Error rate {error_rate}% is acceptable")
        codedeploy.put_lifecycle_event_hook_execution_status(
            DeploymentId=deployment_id,
            LifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
            Status='Succeeded'
        )
        return {'statusCode': 200, 'body': 'Deployment validation passed'}

    except Exception as e:
        print(f"Error validating deployment: {str(e)}")
        codedeploy.put_lifecycle_event_hook_execution_status(
            DeploymentId=deployment_id,
            LifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
            Status='Failed'
        )
        return {'statusCode': 500, 'body': str(e)}
```

### Kubernetes with Argo Rollouts

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 2m}
      - setWeight: 20
      - pause: {duration: 2m}
      - setWeight: 50
      - pause: {duration: 5m}
      - setWeight: 100

      # Automated rollback based on metrics
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 1
        args:
        - name: service-name
          value: web-app

      # Manual rollback with CLI
      abortScaleDownDelaySeconds: 30

  revisionHistoryLimit: 5
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: app
        image: myapp:v1.2.3
        ports:
        - containerPort: 8080

---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 1m
    count: 5
    successCondition: result >= 0.99
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status!~"5.."}[1m]))
          /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[1m]))
```

```bash
# Manual rollback
kubectl argo rollouts abort web-app
kubectl argo rollouts undo web-app

# Promote canary
kubectl argo rollouts promote web-app

# Watch rollout status
kubectl argo rollouts get rollout web-app --watch
```

---

## 5. Testing in CI/CD

### Test Pyramid

```
      /\
     /  \    E2E Tests (10%)
    /____\
   /      \  Integration Tests (30%)
  /________\
 /          \ Unit Tests (60%)
/____________\
```

### Unit Tests

```javascript
// test/unit/orderService.test.js
const { createOrder } = require('../../src/services/orderService');
const { PaymentService } = require('../../src/services/paymentService');

jest.mock('../../src/services/paymentService');

describe('OrderService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('createOrder should charge payment and save order', async () => {
    // Arrange
    const mockPayment = { id: 'pay_123', status: 'succeeded' };
    PaymentService.charge.mockResolvedValue(mockPayment);

    const orderData = {
      userId: 'user_123',
      items: [{ productId: 'prod_456', quantity: 2 }],
      amount: 99.99
    };

    // Act
    const result = await createOrder(orderData);

    // Assert
    expect(PaymentService.charge).toHaveBeenCalledWith({
      userId: 'user_123',
      amount: 99.99
    });
    expect(result).toMatchObject({
      orderId: expect.any(String),
      status: 'confirmed',
      paymentId: 'pay_123'
    });
  });

  test('createOrder should rollback on payment failure', async () => {
    // Arrange
    PaymentService.charge.mockRejectedValue(new Error('Payment failed'));

    const orderData = {
      userId: 'user_123',
      items: [{ productId: 'prod_456', quantity: 2 }],
      amount: 99.99
    };

    // Act & Assert
    await expect(createOrder(orderData)).rejects.toThrow('Payment failed');
  });
});
```

### Integration Tests

```javascript
// test/integration/api.test.js
const request = require('supertest');
const app = require('../../src/app');
const db = require('../../src/db');

describe('API Integration Tests', () => {
  beforeAll(async () => {
    await db.connect(process.env.TEST_DATABASE_URL);
  });

  afterAll(async () => {
    await db.disconnect();
  });

  beforeEach(async () => {
    await db.truncateAll();
  });

  test('POST /api/orders should create order', async () => {
    // Create test user
    const user = await db.users.create({
      email: 'test@example.com',
      name: 'Test User'
    });

    // Get auth token
    const authResponse = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'password' });

    const token = authResponse.body.token;

    // Create order
    const response = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({
        items: [{ productId: 'prod_123', quantity: 2 }]
      });

    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      orderId: expect.any(String),
      status: 'pending',
      totalAmount: expect.any(Number)
    });

    // Verify in database
    const order = await db.orders.findById(response.body.orderId);
    expect(order).toBeDefined();
    expect(order.userId).toBe(user.id);
  });
});
```

### E2E Tests (Cypress)

```javascript
// cypress/e2e/checkout.cy.js
describe('Checkout Flow', () => {
  beforeEach(() => {
    // Reset database
    cy.task('db:seed');

    // Login
    cy.visit('/login');
    cy.get('[data-cy=email]').type('test@example.com');
    cy.get('[data-cy=password]').type('password');
    cy.get('[data-cy=submit]').click();

    cy.url().should('include', '/dashboard');
  });

  it('should complete checkout successfully', () => {
    // Add item to cart
    cy.visit('/products/prod_123');
    cy.get('[data-cy=add-to-cart]').click();
    cy.get('[data-cy=cart-badge]').should('contain', '1');

    // Go to checkout
    cy.get('[data-cy=cart-icon]').click();
    cy.get('[data-cy=checkout-button]').click();

    // Fill shipping info
    cy.get('[data-cy=address]').type('123 Main St');
    cy.get('[data-cy=city]').type('New York');
    cy.get('[data-cy=zipcode]').type('10001');
    cy.get('[data-cy=continue-to-payment]').click();

    // Fill payment info
    cy.get('[data-cy=card-number]').type('4242424242424242');
    cy.get('[data-cy=exp-date]').type('12/25');
    cy.get('[data-cy=cvc]').type('123');
    cy.get('[data-cy=place-order]').click();

    // Verify confirmation
    cy.url().should('include', '/order-confirmation');
    cy.get('[data-cy=order-id]').should('exist');
    cy.get('[data-cy=order-status]').should('contain', 'Confirmed');
  });

  it('should handle payment failure gracefully', () => {
    // Add item
    cy.visit('/products/prod_123');
    cy.get('[data-cy=add-to-cart]').click();
    cy.get('[data-cy=checkout-button]').click();

    // Use declined card
    cy.get('[data-cy=card-number]').type('4000000000000002');
    cy.get('[data-cy=exp-date]').type('12/25');
    cy.get('[data-cy=cvc]').type('123');
    cy.get('[data-cy=place-order]').click();

    // Verify error message
    cy.get('[data-cy=error-message]')
      .should('be.visible')
      .and('contain', 'Payment declined');
  });
});
```

### Load Testing (k6)

```javascript
// loadtest/checkout.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },   // Ramp up to 100 users
    { duration: '5m', target: 100 },   // Stay at 100 users
    { duration: '2m', target: 200 },   // Ramp up to 200 users
    { duration: '5m', target: 200 },   // Stay at 200 users
    { duration: '2m', target: 0 },     // Ramp down to 0 users
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500', 'p(99)<1000'],  // 95% < 500ms, 99% < 1s
    'http_req_failed': ['rate<0.01'],                   // Error rate < 1%
  },
};

const BASE_URL = __ENV.API_URL || 'https://api.example.com';

export default function () {
  // Create order
  let payload = JSON.stringify({
    items: [
      { productId: 'prod_123', quantity: 2 },
      { productId: 'prod_456', quantity: 1 },
    ],
  });

  let params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${__ENV.AUTH_TOKEN}`,
    },
  };

  let response = http.post(`${BASE_URL}/api/orders`, payload, params);

  check(response, {
    'status is 201': (r) => r.status === 201,
    'response has orderId': (r) => JSON.parse(r.body).orderId !== undefined,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
```

```bash
# Run load test in CI
k6 run --out json=results.json loadtest/checkout.js

# Run with CI-specific options
k6 run \
  --vus 100 \
  --duration 10m \
  --out cloud \
  loadtest/checkout.js
```

---

## Interview Tips

### Discussing CI/CD

1. **Start with Pipeline Stages:**
   ```
   "I'd design a pipeline with these stages:
   1. Source checkout
   2. Build and unit tests
   3. Security scanning (SAST, dependency check)
   4. Container build and push
   5. Deploy to staging
   6. Integration and E2E tests
   7. Manual approval
   8. Deploy to production (canary)
   9. Automated rollback if metrics degrade"
   ```

2. **Mention Testing:**
   - Test pyramid: 60% unit, 30% integration, 10% E2E
   - Load testing before production
   - Chaos testing in staging

3. **Discuss Deployment Strategy:**
   - Blue/green for instant rollback
   - Canary for gradual rollout
   - Feature flags to decouple deploy from release

4. **IaC Best Practices:**
   - Store state remotely (S3 + DynamoDB for Terraform)
   - Use modules for reusability
   - Separate environments with workspaces
   - Review IaC changes in PRs

### Common Questions

**Q: How do you ensure zero-downtime deployments?**

**A:** "Several strategies:
1. **Rolling updates** with `maxUnavailable: 0` and `maxSurge: 1`
2. **Health checks** - don't route traffic until container is ready
3. **Pre-stop hooks** - graceful shutdown (finish requests)
4. **Connection draining** - ALB waits 30s before killing connections
5. **Database migrations** - backward-compatible changes first"

**Q: How do you handle secrets in CI/CD?**

**A:** "Never commit secrets to git. Instead:
1. **AWS Secrets Manager** - store secrets, reference in ECS task
2. **Parameter Store** - for non-sensitive config
3. **GitHub Secrets** - for CI/CD pipelines
4. **Vault** - for dynamic secrets
5. **IRSA** (IAM Roles for Service Accounts) - no long-lived credentials"

**Q: Terraform vs CloudFormation?**

**A:**
| Feature | Terraform | CloudFormation |
|---------|-----------|----------------|
| **Multi-cloud** | Yes | AWS only |
| **State** | Remote backend needed | Managed by AWS |
| **Modules** | HCL, reusable | Nested stacks, verbose |
| **Speed** | Fast | Slower for large stacks |
| **Cost** | Free (OSS) | Free |
| **Drift detection** | terraform plan | Detect stack drift |

---

## Summary Checklist

- [ ] CI/CD pipeline with automated tests (unit, integration, E2E, load)
- [ ] Security scanning (SAST, dependency check, container scan)
- [ ] Infrastructure as Code (Terraform or CloudFormation)
- [ ] GitOps (ArgoCD or Flux) for declarative deployments
- [ ] Safe deployment strategy (blue/green, canary, rolling)
- [ ] Automated rollback based on metrics
- [ ] Secrets management (AWS Secrets Manager, not in code)
- [ ] Environment separation (staging, production)
- [ ] IaC state management and locking
- [ ] Pipeline monitoring and alerts
