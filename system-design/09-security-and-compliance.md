# Security & Compliance - System Design Cheatsheet

## Overview

Security is not an afterthought—it must be built into every layer of the system. Compliance ensures you meet regulatory requirements (GDPR, HIPAA, PCI-DSS, SOC 2, etc.).

### Security Principles

1. **Defense in Depth**: Multiple layers of security
2. **Least Privilege**: Grant minimum necessary permissions
3. **Fail Secure**: Default to denying access
4. **Separation of Duties**: No single person has complete control
5. **Audit Everything**: Log all access and changes

---

## 1. Identity & Access Management (IAM)

### AWS IAM Best Practices

#### IAM Policies

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadOnlyAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "203.0.113.0/24"
        },
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

#### IAM Roles (Not Users!)

```yaml
# CloudFormation - ECS Task Role
Resources:
  ECSTaskRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
      Policies:
        - PolicyName: DynamoDBAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - dynamodb:GetItem
                  - dynamodb:Query
                  - dynamodb:Scan
                Resource:
                  - !Sub 'arn:aws:dynamodb:${AWS::Region}:${AWS::AccountId}:table/users'

  # Service account for Kubernetes
  ServiceAccount:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Federated: !Sub 'arn:aws:iam::${AWS::AccountId}:oidc-provider/${OIDCProvider}'
            Action: sts:AssumeRoleWithWebIdentity
            Condition:
              StringEquals:
                !Sub '${OIDCProvider}:sub': 'system:serviceaccount:production:web-app'
```

#### IRSA (IAM Roles for Service Accounts)

```yaml
# Kubernetes ServiceAccount with IAM role annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: web-app
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/web-app-role

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  template:
    spec:
      serviceAccountName: web-app  # Use IAM role
      containers:
      - name: app
        image: myapp:latest
        env:
        - name: AWS_ROLE_ARN
          value: arn:aws:iam::123456789012:role/web-app-role
        - name: AWS_WEB_IDENTITY_TOKEN_FILE
          value: /var/run/secrets/eks.amazonaws.com/serviceaccount/token
```

### Multi-Factor Authentication (MFA)

```python
# Enforce MFA for sensitive operations
import boto3

iam = boto3.client('iam')

# Create policy requiring MFA
mfa_policy = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAllActionsWithMFA",
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        },
        {
            "Sid": "DenyAllActionsWithoutMFA",
            "Effect": "Deny",
            "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ListMFADevices",
                "iam:ListUsers",
                "iam:GetUser"
            ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
}

response = iam.create_policy(
    PolicyName='RequireMFA',
    PolicyDocument=json.dumps(mfa_policy)
)
```

### AWS Organizations & SCPs

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeavingOrganization",
      "Effect": "Deny",
      "Action": [
        "organizations:LeaveOrganization"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyChangingSecurityServices",
      "Effect": "Deny",
      "Action": [
        "guardduty:DeleteDetector",
        "guardduty:DisassociateFromMasterAccount",
        "securityhub:DisableSecurityHub",
        "config:DeleteConfigRule",
        "config:DeleteConfigurationRecorder"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RequireEncryptedS3Uploads",
      "Effect": "Deny",
      "Action": "s3:PutObject",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": ["AES256", "aws:kms"]
        }
      }
    },
    {
      "Sid": "DenyRegionsExceptAllowed",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "route53:*",
        "cloudfront:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-west-2"]
        }
      }
    }
  ]
}
```

---

## 2. Secrets Management

### AWS Secrets Manager

```python
import boto3
import json

secretsmanager = boto3.client('secretsmanager')

# Create secret
secretsmanager.create_secret(
    Name='production/database/password',
    Description='RDS master password',
    SecretString=json.dumps({
        'username': 'admin',
        'password': 'super-secret-password',
        'engine': 'postgres',
        'host': 'mydb.cluster-abcdef.us-east-1.rds.amazonaws.com',
        'port': 5432,
        'dbname': 'production'
    }),
    Tags=[
        {'Key': 'Environment', 'Value': 'production'},
        {'Key': 'Application', 'Value': 'myapp'}
    ]
)

# Retrieve secret
response = secretsmanager.get_secret_value(SecretId='production/database/password')
secret = json.loads(response['SecretString'])

