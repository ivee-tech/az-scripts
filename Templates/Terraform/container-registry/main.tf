resource "azurerm_resource_group" "rg" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_container_registry" "acr" {
  name                     = var.acrName
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = var.acrSku
  admin_enabled            = false
}
