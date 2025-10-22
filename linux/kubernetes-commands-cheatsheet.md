# Kubernetes (kubectl) Commands Cheat Sheet

Essential Kubernetes commands with descriptions and examples for container orchestration.

---

## Cluster Information

### `kubectl cluster-info` - Display Cluster Info
Show cluster endpoint information.
```bash
kubectl cluster-info                      # Show cluster info
kubectl cluster-info dump                 # Dump cluster state
kubectl cluster-info dump --output-directory=/path  # Dump to directory
```

### `kubectl version` - Show Version
Display client and server version.
```bash
kubectl version                           # Show version
kubectl version --short                   # Short version
kubectl version --client                  # Client version only
kubectl version --output=yaml             # YAML format
```

### `kubectl get nodes` - List Nodes
Show cluster nodes.
```bash
kubectl get nodes                         # List all nodes
kubectl get nodes -o wide                 # Detailed view
kubectl get nodes --show-labels           # Show labels
kubectl get nodes --selector=role=worker  # Filter by label
kubectl describe node node-name           # Node details
kubectl top nodes                         # Node resource usage
```

---

## Context and Configuration

### `kubectl config` - Manage Configuration
Manage kubeconfig files.
```bash
# View configuration
kubectl config view                       # Show merged config
kubectl config view --minify              # Show current context config
kubectl config view --raw                 # Show raw config

# Contexts
kubectl config get-contexts               # List contexts
kubectl config current-context            # Show current context
kubectl config use-context context-name   # Switch context
kubectl config rename-context old new     # Rename context
kubectl config delete-context context-name # Delete context

# Clusters
kubectl config get-clusters               # List clusters
kubectl config set-cluster cluster-name --server=https://url
kubectl config delete-cluster cluster-name

# Users
kubectl config set-credentials user-name --token=token
kubectl config delete-user user-name

# Set default namespace
kubectl config set-context --current --namespace=my-namespace

# Create new context
kubectl config set-context my-context \
  --cluster=my-cluster \
  --user=my-user \
  --namespace=default
```

---

## Namespaces

### `kubectl get namespaces` - List Namespaces
Show all namespaces.
```bash
kubectl get namespaces                    # List namespaces
kubectl get ns                            # Short form
kubectl describe namespace name           # Namespace details
kubectl get all -n namespace              # All resources in namespace
kubectl get all --all-namespaces          # All resources in all namespaces
kubectl get all -A                        # Short form for all namespaces
```

### `kubectl create namespace` - Create Namespace
Create a new namespace.
```bash
kubectl create namespace dev              # Create namespace
kubectl create ns staging                 # Short form
kubectl delete namespace dev              # Delete namespace

# From YAML
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: production
EOF
```

---

## Pods

### `kubectl get pods` - List Pods
Show pods in cluster.
```bash
kubectl get pods                          # Pods in current namespace
kubectl get pods -n namespace             # Pods in specific namespace
kubectl get pods --all-namespaces         # All pods
kubectl get pods -A                       # Short form
kubectl get pods -o wide                  # Detailed view
kubectl get pods --show-labels            # Show labels
kubectl get pods -l app=nginx             # Filter by label
kubectl get pods --field-selector=status.phase=Running
kubectl get pods --sort-by=.metadata.creationTimestamp
kubectl get pods -w                       # Watch mode
```

### `kubectl describe pod` - Pod Details
Show detailed pod information.
```bash
kubectl describe pod pod-name             # Describe pod
kubectl describe pod pod-name -n namespace
kubectl describe pods                     # All pods
kubectl describe pods -l app=nginx        # By label
```

### `kubectl logs` - View Pod Logs
Show container logs.
```bash
kubectl logs pod-name                     # Show logs
kubectl logs pod-name -n namespace        # Specific namespace
kubectl logs pod-name -c container-name   # Specific container
kubectl logs pod-name --all-containers    # All containers
kubectl logs pod-name -f                  # Follow logs
kubectl logs pod-name --tail=100          # Last 100 lines
kubectl logs pod-name --since=1h          # Last hour
kubectl logs pod-name --since-time=2024-01-15T10:00:00Z
kubectl logs pod-name --timestamps        # Include timestamps
kubectl logs pod-name --previous          # Previous container instance
kubectl logs -l app=nginx                 # By label
kubectl logs deployment/nginx             # Deployment logs
```

