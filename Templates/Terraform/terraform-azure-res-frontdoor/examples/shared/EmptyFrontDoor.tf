module "front_door" {
  source   = "../.."
  for_each = local.front_doors

  # Use the Corporate Tagging module to create this map
  # terraform-azure-awe-sup-corporate-tagging
  tags = module.tags.tag_map

  resource_group_name        = azurerm_resource_group.daff-demo.name
  settings                   = each.value
  frontdoor_name             = local.front_doors.front_door1.name # Needs to be globally unique
  log_analytics_workspace_id = module.law.id
}


locals {
  front_doors = {
    front_door1 = {
      name                                         = "daff-fd-003"
      enforce_backend_pools_certificate_name_check = false

      routing_rule = {
        rr1 = {
          name                   = "rr1-daff-fd-003"
          frontend_endpoint_keys = ["frontend1"]
          accepted_protocols     = ["Http"]
          patterns_to_match      = ["/*"]
          enabled                = true
          configuration          = "forwarding"
          forwarding_configuration = {
            backend_pool_name = "devbackend1"
          }
        }
      }
      backend_pool_load_balancing = {
        defaultLoadBalancingSettings = {
          name = "defaultLoadBalancingSettings"
        }
      }
      backend_pool_health_probe = {
        healthprobe = {
          name                = "healthprobe"
          path                = "/"
          protocol            = "Https"
          interval_in_seconds = 30
          probe_method        = "HEAD"
        }
      }
      backend_pool = {
        devbackend1 = {
          name               = "devbackend1"
          load_balancing_key = "defaultLoadBalancingSettings"
          health_probe_key   = "healthprobe"
          backend = {
            be3-aueast = {
              enabled     = true
              address     = "ets-demo-dev.azurewebsites.net"
              host_header = "ets-demo-dev.azurewebsites.net"
              http_port   = 80
              https_port  = 443
              priority    = 1
              weight      = 50
            }
          }
        },
        testbackend1 = {
          name               = "testbackend1"
          load_balancing_key = "defaultLoadBalancingSettings"
          health_probe_key   = "healthprobe"
          backend = {
            be3-aueast = {
              enabled     = true
              address     = "ets-demo-test.azurewebsites.net"
              host_header = "ets-demo-test.azurewebsites.net"
              http_port   = 80
              https_port  = 443
              priority    = 1
              weight      = 50
            }
          }
        }
      }
      frontend_endpoints = {
        frontend1 = {
          name      = "frontend1"
          host_name = "daff-fd-003.azurefd.net"
        }
      }
    }
  }
}
