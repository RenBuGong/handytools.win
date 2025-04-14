# show.ps1
param(
    [int]$NameWidth = 15,
    [int]$StateWidth = 8,
    [int]$VersionWidth = 8,
    [int]$BasePathWidth = 35
)


. $PSScriptRoot\common.ps1  # 先加载



# 如果你想在脚本启动时显示一条多语言的可选参数信息：
# Write-Host (Get-Message "showinfo_OptionalParams" @($NameWidth, $StateWidth, $VersionWidth, $BasePathWidth)) -ForegroundColor Cyan

function Get-InstalledDistributions {
    Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss\*" |
        Select-Object @{Name='DistributionName';Expression={$_.DistributionName}}, 
                      @{Name='BasePath';Expression={$_.BasePath}}
}

function Get-WSLStatus {
    $wslOutput = wsl --list --verbose
    $wslStatus = $wslOutput | Select-Object -Skip 1 | Where-Object { $_.Trim() -ne '' } | ForEach-Object {
        $cleanedLine = $_ -replace '[^\x20-\x7E]', '' -replace '\s{2,}', ' '
        $line = $cleanedLine -split '\s+', 4 | Where-Object { $_ -ne '' }

        [PSCustomObject]@{
            Default = $line[0] -eq '*'
            Name    = if ($line[0] -eq '*') { $line[1] } else { $line[0] }
            State   = if ($line[0] -eq '*') { $line[2] } else { $line[1] }
            Version = if ($line[0] -eq '*') { $line[3] } else { $line[2] }
        }
    }
    return $wslStatus
}

function Show-CombinedWSLInfo {
    Write-Host (Get-Message "showinfo_Heading") -ForegroundColor Green

    $installedDistros = Get-InstalledDistributions
    $wslStatus        = Get-WSLStatus

    $combinedInfo = $wslStatus | ForEach-Object {
        $status     = $_
        $distroInfo = $installedDistros | Where-Object { $_.DistributionName -eq $status.Name }

        [PSCustomObject]@{
            Default  = if ($status.Default) { "*" } else { "" }
            Name     = $status.Name
            State    = $status.State
            Version  = $status.Version
            BasePath = if ($distroInfo) { $distroInfo.BasePath } else { (Get-Message "showinfo_NotAvailable") }
        }
    }

    # 输出合并后的信息
    $combinedInfo | Format-Table -AutoSize -Property Default,
        @{Label="Name";     Expression={"{0,-$NameWidth}" -f $_.Name};     Alignment="Left"},
        @{Label="State";    Expression={"{0,-$StateWidth}" -f $_.State};   Alignment="Left"},
        @{Label="Version";  Expression={"{0,-$VersionWidth}" -f $_.Version}; Alignment="Left"},
        @{Label="BasePath"; Expression={"{0,-$BasePathWidth}" -f $_.BasePath}; Alignment="Left"}
}

Show-CombinedWSLInfo
