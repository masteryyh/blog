#!/bin/bash

IMAGE_NAME="masteryyh/blog"
GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
IMAGE_TAG="$(date +%Y%m%d)-$GIT_COMMIT_HASH"
IMAGE="$IMAGE_NAME:$IMAGE_TAG"
IMAGE_LATEST="$IMAGE_NAME:latest"

NAMESPACE="${NAMESPACE:-blog-system}"
INGRESS_HOST="${INGRESS_HOST:-blog.minaandyyh.win}"

docker build -t "$IMAGE" .
docker tag "$IMAGE" "$IMAGE_LATEST"

docker push "$IMAGE"
docker push "$IMAGE_LATEST"

helm package charts/blog
helm upgrade --install blog ./blog-0.1.0.tgz \
  --set image.tag="$IMAGE_TAG" \
  --set ingress.hosts[0].host="$INGRESS_HOST" \
  -f charts/blog/values.yaml \
  -n "$NAMESPACE" \
  --create-namespace
rm -f blog-0.1.0.tgz
