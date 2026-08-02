# ==============================================================================
# Author: Prakriti Mandal
# Contact: prakritimandal611@gmail.com
# ==============================================================================
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
}
