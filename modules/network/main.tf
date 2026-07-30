locals {
  name_prefix = var.name_prefix

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = "network"
    }
  )
}
