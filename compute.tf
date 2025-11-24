resource "google_compute_disk" "db_data_disk" {
  name  = "mediawiki-db-data"
  type  = "pd-ssd"
  zone  = var.gcp_zone
  size  = 10
}

resource "google_compute_instance" "vm_instance" {

  name         = "mediawiki-instance"
  machine_type = var.web_machine_type
  project      = var.project
  tags         = ["web","http-server"]

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mediawiki_subnet.id

    access_config {
    }
  }
  service_account {
    email  = google_service_account.vm_identity.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys                = "ubuntu:${file(var.public_key_path)}"
    metadata_startup_script = templatefile("${path.module}/startup-web.sh.tpl", {
      db_private_ip   = google_compute_instance.vm_instance_db.network_interface.0.network_ip,
      vault_secret_id = google_secret_manager_secret.ansible_vault_pass.secret_id,
      db_pass_secret_id = google_secret_manager_secret.wikiuser_db_pass.secret_id
    })
  }
}


resource "google_compute_instance" "vm_instance_db" {
  name         = "mariadb-instance"
  project      = var.project
  machine_type = var.db_machine_type
  tags         = ["db"]

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }
  attached_disk {
    source      = google_compute_disk.db_data_disk.id
    device_name = "db_data"
  }
  network_interface {
    subnetwork = google_compute_subnetwork.mediawiki_subnet.id
  }
  service_account {
    email  = google_service_account.vm_identity.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys                = "ubuntu:${file(var.public_key_path)}"
    metadata_startup_script = templatefile("${path.module}/startup-db.sh.tpl", {
      backup_bucket_name = google_storage_bucket.secure_backup_bucket.name,
      vault_secret_id    = google_secret_manager_secret.ansible_vault_pass.secret_id,
      db_root_secret_id  = google_secret_manager_secret.db_root_pass.secret_id
    })
  }
}