resource "azurerm_frontdoor" "frontdoor" {
  # Terraform registry for this resource: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor
  name                = var.frontdoor_name
  resource_group_name = var.resource_group_name
  tags                = local.int_tags

  dynamic "routing_rule" {
    for_each = var.settings.routing_rule

    content {
      name               = routing_rule.value.name
      accepted_protocols = routing_rule.value.accepted_protocols
      patterns_to_match  = routing_rule.value.patterns_to_match

      frontend_endpoints = flatten(
        [
          for key in try(routing_rule.value.frontend_endpoint_keys, []) : [
            var.settings.frontend_endpoints[key].name
          ]
        ]
      )

      dynamic "forwarding_configuration" {
        for_each = lower(routing_rule.value.configuration) == "forwarding" ? [routing_rule.value.forwarding_configuration] : []

        content {
          backend_pool_name                     = routing_rule.value.forwarding_configuration.backend_pool_name
          cache_enabled                         = try(routing_rule.value.forwarding_configuration.cache_enabled, null)
          cache_use_dynamic_compression         = try(routing_rule.value.forwarding_configuration.cache_use_dynamic_compression, null) #default: false
          cache_query_parameter_strip_directive = try(routing_rule.value.forwarding_configuration.cache_query_parameter_strip_directive, null)
          custom_forwarding_path                = try(routing_rule.value.forwarding_configuration.custom_forwarding_path, null)
          forwarding_protocol                   = try(routing_rule.value.forwarding_configuration.forwarding_protocol, null)
        }
      }
      dynamic "redirect_configuration" {
        for_each = lower(routing_rule.value.configuration) == "redirecting" ? [routing_rule.value.redirect_configuration] : []

        content {
          custom_host         = routing_rule.value.redirect_configuration.custom_host
          redirect_protocol   = routing_rule.value.redirect_configuration.redirect_protocol
          redirect_type       = routing_rule.value.redirect_configuration.redirect_type
          custom_fragment     = routing_rule.value.redirect_configuration.custom_fragment
          custom_path         = routing_rule.value.redirect_configuration.custom_path
          custom_query_string = routing_rule.value.redirect_configuration.custom_query_string
        }
      }
    }
  }

  load_balancer_enabled = try(var.settings.load_balancer_enabled, true)
  friendly_name         = try(var.settings.backend_pool.name, null)

  backend_pool_settings {
    enforce_backend_pools_certificate_name_check = try(var.settings.certificate_name_check, true)
    backend_pools_send_receive_timeout_seconds   = try(var.settings.backend_pools_send_receive_timeout_seconds, 60)
  }

  dynamic "backend_pool_load_balancing" {
    for_each = var.settings.backend_pool_load_balancing

    content {
      name                            = backend_pool_load_balancing.value.name
      sample_size                     = try(backend_pool_load_balancing.value.sample_size, null)
      successful_samples_required     = try(backend_pool_load_balancing.value.successful_samples_required, null)
      additional_latency_milliseconds = try(backend_pool_load_balancing.value.additional_latency_milliseconds, null)
    }
  }

  dynamic "backend_pool_health_probe" {
    for_each = var.settings.backend_pool_health_probe

    content {
      name                = backend_pool_health_probe.value.name
      path                = backend_pool_health_probe.value.path
      protocol            = backend_pool_health_probe.value.protocol
      interval_in_seconds = backend_pool_health_probe.value.interval_in_seconds
      probe_method        = backend_pool_health_probe.value.probe_method
    }
  }

  dynamic "backend_pool" {
    for_each = var.settings.backend_pool

    content {
      name                = backend_pool.value.name
      load_balancing_name = var.settings.backend_pool_load_balancing[backend_pool.value.load_balancing_key].name
      health_probe_name   = var.settings.backend_pool_health_probe[backend_pool.value.health_probe_key].name

      dynamic "backend" {
        for_each = backend_pool.value.backend
        content {
          enabled     = backend.value.enabled
          address     = backend.value.address
          host_header = backend.value.host_header
          http_port   = backend.value.http_port
          https_port  = backend.value.https_port
          priority    = backend.value.priority
          weight      = backend.value.weight
        }
      }
    }
  }

  dynamic "frontend_endpoint" {
    for_each = var.settings.frontend_endpoints

    content {
      name                                    = frontend_endpoint.value.name
      host_name                               = try(frontend_endpoint.value.host_name, format("%s.azurefd.net", ""))
      session_affinity_enabled                = try(frontend_endpoint.value.session_affinity_enabled, null)
      session_affinity_ttl_seconds            = try(frontend_endpoint.value.session_affinity_ttl_seconds, null)
      web_application_firewall_policy_link_id = try(frontend_endpoint.value.front_door_waf_policy, null)
    }
  }
}

resource "azurerm_frontdoor_custom_https_configuration" "custom_https" {
  # Terraform registry for this resource: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor_custom_https_configuration
  for_each = var.settings.frontend_endpoints

  # frontend_endpoint_id is being hardcoded as a workaround for a bug in the azurerm provider.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/10504
  frontend_endpoint_id              = "${azurerm_frontdoor.frontdoor.id}/frontendEndpoints/${each.value.name}"
  custom_https_provisioning_enabled = try(each.value.custom_https_provisioning_enabled, false)

  dynamic "custom_https_configuration" {
    for_each = try(each.value.custom_https_provisioning_enabled, false) == true ? [1] : []
    content {
      certificate_source                         = each.value.custom_https_configuration.certificate_source
      azure_key_vault_certificate_secret_name    = try(each.value.custom_https_configuration.azure_key_vault_certificate_secret_name, null)
      azure_key_vault_certificate_vault_id       = try(each.value.custom_https_configuration.azure_key_vault_certificate_vault_id, null)
      azure_key_vault_certificate_secret_version = try(each.value.custom_https_configuration.azure_key_vault_certificate_secret_version, null)
    }
  }
}

