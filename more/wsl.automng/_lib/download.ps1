<#
.SYNOPSIS
下载并处理 WSL (Windows Subsystem for Linux) 发行版镜像文件。

.DESCRIPTION
本脚本用于下载指定的 WSL 发行版镜像，并进行必要的处理，最终生成可用于 WSL 导入的 .tar 文件。

流程：
1. 从给定 URL 下载 .appx / .AppxBundle 文件
2. 如果是 .AppxBundle，使用 Expand-AsZip 解压 -> 找到 x64/arm64对应的 .appx -> 交给 Process-Appx
3. 如果是 .appx，直接 Process-Appx
4. 在解压出来的文件中找 install.tar.gz 或 rootfs.tar.gz
5. 解压 .tar.gz 得到最终 .tar
6. 清理中间文件
7. 生成的 .tar 用于 wsl --import

.PARAMETER DistroName
指定要下载的 WSL 发行版名称。如果不提供，脚本将以交互方式进行选择。

.PARAMETER Force
若已存在同名 .tar 文件，是否强制覆盖。

.EXAMPLE
.\download.ps1
交互式下载并处理。

.EXAMPLE
.\download.ps1 -DistroName "Ubuntu-20.04" -Force
下载并处理 Ubuntu-20.04，若已存在对应.tar 则覆盖。

#>

param (
    [string]$DistroName,
    [switch]$Force
)

#------------------ 引用 common.ps1 ------------------
. $PSScriptRoot\common.ps1

#==============================================================
# 函数：Get-SystemArchitecture
#   获取当前系统的架构，返回 "x64" / "ARM64" / "x86"
#==============================================================
function Get-SystemArchitecture {
    if ([System.Environment]::Is64BitOperatingSystem) {
        if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) {
            return "ARM64"
        }
        else {
            return "x64"
        }
    }
    else {
        return "x86"
    }
}

#==============================================================
# 函数：Expand-AsZip
#   将文件(可能是 .AppxBundle 或 .appx)当作 zip 解压到目标目录
#==============================================================
function Expand-AsZip {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    Write-Host "[Expand-AsZip]" (Get-Message "download_ExpandAsZip" @($SourcePath, $DestinationPath))

    if (-not (Test-Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath | Out-Null
    }

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        [System.IO.Compression.ZipFile]::ExtractToDirectory($SourcePath, $DestinationPath)
        Write-Host "[Expand-AsZip]" (Get-Message "download_ExtractSucceeded") -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[Expand-AsZip]" (Get-Message "download_ExtractFailed" $_.Exception.Message) -ForegroundColor Red
        return $false
    }
}

#==============================================================
# 函数：Find-TarGz
#   在目录下查找 install.tar.gz 或 rootfs.tar.gz
#==============================================================
function Find-TarGz {
    param(
        [string]$RootPath
    )

    Write-Host "[Find-TarGz]" (Get-Message "download_FindTarGz" $RootPath)

    $installArchive = Get-ChildItem -Path $RootPath -Filter "install.tar.gz" -Recurse -ErrorAction SilentlyContinue |
                      Select-Object -First 1
    if (-not $installArchive) {
        $installArchive = Get-ChildItem -Path $RootPath -Filter "rootfs.tar.gz" -Recurse -ErrorAction SilentlyContinue |
                          Select-Object -First 1
    }

    if ($installArchive) {
        Write-Host "[Find-TarGz]" (Get-Message "download_FoundTarGz" $($installArchive.FullName)) -ForegroundColor Green
        return $installArchive.FullName
    }
    else {
        Write-Host "[Find-TarGz]" (Get-Message "download_NoTarGzFound") -ForegroundColor Yellow
        return $null
    }
}

#==============================================================
# 函数：Extract-GzipToTar
#   解压 .tar.gz => .tar
#==============================================================
function Extract-GzipToTar {
    param(
        [string]$GzPath
    )

    $tarPath = $GzPath -replace "\.gz$", ""
    Write-Host "[Extract-GzipToTar]" (Get-Message "download_ExtractGzip" @($GzPath, $tarPath))

    try {
        $inStream  = New-Object System.IO.FileStream($GzPath, 'Open', 'Read', 'Read')
        $outStream = New-Object System.IO.FileStream($tarPath, 'Create', 'Write', 'None')
        $gzStream  = New-Object System.IO.Compression.GzipStream($inStream, [IO.Compression.CompressionMode]::Decompress)

        $gzStream.CopyTo($outStream)
        $gzStream.Close()
        $outStream.Close()
        $inStream.Close()

        return $tarPath
    }
    catch {
        Write-Host "[Extract-GzipToTar]" (Get-Message "download_Failed" $_.Exception.Message) -ForegroundColor Red
        return $null
    }
}

