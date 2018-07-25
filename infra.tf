resource "digitalocean_ssh_key" "core" {
  name       = "Terraform Coreos"
  public_key = "${file("${var.ssh_public_key}")}"
}

resource "digitalocean_tag" "magnum" {
  name = "magnum"
}

resource "digitalocean_droplet" "magnum" {
  name  = "${format("magnum-%02d", count.index)}"
  count = 4
  image              = "coreos-stable"

  region             = "${var.region}"
  size               = "1gb"

  user_data = "${file("userdata/magnum.yaml")}"
  tags = ["${digitalocean_tag.magnum.id}"]
  ssh_keys = ["${digitalocean_ssh_key.core.id}"]
}

resource "digitalocean_loadbalancer" "public" {
  name                   = "magnum.${var.domain}"
  region                 = "lon1"
  droplet_tag            = "${digitalocean_tag.magnum.id}"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 8765
    target_protocol = "http"
  }

  healthcheck {
    port     = "8765"
    protocol = "tcp"
  }
}

resource "digitalocean_record" "loadbalancer" {
  domain = "${var.domain}"
  type   = "A"
  name   = "magnum"
  ttl    = 30
  value  = "${digitalocean_loadbalancer.public.ip}"
}
