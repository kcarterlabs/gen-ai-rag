# ========================
# S3 Bucket
# ========================

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = merge(
    {
      Name    = var.bucket_name
      Purpose = "vector-storage"
      Project = var.project_name
    },
    var.tags
  )
}

# ========================
# Versioning Configuration
# ========================

resource "aws_s3_bucket_versioning" "bucket" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ========================
# Encryption Configuration
# ========================

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_algorithm
      kms_master_key_id = var.encryption_algorithm == "aws:kms" ? var.kms_key_id : null
    }
  }
}

# ========================
# Public Access Block
# ========================

resource "aws_s3_bucket_public_access_block" "bucket" {
  count  = var.block_public_access ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