#--------------------------------------------------------------
# 新增：函数 Process-AppxBundle
#   - 解压 .appxbundle -> 找到对应架构的 .appx -> 返回该 .appx 路径
#--------------------------------------------------------------
function Process-AppxBundle {
    param (
        [string]$downloadPath,
        [string]$extractDir,
        [string]$systemArchitecture
    )

    Write-Host (Get-Message "download_ProcessAppxBundle")
    $ok = Expand-AsZip -SourcePath $downloadPath -DestinationPath $extractDir
    if (-not $ok) {
        throw "[Process-AppxBundle] Failed to expand .AppxBundle as zip"
    }

    # 按架构挑选 *.appx
    $archFilter = switch ($systemArchitecture) {
        "x64"   { "*x64*.appx" }
        "ARM64" { "*arm64*.appx" }
        "x86"   { "*x86*.appx" }
        default { "*.appx" }
    }

    Write-Host (Get-Message "download_SearchAppxFilter" $archFilter)
    $allAppx = Get-ChildItem -Path $extractDir -Filter "*.appx" -Recurse -ErrorAction SilentlyContinue
    if (-not $allAppx) {
        throw (Get-Message "download_AppxBundleNoAppx")
    }

    # 优先选含架构的 appx；若没找到，则随便选一个
    $filteredAppx = $allAppx | Where-Object { $_.Name -like $archFilter } | Sort-Object Length -Descending
    if (-not $filteredAppx) {
        Write-Host "[Process-AppxBundle]" (Get-Message "download_NoArchMatch")
        $filteredAppx = $allAppx | Sort-Object Length -Descending
    }

    $mainAppx = $filteredAppx | Select-Object -First 1
    if (-not $mainAppx) {
        throw (Get-Message "download_AppxBundleNoAppx")
    }

    Write-Host "[Process-AppxBundle]" (Get-Message "download_AppxSelected" $($mainAppx.FullName))
    return $mainAppx.FullName
}

#--------------------------------------------------------------
# 新增：函数 Process-Appx
#   - 解压 .appx -> 找到 install.tar.gz 或 rootfs.tar.gz
#   - 解压 .tar.gz => .tar
#   - 移动到最终 .tar 路径
#   - 清理中间目录
#--------------------------------------------------------------
function Process-Appx {
    param (
        [string]$appxPath,
        [string]$finalTarPath
    )

    Write-Host (Get-Message "download_ProcessAppx")
    $parentDir  = Split-Path $appxPath -Parent
    $extractDir = Join-Path $parentDir ("Extracted_" + ([System.IO.Path]::GetFileNameWithoutExtension($appxPath)))

    if (Test-Path $extractDir) {
        Remove-Item -Path $extractDir -Recurse -Force
    }

    $ok = Expand-AsZip -SourcePath $appxPath -DestinationPath $extractDir
    if (-not $ok) {
        throw "[Process-Appx] Failed to expand .appx as zip"
    }

    $tarGz = Find-TarGz -RootPath $extractDir
    if (-not $tarGz) {
        throw (Get-Message "download_NoTarGzFound")
    }

    $finalTar = Extract-GzipToTar -GzPath $tarGz
    if (-not $finalTar) {
        throw "[Process-Appx] Failed to decompress .tar.gz -> .tar"
    }

    Move-Item -Path $finalTar -Destination $finalTarPath -Force
    Write-Host (Get-Message "download_TarCreated" $finalTarPath) -ForegroundColor Green

    Write-Host (Get-Message "download_Cleanup" $extractDir)
    Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue
}

