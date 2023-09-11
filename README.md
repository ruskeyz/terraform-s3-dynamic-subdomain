# Automatic subdomain delivery with terraform

Using reverse-proxy + CNAME wildcard and lambda@edge with cloudfront to dynamically create subdomains based on the contents.

### Why Terraform?

- Expect changes to infrastructure daily
- Declarative approach: describe the outcome
-  Terraform manages infrastructure with code in a consistent manner and mitigate the risks of human error
-  mkdir and cd into terraform.

Requirements
Have AWS CLI, terraform configured etc

### Set up

create terraform.tfvars with:

```
domain_host    = "example.com"
domain_name    = "dev.example.com"
backend_bucket = "terraform-backend.example.com"
backend_key    = "demo-project"
lambda_s3_key  = "lambdas-example-com"



common_tags = {
  Project = "example.com"
}
```

specify domain name in lambda/index.js

Create s3 backend folder with the name from backend_bucket, specify policy from template in providers.tf
Create versioned s3 bucket for lambdas
