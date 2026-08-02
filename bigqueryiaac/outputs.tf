# ==============================================================================
# Author: Prakriti Mandal
# Contact: prakritimandal611@gmail.com
# ==============================================================================

output "gcs_bucket_url" {
  value       = google_storage_bucket.raw_landing.url
  description = "The URL of the D0 Raw Landing GCS Bucket"
}

output "bq_dataset_id" {
  value       = google_bigquery_dataset.staged_enforced.dataset_id
  description = "The ID of the D1 Staged/Enforced BigQuery Dataset"
}

output "bq_table_id" {
  value       = google_bigquery_table.student_onboarding_staged.id
  description = "The fully qualified ID of the student onboarding staged table"
}
