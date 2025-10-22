# Kubernetes Cheat Sheet

Complete guide to Kubernetes features, concepts, and patterns.

---

## What is Kubernetes?

**Kubernetes (K8s)** is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications. Originally developed by Google, now maintained by CNCF.

**Key Characteristics:**
- Declarative configuration
- Self-healing capabilities
- Horizontal scaling
- Service discovery and load balancing
- Automated rollouts and rollbacks
- Secret and configuration management
- Storage orchestration

---

## Essential Features

### 1. Pods

**Description:** Smallest deployable unit in Kubernetes. One or more containers that share network and storage. Ephemeral by nature.

**Key Concepts:**
- Single container pods (most common)
- Multi-container pods (sidecar pattern)
- Shared network namespace (localhost communication)
- Shared storage volumes
- Pod lifecycle: Pending → Running → Succeeded/Failed

**YAML Example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Common Commands:**
```bash
kubectl run nginx --image=nginx           # Create pod
kubectl get pods                          # List pods
kubectl describe pod nginx                # Pod details
kubectl logs nginx                        # View logs
kubectl exec -it nginx -- bash            # Execute shell
kubectl delete pod nginx                  # Delete pod
```

**Use Cases:**
- Running single application instances
- Batch jobs
- Database pods
- Legacy application containers

---

### 2. Deployments

**Description:** Manages ReplicaSets and provides declarative updates for Pods. Primary way to deploy stateless applications. Handles rolling updates and rollbacks.

**Key Concepts:**
- Desired state management
- Rolling updates (zero-downtime)
- Rollback capabilities
- Scaling (manual and automatic)
- ReplicaSet management
- Pod template updates

**YAML Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Common Commands:**
```bash
kubectl create deployment nginx --image=nginx --replicas=3
kubectl get deployments
kubectl scale deployment nginx --replicas=5
kubectl set image deployment/nginx nginx=nginx:1.22
kubectl rollout status deployment/nginx
kubectl rollout history deployment/nginx
kubectl rollout undo deployment/nginx
kubectl delete deployment nginx
```

**Use Cases:**
- Web applications
- API servers
- Microservices
- Stateless applications
- Any workload requiring multiple replicas

---

### 3. Services

**Description:** Stable network endpoint for accessing Pods. Provides service discovery and load balancing. Abstracts Pod IP addresses.

**Key Concepts:**
- ClusterIP: Internal cluster access (default)
- NodePort: External access via node port
- LoadBalancer: Cloud provider load balancer
- ExternalName: DNS CNAME record
- Selector-based routing
- Session affinity

**Service Types:**

**ClusterIP (Internal):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
```

**NodePort (External):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080  # 30000-32767
```

**LoadBalancer (Cloud):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

**Common Commands:**
```bash
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get services
kubectl describe service nginx
kubectl delete service nginx
```

**Use Cases:**
- Microservice communication
- Load balancing across pods
- Service discovery
- External application access
- Database connection pooling

---

### 4. ConfigMaps

**Description:** Store non-confidential configuration data as key-value pairs. Decouple configuration from container images. Can be consumed as environment variables, command-line arguments, or config files.

**Key Concepts:**
- Environment variable injection
- Volume mount as files
- Immutable ConfigMaps (1.21+)
- Size limit: 1MB
- Not encrypted

**YAML Example:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # Simple key-value
  database_host: "db.example.com"
  database_port: "5432"
  log_level: "info"

  # File-like keys
  app.properties: |
    server.port=8080
    server.host=0.0.0.0
    cache.enabled=true

  nginx.conf: |
    server {
      listen 80;
      location / {
        proxy_pass http://backend:8080;
      }
    }
```

**Usage in Pod:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    # As environment variables
    env:
    - name: DATABASE_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
    # All keys as env vars
    envFrom:
    - configMapRef:
        name: app-config
    # As volume mount
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

**Common Commands:**
```bash
kubectl create configmap app-config --from-literal=key=value
kubectl create configmap app-config --from-file=config.json
kubectl get configmaps
kubectl describe configmap app-config
kubectl delete configmap app-config
```

**Use Cases:**
- Application configuration
- Environment-specific settings
- Configuration files (nginx, apache)
- Feature flags
- API endpoints

---

### 5. Secrets

**Description:** Store sensitive data like passwords, tokens, and keys. Base64 encoded (not encrypted by default). Should be used with encryption at rest.

**Key Concepts:**
- Base64 encoding
- Opaque type (generic)
- Docker registry credentials
- TLS certificates
- Service account tokens
- Encryption at rest (optional)
- Size limit: 1MB

**Secret Types:**
- Opaque: Generic secrets
- kubernetes.io/service-account-token
- kubernetes.io/dockerconfigjson
- kubernetes.io/tls
- kubernetes.io/basic-auth
- kubernetes.io/ssh-auth

**YAML Example:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Base64 encoded values
  database-password: cGFzc3dvcmQxMjM=
  api-key: YXBpLWtleS0xMjM0NTY=
stringData:
  # Plain text (auto-encoded)
  username: admin
  connection-string: "postgres://user:pass@host:5432/db"
```

