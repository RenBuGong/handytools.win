# ===================================================================
#
#               RemoteApp 同步脚本 (apps_publish.ps1)
#
# 功能:
#   - 读取 `.env.psd1` 中 RemoteApps 配置。
#   - 智能地同步 RemoteApp 列表：
#     - 如果应用未发布，则创建。
#     - 如果应用已发布但配置有变，则更新。
#     - 如果应用配置一致，则跳过。
#   - 自动为需要命令行参数的应用创建 .bat 包装器。
#
# 使用方法:
#   直接以管理员身份运行此脚本: .\apps_publish.ps1
#
# ===================================================================

# --- 环境设置 ---
$ErrorActionPreference = "Stop"
Import-Module RemoteDesktop -ErrorAction Stop

# --- 读取配置 ---
try {
    # 从统一配置文件读取应用列表
    $envConfig = Get-Content -Path (Join-Path $PSScriptRoot ".env.psd1") -ErrorAction Stop | Out-String | Invoke-Expression
} catch {
    Write-Error "错误：无法读取 '.env.psd1'。请确保该文件与本脚本在同一目录下。"
    exit 1
}

$collectionName = "QuickSessionCollection" 
# 在域环境中，Broker FQDN 应与部署时一致
$connectionBroker = "$($env:COMPUTERNAME).$($env:USERDNSDOMAIN)"

# --- 脚本工作目录 (用于存放 .bat 文件) ---
$scriptRoot = $PSScriptRoot
$wrapperDir = Join-Path -Path $scriptRoot -ChildPath "RemoteAppWrappers"
if (-not (Test-Path -Path $wrapperDir)) {
    New-Item -Path $wrapperDir -ItemType Directory | Out-Null
}

Write-Host "▶️ 开始同步 RemoteApps 到集合 '$collectionName'..." -ForegroundColor Cyan

# --- 获取当前已发布的所有 RemoteApp ---
$publishedApps = Get-RDRemoteApp -CollectionName $collectionName -ConnectionBroker $connectionBroker -ErrorAction SilentlyContinue

