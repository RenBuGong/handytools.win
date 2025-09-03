#=== 步骤 2：安装 RDS 四大基础角色 与 部署 ===

# 遇到任何错误则停止执行
$ErrorActionPreference = "Stop"

# ===================================================================
# Helper functions (defined at the top to be globally available in this script)
# ===================================================================
function Ensure-WID {
    param()
    Write-Host "[Step2] 正在确认 Windows Internal Database (WID) 功能..."
    $widFeature = Get-WindowsFeature -Name Windows-Internal-Database -ErrorAction SilentlyContinue
    if ($widFeature -and -not $widFeature.Installed) {
        Write-Host "[Step2]   正在安装 WID 功能..."
        Install-WindowsFeature -Name Windows-Internal-Database -IncludeManagementTools -ErrorAction Stop | Out-Null
        Write-Host "[Step2]   WID 功能安装完成。需要重启后才能启动服务。服务器将在 10 秒后自动重启..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
        exit 0 # Exit script, will be rerun after reboot
    }
    $widService = Get-Service -Name 'MSSQL$MICROSOFT##WID' -ErrorAction SilentlyContinue
    if ($widService -and $widService.Status -ne 'Running') {
        Write-Host "[Step2]   正在启动 WID 服务..."
        Start-Service $widService.Name
        try {
            $widService.WaitForStatus('Running',(New-TimeSpan -Seconds 30))
        } catch {
             Write-Warning "等待 WID 服务启动超时。脚本将继续，但后续步骤可能失败。"
        }
    }
    Write-Host "[Step2]   WID 功能与服务已就绪。" -ForegroundColor Green
}

function Test-FQDNConsistency {
    param([string]$Fqdn)
    Write-Host "[Step2] 正在检查 FQDN 解析: $Fqdn ..."
    try {
        Resolve-DnsName -Name $Fqdn -ErrorAction Stop | Out-Null
        Write-Host "[Step2]   DNS 已能解析 $Fqdn 。" -ForegroundColor Green
    }
    catch {
        Write-Warning "[Step2]   DNS 无法解析 $Fqdn ，将写入 hosts 文件进行本地解析。"
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        $hostsLine  = "127.0.0.1`t$Fqdn"
        if (-not (Get-Content $hostsPath | Select-String -SimpleMatch $Fqdn)) {
            Add-Content -Path $hostsPath -Value $hostsLine
            Write-Host "[Step2]   已写入 hosts 条目: $hostsLine" -ForegroundColor Yellow
        }
    }
}

function Cleanup-ResidualDeployment {
    param([string]$Fqdn)
    try {
        if (Get-RDDeployment -ConnectionBroker $Fqdn -ErrorAction SilentlyContinue) {
            Write-Warning "[Step2]   检测到残留 RDS 部署，正在强制删除..."
            Remove-RDSessionDeployment -ConnectionBroker $Fqdn -Force -ErrorAction Stop
            Write-Host "[Step2]   残留部署已清理。" -ForegroundColor Green
        }
    }
    catch { } # If no deployment, it throws an error, which is fine.
}

function Wait-ForRDSEnvironment {
    param([string]$ConnectionBroker, [int]$TimeoutSeconds = 300)
    
    Write-Host "`n[Step2] 正在等待 RDS 管理环境就绪 (最长 $($TimeoutSeconds) 秒)..."
    Import-Module RemoteDesktop -ErrorAction SilentlyContinue
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            # 尝试一个轻量级的只读命令来探测环境
            Get-RDServer -ConnectionBroker $ConnectionBroker -ErrorAction Stop | Out-Null
            $stopwatch.Stop()
            Write-Host "✅ [Step2] RDS 环境已就绪。" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host -NoNewline "."
            Start-Sleep -Seconds 10
        }
    }
    
    $stopwatch.Stop()
    Write-Error "`n[Step2] 等待 RDS 环境就绪超时。请检查 'Remote Desktop Management (rdms)' 服务是否正在运行。"
    return $false
}

