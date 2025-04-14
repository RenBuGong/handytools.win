# remove.ps1

. $PSScriptRoot\common.ps1  # 先加载

function Remove-Instance {
    # 读取要删除的实例名称
    $prompt = Get-Message "delete_EnterInstanceName"
    $instanceName = Read-Host $prompt
    if ($instanceName -eq 'q') {
        return
    }

    if ($instanceName) {
        # 检查是否正在运行
        $wslStatus = wsl --list --verbose | Select-Object -Skip 1 | Where-Object { $_ -match $instanceName }
        if ($wslStatus -and $wslStatus -match 'Running') {
            Write-Host (Get-Message "delete_InstRunning" $instanceName) -ForegroundColor Red
            return
        }

        # 确认删除
        $confirmPrompt = (Get-Message "delete_ConfirmDelete" $instanceName)
        $confirmation = Read-Host $confirmPrompt
        if ($confirmation -eq 'Y') {
            wsl --unregister $instanceName
            Write-Host (Get-Message "delete_Deleted" $instanceName) -ForegroundColor Green
        }
        else {
            Write-Host (Get-Message "delete_Cancelled") -ForegroundColor Yellow
        }
    }
    else {
        Write-Host (Get-Message "delete_NoInstName") -ForegroundColor Red
    }
}

Remove-Instance
