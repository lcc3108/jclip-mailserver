# TF-UPGRADE-TODO: Block type was not recognized, so this block and its contents were not automatically upgraded.
#init

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "jclip"

    workspaces {
      name = "jclip-mailserver"
    }
  }
}

#google
# GCP SETTING
provider "google" {
  credentials = file("google_key.json")
  project     = "jclip-260801"
  region      = "asia-east2"
}

data "archive_file" "jclip_zip" {
  type        = "zip"
  source_dir  = "./dist"
  output_path = "./dist.zip"
}

resource "google_storage_bucket" "bucket" {
  name = "jclip_bucket"
}

resource "google_storage_bucket_object" "backend_object" {
  name   = "${data.archive_file.jclip_zip.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.jclip_zip.output_path
}

resource "google_cloudfunctions_function" "function" {
  name        = "jclip_api_server"
  description = "My function"
  runtime     = "nodejs8"
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.backend_object.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "gcpHandler"
}

#aws
provider "aws" {
  region = "us-east-1"
}

#source upload

resource "aws_s3_bucket" "jclip_bucket" {
  bucket = "jclip"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "jclip_bucket_object" {
  bucket = "jclip"
  key    = "${data.archive_file.jclip_zip.output_md5}.zip"
  source = "dist.zip"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "jclip"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "api"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:us-east-1:906259781909:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

resource "aws_lambda_function" "lambda" {
  depends_on    = [aws_s3_bucket_object.jclip_bucket_object]
  s3_bucket     = "jclip"
  s3_key        = "${data.archive_file.jclip_zip.output_md5}.zip"
  function_name = "jclip_api"
  role          = aws_iam_role.role.arn
  handler       = "index.awsHandler"
  runtime       = "nodejs8.10"
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda.zip"))}"
}

resource "aws_api_gateway_stage" "default" {
  stage_name    = "default"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.test.id
}

resource "aws_api_gateway_deployment" "test" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "test"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
}

# IAM
resource "aws_iam_role" "role" {
  name = "myrole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY

}

