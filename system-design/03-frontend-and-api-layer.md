# System Design: Frontend & API Layer

## Overview

The Frontend & API Layer is the interface between users and your backend systems. It handles user interactions, API communication, authentication, rate limiting, and content delivery. For SRE interviews, understanding this layer demonstrates knowledge of client-server architecture, API design best practices, and performance optimization.

---

## 1. Frontend Architecture

### Single Page Applications (SPA)

**Description:** JavaScript applications that load a single HTML page and dynamically update content without full page reloads. All routing and rendering happens in the browser.

**Characteristics:**
- Client-side rendering (CSR)
- Rich, interactive UX
- API-driven (REST/GraphQL)
- State management in browser
- Routing handled by JavaScript

**Popular Frameworks:**
- **React:** Component-based, virtual DOM, large ecosystem
- **Vue:** Progressive framework, easy learning curve
- **Angular:** Full-featured, TypeScript, opinionated

**Pros:**
- Fast after initial load
- Smooth user experience
- Decoupled from backend
- Can work offline (with service workers)
- Mobile-friendly (can use React Native/Flutter)

**Cons:**
- Large initial bundle size
- SEO challenges (crawlers may not execute JS)
- Slower initial page load
- Client device performance dependent

**AWS Deployment:**
```
S3 Bucket (Static Hosting)
    ├── index.html
    ├── /static/js/bundle.js
    ├── /static/css/styles.css
    └── /static/images/

CloudFront (CDN)
    ├── Origin: S3 bucket
    ├── SSL/TLS certificate
    ├── Caching rules
    └── Custom error pages

Route 53 (DNS)
    └── A record → CloudFront distribution
```

**Build & Deploy Pipeline:**
```bash
# Build
npm run build  # Creates optimized production build

# Deploy to S3
aws s3 sync build/ s3://my-app-bucket/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/*"
```

**Performance Optimizations:**
- **Code splitting:** Load only needed code
- **Lazy loading:** Load routes/components on demand
- **Tree shaking:** Remove unused code
- **Minification:** Reduce bundle size
- **Compression:** Gzip/Brotli
- **CDN caching:** Cache static assets at edge

**Example: React SPA Structure:**
```javascript
// App.js
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import { lazy, Suspense } from 'react';

// Lazy load routes for code splitting
const Home = lazy(() => import('./pages/Home'));
const Dashboard = lazy(() => import('./pages/Dashboard'));

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<Loading />}>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/dashboard" element={<Dashboard />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}
```

---

### Server-Side Rendering (SSR)

**Description:** HTML is generated on the server for each request, then sent to the client. JavaScript hydrates the page to make it interactive.

**Characteristics:**
- Server generates HTML
- Better SEO (fully rendered HTML)
- Faster initial page load
- More server resources needed

**Frameworks:**
- **Next.js:** React-based, hybrid rendering
- **Nuxt.js:** Vue-based
- **SvelteKit:** Svelte-based

**Pros:**
- Excellent SEO
- Faster First Contentful Paint (FCP)
- Works without JavaScript
- Better for content-heavy sites

**Cons:**
- Higher server cost (compute per request)
- More complex caching
- Slower Time to Interactive (TTI)
- Server becomes bottleneck

**AWS Deployment:**
```
ALB (Application Load Balancer)
    │
    ├── Target: ECS/Fargate (SSR servers)
    │   └── Next.js app running in containers
    │
    └── CloudFront (CDN)
        ├── Cache static assets (/static/*)
        └── Forward dynamic requests to ALB
```

**Hybrid Approach (Next.js):**
```javascript
// pages/index.js - SSR
export async function getServerSideProps() {
  // Fetch data on every request
  const res = await fetch('https://api.example.com/data');
  const data = await res.json();
  return { props: { data } };
}

// pages/about.js - Static Generation
export async function getStaticProps() {
  // Built at build time
  return { props: { content: 'About us' } };
}

// pages/blog/[slug].js - ISR (Incremental Static Regeneration)
export async function getStaticProps({ params }) {
  return {
    props: { post: await getPost(params.slug) },
    revalidate: 60 // Regenerate page every 60 seconds
  };
}
```

