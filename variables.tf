variable "instance" {
  type    = string
  default = "main"
}

# Provisioning variables
variable "num_nodes" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "t3.2xlarge"
}
