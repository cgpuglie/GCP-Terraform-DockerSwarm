provider "google" {
  credentials = "${ file("account.json") }"
  project     = "${var.project_id}"
  region      = "us-west1"
}

resource "google_compute_firewall" "swarm" {
  name        = "swarm"
  description = "Docker swarm firewall rules"
  network     = "default"

  allow {
    protocol = "tcp"
    ports    = ["2377", "7946"]
  }

  allow {
    protocol = "udp"
    ports    = ["4789", "7946"]
  }

  source_tags = ["manager", "worker"]
  target_tags = ["manager", "worker"]
}

resource "google_compute_instance" "swarm-mom" {
  name        = "swarm-mom"
  description = "Initial Docker Swarm Manager - All others will join here"

  machine_type = "f1-micro"
  zone         = "us-west1-a"

  disk = {
    image = "coreos-stable-1298-6-0-v20170315"
  }

  network_interface = {
    network       = "default"
    access_config = {}
  }

  tags = [
    "manager",
  ]

  connection {
    type        = "ssh"
    user        = "${var.remote_user}"
    private_key = "${file("keys/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm init",
    ]
  }
}

resource "google_compute_instance" "swarm-manager" {
  name        = "swarm-manager-${count.index}"
  description = "Docker Swarm Manager Node - Joins MoM"

  count        = "${var.swarm_manager_count}"
  machine_type = "f1-micro"
  zone         = "us-west1-a"

  disk = {
    image = "coreos-stable-1298-6-0-v20170315"
  }

  network_interface = {
    network       = "default"
    access_config = {}
  }

  tags = [
    "manager",
  ]

  provisioner "local-exec" {
    command = "sleep 60; ssh -o StrictHostKeyChecking=no ${var.remote_user}@${self.network_interface.0.access_config.0.assigned_nat_ip} \"sudo docker swarm join --token $(ssh -o StrictHostKeyChecking=no ${var.remote_user}@${google_compute_instance.swarm-mom.network_interface.0.access_config.0.assigned_nat_ip} 'sudo docker swarm join-token -q manager') ${google_compute_instance.swarm-mom.network_interface.0.address}:2377;\""
  }
}

resource "google_compute_instance" "swarm-worker" {
  name        = "swarm-worker-${count.index}"
  description = "Docker Swarm Worker Node - Joins MoM"

  count        = "${var.swarm_worker_count}"
  machine_type = "f1-micro"
  zone         = "us-west1-a"

  disk = {
    image = "coreos-stable-1298-6-0-v20170315"
  }

  network_interface = {
    network       = "default"
    access_config = {}
  }

  tags = [
    "worker",
  ]

  provisioner "local-exec" {
    command = "sleep 60; ssh -o StrictHostKeyChecking=no ${var.remote_user}@${self.network_interface.0.access_config.0.assigned_nat_ip} \"sudo docker swarm join --token $(ssh -o StrictHostKeyChecking=no ${var.remote_user}@${google_compute_instance.swarm-mom.network_interface.0.access_config.0.assigned_nat_ip} 'sudo docker swarm join-token -q worker') ${google_compute_instance.swarm-mom.network_interface.0.address}:2377;\""
  }
}