# Rotate secret automatically
secretsmanager.rotate_secret(
    SecretId='production/database/password',
    RotationLambdaARN='arn:aws:lambda:us-east-1:123456789012:function:SecretsManagerRotation',
    RotationRules={
        'AutomaticallyAfterDays': 30
    }
)

# Use in application
import psycopg2

conn = psycopg2.connect(
    host=secret['host'],
    port=secret['port'],
    database=secret['dbname'],
    user=secret['username'],
    password=secret['password']
)
```

#### Secrets in ECS

```yaml
# ECS Task Definition with Secrets Manager
{
  "family": "web-app",
  "taskRoleArn": "arn:aws:iam::123456789012:role/ecsTaskRole",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "myapp:latest",
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:production/database/password:password::"
        },
        {
          "name": "API_KEY",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789012:parameter/production/api-key"
        }
      ],
      "environment": [
        {
          "name": "ENVIRONMENT",
          "value": "production"
        }
      ]
    }
  ]
}
```

#### Secrets in Kubernetes

```yaml
# External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: production
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: db-secret
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: production/database/password
      property: password
  - secretKey: username
    remoteRef:
      key: production/database/password
      property: username

---
# Use in pod
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
```

### HashiCorp Vault

```python
import hvac

# Initialize Vault client
client = hvac.Client(url='https://vault.example.com:8200')

# Authenticate with AWS IAM
client.auth.aws.iam_login(
    access_key='AKIAIOSFODNN7EXAMPLE',
    secret_key='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    role='web-app-role'
)

# Read secret
secret = client.secrets.kv.v2.read_secret_version(path='production/database')
db_password = secret['data']['data']['password']

# Dynamic secrets (temporary database credentials)
db_creds = client.secrets.database.generate_credentials(name='postgres-production')
print(f"Username: {db_creds['data']['username']}")
print(f"Password: {db_creds['data']['password']}")
print(f"Lease Duration: {db_creds['lease_duration']} seconds")

# Renew lease
client.sys.renew_lease(lease_id=db_creds['lease_id'])

# Revoke when done
client.sys.revoke_lease(lease_id=db_creds['lease_id'])
```

---

## 3. Encryption

### Encryption at Rest

#### S3 Encryption

```python
import boto3

s3 = boto3.client('s3')

# Enable default encryption
s3.put_bucket_encryption(
    Bucket='my-bucket',
    ServerSideEncryptionConfiguration={
        'Rules': [
            {
                'ApplyServerSideEncryptionByDefault': {
                    'SSEAlgorithm': 'aws:kms',
                    'KMSMasterKeyID': 'arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012'
                },
                'BucketKeyEnabled': True
            }
        ]
    }
)

# Upload with encryption
s3.put_object(
    Bucket='my-bucket',
    Key='sensitive-data.txt',
    Body=b'Secret content',
    ServerSideEncryption='aws:kms',
    SSEKMSKeyId='arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012'
)
```

#### RDS Encryption

```yaml
Resources:
  DBInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      Engine: postgres
      EngineVersion: '14.7'
      DBInstanceClass: db.r5.large
      AllocatedStorage: 100
      StorageEncrypted: true  # Enable encryption
      KmsKeyId: !Ref KMSKey
      BackupRetentionPeriod: 30
      EnableCloudwatchLogsExports:
        - postgresql
        - upgrade

  KMSKey:
    Type: AWS::KMS::Key
    Properties:
      Description: RDS encryption key
      KeyPolicy:
        Version: '2012-10-17'
        Statement:
          - Sid: Enable IAM policies
            Effect: Allow
            Principal:
              AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
            Action: 'kms:*'
            Resource: '*'
          - Sid: Allow RDS to use key
            Effect: Allow
            Principal:
              Service: rds.amazonaws.com
            Action:
              - kms:Decrypt
              - kms:DescribeKey
              - kms:CreateGrant
            Resource: '*'
```

#### EBS Volume Encryption

```yaml
Resources:
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateData:
        BlockDeviceMappings:
          - DeviceName: /dev/xvda
            Ebs:
              VolumeSize: 50
              VolumeType: gp3
              Encrypted: true
              KmsKeyId: !Ref KMSKey
              DeleteOnTermination: true
