variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP (donde viven los NEGs serverless)"
  type        = string
}

variable "name" {
  description = "Prefijo para nombrar los recursos del load balancer"
  type        = string
  default     = "robin-lb"
}

variable "ip_address" {
  description = "IP estática reservada a nivel raíz (evita una dependencia circular con cloud-run, que necesita conocer los dominios nip.io antes de que exista este módulo)"
  type        = string
}

variable "frontend_domain" {
  description = "Dominio nip.io del frontend (calculado a nivel raíz a partir de ip_address)"
  type        = string
}

variable "backend_domain" {
  description = "Dominio nip.io del backend, con prefijo api. (calculado a nivel raíz a partir de ip_address)"
  type        = string
}

variable "frontend_service_name" {
  description = "Nombre del servicio Cloud Run del frontend (output del módulo cloud-run)"
  type        = string
}

variable "backend_service_name" {
  description = "Nombre del servicio Cloud Run del backend (output del módulo cloud-run)"
  type        = string
}
