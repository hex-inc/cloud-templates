variable "name" {
  type    = string
  default = "hex-main"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "num_nodes" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "t3.xlarge"
}

variable "create_db_bastion" {
  type    = bool
  default = false
}