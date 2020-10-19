variable "name" {
  type    = string
  default = "hex-main"
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "num_nodes" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "t3.2xlarge"
}
