resource "null_resource" "node_red_dirs" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.node_red_generated_dir}"
  }
}

resource "local_file" "node_red_settings" {
  filename        = local.node_red_settings_path
  file_permission = "0640"
  content = templatefile(
    "${path.module}/templates/node-red-settings.js.tmpl",
    {
      admin_user        = var.node_red_admin_username
      admin_pass_hash   = var.node_red_admin_password_hash
      credential_secret = var.node_red_credential_secret
      timezone          = var.timezone
    }
  )

  depends_on = [null_resource.node_red_dirs]
}