### `kubectl exec` - Execute Command in Pod
Run commands in containers.
```bash
kubectl exec pod-name -- command          # Execute command
kubectl exec pod-name -- ls /app          # List directory
kubectl exec pod-name -c container -- command  # Specific container
kubectl exec -it pod-name -- /bin/bash    # Interactive bash
kubectl exec -it pod-name -- sh           # Interactive sh
kubectl exec -it pod-name -n namespace -- bash
kubectl exec pod-name -- env              # Show environment variables
```

### `kubectl port-forward` - Forward Ports
Forward local ports to pod.
```bash
kubectl port-forward pod-name 8080:80    # Forward port 8080 to pod port 80
kubectl port-forward pod-name 8080:80 -n namespace
kubectl port-forward svc/service-name 8080:80  # Forward to service
kubectl port-forward deployment/nginx 8080:80   # Forward to deployment
kubectl port-forward --address 0.0.0.0 pod-name 8080:80  # Listen on all interfaces
```

### `kubectl cp` - Copy Files
Copy files to/from containers.
```bash
kubectl cp pod-name:/path/to/file ./local-file  # From pod
kubectl cp ./local-file pod-name:/path/to/file  # To pod
kubectl cp pod-name:/path/to/file ./file -c container-name  # Specific container
kubectl cp namespace/pod-name:/path/file ./file  # With namespace
```

### `kubectl delete pod` - Delete Pods
Remove pods.
```bash
kubectl delete pod pod-name               # Delete pod
kubectl delete pod pod-name -n namespace
kubectl delete pods --all                 # Delete all pods
kubectl delete pods -l app=nginx          # Delete by label
kubectl delete pod pod-name --force --grace-period=0  # Force delete
```

---

## Deployments

### `kubectl get deployments` - List Deployments
Show deployments.
```bash
kubectl get deployments                   # List deployments
kubectl get deploy                        # Short form
kubectl get deployments -n namespace
kubectl get deployments -A                # All namespaces
kubectl get deployments -o wide
kubectl get deployments --show-labels
```

### `kubectl create deployment` - Create Deployment
Create a new deployment.
```bash
kubectl create deployment nginx --image=nginx:latest
kubectl create deployment nginx --image=nginx --replicas=3
kubectl create deployment nginx --image=nginx --port=80
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
```

### `kubectl describe deployment` - Deployment Details
Show deployment details.
```bash
kubectl describe deployment nginx
kubectl describe deployment nginx -n namespace
```

### `kubectl scale` - Scale Deployment
Change number of replicas.
```bash
kubectl scale deployment nginx --replicas=5
kubectl scale deployment nginx --replicas=3 -n namespace
kubectl scale --replicas=0 deployment/nginx  # Scale to zero
kubectl scale deployment nginx --current-replicas=3 --replicas=5  # Conditional scale
```

### `kubectl rollout` - Manage Rollouts
Manage deployment rollouts.
```bash
# Status
kubectl rollout status deployment/nginx   # Check rollout status
kubectl rollout status deployment/nginx -w  # Watch rollout

# History
kubectl rollout history deployment/nginx  # Show rollout history
kubectl rollout history deployment/nginx --revision=2  # Specific revision

# Undo
kubectl rollout undo deployment/nginx     # Rollback to previous
kubectl rollout undo deployment/nginx --to-revision=2  # Rollback to specific revision

# Pause/Resume
kubectl rollout pause deployment/nginx    # Pause rollout
kubectl rollout resume deployment/nginx   # Resume rollout

# Restart
kubectl rollout restart deployment/nginx  # Restart deployment
```

### `kubectl set image` - Update Image
Update container images.
```bash
kubectl set image deployment/nginx nginx=nginx:1.21
kubectl set image deployment/nginx nginx=nginx:1.21 --record
kubectl set image deployment/nginx container1=image1 container2=image2
```

