#Requires -RunAsAdministrator
[CmdletBinding()]
param()

# 该脚本必须以管理员权限运行，以确保所有文件都能被正确下载和保存。

Write-Host "`n此脚本需要以管理员方式运行, 并使用最新版本 powershell (可在应用商店中安装)...`n"

$ErrorActionPreference = "Stop"
$cacheDir = Join-Path $PSScriptRoot "PkgCache"
$tempCacheDir = Join-Path $PSScriptRoot "PkgCache_new"

# --- 1. 环境准备与引导 ---
function Prepare-PowerShellGet {
    Write-Host "▶️ 正在检查并准备 PowerShellGet 环境..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Get-PSRepository -Name PSGallery -ErrorAction Stop | Out-Null
        Write-Host "✅ PowerShellGet 环境已就绪。"
        return
    } catch {
        Write-Warning "PowerShellGet 需要更新。正在尝试自动更新..."
    }
    Install-Module -Name PowerShellGet -Force -SkipPublisherCheck -AllowClobber
    throw "我们已经为您更新了核心的 PowerShellGet 模块。这是一个必要的一次性准备步骤。`n请关闭当前的 PowerShell 窗口，以管理员身份重新打开一个新的窗口，然后再次运行本脚本 '.\New-OfflineCache.ps1'。"
}

# --- 2. 主逻辑 ---
try {
    # 检查 PowerShellGet 环境
    Prepare-PowerShellGet

    # 清理并创建临时缓存目录
    if (Test-Path $tempCacheDir) {
        Remove-Item -Path $tempCacheDir -Recurse -Force
    }
    New-Item -Path $tempCacheDir -ItemType Directory | Out-Null
    Write-Host "`n▶️ 已在 '$tempCacheDir' 创建临时缓存目录。"

    # 下载 RDWebClientManagement 模块
    Write-Host "正在下载 'RDWebClientManagement' 模块..."
    Save-Module -Name RDWebClientManagement -Path $tempCacheDir -AcceptLicense -Force

    # 临时导入模块以下载程序包
    Write-Host "正在导入已下载的模块以使用其命令..."
    $modulePath = Get-ChildItem -Path (Join-Path $tempCacheDir "RDWebClientManagement") -Directory | Select-Object -First 1
    Import-Module -Name (Join-Path $modulePath.FullName "*.psd1") -Force

    # 下载 RD Web Client 程序包
    Write-Host "正在下载 RD Web Client 程序包..."
    Save-RDWebClientPackage -Path $tempCacheDir

    Write-Host "✅ 所有文件已成功下载到 '$tempCacheDir'。"

    # --- 卸载模块以解锁目录 ---
    Write-Host "正在卸载 'RDWebClientManagement' 模块以解锁目录..."
    Remove-Module -Name RDWebClientManagement -Force

    # --- 3. 验证文件完整性 ---
    $zipFile = Get-ChildItem -Path $tempCacheDir -Filter "rdwebclient-*.zip"
    if (-not $zipFile) {
        throw "致命错误：未能下载 Web Client 的 .zip 包。请检查网络连接或代理设置后重试。"
    }

    # --- 4. 替换旧缓存 ---
    Write-Host "`n▶️ 正在替换旧的 PkgCache..."
    if (Test-Path $cacheDir) {
        Write-Host "正在删除旧的 PkgCache..."
        Remove-Item -Path $cacheDir -Recurse -Force
    }
    Write-Host "正在复制 '$tempCacheDir' 到 '$cacheDir'..."
    New-Item -Path $cacheDir -ItemType Directory | Out-Null
    Copy-Item -Path (Join-Path $tempCacheDir '*') -Destination $cacheDir -Recurse -Force

    Write-Host "正在删除临时目录 '$tempCacheDir'..."
    Remove-Item -Path $tempCacheDir -Recurse -Force

    Write-Host "`n🎉🎉🎉 离线缓存包制作/更新成功！现在可以将 'PkgCache' 目录复制到目标服务器进行部署了。 🎉🎉🎉" -ForegroundColor Green

} catch {
    Write-Error $_.Exception.Message
    exit 1
} 