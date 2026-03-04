resource "docker_network" "main" {
  name     = "${var.name_prefix}net"
  driver   = "bridge"
  internal = true
}

resource "docker_image" "node_red" {
  name         = var.node_red_image
  keep_locally = true
}

resource "docker_image" "mongo" {
  name         = var.mongo_image
  keep_locally = true
}

resource "docker_image" "cloudflared" {
  name         = var.cloudflared_image
  keep_locally = true
}
