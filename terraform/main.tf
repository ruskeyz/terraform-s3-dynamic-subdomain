provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "site" {
  bucket = var.domain_name
  acl    = "private"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "access_from_another_account" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.access.json
}

data "aws_iam_policy_document" "access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.identity.iam_arn]
    }
  }
}


resource "aws_cloudfront_origin_access_identity" "identity" {
  comment = "identity iam_arn to access s3 bucket"
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_host
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_host}"]

  tags = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.record : record.fqdn]
}



resource "aws_route53_record" "record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id

}

resource "aws_route53_zone" "primary" {
  name = var.domain_host

  tags = var.common_tags
}

// https://registry.terraform.io/modules/transcend-io/lambda-at-edge/aws/latest?tab=outputs
// Specify lambda@egde here
module "lambda_at_edge" {
  source                 = "transcend-io/lambda-at-edge/aws"
  version                = "0.4.0"
  description            = "Implements dynamic subdomain hosting"
  lambda_code_source_dir = "${path.module}/lambda"
  name                   = "playrcartappsubDomainRedirectS3Edge"
  runtime                = "nodejs14.x"
  s3_artifact_bucket     = var.lambda_s3_key
}



resource "aws_cloudfront_distribution" "dist" {
  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = var.domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.identity.cloudfront_access_identity_path
    }
  }
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["*.${var.domain_host}"]
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = var.domain_name
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    forwarded_values {
      query_string = false
      headers      = ["Origin", "Host"]
      cookies {
        forward = "none"
      }
    }
    lambda_function_association {
      event_type   = "origin-request"
      include_body = false
      lambda_arn   = module.lambda_at_edge.arn
    }
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "subdomain" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "*.${var.domain_host}"
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.dist.domain_name
    zone_id                = aws_cloudfront_distribution.dist.hosted_zone_id
  }
}
