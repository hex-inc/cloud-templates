variable "name" {
  type    = string
  default = "hex-main"
}

variable "bucket_name" {
  type = string
}

variable "expiration_days" {
  type    = number
  default = 0
}

variable "transition_days" {
  type    = number
  default = 0
}
