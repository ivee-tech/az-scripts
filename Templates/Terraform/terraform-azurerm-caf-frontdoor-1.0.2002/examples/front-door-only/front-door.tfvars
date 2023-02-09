front-door-object = {
  name          = "<Name for Front Door>"
  name          = "caftest-afd-mwg"
  friendly_name = "CAF Test for Azure Front Door" 
  enforce_backend_pools_certificate_name_check = false
  load_balancer_enabled                        = true   

   routing_rule = {
    rr1 = {
      name               = "exampleRoutingRule1"
      frontend_endpoints = ["exampleFrontendEndpoint1"]
      accepted_protocols = ["Http", "Https"] 
      patterns_to_match  = ["/*"]           
      enabled            = true              
      configuration      = "Forwarding"        
      forwarding_configuration = {
        backend_pool_name                     = "exampleBackendBing1"
        cache_enabled                         = false       
        cache_use_dynamic_compression         = false       
        cache_query_parameter_strip_directive = "StripNone" 
        custom_forwarding_path                = ""
        forwarding_protocol                   = "MatchRequest"   
      }
      redirect_configuration = {
        custom_host         = ""             
        redirect_protocol   = "MatchRequest"   
        redirect_type       = "Found"        
        custom_fragment     = ""
        custom_path         = ""
        custom_query_string = ""
      }
    } 
  }

  backend_pool_load_balancing = {
    lb1 = {
      name                            = "exampleLoadBalancingSettings1"
      sample_size                     = 4
      successful_samples_required     = 2
      additional_latency_milliseconds = 0 
    }                                     
  }

  backend_pool_health_probe = {
    hp1 = {
      name                = "exampleHealthProbeSetting1"
      path                = "/"
      protocol            = "Http"
      interval_in_seconds = 120    
    }                             
  }

  backend_pool = {
    bp1 = {
      name = "exampleBackendBing1"
      backend = {
        be1 = {
          enabled     = true
          address     = "www.bing.com"
          host_header = "www.bing.com"
          http_port   = 80
          https_port  = 443
          priority    = 1  
          weight      = 50
        },
        be2 = {
          enabled     = true
          address     = "www.bing.co.uk"
          host_header = "www.bing.co.uk"
          http_port   = 80
          https_port  = 443
          priority    = 1 
          weight      = 50
        }
      }
      load_balancing_name = "exampleLoadBalancingSettings1"
      health_probe_name   = "exampleHealthProbeSetting1"
    } 
  }

  frontend_endpoint = {
    fe1 = {
      name                              = "exampleFrontendEndpoint1"
      #host_name                         = "<Name for Front Door>.azurefd.net"
      host_name                         = "caftest-afd-mwg.azurefd.net"
      session_affinity_enabled          = false 
      session_affinity_ttl_seconds      = 0     
      custom_https_provisioning_enabled = false
      #Required if custom_https_provisioning_enabled is true
      custom_https_configuration = {
        certificate_source = "FrontDoor" 
        #If certificate source is AzureKeyVault the below are required:
        azure_key_vault_certificate_vault_id       = ""
        azure_key_vault_certificate_secret_name    = ""
        azure_key_vault_certificate_secret_version = ""
      }
      web_application_firewall_policy_link_name = ""  
    }                                                              

  }
}
