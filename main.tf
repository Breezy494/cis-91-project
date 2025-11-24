terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.10.0"
    }
  }
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
