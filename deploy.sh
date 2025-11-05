#!/bin/bash
set -e

# Pastikan semua variabel ini sudah di-set di lokal CI/CD atau terminal kamu:
# SERVER_HOST, SERVER_PORT, SERVER_USERNAME, DOCKERHUB_USERNAME, DOCKERHUB_TOKEN,
# CONTAINER_REPOSITORY (contoh: hendisantika/ecommerce), IMAGE_TAG, CONTAINER_NAME, APP_PORT

ssh -p "$SERVER_PORT" \
    -i key.txt \
    -o StrictHostKeyChecking=no \
    "$SERVER_USERNAME@$SERVER_HOST" \
    "DOCKERHUB_USERNAME='$DOCKERHUB_USERNAME' DOCKERHUB_TOKEN='$DOCKERHUB_TOKEN' CONTAINER_REPOSITORY='$CONTAINER_REPOSITORY' IMAGE_TAG='$IMAGE_TAG' CONTAINER_NAME='$CONTAINER_NAME' APP_PORT='$APP_PORT' bash -s" <<'ENDSSH'
set -e
cd ~/ecommerce

if [ -f .env ]; then
  set +a
  source .env || true
fi

start=$(date +"%s")

echo "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin
docker pull "$CONTAINER_REPOSITORY:$IMAGE_TAG"

if [ "$(docker ps -qa -f name=$CONTAINER_NAME)" ]; then
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "Container is running -> stopping it..."
        docker stop "$CONTAINER_NAME"
    fi
    docker rm -f "$CONTAINER_NAME"
fi

docker run -d --restart unless-stopped -p "$APP_PORT:$APP_PORT" --env-file .env --name "$CONTAINER_NAME" "$CONTAINER_REPOSITORY:$IMAGE_TAG"
docker ps --filter "name=$CONTAINER_NAME"

end=$(date +"%s")
diff=$((end - start))
echo "Deployed in: ${diff}s"
ENDSSH
