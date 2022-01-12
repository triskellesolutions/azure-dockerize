

function GenerateSshKey {
    ssh-keygen `
    -m PEM `
    -t rsa `
    -b 4096 `
    -C "ubuntu-vm" `
    -f ./.keys/ubuntu-vm
}

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

function RunDeployment {
    Param(
        [parameter(Mandatory=$true)][String] $resourceGroupName,
        [parameter(Mandatory=$true)][String] $dnsNameForPublicIP,
        [parameter(Mandatory=$true)][String] $adminUsername,
        [parameter(Mandatory=$true)][String] $adminPasswordOrKey
    )
    az deployment group create `
    --resource-group $resourceGroupName `
    --template-file "azuredeploy.bicep" `
    --parameters "azuredeploy.parameters.json" `
    --parameters  `
        adminUsername="${adminUsername}" `
        adminPasswordOrKey="${adminPasswordOrKey}" `
        dnsNameForPublicIP="${dnsNameForPublicIP}" `
         | ConvertFrom-Json

}


