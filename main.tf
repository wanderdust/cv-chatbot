terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_lambda_function" "cv_chatbot" {
  function_name = var.lambda_name

  package_type  = "Image"
  image_uri     = var.image_uri
  architectures = ["x86_64"]
  timeout       = 60
  memory_size   = 512
  environment {
    variables = {
      TRANSFORMERS_CACHE = "/mnt/hf_models_cache"

    }
  }

  file_system_config {
    arn              = aws_efs_access_point.cv_chatbot_efs_ap.arn
    local_mount_path = "/mnt/hf_models_cache"
  }

  vpc_config {
    subnet_ids         = ["subnet-0710c1187011bcfe7"]
    security_group_ids = ["sg-09399de201c3b4831"]
  }


  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "cv_chatbot" {
  name = "/aws/lambda/${aws_lambda_function.cv_chatbot.function_name}"

  retention_in_days = 5
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  inline_policy {
    name = "lambda_create_network_interface"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ec2:DescribeNetworkInterfaces",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeInstances",
            "ec2:AttachNetworkInterface",
            "elasticfilesystem:ClientMount",
            "elasticfilesystem:ClientWrite"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_apigatewayv2_api" "lambda" {
  name          = "cv_chatbot_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["http://localhost:3000/,https://pablolopez.tech/"]
    allow_methods = ["OPTIONS", "GET", "POST"]
    allow_headers = ["Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token"]
    max_age       = 400
  }
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "cv_chatbot" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.cv_chatbot.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "cv_chatbot" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key          = "GET /chat"
  target             = "integrations/${aws_apigatewayv2_integration.cv_chatbot.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "cv_chatbot_options" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key          = "OPTIONS /chat"
  target             = "integrations/${aws_apigatewayv2_integration.cv_chatbot.id}"
  authorization_type = "NONE"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 5
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cv_chatbot.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}


# EFS
resource "aws_efs_file_system" "cv_chatbot_efs" {}

resource "aws_efs_access_point" "cv_chatbot_efs_ap" {
  file_system_id = aws_efs_file_system.cv_chatbot_efs.id
  root_directory {
    path = "/exports/models"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "750"
    }
  }
  posix_user {
    uid = 1001
    gid = 1001
  }
}

resource "aws_efs_mount_target" "mount_target" {
  file_system_id = aws_efs_file_system.cv_chatbot_efs.id
  subnet_id      = "subnet-0710c1187011bcfe7"
}
