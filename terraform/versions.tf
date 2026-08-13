terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Terraform Cloud, workspace VCS-driven (no CLI-driven, a diferencia del
  # borrador inicial de la hoja de ruta). Terraform Cloud completa el
  # bloque cloud{} solo al conectar el workspace, así que se deja el
  # nombre reservado pero sin hardcodear la org acá.
  cloud {
    organization = "Guille-devops"

    workspaces {
      name = "robin-devops-challenge"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
