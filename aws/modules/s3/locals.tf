locals {
    // Backcompat so that resources are not recreated
    safe_name = var.bucket_name == "files" ? var.name : "${var.name}-${var.bucket_name}"
}