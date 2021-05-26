variable "name" {
  type    = string
  default = "hex"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "eks_users" {
  type    = list(string)
  default = []
}

variable "instance_type" {
  type    = string
  default = "t3.2xlarge"
}

variable "num_nodes" {
  type    = number
  default = "3"
}

variable "domain_name" {
  type = string
}

variable "alb_url" {
  type    = string
  default = null
}
