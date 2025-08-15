# update this for your google account
locals {
    project = "YOUR-PROJECT-ID"
    region = "asia-southeast1"
    zone = "asia-southeast1-c"
    username = "YOUR USERNAME ON THE HOST"
}

provider "google" {
    project = local.project
    region = local.region
}

resource "google_compute_network" "vpc_network" {
    name  = "lab-network"
    auto_create_subnetworks = false
    mtu = 1460
}

resource "google_compute_subnetwork" "default" {
    name = "lab-subnet"
    ip_cidr_range = "192.168.0.0/24"
    region = local.region
    network = google_compute_network.vpc_network.id
}

# create VM
resource "google_compute_instance" "default" {
    name = "exfil-server"
    machine_type = "e2-micro"
    zone = local.zone
    tags = ["ssh", "nc"]

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-12"
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.default.id

        access_config {
            # include this section give VM external IP address
        }
    }
    metadata = {
        # ssh-keygen -t rsa -b 4096 -f id_rsa
        "ssh-keys" = <<EOT
         ${local.username}:${file("id_rsa.pub")}
        EOT
    }
}

# custom firewall rule
resource "google_compute_firewall" "ssh" {
    name = "allow-ssh"
    allow {
        ports = ["22"]
        protocol = "tcp"
    }
    direction = "INGRESS"
    network = google_compute_network.vpc_network.id
    priority = 1000
    source_ranges = ["0.0.0.0/0"]
    target_tags = ["ssh"]
}

resource "google_compute_firewall" "flask" {
    name = "allow-http-https"
    allow {
        ports = ["80", "443"]
        protocol = "tcp"
    }
    network = google_compute_network.vpc_network.id
    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "netcat" {
    name = "allow-nc"
    allow {
        ports = ["9001"]
        protocol = "tcp"
    }
    direction = "INGRESS"
    network = google_compute_network.vpc_network.id
    source_ranges = ["0.0.0.0/0"]
    target_tags = ["nc"]
}

output "ip-address" {
    value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}