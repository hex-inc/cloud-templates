terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "hex"

    workspaces {
      prefix = "hex-"
    }
  }
}
