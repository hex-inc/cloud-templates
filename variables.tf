variable "instance" {
  type    = string
  default = "main"
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
  default = "t3.2xlarge"
}
