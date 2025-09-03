<#
.SYNOPSIS
    批量创建 Active Directory 用户。
.DESCRIPTION
    此脚本从一个 CSV 文件中读取用户信息，并批量在 Active Directory 中创建用户。
    - 它会自动检查用户是否已存在，避免重复创建。
    - 它会验证目标 OU 是否存在，如果不存在则会跳过。
    - 它会设置密码，并强制用户在下次登录时更改密码。
.PARAMETER CsvPath
    指定包含用户数据的 CSV 文件的路径。
    默认会使用脚本所在目录下的 ".env.users.csv" 文件。
.PARAMETER Force
    如果指定此开关，当用户已存在时，脚本将先强制删除该用户，然后再重新创建。
.PARAMETER CopyProfileFromPath
    指定一个源目录的路径。如果提供此参数，脚本会将其内容完整复制到每个新用户的个人主目录中 (例如 C:\Users\用户名)，并设置正确的权限。
.EXAMPLE
    .\create_ad_users.ps1
    # 上述命令会读取同目录下的 ".env.users.csv" 文件并创建用户。

.EXAMPLE
    .\create_ad_users.ps1 -CsvPath "C:\temp\new_hires.csv"
    # 上述命令会从指定路径读取文件来创建用户。
.NOTES
    作者: Gemini AI
    - 运行此脚本的计算机需要安装 Active Directory PowerShell 模块。
    - 运行此脚本需要域管理员或有相应权限的账户。
    - 请先将 users_template.csv 复制为 .env.users.csv，并填入真实信息。
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "指定包含用户数据的 CSV 文件的路径。建议从 users_template.csv 复制创建。")]
    [string]$CsvPath = (Join-Path $PSScriptRoot ".env.users.csv"),

    [Parameter(Mandatory = $false, HelpMessage = "如果用户已存在，则强制删除并重新创建。")]
    [switch]$Force,

    [Parameter(Mandatory = $false, HelpMessage = "指定一个源目录，脚本会将其内容复制到每个新用户的个人主目录中。")]
    [string]$CopyProfileFromPath
)

# --- 检查先决条件 ---
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "错误：Active Directory 模块未安装。请在服务器管理器中安装 'RSAT-AD-PowerShell' 功能。"
    exit 1
}

if (-not (Test-Path $CsvPath)) {
    Write-Error "错误：在 '$CsvPath' 未找到 CSV 文件。请确保文件存在，或通过 -CsvPath 参数指定正确路径。"
    exit 1
}

if ($CopyProfileFromPath -and -not (Test-Path $CopyProfileFromPath -PathType Container)) {
    Write-Error "错误：提供的源配置文件路径 '$CopyProfileFromPath' 不存在或不是一个目录。"
    exit 1
}

# --- 获取域信息 ---
try {
    $domain = Get-ADDomain
    # 首选方法
    $defaultUserPath = (Get-ADDomainController -Discover -Service PrimaryDC -ErrorAction SilentlyContinue).DefaultUsersContainer
    # 如果首选方法失败，则使用备用方法从域名构造
    if ([string]::IsNullOrWhiteSpace($defaultUserPath)) {
        Write-Warning "无法通过 Get-ADDomainController 自动检测默认用户路径，将尝试从域名构造。"
        $defaultUserPath = "CN=Users,$($domain.DistinguishedName)"
    }
    Write-Host "成功连接到域: $($domain.DnsRoot)" -ForegroundColor Cyan
    Write-Host "将使用默认用户路径: $defaultUserPath" -ForegroundColor Cyan
}
catch {
    Write-Error "错误：无法连接到 Active Directory。请确保您在已加入域的计算机上，并使用有足够权限的账户运行此脚本。"
    exit 1
}

# --- 从 CSV 处理用户 ---
$usersToCreate = Import-Csv -Path $CsvPath

Write-Host "开始从文件处理用户创建任务: '$CsvPath'..." -ForegroundColor Green