### `kubectl edit deployment` - Edit Deployment
Edit deployment configuration.
```bash
kubectl edit deployment nginx             # Edit deployment
kubectl edit deployment nginx -n namespace
kubectl edit deployment nginx -o yaml     # Edit as YAML
```

---

## Services

### `kubectl get services` - List Services
Show services.
```bash
kubectl get services                      # List services
kubectl get svc                           # Short form
kubectl get services -n namespace
kubectl get services -A
kubectl get services -o wide
kubectl get services --show-labels
```

### `kubectl expose` - Expose Resource
Create a service for a deployment/pod.
```bash
kubectl expose deployment nginx --port=80 --target-port=80
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl expose deployment nginx --port=80 --name=nginx-svc
kubectl expose pod nginx --port=80 --name=nginx-pod-svc
```

### `kubectl describe service` - Service Details
Show service details.
```bash
kubectl describe service nginx
kubectl describe service nginx -n namespace
kubectl describe svc nginx
```

### `kubectl delete service` - Delete Service
Remove services.
```bash
kubectl delete service nginx
kubectl delete service nginx -n namespace
kubectl delete svc nginx
```

---

## ConfigMaps and Secrets

### `kubectl get configmaps` - List ConfigMaps
Show ConfigMaps.
```bash
kubectl get configmaps                    # List ConfigMaps
kubectl get cm                            # Short form
kubectl get configmaps -n namespace
kubectl describe configmap name
kubectl get configmap name -o yaml
```

### `kubectl create configmap` - Create ConfigMap
Create ConfigMaps.
```bash
# From literal values
kubectl create configmap app-config \
  --from-literal=key1=value1 \
  --from-literal=key2=value2

# From file
kubectl create configmap app-config --from-file=config.json
kubectl create configmap app-config --from-file=key=config.json

# From directory
kubectl create configmap app-config --from-file=config-dir/

# From env file
kubectl create configmap app-config --from-env-file=.env

# Dry run to generate YAML
kubectl create configmap app-config \
  --from-literal=key=value \
  --dry-run=client -o yaml > configmap.yaml
```

### `kubectl get secrets` - List Secrets
Show secrets.
```bash
kubectl get secrets                       # List secrets
kubectl get secrets -n namespace
kubectl describe secret name
kubectl get secret name -o yaml
kubectl get secret name -o jsonpath='{.data.password}' | base64 -d
```

### `kubectl create secret` - Create Secret
Create secrets.
```bash
# Generic secret
kubectl create secret generic app-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

# From file
kubectl create secret generic app-secret --from-file=ssh-key=~/.ssh/id_rsa

# Docker registry
kubectl create secret docker-registry registry-creds \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=password \
  --docker-email=user@example.com

# TLS secret
kubectl create secret tls tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key

# Dry run
kubectl create secret generic app-secret \
  --from-literal=key=value \
  --dry-run=client -o yaml
```

---

## Apply and Manage Resources

### `kubectl apply` - Apply Configuration
Create or update resources from files.
```bash
kubectl apply -f deployment.yaml          # Apply from file
kubectl apply -f directory/               # Apply all files in directory
kubectl apply -f https://example.com/resource.yaml  # From URL
kubectl apply -k directory/               # Apply kustomization
kubectl apply -f deployment.yaml --dry-run=client  # Dry run
kubectl apply -f deployment.yaml --record # Record command in annotations
kubectl apply -f deployment.yaml --force  # Force apply
kubectl apply -f - <<EOF                  # Apply from stdin
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
EOF
```

### `kubectl create` - Create Resources
Create resources (imperative).
```bash
kubectl create -f deployment.yaml         # Create from file
kubectl create -f deployment.yaml --dry-run=client -o yaml
kubectl create -f deployment.yaml --save-config  # Save config in annotation
```

### `kubectl replace` - Replace Resources
Replace existing resources.
```bash
kubectl replace -f deployment.yaml        # Replace resource
kubectl replace -f deployment.yaml --force  # Delete and recreate
```

