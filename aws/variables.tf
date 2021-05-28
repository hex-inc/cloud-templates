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

variable "create_db_tunnel" {
  type    = bool
  default = false
}

variable "additional_eks_users" {
  type    = list(object({ groups = list(string), userarn = string, username = string }))
  default = []
}

# Optional route53
variable "domain" {
  type    = string
  default = null
}

variable "alb_hostname" {
  type    = string
  default = null
}

# Optional SES (route53 required as well)
variable "ses_enabled" {
  type    = bool
  default = false
}

# Monitoring
variable "monitoring_enabled" {
  type = bool
}

variable "newrelic_license_key" {
  type = string
}

variable "nr_slack_webhook" {
  type = string
}
