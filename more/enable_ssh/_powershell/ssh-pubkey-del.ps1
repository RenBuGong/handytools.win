param(
    [string]$KeyPath,
    [string]$AuthorizedKeysFile
)

# 1. 如果没有输入 $KeyPath，则提示用户手动输入.
if (-not $KeyPath) {
    $KeyPath = Read-Host -Prompt "Enter the full path to the public key file you want to remove"
}

# 2. 检查 $KeyPath 是否存在.
if (-not (Test-Path $KeyPath)) {
    Write-Host "[Error] The specified public key file '$KeyPath' does not exist."
    exit 1
}

# 3. 如果没有传入 -AuthorizedKeysFile，则默认使用当前用户目录下的 .ssh\authorized_keys
if (-not $AuthorizedKeysFile) {
    $AuthorizedKeysFile = Join-Path $env:USERPROFILE '.ssh\authorized_keys'
    Write-Host "[Info] No -AuthorizedKeysFile specified. Defaulting to $AuthorizedKeysFile"
}

# 4. 读取要移除的公钥内容 (假设为单行，如果是多行需额外处理).
$publicKeyContent = (Get-Content -Path $KeyPath -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($publicKeyContent)) {
    Write-Host "[Error] The public key content is empty or whitespace."
    exit 1
}

# 5. 检查目标 authorized_keys 是否存在.
if (-not (Test-Path $AuthorizedKeysFile)) {
    Write-Host "[Info] '$AuthorizedKeysFile' does not exist. Nothing to remove."
    exit 0
}

# 6. 逐行读取 authorized_keys，判断是否包含该行.
$fileLines = Get-Content -Path $AuthorizedKeysFile

# 如果找到完全匹配的行，则移除.
if ($fileLines -contains $publicKeyContent) {
    # 过滤出所有不等于该公钥行的内容.
    $newFileLines = $fileLines | Where-Object { $_ -ne $publicKeyContent }

    # 将过滤后的内容写回 authorized_keys
    $newFileLines | Out-File -FilePath $AuthorizedKeysFile -Encoding UTF8

    Write-Host "[Success] The specified public key has been removed from '$AuthorizedKeysFile'."
}
else {
    Write-Host "[Info] The specified public key does not exist in '$AuthorizedKeysFile'."
}

Write-Host "Done."
