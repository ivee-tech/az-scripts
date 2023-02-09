locals {
    location = "global"
    prefix = "test"
    resource_groups = {
        test = { 
            name     = "-caf-afd"
            location = "australiaeast" 
        },
    }
    tags = {
        environment     = "DEV"
        owner           = "CAF"
    }
}