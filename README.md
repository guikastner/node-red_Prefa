# Node-RED/Mongo Infrastructure (OpenTofu)

Infrastructure as code to provision the stack using OpenTofu and the Docker provider. The stack keeps private east-west traffic on an internal Docker network (no host port publishing), while selected containers also use the default `bridge` network for outbound internet access, and exposes services through a Cloudflare Tunnel.

## Components
- 1× Node-RED container (`nodered/node-red:4.1.4-22`): name comes from `name_prefix` + `node_red_name` (default `lab-node1`) on port `1880` inside the mesh.
- 1× MongoDB container (`mongo:7.0.14`): default `lab-mongo1`.
- 1× Cloudflare Tunnel agent (`cloudflare/cloudflared:latest`): default `lab-cloudflared1`, routing external CNAME to the Node-RED instance. Tunnel and DNS records are created via the Cloudflare provider, not manually.
- 1× MinIO bucket bootstrap (script-driven via OpenTofu `null_resource`): creates a bucket and first-level folders on a remote MinIO endpoint.
- Internal bridge network `${name_prefix}net` marked as `internal` for private inter-container traffic.
- Node-RED is attached to `${name_prefix}net` and also to Docker `bridge` for outbound internet (palette/module installs) without publishing host ports.

### Node-RED security
- Admin auth is enabled by default using user `admin` and password `0102030405!` (bcrypt hash stored in `node_red_admin_password_hash`).
- Credentials encryption uses `node_red_credential_secret`; override it in your `terraform.tfvars`.
- `settings.js` is rendered to `build/node-red/settings.js` from `templates/node-red-settings.js.tmpl` and mounted read-only into the Node-RED container.
- Before the Node-RED container starts, the packages defined in `node_red_extra_modules` are installed into its data directory via the Node-RED image (`npm install ...`). Defaults include `node-red-contrib-3dxinterfaces` tarball and `node-red-contrib-mongodb4`.

### Cloudflare automation
- OpenTofu creates the tunnel using only the tunnel name and account ID; the tunnel secret is generated automatically (no manual secret input).
- Ingress rules and CNAME records are generated for the Node-RED hostname.

## MongoDB
- MongoDB runs as a single container (`mongo:7.0.14`) on the internal network only.
- Root credentials are configured with `mongo_root_username` and `mongo_root_password`.
- Persistent data is stored in a bind mount under `/DATA/AppData/<name_prefix>mongo1`.
- No host ports are published; Node-RED reaches MongoDB through the internal Docker network alias.

## Backup
- MinIO is treated as an external, already existing service (no MinIO container is created in this stack).
- Bucket and first-level folder provisioning are driven by OpenTofu via `minio.tf` and `scripts/minio_setup.sh`.
- Configure backup destination using `minio_endpoint`, `minio_bucket_name`, and `minio_bucket_folders`.
- Recommended folder names for backups include entries such as `backup` and `mongo-backup`.
- Scheduled backup execution is configured by OpenTofu through host cron (`backup.tf`).
- Each run executes `scripts/backup_run.sh`, which:
  - creates a MongoDB gzip archive using `mongodump` inside the running Mongo container,
  - packages Node-RED flow files from the Node-RED data directory,
  - uploads both artifacts under `backup/` in MinIO (`backup/<backup_mongo_prefix>` and `backup/<backup_node_red_prefix>`) using `mc`.

## Prerequisites
- Docker Engine running locally and accessible via `unix:///var/run/docker.sock` (default).
- OpenTofu ≥ 1.6.2 installed (`tofu` CLI).
- MinIO Client (`mc`) installed on the host when MinIO bucket provisioning is enabled.
- Cloudflare account with an active tunnel and permissions to create DNS records for your domain.

## Quick start
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in real values (domain, MongoDB credentials, Cloudflare tunnel data). Keep `terraform.tfvars` out of version control.
2. (Optional) Adjust images or timezone in `variables.tf` if you need different versions.
3. Initialize and review the plan:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

## terraform.tfvars guide
Supply real values in `terraform.tfvars` (keep it out of version control). Below are the inputs:

