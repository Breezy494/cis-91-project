resource "random_password" "db_root_password" {
  length  = 32
  special = true
}
resource "random_password" "wikiuser_db_password" {
  length  = 32
  special = true
}
resource "google_service_account" "vm_identity" {
  account_id   = "vm-bucket-access"
  display_name = "VM Service Account"
  project      = var.project
}

resource "google_secret_manager_secret" "ansible_vault_pass" {
  project   = var.project
  secret_id = "ansible-vault-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ansible_vault_pass_version" {
  secret      = google_secret_manager_secret.ansible_vault_pass.id
  secret_data = file(".vault_pass")
}

resource "google_secret_manager_secret_iam_member" "vault_pass_accessor" {
  project   = google_secret_manager_secret.ansible_vault_pass.project
  secret_id = google_secret_manager_secret.ansible_vault_pass.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_identity.email}"
}

resource "google_secret_manager_secret" "wikiuser_db_pass" {
  project   = var.project
  secret_id = "wikiuser-db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "wikiuser_db_pass_version" {
  secret      = google_secret_manager_secret.wikiuser_db_pass.id
  secret_data = random_password.wikiuser_db_password.result
}

resource "google_secret_manager_secret_iam_member" "wikiuser_db_pass_accessor" {
  project   = google_secret_manager_secret.wikiuser_db_pass.project
  secret_id = google_secret_manager_secret.wikiuser_db_pass.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_identity.email}"
}

resource "google_secret_manager_secret" "db_root_pass" {
  project   = var.project
  secret_id = "db-root-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_root_pass_version" {
  secret      = google_secret_manager_secret.db_root_pass.id
  secret_data = random_password.db_root_password.result
}

resource "google_secret_manager_secret_iam_member" "db_root_pass_accessor" {
  project   = google_secret_manager_secret.db_root_pass.project
  secret_id = google_secret_manager_secret.db_root_pass.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_identity.email}"
}