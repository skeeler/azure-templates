<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    A resource group location.

 .PARAMETER templateFilePath
    Path to the template file.

 .PARAMETER parametersFilePath
    Path to the parameters file.

 .PARAMETER templateUri
    URI for the template file.
#>

param(
[Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [string]
 $resourceGroupLocation = "canadacentral",

 [string]
 $templateFilePath = "azuredeploy.json",

 [string]
 $parametersFilePath = "azuredeploy.parameters.json",

 [string]
 $templateUri = "https://github.com/skeeler/azure-templates/blob/hc/wad-sql-iis/azuredeploy.json"
)

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