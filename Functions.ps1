

function GenerateSshKey {
    ssh-keygen `
    -m PEM `
    -t rsa `
    -b 4096 `
    -C "ubuntu-vm" `
    -f ./.keys/ubuntu-vm
}

#  az login
#  # create the NEW resource group that will hold the vm instance
#  $group = az group create `
#    --name "<resource-group>" `
#    --location "<location>" `
#    --subscription "<subscription-id>" `
#    | ConvertFrom-Json
function CreateResourceGroup {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $resourceGroupName,
        [Parameter()]
        [string]
        $resourceGroupNameLocation,
        [Parameter()]
        [string]
        $subscriptionId
    )
    $group = az group create `
        --name $resourceGroupName `
        --location $resourceGroupNameLocation `
        --subscription $subscriptionId `
    | ConvertFrom-Json
    return $group
}

#  # create the service account with contrib on the new resource group
#  $rbac = az ad sp create-for-rbac `
#    --name $resourceGroupName `
#    --role contributor `
#    --scopes $resourceGroupId | ConvertFrom-Json
#    # capture output of the command to use in the bicep script
#  echo $rbac
#  ###############################################################################
#  #	{
#  #	  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#  #	  "displayName": "display-name",
#  #	  "name": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#  #	  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,
#  #	  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#  #	}
#  ################################################################################
#  $serviceAccountId=$rbac.appId
#  $serviceAccountPassword=$rbac.password
#  $serviceAccountTenant=$rbac.tenant
#  # Test the new service account and make sure you can login
#  az login --service-principal -u $serviceAccountId -p $serviceAccountPassword --tenant $serviceAccountTenant
#  #cd to bicep script
#  az deployment group create `
#  --resource-group $resourceGroupName `
#  --template-file "Ubuntu-VM-Create-Script.bicep" `
#  --parameters  `
#    resourcePrefix='<prefix-that-will-be-used-on-all-related-resources-this-script-creates-this-does-not-include-the-dns>' `
#    storageAccountName='<resourcePrefix-plus-this-value-must-be-unique-in-azure>' `
#    storageAccountFileShareName='<name-of-url-segment-path-of-storage>' `
#    dnsNameForPublicIP='<dns-prefix-unique-in-azure-in-the-location-the-resouce-is>' `
#    ubuntuOSVersion='18.04-LTS' `
#    vmSize='<vm-size-make-a-good-choice-in-dev-prd>' `
#    location=$resourceGroupLocation `
#    resourceGroupName=$resourceGroupName `
#    authenticationType='password' `
#    adminUsername='<root-level-user-name-used-to-access-the-machine>' `
#    adminPasswordOrKey='<strong-password>' `
#    serviceAccountId=$serviceAccountId `
#    serviceAccountPassword=$serviceAccountPassword `
#    serviceAccountTenant=$serviceAccountTenant | ConvertFrom-Json
#  echo $createvm
function RunDeployment {
    Param(
        [parameter(Mandatory=$true)][String] $resourceGroupName,
        [parameter(Mandatory=$true)][String] $dnsNameForPublicIP,
        [parameter(Mandatory=$true)][String] $adminUsername,
        [parameter(Mandatory=$true)][String] $adminPasswordOrKey
    )
    az deployment group create `
    --resource-group $resourceGroupName `
    --template-file "./ubuntu-docker-nginx/azuredeploy.bicep" `
    --parameters "./ubuntu-docker-nginx/azuredeploy.parameters.json" `
    --parameters  `
        adminUsername="${adminUsername}" `
        adminPasswordOrKey="${adminPasswordOrKey}" `
        dnsNameForPublicIP="${dnsNameForPublicIP}" `
         | ConvertFrom-Json

}


function install {
    $subscriptionId="4b8a8873-2247-4054-ab12-b7720eb83560"
    $resourceGroupLocation="eastus"
    $resourceGroupName="ubuntu-docker-sql-rg"
    $sshPublicKey=$(Get-Content -Raw ./.keys/ubuntu-vm.pub)
    #$resourceGroup=CreateResourceGroup $resourceGroupName $resourceGroupLocation $subscriptionId
    #$resourceGroupId=$resourceGroup.id
    $resourceGroupId='/subscriptions/4b8a8873-2247-4054-ab12-b7720eb83560/resourceGroups/ubuntu-docker-sql-rg'
    .RunDeployment "$resourceGroupName" 'tss-docker-sql' 'tssadmin' "${sshPublicKey}"
}
