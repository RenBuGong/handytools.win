# show_help.ps1

# 确保先加载公共脚本
. $PSScriptRoot\common.ps1

function Show-Wsl2Help {
    Write-Host (Get-Message "help_Title") -ForegroundColor Cyan
    Write-Host (Get-Message "help_CommonCommands")
    Write-Host (Get-Message "help_cmd_wsl_l_v")
    Write-Host (Get-Message "help_cmd_wsl_d")
    Write-Host (Get-Message "help_cmd_wsl_shutdown")
    Write-Host (Get-Message "help_cmd_wsl_unreg")
    Write-Host (Get-Message "help_cmd_wsl_setdef")
    Write-Host (Get-Message "help_cmd_wsl_status")
    Write-Host (Get-Message "help_cmd_wsl_update")
    Write-Host ""
    Write-Host (Get-Message "help_PortForwardTitle")
    Write-Host (Get-Message "help_PortForwardCmd")
    Write-Host (Get-Message "help_PortForwardExample")
    Write-Host ""

    Write-Host (Get-Message "help_FirewalldTitle")
    Write-Host (Get-Message "help_FirewalldCmd")
    Write-Host (Get-Message "help_FirewalldExample")
    Write-Host (Get-Message "help_MoreInfo")  -ForegroundColor Green
}

Show-Wsl2Help
