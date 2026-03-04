locals {
  node_red_name = "${var.name_prefix}${var.node_red_name}"

  node_red_instance = {
    name     = local.node_red_name
    hostname = var.base_domain != "" ? "${local.node_red_name}.${var.base_domain}" : local.node_red_name
  }

  data_root         = "/DATA/AppData"
  node_red_data_dir = abspath("${local.data_root}/${local.node_red_name}")
  mongo_data_dir    = abspath("${local.data_root}/${var.name_prefix}mongo1")

  node_red_generated_dir = abspath("${path.module}/build/node-red")
  node_red_settings_path = abspath("${local.node_red_generated_dir}/settings.js")

  cloudflare_generated_dir    = abspath("${path.module}/build/cloudflare")
  cloudflare_config_path      = abspath("${local.cloudflare_generated_dir}/config.yml")
  cloudflare_credentials_path = abspath("${local.cloudflare_generated_dir}/cloudflared-credentials.json")
}
