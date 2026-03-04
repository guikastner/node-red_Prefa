#!/usr/bin/env bash
set -euo pipefail

MINIO_ENDPOINT="${MINIO_ENDPOINT:-}"
MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY:-}"
MINIO_SECRET_KEY="${MINIO_SECRET_KEY:-}"
MINIO_BUCKET_NAME="${MINIO_BUCKET_NAME:-}"
MINIO_BUCKET_FOLDERS="${MINIO_BUCKET_FOLDERS:-}"

if [[ -z "${MINIO_BUCKET_NAME}" ]]; then
  echo "MINIO_BUCKET_NAME is empty, skipping MinIO provisioning."
  exit 0
fi

if [[ -z "${MINIO_ENDPOINT}" || -z "${MINIO_ACCESS_KEY}" || -z "${MINIO_SECRET_KEY}" ]]; then
  echo "MINIO_ENDPOINT, MINIO_ACCESS_KEY and MINIO_SECRET_KEY are required when MINIO_BUCKET_NAME is set."
  exit 1
fi

if ! command -v mc >/dev/null 2>&1; then
  echo "MinIO client 'mc' not found in PATH. Install mc on the host and retry."
  exit 1
fi

tmp_dir="$(mktemp -d)"
keep_file="${tmp_dir}/.keep"
mc_config_dir="${tmp_dir}/mc-config"
echo "created-by-opentofu" > "${keep_file}"
trap 'rm -rf "${tmp_dir}"' EXIT

export MC_CONFIG_DIR="${mc_config_dir}"
alias_name="target"

mc alias set "${alias_name}" "${MINIO_ENDPOINT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}" >/dev/null
mc mb --ignore-existing "${alias_name}/${MINIO_BUCKET_NAME}" >/dev/null

IFS=',' read -r -a folders <<< "${MINIO_BUCKET_FOLDERS}"
for raw_folder in "${folders[@]}"; do
  folder="$(echo "${raw_folder}" | xargs)"
  if [[ -z "${folder}" ]]; then
    continue
  fi

  mc cp "${keep_file}" "${alias_name}/${MINIO_BUCKET_NAME}/${folder}/.keep" >/dev/null
done

echo "MinIO bucket '${MINIO_BUCKET_NAME}' provisioned successfully."