**TLS Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: <base64-cert>
  tls.key: <base64-key>
```

**Usage in Pod:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    # As environment variables
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database-password
    # As volume mount
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secrets
```

**Common Commands:**
```bash
kubectl create secret generic app-secrets --from-literal=password=secret123
kubectl create secret docker-registry registry-creds \
  --docker-server=registry.example.com \
  --docker-username=user --docker-password=pass
kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key
kubectl get secrets
kubectl describe secret app-secrets
```

**Use Cases:**
- Database credentials
- API keys and tokens
- TLS certificates
- SSH keys
- Docker registry credentials
- OAuth tokens

---

### 6. Namespaces

**Description:** Virtual clusters within physical cluster. Provide scope for names and resources. Enable multi-tenancy and resource isolation.

**Key Concepts:**
- Resource isolation
- Access control boundaries
- Resource quotas per namespace
- Network policies
- Default namespaces: default, kube-system, kube-public, kube-node-lease
- DNS: service.namespace.svc.cluster.local

**YAML Example:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    team: platform
```

**With Resource Quota:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
```

**Common Commands:**
```bash
kubectl create namespace production
kubectl get namespaces
kubectl config set-context --current --namespace=production
kubectl get pods -n production
kubectl get all --all-namespaces
kubectl delete namespace production
```

**Use Cases:**
- Environment separation (dev/staging/prod)
- Team isolation
- Multi-tenancy
- Resource quota enforcement
- Access control boundaries

---

### 7. Volumes

**Description:** Storage abstraction for Pods. Persist data beyond Pod lifecycle. Support multiple storage backends.

**Volume Types:**
- **emptyDir**: Temporary storage, deleted with Pod
- **hostPath**: Node's filesystem (testing only)
- **persistentVolumeClaim**: Persistent storage
- **configMap/secret**: Configuration data
- **nfs**: Network File System
- **csi**: Container Storage Interface
- Cloud provider volumes (awsElasticBlockStore, azureDisk, gcePersistentDisk)

**EmptyDir (Temporary):**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cache-pod
spec:
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: cache
      mountPath: /cache
  volumes:
  - name: emptyDir
    emptyDir:
      sizeLimit: 500Mi
```

**PersistentVolumeClaim:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
---
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: app-pvc
```

**Use Cases:**
- Database storage
- Shared configuration
- Log aggregation
- Cache storage
- Stateful application data

---

### 8. StatefulSets

**Description:** Manages stateful applications. Provides stable network identities and persistent storage. Ordered deployment and scaling.

**Key Concepts:**
- Stable pod identifiers (pod-0, pod-1, pod-2)
- Stable network identity (DNS)
- Ordered deployment/scaling
- Ordered rolling updates
- Persistent storage per pod
- Headless service requirement

**YAML Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None  # Headless
  selector:
    app: mysql
  ports:
  - port: 3306
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-headless
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

**Common Commands:**
```bash
kubectl get statefulsets
kubectl scale statefulset mysql --replicas=5
kubectl rollout status statefulset/mysql
kubectl delete statefulset mysql
```

**Use Cases:**
- Databases (MySQL, PostgreSQL, MongoDB)
- Message queues (Kafka, RabbitMQ)
- Distributed systems (Cassandra, Elasticsearch)
- Stateful services requiring stable identity

---

### 9. DaemonSets

**Description:** Ensures a copy of a Pod runs on all (or some) nodes. Automatically schedules Pods on new nodes.

**Key Concepts:**
- One pod per node (by default)
- Node selector for specific nodes
- Automatic scheduling on new nodes
- Typical for system daemons
- Updates via rolling update

