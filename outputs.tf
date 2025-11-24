output "mediawiki_private_ip" {
  description = "The private IP address of the MediaWiki web server."
  value       = google_compute_instance.vm_instance.network_interface.0.network_ip
}

output "mediawiki_public_ip" {
  description = "The public IP address of the MediaWiki web server."
  value       = "http://${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}"
}
