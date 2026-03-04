resource "null_resource" "node_red_modules" {
  # Install requested Node-RED modules into the data directory using the Node-RED image runtime (matches arch).
  provisioner "local-exec" {
    command = <<-EOT
      docker run --rm --entrypoint npm -v ${local.node_red_data_dir}:/data ${var.node_red_image} \
        install --no-progress --no-audit --unsafe-perm --prefix /data ${join(" ", var.node_red_extra_modules)}
    EOT
  }

  triggers = {
    data_dir = local.node_red_data_dir
    modules  = join(",", var.node_red_extra_modules)
    image    = var.node_red_image
  }

  depends_on = [
    null_resource.node_red_data_dirs,
  ]
}
