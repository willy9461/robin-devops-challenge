variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP"
  type        = string
}

variable "network_name" {
  description = "Nombre de la VPC"
  type        = string
  default     = "robin-vpc"
}

variable "subnet_name" {
  description = "Nombre de la subnet"
  type        = string
  default     = "robin-subnet"
}

variable "subnet_cidr" {
  description = "Rango CIDR de la subnet"
  type        = string
  default     = "10.0.0.0/24"
}
