<#
.SYNOPSIS
  Manage remote authorized_keys by either using OpenSSH (ssh/scp) or falling back to PuTTY (plink/pscp).

.PARAMETER Port
  SSH port.

.PARAMETER RemoteHost
  Remote hostname or IP.

.PARAMETER RemoteUser
  The actual username on remote system used to add/remove the key.

.PARAMETER SshKeyPath
  Path to the local private key in OpenSSH format (e.g. id_rsa).
  If we succeed using this key with 'ssh', we won't involve plink/pscp at all.

.PARAMETER PubKeyPath
  Optional. The public key file to add/remove. If not specified, default = "$SshKeyPath.pub"

.PARAMETER Action
  "add" or "remove", default "add".

.EXAMPLE
  .\Manage-RemoteKey.ps1 -Port 22 -RemoteHost 1.2.3.4 -RemoteUser root -SshKeyPath "C:\keys\id_rsa" -Action add

#>

param(
    [Parameter(Mandatory=$true)] [int]$Port,
    [Parameter(Mandatory=$true)] [string]$RemoteHost,
    [Parameter(Mandatory=$true)] [string]$RemoteUser,
    [Parameter(Mandatory=$true)] [string]$SshKeyPath,
    [Parameter(Mandatory=$false)] [string]$PubKeyPath,
    [ValidateSet("add","remove")] [string]$Action = "add"
)
$plinkPath = Join-Path $PSScriptRoot "plink.exe"
$pscpPath = Join-Path  $PSScriptRoot "pscp.exe"

Write-Host "`n=================== Parameter Overview ======="
Write-Host "Port        = $Port"
Write-Host "RemoteHost  = $RemoteHost"
Write-Host "RemoteUser  = $RemoteUser"
Write-Host "SshKeyPath  = $SshKeyPath"
Write-Host "PubKeyPath  = $PubKeyPath"
Write-Host "Action      = $Action"
Write-Host "==============================================="

# ------------------------------------------------------------------------------
# [1] 处理默认公钥路径.
# ------------------------------------------------------------------------------
if (-not $PubKeyPath) {
    $PubKeyPath = "$SshKeyPath.pub"
    Write-Host "[INFO] No PubKeyPath specified, using default: $PubKeyPath"
}
if (-not (Test-Path $PubKeyPath)) {
    Write-Host "[ERROR] Public key file not found: $PubKeyPath"
    exit 1
}

# ------------------------------------------------------------------------------
# [2] 先构造好要在远程执行的脚本 (add/remove 公钥)
# ------------------------------------------------------------------------------
$remoteScript = @'
#!/usr/bin/env bash
set -e

ACTION="$1"


