#!/bin/bash

# Configurable variables
CONTAINER_NAME="postgres-db"
IMAGE_NAME="postgres:16-alpine"
DATA_DIR="./data"
PORT=5432

# Load environment variables (e.g., POSTGRES_PASSWORD) from .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "⚠️  .env file not found. Set POSTGRES_PASSWORD manually or create one."
fi

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Check if container exists
if podman container exists "$CONTAINER_NAME"; then
  if podman ps -a --filter "name=$CONTAINER_NAME" --filter "status=running" | grep "$CONTAINER_NAME" >/dev/null; then
    echo "✅ Container '$CONTAINER_NAME' is already running."
  else
    echo "🔁 Starting existing container '$CONTAINER_NAME'..."
    podman start "$CONTAINER_NAME"
  fi
else
  echo "🚀 Creating and starting container '$CONTAINER_NAME'..."
  podman run -d \
    --name "$CONTAINER_NAME" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -v "$PWD/$DATA_DIR":/var/lib/postgresql/data \
    -p $PORT:5432 \
    "$IMAGE_NAME"
fi