### `kubectl delete` - Delete Resources
Remove resources.
```bash
kubectl delete -f deployment.yaml         # Delete from file
kubectl delete pod pod-name               # Delete by name
kubectl delete pods --all                 # Delete all pods
kubectl delete pods -l app=nginx          # Delete by label
kubectl delete pods --field-selector=status.phase=Failed
kubectl delete all --all                  # Delete all resources
kubectl delete all -l app=nginx           # Delete all with label
kubectl delete namespace dev              # Delete namespace
kubectl delete pod pod-name --grace-period=0 --force  # Force delete
```

### `kubectl patch` - Update Resources
Patch (partially update) resources.
```bash
# JSON patch
kubectl patch deployment nginx -p '{"spec":{"replicas":5}}'

# Strategic merge patch
kubectl patch deployment nginx --type=strategic -p '{"spec":{"replicas":3}}'

# JSON merge patch
kubectl patch deployment nginx --type=merge -p '{"spec":{"replicas":3}}'

# From file
kubectl patch deployment nginx --patch-file=patch.yaml

# Example patches
kubectl patch pod nginx -p '{"metadata":{"labels":{"version":"v2"}}}'
kubectl patch svc nginx -p '{"spec":{"type":"LoadBalancer"}}'
```

---

## Labels and Annotations

### `kubectl label` - Manage Labels
Add or update labels.
```bash
kubectl label pod nginx env=production    # Add label
kubectl label pod nginx env=prod --overwrite  # Update label
kubectl label pod nginx env-              # Remove label
kubectl label pods --all app=nginx        # Label all pods
kubectl label pod nginx env=prod version=v1  # Multiple labels
kubectl label -f deployment.yaml env=prod # Label from file
```

### `kubectl annotate` - Manage Annotations
Add or update annotations.
```bash
kubectl annotate pod nginx description="My pod"
kubectl annotate pod nginx description="Updated" --overwrite
kubectl annotate pod nginx description-   # Remove annotation
kubectl annotate pods --all owner=team
```

---

## Resource Inspection

### `kubectl get` - Get Resources
List resources.
```bash
# Common resources
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get configmaps
kubectl get secrets
kubectl get namespaces
kubectl get nodes
kubectl get all                           # All common resources
kubectl get all -A                        # All resources in all namespaces

# Output formats
kubectl get pods -o wide                  # Wide output
kubectl get pods -o yaml                  # YAML format
kubectl get pods -o json                  # JSON format
kubectl get pods -o name                  # Names only
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
kubectl get pods -o custom-columns-file=columns.txt

# Sorting
kubectl get pods --sort-by=.metadata.creationTimestamp
kubectl get pods --sort-by=.status.startTime

# Filtering
kubectl get pods --field-selector=status.phase=Running
kubectl get pods -l app=nginx,tier=frontend
kubectl get pods -l 'environment in (production,staging)'
kubectl get pods -l 'app!=nginx'

# Watch
kubectl get pods -w                       # Watch for changes
kubectl get pods -w -o wide
```

### `kubectl describe` - Describe Resources
Show detailed resource information.
```bash
kubectl describe pod pod-name
kubectl describe deployment nginx
kubectl describe service nginx
kubectl describe node node-name
kubectl describe pods                     # All pods
kubectl describe pods -l app=nginx        # By label
```

### `kubectl top` - Resource Usage
Show resource usage.
```bash
kubectl top nodes                         # Node resource usage
kubectl top pods                          # Pod resource usage
kubectl top pods -A                       # All namespaces
kubectl top pods -l app=nginx             # By label
kubectl top pod pod-name --containers     # Per-container usage
```

---

## Advanced Commands

