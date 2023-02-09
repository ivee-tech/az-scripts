locals {
  int_tags = merge(var.tags, { module = "terraform-azure-awe-res-frontdoor", version = "1.0.0" })
}