---

### Static Site Generation (SSG)

**Description:** HTML pages are pre-built at build time and served as static files. No server-side processing per request.

**Characteristics:**
- Pre-rendered at build time
- Served as static files
- Excellent performance
- Limited dynamic content

**Pros:**
- Blazing fast (just static files)
- Cheap hosting (S3 + CloudFront)
- Excellent SEO
- High scalability
- No server needed

**Cons:**
- Build time increases with pages
- Not suitable for frequently changing content
- Requires rebuild for updates
- Limited personalization

**Best For:**
- Marketing sites
- Documentation
- Blogs
- Portfolio sites
- Landing pages

**AWS Deployment:**
```
S3 (Static hosting) + CloudFront + Route 53

Build process:
1. npm run build (generate static HTML)
2. Upload to S3
3. Invalidate CloudFront cache
4. Users get pre-rendered HTML
```

---

### Mobile Applications

**Native Mobile:**
- **iOS:** Swift, SwiftUI
- **Android:** Kotlin, Jetpack Compose
- **Pros:** Best performance, full device access, native UX
- **Cons:** Separate codebases, longer development

**Cross-Platform:**
- **React Native:** JavaScript, React components
- **Flutter:** Dart, compiled to native
- **Pros:** Single codebase, faster development
- **Cons:** Some performance overhead, limited native features

**AWS Mobile Services:**
- **Amplify:** Backend services (auth, API, storage)
- **AppSync:** Managed GraphQL, real-time subscriptions
- **Cognito:** User authentication
- **Pinpoint:** Analytics and push notifications
- **Device Farm:** Mobile device testing

---

## 2. Content Delivery Network (CDN)

### CloudFront Architecture

**Description:** AWS CloudFront is a global CDN that caches content at edge locations worldwide, reducing latency and load on origin servers.

**How It Works:**
```
User (Tokyo)
    │
    ▼
CloudFront Edge Location (Tokyo)
    │
    ├─► Cache Hit? Return cached content (fast)
    │
    └─► Cache Miss?
        │
        ▼
    Origin (us-east-1)
        │
        ├─► S3 (static assets)
        ├─► ALB (dynamic content)
        └─► API Gateway (API requests)
```

**Key Features:**
- **Edge Locations:** 400+ locations worldwide
- **Regional Edge Caches:** Larger caches between edge and origin
- **SSL/TLS:** Free certificates via ACM
- **Compression:** Automatic Gzip/Brotli
- **Lambda@Edge:** Run code at edge locations
- **Geo-Restrictions:** Block/allow by country
- **Signed URLs/Cookies:** Restrict content access

**Caching Strategies:**

**Cache Everything (Static Sites):**
```
CloudFront Behavior:
- Path pattern: /*
- TTL: 1 year (31536000 seconds)
- Cache based on: None (all same)
- Compress: Yes

Best for: S3 static sites, immutable assets
```

**Cache API Responses:**
```
CloudFront Behavior:
- Path pattern: /api/*
- TTL: 5 minutes (300 seconds)
- Cache based on: Query strings, headers
- Forward cookies: Selected
- Compress: Yes

Use case: Public API responses, product catalogs
```

**No Cache (Dynamic Content):**
```
CloudFront Behavior:
- Path pattern: /user/*
- TTL: 0 (no cache)
- Forward all headers/cookies
- Compress: Yes

Use case: Personalized content, user dashboards
```

**Cache Invalidation:**
```bash
# Invalidate all
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/*"

# Invalidate specific paths
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/index.html" "/static/css/*"

# Cost: First 1000 paths/month free, then $0.005 per path
```

**Versioned Assets (Cache Busting):**
```
# Don't invalidate, use versioned filenames
/static/js/main.abc123.js  # Hash in filename
/static/css/styles.v2.css  # Version in filename

# CloudFront caches forever, new versions = new URLs
# No invalidation cost, instant cache busting
```

