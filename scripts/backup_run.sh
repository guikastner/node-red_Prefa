#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  MINIO_ENDPOINT
  MINIO_ACCESS_KEY
  MINIO_SECRET_KEY
  MINIO_BUCKET_NAME
  MINIO_MONGO_PREFIX
  MINIO_NODE_RED_PREFIX
  MONGO_CONTAINER_NAME
  MONGO_USER
  MONGO_PASSWORD
  NODE_RED_DATA_DIR
  BACKUP_LOCAL_DIR
)

for name in "${required_vars[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}"
    exit 1
  fi
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH."
  exit 1
fi

if ! command -v mc >/dev/null 2>&1; then
  echo "MinIO client 'mc' not found in PATH."
  exit 1
fi

if [[ ! -d "${NODE_RED_DATA_DIR}" ]]; then
  echo "Node-RED data directory does not exist: ${NODE_RED_DATA_DIR}"
  exit 1
fi

retention_days="${BACKUP_RETENTION_DAYS:-14}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
mongo_file="${BACKUP_LOCAL_DIR}/mongo-${timestamp}.archive.gz"
node_red_file="${BACKUP_LOCAL_DIR}/node-red-${timestamp}.tar.gz"
tmp_dir="$(mktemp -d)"
mc_config_dir="${tmp_dir}/mc-config"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${BACKUP_LOCAL_DIR}"

docker exec \
  -e MONGO_BACKUP_USER="${MONGO_USER}" \
  -e MONGO_BACKUP_PASS="${MONGO_PASSWORD}" \
  "${MONGO_CONTAINER_NAME}" \
  sh -c 'mongodump --archive --gzip --username "$MONGO_BACKUP_USER" --password "$MONGO_BACKUP_PASS" --authenticationDatabase admin' \
  > "${mongo_file}"

if [[ -f "${NODE_RED_DATA_DIR}/flows.json" ]]; then
  tar -czf "${node_red_file}" \
    -C "${NODE_RED_DATA_DIR}" \
    flows.json flows_cred.json package.json package-lock.json settings.js 2>/dev/null \
    || tar -czf "${node_red_file}" -C "${NODE_RED_DATA_DIR}" flows.json
else
  tar -czf "${node_red_file}" -C "${NODE_RED_DATA_DIR}" .
fi

export MC_CONFIG_DIR="${mc_config_dir}"
mc alias set backup "${MINIO_ENDPOINT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}" >/dev/null
mc cp "${mongo_file}" "backup/${MINIO_BUCKET_NAME}/backup/${MINIO_MONGO_PREFIX}/$(basename "${mongo_file}")" >/dev/null
mc cp "${node_red_file}" "backup/${MINIO_BUCKET_NAME}/backup/${MINIO_NODE_RED_PREFIX}/$(basename "${node_red_file}")" >/dev/null

find "${BACKUP_LOCAL_DIR}" -type f -mtime +"${retention_days}" -delete

echo "Backup finished successfully at ${timestamp}"
