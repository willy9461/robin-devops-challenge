# Módulo: service-accounts
#
# 4 SAs en total, separadas por función:
# - 2 de RUNTIME (app-backend, app-frontend): las que usan los servicios
#   de Cloud Run en producción, con el mínimo privilegio que necesitan
#   para correr — nada de permisos de administración.
# - 2 de BUILD (build-backend, build-frontend): las que ejecutan Cloud
#   Build (compilar, pushear a Artifact Registry, desplegar la nueva
#   revisión). Necesitan permisos más amplios a nivel proyecto, pero
#   nunca corren código de la app en producción.
#
# La SA de DEPLOY (terraform-deployer, la que usa el workspace de
# Terraform Cloud vía GOOGLE_CREDENTIALS) no la crea este módulo: no
# puede crearse a sí misma antes de existir — se crea a mano, una sola
# vez, documentado en el README.

# --- SAs de runtime (mínimo privilegio real) ---

resource "google_service_account" "app_backend" {
  project      = var.project_id
  account_id   = "app-backend"
  display_name = "Backend runtime SA"
  description  = "Usada por el servicio Cloud Run del backend en producción — sin permisos de administración"
}

resource "google_service_account" "app_frontend" {
  project      = var.project_id
  account_id   = "app-frontend"
  display_name = "Frontend runtime SA"
  description  = "Usada por el servicio Cloud Run del frontend en producción — sin permisos de administración"
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

resource "google_project_iam_member" "frontend_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app_frontend.email}"
}

# --- SAs de build (ejecutan Cloud Build, nunca corren la app) ---

resource "google_service_account" "build_backend" {
  project      = var.project_id
  account_id   = "build-backend"
  display_name = "Backend build SA"
  description  = "Ejecuta el trigger de Cloud Build del backend (build, push, deploy)"
}

resource "google_service_account" "build_frontend" {
  project      = var.project_id
  account_id   = "build-frontend"
  display_name = "Frontend build SA"
  description  = "Ejecuta el trigger de Cloud Build del frontend (build, push, deploy)"
}

resource "google_project_iam_member" "build_backend_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.build_backend.email}"
}

resource "google_project_iam_member" "build_backend_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.build_backend.email}"
}

resource "google_project_iam_member" "build_backend_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.build_backend.email}"
}

resource "google_project_iam_member" "build_backend_cloudbuild_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.build_backend.email}"
}

resource "google_project_iam_member" "build_frontend_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.build_frontend.email}"
}

resource "google_project_iam_member" "build_frontend_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.build_frontend.email}"
}

resource "google_project_iam_member" "build_frontend_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.build_frontend.email}"
}

resource "google_project_iam_member" "build_frontend_cloudbuild_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.build_frontend.email}"
}
