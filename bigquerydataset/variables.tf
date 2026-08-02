# ==============================================================================
# Author: Prakriti Mandal
# Contact: prakritimandal611@gmail.com
# ==============================================================================

variable "project_id" {
  type        = string
  description = "The Google Cloud Project ID where resources will be provisioned"
  default     = "k8s-staging-252732"
}

variable "region" {
  type        = string
  description = "The GCP region for regional resources"
  default     = "us-central1"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., prod, staging, dev)"
  default     = "prod"
}

variable "data_retention_days" {
  type        = number
  description = "Number of days to retain objects in the raw landing bucket"
  default     = 90
}
