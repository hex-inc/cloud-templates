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
