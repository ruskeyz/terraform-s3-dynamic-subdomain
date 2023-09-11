variable "domain_host" {
  type        = string
  description = "Specify the domain host name (example.com)"
}

variable "domain_name" {
  type        = string
  description = "full domain name with the sub domain"
}

variable "backend_bucket" {
  type        = string
  description = "Name of the previously created S3 bucket to store terraform state"
}

variable "backend_key" {
  type = string
}

variable "lambda_s3_key" {
  type        = string
  description = "name of lambdas s3 bucket"
}

variable "common_tags" {
  description = "Common tags you want applied to all components"
}

