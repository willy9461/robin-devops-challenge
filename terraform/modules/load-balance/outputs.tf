output "frontend_url" {
  description = "URL pública del frontend (HTTPS)"
  value       = "https://${var.frontend_domain}"
}

output "backend_url" {
  description = "URL pública del backend (HTTPS)"
  value       = "https://${var.backend_domain}"
}
