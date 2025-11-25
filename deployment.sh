#!/bin/bash

echo "Starting deployment..."

# Check if Docker is installed
if ! command -v docker >/dev/null; then
  echo "Docker is not installed. Please install Docker first."
  exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose >/dev/null; then
  echo "Docker Compose is not installed."
  exit 1
fi

echo "Docker and Docker Compose are ready."

# Ports needed for backend and transactions
PORTS=(3000 5000)

for port in "${PORTS[@]}"; do
  if lsof -i:$port >/dev/null 2>&1; then
    echo "Port $port is already being used. Please free it before running the script."
    exit 1
  else
    echo "Port $port is free."
  fi
done

# Use current folder
echo "Project folder: $(pwd)"

# Make sure docker-compose.yml exists
if [[ ! -f "docker-compose.yml" ]]; then
  echo "docker-compose.yml not found in this directory."
  exit 1
fi

echo "docker-compose.yml found."

# Build and start containers
echo "Building and starting services..."
docker compose up --build -d

# Wait for containers to start
sleep 5

echo "Checking if services are responding..."
curl -I http://localhost:3000 2>/dev/null
curl -I http://localhost:5000 2>/dev/null

echo "Health checks done."

# Show containers
echo "Running containers:"
docker ps

# Capture nginx container ID
NGINX_ID=$(docker ps | grep "nginx" | awk '{print $1}')

if [[ -z "$NGINX_ID" ]]; then
  echo "Nginx container not found."
  exit 1
fi

echo "Nginx container ID: $NGINX_ID"

# Test nginx page
echo "Checking nginx home page..."
curl -I http://localhost

# Make sure jq exists
if ! command -v jq >/dev/null; then
  echo "jq is not installed. Install jq before running the script."
  exit 1
fi

# Inspect nginx image
echo "Saving nginx image details..."
docker inspect nginx:alpine > nginx-logs.txt

echo "Reading values from nginx-logs.txt..."

echo "RepoTags:"
jq '.[0].RepoTags' nginx-logs.txt

echo "Created:"
jq '.[0].Created' nginx-logs.txt

echo "OS:"
jq '.[0].Os' nginx-logs.txt

echo "Config:"
jq '.[0].Config' nginx-logs.txt

echo "Exposed Ports:"
jq '.[0].Config.ExposedPorts' nginx-logs.txt

echo "Deployment complete."