### `kubectl run` - Run Pods
Run a pod (imperative).
```bash
kubectl run nginx --image=nginx           # Run pod
kubectl run nginx --image=nginx --port=80 # With port
kubectl run nginx --image=nginx --env="KEY=value"  # With env var
kubectl run nginx --image=nginx --labels="app=nginx,tier=frontend"
kubectl run nginx --image=nginx --dry-run=client -o yaml  # Generate YAML
kubectl run nginx --image=nginx --rm -it -- /bin/bash  # Interactive, delete on exit
kubectl run busybox --image=busybox --restart=Never -- sleep 3600
kubectl run nginx --image=nginx --expose --port=80  # Create pod and service
```

### `kubectl debug` - Debug Pods
Debug running pods (Kubernetes 1.18+).
```bash
kubectl debug pod-name -it --image=busybox  # Debug with ephemeral container
kubectl debug pod-name -it --copy-to=pod-name-debug  # Create debug copy
kubectl debug node/node-name -it --image=ubuntu  # Debug node
kubectl debug -it pod-name --image=busybox --target=container-name
```

### `kubectl attach` - Attach to Running Container
Attach to a running container.
```bash
kubectl attach pod-name                   # Attach to pod
kubectl attach pod-name -c container-name # Attach to specific container
kubectl attach pod-name -it               # Interactive mode
```

### `kubectl wait` - Wait for Condition
Wait for specific conditions.
```bash
kubectl wait --for=condition=Ready pod/nginx --timeout=60s
kubectl wait --for=condition=Available deployment/nginx --timeout=300s
kubectl wait --for=delete pod/nginx --timeout=60s
kubectl wait --for=jsonpath='{.status.phase}'=Running pod/nginx
```

### `kubectl diff` - Show Differences
Show differences between live and local configurations.
```bash
kubectl diff -f deployment.yaml           # Show diff
kubectl diff -f directory/                # Diff directory
```

---

## StatefulSets and DaemonSets

### `kubectl get statefulsets` - List StatefulSets
Show StatefulSets.
```bash
kubectl get statefulsets                  # List StatefulSets
kubectl get sts                           # Short form
kubectl describe statefulset name
kubectl scale statefulset name --replicas=5
kubectl rollout status statefulset/name
kubectl delete statefulset name
```

### `kubectl get daemonsets` - List DaemonSets
Show DaemonSets.
```bash
kubectl get daemonsets                    # List DaemonSets
kubectl get ds                            # Short form
kubectl describe daemonset name
kubectl rollout status daemonset/name
kubectl delete daemonset name
```

---

## Jobs and CronJobs

### `kubectl get jobs` - List Jobs
Show jobs.
```bash
kubectl get jobs                          # List jobs
kubectl describe job job-name
kubectl logs job/job-name                 # Job logs
kubectl delete job job-name
```

### `kubectl create job` - Create Job
Create a job.
```bash
kubectl create job my-job --image=busybox -- echo "Hello"
kubectl create job my-job --image=busybox --dry-run=client -o yaml
kubectl create job test-job --from=cronjob/cron-job  # Create from CronJob
```

### `kubectl get cronjobs` - List CronJobs
Show CronJobs.
```bash
kubectl get cronjobs                      # List CronJobs
kubectl get cj                            # Short form
kubectl describe cronjob name
kubectl delete cronjob name
```

### `kubectl create cronjob` - Create CronJob
Create a CronJob.
```bash
kubectl create cronjob backup \
  --image=backup:latest \
  --schedule="0 2 * * *" \
  -- /backup.sh

kubectl create cronjob backup \
  --image=backup:latest \
  --schedule="*/5 * * * *" \
  --dry-run=client -o yaml
```

---

## Persistent Volumes

### `kubectl get pv` - List Persistent Volumes
Show PersistentVolumes.
```bash
kubectl get pv                            # List PVs
kubectl get persistentvolumes
kubectl describe pv pv-name
kubectl delete pv pv-name
```

### `kubectl get pvc` - List Persistent Volume Claims
Show PersistentVolumeClaims.
```bash
kubectl get pvc                           # List PVCs
kubectl get persistentvolumeclaims
kubectl get pvc -n namespace
kubectl describe pvc pvc-name
kubectl delete pvc pvc-name
```

---

## Ingress

