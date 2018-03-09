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
 $resourceGroupName
)

# Check these variables are set correctly
$deploySource = "command-line"     # Set to 'command-line', 'local', or 'github'
$deploySourceValid = @('command-line', 'local', 'github')
$resourceGroupLocation = "canadacentral"
$templateFilePath = "azuredeploy.json"
$parametersFilePath = "azuredeploy.parameters.json"
$templateUri = "https://raw.githubusercontent.com/skeeler/azure-templates/hc/wad-sql-iis-dsc/azuredeploy.json"

if ($deploySource -notin $deploySourceValid)
{
    Write-Output ""
    Write-Output "Deployment did not run!"
    Write-Error 'Invalid value specified for $deploySource parameter' -ErrorAction Continue
    Write-Output "Specify one of: 'command-line', 'local', or 'github'"
    Write-Output "Current value is: $($deploySource)"
    Write-Output ""
    return
}

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

# Setup different deployment names if you want to run multiple deployments concurrently
$deployName = $resourceGroupName + (Get-Date -Format "yyMMdd-HHmmss")

# Run the deployment as "command-line", "local", or "github"
if ($deploySource -eq "command-line")
{
    $dnsQualifier = "-qual-105"
    $adminUsername = "admaccess"
    $adminPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
    $domainName = "contoso.local"
    $_artifactsLocation = "https://raw.githubusercontent.com/skeeler/azure-templates/master/wad-sql-iis-dsc"

    Write-Output "Deploying using local template file and command-line parameters..."
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -dnsQualifier $dnsQualifier -adminUser $adminUserName -adminPassword $adminPassword -domainName $domainName -Name $deployName -_artifactsLocation $_artifactsLocation -Verbose   #-DeploymentDebugLogLevel All

    # https://azure.microsoft.com/en-us/blog/debugging-arm-template-deployments/
}
elseif ($deploySource -eq "local")
{
    if(Test-Path $parametersFilePath)
    {
        Write-Output "Deploying using local template file and local parameters file..."
        New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Name $deployName -Verbose
    }
    else
    {
        Write-Output "Deploying using local template file and no parameters file..."
        New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -Name $deployName -Verbose;
    }
}
elseif ($deploySource -eq "github")
{
    if(Test-Path $parametersFilePath)
    {
        Write-Output "Deploying using GitHub-based template file and local parameters file..."
        New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterFile $parametersFilePath -Name $deployName -Verbose
    }
    else
    {
        Write-Output "Deploying using GitHub-based template file and no parameters file..."
        New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -Name $deployName -Verbose;
    }
}

$deployStop = Get-Date
$deployTime = $deployStop - $deployStart
Write-Output ""
Write-Output "*** Deployment stopped at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
Write-Output ""
Write-Output "*** Deployment took $($deployTime.Hours) hours $($deployTime.Minutes) minutes $($deployTime.Seconds) seconds"
Write-Output ""
