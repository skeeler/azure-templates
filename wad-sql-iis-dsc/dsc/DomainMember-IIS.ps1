Configuration DomainMember-IIS
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
        [String]$DNSServer
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

        <# ------------------------------------------------------------------
            The config above is the same as the DomainMember.ps1 DSC script.
            The config below ensures IIS and .NET Framework 4.6.1 are present.
        #>

        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
            DependsOn = "[xComputer]DomainJoin"
        }

        Script Install_Net_4.6.1
        {
            DependsOn = "[WindowsFeature]IIS"

            SetScript = {
                $SourceURI = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49981"
                $FileName = $SourceURI.Split('/')[-1]
                $BinPath = Join-Path $env:SystemRoot -ChildPath "Temp\$FileName"

                if (!(Test-Path $BinPath))
                {
                    Invoke-Webrequest -Uri $SourceURI -OutFile $BinPath
                }

                write-verbose "Installing .Net 4.6.1 from $BinPath"
                write-verbose "Executing $binpath /q /norestart"
                Sleep 5
                Start-Process -FilePath $BinPath -ArgumentList "/q /norestart" -Wait -NoNewWindow            
                Sleep 5
                Write-Verbose "Setting DSCMachineStatus to reboot server after DSC run is completed"
                $global:DSCMachineStatus = 1
            }

            TestScript = {
                [int]$NetBuildVersion = 394271

                if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | %{$_ -match 'Release'})
                {
                    [int]$CurrentRelease = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
                    if ($CurrentRelease -lt $NetBuildVersion)
                    {
                        Write-Verbose "Current .Net build version is less than 4.6.1 ($CurrentRelease)"
                        return $false
                    }
                    else
                    {
                        Write-Verbose "Current .Net build version is the same as or higher than 4.6.1 ($CurrentRelease)"
                        return $true
                    }
                }
                else
                {
                    Write-Verbose ".Net build version not recognised"
                    return $false
                }
            }

            GetScript = {
                if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | %{$_ -match 'Release'})
                {
                    $NetBuildVersion =  (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
                    return $NetBuildVersion
                }
                else
                {
                    Write-Verbose ".Net build version not recognised"
                    return ".Net 4.6.1 not found"
                }
            }
        }
    }
} 