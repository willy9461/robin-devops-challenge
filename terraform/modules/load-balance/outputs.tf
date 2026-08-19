output "domain" {
  description = "Dominio nip.io del load balancer"
  value       = local.domain
}

output "url" {
  description = "URL pública completa (HTTPS) — la que se comparte para la entrega"
  value       = "https://${local.domain}"
}
