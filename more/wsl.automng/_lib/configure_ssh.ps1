# configure_ssh.ps1
. $PSScriptRoot\common.ps1  # 多语言加载

function ConfigureSshService {
    # 1. 读取要配置的实例
    $distroName = Read-Host (Get-Message "configure_ssh_EnterDistro")
    if ($distroName -eq 'q') {
        return
    }

    # 2. 显示操作菜单
    Write-Host (Get-Message "configure_ssh_OptionMenu")
    $choice = Read-Host
    if ($choice -eq 'q') {
        return
    }

    switch ($choice) {
        "1" {
            # 启动/启用 SSH
            $port = Read-Host (Get-Message "configure_ssh_EnterPort")
            if (-not $port) { $port = 22 }

            Write-Host (Get-Message "configure_ssh_Configuring" @($distroName, $port))
            try {
                # 这里假设你的脚本 configure_ssh.sh 的第一参数是 port
                # 例如: ./configure_ssh.sh start 22022
                wsl -d $distroName -- bash -c "./configure_ssh.sh start $port $currentCulture"
                Write-Host (Get-Message "configure_ssh_StartingOK") -ForegroundColor Green
            }
            catch {
                Write-Host (Get-Message "configure_ssh_Failed" $_) -ForegroundColor Red
            }
        }
        "2" {
            # 停止/关闭 SSH
            Write-Host (Get-Message "configure_ssh_Configuring" @($distroName, "stop"))
            try {
                # 比如: ./configure_ssh.sh stop
                wsl -d $distroName -- bash -c "./configure_ssh.sh stop $currentCulture"
                Write-Host (Get-Message "configure_ssh_StoppingOK") -ForegroundColor Green
            }
            catch {
                Write-Host (Get-Message "configure_ssh_Failed" $_) -ForegroundColor Red
            }
        }
        default {
            Write-Host (Get-Message "configure_ssh_InvalidOpt") -ForegroundColor Yellow
        }
    }
}

ConfigureSshService
