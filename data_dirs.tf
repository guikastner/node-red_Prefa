resource "null_resource" "node_red_data_dirs" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.node_red_data_dir}"
  }
}

resource "null_resource" "mongo_data_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.mongo_data_dir}"
  }
}

# Optional cleanup resources controlled by delete_data_on_destroy
resource "null_resource" "node_red_data_dirs_cleanup" {
  count = var.delete_data_on_destroy ? 1 : 0

  triggers = {
    path = local.node_red_data_dir
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${self.triggers.path}"
  }
}

resource "null_resource" "mongo_data_dir_cleanup" {
  count = var.delete_data_on_destroy ? 1 : 0

  triggers = {
    path = local.mongo_data_dir
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${self.triggers.path}"
  }
}