**Lambda@Edge Use Cases:**
```javascript
// Viewer Request: Modify request before cache lookup
exports.handler = async (event) => {
  const request = event.Records[0].cf.request;

  // A/B testing: Route to different origins
  if (Math.random() < 0.5) {
    request.origin.s3.domainName = 'bucket-b.s3.amazonaws.com';
  }

  return request;
};

// Origin Response: Modify response before caching
exports.handler = async (event) => {
  const response = event.Records[0].cf.response;

  // Add security headers
  response.headers['strict-transport-security'] = [{
    key: 'Strict-Transport-Security',
    value: 'max-age=31536000; includeSubDomains'
  }];

  return response;
};
```

---

## 3. API Design

### REST API

**Description:** Representational State Transfer - architectural style using HTTP methods and standard status codes.

**Principles:**
- **Stateless:** Each request contains all needed information
- **Resource-based:** URLs represent resources, not actions
- **HTTP Methods:** GET, POST, PUT, PATCH, DELETE
- **Status Codes:** Semantic response codes (200, 404, 500)

**URL Design Best Practices:**
```
✅ Good REST URLs:
GET    /api/users              - List users
GET    /api/users/123          - Get user 123
POST   /api/users              - Create user
PUT    /api/users/123          - Replace user 123
PATCH  /api/users/123          - Update user 123
DELETE /api/users/123          - Delete user 123
GET    /api/users/123/orders   - User's orders

❌ Bad URLs:
GET    /api/getUser?id=123     - Action in URL
POST   /api/user/delete/123    - Wrong method
GET    /api/users/delete/123   - Mutation via GET
```

**HTTP Status Codes:**
```
Success:
200 OK              - Request succeeded
201 Created         - Resource created
202 Accepted        - Async processing started
204 No Content      - Success, no body

Client Errors:
400 Bad Request     - Invalid request
401 Unauthorized    - Authentication required
403 Forbidden       - Authenticated but no permission
404 Not Found       - Resource doesn't exist
409 Conflict        - Request conflicts with current state
422 Unprocessable   - Validation error
429 Too Many Req    - Rate limit exceeded

Server Errors:
500 Internal Error  - Server error
502 Bad Gateway     - Invalid upstream response
503 Service Unavail - Temporarily down
504 Gateway Timeout - Upstream timeout
```

**Versioning:**
```
URL versioning (recommended for public APIs):
/api/v1/users
/api/v2/users

Header versioning:
GET /api/users
Accept: application/vnd.myapi.v1+json

Query parameter (simple):
/api/users?version=1
```

**Pagination:**
```javascript
// Offset-based (simple, not recommended for large datasets)
GET /api/users?limit=20&offset=40

// Cursor-based (better for large datasets)
GET /api/users?limit=20&cursor=eyJpZCI6MTIzfQ

Response:
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTQzfQ",
    "has_more": true
  }
}
```

**Filtering, Sorting, Fields:**
```
GET /api/users?status=active&role=admin      # Filtering
GET /api/users?sort=-created_at,name         # Sort (- for desc)
GET /api/users?fields=id,name,email          # Sparse fieldsets
```

**AWS Implementation:**

**API Gateway REST API:**
```yaml
Resources:
  UsersApi:
    Type: AWS::ApiGateway::RestApi
    Properties:
      Name: users-api
      Description: Users REST API
      EndpointConfiguration:
        Types:
          - REGIONAL

  UsersResource:
    Type: AWS::ApiGateway::Resource
    Properties:
      RestApiId: !Ref UsersApi
      ParentId: !GetAtt UsersApi.RootResourceId
      PathPart: users

  GetUsersMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      RestApiId: !Ref UsersApi
      ResourceId: !Ref UsersResource
      HttpMethod: GET
      AuthorizationType: AWS_IAM
      Integration:
        Type: AWS_PROXY
        IntegrationHttpMethod: POST
        Uri: !Sub arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${GetUsersFunction.Arn}/invocations
```

---

### GraphQL

**Description:** Query language for APIs that allows clients to request exactly the data they need. Single endpoint, flexible queries.

**Characteristics:**
- Single endpoint (typically `/graphql`)
- Client specifies fields needed
- Type system and schema
- Real-time subscriptions
- Efficient data fetching (no over/under-fetching)

