output "backend_email" {
  description = "Email de la SA de runtime del backend"
  value       = google_service_account.app_backend.email
}

output "frontend_email" {
  description = "Email de la SA de runtime del frontend"
  value       = google_service_account.app_frontend.email
}

output "build_backend_email" {
  description = "Email de la SA de build del backend, usada por el trigger de Cloud Build"
  value       = google_service_account.build_backend.email
}

output "build_frontend_email" {
  description = "Email de la SA de build del frontend, usada por el trigger de Cloud Build"
  value       = google_service_account.build_frontend.email
}
