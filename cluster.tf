provider "google" {
  credentials = "${ file("account.json") }",
  project     = "bionic-obelisk-162521",
  region      = "us-west1"
}

resource "google_compute_instance" "default" {
  name        = "swarm-manager1",
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
}