**Query Example:**
```graphql
# Client requests only needed fields
query GetUser {
  user(id: "123") {
    id
    name
    email
    posts {
      title
      createdAt
    }
  }
}

# Response has exact structure
{
  "data": {
    "user": {
      "id": "123",
      "name": "John Doe",
      "email": "john@example.com",
      "posts": [
        {
          "title": "Hello World",
          "createdAt": "2024-01-15"
        }
      ]
    }
  }
}
```

**Mutations (Create/Update/Delete):**
```graphql
mutation CreateUser {
  createUser(input: {
    name: "Jane Doe"
    email: "jane@example.com"
  }) {
    id
    name
    email
  }
}
```

**Subscriptions (Real-time):**
```graphql
subscription OnNewMessage {
  messageAdded(roomId: "room-123") {
    id
    text
    user {
      name
    }
  }
}
```

**Pros:**
- No over-fetching (client gets exactly what it needs)
- No under-fetching (single request for related data)
- Strong typing and introspection
- Self-documenting
- Real-time via subscriptions

**Cons:**
- More complex than REST
- HTTP caching harder (single endpoint)
- Query complexity attacks (need rate limiting)
- Learning curve
- Potentially expensive queries

**AWS Implementation (AppSync):**
```yaml
Resources:
  GraphQLApi:
    Type: AWS::AppSync::GraphQLApi
    Properties:
      Name: MyGraphQLApi
      AuthenticationType: API_KEY
      LogConfig:
        CloudWatchLogsRoleArn: !GetAtt AppSyncLogsRole.Arn
        FieldLogLevel: ERROR

  GraphQLSchema:
    Type: AWS::AppSync::GraphQLSchema
    Properties:
      ApiId: !GetAtt GraphQLApi.ApiId
      Definition: |
        type User {
          id: ID!
          name: String!
          email: String!
          posts: [Post]
        }

        type Post {
          id: ID!
          title: String!
          content: String!
          author: User
        }

        type Query {
          getUser(id: ID!): User
          listUsers: [User]
        }

        type Mutation {
          createUser(name: String!, email: String!): User
        }

        type Subscription {
          onCreateUser: User
            @aws_subscribe(mutations: ["createUser"])
        }

  UserDataSource:
    Type: AWS::AppSync::DataSource
    Properties:
      ApiId: !GetAtt GraphQLApi.ApiId
      Name: UserTable
      Type: AMAZON_DYNAMODB
      DynamoDBConfig:
        TableName: !Ref UsersTable
        AwsRegion: !Ref AWS::Region
```

**When to Use GraphQL:**
- Mobile apps (reduce bandwidth)
- Complex data relationships
- Rapid iteration (frontend changes frequently)
- Multiple client types (web, mobile, IoT)
- Real-time features needed

**When to Use REST:**
- Simple CRUD operations
- Public APIs (easier to document/consume)
- Caching important (CloudFront, browsers)
- Team familiar with REST
- File uploads/downloads

---

### gRPC

**Description:** High-performance RPC framework using Protocol Buffers. Binary protocol designed for service-to-service communication.

**Characteristics:**
- Binary protocol (more efficient than JSON)
- HTTP/2 based (multiplexing, server push)
- Strongly typed (Protocol Buffers)
- Code generation from .proto files
- Streaming (client, server, bidirectional)

**Protocol Buffer Definition:**
```protobuf
// user.proto
syntax = "proto3";

service UserService {
  rpc GetUser (GetUserRequest) returns (User);
  rpc ListUsers (ListUsersRequest) returns (stream User);
  rpc CreateUser (CreateUserRequest) returns (User);
}

message User {
  string id = 1;
  string name = 2;
  string email = 3;
  int64 created_at = 4;
}

message GetUserRequest {
  string id = 1;
}
```

**Pros:**
- Fast (binary, efficient serialization)
- Type-safe (compiled contracts)
- Streaming support
- Language-agnostic
- Smaller payloads than JSON

**Cons:**
- Not human-readable (binary)
- Limited browser support (needs grpc-web proxy)
- Steeper learning curve
- Less tooling than REST