### `kubectl get ingress` - List Ingress
Show Ingress resources.
```bash
kubectl get ingress                       # List Ingress
kubectl get ing                           # Short form
kubectl get ingress -A
kubectl describe ingress ingress-name
kubectl delete ingress ingress-name
```

---

## RBAC

### `kubectl get roles` - List Roles
Show RBAC roles.
```bash
kubectl get roles                         # List roles
kubectl get roles -A
kubectl describe role role-name
kubectl get rolebindings                  # Role bindings
kubectl describe rolebinding binding-name
```

### `kubectl get clusterroles` - List ClusterRoles
Show cluster-wide roles.
```bash
kubectl get clusterroles                  # List cluster roles
kubectl describe clusterrole role-name
kubectl get clusterrolebindings           # Cluster role bindings
kubectl describe clusterrolebinding binding-name
```

### `kubectl auth` - Authorization
Check authorization.
```bash
# Can I?
kubectl auth can-i create pods            # Check if you can create pods
kubectl auth can-i create pods --namespace=dev
kubectl auth can-i create pods --as=user  # Check as different user
kubectl auth can-i '*' '*'                # Check if admin

# Who can?
kubectl auth whoami                       # Show current user info (1.28+)

# Reconcile
kubectl auth reconcile -f rbac.yaml       # Create or update RBAC
```

---

## API Resources

### `kubectl api-resources` - List API Resources
Show available resource types.
```bash
kubectl api-resources                     # List all resources
kubectl api-resources --namespaced=true   # Namespaced resources
kubectl api-resources --namespaced=false  # Cluster-wide resources
kubectl api-resources --api-group=apps    # Specific API group
kubectl api-resources -o wide             # With more details
kubectl api-resources -o name             # Names only
```

### `kubectl api-versions` - List API Versions
Show available API versions.
```bash
kubectl api-versions                      # List API versions
```

### `kubectl explain` - Explain Resources
Show resource documentation.
```bash
kubectl explain pods                      # Explain pods
kubectl explain pod.spec                  # Explain pod spec
kubectl explain pod.spec.containers       # Explain containers
kubectl explain deployment.spec.replicas
kubectl explain --recursive pod.spec      # Show all fields
```

---

## Plugin and Extension

### `kubectl plugin` - Manage Plugins
List and manage kubectl plugins.
```bash
kubectl plugin list                       # List installed plugins
kubectl krew install plugin-name          # Install plugin (with krew)
kubectl krew upgrade                      # Upgrade plugins
kubectl krew uninstall plugin-name        # Uninstall plugin
```

---

## Troubleshooting

### `kubectl events` - View Events
Show cluster events.
```bash
kubectl get events                        # List events
kubectl get events -A                     # All namespaces
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector type=Warning
kubectl get events --field-selector involvedObject.name=pod-name
kubectl get events -w                     # Watch events
```

### Debugging Pods
```bash
# Check pod status
kubectl get pods
kubectl describe pod pod-name

# View logs
kubectl logs pod-name
kubectl logs pod-name --previous
kubectl logs pod-name -c container-name

# Execute commands
kubectl exec -it pod-name -- sh
kubectl exec pod-name -- env

# Check events
kubectl get events --field-selector involvedObject.name=pod-name

# Port forward for testing
kubectl port-forward pod-name 8080:80

# Copy files for inspection
kubectl cp pod-name:/path/to/file ./local-file
```

### Network Debugging
```bash
# Run debug pod
kubectl run debug --image=nicolaka/netshoot -it --rm -- /bin/bash

# DNS debugging
kubectl run debug --image=busybox -it --rm -- nslookup kubernetes.default

# Test connectivity
kubectl run debug --image=busybox -it --rm -- wget -O- service-name

# Check service endpoints
kubectl get endpoints service-name
```

### Node Issues
```bash
# Check node status
kubectl get nodes
kubectl describe node node-name
kubectl top nodes

# Cordon node (mark unschedulable)
kubectl cordon node-name

# Drain node (evict pods)
kubectl drain node-name --ignore-daemonsets --delete-emptydir-data

# Uncordon node
kubectl uncordon node-name

# Check node logs
kubectl logs -n kube-system pod-name
```

