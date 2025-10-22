#!/bin/bash
# Docker Commands Cheat Sheet - Essential Commands Reference

# ====================
# Image Commands
# ====================

# Build an image
docker build -t myapp:latest .
docker build -t myapp:1.0.0 -f Dockerfile.prod .
docker build --no-cache -t myapp:latest .  # No cache

# List images
docker images
docker image ls

# Remove image
docker rmi myapp:latest
docker image rm myapp:latest

# Remove unused images
docker image prune
docker image prune -a  # Remove all unused

# Pull image from registry
docker pull nginx:alpine
docker pull ubuntu:22.04

# Push image to registry
docker tag myapp:latest username/myapp:latest
docker push username/myapp:latest

# Inspect image
docker image inspect nginx:alpine

# View image history
docker history myapp:latest

# Save/Load images
docker save -o myapp.tar myapp:latest
docker load -i myapp.tar


# ====================
# Container Commands
# ====================

# Run container
docker run -d --name mycontainer nginx:alpine
docker run -it ubuntu:22.04 bash  # Interactive
docker run -d -p 8080:80 nginx:alpine  # Port mapping
docker run -d -v /host/path:/container/path myapp  # Volume mount
docker run -d -e ENV_VAR=value myapp  # Environment variable
docker run --rm myapp  # Remove after exit

# List containers
docker ps  # Running containers
docker ps -a  # All containers

# Stop/Start/Restart container
docker stop mycontainer
docker start mycontainer
docker restart mycontainer

# Remove container
docker rm mycontainer
docker rm -f mycontainer  # Force remove running container

# Remove all stopped containers
docker container prune

# View logs
docker logs mycontainer
docker logs -f mycontainer  # Follow logs
docker logs --tail 100 mycontainer  # Last 100 lines

# Execute command in container
docker exec -it mycontainer bash
docker exec mycontainer ls /app
docker exec -u root mycontainer whoami  # As specific user

# Inspect container
docker inspect mycontainer
docker inspect --format='{{.State.Status}}' mycontainer

# View container stats
docker stats
docker stats mycontainer

# View container processes
docker top mycontainer

# Copy files
docker cp mycontainer:/app/file.txt ./file.txt
docker cp ./file.txt mycontainer:/app/

# Commit container to image
docker commit mycontainer myapp:new-version

# Export/Import containers
docker export mycontainer > container.tar
docker import container.tar myapp:imported


# ====================
# Volume Commands
# ====================

# Create volume
docker volume create myvolume

# List volumes
docker volume ls

# Inspect volume
docker volume inspect myvolume

# Remove volume
docker volume rm myvolume

# Remove unused volumes
docker volume prune

# Run with volume
docker run -d -v myvolume:/app/data myapp


# ====================
# Network Commands
# ====================

# Create network
docker network create mynetwork
docker network create --driver bridge mynetwork

# List networks
docker network ls

# Inspect network
docker network inspect mynetwork

# Connect/Disconnect container
docker network connect mynetwork mycontainer
docker network disconnect mynetwork mycontainer

# Remove network
docker network rm mynetwork

# Remove unused networks
docker network prune

# Run with network
docker run -d --network mynetwork myapp


# ====================
# Docker Compose Commands
# ====================

# Start services
docker-compose up
docker-compose up -d  # Detached mode
docker-compose up --build  # Rebuild images

# Stop services
docker-compose down
docker-compose down -v  # Remove volumes
docker-compose stop

# View logs
docker-compose logs
docker-compose logs -f  # Follow
docker-compose logs web  # Specific service

# List services
docker-compose ps

# Execute command
docker-compose exec web sh
docker-compose exec db psql -U user

# Build services
docker-compose build
docker-compose build --no-cache

# Scale services
docker-compose up -d --scale worker=3

# Restart services
docker-compose restart
docker-compose restart web

# Pull images
docker-compose pull


# ====================
# System Commands
# ====================

# View disk usage
docker system df

# Clean up everything
docker system prune
docker system prune -a  # More aggressive
docker system prune -a --volumes  # Include volumes

# View system info
docker info
docker version


# ====================
# Registry Commands
# ====================

# Login to registry
docker login
docker login registry.example.com

# Logout
docker logout

# Search images
docker search nginx


# ====================
# Debugging Commands
# ====================

# View container logs
docker logs -f --tail 100 mycontainer

# Inspect container config
docker inspect mycontainer | jq '.[0].Config'

# View container IP
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mycontainer

# View port mappings
docker port mycontainer

# Check container health
docker inspect --format='{{.State.Health.Status}}' mycontainer

# Monitor events
docker events
docker events --filter 'container=mycontainer'


# ====================
# Build Arguments
# ====================

# Build with args
docker build --build-arg VERSION=1.0.0 --build-arg ENV=prod -t myapp .

# Build for different platforms
docker buildx build --platform linux/amd64,linux/arm64 -t myapp .


# ====================
# Useful Aliases
# ====================

# Add to ~/.bashrc or ~/.zshrc:

# alias dps='docker ps'
# alias dpsa='docker ps -a'
# alias di='docker images'
# alias dex='docker exec -it'
# alias dlogs='docker logs -f'
# alias dcu='docker-compose up -d'
# alias dcd='docker-compose down'
# alias dcl='docker-compose logs -f'
# alias dprune='docker system prune -a --volumes'
