# ==============================================================================
# Author: Prakriti Mandal
# Contact: prakritimandal611@gmail.com
# ==============================================================================
resource "google_service_account" "landing_loader" {
  account_id   = "landing-loader-sa"
  display_name = "Landing Loader Service Account"
}

resource "google_service_account" "etl_loader" {
  account_id   = "etl-loader-sa"
  display_name = "ETL Loader Service Account"
}

resource "google_service_account" "teacher_onboarding" {
  account_id   = "teacher-onboarding-sa"
  display_name = "Teacher Onboarding Service Account"
}

resource "google_storage_bucket" "raw_landing" {
  name          = local.bucket_name
  location      = local.region
  force_destroy = false

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
  public_access_prevention = "enforced"

  encryption {
    default_kms_key_name = "" # Set KMS key path if Customer Managed Encryption Key is desired
  }
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = local.data_retention_days
    }
  }

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = 30
    }
  }
}

resource "google_storage_bucket_iam_member" "restricted_landing_loader" {
  bucket = google_storage_bucket.raw_landing.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.landing_loader_sa}"
}

resource "google_bigquery_dataset" "staged_enforced" {
  dataset_id                  = local.dataset_id
  friendly_name               = "D1 Staged Enforced Dataset"
  description                 = "Contains validated and structured student onboarding schemas"
  location                    = local.region
  default_table_expiration_ms = 31536000000 # 365 days in milliseconds

  # Restrict access permissions explicitly
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "WRITER"
    user_by_email = local.etl_loader_sa
  }


  access {
    role          = "READER"
    user_by_email = local.teacher_onboarding_sa
  }
}

resource "google_bigquery_table" "student_onboarding_staged" {
  dataset_id          = google_bigquery_dataset.staged_enforced.dataset_id
  table_id            = "student_onboarding_staged"
  deletion_protection = false

  schema = jsonencode([
    {
      name        = "student_id",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "Unique alphanumeric student identifier"
    },
    {
      name        = "name",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "Full name of the student"
    },
    {
      name        = "age",
      type        = "INTEGER",
      mode        = "REQUIRED",
      description = "Age of the student (must be >= 5)"
    },
    {
      name        = "email",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "Primary email address"
    },
    {
      name        = "grade",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "Onboarding performance grade (A, B, C, D, F)"
    },
    {
      name        = "courses",
      type        = "STRING",
      mode        = "REPEATED",
      description = "List of active courses registered by the student"
    }
  ])
}

resource "google_bigquery_row_access_policy" "student_rls_policy" {
  dataset_id      = google_bigquery_dataset.staged_enforced.dataset_id
  table_id        = google_bigquery_table.student_onboarding_staged.table_id
  policy_id       = "rls_restrict_underage_and_unauthorized"
  
  filter_predicate = "age >= 18 OR session_user() = '${local.teacher_onboarding_sa}'"
  
  grantees = [
    "serviceAccount:${local.teacher_onboarding_sa}"
  ]
}

