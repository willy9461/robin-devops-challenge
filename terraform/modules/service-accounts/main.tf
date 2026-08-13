# Módulo: service-accounts
#
# SAs de RUNTIME únicamente (las que usan los servicios de Cloud Run en
# producción). La SA de DEPLOY (terraform-deployer, la que usa el
# workspace de Terraform Cloud vía GOOGLE_CREDENTIALS) no la crea este
# módulo: no puede crearse a sí misma antes de existir — se crea a mano,
# una sola vez, documentado en el README.
#
# Dos SAs separadas por mínimo privilegio: el frontend no necesita tocar
# la DB ni Secret Manager, así que no los tiene.

resource "google_service_account" "app_backend" {
  project      = var.project_id
  account_id   = "app-backend"
  display_name = "Backend runtime SA"
  description  = "Usada por el servicio Cloud Run del backend"
}

resource "google_service_account" "app_frontend" {
  project      = var.project_id
  account_id   = "app-frontend"
  display_name = "Frontend runtime SA"
  description  = "Usada por el servicio Cloud Run del frontend"
}

resource "google_project_iam_member" "backend_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app_backend.email}"
}

resource "google_project_iam_member" "backend_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.app_backend.email}"
}

resource "google_project_iam_member" "backend_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app_backend.email}"
}

resource "google_project_iam_member" "backend_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.app_backend.email}"
}

resource "google_project_iam_member" "backend_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.app_backend.email}"
}

resource "google_project_iam_member" "backend_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.app_backend.email}"
}

resource "google_project_iam_member" "backend_cloudbuild_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.app_backend.email}"
}

resource "google_project_iam_member" "frontend_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.app_frontend.email}"
}

resource "google_project_iam_member" "frontend_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app_frontend.email}"
}

resource "google_project_iam_member" "frontend_cloudbuild_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.app_frontend.email}"
}

resource "google_project_iam_member" "frontend_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.app_frontend.email}"
}

resource "google_project_iam_member" "frontend_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.app_frontend.email}"
}
