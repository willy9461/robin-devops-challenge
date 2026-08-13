# Módulo: cloudbuild-trigger
#
# Artifact Registry (donde van las imágenes) + 2 triggers de Cloud Build
# (uno para frontend, uno para backend — mismo repo, carpetas distintas),
# disparados por push de TAG, con los steps de build/push/deploy inline en
# HCL (sin cloudbuild.yaml en el repo, mismo patrón que el challenge
# anterior).
#
# Requiere que el repo de la app ya esté conectado a Cloud Build (paso
# manual, una sola vez, documentado en el README).

resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = var.artifact_registry_repo
  format        = "DOCKER"
}

locals {
  backend_image  = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/backend"
  frontend_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/frontend"
}

resource "google_cloudbuild_trigger" "backend" {
  project  = var.project_id
  name     = "${var.trigger_name_prefix}-backend"
  location = var.region

  github {
    owner = var.repo_owner
    name  = var.repo_name
    push {
      tag = var.tag_pattern
    }
  }

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "${local.backend_image}:$TAG_NAME", "-f", "backend/Dockerfile", "backend"]
    }
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "${local.backend_image}:$TAG_NAME"]
    }
    step {
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"
      args = [
        "run", "deploy", var.backend_service_name,
        "--image", "${local.backend_image}:$TAG_NAME",
        "--region", var.region,
        "--service-account", var.backend_service_account_email,
      ]
    }
  }
}

resource "google_cloudbuild_trigger" "frontend" {
  project  = var.project_id
  name     = "${var.trigger_name_prefix}-frontend"
  location = var.region

  github {
    owner = var.repo_owner
    name  = var.repo_name
    push {
      tag = var.tag_pattern
    }
  }

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "build",
        "-t", "${local.frontend_image}:$TAG_NAME",
        "-f", "frontend/Dockerfile",
        "--build-arg", "VITE_API_URL=${var.backend_url}",
        "frontend",
      ]
    }
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "${local.frontend_image}:$TAG_NAME"]
    }
    step {
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"
      args = [
        "run", "deploy", var.frontend_service_name,
        "--image", "${local.frontend_image}:$TAG_NAME",
        "--region", var.region,
        "--service-account", var.frontend_service_account_email,
      ]
    }
  }
}