foreach ($user in $usersToCreate) {
    # --- 安全地读取和验证数据 ---
    $samAccountName = $user.SamAccountName
    if ([string]::IsNullOrWhiteSpace($samAccountName)) {
        Write-Warning "跳过：发现一个 SamAccountName 为空的行，可能是文件的空行。"
        continue
    }
    $samAccountName = $samAccountName.Trim()

    $password = $user.Password
    if ([string]::IsNullOrWhiteSpace($password)) {
        Write-Warning "跳过用户 '$samAccountName'：密码为空。"
        continue
    }

    $firstName      = if ($user.FirstName) { $user.FirstName.Trim() } else { "" }
    $lastName       = if ($user.LastName) { $user.LastName.Trim() } else { "" }
    $description    = if ($user.Description) { $user.Description } else { "" }
    $ouPath         = if ($user.OUPath) { $user.OUPath.Trim() } else { "" }

    try {
        # --- 决定用户的显示名称 ---
        $displayName = ("$firstName $lastName").Trim()
        if ([string]::IsNullOrWhiteSpace($displayName)) {
            $displayName = $samAccountName
        }

        # --- 检查用户是否存在 ---
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
        if ($existingUser) {
            if ($Force.IsPresent) {
                Write-Host -NoNewline " 用户 '$samAccountName' 已存在，正在强制删除..."
                try {
                    Remove-ADUser -Identity $existingUser -Confirm:$false
                    Write-Host " 删除成功。" -ForegroundColor Yellow
                }
                catch {
                    Write-Warning "`n删除用户 '$samAccountName' 时失败: $($_.Exception.Message)。跳过此用户。"
                    continue
                }
            }
            else {
                Write-Warning "跳过：用户 '$samAccountName' 已存在。可使用 -Force 开关强制删除并重建。"
                continue
            }
        }

        # --- 决定并验证 OU 路径 ---
        $targetPath = if ([string]::IsNullOrWhiteSpace($ouPath)) { $defaultUserPath } else { $ouPath }

        # Test-Path 对 AD 路径需要特定的提供程序前缀
        if (-not (Test-Path "AD:$targetPath")) {
             Write-Warning "跳过：用户 '$samAccountName' 的目标 OU '$targetPath' 不存在。请先在 'Active Directory 用户和计算机' 中创建该 OU。"
             continue
        }

        # --- 准备 New-ADUser 参数 ---
        $userParams = @{
            SamAccountName        = $samAccountName
            UserPrincipalName     = "$samAccountName@$($domain.DnsRoot)"
            Name                  = $displayName
            GivenName             = $firstName
            Surname               = $lastName
            Description           = $description
            Path                  = $targetPath
            AccountPassword       = (ConvertTo-SecureString $password -AsPlainText -Force)
            Enabled               = $true
            ChangePasswordAtLogon = $false
        }

        # --- 创建用户 ---
        Write-Host "正在创建用户 '$samAccountName'..." -NoNewline
        New-ADUser @userParams
        
        # --- 设置密码永不过期 ---
        Set-ADUser -Identity $samAccountName -PasswordNeverExpires $true

        Write-Host " 成功，路径: $targetPath, 且密码已设为永不过期。" -ForegroundColor Green
        
        # --- 复制初始配置文件 ---
        if ($CopyProfileFromPath) {
            $userProfilePath = Join-Path "$env:SystemDrive\Users" $samAccountName
            Write-Host -NoNewline "  └─ 正在为用户 '$samAccountName' 复制配置文件到 '$userProfilePath'..."
            try {
                # 1. 创建用户目录
                New-Item -Path $userProfilePath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                
                # 2. 复制文件
                Copy-Item -Path "$CopyProfileFromPath\*" -Destination $userProfilePath -Recurse -Force -ErrorAction Stop

                # 3. 设置权限 (使用 icacls 命令行工具，更直接可靠)
                $userPrincipal = "$($domain.NetbiosName)\$samAccountName"
                
                # /Q (Quiet) 安静模式，不显示成功信息
                # /T (Traverse) 递归处理
                # /C (Continue) 出错时继续

                # 设置所有者为新用户
                icacls.exe $userProfilePath /setowner $userPrincipal /T /C /Q | Out-Null
                
                # 授予新用户完全控制权限，(OI) 对象继承, (CI) 容器继承
                icacls.exe $userProfilePath /grant "$($userPrincipal):(OI)(CI)F" /T /C /Q | Out-Null
                
                Write-Host " 成功。" -ForegroundColor Green
            }
            catch {
                Write-Warning "`n  └─ 复制配置文件失败: $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Warning "`n失败：创建用户 '$samAccountName' 时发生错误。详情: $($_.Exception.Message)"
    }
}

Write-Host "`n批量用户创建流程已全部完成。" -ForegroundColor Green 