/*

*/

@description('The resource group prefix.  This will be used as a prefix on all resources in this group.')
param resourcePrefix string = 'tss'

@description('Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed. This will have the resourcePrefix prepended')
param storageAccountName string = 'storage'

@description('Unique Bucket Name for the Storage Account where the Virtual Machine\'s disks will be placed.')
param storageAccountFileShareName string = 'fileshare'

@description('The resource group name for the storage account.')
param storageAccountResouceGroupName string = resourceGroup().name

@description('Unique DNS prefix for the Public IP used to access the Virtual Machine. alphanumeric ')
param dnsNameForPublicIP string

@allowed([
  '20_04-lts-gen2'
])
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values: 18.04-LTS, 16.04.0-LTS, 14.04.5-LTS.')
param ubuntuOSVersion string = '20_04-lts-gen2'

@description('Size of the virtual machine')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Admin user name for the Virtual Machine.')
param adminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'password'

@description('''SSH Key or password for the Virtual Machine. SSH key is recommended.
if authenticationType='password':
    The supplied password must be between 6-72 characters long and must satisfy at least 3 of password complexity requirements from the following:
    1) Contains an uppercase character
    2) Contains a lowercase character
    3) Contains a numeric digit
    4) Contains a special character
    5) Control characters are not allowed
'''')
@secure()
param adminPasswordOrKey string

@description('The service account used to connect to azure storage.')
@secure()
param serviceAccountId string
@description('The service account password used to connect to azure storage.')
@secure()
param serviceAccountPassword string
@description('The service account tenant used to connect to azure storage.')
@secure()
param serviceAccountTenant string

@description('This is the path to the version of gist we are using. Example: https://raw.githubusercontent.com/triskellesolutions/azure-ubuntu-sftp/master/<file-name>')
param gistUrlPath string = 'https://raw.githubusercontent.com/triskellesolutions/azure-dockerize/main/docker-sql-container/install.sh'

@allowed([
  'AzureCloud'
  'AzureUSGovernment'
])
@description('This is the azure cloud env we are working against.')
param azureCloudEnv string

@allowed([
  'new'
  'existing'
])
param newOrExisting string = 'new'

var _resourcePrefix = ((newOrExisting ==  'new') ? resourcePrefix : ((newOrExisting ==  'existing') ? resourcePrefix : resourcePrefix))
/*
*    _storageAccountName when newOrExisting ==  'new' combine prefix with the storage.
*/
var _storageAccountName = ((newOrExisting ==  'new') ? replace('${resourcePrefix}${storageAccountName}', '-', '') : ((newOrExisting ==  'existing') ? storageAccountName : storageAccountName))
var _storageAccountFileShareName = ((newOrExisting ==  'new') ? storageAccountFileShareName : ((newOrExisting ==  'existing') ? storageAccountFileShareName : storageAccountFileShareName))
var _dnsNameForPublicIP = ((newOrExisting ==  'new') ? dnsNameForPublicIP : ((newOrExisting ==  'existing') ? dnsNameForPublicIP : dnsNameForPublicIP))
var _ubuntuOSVersion = ((newOrExisting ==  'new') ? ubuntuOSVersion : ((newOrExisting ==  'existing') ? ubuntuOSVersion : ubuntuOSVersion))
var _vmSize = ((newOrExisting ==  'new') ? vmSize : ((newOrExisting ==  'existing') ? vmSize : vmSize))
var _location = ((newOrExisting ==  'new') ? location : ((newOrExisting ==  'existing') ? location : location))
var _storageAccountResourceGroupName = ((newOrExisting ==  'new') ? storageAccountResouceGroupName : ((newOrExisting ==  'existing') ? storageAccountResouceGroupName : storageAccountResouceGroupName))
var _adminUsername = ((newOrExisting ==  'new') ? adminUsername : ((newOrExisting ==  'existing') ? adminUsername : adminUsername))
var _authenticationType = ((newOrExisting ==  'new') ? authenticationType : ((newOrExisting ==  'existing') ? authenticationType : authenticationType))
var _adminPasswordOrKey = ((newOrExisting ==  'new') ? adminPasswordOrKey : ((newOrExisting ==  'existing') ? adminPasswordOrKey : adminPasswordOrKey))
var _serviceAccountId = ((newOrExisting ==  'new') ? serviceAccountId : ((newOrExisting ==  'existing') ? serviceAccountId : serviceAccountId))
var _serviceAccountPassword = ((newOrExisting ==  'new') ? serviceAccountPassword : ((newOrExisting ==  'existing') ? serviceAccountPassword : serviceAccountPassword))
var _serviceAccountTenant = ((newOrExisting ==  'new') ? serviceAccountTenant : ((newOrExisting ==  'existing') ? serviceAccountTenant : serviceAccountTenant))
var _gistUrlPath = ((newOrExisting ==  'new') ? gistUrlPath : ((newOrExisting ==  'existing') ? gistUrlPath : gistUrlPath))
var _azureCloudEnv = ((newOrExisting ==  'new') ? azureCloudEnv : ((newOrExisting ==  'existing') ? azureCloudEnv : azureCloudEnv))

var _imagePublisher = 'Canonical'
var _imageOffer = (_ubuntuOSVersion == '20_04-lts-gen2') ? '0001-com-ubuntu-server-focal' : 'UbuntuServer'
var _nicName = '${_resourcePrefix}-vm-nic'
var _addressPrefix = '10.0.0.0/16'
var _subnetName = '${_resourcePrefix}-subnet'
var _subnetPrefix = '10.0.0.0/24'
var _publicIPAddressName = '${_resourcePrefix}-public-ip'
var _publicIPAddressType = 'Static'
var _vmName = '${_resourcePrefix}-ubuntu-vm'
var _virtualNetworkName = '${_resourcePrefix}-vnet'
var _subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', _virtualNetworkName, _subnetName)
var _linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${_adminUsername}/.ssh/authorized_keys'
        keyData: _adminPasswordOrKey
      }
    ]
  }
}
var _networkSecurityGroupName = '${_resourcePrefix}-nsg'

