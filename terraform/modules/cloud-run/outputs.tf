output "backend_url" {
  description = "URL pública del backend (*.run.app)"
  value       = google_cloud_run_v2_service.backend.uri
}

output "frontend_url" {
  description = "URL pública del frontend (*.run.app)"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "backend_service_name" {
  description = "Nombre del servicio backend, consumido por el módulo cloudbuild-trigger"
  value       = google_cloud_run_v2_service.backend.name
}

output "frontend_service_name" {
  description = "Nombre del servicio frontend, consumido por el módulo cloudbuild-trigger"
  value       = google_cloud_run_v2_service.frontend.name
}
