@description('The name of you Virtual Machine.')
param vmName string = 'simpleLinuxVM'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('simplelinuxvm-${uniqueString(resourceGroup().id)}')

@description('The Ubuntu offers from Canonical. Use 0001-com-ubuntu-server-focal for 20.04 version.')
@allowed([
  'UbuntuServer'
  '0001-com-ubuntu-server-focal'
])
param offer string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Use 20_04-lts-gen2 with 0001-com-ubuntu-server-focal offer, anything else with UbuntuServer offer.')
@allowed([
  '12.04.5-LTS'
  '14.04.5-LTS'
  '16.04.0-LTS'
  '18.04-LTS'
  '20_04-lts-gen2'
])
param ubuntuOSVersion string = '18.04-LTS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VM')
param vmSize string = 'Standard_B2s'

@description('Name of the VNET')
param vnetName string = 'vNet'

@description('Name of the subnet in the virtual network')
param subnetName string = 'default'

@description('Name of the Network Security Group')
param networkSecurityGroupName string = 'SecGroupNet'

// @description('Script to execute for custom extension (BASE 64 encoded)')
// param script string = ''

var publicIpAddressName_var = '${vmName}pip'
var networkInterfaceName_var = '${vmName}nic'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var osDiskType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource publicIpAddressName 'Microsoft.Network/publicIpAddresses@2020-06-01' = {
  name: publicIpAddressName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: offer
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
  }
}

resource vmName_custom_script 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = if(false) {
  parent: vmName_resource
  name: 'install-dev-software'
  location: resourceGroup().location
  tags: {
    displayName: 'install-dev-software'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      // script: script
      commandToExecute: 'sh install.sh'
      fileUris: [
        'https://raw.githubusercontent.com/ivee-tech/infrastructure/main/Templates/ARM/linux-vm/scripts/install.sh'
      ]
    }
  }
}

output adminUsername string = adminUsername
output hostname string = publicIpAddressName.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${publicIpAddressName.properties.dnsSettings.fqdn}'
