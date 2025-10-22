# Docker Boilerplate - Essential Syntax Reference

# ====================
# Base Image
# ====================
# Use an official base image
FROM node:18-alpine AS base

# Alternative base images:
# FROM python:3.11-slim
# FROM ubuntu:22.04
# FROM nginx:alpine
# FROM postgres:15

# ====================
# Metadata
# ====================
LABEL maintainer="your-email@example.com"
LABEL version="1.0.0"
LABEL description="Docker boilerplate with essential syntax"

# ====================
# Environment Variables
# ====================
ENV NODE_ENV=production \
    APP_PORT=3000 \
    APP_NAME="Docker Boilerplate"

# ====================
# Working Directory
# ====================
WORKDIR /app

# ====================
# Copy Files
# ====================
# Copy package files first (for better caching)
COPY package*.json ./

# Copy all files from current directory
# COPY . .

# Copy specific files/directories
# COPY src/ ./src/
# COPY config/ ./config/

# ====================
# Run Commands
# ====================
# RUN executes commands during build time

# Install dependencies
RUN npm install --production

# Multiple commands can be chained with &&
RUN apt-get update && \
    apt-get install -y curl vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /app/logs /app/data

# Change ownership
RUN chown -R node:node /app

# ====================
# User
# ====================
# Switch to non-root user for security
USER node

# ====================
# Expose Ports
# ====================
# Document which ports the container listens on
EXPOSE 3000
EXPOSE 8080

# ====================
# Volumes
# ====================
# Create mount points for persistent data
VOLUME ["/app/data", "/app/logs"]

# ====================
# Health Check
# ====================
# Check if container is healthy
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Alternative healthcheck:
# HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# ====================
# Entrypoint and CMD
# ====================
# ENTRYPOINT sets the main command (not easily overridden)
# CMD provides default arguments (can be overridden)

# Exec form (preferred)
ENTRYPOINT ["node"]
CMD ["server.js"]

# Shell form
# CMD npm start

# Combined example:
# ENTRYPOINT ["docker-entrypoint.sh"]
# CMD ["node", "server.js"]

# ====================
# Multi-stage Build Example
# ====================

# Build stage
FROM node:18-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /build/dist ./dist
COPY --from=builder /build/node_modules ./node_modules
COPY package*.json ./
EXPOSE 3000
USER node
CMD ["node", "dist/server.js"]

# ====================
# ARG (Build-time Variables)
# ====================
ARG BUILD_VERSION=1.0.0
ARG BUILD_DATE
ENV VERSION=${BUILD_VERSION}

# Use in RUN commands
RUN echo "Building version ${BUILD_VERSION} on ${BUILD_DATE}"

# ====================
# Common Patterns
# ====================

# Pattern 1: Node.js app
# FROM node:18-alpine
# WORKDIR /app
# COPY package*.json ./
# RUN npm ci --only=production
# COPY . .
# EXPOSE 3000
# USER node
# CMD ["node", "index.js"]

# Pattern 2: Python app
# FROM python:3.11-slim
# WORKDIR /app
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt
# COPY . .
# EXPOSE 8000
# CMD ["python", "app.py"]

# Pattern 3: Static website with Nginx
# FROM nginx:alpine
# COPY nginx.conf /etc/nginx/nginx.conf
# COPY --from=builder /app/dist /usr/share/nginx/html
# EXPOSE 80
# CMD ["nginx", "-g", "daemon off;"]