# --- 遍历配置文件中定义的每个应用 ---
foreach ($app in $envConfig.RemoteApps) {
    
    $displayName = $app.DisplayName
    Write-Host "`n处理应用: '$displayName'..."

    # 查找此应用是否已发布
    $existingApp = $null
    if ($publishedApps) {
        $existingApp = $publishedApps | Where-Object { $_.DisplayName -eq $displayName }
    }

    # --- 准备应用参数 ---
    # 这是我们希望达到的最终状态
    $baseState = @{
        DisplayName      = $displayName
        CollectionName   = $collectionName
        ConnectionBroker = $connectionBroker
    }
    
    $desiredState = $null

    # 处理命令行参数
    if ($app.PSObject.Properties.Match("CommandLine") -and -not [string]::IsNullOrWhiteSpace($app.CommandLine)) {
        Write-Host "  -> 检测到命令行参数，将创建 .bat 包装器..." -ForegroundColor DarkGray
        # 如果有命令行参数，则创建 .bat 包装器
        $wrapperPath = Join-Path -Path $wrapperDir -ChildPath "$($displayName -replace '[^a-zA-Z0-9]', '')_wrapper.bat"
        $fileContent = "@echo off`r`n`"$($app.FilePath)`" $($app.CommandLine)"
        Set-Content -Path $wrapperPath -Value $fileContent -Encoding UTF8
        
        $desiredState = $baseState.Clone()
        $desiredState.FilePath = $wrapperPath
        $desiredState.CommandLineSetting = "DoNotAllow"
        if ($app.PSObject.Properties.Match("IconPath")) { 
            $desiredState.IconPath = $app.IconPath 
            if ($app.PSObject.Properties.Match("IconIndex")) { $desiredState.IconIndex = $app.IconIndex } else { $desiredState.IconIndex = 0 }
        } else {
            # 安全回退：如果未提供图标，则使用一个保证可用的系统通用图标
            $desiredState.IconPath = "C:\Windows\System32\imageres.dll"
            $desiredState.IconIndex = 2
        }

    }
    elseif ($app.PSObject.Properties.Match("FilePath") -and -not [string]::IsNullOrWhiteSpace($app.FilePath)) {
        $desiredState = $baseState.Clone()
        $desiredState.FilePath = $app.FilePath

        # --- 图标处理：带验证和回退机制 ---
        # 优先使用 IconPath，如果未提供，则回退到使用 FilePath 作为图标来源
        $iconSourcePath = if ($app.PSObject.Properties.Match("IconPath") -and -not [string]::IsNullOrWhiteSpace($app.IconPath)) { $app.IconPath } else { $app.FilePath }
        $iconSourceIndex = if ($app.PSObject.Properties.Match("IconIndex")) { $app.IconIndex } else { 0 }
        
        $iconIsValid = $false
        if (-not [string]::IsNullOrWhiteSpace($iconSourcePath) -and (Test-Path $iconSourcePath)) {
            try {
                # 尝试加载图标来验证路径是否可访问
                $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($iconSourcePath)
                if ($ico) {
                    $iconIsValid = $true
                    $ico.Dispose() # 释放资源
                }
            } catch {
                Write-Warning "  -> ❗ 无法从 '$($iconSourcePath)' 提取图标 (这在 Windows Server 上可能由安全策略导致)。"
            }
        }

        if ($iconIsValid) {
            $desiredState.IconPath = $iconSourcePath
            $desiredState.IconIndex = $iconSourceIndex
            Write-Host "  -> 使用指定图标: '$($iconSourcePath)' (Index: $($iconSourceIndex))" -ForegroundColor DarkGray
        } else {
            # 安全回退：如果未提供图标或图标路径无效，则使用一个保证可用的系统通用图标
            $desiredState.IconPath = "C:\Windows\System32\imageres.dll"
            $desiredState.IconIndex = 2 # 通用应用程序图标
            Write-Warning "  -> 将回退到通用系统图标。"
        }
    }
    elseif ($app.PSObject.Properties.Match("AppAlias") -and -not [string]::IsNullOrWhiteSpace($app.AppAlias)) {
        $desiredState = $baseState.Clone()
        # UWP/Store 应用须使用 FilePath = "||<AUMID>" 形式
        $desiredState.FilePath = "||$($app.AppAlias)" 
        # 为确保唯一性，设置 Alias，可使用过滤后的 DisplayName
        $desiredState.Alias = ($displayName -replace '[^a-zA-Z0-9]', '')
    }
    else {
        Write-Warning "  -> 跳过 '$displayName'，因为它缺少 FilePath 或 AppAlias 属性。"
        continue
    }

    # 在后续比较之前，移除值为空的可选键，防止错误更新
    foreach ($optKey in @('IconPath','IconIndex','CommandLineSetting')) {
        if ($desiredState.ContainsKey($optKey) -and ([string]::IsNullOrWhiteSpace($desiredState.$optKey))) {
            $desiredState.Remove($optKey)
        }
    }

    # --- 对比并执行操作 ---
    if (-not $existingApp) {
        # --- 创建新应用 ---
        Write-Host "  -> 应用未发布，正在创建..." -ForegroundColor Yellow
        
        if ($app.PSObject.Properties.Match("AppAlias") -and -not [string]::IsNullOrWhiteSpace($app.AppAlias)) {
            # --- 创建 UWP 应用 ---
            Write-Host "  -> 检测到 UWP 应用，正在通过 Get-StartApps 查找..." -ForegroundColor DarkGray
            $uwpApp = Get-StartApps | Where-Object { $_.AppID -eq $app.AppAlias }
            if ($uwpApp) {
                # 使用管道将 UWP 应用对象传递给 New-RDRemoteApp
                $uwpApp | New-RDRemoteApp -CollectionName $collectionName -ConnectionBroker $connectionBroker -DisplayName $displayName
                Write-Host "  -> ✅ 创建成功。" -ForegroundColor Green
            } else {
                Write-Warning "  -> ❗ 错误: 无法在系统中找到 AppID 为 '$($app.AppAlias)' 的 UWP 应用。这在 Windows Server 系统上很常见，因为它可能没有默认安装此应用。请尝试从 Microsoft Store 或使用 winget 手动安装。"
            }
        }
        else {
            # --- 创建传统 Win32 应用 ---
            # 移除所有值为空的可选键，防止错误更新
            foreach ($optKey in @('IconPath','IconIndex','CommandLineSetting')) {
                if ($desiredState.ContainsKey($optKey) -and ([string]::IsNullOrWhiteSpace($desiredState.$optKey))) {
                    $desiredState.Remove($optKey)
                }
            }
            $newApp = New-RDRemoteApp @desiredState
            Write-Host "  -> ✅ 创建成功。" -ForegroundColor Green
            
            # --- 创建后，如果需要，设置命令行参数 ---
            if ($app.PSObject.Properties.Match("CommandLine") -and -not [string]::IsNullOrWhiteSpace($app.CommandLine)) {
                Write-Host "  -> 正在为 '$($displayName)' 设置命令行参数..." -ForegroundColor DarkGray
                Set-RDRemoteApp -Alias $newApp.Alias -DisplayName $displayName -CollectionName $collectionName -ConnectionBroker $connectionBroker -RequiredCommandLine $app.CommandLine -CommandLineSetting Require
                Write-Host "  -> ✅ 命令行参数设置成功。" -ForegroundColor Green
            }
        }
    }
    else {
        # --- 对比并更新已存在的应用 ---
        $needsUpdate = $false
        # 对于 UWP 应用，大部分属性是只读的，我们只做最基础的检查，不进行更新
        if ($existingApp.FilePath.StartsWith("||")) {
            Write-Host "  -> ✅ UWP 应用配置一致，无需操作。" -ForegroundColor Green
            continue
        }

        # 检查命令行参数是否需要更新
        $currentCmd = $existingApp.RequiredCommandLine
        $desiredCmd = if ($app.PSObject.Properties.Match("CommandLine")) { $app.CommandLine } else { $null }

        if ($currentCmd -ne $desiredCmd) {
            Write-Host "  -> 属性 'RequiredCommandLine' 需要更新 (当前: '$($currentCmd)', 期望: '$($desiredCmd)')"
            $needsUpdate = $true
        }

        foreach ($key in $desiredState.Keys) {
            # 排除不直接对应的参数
            if ($key -in @("CollectionName", "ConnectionBroker")) { continue }
            
            # AppAlias 是创建时参数，只读属性，不能用于对比或更新
            if ($key -eq "AppAlias") {
                if ($existingApp.AppAlias -ne $desiredState.AppAlias) {
                    Write-Warning "  -> ❗ 注意: 不支持修改 AppAlias。如需更改，请先手动删除旧应用再运行脚本。"
                }
                continue 
            }

            # FilePath 也是只读属性
            if ($key -eq "FilePath") {
                if ($existingApp.FilePath -ne $desiredState.FilePath) {
                    Write-Warning "  -> ❗ 注意: 不支持直接修改 FilePath。如需更改，请先手动删除旧应用再运行脚本。"
                }
                continue
            }

            # 对比其他可写属性
            try {
                if ($existingApp.$key -ne $desiredState.$key) {
                    Write-Host "  -> 属性 '$key' 需要更新 (当前: '$($existingApp.$key)', 期望: '$($desiredState.$key)')"
                    $needsUpdate = $true
                }
            } catch {}
        }

        if ($needsUpdate) {
            Write-Host "  -> 应用配置已变更，正在更新..." -ForegroundColor Yellow
            # Alias 是 Set-RDRemoteApp 的必需参数
            $desiredState.Alias = $existingApp.Alias
            if ($app.PSObject.Properties.Match("CommandLine")) {
                $desiredState.RequiredCommandLine = $app.CommandLine
                $desiredState.CommandLineSetting = "Require"
            } else {
                 $desiredState.RequiredCommandLine = ""
                 $desiredState.CommandLineSetting = "Allow"
            }
            Set-RDRemoteApp @desiredState
            Write-Host "  -> ✅ 更新成功。" -ForegroundColor Green
        }
        else {
            Write-Host "  -> ✅ 配置一致，无需操作。" -ForegroundColor Green
        }
    }
}

# --- 清理不再需要的 .bat 包装器目录 ---
if (Test-Path -Path $wrapperDir) {
    Remove-Item -Path $wrapperDir -Recurse -Force
    Write-Host "`n✅ 已清理旧的 .bat 包装器目录。" -ForegroundColor Green
}

Write-Host "`n▶️ RemoteApp 同步完成。" -ForegroundColor Cyan 