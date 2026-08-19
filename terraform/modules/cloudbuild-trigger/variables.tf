variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP"
  type        = string
}

variable "repo_owner" {
  description = "Usuario/org de GitHub dueño del repo de la app"
  type        = string
  default     = "willy9461"
}

variable "repo_name" {
  description = "Nombre del repo de la app"
  type        = string
  default     = "robin-devops-challenge"
}

variable "backend_service_account_email" {
  description = "Email de la SA de runtime del backend (identidad con la que corre el servicio desplegado, usada en gcloud run deploy)"
  type        = string
}

variable "frontend_service_account_email" {
  description = "Email de la SA de runtime del frontend (identidad con la que corre el servicio desplegado, usada en gcloud run deploy)"
  type        = string
}

variable "build_backend_service_account_email" {
  description = "Email de la SA de build del backend (ejecutor del trigger en sí, distinto de la SA de runtime)"
  type        = string
}

variable "build_frontend_service_account_email" {
  description = "Email de la SA de build del frontend (ejecutor del trigger en sí, distinto de la SA de runtime)"
  type        = string
}

variable "backend_service_name" {
  description = "Nombre del servicio Cloud Run del backend (output del módulo cloud-run)"
  type        = string
}

variable "frontend_service_name" {
  description = "Nombre del servicio Cloud Run del frontend (output del módulo cloud-run)"
  type        = string
}

variable "artifact_registry_repo" {
  description = "Nombre del repo de Artifact Registry para las imágenes"
  type        = string
  default     = "robin-images"
}

variable "trigger_name_prefix" {
  description = "Prefijo para los nombres de los triggers"
  type        = string
  default     = "robin-deploy"
}

variable "tag_pattern" {
  description = "Regex de tags que disparan el CI/CD"
  type        = string
  default     = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
}
