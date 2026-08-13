# Módulo: networking
#
# VPC + subnet + firewall rules + Private Service Access, para que Cloud
# SQL pueda tener IP privada dentro de esta VPC. Mismo patrón probado en
# el challenge anterior, sin bloque provider{} (lo define el root module).

resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                     = var.network_name
  auto_create_subnetworks  = false
}

resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr
}

# Permite tráfico interno entre recursos de la misma VPC (Cloud Run vía
# Direct VPC Egress <-> Cloud SQL).
resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}

# Bloquea explícitamente el acceso a los puertos de bases de datos desde
# fuera de la VPC — refuerzo defensivo (Cloud SQL con ipv4_enabled=false
# ya no tiene IP pública, esto es una segunda barrera).
resource "google_compute_firewall" "deny_db_ports_internet" {
  project = var.project_id
  name    = "deny-db-ports-internet"

  deny {
    protocol = "tcp"
    ports    = ["5432", "3306"]
  }

  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  priority      = 900
}

# Rango de IPs reservado para Private Service Access (lo usa Cloud SQL
# internamente para su propia red administrada por Google).
resource "google_compute_global_address" "private_ip_range" {
  project       = var.project_id
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                  = "servicenetworking.googleapis.com"
  reserved_peering_ranges  = [google_compute_global_address.private_ip_range.name]
}
