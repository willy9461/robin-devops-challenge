output "frontend_url" {
  description = "URL pública del frontend — la que se comparte para la entrega"
  value       = module.cloud_run.frontend_url
}

output "backend_url" {
  description = "URL pública del backend — la que se comparte para la entrega"
  value       = module.cloud_run.backend_url
}
