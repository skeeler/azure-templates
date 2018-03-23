Configuration DomainMember-MGT
{
   param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=60,

        [Parameter(Mandatory)]
        [String]$DNSServer,

        [Parameter(Mandatory)]
        [Bool]$ChangePasswordAtNextLogon=$false,

        [Parameter(Mandatory)]
        [String]$RDPUserAuthentication="Secure"
    )

    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xNetworking

    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)
    $shortDomainName = $DomainName -split '\.' | Select-Object -First 1
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${shortDomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        xDnsServerAddress DnsServerAddress
        {
            Address        = $DNSServer
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
        }
        
        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn="[xDnsServerAddress]DnsServerAddress"
        }

        xComputer DomainJoin
        {
            Name = 'localhost'
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait" 
        }

        xRemoteDesktopAdmin EnableRDP
        {
            Ensure = "Present"
            UserAuthentication = $RDPUserAuthentication
            DependsOn = "[xComputer]DomainJoin" 
        }

        Script ChangePasswordAtNextLogon
	    {
      	    SetScript = {
                Add-WindowsFeature -Name "RSAT-AD-PowerShell" 
                Get-ADUser -Identity $using:Admincreds.UserName | Set-ADUser -Credential $using:DomainCreds -ChangePasswordAtLogon $true
                Write-Verbose -Verbose "Configured admin account to force password change at next login" 
            }

            GetScript =  { @{} }

            TestScript = {
                if ($using:ChangePasswordAtNextLogon)
                {
                    Write-Verbose -Verbose "Checking Network Level Authentication (NLA) setting before configuring admin account to force password change at next login..."
                    if ($using:RDPUserAuthentication -eq "NonSecure")
                    {
                        Write-Verbose "NLA is disabled, so we are safe to set ChangePasswordAtNextLogon as requested"
                        return $false
                    }
                    else
                    {
                        Write-Warning "NLA is enabled, so we will skip setting ChangePasswordAtNextLogon although it was requested"
                        return $true
                    }
                }
                else
                {
                    Write-Verbose "Skipping ChangePasswordAtNextLogon as requested"
                    return $true    
                }
            }

            DependsOn = "[xRemoteDesktopAdmin]EnableRDP"
        }
    }
} 

        [String]$DNSServer,

        [Parameter()]
        [Bool]$ChangePasswordAtNextLogon=$false,

        [Parameter()]
        [String]$RDPUserAuthentication="Secure"
    )

    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xNetworking

    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)
    $shortDomainName = $DomainName -split '\.' | Select-Object -First 1
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${shortDomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        xDnsServerAddress DnsServerAddress
        {
            Address        = $DNSServer
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
        }
        
        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn="[xDnsServerAddress]DnsServerAddress"
        }

        xComputer DomainJoin
        {
            Name = 'localhost'
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait" 
        }

        xRemoteDesktopAdmin EnableRDP
        {
            Ensure = "Present"
            UserAuthentication = $RDPUserAuthentication
            DependsOn = "[xComputer]DomainJoin" 
        }

        Script ChangePasswordAtNextLogon
	    {
      	    SetScript = {
                Add-WindowsFeature -Name "RSAT-AD-PowerShell" 
                Get-ADUser -Identity $using:Admincreds.UserName | Set-ADUser -Credential $using:DomainCreds -ChangePasswordAtLogon $true
                Write-Verbose -Verbose "Configured admin account to force password change at next login" 
            }

            GetScript =  { @{} }

            TestScript = {
                if ($using:ChangePasswordAtNextLogon)
                {
                    Write-Verbose -Verbose "Checking Network Level Authentication (NLA) setting before configuring admin account to force password change at next login..."
                    if ($using:RDPUserAuthentication -eq "NonSecure")
                    {
                        Write-Verbose "NLA is disabled, so we are safe to set ChangePasswordAtNextLogon as requested"
                        return $false
                    }
                    else
                    {
                        Write-Warning "NLA is enabled, so we will skip setting ChangePasswordAtNextLogon although it was requested"
                        return $true
                    }
                }
                else
                {
                    Write-Verbose "Skipping ChangePasswordAtNextLogon as requested"
                    return $true    
                }
            }

            DependsOn = "[xRemoteDesktopAdmin]EnableRDP"
        }
    }
} 
