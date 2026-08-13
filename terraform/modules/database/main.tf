# Módulo: database
#
# Cloud SQL Postgres con IP privada únicamente (sin IP pública). La
# password se genera con random_password y se guarda en Secret Manager —
# el módulo cloud-run la inyecta al backend vía secret_env_vars, nunca
# como variable de entorno plana (mejora respecto al challenge anterior).
#
# Depende de que la Private Service Access connection del módulo
# networking ya exista.

resource "random_password" "db_password" {
  length  = 24
  special = false # evita caracteres que compliquen el connection string
}

resource "google_sql_database_instance" "instance" {
  project          = var.project_id
  name             = var.instance_name
  region           = var.region
  database_version = var.database_version

  settings {
    tier              = var.tier
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }

    backup_configuration {
      enabled = false # sin backups: alcance de challenge, no producción real
    }
  }

  deletion_protection = false # facilita el terraform destroy al terminar
}

resource "google_sql_database" "database" {
  project  = var.project_id
  name     = var.database_name
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "user" {
  project  = var.project_id
  name     = var.db_user_name
  instance = google_sql_database_instance.instance.name
  password = random_password.db_password.result
}

resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = "db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}
