
$ErrorActionPreference = "Stop"

Write-Output ""
Write-Output "Ensure you are logged in to Azure (Login-AzureRmAccount), and"
Write-Output "the correct subscription is selected (Select-AzureRmSubscription)"
Write-Output "prior to proceeding."
Write-Output ""

Pause

$labName = "MyDevTestLab"
$resourceGroupLocation = "canadacentral"
#$resourceGroupLocation = "eastus"
#$resourceGroupLocation = "southeastasia"
$templateFilePath = "azuredeploy.json"
$resourceGroupName = "DevTest-Lab-RG"
$deployName = $resourceGroupName + (Get-Date -Format "yyMMdd-HHmmss")
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

if (!$resourceGroup) {
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -Name $deployName -labName $labName -Verbose
