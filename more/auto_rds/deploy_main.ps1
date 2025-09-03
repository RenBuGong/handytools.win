<#
.SYNOPSIS
    主控部署脚本，用于自动化部署 Active Directory 和 Remote Desktop Services.
.DESCRIPTION
    此脚本是整个部署流程的入口。它会执行以下操作：
    1. 检查是否以管理员权限运行。
    2. 读取 `.env.psd1` 文件中的所有配置。
    3. 将配置中的密码转换为 SecureString 以安全地传递。
    4. 按顺序调用 Step 1 到 Step 4 的部署脚本，并传入所需配置。
.NOTES
    在运行此脚本前，请确保：
    - `.env.psd1` 文件已根据您的环境正确填写。
    - SSL 证书文件已放置在 `.env.psd1` 中指定的路径。
#>
[CmdletBinding()]
param(
    [switch]$ForceFresh
)

# --- 初始化 ---
# 遇到任何错误则停止执行
$ErrorActionPreference = "Stop"

# 启动日志记录
$logFile = Join-Path $PSScriptRoot ("deploy_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
Start-Transcript -Path $logFile -NoClobber | Out-Null

# --- 重启标记处理 ---
$rebootMarkerFile = Join-Path $PSScriptRoot "reboot.marker"
if (Test-Path $rebootMarkerFile) {
    Write-Host "[Deploy] 检测到重启标记，表示系统已按预期重启。继续执行部署..." -ForegroundColor Cyan
    Remove-Item $rebootMarkerFile -Force
}

# --- 状态管理 ---
$lockFilePath = Join-Path $PSScriptRoot "deployment.lock"

function Update-DeploymentState {
    param([string]$State)
    Set-Content -Path $lockFilePath -Value "State: $State"
    Write-Host "[Deploy] 状态更新: $State" -ForegroundColor DarkGray
}

# --- 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "此脚本需要管理员权限运行。请右键单击并选择 '以管理员身份运行'。"
    exit 1
}

# 如果使用 -ForceFresh，则清理旧状态
if ($ForceFresh) {
    Write-Warning "[Deploy] 检测到 -ForceFresh 参数，将忽略现有状态并开始全新部署。"
    if (Test-Path $lockFilePath) {
        Remove-Item $lockFilePath -Force
    }
}

# 在 .NOTES 之后插入函数和调用
function Test-PendingReboot {
    [OutputType([bool])]
    param()
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )
    foreach ($k in $keys) { if (Test-Path $k) { return $true } }
    try {
        $pfr = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction Stop
        if ($pfr) { return $true }
    } catch {}
    return $false
}

if (Test-PendingReboot) {
    Write-Warning "检测到系统存在挂起重启标志 (Windows Update 或 CBS)。请先完成所有更新并重启，然后重新运行 deploy.ps1。脚本将终止。"
    exit 1
}

# --- 读取并解析配置文件 ---
try {
    $envConfig = Get-Content -Path (Join-Path $PSScriptRoot ".env.psd1") -ErrorAction Stop | Out-String | Invoke-Expression
    $config = $envConfig.Deployment
}
catch {
    Write-Error "无法加载或解析 .env.psd1。请确保文件存在且格式正确。"
    Read-Host "按任意键退出..."
    exit 1
}

# --- 检查证书路径 ---
# 新增: 将相对证书路径转换为绝对路径
if (-not ([System.IO.Path]::IsPathRooted($config.SslCertPath))) {
    $resolvedPath = Join-Path $PSScriptRoot $config.SslCertPath
    if (Test-Path $resolvedPath) {
        $config.SslCertPath = (Resolve-Path -Path $resolvedPath).Path
        Write-Host "[Deploy] 检测到相对证书路径，已自动解析为: $($config.SslCertPath)" -ForegroundColor Cyan
    }
    # 如果解析后仍然不存在，后续脚本会在检查文件时自然报错
}

# --- 转换密码为 SecureString ---
$SafeModePwdSecure = ConvertTo-SecureString $config.SafeModePassword -AsPlainText -Force
$SslCertPwdSecure  = ConvertTo-SecureString $config.SslCertPassword -AsPlainText -Force

