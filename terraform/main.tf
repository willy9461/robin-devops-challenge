# Root module — conecta los módulos entre sí: las referencias entre
# módulos son automáticas vía module.<nombre>.<output>, resueltas por
# Terraform dentro de un único workspace.

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
  backend_url            = module.cloud_run.backend_url
}
