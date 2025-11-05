#!/bin/bash

# --- set local vars (pastikan sudah di-export / tersedia di environment lokal) ---
# SERVER_PORT, SERVER_USERNAME, SERVER_HOST, DOCKERHUB_TOKEN, DOCKERHUB_USERNAME,
# CONTAINER_REPOSITORY, IMAGE_TAG, CONTAINER_NAME, APP_PORT

ssh -p "$SERVER_PORT" \
    -i key.txt \
    -o StrictHostKeyChecking=no \
    "$SERVER_USERNAME@$SERVER_HOST" \
    "DOCKERHUB_TOKEN='$DOCKERHUB_TOKEN' DOCKERHUB_USERNAME='$DOCKERHUB_USERNAME' CONTAINER_REPOSITORY='$CONTAINER_REPOSITORY' IMAGE_TAG='$IMAGE_TAG' CONTAINER_NAME='$CONTAINER_NAME' APP_PORT='$APP_PORT' bash -s" <<'ENDSSH'
set -euo pipefail
cd ~/ecommerce || exit 1

# load env file on remote (if kamu masih ingin pakai .env)
if [ -f .env ]; then
  # don't export automatically unless .env uses export VAR=...
  set +a
  # shellcheck disable=SC1091
  source .env || true
fi

start=$(date +"%s")

# login to docker using env passed above
echo "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin
docker pull "$CONTAINER_REPOSITORY:$IMAGE_TAG"

# stop and remove existing container if present
if [ "$(docker ps -qa -f name=$CONTAINER_NAME)" ]; then
  if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Container is running -> stopping it..."
    docker stop "$CONTAINER_NAME" || true
  fi
  docker rm -f "$CONTAINER_NAME" || true
fi

# run new container
docker run -d --restart unless-stopped -p "$APP_PORT:$APP_PORT" --env-file .env --name "$CONTAINER_NAME" "$CONTAINER_REPOSITORY:$IMAGE_TAG"
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

end=$(date +"%s")
diff=$((end - start))
echo "Deployed in : ${diff}s"
ENDSSH

# Periksa exit code SSH (baris ini harus di-shell lokal — no escaping)
if [ $? -eq 0 ]; then
  exit 0
else
  exit 1
fi
