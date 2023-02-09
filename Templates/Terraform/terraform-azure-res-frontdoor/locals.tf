locals {
  module_tag = {
    "Module" = "terraform-azure-awe-res-frontdoor"
  }
  tags = merge(var.tags, local.module_tag, try(var.settings.tags, null))
  backend_pool = flatten([
    for backend_pool_key, backend_pool in var.settings.backend_pool : [

      for backend in backend_pool.backend : {
        backend_pool_key = backend_pool_key
        address          = backend.address
      }
    ]
  ])

}
