variable "location" {
  type    = string
  default = "Canada Central"
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "test", "prod", "eph"], var.environment)
    error_message = "environment must be one of: dev, test, prod, eph."
  }
}

variable "namespace" {
  type    = string
  default = ""

  validation {
    condition     = var.environment == "eph" ? trimspace(var.namespace) != "" : var.namespace == ""
    error_message = "namespace must be non-empty for the eph environment and empty for all other environments."
  }
}