**When to Use:**
- Microservices communication
- High-performance requirements
- Streaming data (real-time, bidirectional)
- Polyglot environments
- Internal APIs (not public-facing)

**AWS Implementation:**
```
gRPC Server:
- ECS/EKS (containers)
- NLB (Layer 4 load balancer for gRPC)
- ECS Service Discovery for service mesh

Client ──► NLB ──► ECS Tasks (gRPC servers)

Note: ALB doesn't support HTTP/2 end-to-end,
      use NLB or API Gateway HTTP API
```

---

## 4. Authentication & Authorization

### Authentication (Who are you?)

**AWS Cognito User Pools:**

**Description:** Managed user directory with sign-up, sign-in, and access control.

**Features:**
- User registration and authentication
- Social identity providers (Google, Facebook, Amazon)
- SAML/OIDC enterprise identity providers
- MFA (Multi-Factor Authentication)
- Password policies and account recovery
- JWT tokens (ID token, Access token, Refresh token)

**Architecture:**
```
Client App
    │
    ├─► Sign Up ────► Cognito User Pool
    │                     │
    │                     ├─► Email verification
    │                     └─► User created
    │
    ├─► Sign In ────► Cognito User Pool
    │                     │
    │                     └─► Return tokens:
    │                         - ID Token (user info)
    │                         - Access Token (API access)
    │                         - Refresh Token (get new tokens)
    │
    └─► API Call (with Access Token)
            │
            ▼
        API Gateway
            │
            ├─► Cognito Authorizer
            │   (validates token)
            │
            └─► Lambda (if valid)
```

**Token Types:**
```
ID Token (JWT):
- User attributes (name, email, custom)
- Use for: Display user info in UI

Access Token (JWT):
- Scopes and groups
- Use for: API authentication

Refresh Token (opaque):
- Long-lived (days/months)
- Use for: Get new Access/ID tokens
```

**Example: React Authentication:**
```javascript
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const poolData = {
  UserPoolId: 'us-east-1_ABC123',
  ClientId: 'abc123def456'
};
const userPool = new CognitoUserPool(poolData);

// Sign In
function signIn(username, password) {
  const authenticationData = {
    Username: username,
    Password: password,
  };
  const authenticationDetails = new AuthenticationDetails(authenticationData);

  const userData = {
    Username: username,
    Pool: userPool,
  };
  const cognitoUser = new CognitoUser(userData);

  cognitoUser.authenticateUser(authenticationDetails, {
    onSuccess: (result) => {
      const accessToken = result.getAccessToken().getJwtToken();
      const idToken = result.getIdToken().getJwtToken();
      // Store tokens, redirect to app
    },
    onFailure: (err) => {
      console.error(err);
    },
  });
}

// Call API with token
async function callApi() {
  const session = await getCurrentSession();
  const accessToken = session.getAccessToken().getJwtToken();

  const response = await fetch('https://api.example.com/user', {
    headers: {
      'Authorization': `Bearer ${accessToken}`
    }
  });
  return response.json();
}
```

**Social Sign-In:**
```
Cognito User Pool Identity Providers:
- Google
- Facebook
- Amazon
- Apple
- SAML 2.0 (enterprise)
- OpenID Connect

Cognito handles OAuth flow:
1. Redirect to provider
2. User authenticates
3. Provider redirects back with code
4. Cognito exchanges code for tokens
5. Return Cognito JWT tokens to app
```

---

### Authorization (What can you do?)

**AWS IAM (for AWS resources):**
- Fine-grained permissions
- Role-based access control
- Service-to-service auth

**Cognito Groups:**
```
User Pool Groups:
- Admin
- Moderator
- User

Claims in Access Token:
{
  "cognito:groups": ["Admin", "Moderator"],
  "username": "john@example.com"
}

API checks groups for authorization
```