**YAML Example:**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  labels:
    app: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluentd:latest
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: containers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
```

**Common Commands:**
```bash
kubectl get daemonsets
kubectl describe daemonset fluentd
kubectl delete daemonset fluentd
```

**Use Cases:**
- Log collection (Fluentd, Logstash)
- Monitoring agents (Prometheus node exporter)
- Storage daemons (Gluster, Ceph)
- Network plugins (Calico, Weave)

---

## Advanced Features

### 10. Ingress

**Description:** Exposes HTTP/HTTPS routes from outside cluster to services. Provides load balancing, SSL termination, and name-based virtual hosting.

**Key Concepts:**
- Layer 7 load balancing
- Host-based routing
- Path-based routing
- TLS/SSL termination
- Requires Ingress Controller
- Annotations for controller-specific features

**YAML Example:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - example.com
    secretName: tls-secret
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

**Common Ingress Controllers:**
- NGINX Ingress Controller
- Traefik
- HAProxy
- Istio
- AWS ALB Ingress Controller
- GCE Ingress Controller

**Use Cases:**
- Single IP for multiple services
- SSL/TLS termination
- Name-based virtual hosting
- Path-based routing
- External access to services

---

### 11. Jobs

**Description:** Creates one or more Pods and ensures specified number complete successfully. Runs to completion then stops.

**Key Concepts:**
- Run-to-completion workloads
- Parallel execution
- Completion tracking
- Restart policies
- TTL for cleanup

**YAML Example:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  completions: 3      # Run 3 times
  parallelism: 2      # 2 at a time
  backoffLimit: 4     # Retry limit
  ttlSecondsAfterFinished: 100  # Auto cleanup
  template:
    spec:
      containers:
      - name: migration
        image: migration:latest
        command: ["./migrate.sh"]
      restartPolicy: OnFailure
```

**Common Commands:**
```bash
kubectl create job backup --image=backup:latest -- /backup.sh
kubectl get jobs
kubectl describe job data-migration
kubectl logs job/data-migration
kubectl delete job data-migration
```

**Use Cases:**
- Database migrations
- Batch processing
- Data imports/exports
- One-time tasks
- CI/CD pipelines

---

### 12. CronJobs

**Description:** Creates Jobs on a schedule. Kubernetes equivalent of cron. Manages time-based job execution.

**Key Concepts:**
- Cron syntax scheduling
- Job template
- History limits
- Concurrency policy
- Suspend scheduling

**YAML Example:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-cronjob
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  concurrencyPolicy: Forbid  # Allow, Forbid, Replace
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup:latest
            command: ["/backup.sh"]
          restartPolicy: OnFailure
```

**Cron Schedule Examples:**
```
*/5 * * * *     # Every 5 minutes
0 * * * *       # Every hour
0 2 * * *       # Daily at 2 AM
0 0 * * 0       # Weekly on Sunday
0 0 1 * *       # Monthly on 1st
@hourly         # Every hour
@daily          # Daily at midnight
@weekly         # Weekly on Sunday
```

**Use Cases:**
- Scheduled backups
- Report generation
- Data cleanup
- Health checks
- Periodic synchronization

---

### 13. Horizontal Pod Autoscaler (HPA)

**Description:** Automatically scales pod replicas based on observed metrics. Adjusts deployment/statefulset replicas.

**Key Concepts:**
- CPU-based scaling (default)
- Memory-based scaling
- Custom metrics (via Metrics Server)
- External metrics
- Scale-up and scale-down delays

**YAML Example:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
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
        periodSeconds: 15
```

**Common Commands:**
```bash
kubectl autoscale deployment web-app --min=2 --max=10 --cpu-percent=70
kubectl get hpa
kubectl describe hpa web-hpa
kubectl delete hpa web-hpa
```

**Use Cases:**
- Traffic-based scaling
- Cost optimization
- Performance optimization
- Handling traffic spikes
- Resource efficiency

---

### 14. Resource Quotas

**Description:** Restricts resource consumption per namespace. Enforces limits on compute, storage, and object count.

**Key Concepts:**
- CPU and memory limits
- Storage quotas
- Object count limits
- Per-namespace enforcement
- Request vs limit quotas

**YAML Example:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    # Compute resources
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi

    # Storage
    requests.storage: 100Gi
    persistentvolumeclaims: "10"

    # Object counts
    pods: "50"
    services: "20"
    configmaps: "30"
    secrets: "30"
    replicationcontrollers: "10"