# --- 配置防火墙规则 ---
if ($envConfig.Firewall) {
    Write-Host "`n▶️ 执行 [防火墙规则配置]..." -ForegroundColor Green
    $firewallConfig = $envConfig.Firewall
    foreach ($rule in $firewallConfig.Rules) {
        $ruleName = "$($firewallConfig.RulePrefix)$($rule.Description)"
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        
        if (-not $existingRule) {
            Write-Host -NoNewline "  正在添加入站规则: '$($ruleName)' (端口 $($rule.Port)/$($rule.Protocol))..."
            New-NetFirewallRule -DisplayName $ruleName `
                -Direction Inbound `
                -Action Allow `
                -Protocol $rule.Protocol `
                -LocalPort $rule.Port `
                -Enabled True | Out-Null
            Write-Host " 成功." -ForegroundColor Green
        } else {
            Write-Host "  防火墙规则 '$($ruleName)' 已存在，跳过。" -ForegroundColor Yellow
        }
    }
}

# --- 执行部署步骤 ---
$lastState = if (Test-Path $lockFilePath) { (Get-Content $lockFilePath) } else { "" }

# --- 步骤 1: AD DS & DNS ---
if ($config.Steps.Step1_AD_DNS -and -not $lastState.Contains("Step1_AD_DNS_Completed")) {
    Update-DeploymentState "Step1_AD_DNS"
    Write-Host "`n▶️ 执行 [步骤 1: 安装 AD DS & DNS]..." -ForegroundColor Green
    # 传递参数
    & (Join-Path $PSScriptRoot "deploy_1_ad.ps1") `
        -DomainName $config.DomainName `
        -DomainNetbios $config.DomainNetbios `
        -SafeModePwd $SafeModePwdSecure `
        -ForceFresh:$ForceFresh.IsPresent
    Update-DeploymentState "Step1_AD_DNS_Completed"
}

# --- 步骤 2: RDS 基础角色 ---
# 注意：步骤1执行后系统会自动重启。您需要手动重新登录并再次运行此 deploy.ps1 脚本。
# 脚本会自动跳过已完成的步骤1，并从步骤2继续。
$adForest = Get-ADForest -ErrorAction SilentlyContinue
if ($adForest -and $adForest.Name -eq $config.DomainName) {
    
    # 直接执行步骤 2。脚本本身具备幂等性，会自动跳过已完成的部分。
    if ($config.Steps.Step2_RDS_Role -and -not $lastState.Contains("Step2_RDS_Role_Completed")) {
        Update-DeploymentState "Step2_RDS_Role"
        Write-Host "`n▶️ 执行 [步骤 2: 配置 RDS 角色与部署]..." -ForegroundColor Green
        & (Join-Path $PSScriptRoot "deploy_2_rds.ps1")
        Update-DeploymentState "Step2_RDS_Role_Completed"
    }
    
    # --- 步骤 3: RDS 授权 ---
    if ($config.Steps.Step3_RDS_License -and -not $lastState.Contains("Step3_RDS_License_Completed")) {
         Write-Host "`n[Deploy] 等待 30 秒，让 RDMS 服务在进入下一步前完全稳定..." -ForegroundColor Cyan
        Start-Sleep -Seconds 30

        Update-DeploymentState "Step3_RDS_License"
        Write-Host "`n▶️ 执行 [步骤 3: 配置 RDS 授权]..." -ForegroundColor Green
        & (Join-Path $PSScriptRoot "deploy_3_license.ps1") `
            -LicenseMode $config.LicenseMode `
            -LicenseKeyPackID $config.LicenseKeyPackID `
            -LicenseCount $config.LicenseCount `
            -CompanyInfo $config.CompanyInfo
        Update-DeploymentState "Step3_RDS_License_Completed"
    }

    # --- 步骤 4: RD Web Client & SSL ---
    if ($config.Steps.Step4_Web_Client -and -not $lastState.Contains("Step4_Web_Client_Completed")) {
        Update-DeploymentState "Step4_Web_Client"
        Write-Host "`n▶️ 执行 [步骤 4: RD Web Client & SSL]..." -ForegroundColor Green
        & (Join-Path $PSScriptRoot "deploy_4_web.ps1") `
            -PublicFqdn $config.PublicFqdn `
            -SslCertPath $config.SslCertPath `
            -SslCertPassword $SslCertPwdSecure
        Update-DeploymentState "Step4_Web_Client_Completed"
    }

    # --- 步骤 5: 配置 WebSocket ---
    if ($config.Steps.Step5_WebSocket -and -not $lastState.Contains("Step5_WebSocket_Completed")) {
        Update-DeploymentState "Step5_WebSocket"
        Write-Host "`n▶️ 执行 [步骤 5: 配置 WebSocket 支持]..." -ForegroundColor Green
        & (Join-Path $PSScriptRoot "deploy_5_websocket.ps1") `
            -SslCertPath $config.SslCertPath `
            -SslCertPassword $SslCertPwdSecure
        Update-DeploymentState "Step5_WebSocket_Completed"
    }

    Write-Host "`n`n✅✅✅ [Deploy] 所有配置步骤已执行完毕。" -ForegroundColor Green
    # 部署成功，删除锁文件
    if (Test-Path $lockFilePath) { Remove-Item $lockFilePath -Force }
    # 同时删除重启标记文件（如果存在）
    if (Test-Path $rebootMarkerFile) { Remove-Item $rebootMarkerFile -Force }
    Write-Host "您的 RD Web 访问地址是: https://$($config.PublicFqdn)/rdweb/webclient/"
    Write-Host "要发布或更新应用程序，请单独运行 'apps_publish.ps1' 脚本。" -ForegroundColor Cyan
    Read-Host "按任意键退出..."

    Stop-Transcript | Out-Null

} else {
    Write-Host "`n⏳ [步骤 1] 要求重启系统。重启后，请以管理员身份重新登录并再次运行此 deploy.ps1 脚本以继续后续步骤。" -ForegroundColor Cyan
}

Read-Host "按 Enter 键退出..." 