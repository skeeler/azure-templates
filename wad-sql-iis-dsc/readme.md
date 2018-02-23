# Active Directory, SQL Server, and IIS

This template creates four virtual machines:
* Windows Active Directory
* SQL Server
* IIS
* Jumpbox

Each VM has its own subnet, all included in a single virtual network. Creates the template-specified domain on the Windows Active Directory server, and joins the other three servers to the domain. Only the jumpbox VM has RDP access enabled - you can RDP into the other servers from the jumpbox.

The template demonstrates template features, including:
* Using parameter files to define alternate configurations
* Resource replication using copy loops
* DSC extensions for creating and joining the domain


[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fskeeler%2Fazure-templates%2Fmaster%2Fwad-sql-iis-dsc%2Fazuredeploy.json)

[![Visualize](https://camo.githubusercontent.com/536ab4f9bc823c2e0ce72fb610aafda57d8c6c12/687474703a2f2f61726d76697a2e696f2f76697375616c697a65627574746f6e2e706e67)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fskeeler%2Fazure-templates%2Fmaster%2Fwad-sql-iis-dsc%2Fazuredeploy.json)
