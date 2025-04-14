# backup.ps1

. $PSScriptRoot\common.ps1  # 一定要先加载，才能用 Get-Message

function Export-WslToBackup {
    # 读取要导出的实例
    $distroToExport = Read-Host (Get-Message "backup_ExportWslPrompt" $scriptConfig.sys_image_lib_dir)
    if ($distroToExport -eq 'q') {
        return
    }

    $exportPath = Join-Path $scriptConfig.sys_image_lib_dir ("Backup_{0}{1}.tar" -f $distroToExport, (Get-Date -Format 'yyyyMMddHHmmss'))

    Write-Host (Get-Message "backup_ExportWslStarting" @($distroToExport, $exportPath))
    try {
        wsl --export $distroToExport $exportPath
        # Write-Host (Get-Message "backup_ExportWslCompleted" $exportPath) -ForegroundColor Green
    }
    catch {
        Write-Host (Get-Message "backup_ExportWslFailed" $_) -ForegroundColor Red
        throw
    }
}

Export-WslToBackup
