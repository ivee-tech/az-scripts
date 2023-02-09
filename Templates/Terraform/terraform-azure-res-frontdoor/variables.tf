variable "tags" {
  description = "Map of Tags to add to the resource (Required)"
  type        = map(string)
}

variable "resource_group_name" {
  description = "The name of the resource group to create the front door in. (Required)"
  type        = string
}

variable "settings" {
  description = "A map of values that will build out the front door components. See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor for setting names that are used. (Required)"
}

variable "frontdoor_name" {
  description = "Name for the front door. (Required)"
  type        = string
}

variable "keyvault_id" {
  description = "The Azure ID for a KeyVault that will be used for storing SSL certificates. (Optional)"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "The Azure ID for a Log Analytics Workspace that will be used by Azure Front Door"
  type        = string
}