```

**Use Cases:**
- Multi-tenant clusters
- Cost control
- Resource allocation
- Preventing resource exhaustion
- Fair resource sharing

---

### 15. Limit Ranges

**Description:** Enforce min/max resource limits per container/pod in namespace. Provide default values for resource requests/limits.

**Key Concepts:**
- Default resource values
- Min/max constraints
- Per-container limits
- Per-pod limits
- Prevent resource hogging

**YAML Example:**
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: development
spec:
  limits:
  # Container limits
  - type: Container
    max:
      cpu: "2"
      memory: 4Gi
    min:
      cpu: 100m
      memory: 128Mi
    default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 250m
      memory: 256Mi

  # Pod limits
  - type: Pod
    max:
      cpu: "4"
      memory: 8Gi

  # PVC limits
  - type: PersistentVolumeClaim
    max:
      storage: 50Gi
    min:
      storage: 1Gi
```

**Use Cases:**
- Default resource allocation
- Preventing excessive resource requests
- Enforcing resource standards
- Pod density control

---

### 16. Network Policies

**Description:** Control traffic flow at IP address or port level. Implement micro-segmentation. Requires CNI plugin support.

**Key Concepts:**
- Pod-to-pod traffic control
- Ingress and egress rules
- Label-based selection
- Namespace isolation
- Requires CNI plugin (Calico, Cilium, Weave)

**YAML Example:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress

  # Ingress rules
  ingress:
  - from:
    # From specific pods
    - podSelector:
        matchLabels:
          app: frontend
    # From specific namespaces
    - namespaceSelector:
        matchLabels:
          environment: production
    # From IP blocks
    - ipBlock:
        cidr: 10.0.0.0/24
        except:
        - 10.0.0.5/32
    ports:
    - protocol: TCP
      port: 8080

  # Egress rules
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    - podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

**Use Cases:**
- Micro-segmentation
- Security isolation
- Compliance requirements
- Zero-trust networking
- Multi-tenant security

---

### 17. Pod Disruption Budgets (PDB)

**Description:** Limits number of pods that can be down simultaneously. Ensures availability during voluntary disruptions.

**Key Concepts:**
- Minimum available pods
- Maximum unavailable pods
- Voluntary disruptions only
- Protects against node drains
- Enables safe maintenance

**YAML Example:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2  # Or use maxUnavailable: 1
  selector:
    matchLabels:
      app: web
---
# Alternative with percentage
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  maxUnavailable: 25%  # Allow 25% down
  selector:
    matchLabels:
      app: api
```

**Use Cases:**
- High availability requirements
- Safe node maintenance
- Cluster upgrades
- Application updates
- Preventing cascading failures

---

### 18. Service Accounts

**Description:** Provides identity for processes running in pods. Controls API access and permissions.

**Key Concepts:**
- Pod identity
- RBAC integration
- Automatic token mounting
- API authentication
- Per-namespace accounts

**YAML Example:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: production
automountServiceAccountToken: true
---
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  serviceAccountName: app-service-account
  containers:
  - name: app
    image: myapp:1.0
```

**With RBAC:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Use Cases:**
- API access control
- External service authentication
- CI/CD pipelines
- Operator patterns
- Custom controllers

---

### 19. Init Containers

**Description:** Specialized containers that run before app containers. Run to completion sequentially.

**Key Concepts:**
- Run before main containers
- Sequential execution
- Must complete successfully
- Share volumes with main containers
- Different image from main containers

**YAML Example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  initContainers:
  # Wait for database
  - name: wait-for-db
    image: busybox:1.35
    command: ['sh', '-c']
    args:
    - |
      until nc -z db-service 5432; do
        echo "Waiting for database..."
        sleep 2
      done
      echo "Database is ready!"

  # Initialize data
  - name: init-data
    image: busybox:1.35
    command: ['sh', '-c', 'echo "Initializing..." > /work-dir/init.txt']
    volumeMounts:
    - name: workdir
      mountPath: /work-dir

  # Download config
  - name: download-config
    image: curlimages/curl:latest
    command: ['sh', '-c']
    args:
    - curl -o /config/app.conf https://config-server/app.conf
    volumeMounts:
    - name: config
      mountPath: /config

  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: workdir
      mountPath: /work-dir
    - name: config
      mountPath: /etc/config

  volumes:
  - name: workdir
    emptyDir: {}
  - name: config
    emptyDir: {}
