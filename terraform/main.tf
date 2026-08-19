# Root module — conecta los módulos entre sí: las referencias entre
# módulos son automáticas vía module.<nombre>.<output>, resueltas por
# Terraform dentro de un único workspace.

# La IP del Load Balancer se reserva acá, a nivel raíz, en vez de adentro
# del módulo load-balance — porque el dominio nip.io que se arma a partir
# de esta IP hace falta ANTES de crear los servicios de Cloud Run (para
# poder restringir CORS del backend a ese dominio), pero el módulo
# load-balance en sí depende de que esos servicios ya existan (necesita
# sus nombres para armar los NEGs). Reservar la IP acá, compartida por
# ambos módulos, rompe esa dependencia circular sin necesidad de un
# segundo apply.
resource "google_compute_global_address" "lb_ip" {
  project = var.project_id
  name    = "robin-lb-ip"
}

locals {
  lb_domain = "${google_compute_global_address.lb_ip.address}.nip.io"
}

module "networking" {
  source = "./modules/networking"

  project_id = var.project_id
  region     = var.region
}

module "service_accounts" {
  source = "./modules/service-accounts"

  project_id = var.project_id
}

module "database" {
  source = "./modules/database"

  project_id = var.project_id
  region     = var.region
  network_id = module.networking.network_id

  # Dependencia explícita: la instancia de Cloud SQL con IP privada
  # necesita que la conexión de Private Service Access ya esté establecida,
  # pero Terraform no detecta esa dependencia solo a través de network_id
  # (son recursos distintos dentro del módulo networking). Sin este
  # depends_on, a veces Terraform intenta crear la instancia antes de que
  # el peering termine de propagarse.
  depends_on = [module.networking]
}

module "cloud_run" {
  source = "./modules/cloud-run"

  project_id   = var.project_id
  region       = var.region
  network_name = module.networking.network_name
  subnet_name  = module.networking.subnet_name

  backend_service_account_email  = module.service_accounts.backend_email
  frontend_service_account_email = module.service_accounts.frontend_email

  db_host                = module.database.private_ip_address
  db_name                 = module.database.database_name
  db_user                 = module.database.db_user_name
  db_password_secret_id  = module.database.db_password_secret_id

  # El dominio se calcula solo a partir de la IP reservada arriba, sin
  # depender de que exista ningún servicio de Cloud Run — por eso se
  # puede pasar acá sin generar una dependencia circular con el módulo
  # load-balance.
  frontend_origin = "https://${local.lb_domain}"
}

module "cloudbuild_trigger" {
  source = "./modules/cloudbuild-trigger"

  project_id = var.project_id
  region     = var.region

  backend_service_account_email  = module.service_accounts.backend_email
  frontend_service_account_email = module.service_accounts.frontend_email

  build_backend_service_account_email  = module.service_accounts.build_backend_email
  build_frontend_service_account_email = module.service_accounts.build_frontend_email

  backend_service_name  = module.cloud_run.backend_service_name
  frontend_service_name = module.cloud_run.frontend_service_name
}

module "load_balance" {
  source = "./modules/load-balance"

  project_id = var.project_id
  region     = var.region
  ip_address = google_compute_global_address.lb_ip.address

  frontend_service_name = module.cloud_run.frontend_service_name
  backend_service_name  = module.cloud_run.backend_service_name
}
