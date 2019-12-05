# GCP SETTING
provider "google" {
  credentials = "${file("google_key.json")}"
  project     = "[your-project-name]"
  region      = "[your-region]"
}

data "archive_file" "frontend_zip" {
  type        = "zip"
  source_dir  = "./frontend/out"
  output_path = "./frontend.zip"
}

resource "google_storage_bucket" "bucket" {
  name = "[your-bucket]"
}

resource "google_storage_bucket_object" "backend_object" {
  name   = "${data.archive_file.backend_zip.output_base64sha256}.zip"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${data.archive_file.backend_zip.output_path}"
}
resource "google_cloudfunctions_function" "function" {
  name                  = "[your-fuction-name]"
  description           = "My function"
  runtime               = "nodejs8"

  available_memory_mb   = 256
  source_archive_bucket = "${google_storage_bucket.bucket.name}"
  source_archive_object = "${google_storage_bucket_object.backend_object.name}"
  trigger_http          = true
  timeout               = 60
  entry_point           = "graphql"
}
