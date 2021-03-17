variable "name" {
  type    = string
  default = "hex"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "instance_type" {
  type    = string
  default = "t3.2xlarge"
}

variable "num_nodes" {
  type    = number
  default = "3"
}

variable "vpc_peering_id" {
  type    = string
  default = null
}

variable "domain_name" {
  type = string
}

variable "alb_url" {
  type    = string
  default = null
}
