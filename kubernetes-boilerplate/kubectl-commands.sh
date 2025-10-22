#!/bin/bash
# Kubectl Commands Cheat Sheet - Essential Commands Reference

# ====================
# Cluster Info
# ====================

# Cluster information
kubectl cluster-info
kubectl version

# View cluster nodes
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <node-name>

# Node resource usage
kubectl top nodes

# ====================
# Context and Namespace
# ====================

# View contexts
kubectl config get-contexts
kubectl config current-context

# Switch context
kubectl config use-context <context-name>

# Set default namespace
kubectl config set-context --current --namespace=<namespace>

# View namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace production
kubectl create ns dev

# ====================
# Pod Commands
# ====================

# List pods
kubectl get pods
kubectl get pods -n <namespace>
kubectl get pods --all-namespaces
kubectl get pods -A
kubectl get pods -o wide
kubectl get pods --show-labels
kubectl get pods -l app=web

# Describe pod
kubectl describe pod <pod-name>
kubectl describe pod <pod-name> -n <namespace>

# Create pod
kubectl run nginx --image=nginx:alpine
kubectl run test --image=busybox -it --rm -- sh  # Interactive, delete on exit

# Delete pod
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> -n <namespace>
kubectl delete pod --all  # Delete all pods

# Pod logs
kubectl logs <pod-name>
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -f  # Follow logs
kubectl logs <pod-name> --tail=100  # Last 100 lines
kubectl logs <pod-name> -c <container-name>  # Specific container
kubectl logs <pod-name> --previous  # Previous container logs

# Execute command in pod
kubectl exec <pod-name> -- ls /app
kubectl exec -it <pod-name> -- bash
kubectl exec -it <pod-name> -- sh
kubectl exec <pod-name> -c <container-name> -- command

# Copy files
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp ./local-file <pod-name>:/path/to/file

# Port forwarding
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward svc/<service-name> 8080:80

# Pod resource usage
kubectl top pod <pod-name>
kubectl top pods -n <namespace>

# ====================
# Deployment Commands
# ====================

# List deployments
kubectl get deployments
kubectl get deploy
kubectl get deploy -n <namespace>
kubectl get deploy -o wide

# Describe deployment
kubectl describe deployment <deployment-name>

# Create deployment
kubectl create deployment nginx --image=nginx:alpine
kubectl create deployment web --image=nginx --replicas=3

# Delete deployment
kubectl delete deployment <deployment-name>

# Scale deployment
kubectl scale deployment <deployment-name> --replicas=5

# Update deployment image
kubectl set image deployment/<deployment-name> <container-name>=<new-image>
kubectl set image deployment/web nginx=nginx:1.21

# Rollout commands
kubectl rollout status deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name>  # Rollback
kubectl rollout undo deployment/<deployment-name> --to-revision=2
kubectl rollout restart deployment/<deployment-name>
kubectl rollout pause deployment/<deployment-name>
kubectl rollout resume deployment/<deployment-name>

# ====================
# Service Commands
# ====================

# List services
kubectl get services
kubectl get svc
kubectl get svc -n <namespace>

# Describe service
kubectl describe svc <service-name>

# Create service
kubectl expose deployment <deployment-name> --port=80 --target-port=8080
kubectl expose deployment web --type=LoadBalancer --port=80

# Delete service
kubectl delete svc <service-name>

# ====================
# ConfigMap Commands
# ====================

# List ConfigMaps
kubectl get configmaps
kubectl get cm

# Describe ConfigMap
kubectl describe cm <configmap-name>

# Create ConfigMap from literals
kubectl create configmap app-config \
  --from-literal=key1=value1 \
  --from-literal=key2=value2

# Create from file
kubectl create configmap app-config --from-file=config.json
kubectl create configmap app-config --from-file=config-dir/

# Create from env file
kubectl create configmap app-config --from-env-file=.env

# View ConfigMap data
kubectl get cm <configmap-name> -o yaml
kubectl get cm <configmap-name> -o jsonpath='{.data}'

# Delete ConfigMap
kubectl delete cm <configmap-name>

# ====================
# Secret Commands
# ====================

# List secrets
kubectl get secrets
kubectl get secret

# Describe secret
kubectl describe secret <secret-name>

# Create secret from literals
kubectl create secret generic app-secrets \
  --from-literal=username=admin \
  --from-literal=password=secret123

# Create from file
kubectl create secret generic app-secrets \
  --from-file=ssh-key=~/.ssh/id_rsa

# Docker registry secret
kubectl create secret docker-registry registry-creds \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=password \
  --docker-email=user@example.com

# TLS secret
kubectl create secret tls tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key

# View secret
kubectl get secret <secret-name> -o yaml
kubectl get secret <secret-name> -o jsonpath='{.data.password}' | base64 -d

# Delete secret
kubectl delete secret <secret-name>

