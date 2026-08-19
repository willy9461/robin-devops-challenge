output "app_url" {
  description = "URL pública única (HTTPS, vía Load Balancer) — la que se comparte para la entrega. Sirve tanto el frontend como el backend, ruteados por path bajo el mismo origen."
  value       = module.load_balance.url
}

output "load_balancer_ip" {
  description = "IP estática del Load Balancer"
  value       = google_compute_global_address.lb_ip.address
}
