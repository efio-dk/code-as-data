resource "random_pet" "this" {
  keepers = {
    account = local.region_name
    region  = local.account_id
    name    = local.name_prefix
  }
}

resource "aws_s3_bucket" "this" {
  bucket = "${local.name_prefix}static-website-${random_pet.this.id}"
  tags   = local.default_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      # kms_master_key_id = aws_kms_key.this.arn
      # sse_algorithm     = "aws:kms"
      sse_algorithm = "AES256"
    }
  }
}
/*
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}
*/
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  index_document {
    suffix = local.config.index_document
  }

  error_document {
    key = local.config.error_document
  }
}

# resource "aws_s3_bucket_cors_configuration" "this" {
#   bucket = aws_s3_bucket.this.bucket

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["PUT", "POST"]
#     allowed_origins = ["https://s3-website-test.hashicorp.com"]
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3000
#   }

#   cors_rule {
#     allowed_methods = ["GET"]
#     allowed_origins = ["*"]
#   }
# }

data "aws_iam_policy_document" "this" {
  /*
  statement {
    sid    = "Allow SSL Requests Only"
    effect = "Deny"
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "Deny Incorrect Encryption Header"
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
    actions = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.this.arn]
    }
  }
*/
  statement {
    sid    = "Deny Unencrypted Object Uploads"
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
    actions = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }

  statement {
    sid = "Allow CloudFront Browsing"

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  dynamic "statement" {
    for_each = length(local.config.allowed_ip_cidrs) > 0 ? [1] : []

    content {
      sid = "Allowed IP CIDRs Browsing"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = [
        "s3:GetObject",
      ]

      resources = [
        "${aws_s3_bucket.this.arn}/*",
      ]

      condition {
        test     = "IpAddress"
        variable = "aws:SourceIp"
        values   = local.config.allowed_ip_cidrs
      }
    }
  }

  dynamic "statement" {
    for_each = length(local.config.trusted_accounts) > 0 ? [1] : []

    content {
      sid = "Allowed cross account uploads"

      principals {
        type        = "AWS"
        identifiers = [for acc in local.config.trusted_accounts : "arn:aws:iam::${acc}:root"]
      }

      actions = [
        "s3:DeleteObject",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ]

      resources = [
        "${aws_s3_bucket.this.arn}",
        "${aws_s3_bucket.this.arn}/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = "public-read"
      }
    }
  }


}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_s3_object" "this" {
  count = local.config.deploy_sample_document ? 1 : 0

  bucket       = aws_s3_bucket.this.bucket
  key          = "index.html"
  source       = "${path.module}/sample/index.html"
  content_type = "text/html"
  # kms_key_id   = aws_kms_key.this.arn
}
