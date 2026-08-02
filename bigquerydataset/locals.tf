# ==============================================================================
# Author: Prakriti Mandal
# Contact: prakritimandal611@gmail.com
# ==============================================================================

locals {
  # Project details mapped from variables
  project_id          = var.project_id
  region              = var.region
  environment         = var.environment
  data_retention_days = var.data_retention_days

  # Service Accounts and Groups
  landing_loader_sa     = google_service_account.landing_loader.email
  etl_loader_sa         = google_service_account.etl_loader.email
  teacher_onboarding_sa = google_service_account.teacher_onboarding.email
  data_analysts_group   = "data-analysts-group@example.com"
  analyst_auditor       = "analyst-auditor@example.com"

  # Resource Names
  bucket_name = "bigquery-d0-raw-landing-${local.environment}-${local.project_id}"
  dataset_id  = "d1_staged_enforced_${local.environment}"
}