**Custom Authorizer (Lambda):**
```javascript
// Lambda Authorizer for API Gateway
exports.handler = async (event) => {
  const token = event.authorizationToken;

  // Verify token (check signature, expiration)
  const decoded = verifyJWT(token);

  // Check permissions
  const hasAccess = checkPermissions(decoded, event.methodArn);

  if (hasAccess) {
    return generatePolicy('user', 'Allow', event.methodArn);
  } else {
    return generatePolicy('user', 'Deny', event.methodArn);
  }
};

function generatePolicy(principalId, effect, resource) {
  return {
    principalId: principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [{
        Action: 'execute-api:Invoke',
        Effect: effect,
        Resource: resource
      }]
    },
    // Context passed to Lambda
    context: {
      userId: principalId,
      role: 'admin'
    }
  };
}
```

**OAuth 2.0 & OpenID Connect:**
```
OAuth 2.0 Flows:

1. Authorization Code (most secure):
   - Redirect to auth server
   - User approves
   - Get authorization code
   - Exchange code for tokens
   - Use for: Web apps, mobile apps

2. Client Credentials:
   - Service provides client_id + secret
   - Get access token directly
   - Use for: Service-to-service

3. Implicit (deprecated):
   - Tokens in URL fragment
   - Less secure

OpenID Connect (OIDC):
- Layer on top of OAuth 2.0
- Adds ID Token with user info
- Standardized authentication
```

---

## 5. Rate Limiting & Throttling

### Why Rate Limit?

**Reasons:**
- **Prevent abuse:** DDoS protection, brute force attacks
- **Fair usage:** Ensure all users get service
- **Cost control:** Limit expensive operations
- **Stability:** Prevent overload

### Rate Limiting Strategies

**Fixed Window:**
```
Allow 100 requests per minute

Window: 10:00:00 - 10:01:00
├─► Request 1-100: Allowed
└─► Request 101+: Rejected (429 Too Many Requests)

Next window: 10:01:00 (counter resets)

Issue: Burst at window boundaries
- 100 requests at 10:00:59
- 100 requests at 10:01:00
- = 200 requests in 2 seconds!
```

**Sliding Window:**
```
Allow 100 requests per minute (sliding)

Current time: 10:00:30
Look back 60 seconds (09:59:30 - 10:00:30)
Count requests in window

More accurate, prevents boundary bursts
```

**Token Bucket:**
```
Bucket capacity: 100 tokens
Refill rate: 10 tokens/second

Request arrives:
- Token available? ✓ Consume token, allow request
- No token? ✗ Reject (429)

Allows bursts up to bucket capacity
Smooth average rate over time
```

**Leaky Bucket:**
```
Bucket capacity: 100 requests
Leak rate: 10 requests/second

Requests queue in bucket
Processed at constant rate
If bucket full, reject

Smooths traffic, no bursts
```

### AWS Implementation

**API Gateway Throttling:**
```yaml
Resources:
  RestApi:
    Type: AWS::ApiGateway::RestApi
    Properties:
      Name: my-api

  UsagePlan:
    Type: AWS::ApiGateway::UsagePlan
    Properties:
      UsagePlanName: basic-plan
      Description: Basic tier
      Throttle:
        BurstLimit: 100    # Max concurrent requests
        RateLimit: 50      # Requests per second (steady state)
      Quota:
        Limit: 10000       # Total requests
        Period: MONTH      # Per month
      ApiStages:
        - ApiId: !Ref RestApi
          Stage: prod

  ApiKey:
    Type: AWS::ApiGateway::ApiKey
    Properties:
      Name: customer-key
      Enabled: true

  UsagePlanKey:
    Type: AWS::ApiGateway::UsagePlanKey
    Properties:
      KeyId: !Ref ApiKey
      KeyType: API_KEY
      UsagePlanId: !Ref UsagePlan
```

**Application-Level Rate Limiting (Lambda + DynamoDB):**
```python
import boto3
import time
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('rate_limits')

def rate_limit(user_id, limit=100, window=60):
    """Token bucket implementation"""
    now = int(time.time())
    key = f"{user_id}:{now // window}"

    try:
        # Atomic increment
        response = table.update_item(
            Key={'key': key},
            UpdateExpression='SET requests = if_not_exists(requests, :zero) + :inc, expiry = :exp',
            ExpressionAttributeValues={
                ':inc': 1,
                ':zero': 0,
                ':exp': now + window,
                ':limit': limit
            },
            ConditionExpression='requests < :limit',
            ReturnValues='UPDATED_NEW'
        )
        return True  # Request allowed
    except Exception as e:
        if 'ConditionalCheckFailedException' in str(e):
            return False  # Rate limit exceeded
        raise

# Usage in Lambda
def handler(event, context):
    user_id = event['requestContext']['authorizer']['claims']['sub']

    if not rate_limit(user_id):
        return {
            'statusCode': 429,
            'body': json.dumps({'error': 'Rate limit exceeded'}),
            'headers': {
                'Retry-After': '60'
            }
        }

    # Process request
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Success'})
    }
```

