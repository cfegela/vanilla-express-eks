# S3 Bucket for Frontend Static Files
resource "aws_s3_bucket" "frontend" {
  count         = var.enable_cloudfront ? 1 : 0
  bucket        = "${var.cluster_name}-frontend"
  force_destroy = true

  tags = {
    Name = "${var.cluster_name}-frontend"
  }
}

# Block all public access - CloudFront will access via OAC
resource "aws_s3_bucket_public_access_block" "frontend" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for rollback capability
resource "aws_s3_bucket_versioning" "frontend" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Origin Access Control for secure S3 access
resource "aws_cloudfront_origin_access_control" "frontend" {
  count                             = var.enable_cloudfront ? 1 : 0
  name                              = "${var.cluster_name}-frontend-oac"
  description                       = "OAC for ${var.cluster_name} frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 Bucket Policy allowing CloudFront OAC access
resource "aws_s3_bucket_policy" "frontend" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend[0].arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  count = var.enable_cloudfront ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${var.cluster_name} frontend distribution"
  price_class         = "PriceClass_100"

  aliases = [var.frontend_domain_name]

  origin {
    domain_name              = aws_s3_bucket.frontend[0].bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend[0].id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend[0].id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend[0].id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Custom error response for SPA routing (return index.html for 404s)
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "${var.cluster_name}-frontend-cdn"
  }
}

# Route53 Alias Record for CloudFront
resource "aws_route53_record" "frontend" {
  count   = var.enable_cloudfront ? 1 : 0
  zone_id = local.hosted_zone_id
  name    = var.frontend_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend[0].domain_name
    zone_id                = aws_cloudfront_distribution.frontend[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Deploy frontend files to S3
resource "null_resource" "frontend_deploy" {
  count = var.enable_cloudfront ? 1 : 0

  triggers = {
    # Re-deploy when any frontend file changes
    app_js_hash    = filemd5("${path.module}/../../frontend/app.js")
    index_hash     = filemd5("${path.module}/../../frontend/index.html")
    users_hash     = filemd5("${path.module}/../../frontend/users.html")
    add_user_hash  = filemd5("${path.module}/../../frontend/add-user.html")
    edit_user_hash = filemd5("${path.module}/../../frontend/edit-user.html")
    styles_hash    = filemd5("${path.module}/../../frontend/styles.css")
    api_url        = var.frontend_api_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create temporary directory for modified files
      TEMP_DIR=$(mktemp -d)

      # Copy all frontend files except app.js
      cp ${path.module}/../../frontend/index.html $TEMP_DIR/
      cp ${path.module}/../../frontend/users.html $TEMP_DIR/
      cp ${path.module}/../../frontend/add-user.html $TEMP_DIR/
      cp ${path.module}/../../frontend/edit-user.html $TEMP_DIR/
      cp ${path.module}/../../frontend/edit-user.html $TEMP_DIR/
      cp ${path.module}/../../frontend/styles.css $TEMP_DIR/

      # Create app.js with replaced API_URL
      sed "s|const API_URL = 'http://localhost:3000';|const API_URL = '${var.frontend_api_url}';|g" \
        ${path.module}/../../frontend/app.js > $TEMP_DIR/app.js

      # Sync to S3 with proper content types
      aws s3 sync $TEMP_DIR s3://${aws_s3_bucket.frontend[0].id}/ \
        --delete \
        --cache-control "max-age=31536000" \
        --exclude "*.html" \
        --region ${var.aws_region}

      # Upload HTML files with shorter cache
      aws s3 sync $TEMP_DIR s3://${aws_s3_bucket.frontend[0].id}/ \
        --exclude "*" \
        --include "*.html" \
        --cache-control "max-age=0, must-revalidate" \
        --content-type "text/html" \
        --region ${var.aws_region}

      # Invalidate CloudFront cache
      aws cloudfront create-invalidation \
        --distribution-id ${aws_cloudfront_distribution.frontend[0].id} \
        --paths "/*" \
        --region us-east-1

      # Cleanup
      rm -rf $TEMP_DIR
    EOT
  }

  depends_on = [
    aws_s3_bucket.frontend,
    aws_s3_bucket_policy.frontend,
    aws_cloudfront_distribution.frontend
  ]
}
