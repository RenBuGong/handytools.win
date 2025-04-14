param(
    [string]$KeyPath,
    [string]$AuthorizedKeysFile
)

# 1. 如果没有输入 $KeyPath，则提示用户手动输入.
if (-not $KeyPath) {
    $KeyPath = Read-Host -Prompt "Enter the full path to your public key file"
}

# 2. 检查 $KeyPath 是否存在.
if (-not (Test-Path $KeyPath)) {
    Write-Host "[Error] The specified public key file '$KeyPath' does not exist."
    exit 1
}

# 3. 如果没有传入 -AuthorizedKeysFile，则默认使用当前用户目录下 .ssh/authorized_keys
if (-not $AuthorizedKeysFile) {
    $AuthorizedKeysFile = Join-Path $env:USERPROFILE '.ssh\authorized_keys'
    Write-Host "[Info] No -AuthorizedKeysFile specified. Defaulting to $AuthorizedKeysFile"
}

# 4. 确保目标目录存在（如果需要则创建），例如:
#    - C:\Users\<User>\.ssh\authorized_keys
#    - 或 C:\ProgramData\ssh\administrators_authorized_keys 等.
$destDir = Split-Path $AuthorizedKeysFile
if (-not (Test-Path $destDir)) {
    Write-Host "[Info] Target directory '$destDir' not found. Creating it..."
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    if (-not (Test-Path $destDir)) {
        Write-Host "[Error] Failed to create directory '$destDir'. Check permissions."
        exit 1
    }
}

# 5. 读取公钥内容 (假设公钥文件只有一行，如果多行，需要额外处理).
$publicKeyContent = (Get-Content -Path $KeyPath -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($publicKeyContent)) {
    Write-Host "[Error] The public key content is empty or whitespace."
    exit 1
}

# 6. 如果 authorized_keys 文件不存在，则直接创建并写入公钥.
if (-not (Test-Path $AuthorizedKeysFile)) {
    Write-Host "[Info] authorized_keys not found at '$AuthorizedKeysFile'. Creating file and adding public key..."
    $publicKeyContent | Out-File -FilePath $AuthorizedKeysFile -Encoding UTF8
    if (-not (Test-Path $AuthorizedKeysFile)) {
        Write-Host "[Error] Failed to create '$AuthorizedKeysFile'."
        exit 1
    }
    Write-Host "[Success] Public key added to the new authorized_keys file."
}
else {
    # 7. 如果 authorized_keys 已存在，则逐行读取，检查是否包含该公钥.
    $fileLines = Get-Content -Path $AuthorizedKeysFile
    if ($fileLines -notcontains $publicKeyContent) {
        Write-Host "[Info] Public key not found in authorized_keys. Appending..."
        Add-Content -Path $AuthorizedKeysFile -Value $publicKeyContent
        Write-Host "[Success] Public key successfully appended to authorized_keys."
    }
    else {
        Write-Host "[Info] The public key is already present in authorized_keys."
    }
}

Write-Host "Done."