**Redis-Based Rate Limiting:**
```python
import redis
import time

r = redis.Redis(host='redis-endpoint', port=6379)

def rate_limit_sliding_window(user_id, limit=100, window=60):
    """Sliding window using Redis sorted set"""
    key = f"rate_limit:{user_id}"
    now = time.time()

    # Remove old entries outside window
    r.zremrangebyscore(key, 0, now - window)

    # Count current requests
    current = r.zcard(key)

    if current < limit:
        # Add current request
        r.zadd(key, {str(now): now})
        r.expire(key, window)
        return True
    else:
        return False

def rate_limit_token_bucket(user_id, capacity=100, refill_rate=10):
    """Token bucket using Redis"""
    key = f"bucket:{user_id}"
    now = time.time()

    # Get current state
    data = r.hgetall(key)
    tokens = float(data.get(b'tokens', capacity))
    last_refill = float(data.get(b'last_refill', now))

    # Refill tokens
    elapsed = now - last_refill
    tokens = min(capacity, tokens + elapsed * refill_rate)

    if tokens >= 1:
        # Consume token
        tokens -= 1
        r.hset(key, mapping={
            'tokens': tokens,
            'last_refill': now
        })
        r.expire(key, 3600)
        return True
    else:
        return False
```

**Response Headers:**
```
HTTP/1.1 429 Too Many Requests
Content-Type: application/json
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1642252800
Retry-After: 60

{
  "error": "Rate limit exceeded",
  "message": "You have exceeded the rate limit of 100 requests per minute",
  "retry_after": 60
}
```

---

## 6. API Gateway Patterns

### API Gateway (Microservices Pattern)

**Description:** Single entry point for all client requests. Routes to appropriate backend services, handles cross-cutting concerns.

**Responsibilities:**
- Request routing
- Authentication & authorization
- Rate limiting & throttling
- Request/response transformation
- Protocol translation (REST → gRPC)
- Caching
- Monitoring & logging
- Circuit breaking

**Architecture:**
```
Clients (Web, Mobile, IoT)
    │
    ▼
┌─────────────────────────┐
│      API Gateway        │
│  ┌──────────────────┐   │
│  │ Authentication   │   │
│  │ Rate Limiting    │   │
│  │ Request Routing  │   │
│  │ Caching          │   │
│  │ Monitoring       │   │
│  └──────────────────┘   │
└────────────┬────────────┘
             │
    ┌────────┼────────┬─────────┐
    │        │        │         │
┌───▼──┐ ┌──▼───┐ ┌──▼───┐ ┌───▼───┐
│User  │ │Order │ │Pay   │ │Search │
│Svc   │ │Svc   │ │Svc   │ │Svc    │
└──────┘ └──────┘ └──────┘ └───────┘
```

**AWS API Gateway:**
```yaml
# API Gateway with multiple integrations
Resources:
  ApiGateway:
    Type: AWS::ApiGateway::RestApi
    Properties:
      Name: microservices-gateway
      Description: Gateway for all microservices

  # Users resource
  UsersResource:
    Type: AWS::ApiGateway::Resource
    Properties:
      RestApiId: !Ref ApiGateway
      ParentId: !GetAtt ApiGateway.RootResourceId
      PathPart: users

  UsersGetMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      RestApiId: !Ref ApiGateway
      ResourceId: !Ref UsersResource
      HttpMethod: GET
      AuthorizationType: COGNITO_USER_POOLS
      AuthorizerId: !Ref CognitoAuthorizer
      Integration:
        Type: HTTP_PROXY
        IntegrationHttpMethod: GET
        Uri: http://users-service-alb.internal/users
        # Or Lambda: AWS_PROXY to Lambda function

  # Orders resource
  OrdersResource:
    Type: AWS::ApiGateway::Resource
    Properties:
      RestApiId: !Ref ApiGateway
      ParentId: !GetAtt ApiGateway.RootResourceId
      PathPart: orders

  OrdersPostMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      RestApiId: !Ref ApiGateway
      ResourceId: !Ref OrdersResource
      HttpMethod: POST
      AuthorizationType: COGNITO_USER_POOLS
      AuthorizerId: !Ref CognitoAuthorizer
      Integration:
        Type: HTTP_PROXY
        IntegrationHttpMethod: POST
        Uri: http://orders-service-alb.internal/orders
```

