# Módulo: load-balance
#
# Certificado SSL gestionado (cubre 2 dominios nip.io: uno para el
# frontend, uno para el backend — ambos generados a partir de la IP
# reservada a nivel raíz) + un Serverless NEG por servicio + un url_map
# que rutea por HOST: cada subdominio va directo a su propio backend
# service, sin necesidad de path matching.
#
# Frontend y backend quedan en orígenes distintos (subdominios), así que
# el navegador SÍ trata las llamadas del frontend al backend como
# cross-origin — por eso el backend restringe su CORS al dominio exacto
# del frontend (ver root main.tf).

resource "google_compute_managed_ssl_certificate" "cert" {
  project = var.project_id
  # El nombre incluye un hash de los dominios que cubre: si los dominios
  # cambian en el futuro, el nombre cambia con ellos, y Terraform puede
  # crear el certificado nuevo ANTES de borrar el viejo (nombres
  # distintos, sin colisión), en vez de intentar borrar el viejo primero
  # mientras el proxy todavía lo está usando — el error real que dio acá
  # ("resourceInUseByAnotherResource") cuando el nombre no cambiaba.
  name = "${var.name}-cert-${substr(md5(join(",", [var.frontend_domain, var.backend_domain])), 0, 8)}"

  managed {
    domains = [var.frontend_domain, var.backend_domain]
  }

  lifecycle {
    create_before_destroy = true
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

# Ruteo por HOST: cada dominio (subdominio) va directo a su backend
# service, sin path matching — a diferencia de la versión anterior con
# un solo dominio ruteado por path.
resource "google_compute_url_map" "https" {
  project         = var.project_id
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.frontend.id

  host_rule {
    hosts        = [var.frontend_domain]
    path_matcher = "frontend"
  }

  host_rule {
    hosts        = [var.backend_domain]
    path_matcher = "backend"
  }

  path_matcher {
    name            = "frontend"
    default_service = google_compute_backend_service.frontend.id
  }

  path_matcher {
    name            = "backend"
    default_service = google_compute_backend_service.backend.id
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
