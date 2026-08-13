output "network_id" {
  description = "ID de la VPC, consumido por el módulo database"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "Nombre de la VPC, consumido por el módulo cloud-run (Direct VPC Egress)"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Nombre de la subnet, consumido por el módulo cloud-run"
  value       = google_compute_subnetwork.subnet.name
}
