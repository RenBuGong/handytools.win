# autostart.ps1
. $PSScriptRoot\common.ps1  # 确保加载多语言支持

function Set-WslAutoRunAtLogin {
    # 使用多语言提示
    $distroName = Read-Host (Get-Message "autostart_PromptDistro")
    if ($distroName -eq 'q') {
        return
    }

    # 假设模板文件名是 wsl_startup_ubuntu.vbs，位于脚本目录或固定位置
    $templatePath = Join-Path $PSScriptRoot "wsl_startup_ubuntu.vbs"
    if (-not (Test-Path $templatePath)) {
        Write-Host (Get-Message "autostart_TemplateMissing" $templatePath) -ForegroundColor Red
        return
    }

    # 读取模板
    $vbsContent = Get-Content $templatePath -Raw
    # 替换占位符 "ubuntu" 为目标实例名
    $vbsContent = $vbsContent -replace "ubuntu", $distroName

    # 拼接目标启动文件路径
    $startupDir = Join-Path $env:UserProfile "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    if (-not (Test-Path $startupDir)) {
        Write-Host (Get-Message "autostart_StartupMissing") -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $startupDir | Out-Null
    }

    $destVbsPath = Join-Path $startupDir ("wsl_startup_{0}.vbs" -f $distroName)

    # 写入新文件
    Set-Content -Path $destVbsPath -Value $vbsContent -Force

    Write-Host (Get-Message "autostart_CreatedScript" $destVbsPath) -ForegroundColor Green
    Write-Host (Get-Message "autostart_Success" $distroName)
}

Set-WslAutoRunAtLogin

