variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP"
  type        = string
}

variable "network_name" {
  description = "Nombre de la VPC (output del módulo networking), para Direct VPC Egress del backend"
  type        = string
}

variable "subnet_name" {
  description = "Nombre de la subnet (output del módulo networking)"
  type        = string
}

variable "backend_service_account_email" {
  description = "Email de la SA de runtime del backend"
  type        = string
}

variable "frontend_service_account_email" {
  description = "Email de la SA de runtime del frontend"
  type        = string
}

variable "backend_service_name" {
  description = "Nombre del servicio Cloud Run del backend"
  type        = string
  default     = "robin-backend"
}

variable "frontend_service_name" {
  description = "Nombre del servicio Cloud Run del frontend"
  type        = string
  default     = "robin-frontend"
}

variable "backend_image" {
  description = "Imagen inicial del backend (placeholder; el CI/CD la reemplaza en cada deploy real)"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "frontend_image" {
  description = "Imagen inicial del frontend (placeholder; el CI/CD la reemplaza en cada deploy real)"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "db_host" {
  description = "IP privada de Cloud SQL (output del módulo database)"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos (output del módulo database)"
  type        = string
}

variable "db_user" {
  description = "Usuario de la base de datos (output del módulo database)"
  type        = string
}

variable "db_password_secret_id" {
  description = "ID del secret en Secret Manager con la password de la DB (output del módulo database)"
  type        = string
}

variable "frontend_origin" {
  description = "URL del dominio del Load Balancer, para restringir CORS del backend a ese origen específico (en vez del wildcard *)"
  type        = string
}
