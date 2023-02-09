@description('Local Admin Username for the Virtual Machine.')
param adminUsername string

@description('Local Admin Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
  'VS-2017-Comm-Latest-Preview-WS2016'
  'VS-2017-Comm-Latest-Win10-N'
  'VS-2017-Comm-Latest-WS2016'
  'VS-2017-Comm-Win10-N'
  'VS-2017-Comm-WS2016'
  'VS-2017-Ent-Latest-Preview-WS2016'
  'VS-2017-Ent-Latest-Win10-N'
  'VS-2017-Ent-Latest-WS2016'
  'VS-2017-Ent-Win10-N'
  'VS-2017-Ent-WS2016'
  'vs-2019-comm-ws2019'
  'vs-2019-comm-latest-ws2019'
  'vs-2019-ent-latest-ws2019'
])
param sku string = 'vs-2019-comm-latest-ws2019'

@description('Virtual netowrk name')
param vnetName string = 'vnet'

@description('Virtual machine name')
param vmName string = 'vmname'

@description('The VM size, specifying the hardware profile, e.g. Standard_A2, Standard_DS2_v2, Standard_D4s_v3, etc.')
param vmSize string = 'Standard_DS2_v2'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The IP address or range to allow RDP inbound access.')
param rdpAddressRange string = '*'

@description('Cost Centre for the VM')
param costCentre string

var storageAccountName_var = '${uniqueString(resourceGroup().id)}acctvswinvm'
var nicName_var = '${vmName}NIC'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Default'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = '${vmName}PIP'
var vmName_var = vmName
var vmSize_var = vmSize
var virtualNetworkName_var = vnetName
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var nsgName_var = '${virtualNetworkName_var}${subnetName}nsg'
var tags = {
  costCentre: costCentre
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2018-07-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  tags: tags
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-10-01' = {
  name: publicIPAddressName_var
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2018-10-01' = {
  name: nsgName_var
  location: location
  tags: tags
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAzureLoadBalancerInBound'
        properties: {
          description: 'Allow inbound traffic from azure load balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 65001
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource nsgName_RDPRule 'Microsoft.Network/networkSecurityGroups/securityRules@2018-10-01' = {
  parent: nsgName
  name: 'RDPRule'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3389'
    sourceAddressPrefix: rdpAddressRange
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1000
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: virtualNetworkName_var
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsgName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2018-10-01' = {
  name: nicName_var
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2018-10-01' = {
  name: vmName_var
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize_var
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftVisualStudio'
        offer: 'visualstudio2019latest'
        sku: sku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
}

output hostname string = publicIPAddressName.properties.dnsSettings.fqdn
