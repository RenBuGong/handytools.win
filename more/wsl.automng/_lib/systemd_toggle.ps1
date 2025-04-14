# systemd_toggle.ps1
. $PSScriptRoot\common.ps1   # 如果需要多语言，就先加载

function ToggleSystemdInWSL {
    $distroName = Read-Host (Get-Message "systemd_toggle_EnterDistro")
    if ($distroName -eq 'q') {
        return
    }

    # 显示可选菜单
    Write-Host (Get-Message "systemd_toggle_OptionMenu")
    $choice = Read-Host
    if ($choice -eq 'q') {
        return
    }

    switch ($choice) {
        "1" {
            # 启用 systemd
            Write-Host (Get-Message "systemd_toggle_Enabling" $distroName)
            wsl -d $distroName -- bash -c "./toggle_systemd.sh enable"
        }
        "2" {
            # 禁用 systemd
            Write-Host (Get-Message "systemd_toggle_Disabling" $distroName)
            wsl -d $distroName -- bash -c "./toggle_systemd.sh disable"
        }
        default {
            Write-Host (Get-Message "systemd_toggle_InvalidChoice") -ForegroundColor Yellow
        }
    }
}

ToggleSystemdInWSL
