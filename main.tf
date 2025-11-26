terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

provider "google" {
   project = var.project
   region  = var.gcp_region
   zone    = var.gcp_zone
 }

resource "google_compute_network" "vpc_network" {
  name                    = "mediawiki-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mediawiki_subnet" {
  name          = "mediawiki-subnet"
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc_network.id
  region        = var.gcp_region
}

resource "google_compute_disk" "db_disk" {
  name  = "db-data-disk"
  type  = "pd-standard"
  zone  = var.gcp_zone
  size  = 20
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "random_password" "db_user_password" {
  length  = 16
  special = false
}

resource "google_secret_manager_secret" "db_root_password" {
  secret_id = "db-root-password"
  replication {
    auto {}
    }
}

resource "google_secret_manager_secret_version" "db_root_password_version" {
  secret      = google_secret_manager_secret.db_root_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "db_user_password" {
  secret_id = var.db_user_password_secret_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_user_password_version" {
  secret      = google_secret_manager_secret.db_user_password.id
  secret_data = random_password.db_user_password.result
}

resource "google_service_account" "vm_sa" {
  account_id   = var.service_account_id
  display_name = "MediaWiki VM Service Account"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "logging_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_compute_address" "db_static_ip" {
  name = "db-provisioning-ip"
}

resource "google_storage_bucket" "backup" {
  name     = "${var.project}-db-backups"
  location = var.gcp_region
  force_destroy = true
   versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
    condition {
      days_since_noncurrent_time = 7
    }
  }
}

resource "google_compute_instance" "db" {
  name         = "mariadb-server"
  machine_type = var.db_machine_type
  zone         = var.gcp_zone
  tags         = ["db", "ssh"]

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }

  attached_disk {
    source = google_compute_disk.db_disk.id
    device_name = "db_data"
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.mediawiki_subnet.id
    access_config {
      nat_ip = google_compute_address.db_static_ip.address
    }
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    
    ssh-keys = "drewmilliman45:${file(var.public_key_path)}"
    
    startup-script = <<-EOF
      #!/bin/bash
      # Ensure SSH server is installed and running
      apt-get update
      apt-get install -y openssh-server
      systemctl start ssh
    EOF
  }

  connection {
    type        = "ssh"
    user        = "drewmilliman45"
    private_key = file(var.private_key_path)
    host        = self.network_interface[0].access_config[0].nat_ip
  }

  provisioner "local-exec" {
    command = "sleep 30 && ansible-playbook -i '${self.network_interface[0].access_config[0].nat_ip},' --private-key ${var.private_key_path} --user drewmilliman45 -e 'db_root_secret_id=${google_secret_manager_secret.db_root_password.secret_id} db_pass=${random_password.db_user_password.result} backup_bucket_name=${google_storage_bucket.backup.name}' install_db.yml"
    environment = {
      ANSIBLE_STDOUT_CALLBACK = "default"
    }
  }
}

resource "null_resource" "remove_db_public_ip" {
  
  depends_on = [google_compute_instance.db]

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Skipping on destroy'"
  }

  triggers = {
    db_instance_id = google_compute_instance.db.id
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "mediawiki-web"
  machine_type = var.web_machine_type
  zone         = var.gcp_zone
  tags         = ["web", "ssh"]

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.mediawiki_subnet.id
    access_config {}
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [google_compute_instance.db]
  
  metadata = {
    
    ssh-keys = "drewmilliman45:${file(var.public_key_path)}"
    
    startup-script = <<-EOF
      #!/bin/bash
      # Ensure SSH server is installed and running
      apt-get update
      apt-get install -y openssh-server
      systemctl start ssh
    EOF
  }
  
  connection {
    type        = "ssh"
    user        = "drewmilliman45"
    private_key = file(var.private_key_path)
    host        = self.network_interface[0].access_config[0].nat_ip
  }
  
  
  provisioner "local-exec" {
    command = "sleep 30 && ansible-playbook -i '${self.network_interface[0].access_config[0].nat_ip},' --private-key ${var.private_key_path} --user drewmilliman45 -e 'db_ip=${google_compute_instance.db.network_interface[0].network_ip} db_pass_secret_id=${var.db_user_password_secret_id} public_ip=${self.network_interface[0].access_config[0].nat_ip}' mediawiki.yml"
    environment = {
      ANSIBLE_STDOUT_CALLBACK = "default"
    }
  }
}


resource "google_compute_firewall" "allow_ssh" {
  name    = "mediawiki-allow-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [local.my_ip_cidr]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_web" {
  name    = "mediawiki-allow-web"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "allow_internal_db" {
  name    = "mediawiki-allow-internal-db"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_tags = ["web"]
  target_tags = ["db"]
}
