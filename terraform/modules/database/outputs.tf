output "private_ip_address" {
  description = "IP privada de la instancia, consumida por el backend"
  value       = google_sql_database_instance.instance.private_ip_address
}

output "connection_name" {
  description = "Connection name de Cloud SQL"
  value       = google_sql_database_instance.instance.connection_name
}

output "database_name" {
  description = "Nombre de la base de datos"
  value       = google_sql_database.database.name
}

output "db_user_name" {
  description = "Nombre del usuario de la base de datos"
  value       = google_sql_user.user.name
}

output "db_password_secret_id" {
  description = "ID del secret en Secret Manager con la password — el módulo cloud-run lo referencia (no expone el valor)"
  value       = google_secret_manager_secret.db_password.secret_id
}