function Verify-And-Repair-RDMS {
    param([string]$RebootMarkerFile, [int]$TimeoutSeconds = 120)

    Write-Host "[Step2] 正在验证 RDMS WMI 提供程序..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $namespaceExists = $false
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            # 使用一个轻量级的查询来验证命名空间是否存在
            Get-CimInstance -Namespace "root\cimv2\rdms" -ClassName "__Namespace" -ErrorAction Stop | Out-Null
            $namespaceExists = $true
            break
        } catch {
            Write-Host -NoNewline "."
            Start-Sleep -Seconds 10
        }
    }
    $stopwatch.Stop()

    if ($namespaceExists) {
        Write-Host "`n✅ [Step2] RDMS WMI 提供程序已成功加载。" -ForegroundColor Green
        return
    }

    # 如果 WMI 持续不可用，则启动修复流程
    Write-Warning "`n[Step2] RDMS WMI 提供程序在超时后仍未加载，表明角色安装可能已损坏。"
    Write-Warning "[Step2] 正在尝试自动修复：卸载并重新安装 RDS 核心角色..."

    $rolesToRepair = @("RDS-Connection-Broker", "RDS-RD-Server")
    
    Write-Host "[Step2]   正在卸载: $($rolesToRepair -join ', ')"
    Uninstall-WindowsFeature -Name $rolesToRepair -ErrorAction SilentlyContinue | Out-Null

    # 短暂等待以确保卸载完成
    Start-Sleep -Seconds 15

    Write-Host "[Step2]   正在重新安装: $($rolesToRepair -join ', ')"
    Install-WindowsFeature -Name $rolesToRepair -IncludeManagementTools -ErrorAction Stop | Out-Null

    Write-Host "[Step2] 修复操作完成。需要重启来使更改完全生效。将在 10 秒后自动重启..." -ForegroundColor Green
    Set-Content -Path $RebootMarkerFile -Value (Get-Date)
    Start-Sleep -Seconds 10
    Restart-Computer -Force
    exit 0
}

# ===================================================================
# Main Script Logic
# ===================================================================

# --- 定义重启标记文件路径 ---
$rebootMarkerFile = Join-Path $PSScriptRoot "reboot.marker"

# --- 检查并处理挂起的重启 ---
$rebootPending = $false
$pendingKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
)
foreach ($k in $pendingKeys) {
    if (Test-Path $k) { $pendingReboot = $true; Write-Warning "[Step2] 检测到挂起重启标志: $k" }
}
try {
    $pfr = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction Stop
    if ($pfr) { $pendingReboot = $true; Write-Warning "[Step2] 检测到挂起文件重命名操作 (PendingFileRenameOperations)" }
} catch {}

if ($pendingReboot) {
    Write-Host "[Step2] 系统存在挂起重启项。将在 10 秒后自动重启以完成系统配置..." -ForegroundColor Green
    Set-Content -Path $rebootMarkerFile -Value (Get-Date)
    Start-Sleep -Seconds 10
    Restart-Computer -Force
    exit 0
}

# --- 安装 RDS 基础角色 (幂等) ---
Write-Host "`n[Step2] 正在安装 RDS 基础角色 (Broker/SessionHost/Licensing/WebAccess)..."
$res = Install-WindowsFeature `
  RDS-Connection-Broker, `
  RDS-RD-Server, `
  RDS-Licensing, `
  RDS-Web-Access `
  -IncludeManagementTools
Write-Host "`n✅ [Step2] RDS 基础角色安装完成。" -ForegroundColor Green

# --- 如果安装后需要重启，则立即重启 ---
$pendingAfterInstall = $false
foreach ($k in $pendingKeys) { if (Test-Path $k) { $pendingAfterInstall = $true } }
try {
    $pfr = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction Stop
    if ($pfr) { $pendingAfterInstall = $true }
} catch {}

if ($res.RestartNeeded -and $pendingAfterInstall) {
    Write-Host "`n[Step2] 角色安装完成，需要重启以应用更改。将在 10 秒后自动重启..." -ForegroundColor Green
    Set-Content -Path $rebootMarkerFile -Value (Get-Date)
    Start-Sleep -Seconds 10
    Restart-Computer -Force
    exit 0
}

# --- 确保核心 RDS 服务正在运行 ---
$requiredServices = @("tssdis", "rdms", "tscpubrpc")
Write-Host "[Step2] 正在检查并启动核心 RDS 服务..." -ForegroundColor Yellow
foreach ($serviceName in $requiredServices) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.StartType -ne "Automatic") {
            Set-Service -Name $serviceName -StartupType Automatic
        }
        if ($service.Status -ne "Running") {
            Start-Service -Name $serviceName
            $service.WaitForStatus("Running", (New-TimeSpan -Seconds 30))
        }
    }
    catch {
        Write-Warning "[Step2] 处理服务 '$serviceName' 时出错: $($_.Exception.Message)。"
    }
}
Write-Host "✅ [Step2] 核心 RDS 服务检查完毕。" -ForegroundColor Green

# --- 给服务一点稳定时间 ---
# Write-Host "[Step2] 等待 15 秒让服务完全初始化..." -ForegroundColor Cyan
# Start-Sleep -Seconds 15

