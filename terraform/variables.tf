variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP"
  type        = string
  default     = "us-central1"
}

# TODO: sumar acá las variables específicas de cada módulo a medida que
# se definen (nombres de servicios, imágenes iniciales, etc.), o pasarlas
# con defaults dentro de cada módulo si no necesitan ser configurables
# desde afuera.
