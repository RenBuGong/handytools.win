#=== 步骤 3：配置并激活许可服务器 ===
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("PerUser","PerDevice")]
    [string]$LicenseMode,

    [Parameter(Mandatory=$true)]
    [string]$LicenseKeyPackID,

    [Parameter(Mandatory=$true)]
    [int]$LicenseCount,

    [Parameter(Mandatory=$true)]
    [hashtable]$CompanyInfo
)

# 遇到任何错误则停止执行
$ErrorActionPreference = "Stop"

function Wait-ForRDMS_WMI {
    param([int]$TimeoutSeconds = 240)
    Write-Host "[Step3] 正在等待 RDS WMI 接口就绪 (最长 $($TimeoutSeconds) 秒)..."
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # 确保 RD Licensing 服务正在运行
    $licSvc = Get-Service -Name "TermServLicensing" -ErrorAction SilentlyContinue
    if ($licSvc -and $licSvc.Status -ne 'Running') {
        Write-Host "[Step3]   检测到 'TermServLicensing' 服务未运行，正在尝试启动..." -NoNewline
        try {
            Start-Service -Name $licSvc.Name
            $licSvc.WaitForStatus('Running',(New-TimeSpan -Seconds 20))
            Write-Host " 成功。" -ForegroundColor Green
        } catch {
            Write-Host " 失败。" -ForegroundColor Yellow
        }
    }

    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        foreach ($ns in @("root\CIMV2", "root\CIMV2\TerminalServices")) {
            try {
                $instance = Get-CimInstance -Namespace $ns -ClassName "Win32_TSLicenseServer" -ErrorAction Stop
                Write-Host "`n✅ [Step3] RDS WMI 接口在命名空间 '$ns' 中已就绪。" -ForegroundColor Green
                return $instance
            } catch {
                # Continue searching
            }
        }
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 5
    }

    $stopwatch.Stop()
    Write-Error "`n[Step3] 等待 RDS WMI 接口超时。请确认 'TermServLicensing' 服务已启动，且 WMI 中存在 Win32_TSLicenseServer 类。"
    return $null
}

function Add-ComputerToLicenseServerGroup {
    param([string]$DomainName)
    try {
        $groupName = "Terminal Server License Servers"
        $group = Get-ADGroup -Filter "Name -eq '$groupName'"
        $computer = Get-ADComputer -Identity $env:COMPUTERNAME
        
        Write-Host "[Step3] 尝试将计算机 '$($env:COMPUTERNAME)' 添加到 '$groupName' 组..."
        Add-ADGroupMember -Identity $group -Members $computer
        Write-Host "✅ [Step3] 已成功将计算机添加到组。" -ForegroundColor Green
    }
    catch {
        if ($_.Exception.Message -like "*already a member*") {
            Write-Host "✅ [Step3] 计算机已在 '$groupName' 组中，无需操作。" -ForegroundColor Green
        }
        else {
            Write-Warning "[Step3] 无法自动将计算机添加到 '$groupName' 组: $($_.Exception.Message)"
            Write-Warning "[Step3] 这通常不是严重问题。如果遇到 CAL 无法颁发的问题，请在'Active Directory 用户和计算机'中手动添加。"
        }
    }
}

Import-Module RemoteDesktop
Import-Module ActiveDirectory

# --- 额外等待，确保 RDMS 服务和 WMI 提供程序完全就绪 ---
# Write-Host "[Step3] 正在等待 RDMS 服务稳定 (20 秒)..." -ForegroundColor Cyan
# Start-Sleep -Seconds 20
$tsLicenseServerInstance = Wait-ForRDMS_WMI
if (-not $tsLicenseServerInstance) {
    exit 1
}

# --- 确保计算机在许可证服务器组中 ---
$domain = Get-ADDomain
Add-ComputerToLicenseServerGroup -DomainName $domain.NetBIOSName

