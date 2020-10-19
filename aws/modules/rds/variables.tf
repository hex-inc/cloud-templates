variable "name" {
  type    = string
  default = "hex-main"
}

variable "instance_type" {
  type    = string
  default = "db.m5.large"
}

variable "vpc_id" {
  type = string
}

variable "security_groups" {
  type        = list(string)
  description = "A list of security groups allowed to connect to the DB"
}

variable "database_subnet_group" {
  type = string
}