| Variable | Description | Example |
| --- | --- | --- |
| `base_domain` | Base domain used to build hostnames (CNAMEs) for Node-RED. | `example.com` |
| `timezone` | Timezone injected into Node-RED containers. | `America/Sao_Paulo` |
| `name_prefix` | Optional prefix applied to all names (containers, hostnames, data dirs). | `lab-` |
| `mongo_root_username` | MongoDB root user. | `admin` |
| `mongo_root_password` | MongoDB root password (sensitive). | `change-me` |
| `node_red_admin_username` | Node-RED editor admin user. | `admin` |
| `node_red_admin_password_hash` | BCrypt hash for the Node-RED admin password. Default hash = `0102030405!`. | `$2y$08$...` |
| `node_red_credential_secret` | Secret to encrypt Node-RED credentials. | `set-your-own-secret` |
| `node_red_name` | Base name (prefix added) for the Node-RED container/hostname. | `"node1"` |
| `minio_endpoint` | MinIO/S3 endpoint URL for bucket provisioning. | `https://minio2.kastner.com.br` |
| `minio_access_key` | MinIO access key (user). | `minioadmin` |
| `minio_secret_key` | MinIO secret key (password). | `change-me` |
| `minio_bucket_name` | Bucket name to create. Empty value disables MinIO provisioning. | `"my-bucket"` |
| `minio_bucket_folders` | List of first-level folders to create as prefixes. | `["backup","backup/mongo-backup","backup/node-red-backup"]` |
| `backup_enabled` | Enables/disables backup cron provisioning on the host. | `true` |
| `backup_cron_schedule` | Cron expression for backup execution. | `"0 2 * * *"` |
| `backup_retention_days` | Local retention (days) for generated backup files. | `14` |
| `backup_mongo_prefix` | MinIO folder/prefix used for MongoDB archives. | `"mongo-backup"` |
| `backup_node_red_prefix` | MinIO folder/prefix used for Node-RED flow backups. | `"node-red-backup"` |
| `cloudflare_api_token` | API token with tunnel + DNS permissions. | `CLOUDFLARE_API_TOKEN` |
| `cloudflare_zone_id` | Cloudflare Zone ID where CNAMEs are created. | `CLOUDFLARE_ZONE_ID` |
| `cloudflare_zone_name` | Zone name (for reference/logging). | `your-domain.com` |
| `cloudflare_origin_address` | Optional origin address (not used by current CNAME setup). | `` |
| `cloudflare_proxied` | Whether DNS records are proxied by Cloudflare. | `true` |
| `cloudflare_tunnel.name` | Name of the tunnel to create. | `lab-tunnel` |
| `cloudflare_tunnel.account_id` | Cloudflare account ID. | `ACCOUNT_ID_FROM_CLOUDFLARE` |
| `delete_data_on_destroy` | If `true`, deletes the data bind directories on destroy; otherwise keeps them. | `false` |
  - Implemented via separate cleanup resources (`node_red_data_dirs_cleanup`, `mongo_data_dir_cleanup`) that run only when this flag is true.

4. Cloudflare resources (tunnel, config, and CNAME records) are created automatically. The agent reads its rendered config at `build/cloudflare/config.yml` and credentials at `build/cloudflare/<tunnel-id>.json`, both generated during `tofu apply` and mounted into the cloudflared container.

## Cloudflare settings & CNAMEs
- The tunnel is created by OpenTofu (`cloudflare_tunnel`), and the DNS CNAME for the Node-RED hostname is created automatically via `cloudflare_record`.
- The agent-side config is rendered from `templates/cloudflared-config.yml.tmpl`; it builds the ingress entry for the Node-RED container using `base_domain` (e.g., `lab-node1.example.com`).
- Example settings input is in `config/cloudflare/settings.example.yml`; use it as a guide for required fields (tunnel id/name, account tag, secret, base domain, timezone).

## Project structure
- `main.tf` / `locals.tf` / `variables.tf`: Providers, shared locals, and input variables.
- `infrastructure.tf`: Network and base images.
- `containers.tf`: Node-RED and MongoDB containers.
- `cloudflare.tf`: Cloudflare tunnel config generation and container wiring.
- `minio.tf`: Scripted MinIO bucket/prefix provisioning workflow.
- `backup.tf`: Cron-based backup provisioning and secure backup runner generation.
- `scripts/backup_run.sh`: Backup executor (MongoDB + Node-RED flows to MinIO).
- `scripts/minio_setup.sh`: Idempotent MinIO setup script executed by OpenTofu.
- `templates/cloudflared-config.yml.tmpl`: Template for ingress mapping to the Node-RED instance.
- `terraform.tfvars.example`: Sample values (do not commit your real `terraform.tfvars`).
- `logs/`: Interaction logs required by the project guidelines.

## Operational notes
- No ports are published to the host; inbound traffic enters via the Cloudflare tunnel.
- Network model:
  - Node-RED: `${name_prefix}net` (internal) + `bridge` (outbound internet).
  - MongoDB: `${name_prefix}net` only.
- Node-RED data and MongoDB data are stored in bind mounts under `/DATA/AppData/<name>` to persist across container recreations.
- The Cloudflare container runs with `--no-autoupdate`; update the image tag in `variables.tf` to control upgrades.
- MinIO bucket setup is executed with local `mc` (MinIO Client) on the host; each folder entry creates `<folder>/.keep` in the target bucket.
- Backup execution also requires local `mc` and host `crontab`; logs are written to `/DATA/AppData/<name_prefix>backups/backup.log`.

## Next steps
- Provide real tunnel credentials and domain values, then run `opentofu apply`.
- Add Node-RED flows or additional services by extending the locals in `locals.tf` and the template in `templates/cloudflared-config.yml.tmpl`.