# --- 检查是否已经配置 ---
$licensingServer = Get-RDLicenseConfiguration -ErrorAction SilentlyContinue
if ($licensingServer -and $licensingServer.LicenseServer.Count -gt 0) {
    Write-Host "✅ [步骤 3] RDS 许可服务器已配置，跳过。" -ForegroundColor Green
    return
}

Write-Host "`n[Step3] 正在指定许可模式 ($LicenseMode) 和许可服务器 ($env:COMPUTERNAME.$env:USERDNSDOMAIN)..."
# 在域环境中，需要使用 FQDN
$licenseServerFqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN"
Set-RDLicenseConfiguration -LicenseServer $licenseServerFqdn -Mode $LicenseMode -ConnectionBroker $licenseServerFqdn -Force

Write-Host "[Step3] 正在填写公司信息..."

# 检查许可证密钥是否为占位符
if ($LicenseKeyPackID -like "XXXXX*") {
    Write-Warning "[Step3] 检测到占位符许可证密钥。跳过 CAL 安装。"
    Write-Warning "[Step3] 请在 .env.psd1 中提供真实的许可证密钥后重新运行脚本。"
    return
}

Write-Host "[Step3] 正在通过 WMI 直接配置和激活许可证服务器..."
try {
    # 1. 激活许可证服务器
    Write-Host "[Step3]   正在尝试激活许可证服务器..."
    # '1' 表示自动方法激活
    $activationResult = Invoke-CimMethod -InputObject $tsLicenseServerInstance -MethodName SetServerActivationStatus -Arguments @{ Status = 1 }
    if ($activationResult.ReturnValue -ne 0) {
        # 如果返回值非0，尝试注册公司信息后再激活
        Write-Warning "[Step3]   直接激活失败(代码: $($activationResult.ReturnValue))，尝试先注册公司信息..."
        $regParams = @{
            sFirstName = $CompanyInfo.FirstName
            sLastName = $CompanyInfo.LastName
            sCompany = $CompanyInfo.Company
            sCountryCode = $CompanyInfo.CountryRegion
        }
        Invoke-CimMethod -InputObject $tsLicenseServerInstance -MethodName RegisterLSServer -Arguments $regParams | Out-Null
        $activationResult = Invoke-CimMethod -InputObject $tsLicenseServerInstance -MethodName SetServerActivationStatus -Arguments @{ Status = 1 }
        if ($activationResult.ReturnValue -ne 0) {
            throw "激活许可证服务器失败，返回值: $($activationResult.ReturnValue)"
        }
    }
     Write-Host "✅ [Step3]   激活命令已发送。"

    # 2. 安装 CAL
    Write-Host "[Step3]   正在尝试安装 CAL..."
    # dwKeyPackType 4 = Enterprise Agreement
    # dwProductType 1 = PerUser, 0 = PerDevice
    $prodType = if($LicenseMode -eq "PerUser"){1}else{0}
    # dwProductVersion 8 = Windows Server 2022 (适用于 2025)
    
    $installResult = Invoke-CimMethod -InputObject $tsLicenseServerInstance -MethodName InstallLicenseKeyPack -Arguments @{
        dwKeyPackType    = 4 
        sAgreementNumber = $LicenseKeyPackID
        dwProductVersion = 8
        dwProductType    = $prodType
        dwLicenseCount   = $LicenseCount
    }
    
    if ($installResult.ReturnValue -ne 0) {
        throw "安装 CAL 失败，返回值: $($installResult.ReturnValue)"
    }
    
    Write-Host "✅ [Step3] 许可证服务器激活并成功安装 $LicenseCount 个 '$LicenseMode' CAL (for Server 2022/2025)。" -ForegroundColor Green
}
catch {
    Write-Error "[Step3] 通过 WMI 配置许可证服务器失败: $($_.Exception.Message)"
    Write-Error "[Step3] 这可能是因为许可证服务器需要几分钟才能完全初始化。请稍后重试或检查事件查看器中的 'TermServLicensing' 日志。"
    exit 1
}

Write-Host "`n[Step3] 许可配置完成，继续执行 win_step4_web.ps1" 