# --- 创建 RDS 部署 ---
Import-Module RemoteDesktop
$fqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN"

# --- 调用辅助检查 ---
Write-Host "`n[Step2] 执行部署前置检查..." -ForegroundColor Cyan
Verify-And-Repair-RDMS -RebootMarkerFile $rebootMarkerFile
Test-FQDNConsistency -Fqdn $fqdn
Ensure-WID
# Cleanup-ResidualDeployment -Fqdn $fqdn # 清理逻辑应在环境就绪后
Write-Host "✅ [Step2] 前置检查完成。" -ForegroundColor Green

# --- 等待并验证 RDS 环境 ---
if (-not (Wait-ForRDSEnvironment -ConnectionBroker $fqdn)) {
    exit 1
}

# --- 尝试获取/创建部署 ---
try {
    # 在清理和创建之前，再次检查，因为Wait-ForRDSEnvironment可能已经花了一些时间
    Cleanup-ResidualDeployment -Fqdn $fqdn
    
    Get-RDDeployment -ConnectionBroker $fqdn -ErrorAction Stop
    Write-Host "[Step2] 检测到已有 RDS 部署，跳过创建。" -ForegroundColor Green
}
catch {
    Write-Host "[Step2] 未检测到有效的 RDS 部署，正在创建..." -ForegroundColor Yellow
    try {
        New-RDSessionDeployment -ConnectionBroker $fqdn -WebAccessServer $fqdn -SessionHost $fqdn -ErrorAction Stop
        
        # 验证循环
        Write-Host "[Step2] 部署命令已发送，正在验证状态..."
        $deploymentReady = $false
        for ($i=1; $i -le 60; $i++) {
            Write-Host "[Step2]   验证尝试 $i/60..."
            try {
                Get-RDDeployment -ConnectionBroker $fqdn -ErrorAction Stop | Out-Null
                $deploymentReady = $true
                Write-Host "✅ [Step2] RDS 部署已成功创建并验证。" -ForegroundColor Green
                break
            }
            catch { Start-Sleep -Seconds 5 }
        }

        if (-not $deploymentReady) {
            throw "无法在超时时间内验证 RDS 部署。请检查事件查看器中的 'Microsoft-Windows-RemoteDesktopServices-RDMS/Admin' 日志获取详细信息。"
        }
    }
    catch {
        if (($_.Exception.Message -like '*session-based desktop deployment is already present*') -or ($_.Exception.Message -like '*基于会话的桌面部署已存在*')) {
            Write-Host "[Step2] 检测到系统已存在会话部署，视为成功，继续后续步骤。" -ForegroundColor Green
        }
        else {
            Write-Error "[Step2] 创建或验证 RDS 部署时发生严重错误: $($_.Exception.Message)"
            exit 1
        }
    }
}

# --- 创建默认会话集合 ---
try {
    $existingCollection = Get-RDSessionCollection -ConnectionBroker $fqdn -ErrorAction SilentlyContinue
    if ($existingCollection.CollectionName -contains "QuickSessionCollection") {
        Write-Host "[Step2] 已检测到 'QuickSessionCollection'，跳过创建。" -ForegroundColor Green
    }
    else {
        Write-Host "[Step2] 正在创建默认会话集合 'QuickSessionCollection'..." -ForegroundColor Yellow
        New-RDSessionCollection -CollectionName "QuickSessionCollection" -SessionHost $fqdn -CollectionDescription "默认会话集合" -ConnectionBroker $fqdn
        Write-Host "✅ [Step2] 会话集合创建成功。" -ForegroundColor Green
        
        # --- 设置备用完整地址以解决 Web 客户端连接问题 ---
        $envCfg = Get-Content -Path (Join-Path $PSScriptRoot ".env.psd1") | Out-String | Invoke-Expression
        $web_domain = $envCfg.Deployment.PublicFqdn
        if ($web_domain) {
            Write-Host "[Step2] 正在为 QuickSessionCollection 设置备用完整地址: $web_domain ..." -ForegroundColor Yellow
            Set-RDSessionCollectionConfiguration -CollectionName "QuickSessionCollection" -CustomRdpProperty "alternate full address:s:$web_domain" -ConnectionBroker $fqdn
            Write-Host "✅ [Step2] 备用完整地址设置成功。" -ForegroundColor Green
        }
    }
}
catch {
    Write-Warning "[Step2] 无法创建或检测会话集合：$($_.Exception.Message)"
}

Write-Host "`n[Step2] 角色及部署配置完成，继续执行 win_step3_license.ps1" 