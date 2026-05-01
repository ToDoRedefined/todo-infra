locals {
  namespace_prefix = var.environment == "eph" && trimspace(var.namespace) != "" ? "${var.namespace}-" : var.namespace
}
