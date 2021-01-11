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

variable "additional_eks_users" {
  type    = list(object({ groups = list(string), userarn = string, username = string }))
  default = []
}
