resource "docker_container" "node_red" {
  name     = local.node_red_instance.name
  image    = docker_image.node_red.image_id
  restart  = "unless-stopped"
  hostname = local.node_red_instance.name

  env = [
    "TZ=${var.timezone}"
  ]

  mounts {
    target = "/data"
    source = local.node_red_data_dir
    type   = "bind"
  }

  mounts {
    target    = "/data/settings.js"
    source    = local.node_red_settings_path
    type      = "bind"
    read_only = true
  }

  networks_advanced {
    name    = docker_network.main.name
    aliases = [local.node_red_instance.name]
  }

  depends_on = [
    docker_network.main,
    local_file.node_red_settings,
    null_resource.node_red_data_dirs,
    null_resource.node_red_modules,
  ]

}

resource "docker_container" "mongo" {
  name     = "${var.name_prefix}mongo1"
  image    = docker_image.mongo.image_id
  restart  = "unless-stopped"
  hostname = "${var.name_prefix}mongo1"

  env = [
    "MONGO_INITDB_ROOT_USERNAME=${var.mongo_root_username}",
    "MONGO_INITDB_ROOT_PASSWORD=${var.mongo_root_password}"
  ]

  mounts {
    target = "/data/db"
    source = local.mongo_data_dir
    type   = "bind"
  }

  networks_advanced {
    name    = docker_network.main.name
    aliases = ["${var.name_prefix}mongo1"]
  }

  healthcheck {
    test     = ["CMD-SHELL", "mongosh --quiet --eval 'db.runCommand({ ping: 1 })' || exit 1"]
    interval = "30s"
    timeout  = "10s"
    retries  = 5
  }

  depends_on = [
    docker_network.main,
    null_resource.mongo_data_dir,
  ]

}
