[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SslCertPath,

    [Parameter(Mandatory=$true)]
    [SecureString]$SslCertPassword,

    [Parameter(Mandatory=$false)]
    [string]$PublicFqdn
)

# 遇到任何错误则停止执行
$ErrorActionPreference = "Stop"

Write-Host "▶️ 开始执行 [步骤 5: 配置 WebSocket 连接]..."

# --- 1. 安装 IIS WebSocket 功能 ---
Write-Host "[Step5] 正在检查并安装 IIS WebSocket 功能..."
if (-not (Get-WindowsFeature -Name Web-WebSockets).Installed) {
    Install-WindowsFeature Web-WebSockets
    Write-Host "✅ [Step5] IIS WebSocket 功能安装完成。"
} else {
    Write-Host "✅ [Step5] IIS WebSocket 功能已安装，跳过。"
}

# --- 2. 获取证书指纹 ---
# 我们从 PFX 文件动态获取指纹，而不是硬编码，这让脚本更通用
Write-Host "[Step5] 正在从 PFX 文件获取证书指纹..."
$cert = Get-PfxData -FilePath $SslCertPath -Password $SslCertPassword
$certThumbprint = $cert.EndEntityCertificates[0].Thumbprint
Write-Host "✅ [Step5] 证书指纹获取成功: $certThumbprint"

# 确保证书也存在于 "Remote Desktop" 存储区
if (-not (Get-ChildItem "Cert:\\LocalMachine\\Remote Desktop" | Where-Object Thumbprint -eq $certThumbprint)) {
    Write-Host "[Step5] 正在将证书复制到 'Remote Desktop' 存储区..."
    $origCert = Get-ChildItem "Cert:\\LocalMachine\\My" | Where-Object Thumbprint -eq $certThumbprint
    if ($origCert) {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Remote Desktop", "LocalMachine")
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($origCert)
        $store.Close()
    }
}

# --- 3. 绑定证书到 WebSocket 端口 (3392) ---
Write-Host "[Step5] 正在为 WebSocket 端口 (3392) 绑定 SSL 证书..."
# 首先移除可能存在的旧绑定
netsh http delete sslcert ipport=0.0.0.0:3392 | Out-Null
# 添加新绑定
netsh http add sslcert ipport=0.0.0.0:3392 certhash=$certThumbprint appid="{00000000-0000-0000-0000-000000000000}" certstorename="Remote Desktop"
Write-Host "✅ [Step5] WebSocket 端口证书绑定完成。"

# --- 4. 配置 RDP 服务监听 WebSocket ---
Write-Host "[Step5] 正在配置 RDP 服务以监听 WebSocket..."
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
Set-ItemProperty -Path $regPath -Name "WebSocketURI" -Value "https://+:3392/rdp/"
Write-Host "✅ [Step5] RDP 服务注册表配置完成。"

# --- 5. 重启远程桌面服务以应用更改 ---
Write-Host "[Step5] 正在重启远程桌面服务..."
Restart-Service TermService -Force
Write-Host "✅ [Step5] 远程桌面服务重启完成。"

Write-Host "`n✅ [步骤 5] WebSocket 配置成功！现在可以从 Web Client 建立远程连接了。" -ForegroundColor Green

if ($PublicFqdn) {
    Write-Host "`n您现在应该可以通过 https://$PublicFqdn/rdweb/webclient 访问 RD Web 客户端并建立远程连接。" -ForegroundColor Cyan
} 