variable "name" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "pgp_key" {
  type = string
}

variable "hex_account_id" {
  type = string
}

variable "hex_vpc_id" {
  type = string
}

variable "hex_vpc_region" {
  type = string
}