resource "google_storage_bucket" "app_storage" {
  name          = "my-app-storage-${var.project}"
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