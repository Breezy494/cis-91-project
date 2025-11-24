
resource "google_compute_subnetwork" "mediawiki_subnet" {
  name          = "mediawiki-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}
resource "google_compute_firewall" "allow_http" {
  name    = "default-allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}


resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web", "db"]
}

resource "google_compute_firewall" "allow_db_from_web" {
  name    = "allow-db-from-web"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_tags = ["web"]
  target_tags = ["db"]
}