resource storageAccountContainerShareResource 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' existing = {
  name: '${_storageAccountName}/default/${_storageAccountFileShareName}'
  scope: resourceGroup(_storageAccountResourceGroupName)
}

// var _fileShareAccessTier = 'Cool'
// resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-02-01' = {
//   name: _storageAccountName
//   location: _location
//   sku: {
//     name: 'Standard_LRS'
//   }
//   kind: 'StorageV2'
//   properties: {
//     accessTier: _fileShareAccessTier
//   }
// }

// resource storageAccountContainerShareResource 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
//   name: '${_storageAccountName}/default/${_storageAccountFileShareName}'
//   properties: {
//     accessTier: _fileShareAccessTier
//   }
//   dependsOn: [
//     storageAccountResource
//   ]
// }

resource publicIPAddressNameResource 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: _publicIPAddressName
  location: _location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: _publicIPAddressType
    dnsSettings: {
      domainNameLabel: _dnsNameForPublicIP
    }
  }
}

resource networkSecurityGroupNameResource 'Microsoft.Network/networkSecurityGroups@2021-05-01' =  {
  name: _networkSecurityGroupName
  location: _location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-9090'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '9090'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-80'
        properties: {
          priority: 1003
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkNameResource 'Microsoft.Network/virtualNetworks@2021-05-01' =  {
  name: _virtualNetworkName
  location: _location
  properties: {
    addressSpace: {
      addressPrefixes: [
        _addressPrefix
      ]
    }
    subnets: [
      {
        name: _subnetName
        properties: {
          addressPrefix: _subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupNameResource.id
          }
        }
      }
    ]
  }
}

resource nicNameResource 'Microsoft.Network/networkInterfaces@2021-05-01' =  {
  name: _nicName
  location: _location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressNameResource.id
          }
          subnet: {
            id: _subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkNameResource
  ]
}

resource _vmNameResource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: _vmName
  location: _location
  properties: {
    hardwareProfile: {
      vmSize: _vmSize
    }
    osProfile: {
      computerName: _vmName
      adminUsername: _adminUsername
      adminPassword: _adminPasswordOrKey
      linuxConfiguration: ((_authenticationType == 'password') ? json('null') : _linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: _imagePublisher
        offer: _imageOffer
        sku: _ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicNameResource.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountContainerShareResource
  ]
}

resource vmName_install_sfpt 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: _vmNameResource
  name: 'install_sftp'
  location: _location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
      fileUris: [
        '${_gistUrlPath}/install-sftp-server.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: ' sudo mkdir -p /vmsetup && sudo touch /vmsetup/install.log && sh install-sftp-server.sh "${_storageAccountResourceGroupName}" "${_storageAccountName}" "${_storageAccountFileShareName}" "${_serviceAccountId}" "${_serviceAccountPassword}" "${_serviceAccountTenant}" "${_gistUrlPath}" "${_azureCloudEnv}" 2>&1 | sudo tee /vmsetup/install.log && sudo chmod 600 /vmsetup/install.log'
    }
  }
}

