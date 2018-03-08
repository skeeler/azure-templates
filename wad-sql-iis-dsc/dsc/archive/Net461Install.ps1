Configuration Net461Install
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node "localhost"
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        Script Install_Net_4.6.1
        {
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