# ====================
# Volume Commands
# ====================

# List PersistentVolumes
kubectl get pv

# List PersistentVolumeClaims
kubectl get pvc
kubectl get pvc -n <namespace>

# Describe PVC
kubectl describe pvc <pvc-name>

# ====================
# Apply/Create/Delete Resources
# ====================

# Apply configuration
kubectl apply -f deployment.yaml
kubectl apply -f directory/
kubectl apply -f https://example.com/deployment.yaml

# Create resources
kubectl create -f deployment.yaml

# Delete resources
kubectl delete -f deployment.yaml
kubectl delete -f directory/

# Replace resource
kubectl replace -f deployment.yaml
kubectl replace --force -f deployment.yaml  # Delete and recreate

# ====================
# Labels and Selectors
# ====================

# Show labels
kubectl get pods --show-labels

# Filter by label
kubectl get pods -l app=web
kubectl get pods -l 'env in (prod,staging)'
kubectl get pods -l app=web,tier=frontend

# Add label
kubectl label pod <pod-name> env=production
kubectl label pod <pod-name> env=production --overwrite

# Remove label
kubectl label pod <pod-name> env-

# ====================
# Annotations
# ====================

# Add annotation
kubectl annotate pod <pod-name> description='My pod'

# Remove annotation
kubectl annotate pod <pod-name> description-

# ====================
# Resource Editing
# ====================

# Edit resource
kubectl edit deployment <deployment-name>
kubectl edit svc <service-name>

# Patch resource
kubectl patch deployment <deployment-name> -p '{"spec":{"replicas":3}}'

# ====================
# Debugging
# ====================

# Debug with ephemeral container (K8s 1.23+)
kubectl debug <pod-name> -it --image=busybox

# Create debug pod
kubectl run debug --image=busybox -it --rm -- sh

# Events
kubectl get events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n <namespace> --watch

# Describe issues
kubectl describe pod <pod-name>
kubectl describe node <node-name>

# Resource usage
kubectl top nodes
kubectl top pods
kubectl top pod <pod-name> --containers

# ====================
# StatefulSet Commands
# ====================

# List StatefulSets
kubectl get statefulsets
kubectl get sts

# Scale StatefulSet
kubectl scale sts <statefulset-name> --replicas=5

# Update StatefulSet
kubectl rollout status sts/<statefulset-name>
kubectl rollout history sts/<statefulset-name>

# ====================
# DaemonSet Commands
# ====================

# List DaemonSets
kubectl get daemonsets
kubectl get ds

# ====================
# Job and CronJob Commands
# ====================

# List jobs
kubectl get jobs

# Create job
kubectl create job test-job --image=busybox -- echo "Hello"

# Delete job
kubectl delete job <job-name>

# List CronJobs
kubectl get cronjobs
kubectl get cj

# Create CronJob
kubectl create cronjob backup --image=backup:latest --schedule="0 2 * * *" -- /backup.sh

# ====================
# Ingress Commands
# ====================

# List ingress
kubectl get ingress
kubectl get ing

# Describe ingress
kubectl describe ing <ingress-name>

# ====================
# Output Formats
# ====================

# YAML output
kubectl get pod <pod-name> -o yaml

# JSON output
kubectl get pod <pod-name> -o json

# Wide output
kubectl get pods -o wide

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# JSONPath
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].image}'

# ====================
# Resource Types
# ====================

# List all resource types
kubectl api-resources

# Get all resources
kubectl get all
kubectl get all -n <namespace>

# ====================
# Useful Combinations
# ====================

# Delete all pods with label
kubectl delete pods -l app=web

# Get pod IPs
kubectl get pods -o wide | awk '{print $1, $6}'

# Watch resources
kubectl get pods --watch
kubectl get pods -w

# Dry run (test without creating)
kubectl create deployment test --image=nginx --dry-run=client -o yaml
kubectl apply -f deployment.yaml --dry-run=client

# Server-side dry run
kubectl apply -f deployment.yaml --dry-run=server

# ====================
# Useful Aliases
# ====================

# Add to ~/.bashrc or ~/.zshrc:

# alias k='kubectl'
# alias kg='kubectl get'
# alias kd='kubectl describe'
# alias kdel='kubectl delete'
# alias kl='kubectl logs'
# alias kex='kubectl exec -it'
# alias kgp='kubectl get pods'
# alias kgs='kubectl get svc'
# alias kgd='kubectl get deployments'
# alias kaf='kubectl apply -f'
# alias kdf='kubectl delete -f'

# ====================
# Completion
# ====================

# Bash completion
# source <(kubectl completion bash)
# echo "source <(kubectl completion bash)" >> ~/.bashrc

# Zsh completion
# source <(kubectl completion zsh)
# echo "source <(kubectl completion zsh)" >> ~/.zshrc
