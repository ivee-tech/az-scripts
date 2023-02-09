# Azure FrontDoor Module

[[_TOC_]]

## Description

The purpose of this module is to take in data to dynamically configure all the aspects of a Azure FrontDoor.

## Usage

All of the configuration for the FrontDoor module will live in a map inside the locals.tf file, so please see the [examples directory](./examples) in this module for a complete working example. Below is just a simple example of how you would call the FrontDoor module as well as a bare example of the structure of the local settings.

```hcl
module "front_door" {
    source   = "git::https://{org}@dev.azure.com/{org}/eslz-Module-Library/_git/terraform-azure-awe-res-frontdoor?ref=v1.x"
    for_each = local.front_doors
    
    # Use the Corporate Tagging module to create this map
    # terraform-azure-awe-sup-corporate-tagging
    tags = module.tags.tag_map

    resource_group_name = var.resource_group
    settings            = each.value
    frontdoor_name      = local.front_doors.front_door1.name # Needs to be globally unique
}

locals {
  front_doors = {
    front_door1 = {
      name                                         = "fd-example"
      enforce_backend_pools_certificate_name_check = false

      routing_rule = {
        rr1 = {
          config in here....
        }
      }
      backend_pool_load_balancing = {
        defaultLoadBalancingSettings = {
          name = "defaultLoadBalancingSettings"
        }
      }
      backend_pool_health_probe = {
        healthprobe = {
          config in here....
        }
      }
      backend_pool = {
        backendpoolexample = {
          name               = "backendpoolexample"
          load_balancing_key = "defaultLoadBalancingSettings"
          health_probe_key   = "healthprobe"
          backend = {
            be3-aueast = {
              config in here....
            }
          }
        }
      }
      frontend_endpoints = {
        frontendexample = {
          name      = "frontendexample"
          host_name = "fd-example.azurefd.net"
        }
      }
    }
  }
}
```

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_frontdoor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor) | resource |
| [azurerm_frontdoor_custom_https_configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor_custom_https_configuration) | resource |

## Inputs

Table of input variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_frontdoor_name"></a> [input\_frontdoor\_name](#input\_frontdoor\_name) | Name for the FrontDoor. Needs to be globally unique | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [input\_resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group to deploy into | `string` | n/a | yes |
| <a name="input_settings"></a> [input\_settings](#input\_settings) | The name of the Resource Group to deploy into | `map(any)` | n/a | yes |
| <a name="input_keyvault_id"></a> [input\_keyvault\_id](#input\_keyvault\_id) | The Azure ID of a KeyVault that stores certificates for use with the FrontDoor | `string` | n/a | no |
| <a name="input_tags"></a> [input\_tags](#input\_tags) | The Azure ID of a KeyVault that stores certificates for use with the FrontDoor | `map(string)` | n/a | yes |

## Outputs

Table of outputs from the module

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [output\_id](#output\_id) | The Azure ID of the FrontDoor |
| <a name="output_name"></a> [output\_name](#output\_name) | The name of the FrontDoor |
| <a name="output_frontend_endpoint"></a> [output\_frontend\_endpoint](#output\_frontend\_endpoint) | Will output the FrontDoor's frontend endpoint objects |
| <a name="output_header_frontdoor_id"></a> [output\_header\_frontdoor\_id](#output\_header\_frontdoor\_id) | Will output the FrontDoor's header ID. This can be used in the X-Azure-FDID http header  |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_action_group"></a> [action\_group](#module\_action\_group) | git::https://{org}@dev.azure.com/{org}/eslz-Module-Library/_git/terraform-azure-awe-res-monitor-action-group | v0.x |
| <a name="module_frontdoor_diagnostic_settings"></a> [frontdoor\_diagnostic\_settings](#module\_frontdoor\_diagnostic\_settings) | git::https://{org}@dev.azure.com/{org}/eslz-Module-Library/_git/terraform-azure-awe-sup-diagnostic-setting | v1.x |
| <a name="module_metric_alert_backendhealthpercentage_warning"></a> [metric\_alert\_backendhealthpercentage\_warning](#module\_metric\_alert\_backendhealthpercentage\_warning) | git::https://{org}@dev.azure.com/{org}/eslz-Module-Library/_git/terraform-azure-awe-res-monitor-metric-alert | v0.x |
| <a name="module_metric_alert_backendpoolhealthpercentage_critical"></a> [metric\_alert\_backendpoolhealthpercentage\_critical](#module\_metric\_alert\_backendpoolhealthpercentage\_critical) | git::https://{org}@dev.azure.com/{org}/eslz-Module-Library/_git/terraform-azure-awe-res-monitor-metric-alert | v0.x |
| <a name="module_metric_alert_backendpoolhealthpercentage_warning"></a> [metric\_alert\_backendpoolhealthpercentage\_warning](#module\_metric\_alert\_backendpoolhealthpercentage\_warning) | git::https://{org}@dev.azure.com/{org}/eslz-Module-Library/_git/terraform-azure-awe-res-monitor-metric-alert | v0.x |
| <a name="module_sqr_alert_frontdoorwafblockedrequests_warning"></a> [sqr\_alert\_frontdoorwafblockedrequests\_warning](#module\_sqr\_alert\_frontdoorwafblockedrequests\_warning) | git::https://{org}@dev.azure.com/{org}/eslz-Module-Library/_git/terraform-azure-awe-res-scheduled-query-rules-alert | v0.x |

## Resources

| Name | Type |
|------|------|
| [azurerm_frontdoor.frontdoor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor) | resource |
| [azurerm_frontdoor_custom_https_configuration.custom_https](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor_custom_https_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_frontdoor_name"></a> [frontdoor\_name](#input\_frontdoor\_name) | Name for the front door. (Required) | `string` | n/a | yes |
| <a name="input_keyvault_id"></a> [keyvault\_id](#input\_keyvault\_id) | The Azure ID for a KeyVault that will be used for storing SSL certificates. (Optional) | `string` | `null` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | The Azure ID for a Log Analytics Workspace that will be used by Azure Front Door | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group to create the front door in. (Required) | `string` | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | A map of values that will build out the front door components. See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor for setting names that are used. (Required) | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of Tags to add to the resource (Required) | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_frontend_endpoint"></a> [frontend\_endpoint](#output\_frontend\_endpoint) | n/a |
| <a name="output_header_frontdoor_id"></a> [header\_frontdoor\_id](#output\_header\_frontdoor\_id) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
<!-- END_TF_DOCS -->