if [ "$ACTION" = "add" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
  fi

  if ! grep -Fxq '__PUB_KEY__' "$HOME/.ssh/authorized_keys"; then
    echo '__PUB_KEY__' >> "$HOME/.ssh/authorized_keys"
  fi
  chmod 600 "$HOME/.ssh/authorized_keys"
  echo "[INFO] Public key added."

elif [ "$ACTION" = "remove" ]; then
  if [ -f "$HOME/.ssh/authorized_keys" ]; then
    t_xx=$(grep -Fxv '__PUB_KEY__' "$HOME/.ssh/authorized_keys"|| true)
    echo "$t_xx" > "$HOME/.ssh/authorized_keys"
    echo "[INFO] Public key removed."
  else
    echo "[WARN] authorized_keys not found, nothing to remove."
  fi

else
  echo "[ERROR] Unknown action: $ACTION"
  exit 1
fi
'@



# 把本地公钥注入脚本文本 (去掉换行、转义特殊字符)
$pubKey       = Get-Content -Raw $PubKeyPath
$escapedPubKey = $pubKey -replace "`r?`n",""
$remoteScript  = $remoteScript -replace "__PUB_KEY__", $escapedPubKey
# $remoteScript  = $remoteScript -replace "__PUB_KEY__", [Regex]::Escape($escapedPubKey)

# 先保存为临时文件, 以后不管用 scp 还是 pscp, 都要上传.
$tempScriptPath = Join-Path $env:TEMP ("_remote_op_" + [guid]::NewGuid() + ".sh")

# === 改动在这里 ===
$remoteScriptUnix = $remoteScript -replace "`r`n","`n"           # 保证 UNIX 行尾
$utf8NoBOM        = New-Object System.Text.UTF8Encoding($false) # 不带 BOM
[System.IO.File]::WriteAllText($tempScriptPath, $remoteScriptUnix, $utf8NoBOM)

# ------------------------------------------------------------------------------
# [3] 优先尝试使用 "ssh.exe" + "scp.exe" (OpenSSH) 来做免密登录.
#     - 通过 -o BatchMode=yes 可以让 ssh 在私钥失败时直接退出而不提示密码.
#     - -o StrictHostKeyChecking=accept-new 可以自动将未知主机的key加入 known_hosts
#       (Windows 10+ 一般可用; 若版本太旧无此选项, 可改为 no)
# ------------------------------------------------------------------------------
Write-Host "[STEP] Trying to use OpenSSH client (ssh.exe / scp.exe) with key: $SshKeyPath"
$sshExe = "ssh.exe"
$scpExe = "scp.exe"

# 测试免密.
$testSshParams = @(
    "-i", $SshKeyPath,
    "-o", "BatchMode=yes",
    "-o", "StrictHostKeyChecking=accept-new",
    "-p", $Port,
    "$RemoteUser@$RemoteHost",
    "echo OK"
)
Write-Host "[DEBUG] ssh command: $sshExe $($testSshParams -join ' ')"

$sshTestProcess = New-Object System.Diagnostics.Process
$sshTestProcess.StartInfo.FileName  = $sshExe
$sshTestProcess.StartInfo.Arguments = $testSshParams -join " "
$sshTestProcess.StartInfo.UseShellExecute = $false
$sshTestProcess.StartInfo.CreateNoWindow  = $true
$sshTestProcess.StartInfo.RedirectStandardOutput = $true
$sshTestProcess.StartInfo.RedirectStandardError  = $true

$sshTestProcess.Start() | Out-Null
$sshTestProcess.WaitForExit()
$sshExitCode = $sshTestProcess.ExitCode

Write-Host "[INFO] ssh test exit code = $sshExitCode"
$useOpenSsh = ($sshExitCode -eq 0)

if ($useOpenSsh) {
    Write-Host "[INFO] => OpenSSH-based key login successful, will use ssh/scp."
} else {
    Write-Host "[WARN] => OpenSSH failed to use private key, will use PuTTY (plink/pscp)."
}

# ------------------------------------------------------------------------------
# [4] 如果 OpenSSH 成功, 则直接用 ssh/scp 执行后续操作.
#     否则, 则需要(1)用虚拟用户+错误密码来进行 plink交互式缓存host key
#             (2)提示用户输入密码.
#             (3)用 pscp/plink + -pw <pwd> 来执行.
# ------------------------------------------------------------------------------
if ($useOpenSsh) {
    # ========== 使用 ssh/scp 逻辑 ==========

    # 4.1 上传脚本 => scp -i <key> -o StrictHostKeyChecking=accept-new -P <Port> <local> <user@host>:__sub.cmd.sh
    $scpUploadParams = @(
        "-i", $SshKeyPath,
        "-o", "StrictHostKeyChecking=accept-new",
        "-P", $Port,
        $tempScriptPath,
        "$RemoteUser@${RemoteHost}:__sub.cmd.sh"
    )
    Write-Host "[DEBUG] scp command: $scpExe $($scpUploadParams -join ' ')"
    $scpProc = Start-Process -FilePath $scpExe -ArgumentList ($scpUploadParams -join " ") -PassThru -Wait -NoNewWindow
    if ($scpProc.ExitCode -ne 0) {
        Remove-Item $tempScriptPath -Force
        Write-Host "[ERROR] scp failed, exit code = $($scpProc.ExitCode)"
        exit $scpProc.ExitCode
    }

    # 4.2 远程执行 => ssh -i <key> -o ... -p <Port> <user@host> "chmod +x ... && bash ... <Action> && rm ..."
    $sshExecParams = @(
        "-i", $SshKeyPath,
        "-o", "StrictHostKeyChecking=accept-new",
        "-p", $Port,
        "$RemoteUser@$RemoteHost",
        "chmod +x __sub.cmd.sh && bash __sub.cmd.sh $Action && rm -f __sub.cmd.sh"
    )
    Write-Host "[DEBUG] ssh command: $sshExe $($sshExecParams -join ' ')"
    $sshProc = Start-Process -FilePath $sshExe -ArgumentList ($sshExecParams -join " ") -PassThru -Wait -NoNewWindow
    $sshCode = $sshProc.ExitCode
    Remove-Item $tempScriptPath -Force

    if ($sshCode -ne 0) {
        Write-Host "[ERROR] ssh failed, exit code = $sshCode"
        exit $sshCode
    }

    Write-Host "[INFO] Done via OpenSSH. exit 0"
    exit 0
}
else {
    # ========== 使用 plink/pscp 逻辑 ==========

    # 4.1 用虚拟用户(假名)做一次交互式连接, 让用户手动yes缓存hostkey
    $fakeUser  = "fe750f81-9419-4787-a836-01b4e0719736"
    $fakePass  = "fakePassword12345"

    Write-Host "`n[STEP] Using virtual user '$fakeUser' + fakePassword for an interactive plink connection, to cache hostkey."
    $answer = Read-Host "Continue? [Y/N]"
    if ($answer -notmatch '^[Yy]$') {
        Write-Host "User cancelled, script exiting."
        Remove-Item $tempScriptPath -Force
        exit 0
    }

    # 不加 -batch, 让用户看到 host key 提示.
    Start-Process -FilePath $plinkPath -ArgumentList (
        "-ssh",
        "-P", $Port,
        "-pw", $fakePass,
        "$fakeUser@$RemoteHost"
    ) -Wait -NoNewWindow

    Write-Host "`n[INFO] Virtual user connection ended (will report Access denied). If you have already input 'yes', host key has been cached.`n"

    # 4.2 提示用户输入真正密码.
    do {
      $pwSec = Read-Host -Prompt "Please input the SSH password for $RemoteUser@$RemoteHost (input hidden)" -AsSecureString
      $bstr  = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwSec)
      $pwPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
      [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
      
      if ([string]::IsNullOrWhiteSpace($pwPlain)) {
          Write-Host "Password cannot be empty. Please try again."
      }
  } while ([string]::IsNullOrWhiteSpace($pwPlain))
  

    # 4.3 上传脚本 => pscp -batch -P <Port> -pw <pwPlain> <local> <user@host>:__sub.cmd.sh
    $pscpUploadParams = @(
        "-batch",
        "-P", $Port,
        "-pw", $pwPlain,
        $tempScriptPath,
        "$RemoteUser@${RemoteHost}:__sub.cmd.sh"
    )
    Write-Host "[DEBUG] pscp: $pscpPath $($pscpUploadParams -join ' ')"
    $pscpProc = Start-Process -FilePath $pscpPath -ArgumentList ($pscpUploadParams -join " ") -PassThru -Wait -NoNewWindow
    $pscpCode = $pscpProc.ExitCode
    if ($pscpCode -ne 0) {
        Remove-Item $tempScriptPath -Force
        Write-Host "[ERROR] pscp failed, exit code=$pscpCode"
        exit $pscpCode
    }

    # 4.4 远程执行 => plink -batch -ssh -P <Port> -pw <pwPlain> <user@host> "chmod +x && bash ... && rm ..."
    $plinkExecParams = @(
        "-batch",
        "-ssh",
        "-P", $Port,
        "-pw", $pwPlain,
        "$RemoteUser@${RemoteHost}",
        "chmod +x __sub.cmd.sh && bash __sub.cmd.sh $Action && rm -f __sub.cmd.sh"
    )
    Write-Host "[DEBUG] plink: $plinkPath $($plinkExecParams -join ' ')"
    $plinkProc = Start-Process -FilePath $plinkPath -ArgumentList ($plinkExecParams -join " ") -PassThru -Wait -NoNewWindow
    $plinkCode = $plinkProc.ExitCode
    Remove-Item $tempScriptPath -Force

    if ($plinkCode -ne 0) {
        Write-Host "[ERROR] plink failed, exit code=$plinkCode"
        exit $plinkCode
    }

    Write-Host "`n[INFO] Done via PuTTY. exit 0"
    exit 0
}