```

**Use Cases:**
- Wait for dependencies
- Database migrations
- Configuration setup
- Pre-loading data
- Security scanning

---

### 20. Probes (Health Checks)

**Description:** Monitor container health and readiness. Three types of probes for different purposes.

**Probe Types:**

**1. Liveness Probe** - Restart container if fails
**2. Readiness Probe** - Remove from service if fails
**3. Startup Probe** - Disable other probes during startup

**Probe Mechanisms:**
- HTTP GET
- TCP Socket
- Command Exec
- gRPC (1.24+)

**YAML Example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    ports:
    - containerPort: 8080

    # Liveness probe - restart if fails
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      successThreshold: 1
      failureThreshold: 3

    # Readiness probe - remove from service if fails
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 3

    # Startup probe - for slow-starting apps
    startupProbe:
      httpGet:
        path: /startup
        port: 8080
      initialDelaySeconds: 0
      periodSeconds: 10
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 30  # 30 * 10 = 300s max startup time
```

**TCP Socket Probe:**
```yaml
livenessProbe:
  tcpSocket:
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 20
```

**Exec Probe:**
```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

**gRPC Probe:**
```yaml
livenessProbe:
  grpc:
    port: 9090
  initialDelaySeconds: 10
```

**Use Cases:**
- Automatic failure recovery
- Load balancer health checks
- Zero-downtime deployments
- Application health monitoring
- Graceful shutdowns

---

## Common Patterns

### 1. Sidecar Pattern
**Description:** Helper container alongside main container.

```yaml
containers:
- name: app
  image: myapp:1.0
- name: log-forwarder  # Sidecar
  image: fluentd:latest
  volumeMounts:
  - name: logs
    mountPath: /var/log
```

**Use Cases:** Logging, monitoring, proxies, adapters

---

### 2. Ambassador Pattern
**Description:** Proxy container for external communication.

```yaml
containers:
- name: app
  image: myapp:1.0
- name: ambassador
  image: ambassador-proxy:latest
```

**Use Cases:** Service mesh, API gateways, protocol translation

---

### 3. Adapter Pattern
**Description:** Standardize output from main container.

```yaml
containers:
- name: app
  image: myapp:1.0
- name: adapter
  image: metric-adapter:latest
```

**Use Cases:** Metrics formatting, log normalization

---

### 4. Blue-Green Deployment
**Description:** Two identical environments for zero-downtime updates.

```bash
# Deploy green
kubectl apply -f green-deployment.yaml
# Test green
# Switch traffic
kubectl patch service app -p '{"spec":{"selector":{"version":"green"}}}'
# Remove blue
```

---

### 5. Canary Deployment
**Description:** Gradual rollout to subset of users.

```yaml
# 90% stable, 10% canary
apiVersion: v1
kind: Service
metadata:
  name: app
spec:
  selector:
    app: myapp
    # No version selector - routes to both
```

---

## Best Practices

1. **Resource Limits** - Always set requests and limits
2. **Health Checks** - Use liveness and readiness probes
3. **Labels** - Consistent labeling strategy
4. **Namespaces** - Organize resources logically
5. **ConfigMaps/Secrets** - Externalize configuration
6. **RBAC** - Principle of least privilege
7. **Network Policies** - Implement micro-segmentation
8. **Monitoring** - Use Prometheus and Grafana
9. **Logging** - Centralized log aggregation
10. **Backups** - Regular etcd and persistent volume backups

---

## Quick Reference

### Pod Lifecycle States
- **Pending**: Waiting to be scheduled
- **Running**: Pod is executing
- **Succeeded**: All containers terminated successfully
- **Failed**: All containers terminated, at least one failed
- **Unknown**: State cannot be determined

### Resource Units
- **CPU**: 1 = 1 vCPU, 100m = 0.1 vCPU
- **Memory**: 128Mi, 1Gi, etc.
- **Storage**: 10Gi, 100Gi, etc.

### Common kubectl Commands
```bash
kubectl get <resource>         # List resources
kubectl describe <resource>    # Detailed info
kubectl logs <pod>            # View logs
kubectl exec -it <pod> -- sh  # Execute shell
kubectl apply -f <file>       # Apply config
kubectl delete <resource>     # Delete resource
```

### Labels Best Practices
```yaml
metadata:
  labels:
    app: myapp              # Application name
    version: v1.0.0         # Version
    environment: production # Environment
    tier: frontend          # Application tier
    component: ui           # Component
```
