#=== 步骤 4：部署 RD Web Client & 配置 SSL ===
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$PublicFqdn,

    [Parameter(Mandatory=$true)]
    [string]$SslCertPath,

    [Parameter(Mandatory=$true)]
    [SecureString]$SslCertPassword,

    [Parameter(Mandatory=$false)]
    [bool]$UseGateway = $false
)

# 新增: 导入 RemoteDesktop 模块以确保所有相关 cmdlet 可用
Import-Module RemoteDesktop

# 遇到任何错误则停止执行
$ErrorActionPreference = "Stop"

# --- 检查证书文件是否存在 ---
if (-NOT (Test-Path $SslCertPath)) {
    Write-Error "[Step4] SSL 证书文件未找到: $SslCertPath。请检查 .env.psd1 中的路径。"
    exit 1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 导入 PFX 证书 ---
Write-Host "`n[Step4] 正在从 $SslCertPath 导入 SSL 证书..."
$certThumbprint = (Import-PfxCertificate -FilePath $SslCertPath -CertStoreLocation Cert:\LocalMachine\My -Password $SslCertPassword).Thumbprint
if (-not $certThumbprint) {
    Write-Error "[Step4] 证书导入失败。请检查证书路径和密码是否正确。"
    exit 1
}
Write-Host "✅ [Step4] 证书导入成功，指纹: $certThumbprint" -ForegroundColor Green

# --- 配置 RDS 角色使用新证书和 FQDN ---
$cert = Get-ChildItem "Cert:\LocalMachine\My\$certThumbprint"
$rdgw = "$env:COMPUTERNAME.$env:USERDNSDOMAIN" # 在一体化部署中，网关和Broker是同一台机器

Write-Host "[Step4] 正在为 RDS 角色配置 SSL 证书..."
Set-RDCertificate -Role RDRedirector -ImportPath $SslCertPath -Password $SslCertPassword -ConnectionBroker $rdgw -Force
Set-RDCertificate -Role RDPublishing  -ImportPath $SslCertPath -Password $SslCertPassword -ConnectionBroker $rdgw -Force
Write-Host "✅ [Step4] RDS 角色证书配置完成。" -ForegroundColor Green

if ($UseGateway) {
    throw "当前脚本尚未实现 RD Gateway 模式。请在 .env.psd1 将 UseGateway 保持为 \$false。"
} else {
    # 在非网关模式下，指示客户端使用公共 FQDN 连接到会话主机
    Write-Host "[Step4] 正在配置会话集合以使用公共 FQDN ($PublicFqdn) 进行直连..."
    # 'alternate full address' 告诉客户端使用这个地址来连接会话主机，而不是其内部 FQDN
    # 'gatewayusagemethod:i:0' 确保不尝试使用网关
    $customRdp = "gatewayusagemethod:i:0`r`nalternate full address:s:$PublicFqdn"
    Set-RDSessionCollectionConfiguration -CollectionName "QuickSessionCollection" -CustomRdpProperty $customRdp -ConnectionBroker $rdgw
    Write-Host "✅ [Step4] 已将会话集合配置为使用公共 FQDN ($PublicFqdn) 直连。" -ForegroundColor Green
}

# --- 配置 IIS ---
Write-Host "[Step4] 正在为 IIS 'Default Web Site' 绑定 SSL 证书..."
$siteName = 'Default Web Site'
$hostName = $PublicFqdn

# 清理可能存在的旧绑定
Write-Host "[Step4]   正在清理与 '$($hostName)' 冲突的旧 HTTPS 绑定..."
Get-WebBinding -Name $siteName -Protocol "https" -HostHeader $hostName -Port 443 -ErrorAction SilentlyContinue | Remove-WebBinding

# 创建新的 HTTPS 绑定
Write-Host "[Step4]   正在为 '$($hostName)' 创建新的 HTTPS 绑定..."
# 使用 SslFlags = 1 表示需要 SNI
New-WebBinding -Name $siteName -HostHeader $hostName -Protocol "https" -Port 443 -SslFlags 1 -ErrorAction Stop

# 等待并重试，以确保绑定已创建
$binding = $null
$retries = 5
$retryDelay = 2 # 秒
for ($i = 1; $i -le $retries; $i++) {
    $binding = Get-WebBinding -Name $siteName -HostHeader $hostName -Port 443 -Protocol "https" -ErrorAction SilentlyContinue
    if ($binding) {
        Write-Host "[Step4]   HTTPS 绑定已确认。"
        break
    }
    Write-Host "[Step4]   等待 HTTPS 绑定就绪... (尝试 $i / $retries)"
    Start-Sleep -Seconds $retryDelay
}

if (-not $binding) {
    throw "创建 IIS 绑定后无法找到它，证书关联失败。请检查 IIS 管理器确认 'Default Web Site' 下是否存在 for '$($hostName)' 的 HTTPS 绑定。"
}

# 关联证书
Write-Host "[Step4]   正在将证书 ($($cert.Thumbprint)) 关联到 HTTPS 绑定..."
# 'my' 是 Windows 的个人证书存储区
$binding.AddSslCertificate($cert.Thumbprint, "my")

Write-Host "✅ [Step4] IIS SSL 证书绑定完成。"

# --- 在 IIS 绑定成功后，为 RDWebAccess 角色配置证书 ---
Write-Host "[Step4] 正在为 RD Web Access 角色配置证书..."
Set-RDCertificate -Role RDWebAccess -ImportPath $SslCertPath -Password $SslCertPassword -ConnectionBroker $rdgw -Force
Write-Host "✅ [Step4] RD Web Access 角色证书配置完成。" -ForegroundColor Green

# --- 6. 部署和配置 RD Web Client (完全离线模式) ---
# 脚本将从本地缓存 '.\PkgCache' 目录安装，不再需要网络连接或更新 PowerShellGet。

Write-Host "[Step4] 正在切换到完全离线部署模式..."
$cachePath = Join-Path $PSScriptRoot "PkgCache"

# 校验缓存目录和文件是否存在
if (-not (Test-Path $cachePath)) {
    throw "错误: 本地缓存目录 '$cachePath' 不存在。请按照指示，先在有网络的计算机上创建缓存，然后将其完整复制到脚本所在目录下的 'PkgCache' 文件夹中。"
}

$moduleDir = Get-ChildItem -Path $cachePath -Directory -Filter "RDWebClientManagement" | Select-Object -First 1
if (-not $moduleDir) {
    throw "错误: 在缓存目录 '$cachePath' 中未找到 'RDWebClientManagement' 模块文件夹。"
}

$moduleVersionDir = Get-ChildItem -Path $moduleDir.FullName -Directory | Select-Object -First 1
$psd1Path = Join-Path $moduleVersionDir.FullName "RDWebClientManagement.psd1"
if (-not (Test-Path $psd1Path)) {
    throw "错误: 未找到模块定义文件 '$psd1Path'。"
}

# 兼容旧版 (rd-html-client-*) 与新版 (rdwebclient-*) 的文件命名
$clientPackage = Get-ChildItem -Path $cachePath -Filter "rd-html-client-*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $clientPackage) {
    $clientPackage = Get-ChildItem -Path $cachePath -Filter "rdwebclient-*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
}

# 1. 从本地缓存导入模块
Write-Host "[Step4] 正在从本地缓存导入 RDWebClientManagement 模块..."
Import-Module -Name $psd1Path -Force

# 2. 从本地缓存安装 Web Client 包
Write-Host "[Step4] 正在从本地缓存安装 RD Web Client 包..."
Install-RDWebClientPackage -Source $clientPackage.FullName

# 3. 导入 Broker 证书以供 Web Client 使用
Write-Host "[Step4] 正在导入 Broker 证书以供 Web Client 使用..."
$certExportPath = "$env:TEMP\broker_cert.cer"
Export-Certificate -Cert $cert -FilePath $certExportPath
Import-RDWebClientBrokerCert $certExportPath
Remove-Item $certExportPath -Force

# 4. 发布 Web Client
Write-Host "[Step4] 正在将 RD Web Client 发布到生产环境..."
Publish-RDWebClientPackage -Type Production -Latest

Write-Host "`n✅ [Step4] RD Web Client 部署完成！" -ForegroundColor Green
# 连接提示已移动至步骤 5，以避免重复并在所有配置完成后统一显示。 