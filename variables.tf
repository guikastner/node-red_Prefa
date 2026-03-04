variable "docker_host" {
  description = "Docker host socket URL. Keep default for local Docker engine."
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "base_domain" {
  description = "Base domain used to build Cloudflare CNAMEs for Node-RED instances (e.g. example.com)."
  type        = string
  default     = ""
}

variable "timezone" {
  description = "Timezone applied to containers that support TZ (Node-RED)."
  type        = string
  default     = "UTC"
}

variable "name_prefix" {
  description = "Optional prefix applied to all container names, hostnames, and data directories (e.g., \"lab-\")."
  type        = string
  default     = ""
}

variable "node_red_name" {
  description = "Base name for the single Node-RED container (prefix will be prepended)."
  type        = string
  default     = "node1"
}

variable "node_red_image" {
  description = "Container image for Node-RED."
  type        = string
  default     = "nodered/node-red:4.1.4-22"
}

variable "mongo_image" {
  description = "Container image for MongoDB."
  type        = string
  default     = "mongo:7.0.14"
}

variable "cloudflared_image" {
  description = "Container image for Cloudflare Tunnel agent."
  type        = string
  default     = "cloudflare/cloudflared:latest"
}

variable "mongo_root_username" {
  description = "Root username for MongoDB."
  type        = string
}

variable "mongo_root_password" {
  description = "Root password for MongoDB."
  type        = string
  sensitive   = true
}

variable "node_red_admin_username" {
  description = "Admin username for Node-RED editor (basic auth)."
  type        = string
  default     = "admin"
}

variable "node_red_admin_password_hash" {
  description = "BCrypt hash for Node-RED admin password. Default corresponds to '0102030405!'."
  type        = string
  default     = "$2y$08$zxIS.hLoUbsk2FmZ13awj.r3wpPekvLz/KWDQKK/p4mV0oexYVXuq"
  sensitive   = true
}

variable "node_red_credential_secret" {
  description = "Secret used by Node-RED to encrypt flow credentials (credentialSecret)."
  type        = string
  default     = "credential-secret"
  sensitive   = true
}

variable "node_red_extra_module_url" {
  description = "Optional npm package URL to install into each Node-RED data dir before container start."
  type        = string
  default     = "https://btcc.s3.dualstack.eu-west-1.amazonaws.com/widget-lab/npm/node-red-contrib-3dxinterfaces/dist/widget-lab-node-red-contrib-3dxinterfaces-6.5.1.tgz"
}

variable "node_red_extra_modules" {
  description = "List of npm packages (names or URLs) to install into each Node-RED data dir."
  type        = list(string)
  default = [
    "https://btcc.s3.dualstack.eu-west-1.amazonaws.com/widget-lab/npm/node-red-contrib-3dxinterfaces/dist/widget-lab-node-red-contrib-3dxinterfaces-6.5.1.tgz",
    "node-red-contrib-mongodb4",
  ]
}

variable "delete_data_on_destroy" {
  description = "If true, data directories (bind mounts) are deleted on destroy; otherwise they are kept."
  type        = bool
  default     = false
}

variable "minio_endpoint" {
  description = "MinIO/S3 endpoint URL used for bucket provisioning."
  type        = string
  default     = "https://minio2.kastner.com.br"
}

variable "minio_access_key" {
  description = "MinIO access key (user)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "minio_secret_key" {
  description = "MinIO secret key (password)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "minio_bucket_name" {
  description = "Bucket name to create in MinIO. Leave empty to skip provisioning."
  type        = string
  default     = ""
}

variable "minio_bucket_folders" {
  description = "List of first-level folders (prefixes) to ensure inside the MinIO bucket."
  type        = list(string)
  default     = []
}

variable "cloudflare_api_token" {
  description = "API token with permissions to manage tunnels and DNS records."
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Zone ID in Cloudflare where CNAMEs will be created."
  type        = string
}

variable "cloudflare_zone_name" {
  description = "Zone name (domain) in Cloudflare. Kept for reference/logging."
  type        = string
  default     = ""
}

variable "cloudflare_origin_address" {
  description = "Origin address (if needed for additional records). Not used by current CNAME-only setup."
  type        = string
  default     = ""
}

variable "cloudflare_proxied" {
  description = "Whether created DNS records should be proxied by Cloudflare."
  type        = bool
  default     = true
}

variable "cloudflare_tunnel" {
  description = "Cloudflare tunnel settings and secrets."
  type = object({
    name       = string
    account_id = string
  })
}