**Benefits:**
- Centralized security and governance
- Consistent API interface
- Simplified client code
- Independent service scaling
- Easy to add new services

**Challenges:**
- Single point of failure (mitigate with multi-AZ)
- Potential bottleneck (use caching, CDN)
- Increased latency (one extra hop)
- Gateway becomes complex (keep logic minimal)

---

### Backend for Frontend (BFF)

**Description:** Separate API gateway for each client type (web, mobile, IoT). Optimized for specific client needs.

**Architecture:**
```
┌──────────┐         ┌──────────────┐
│ Web App  ├────────►│  Web BFF     │
└──────────┘         │ (GraphQL)    │
                     └───────┬──────┘
┌──────────┐                │
│ Mobile   ├─────┐          │
│   App    │     │          │         Backend Services
└──────────┘     ▼          ▼         ┌─────────────┐
           ┌──────────────┐            │   Users     │
           │  Mobile BFF  ├───────────►│   Orders    │
           │ (REST slim)  │            │   Products  │
           └──────────────┘            │   Payment   │
                                       └─────────────┘
Web BFF:
- Rich GraphQL queries
- Desktop-optimized responses
- Larger payloads OK

Mobile BFF:
- Slim REST responses
- Minimal data transfer
- Optimized for 3G/4G
```

**When to Use:**
- Different client requirements (web vs mobile)
- Web needs rich data, mobile needs minimal
- Different security requirements
- Team ownership (web team, mobile team)

---

## 7. Interview Tips

### Discussing Frontend & API Layer

**Structure Your Answer:**

1. **Start with Client Type:**
   - "This is a web app, so I'd use a React SPA hosted on S3 behind CloudFront for global distribution..."

2. **API Design:**
   - "For the API, I'd use RESTful endpoints with proper HTTP methods and status codes..."
   - "If we have complex data relationships, GraphQL via AppSync would be better..."

3. **Authentication:**
   - "For auth, I'd use Cognito User Pools with JWT tokens..."
   - "API Gateway validates tokens before forwarding to backend..."

4. **Performance:**
   - "CloudFront caches static assets at edge locations..."
   - "API Gateway can cache responses for read-heavy endpoints..."

5. **Rate Limiting:**
   - "API Gateway provides built-in throttling at 10K requests/second..."
   - "For more granular control, implement token bucket in Redis..."

**Trade-offs to Mention:**
- SPA vs SSR (SEO, performance, complexity)
- REST vs GraphQL (simplicity vs flexibility)
- API Gateway vs ALB (features vs performance)
- Cognito vs custom auth (managed vs control)

---

## Summary

**Key Takeaways:**

1. **Frontend:** Choose based on SEO needs (SSR), simplicity (SPA), or cost (SSG)
2. **CDN:** Always use CloudFront for static assets and geographic distribution
3. **API Design:** REST for simple CRUD, GraphQL for complex queries, gRPC for service-to-service
4. **Authentication:** Use Cognito for managed solution, supports social/enterprise identity
5. **Authorization:** Groups for RBAC, Lambda authorizer for custom logic
6. **Rate Limiting:** API Gateway built-in for basic, Redis/DynamoDB for advanced
7. **API Gateway:** Central entry point with cross-cutting concerns, but watch for bottlenecks

**Remember:** The frontend and API layer is the user's first interaction with your system. Make it fast, secure, and reliable!