---

## Resource Management

### `kubectl set resources` - Set Resource Limits
Update resource limits.
```bash
kubectl set resources deployment nginx --limits=cpu=200m,memory=512Mi
kubectl set resources deployment nginx --requests=cpu=100m,memory=256Mi
kubectl set resources deployment nginx \
  --limits=cpu=200m,memory=512Mi \
  --requests=cpu=100m,memory=256Mi
```

### `kubectl autoscale` - Create Autoscaler
Create HorizontalPodAutoscaler.
```bash
kubectl autoscale deployment nginx --min=2 --max=10 --cpu-percent=80
kubectl get hpa                           # List autoscalers
kubectl describe hpa nginx
kubectl delete hpa nginx
```

---

## Output and Formatting

### JSON Path
```bash
# Get specific field
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o jsonpath='{.items[*].status.podIP}'

# Range with formatting
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# Conditional
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'
```

### Custom Columns
```bash
kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
STATUS:.status.phase,\
IP:.status.podIP

kubectl get nodes -o custom-columns=\
NAME:.metadata.name,\
CPU:.status.capacity.cpu,\
MEMORY:.status.capacity.memory
```

---

## Common Workflows

### Deploy Application
```bash
# Create deployment
kubectl create deployment nginx --image=nginx:latest

# Expose as service
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Scale
kubectl scale deployment nginx --replicas=3

# Update image
kubectl set image deployment/nginx nginx=nginx:1.21

# Check rollout
kubectl rollout status deployment/nginx
```

### Update Application
```bash
# Edit deployment
kubectl edit deployment nginx

# Or apply changes
kubectl apply -f deployment.yaml

# Watch rollout
kubectl rollout status deployment/nginx -w

# If issues, rollback
kubectl rollout undo deployment/nginx
```

### Debugging Application
```bash
# Check pods
kubectl get pods -l app=nginx

# Describe pod
kubectl describe pod pod-name

# View logs
kubectl logs -f pod-name

# Execute shell
kubectl exec -it pod-name -- /bin/bash

# Check service
kubectl get svc nginx
kubectl describe svc nginx

# Test connectivity
kubectl run debug --image=busybox -it --rm -- wget -O- nginx
```

---

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:
```bash
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kdel='kubectl delete'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kpf='kubectl port-forward'

alias kgp='kubectl get pods'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'

alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

alias kcn='kubectl config set-context --current --namespace'
alias kctx='kubectl config use-context'

alias kgpa='kubectl get pods --all-namespaces'
alias kgpw='kubectl get pods -o wide'
alias kgpwa='kubectl get pods -o wide --all-namespaces'
```

---

## Environment Variables

```bash
# Kubeconfig
export KUBECONFIG=~/.kube/config
export KUBECONFIG=~/.kube/config1:~/.kube/config2  # Multiple configs

# Default namespace
export KUBECTL_NAMESPACE=default

# Output format
export KUBECTL_OUTPUT=yaml

# Editor
export KUBE_EDITOR=vim
```

---

## Quick Reference

### Essential Commands
```bash
kubectl get pods              # List pods
kubectl describe pod name     # Pod details
kubectl logs pod-name         # View logs
kubectl exec -it pod -- sh    # Execute shell
kubectl apply -f file.yaml    # Apply config
kubectl delete -f file.yaml   # Delete resources
```

### Common Flags
```bash
-n, --namespace               # Namespace
-A, --all-namespaces          # All namespaces
-o, --output                  # Output format
-l, --selector                # Label selector
-w, --watch                   # Watch for changes
--dry-run=client              # Dry run
-f, --filename                # File or directory
```

### Resource Short Names
```bash
po = pods
deploy = deployments
svc = services
ns = namespaces
cm = configmaps
pv = persistentvolumes
pvc = persistentvolumeclaims
sts = statefulsets
ds = daemonsets
rs = replicasets
ing = ingress
hpa = horizontalpodautoscalers
```
