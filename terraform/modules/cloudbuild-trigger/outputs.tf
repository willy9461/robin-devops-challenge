output "backend_trigger_id" {
  description = "ID del trigger de Cloud Build del backend"
  value       = google_cloudbuild_trigger.backend.trigger_id
}

output "frontend_trigger_id" {
  description = "ID del trigger de Cloud Build del frontend"
  value       = google_cloudbuild_trigger.frontend.trigger_id
}

output "backend_image_uri" {
  description = "URI base de la imagen del backend en Artifact Registry"
  value       = local.backend_image
}

output "frontend_image_uri" {
  description = "URI base de la imagen del frontend en Artifact Registry"
  value       = local.frontend_image
}
