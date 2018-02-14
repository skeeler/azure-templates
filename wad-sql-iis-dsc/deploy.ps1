<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER parametersFilePath
    Path to the parameters file.
#>

param(
[Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string]
 $parametersFilePath
)

 $resourceGroupLocation = "canadacentral"
 $templateFilePath = "azuredeploy.json"
 $templateUri = "https://raw.githubusercontent.com/skeeler/azure-templates/hc/wad-sql-iis-dsc/azuredeploy.json"

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

Write-Output ""
Write-Output "Ensure you are logged in to Azure (Login-AzureRmAccount), and"
Write-Output "the correct subscription is selected (Select-AzureRmSubscription)"
Write-Output "prior to proceeding."
Write-Output ""

Pause
$deployStart = Get-Date
Write-Output ""
Write-Output "*** Starting deployment at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
Write-Output ""

# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.devtestlab","microsoft.network","microsoft.storage");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";
if(Test-Path $parametersFilePath)
{
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterFile $parametersFilePath;
}
else
{
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri;
}

$deployTime = Get-Date - $deployStart
Write-Output ""
Write-Output "*** Deployment stopped at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
Write-Output ""
Write-Output "*** Deployment took $($deployTime.Hours) hours $($deployTime.Minutes) minutes $($deployTime.Seconds) seconds"
Write-Output ""
