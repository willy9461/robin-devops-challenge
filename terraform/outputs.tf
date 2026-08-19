output "frontend_url" {
  description = "URL pública del frontend — la que se comparte para la entrega"
  value       = module.load_balance.frontend_url
}

output "backend_url" {
  description = "URL pública del backend — la que se comparte para la entrega"
  value       = module.load_balance.backend_url
}

output "load_balancer_ip" {
  description = "IP estática del Load Balancer (compartida por ambos subdominios)"
  value       = google_compute_global_address.lb_ip.address
}
