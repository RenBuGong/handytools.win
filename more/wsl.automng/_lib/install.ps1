# install.ps1

# 导入共用函数
. $PSScriptRoot\common.ps1

# 获取所有可用的镜像文件
function Get-AvailableImages {
    Get-ChildItem -Path $scriptConfig.sys_image_lib_dir -Filter "*.tar"
}

# 从镜像文件安装 WSL 实例（仅支持 .tar）
function Install-WslFromImage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ImagePath,
        [Parameter(Mandatory=$true)]
        [string]$DistroName
    )
    # 原来写死的提示: "Starting installation of WSL instance from image file: $DistroName"
    # 替换为:
    Write-Host (Get-Message "install_Starting" $DistroName)

    try {
        $installDir = Join-Path $scriptConfig.new_wsl_install_dir $DistroName
        New-Item -ItemType Directory -Force -Path $installDir | Out-Null
        wsl --import $DistroName $installDir $ImagePath

        Write-Host (Get-Message "install_Completed" $DistroName) -ForegroundColor Green
    }
    catch {
        # 同理替换
        Write-Host (Get-Message "install_Failed" $_) -ForegroundColor Red
        throw
    }
}

function Install-WslFromAvailableImage {
    $availableImages = Get-AvailableImages
    if ($availableImages.Count -eq 0) {
        Write-Host (Get-Message "install_NoTar") -ForegroundColor Yellow
        return
    }
    
    Write-Host (Get-Message "install_AvailableImgs") -ForegroundColor Cyan
    for ($i = 0; $i -lt $availableImages.Count; $i++) {
        Write-Host "$($i+1). $($availableImages[$i].Name)"
    }
    
    # 例如: "`nSelect an image to install (1-$($availableImages.Count)) or 'q' to return..."
    $prompt = (Get-Message "install_SelectPrompt" @($availableImages.Count,$scriptConfig.new_wsl_install_dir))
    $choice = Read-Host $prompt
    if ($choice -eq 'q') {
        return
    }
    $selectedImage = $availableImages[$choice - 1]
    
    $distroPrompt = (Get-Message "install_NewDistroPrompt")
    $distroName = Read-Host $distroPrompt
    if ($distroName -eq 'q') {
        return
    }
    Install-WslFromImage -ImagePath $selectedImage.FullName -DistroName $distroName
}

Install-WslFromAvailableImage
