# Módulo: cloud-run
#
# 2 servicios: backend (con Direct VPC Egress para llegar a Cloud SQL
# privada, sin conector separado) y frontend. Ambos aceptan tráfico tanto
# vía el Load Balancer (módulo load-balance) como directo a su URL
# *.run.app — a diferencia de una versión anterior que restringía el
# ingress solo al Load Balancer, se decidió mantener ambos caminos
# accesibles en paralelo.
#
# lifecycle.ignore_changes en la imagen: el primer apply usa una imagen
# placeholder, los deploys reales los hace el CI/CD (Cloud Build) después,
# para que `terraform plan` no intente revertir esos deploys.

resource "google_cloud_run_v2_service" "backend" {
  project  = var.project_id
  name     = var.backend_service_name
  location = var.region

  template {
    service_account = var.backend_service_account_email

    containers {
      image = var.backend_image

      ports {
        container_port = 8080
      }

      env {
        name  = "DB_HOST"
        value = var.db_host
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
      }
      env {
        name  = "DB_USER"
        value = var.db_user
      }
      env {
        name  = "FRONTEND_ORIGIN"
        value = var.frontend_origin
      }

      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = var.db_password_secret_id
            version = "latest"
          }
        }
      }
    }

    vpc_access {
      network_interfaces {
        network    = var.network_name
        subnetwork = var.subnet_name
      }
      egress = "PRIVATE_RANGES_ONLY"
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }
}

resource "google_cloud_run_v2_service" "frontend" {
  project  = var.project_id
  name     = var.frontend_service_name
  location = var.region

  template {
    service_account = var.frontend_service_account_email

    containers {
      image = var.frontend_image

      ports {
        container_port = 8080
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }
}

resource "google_cloud_run_v2_service_iam_member" "backend_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "frontend_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