```

### Encryption in Transit

#### TLS/SSL Configuration

```nginx
# nginx.conf - Strong TLS configuration
server {
    listen 443 ssl http2;
    server_name api.example.com;

    # Certificates
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # Strong TLS settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;

    # Perfect Forward Secrecy
    ssl_dhparam /etc/nginx/ssl/dhparam.pem;

    # HSTS (force HTTPS)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/nginx/ssl/ca-bundle.pem;

    # Session resumption
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    location / {
        proxy_pass http://backend;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

#### AWS Certificate Manager (ACM)

```yaml
Resources:
  Certificate:
    Type: AWS::CertificateManager::Certificate
    Properties:
      DomainName: api.example.com
      SubjectAlternativeNames:
        - '*.example.com'
      ValidationMethod: DNS
      DomainValidationOptions:
        - DomainName: example.com
          HostedZoneId: !Ref HostedZone

  LoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Type: application
      Subnets: !Ref PublicSubnets
      SecurityGroups:
        - !Ref ALBSecurityGroup

  Listener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref LoadBalancer
      Port: 443
      Protocol: HTTPS
      SslPolicy: ELBSecurityPolicy-TLS-1-2-2017-01  # Strong TLS policy
      Certificates:
        - CertificateArn: !Ref Certificate
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup

  # Redirect HTTP to HTTPS
  HTTPListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref LoadBalancer
      Port: 80
      Protocol: HTTP
      DefaultActions:
        - Type: redirect
          RedirectConfig:
            Protocol: HTTPS
            Port: '443'
            StatusCode: HTTP_301
```

### Application-Level Encryption

```python
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2

# Encrypt sensitive data before storing
class DataEncryption:
    def __init__(self, master_key: str):
        # Derive encryption key from master key
        kdf = PBKDF2(
            algorithm=hashes.SHA256(),
            length=32,
            salt=b'static-salt',  # Use unique salt per user in production
            iterations=100000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(master_key.encode()))
        self.cipher = Fernet(key)

    def encrypt(self, plaintext: str) -> str:
        return self.cipher.encrypt(plaintext.encode()).decode()

    def decrypt(self, ciphertext: str) -> str:
        return self.cipher.decrypt(ciphertext.encode()).decode()

# Usage
encryptor = DataEncryption(master_key=os.environ['MASTER_KEY'])

# Encrypt before storing in database
encrypted_ssn = encryptor.encrypt('123-45-6789')
db.users.update(user_id=123, ssn=encrypted_ssn)

# Decrypt when needed
encrypted_ssn = db.users.get(user_id=123).ssn
ssn = encryptor.decrypt(encrypted_ssn)
```

---

## 4. Network Security

### Security Groups

```yaml
Resources:
  # ALB Security Group - Public facing
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: ALB security group
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0

  # ECS Tasks Security Group - Private
  ECSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: ECS tasks security group
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          SourceSecurityGroupId: !Ref ALBSecurityGroup  # Only from ALB

  # RDS Security Group - Private
  RDSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: RDS security group
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref ECSSecurityGroup  # Only from ECS

  # Redis Security Group - Private
  RedisSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Redis security group
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 6379
          ToPort: 6379
          SourceSecurityGroupId: !Ref ECSSecurityGroup  # Only from ECS
```

### Network ACLs

```yaml
Resources:
  NetworkAcl:
    Type: AWS::EC2::NetworkAcl
    Properties:
      VpcId: !Ref VPC

  # Allow inbound HTTPS
  InboundHTTPSRule:
    Type: AWS::EC2::NetworkAclEntry
    Properties:
      NetworkAclId: !Ref NetworkAcl
      RuleNumber: 100
      Protocol: 6  # TCP
      RuleAction: allow
      CidrBlock: 0.0.0.0/0
      PortRange:
        From: 443
        To: 443

  # Block known malicious IP
  BlockMaliciousIP:
    Type: AWS::EC2::NetworkAclEntry
    Properties:
      NetworkAclId: !Ref NetworkAcl
      RuleNumber: 50
      Protocol: -1  # All protocols
      RuleAction: deny
      CidrBlock: 198.51.100.0/24  # Malicious IP range

  # Allow outbound
  OutboundRule:
    Type: AWS::EC2::NetworkAclEntry
    Properties:
      NetworkAclId: !Ref NetworkAcl
      RuleNumber: 100
      Protocol: -1
      Egress: true
      RuleAction: allow
      CidrBlock: 0.0.0.0/0
```

### VPC Endpoints (Private AWS Service Access)

```yaml
Resources:
  # S3 Gateway Endpoint (free)
  S3Endpoint:
    Type: AWS::EC2::VPCEndpoint
    Properties:
      VpcId: !Ref VPC
      ServiceName: !Sub 'com.amazonaws.${AWS::Region}.s3'
      RouteTableIds:
        - !Ref PrivateRouteTable

  # Interface Endpoints (charged)
  SecretsManagerEndpoint:
    Type: AWS::EC2::VPCEndpoint
    Properties:
      VpcId: !Ref VPC
      ServiceName: !Sub 'com.amazonaws.${AWS::Region}.secretsmanager'
      VpcEndpointType: Interface
      PrivateDnsEnabled: true
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
      SecurityGroupIds:
        - !Ref EndpointSecurityGroup

  ECRApiEndpoint:
    Type: AWS::EC2::VPCEndpoint
    Properties:
      VpcId: !Ref VPC
      ServiceName: !Sub 'com.amazonaws.${AWS::Region}.ecr.api'
      VpcEndpointType: Interface
      PrivateDnsEnabled: true
      SubnetIds:
        - !Ref PrivateSubnet1
      SecurityGroupIds:
        - !Ref EndpointSecurityGroup
```

### AWS WAF (Web Application Firewall)

```yaml
Resources:
  WebACL:
    Type: AWS::WAFv2::WebACL
    Properties:
      Name: ProductionWebACL
      Scope: REGIONAL
      DefaultAction:
        Allow: {}
      Rules:
        # Rate limiting
        - Name: RateLimitRule
          Priority: 1
          Statement:
            RateBasedStatement:
              Limit: 2000  # 2000 requests per 5 minutes per IP
              AggregateKeyType: IP
          Action:
            Block:
              CustomResponse:
                ResponseCode: 429
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: RateLimitRule

        # Block known bad IPs
        - Name: BlockBadIPs
          Priority: 2
          Statement:
            IPSetReferenceStatement:
              Arn: !GetAtt BadIPSet.Arn
          Action:
            Block: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: BlockBadIPs

        # SQL injection protection
        - Name: SQLInjectionRule
          Priority: 3
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesSQLiRuleSet
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: SQLInjectionRule

        # Block common attacks
        - Name: CoreRuleSet
          Priority: 4
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesCommonRuleSet
              ExcludedRules:
                - Name: SizeRestrictions_BODY  # Allow large POST bodies
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: CoreRuleSet

      VisibilityConfig:
        SampledRequestsEnabled: true
        CloudWatchMetricsEnabled: true
        MetricName: ProductionWebACL

  BadIPSet:
    Type: AWS::WAFv2::IPSet
    Properties:
      Name: BadIPSet
      Scope: REGIONAL
      IPAddressVersion: IPV4
      Addresses:
        - 198.51.100.0/24
        - 203.0.113.0/24

  # Associate with ALB
  WebACLAssociation:
    Type: AWS::WAFv2::WebACLAssociation
    Properties:
      ResourceArn: !Ref LoadBalancer
      WebACLArn: !GetAtt WebACL.Arn
```

---

## 5. Security Monitoring & Detection

### AWS GuardDuty

```python
import boto3

guardduty = boto3.client('guardduty')

# Enable GuardDuty
detector_response = guardduty.create_detector(Enable=True)
detector_id = detector_response['DetectorId']

# Configure S3 protection
guardduty.update_detector(
    DetectorId=detector_id,
    DataSources={
        'S3Logs': {'Enable': True},
        'Kubernetes': {
            'AuditLogs': {'Enable': True}
        }
    }
)

# List findings
findings = guardduty.list_findings(
    DetectorId=detector_id,
    FindingCriteria={
        'Criterion': {
            'severity': {
                'Gte': 7  # High and Critical only
            },
            'service.archived': {
                'Eq': ['false']
            }
        }
    }
)

# Get finding details
if findings['FindingIds']:
    details = guardduty.get_findings(
        DetectorId=detector_id,
        FindingIds=findings['FindingIds']
    )

    for finding in details['Findings']:
        print(f"Type: {finding['Type']}")
        print(f"Severity: {finding['Severity']}")
        print(f"Title: {finding['Title']}")
        print(f"Description: {finding['Description']}")
```

### AWS Security Hub

```yaml
Resources:
  SecurityHub:
    Type: AWS::SecurityHub::Hub
    Properties:
      Tags:
        Environment: production

  # Enable standards
  CISStandard:
    Type: AWS::SecurityHub::Standard
    Properties:
      StandardsArn: !Sub 'arn:aws:securityhub:${AWS::Region}::standards/cis-aws-foundations-benchmark/v/1.2.0'

  PCIDSSStandard:
    Type: AWS::SecurityHub::Standard
    Properties:
      StandardsArn: !Sub 'arn:aws:securityhub:${AWS::Region}::standards/pci-dss/v/3.2.1'

  # Custom insights
  HighSeverityFindings:
    Type: AWS::SecurityHub::Insight
    Properties:
      Name: High Severity Findings
      Filters:
        SeverityLabel:
          - Value: HIGH
            Comparison: EQUALS
          - Value: CRITICAL
            Comparison: EQUALS
        RecordState:
          - Value: ACTIVE
            Comparison: EQUALS
      GroupByAttribute: ResourceType
```

### AWS Config

```yaml
Resources:
  ConfigBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256

  ConfigRecorder:
    Type: AWS::Config::ConfigurationRecorder
    Properties:
      Name: default
      RoleArn: !GetAtt ConfigRole.Arn
      RecordingGroup:
        AllSupported: true
        IncludeGlobalResourceTypes: true

  DeliveryChannel:
    Type: AWS::Config::DeliveryChannel
    Properties:
      S3BucketName: !Ref ConfigBucket
      SnsTopicARN: !Ref ConfigTopic

  # Config Rules
  EncryptedVolumesRule:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: encrypted-volumes
      Description: Checks that EBS volumes are encrypted
      Source:
        Owner: AWS
        SourceIdentifier: ENCRYPTED_VOLUMES

  S3BucketPublicReadRule:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: s3-bucket-public-read-prohibited
      Description: Checks that S3 buckets do not allow public read access
      Source:
        Owner: AWS
        SourceIdentifier: S3_BUCKET_PUBLIC_READ_PROHIBITED

  IMDSv2Rule:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: ec2-imdsv2-check
      Description: Checks that EC2 instances use IMDSv2
      Source:
        Owner: AWS
        SourceIdentifier: EC2_IMDSV2_CHECK
```

### CloudTrail (Audit Logging)

```yaml
Resources:
  TrailBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
              KMSMasterKeyID: !Ref KMSKey
      VersioningConfiguration:
        Status: Enabled
      LifecycleConfiguration:
        Rules:
          - Id: DeleteOldLogs
            Status: Enabled
            ExpirationInDays: 90
            NoncurrentVersionExpirationInDays: 30

  Trail:
    Type: AWS::CloudTrail::Trail
    Properties:
      TrailName: OrganizationTrail
      S3BucketName: !Ref TrailBucket
      IsLogging: true
      IsMultiRegionTrail: true
      IncludeGlobalServiceEvents: true
      EnableLogFileValidation: true
      EventSelectors:
        - ReadWriteType: All
          IncludeManagementEvents: true
          DataResources:
            - Type: AWS::S3::Object
              Values:
                - !Sub '${SensitiveDataBucket}/*'
            - Type: AWS::Lambda::Function
              Values:
                - !Sub 'arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:function/*'
      InsightSelectors:
        - InsightType: ApiCallRateInsight

  # Alert on dangerous API calls
  RootAccountUsageAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: RootAccountUsage
      MetricName: RootAccountUsageCount
      Namespace: CloudTrailMetrics
      Statistic: Sum
      Period: 300
      EvaluationPeriods: 1
      Threshold: 1
      ComparisonOperator: GreaterThanOrEqualToThreshold
      AlarmActions:
        - !Ref SecurityAlertTopic

  UnauthorizedAPICallsAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: UnauthorizedAPICalls
      MetricName: UnauthorizedAPICallsCount
      Namespace: CloudTrailMetrics
      Statistic: Sum
      Period: 300
      EvaluationPeriods: 1
      Threshold: 5
      ComparisonOperator: GreaterThanOrEqualToThreshold
      AlarmActions:
        - !Ref SecurityAlertTopic
```

---

## 6. Compliance

### GDPR (General Data Protection Regulation)

```python
# Right to erasure (right to be forgotten)
class GDPRCompliance:
    def delete_user_data(self, user_id: str):
        """Delete or anonymize all user data"""

        # 1. Delete from primary database
        db.users.delete(user_id=user_id)
        db.orders.update_many(
            {'user_id': user_id},
            {'$set': {'user_id': 'DELETED', 'email': 'deleted@example.com'}}
        )

        # 2. Delete from cache
        cache.delete(f'user:{user_id}')

        # 3. Delete from S3
        s3.delete_objects(
            Bucket='user-uploads',
            Delete={
                'Objects': [
                    {'Key': f'{user_id}/'}
                ]
            }
        )

        # 4. Delete from backups (mark for deletion)
        db.deleted_users.insert({
            'user_id': user_id,
            'deleted_at': datetime.now(),
            'delete_from_backups': True
        })

        # 5. Delete from logs (CloudWatch Logs expiration)
        logs.put_retention_policy(
            logGroupName=f'/users/{user_id}',
            retentionInDays=7  # Minimum retention
        )

        # 6. Publish event for downstream systems
        sns.publish(
            TopicArn='arn:aws:sns:us-east-1:123456789012:user-deletion',
            Message=json.dumps({'user_id': user_id, 'action': 'delete'})
        )

    def export_user_data(self, user_id: str) -> dict:
        """Right to data portability"""
        user_data = {
            'personal_info': db.users.find_one({'id': user_id}),
            'orders': list(db.orders.find({'user_id': user_id})),
            'activity': list(db.activity_log.find({'user_id': user_id})),
            'preferences': db.preferences.find_one({'user_id': user_id})
        }

        # Generate export file
        export_file = f'/tmp/{user_id}_export.json'
        with open(export_file, 'w') as f:
            json.dump(user_data, f, indent=2, default=str)

        # Upload to S3 with expiration
        s3.upload_file(
            export_file,
            'gdpr-exports',
            f'{user_id}/export.json',
            ExtraArgs={
                'ServerSideEncryption': 'aws:kms',
                'Expires': datetime.now() + timedelta(days=7)
            }
        )

        # Generate presigned URL (expires in 7 days)
        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': 'gdpr-exports', 'Key': f'{user_id}/export.json'},
            ExpiresIn=604800  # 7 days
        )

        return {'download_url': url}
```

### HIPAA (Health Insurance Portability and Accountability Act)

```yaml
# HIPAA-compliant infrastructure
Resources:
  # Encrypted database
  RDSInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      Engine: postgres
      StorageEncrypted: true
      EnableCloudwatchLogsExports:
        - postgresql  # Audit logging required
      BackupRetentionPeriod: 30  # Minimum retention
      DeletionProtection: true

  # Encrypted file storage
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
      VersioningConfiguration:
        Status: Enabled  # Required for audit trail
      LoggingConfiguration:
        DestinationBucketName: !Ref LoggingBucket
        LogFilePrefix: access-logs/
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true

  # Access logging
  LoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Type: application
      LoadBalancerAttributes:
        - Key: access_logs.s3.enabled
          Value: 'true'
        - Key: access_logs.s3.bucket
          Value: !Ref LoggingBucket
```

### PCI-DSS (Payment Card Industry Data Security Standard)

```python
# Never store CVV, always tokenize card data
import stripe

stripe.api_key = os.environ['STRIPE_SECRET_KEY']

def process_payment(card_data: dict, amount: int):
    """PCI-compliant payment processing"""

    # Create token (card data sent directly to Stripe, not your server)
    token = stripe.Token.create(
        card={
            'number': card_data['number'],
            'exp_month': card_data['exp_month'],
            'exp_year': card_data['exp_year'],
            'cvc': card_data['cvc'],  # Never stored
        }
    )

    # Store only token, not card details
    customer = stripe.Customer.create(
        source=token.id,
        email=card_data['email']
    )

    # Save customer ID, not card data
    db.users.update(
        {'email': card_data['email']},
        {'$set': {'stripe_customer_id': customer.id}}
    )

    # Charge using token
    charge = stripe.Charge.create(
        amount=amount,
        currency='usd',
        customer=customer.id
    )

    # Log transaction (no sensitive data)
    audit_log.info(
        'payment_processed',
        user_email=mask_email(card_data['email']),
        amount=amount,
        charge_id=charge.id,
        last4=charge.source.last4  # Only last 4 digits
    )

    return charge

def mask_email(email: str) -> str:
    """Mask email for logging"""
    username, domain = email.split('@')
    return f"{username[0]}***@{domain}"
```

### SOC 2 Compliance

```python
# Implement audit logging for all data access
import functools
import inspect

def audit_log(func):
    """Decorator to log all data access"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        # Get caller information
        frame = inspect.currentframe().f_back
        caller_info = {
            'function': frame.f_code.co_name,
            'file': frame.f_code.co_filename,
            'line': frame.f_lineno
        }

        # Get user context
        user_id = g.get('user_id', 'anonymous')
        ip_address = request.remote_addr

        # Log before access
        logger.info(
            'data_access_attempt',
            user_id=user_id,
            ip_address=ip_address,
            resource=func.__name__,
            args=str(args),
            kwargs=str(kwargs),
            caller=caller_info
        )

        try:
            result = func(*args, **kwargs)

            # Log successful access
            logger.info(
                'data_access_success',
                user_id=user_id,
                resource=func.__name__,
                records_accessed=len(result) if isinstance(result, list) else 1
            )

            return result

        except Exception as e:
            # Log failed access
            logger.error(
                'data_access_failure',
                user_id=user_id,
                resource=func.__name__,
                error=str(e)
            )
            raise

    return wrapper

# Usage
@audit_log
def get_patient_records(patient_id: str):
    return db.patients.find_one({'id': patient_id})
```

---

## Interview Tips

### Discussing Security

1. **Defense in Depth:**
   ```
   "I'd implement security at multiple layers:
   - Network: VPC, security groups, NACLs, WAF
   - Application: Input validation, authentication, authorization
   - Data: Encryption at rest and in transit
   - Monitoring: GuardDuty, Security Hub, CloudTrail"
   ```

2. **Principle of Least Privilege:**
   - IAM roles, not users
   - Temporary credentials (STS, IRSA)
   - MFA for human access
   - Service-specific roles with minimal permissions

3. **Compliance Requirements:**
   - Ask: "What compliance requirements do we have?"
   - GDPR: Right to erasure, data portability
   - HIPAA: Encryption, audit logging, BAA with AWS
   - PCI-DSS: Never store CVV, tokenize cards
   - SOC 2: Audit all data access

### Common Questions

**Q: How do you secure secrets?**

**A:** "Never in code or environment variables. Use:
1. **AWS Secrets Manager** - automatic rotation
2. **Parameter Store** - for non-sensitive config
3. **Vault** - for dynamic secrets
4. **IRSA** - no long-lived credentials in Kubernetes
5. Encrypt in transit (TLS) and at rest (KMS)"

**Q: How do you detect security incidents?**

**A:** "Multi-layer detection:
1. **GuardDuty** - ML-based threat detection
2. **Security Hub** - centralized findings
3. **Config** - compliance violations
4. **CloudTrail** - audit all API calls
5. **VPC Flow Logs** - network traffic
6. **WAF** - application-layer attacks"

**Q: How do you handle a security breach?**

**A:** "Incident response process:
1. **Contain**: Isolate affected resources, revoke credentials
2. **Investigate**: CloudTrail, GuardDuty findings, logs
3. **Eradicate**: Remove malware, patch vulnerabilities
4. **Recover**: Restore from backups, verify integrity
5. **Lessons Learned**: Postmortem, update runbooks
6. **Notify**: Customers (if required), regulators, legal"

---

## Summary Checklist

- [ ] IAM roles with least privilege (no long-lived credentials)
- [ ] MFA for all human access
- [ ] Secrets in Secrets Manager (automatic rotation)
- [ ] Encryption at rest (KMS) and in transit (TLS 1.2+)
- [ ] Security groups (deny by default)
- [ ] VPC endpoints for private AWS access
- [ ] WAF for application protection
- [ ] GuardDuty + Security Hub for threat detection
- [ ] CloudTrail for audit logging (all regions)
- [ ] Config for compliance monitoring
- [ ] Regular security assessments and penetration testing
- [ ] Incident response runbooks
- [ ] Compliance requirements implemented (GDPR, HIPAA, PCI-DSS, SOC 2)
