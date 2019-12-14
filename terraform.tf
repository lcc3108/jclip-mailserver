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
#data
data "aws_vpc" "jclip" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.jclip.id

  
}

data "aws_security_groups" "default" {
  tags = {
    service = "jclip"
  }
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

  depends_on    = [aws_iam_role_policy_attachment.lambda_logs, aws_cloudwatch_log_group.example, aws_s3_bucket_object.jclip_bucket_object]
  role          = aws_iam_role.iam_for_lambda.arn
  s3_bucket     = "jclip"
  s3_key        = "${data.archive_file.jclip_zip.output_md5}.zip"
  function_name = "jclip_api"
  handler       = "index.awsHandler"
  runtime       = "nodejs8.10"
   vpc_config {
    subnet_ids         = data.aws_subnet_ids.default.ids
    security_group_ids = data.aws_security_groups.default.ids
  }
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda.zip"))}"
}

#Aplication LoadBalancer

resource "aws_lb" "default" {
  name               = "jcliplb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = data.aws_security_groups.default.ids
  subnets            = data.aws_subnet_ids.default.ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "default" {
  name        = "jcliplb-TG"
  target_type = "lambda"
}

resource "aws_lb_listener" "default" {
  load_balancer_arn = aws_lb.default.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

resource "aws_lb_listener_rule" "lambda" {
  listener_arn = aws_lb_listener.default.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn =  aws_lb_target_group.default.arn
  }
  condition{
    path_pattern {
      values = ["/**"]
    }
  }
  
}

resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromLB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.default.arn
}

resource "aws_lb_target_group_attachment" "default" {
  target_group_arn = aws_lb_target_group.default.arn
  target_id        = aws_lambda_function.lambda.arn
}

# return base url
output "base_url" {
  value = aws_lb.default.dns_name
}
#API gateway
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

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/jclip_api"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "network" {
  name = "lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.network.arn
}

resource "aws_iam_role_policy_attachment" "lambda_network" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
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
EOF
}