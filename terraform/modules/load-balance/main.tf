# Módulo: load-balance
#
# Certificado SSL gestionado (dominio nip.io generado a partir de la IP,
# reservada a nivel raíz — ver comentario en el root main.tf sobre por
# qué vive ahí y no acá) + un Serverless NEG por servicio + un solo
# url_map que rutea por path: todo lo que no matchee cae al frontend
# (default), y las rutas de la API van al backend. Con esto, frontend y
# backend quedan bajo el mismo origen — el navegador deja de ver CORS
# como un problema cross-origin.

locals {
  # nip.io resuelve automáticamente <ip>.nip.io hacia esa misma IP, sin
  # necesidad de crear ningún registro DNS a mano ni esperar propagación
  # — por eso se puede pedir el certificado gestionado justo después,
  # en el mismo apply, sin condición de carrera.
  domain = "${var.ip_address}.nip.io"
}

resource "google_compute_managed_ssl_certificate" "cert" {
  project = var.project_id
  name    = "${var.name}-cert"

  managed {
    domains = [local.domain]
  }
}

resource "google_compute_region_network_endpoint_group" "frontend_neg" {
  project               = var.project_id
  name                  = "${var.name}-frontend-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.frontend_service_name
  }
}

resource "google_compute_region_network_endpoint_group" "backend_neg" {
  project               = var.project_id
  name                  = "${var.name}-backend-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.backend_service_name
  }
}

resource "google_compute_backend_service" "frontend" {
  project               = var.project_id
  name                  = "${var.name}-frontend-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.frontend_neg.id
  }
}

resource "google_compute_backend_service" "backend" {
  project               = var.project_id
  name                  = "${var.name}-backend-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.backend_neg.id
  }
}

# Un solo host (el dominio nip.io), ruteado por path: /health y
# /projects* van al backend, todo lo demás (la SPA de React) va al
# frontend. Es lo que le permite al navegador tratar ambos servicios
# como un único origen.
resource "google_compute_url_map" "https" {
  project         = var.project_id
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.frontend.id

  host_rule {
    hosts        = [local.domain]
    path_matcher = "main"
  }

  path_matcher {
    name            = "main"
    default_service = google_compute_backend_service.frontend.id

    path_rule {
      paths   = ["/health", "/projects", "/projects/*"]
      service = google_compute_backend_service.backend.id
    }
  }
}

resource "google_compute_target_https_proxy" "https" {
  project          = var.project_id
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.https.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "${var.name}-https-rule"
  target                = google_compute_target_https_proxy.https.id
  port_range            = "443"
  ip_address             = var.ip_address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# Redirect HTTP -> HTTPS
resource "google_compute_url_map" "http_redirect" {
  project = var.project_id
  name    = "${var.name}-http-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "http" {
  project = var.project_id
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  project               = var.project_id
  name                  = "${var.name}-http-rule"
  target                = google_compute_target_http_proxy.http.id
  port_range            = "80"
  ip_address             = var.ip_address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
