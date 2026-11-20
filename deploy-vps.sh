#!/usr/bin/env bash
set -euo pipefail

cd /opt/auto-deploy

docker_config="$(mktemp -d)"
export DOCKER_CONFIG="$docker_config"
cleanup() {
  docker logout ghcr.io >/dev/null 2>&1 || true
  rm -rf "$docker_config"
}
trap cleanup EXIT

printf '%s' "$GHCR_TOKEN" | docker login ghcr.io --username "$GHCR_USER" --password-stdin
docker compose pull backend
docker compose up -d --no-build --remove-orphans

attempt=0
while [ "$attempt" -lt 30 ]; do
  if docker compose exec -T frontend wget -q -O- http://localhost/api/health | grep -q '"status":"healthy"'; then
    exit 0
  fi
  attempt=$((attempt + 1))
  sleep 2
done

docker compose ps
docker compose logs --tail=100
exit 1