#==============================================================
# 主逻辑函数：Save-WslImage
#==============================================================
function Save-WslImage {
    param (
        [string]$DistroName,
        [switch]$Force
    )

    $systemArchitecture = Get-SystemArchitecture
    Write-Host (Get-Message "download_SystemArch" $systemArchitecture)

    # 1. 获取可用发行版信息
    $distributions = Get-DistributionList
    if (-not $DistroName) {
        Show-DistributionList $distributions
        $DistroName = Read-Host (Get-Message "download_EnterDistroPrompt" $scriptConfig.sys_image_lib_dir)
        if ($DistroName -eq 'q') {
            Write-Host (Get-Message "download_Cancelled") -ForegroundColor Yellow
            return
        }
    }

    # 在 Distributions 中查找
    $selectedDistro = $distributions | Where-Object { $_.Name -eq $DistroName }
    if (-not $selectedDistro) {
        Write-Host (Get-Message "download_DistroNotFound" $DistroName) -ForegroundColor Red
        return
    }

    $downloadUrl = $selectedDistro.Url
    Write-Host (Get-Message "download_DistributionName" $DistroName)
    Write-Host (Get-Message "download_Url" $downloadUrl)

    # 2. 构建下载路径、最终 tar 路径
    $fileName      = "Downloaded_$([System.IO.Path]::GetFileName($downloadUrl))"
    $downloadPath  = Join-Path $scriptConfig.sys_image_lib_dir $fileName
    $finalTarPath  = Join-Path $scriptConfig.sys_image_lib_dir ("$fileName.tar")

    Write-Host (Get-Message "download_PathDownload" $downloadPath)
    Write-Host (Get-Message "download_PathFinalTar" $finalTarPath)

    # 如果 .tar 已存在，未指定 -Force 则询问
    if ((Test-Path $finalTarPath) -and (-not $Force)) {
        if ($PSBoundParameters.ContainsKey('DistroName')) {
            Write-Host (Get-Message "download_FileExists" $finalTarPath) -ForegroundColor Yellow
            return
        }
        else {
                # 交互式
            $choice = Read-Host (Get-Message "download_FileExists" $finalTarPath)
            if ($choice -notin @('Y','y')) {
                Write-Host (Get-Message "download_Cancelled") -ForegroundColor Yellow
                return
            }
        }
    }

    # 确保目录存在
    if (-not (Test-Path $scriptConfig.sys_image_lib_dir)) {
        New-Item -ItemType Directory -Force -Path $scriptConfig.sys_image_lib_dir | Out-Null
    }

    # 3. 执行下载
    Write-Host (Get-Message "download_StartDownload")
    try {
        $bitsCmd = Get-Command -Name "Start-BitsTransfer" -ErrorAction SilentlyContinue
        if ($bitsCmd) {
            # Write-Host "[Save-WslImage] Using Start-BitsTransfer ..."
            Start-BitsTransfer -Source $downloadUrl -Destination $downloadPath -Description "Downloading $DistroName"
        }
        else {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
        }
        Write-Host (Get-Message "download_DownloadCompleted") -ForegroundColor Green
    }
    catch {
        Write-Host (Get-Message "download_DownloadFailed" $_.Exception.Message) -ForegroundColor Red
        return
    }

    # 4. 解包逻辑
    try {
        $fileExt    = [System.IO.Path]::GetExtension($downloadPath).ToLower()
        $parentDir  = Split-Path $downloadPath -Parent

        # 解压目录：与下载文件同级，方便查看.
        $extractDir = Join-Path $parentDir ("Extracted_" + ([System.IO.Path]::GetFileNameWithoutExtension($downloadPath)))

        if (Test-Path $extractDir) {
            Remove-Item -Path $extractDir -Recurse -Force
        }

        switch ($fileExt) {
            ".appxbundle" {
                # 1) 处理 AppxBundle
                $appxPath = Process-AppxBundle -downloadPath $downloadPath -extractDir $extractDir -systemArchitecture $systemArchitecture

                # 2) 处理生成的 .appx
                Process-Appx -appxPath $appxPath -finalTarPath $finalTarPath

                # 清理 .appxbundle 解压目录
                Write-Host (Get-Message "download_Cleanup" $extractDir)
                Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue

                Write-Host (Get-Message "download_Done") -ForegroundColor Green
                return
            }
            ".appx" {
                Write-Host (Get-Message "download_AppxDetected")
                # 直接处理 .appx
                Process-Appx -appxPath $downloadPath -finalTarPath $finalTarPath

                Write-Host (Get-Message "download_Done") -ForegroundColor Green
                return
            }
        #---------------------------------
        # 如果既不是 .appx 也不是 .appxbundle
        #---------------------------------
            default {
                throw (Get-Message "download_UnsupportedFormat" $fileExt)
            }
        }
    }
    catch {
        # 如果有多语言的报错，可以这里统一捕获 
        Write-Host (Get-Message "download_Failed" $_.Exception.Message) -ForegroundColor Red
    }
}

#========================
# 脚本入口
#========================
Save-WslImage @PSBoundParameters
