# common.ps1
# 
# 放于 proj_root\_lib\common.ps1
# 此脚本加载 config.ps1 (位于 proj_root\config.ps1)，并执行初始化检查

###############################################################################
# 1. 加载多语言资源
###############################################################################
. "$PSScriptRoot\resources.ps1"

###############################################################################
# 2. 检测系统语言并设置默认语言
###############################################################################
$currentCulture = $PSCulture
if (-not $Messages.ContainsKey($currentCulture)) {
    $currentCulture = "en-US"
}

###############################################################################
# 3. 定义获取多语言文本的函数
###############################################################################
function Get-Message {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Key,

        [Parameter(Mandatory=$false)]
        [object[]] $Args
    )

    if ($Messages[$currentCulture].ContainsKey($Key)) {
        $msg = $Messages[$currentCulture][$Key]
        if ($null -ne $Args -and $Args.Count -gt 0) {
            return $msg -f $Args
        }
        else {
            return $msg
        }
    }
    else {
        # 如果没找到对应的Key, 返回一个提示
        return "[MISSING:$Key]"
    }
}

###############################################################################
# 4. 定义路径与标志文件
###############################################################################
# proj_root 是上一级目录
$ProjRoot  = Split-Path $PSScriptRoot -Parent
$configFile = Join-Path $ProjRoot "config.ps1"
$initFile   = Join-Path $ProjRoot "confirmed.mark.tmp.log"

###############################################################################
# 5. Expand-ProjectPath: 若给定路径是相对的，则视为相对于 proj_root
###############################################################################
function Expand-ProjectPath($path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        return ""
    }
    # 如果 path 是绝对路径 (盘符开头，或网络路径等)，直接返回
    if ($path -match '^[a-zA-Z]:\\' -or $path -match '^[\\/]{2}' -or $path -match '^%') {
        return [System.Environment]::ExpandEnvironmentVariables($path)
    }
    else {
        # 否则认为是相对于 proj_root 的路径
        $joined = Join-Path $ProjRoot $path
        return [System.Environment]::ExpandEnvironmentVariables($joined)
    }
}

###############################################################################
# 6. Initialize-Config: 加载 config.ps1 并做检查
###############################################################################
function Initialize-Config {

    # 0) 如果没有 initialized.tmp，则提示是首次运行
    if (-not (Test-Path $initFile)) {
        Write-Host (Get-Message "common_FirstRun") -ForegroundColor Yellow
        [void][System.Console]::ReadKey()  # 暂停，等用户按键
    }

    # 1) 检查 config.ps1 是否存在
    if (-not (Test-Path $configFile)) {
        Write-Host (Get-Message "common_ConfigNotFound" $configFile) -ForegroundColor Red
        Write-Host (Get-Message "common_PleaseCreateConfig") -ForegroundColor Red
        throw (Get-Message "common_ConfigNotFound" $configFile)
    }

    # 2) 尝试加载 config.ps1
    try {
        . $configFile
    }
    catch {
        # 若加载脚本出错，可能是语法错误等
        $errMsg = $_.Exception.Message
        Write-Host "[Error] Failed to load config.ps1. Error: $errMsg" -ForegroundColor Red
        throw "[Error] $errMsg"
    }

    # 3) 检查 $Global:PSConfig 是否包含必需字段
    if (-not $Global:PSConfig -or -not ($Global:PSConfig -is [hashtable])) {
        Write-Host (Get-Message "common_ConfigMissingFields") -ForegroundColor Red
        throw (Get-Message "common_ConfigMissingFields")
    }
    if (-not $Global:PSConfig["sys_image_lib_dir"] -or -not $Global:PSConfig["new_wsl_install_dir"]) {
        Write-Host (Get-Message "common_ConfigMissingFields") -ForegroundColor Red
        throw (Get-Message "common_ConfigMissingFields")
    }

    # 4) Expand paths (相对于 proj_root)
    $expandedImageDir   = Expand-ProjectPath $Global:PSConfig["sys_image_lib_dir"]
    $expandedInstallDir = Expand-ProjectPath $Global:PSConfig["new_wsl_install_dir"]

    if ([string]::IsNullOrWhiteSpace($expandedImageDir) -or [string]::IsNullOrWhiteSpace($expandedInstallDir)) {
        Write-Host (Get-Message "common_PathIsEmpty") -ForegroundColor Red
        throw (Get-Message "common_PathIsEmpty")
    }

    # 5) 检查目录是否存在，若不存在可询问是否创建
    if (-not (Test-Path $expandedImageDir)) {
        Write-Host (Get-Message "common_DirNotExist" $expandedImageDir) -ForegroundColor Yellow
        $choice = Read-Host (Get-Message "common_PromptCreateDir")
        if ($choice -eq 'y') {
            New-Item -ItemType Directory -Path $expandedImageDir | Out-Null
            Write-Host (Get-Message "common_DirCreated" $expandedImageDir) -ForegroundColor Green
        }
        else {
            Write-Host (Get-Message "common_CannotProceed" $expandedImageDir) -ForegroundColor Red
            throw (Get-Message "common_CannotProceed" $expandedImageDir)
        }
    }

    if (-not (Test-Path $expandedInstallDir)) {
        Write-Host (Get-Message "common_DirNotExist" $expandedInstallDir) -ForegroundColor Yellow
        $choice = Read-Host (Get-Message "common_PromptCreateDir")
        if ($choice -eq 'y') {
            New-Item -ItemType Directory -Path $expandedInstallDir | Out-Null
            Write-Host (Get-Message "common_DirCreated" $expandedInstallDir) -ForegroundColor Green
        }
        else {
            Write-Host (Get-Message "common_CannotProceed" $expandedInstallDir) -ForegroundColor Red
            throw (Get-Message "common_CannotProceed" $expandedInstallDir)
        }
    }

    # 6) 组装 $scriptConfig 供后续脚本使用
    $global:scriptConfig = @{
        sys_image_lib_dir   = $expandedImageDir
        new_wsl_install_dir = $expandedInstallDir
    }

    # 7) 最终确认配置信息 (每次都确认)

    if (-not (Test-Path $initFile)) {
        Write-Host (Get-Message "common_PleaseConfirmConfig") -ForegroundColor Yellow
        Write-Host " - sys_image_lib_dir   = $expandedImageDir"
        Write-Host " - new_wsl_install_dir = $expandedInstallDir"
        $choice = Read-Host (Get-Message "common_PressYToContinue")
        
        if ($choice -eq 'y') {
            # 如果第一次确认，就创建 initFile
            if (-not (Test-Path $initFile)) {
                New-Item -ItemType File -Path $initFile -Force | Out-Null
                Write-Host (Get-Message "common_InitCompleted" $initFile) -ForegroundColor Green
            }
            else {
                Write-Host "Config is already confirmed (flag file exists)."
            }
        }
        else {
            Write-Host (Get-Message "common_OperationCancelled") -ForegroundColor Red
            throw (Get-Message "common_OperationCancelled")
        }
    }

}

