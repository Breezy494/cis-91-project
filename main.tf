terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
   project = var.project
   region  = "us-central1"
   zone    = "us-central1-c"
 }
 resource "google_compute_disk" "db_data_disk" {
  name  = "mediawiki-db-data"
  type  = "pd-ssd"         
  zone  = "us-central1-c"   
  size  = 10                
}
resource "google_compute_firewall" "allow_web_ssh" {
  name    = "allow-web-ssh"
  network = "default" 
allow {
    protocol = "tcp"
    ports    = ["80", "443", "22"]
  }
   source_ranges = ["0.0.0.0/0"]
   target_tags   = ["web","db"]
}
 resource "google_service_account" "vm_identity" {
  account_id   = "vm-bucket-access"
  display_name = "VM Service Account"
}

resource "google_storage_bucket" "app_storage" {
  name          = "my-app-storage-${var.project}" # Must be globally unique
  location      = "US"
  force_destroy = true 
}
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.app_storage.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm_identity.email}"
}
resource "google_storage_bucket" "secure_backup_bucket" {
  name          = "my-secure-backup-${var.project}"
  location      = "US"
  storage_class = "STANDARD"

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
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      days_since_noncurrent_time = 182
    }
  }
}
resource "google_compute_network" "vpc_network" {
  name = "mediawiki"
 }
resource "google_compute_instance" "vm_instance" {

  name         = "mediawiki-instance"
  machine_type = "f1-micro"
  tags         = ["web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
service_account {
    email  = google_service_account.vm_identity.email
    scopes = ["cloud-platform"]
  }
metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  provisioner "remote-exec" {
    inline = ["echo 'SSH is ready!'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network_interface.0.access_config.0.nat_ip
    }
  }
 provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu --private-key ~/.ssh/id_rsa -i '${self.network_interface.0.access_config.0.nat_ip},' mediawiki.yml"
  }
}

resource "google_compute_instance" "vm_instance_db" {
  name         = "mariadb-instance"
  machine_type = "f1-micro"
  tags         = ["db"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
 attached_disk {
    source      = google_compute_disk.db_data_disk.id
    device_name = "db_data"
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
service_account {
    email  = google_service_account.vm_identity.email
    scopes = ["cloud-platform"]
  }
metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  provisioner "remote-exec" {
    inline = ["echo 'SSH is ready!'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network_interface.0.access_config.0.nat_ip
    }
  }
 provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu --private-key ~/.ssh/id_rsa -i '${self.network_interface.0.access_config.0.nat_ip},' install_db.yml"
  }
}