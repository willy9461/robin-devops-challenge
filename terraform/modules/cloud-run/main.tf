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

# GCP genera 2 URLs distintas para el mismo servicio de Cloud Run (una
# con hash, otra con el número de proyecto) — se necesita el número para
# poder armar la segunda a mano, ya que el output .uri del recurso solo
# expone la primera.
data "google_project" "current" {
  project_id = var.project_id
}

locals {
  frontend_alt_url = "https://${var.frontend_service_name}-${data.google_project.current.number}.${var.region}.run.app"
}

resource "google_cloud_run_v2_service" "backend" {
  project  = var.project_id
  name     = var.backend_service_name
  location = var.region
  # Explícito en "ALL", no simplemente omitido: este campo es
  # Optional+Computed en el provider de Google — si se omite la línea en
  # vez de ponerla en un valor concreto, Terraform interpreta "dejar de
  # gestionar este campo" y NO revierte al default, sino que deja el
  # valor real que ya estuviera en GCP (en este caso, se había quedado
  # trabado en INTERNAL_LOAD_BALANCER de un cambio anterior, a pesar de
  # que el apply reportaba "Updated" sin error).
  ingress = "INGRESS_TRAFFIC_ALL"

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
        # Se combinan 3 orígenes: el dominio del Load Balancer (el
        # camino "real" de la app), y las 2 URLs raw de Cloud Run del
        # frontend que genera GCP para el mismo servicio (una con hash,
        # otra con el número de proyecto) — ambas siguen respondiendo en
        # paralelo por decisión propia, así que quedan funcionales.
        name  = "FRONTEND_ORIGIN"
        value = "${var.frontend_origin},${google_cloud_run_v2_service.frontend.uri},${local.frontend_alt_url}"
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
  ingress  = "INGRESS_TRAFFIC_ALL"

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