###############################################################################
# 7. 调用 Initialize-Config
###############################################################################
Initialize-Config
# (可选) 显示最终配置信息。若你想多语言，这里也可以：
Write-Host (Get-Message "common_sys_image_lib_dir" $global:scriptConfig.sys_image_lib_dir) -ForegroundColor Green
Write-Host (Get-Message "common_new_wsl_install_dir" $global:scriptConfig.new_wsl_install_dir) -ForegroundColor Green


###############################################################################
# 8. 其他公共函数：WSL 相关等 (若需要多语言可自行改进)
###############################################################################
function Get-DistributionList {
    # 这里替换成你实际要使用的 JSON URL
    $jsonUrl = "https://ipzu.com/en/software/wsl/DistributionInfo.v2504.json"
    $jsonData = Invoke-RestMethod -Uri $jsonUrl
    $distributions = $jsonData.Distributions |
        Where-Object { $_.Name -and $_.Amd64PackageUrl } |
        Select-Object Name, @{Name='Url';Expression={$_.Amd64PackageUrl}}
    return $distributions
}

function Show-DistributionList {
    param(
        [Parameter(Mandatory=$true)]
        $DistributionInfo
    )
    # 示例: 如果要多语言化，请在 resources.ps1 中加一个键 "common_AvailableWslDistro"
    # Write-Host (Get-Message "common_AvailableWslDistro") -ForegroundColor Cyan
    Write-Host "`nAvailable WSL online distributions:" -ForegroundColor Cyan

    $DistributionInfo |
        Format-Table -AutoSize -Property Name, @{Name='Download URL';Expression={$_.Url}}
}

function Show-InstalledDistributions {
    Write-Host "`nList of installed WSL instances:" -ForegroundColor Cyan
    Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss\*" |
        Select-Object @{Name='DistributionName';Expression={$_.DistributionName}},
                       @{Name='BasePath';Expression={$_.BasePath}} |
        Format-Table -AutoSize
}

function PauseToMain {
    Write-Host (Get-Message "main_PressAnyKey") -ForegroundColor Cyan
    # Write-Host (Get-Message "common_PressAnyToContinue")

    # $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    [void][System.Console]::ReadKey()
}