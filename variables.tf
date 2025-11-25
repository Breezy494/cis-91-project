variable "project" {
  description = "The GCP project ID to deploy resources in."
  type        = string
}
variable "public_key_path" {
  description = "The path to the SSH public key file"
  type        = string
}
variable "private_key_path" {
  description = "The absolute path to the SSH private key file used for provisioning."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in."
  type        = string

}
variable "gcp_zone" {
  description = "The GCP zone to deploy resources in."
  type        = string
}

variable "web_machine_type" {
  description = "The machine type for the web server VM."
}

variable "db_machine_type" {
  description = "The machine type for the database VM."
}

variable "vm_image" {
  description = "The VM image to use for the instances."
}

variable "subnet_cidr" {
   description = "The CIDR block for the VPC subnetwork."
   type        = string
}

variable "db_user_password_secret_id" {
  description = "The ID for the Secret Manager secret for the MediaWiki DB user password."
  type        = string
}

variable "service_account_id" {
  description = "The account ID for the VM service account."
  type        = string
}
