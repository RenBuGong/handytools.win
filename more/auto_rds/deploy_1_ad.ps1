#=== 步骤 1：安装 AD DS + DNS 并提升为域控 ===
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName,

    [Parameter(Mandatory=$true)]
    [string]$DomainNetbios,

    [Parameter(Mandatory=$true)]
    [SecureString]$SafeModePwd,

    [Parameter(Mandatory=$false)]
    [switch]$ForceFresh
)

# 遇到任何错误则停止执行
$ErrorActionPreference = "Stop"

# 检查AD DS角色是否已经安装
$adFeature = Get-WindowsFeature AD-Domain-Services -ErrorAction SilentlyContinue
if ($adFeature -and $adFeature.Installed) {
    Write-Host "✅ [步骤 1] AD DS 角色已安装，跳过安装过程。" -ForegroundColor Green
    if ($ForceFresh) {
        Write-Warning "`n❗️ [步骤 1] 在 -ForceFresh 模式下检测到已存在的 AD 角色，将强制重启以确保环境一致性。请在重启后重新运行脚本。"
        Restart-Computer -Force
    }
    return
}

Write-Host "`n[Step1] 正在安装 AD DS / DNS 功能..."
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

Write-Host "[Step1] 正在提升为新森林域控制器 (此过程需要一些时间)..."
Import-Module ADDSDeployment
Install-ADDSForest `
  -DomainName $DomainName `
  -DomainNetbiosName $DomainNetbios `
  -SafeModeAdministratorPassword $SafeModePwd `
  -InstallDNS -Force -NoRebootOnCompletion

Write-Host "`n✅ [步骤 1] 配置完成。" -ForegroundColor Green
Write-Host "`n❗️ **系统需要重启以完成域控制器提升。脚本将在重启后由主控脚本继续执行。**" -ForegroundColor Yellow
Restart-Computer -Force 