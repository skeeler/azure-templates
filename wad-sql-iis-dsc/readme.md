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
