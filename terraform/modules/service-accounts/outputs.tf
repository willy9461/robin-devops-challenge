output "backend_email" {
  description = "Email de la SA de runtime del backend"
  value       = google_service_account.app_backend.email
}

output "frontend_email" {
  description = "Email de la SA de runtime del frontend"
  value       = google_service_account.app_frontend.email
}
