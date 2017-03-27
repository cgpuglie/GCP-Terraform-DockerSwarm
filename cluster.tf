provider "google" {
  credentials = "${ file("account.json") }",
  project     = "${var.project_id}",
  region      = "us-west1"
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
  }
}