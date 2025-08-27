#!/bin/zsh

# Configurable variables
CONTAINER_NAME="postgres-db"
IMAGE_NAME="postgres:16-alpine"
DATA_DIR="./data"
PORT=5432
VOLUME_NAME="postgres-data"

# Load environment variables (e.g., POSTGRES_PASSWORD) from .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "⚠️  .env file not found. Set POSTGRES_PASSWORD manually or create one."
fi

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Decide storage strategy: named volume on macOS/Windows; bind mount on Linux
OS_NAME="$(uname -s)"
USE_NAMED_VOLUME="true"
VOLUME_SPEC=""
STORAGE_DESC=""
RUN_USER=""

if [ "$OS_NAME" = "Linux" ]; then
  USE_NAMED_VOLUME="false"
fi

if [ "$USE_NAMED_VOLUME" = "true" ]; then
  # Ensure named volume exists
  if ! podman volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    podman volume create "$VOLUME_NAME" >/dev/null
  fi
  VOLUME_SPEC="${VOLUME_NAME}:/var/lib/postgresql/data"
  STORAGE_DESC="named volume '${VOLUME_NAME}'"
  # Run as root initially so entrypoint can fix ownership/permissions, then it drops to 'postgres'
  RUN_USER="--user root"
else
  # Bind mount with SELinux relabel
  ABS_DATA_DIR="$(pwd)/$DATA_DIR"
  VOLUME_SPEC="${ABS_DATA_DIR}:/var/lib/postgresql/data:Z"
  STORAGE_DESC="bind mount '${ABS_DATA_DIR}'"
  RUN_USER=""  # default user is fine on native Linux
fi

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
  echo "Storage: $STORAGE_DESC"
  podman run -d \
    --name "$CONTAINER_NAME" \
    --pull=always \
    --restart=unless-stopped \
    $RUN_USER \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -v "$VOLUME_SPEC" \
    -p $PORT:5432 \
    "$IMAGE_NAME"
fi
