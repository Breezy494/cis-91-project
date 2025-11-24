variable "project" {
  description = "The GCP project ID to deploy resources in."
  default = "cis-91-471119"
}
variable "public_key_path" {
  description = "The path to the SSH public key file"
  type        = string
}
variable "private_key_path" {
  description = "The absolute path to the SSH private key file used for provisioning."
  type        = string
}
variable "my_ip_cidr" {
  description = "The CIDR block of the network to allow SSH access from."
  type        = string
  default     = "0.0.0.0/0"
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in."
  type        = string
  default     = "us-central1"
}
variable "gcp_zone" {
  description = "The GCP zone to deploy resources in."
  type        = string
  default     = "us-central1-c"
}

variable "web_machine_type" {
  description = "The machine type for the web server VM."
  default = "e2-small"
}

variable "db_machine_type" {
  description = "The machine type for the database VM."
  default = "e2-medium"
}

variable "vm_image" {
  description = "The VM image to use for the instances."
  default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "subnet_cidr" {
   description = "The CIDR block for the VPC subnetwork."
   type        = string
   default = "10.10.1.0/24"
  
}
