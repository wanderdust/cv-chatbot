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



# API Gateway
resource "aws_api_gateway_rest_api" "cv_chatbot" {
  name        = "cv_chatbot"
  description = "cv_chatbot"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.cv_chatbot.id
  parent_id   = aws_api_gateway_rest_api.cv_chatbot.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.cv_chatbot.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.cv_chatbot.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cv_chatbot.invoke_arn
}

resource "aws_api_gateway_deployment" "cv_chatbot" {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]
  rest_api_id = aws_api_gateway_rest_api.cv_chatbot.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cv_chatbot.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the specified API Gateway.
  source_arn = "${aws_api_gateway_rest_api.cv_chatbot.execution_arn}/*/*"
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
