variable "lambda_name" {
  description = "The name of the lambda function"
  type        = string
  default     = "pablo-cv-chatbot"
}


variable "image_uri" {
  description = "The name of the ECR repository"
  type        = string
  default     = "236212633992.dkr.ecr.eu-west-1.amazonaws.com/pablo-cv-chatbot:latest"
}
