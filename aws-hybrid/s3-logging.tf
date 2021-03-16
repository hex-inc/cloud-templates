resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.name}-log-bucket"
  acl    = "log-delivery-write"
}
