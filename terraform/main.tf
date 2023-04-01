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

data "archive_file" "cv_chatbot" {
  type        = "zip"
  source_dir  = "../build"
  output_path = "../cv_chatbot.zip"
}

resource "aws_lambda_function" "cv_chatbot" {
  function_name    = var.lambda_name
  runtime          = "python3.8"
  handler          = "main.handler"
  filename         = data.archive_file.cv_chatbot.output_path
  source_code_hash = data.archive_file.cv_chatbot.output_base64sha256

  timeout = 20
  environment {
    variables = {
      OPENAI_API_KEY = var.api_key

    }
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

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.cv_chatbot.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    aws_api_gateway_method.proxy
  ]

}

resource "aws_api_gateway_integration_response" "response_200" {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]
  rest_api_id = aws_api_gateway_rest_api.cv_chatbot.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'https://pablolopez.tech'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
  }

  response_templates = {
    "application/json" = ""
  }
}
