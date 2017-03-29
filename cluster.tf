provider "google" {
  credentials = "${ file("account.json") }",
  project     = "${var.project_id}",
  region      = "us-west1"
}

resource "google_compute_firewall" "swarm" {
  name = "swarm",
  description = "Docker swarm firewall rules",
  network = "default",

  allow {
    protocol = "tcp",
    ports = ["2375", "2377", "7946"]
  }

  allow {
    protocol = "udp",
    ports = ["4789", "7946"]
  }

  source_tags = ["manager", "worker"]
}

resource "google_compute_instance" "manager1" {
  name        = "manager1",
  description = "Docker Swarm manager",
  
  machine_type = "f1-micro",
  zone         = "us-west1-a",

  disk = {
    image      = "coreos-stable-1298-6-0-v20170315"
  },
  network_interface = {
    network    = "default",
    access_config = {}
  },

  tags = [
    "manager"
  ],

  connection {
    type = "ssh",
    user = "${var.remote_user}",
    private_key = "${file("keys/id_rsa")}"
  },
  provisioner "file" {
    source = "docker.options",
    destination = "/tmp/docker"
  },
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/docker /etc/default/docker",
      "sudo docker swarm init"
    ]
  }
}

resource "google_compute_instance" "worker1" {
  name        = "worker1",
  description = "Docker Swarm worker",
  
  machine_type = "f1-micro",
  zone         = "us-west1-a",

  disk = {
    image      = "coreos-stable-1298-6-0-v20170315"
  },
  network_interface = {
    network    = "default",
    access_config = {}
  },

  tags = [
    "worker"
  ],

  connection {
    type = "ssh",
    user = "${var.remote_user}",
    private_key = "${file("keys/id_rsa")}"
  },
  provisioner "remote-exec" {
    inline = [
      <<-EOF
        sudo docker swarm join  \
        ${google_compute_instance.manager1.network_interface.0.access_config.0.assigned_nat_ip}:2377 \
        --token $(sudo docker -H ${google_compute_instance.manager1.network_interface.0.access_config.0.assigned_nat_ip} swarm join-token -q worker)
        EOF
    ]
  }
}