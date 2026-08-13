variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP"
  type        = string
}

variable "network_id" {
  description = "ID de la VPC (output del módulo networking), para la IP privada"
  type        = string
}

variable "instance_name" {
  description = "Nombre de la instancia de Cloud SQL"
  type        = string
  default     = "robin-db"
}

variable "database_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "app_db"
}

variable "db_user_name" {
  description = "Nombre del usuario de la base de datos"
  type        = string
  default     = "app_user"
}

variable "database_version" {
  description = "Versión del motor (Postgres)"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Tier de la instancia (free-tier friendly)"
  type        = string
  default     = "db-f1-micro"
}
