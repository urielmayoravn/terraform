locals {
  origin_access_control_id = one(aws_cloudfront_origin_access_control.main[*].id)
}

resource "aws_cloudfront_origin_access_control" "main" {
  count = var.create_oac == true ? 1 : 0

  name                              = var.oac_attrs.name
  description                       = var.oac_attrs.description
  origin_access_control_origin_type = var.oac_attrs.origin_type
  signing_behavior                  = var.oac_attrs.signing_behavior
  signing_protocol                  = var.oac_attrs.signing_protocol
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name              = var.origin_domain_name
    origin_access_control_id = local.origin_access_control_id
    origin_id                = var.default_origin
  }

  enabled = true
  aliases = var.aliases


  default_cache_behavior {
    allowed_methods        = var.default_cache_behavior.allowed_methods
    cached_methods         = var.default_cache_behavior.cached_methods
    target_origin_id       = var.default_origin
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy

    forwarded_values {
      query_string = var.default_cache_behavior.query_string
      cookies {
        forward = var.default_cache_behavior.cookies
      }
    }
  }

  for_each = { for i, val in var.ordered_cache_behavior : i => val }
  ordered_cache_behavior {
    path_pattern           = each.value.path_pattern
    allowed_methods        = each.value.allowed_methods
    cached_methods         = each.value.cached_methods
    target_origin_id       = var.default_origin
    viewer_protocol_policy = each.value.viewer_protocol_policy

    forwarded_values {
      query_string = each.value.query_string
      cookies {
        forward = each.value.cookies
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${var.s3_bucket.bucket.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "aoc_updated_policy" {
  count  = var.s3_bucket != null ? 1 : 0
  bucket = var.s3_bucket.bucket
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}
