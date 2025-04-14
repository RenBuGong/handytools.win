# adduser.ps1

. "$PSScriptRoot\common.ps1"   # 加载多语言功能 & 其他公用函数

function Set-WslDefaultUser {

    # 获取用户输入
    $distroName = Read-Host (Get-Message "adduser_EnterDistro")
    if ($distroName -eq 'q') {return}
    $username   = Read-Host (Get-Message "adduser_EnterUsername")
    if ($username -eq 'q') {return}
    $password   = Read-Host (Get-Message "adduser_EnterPassword")
    if ($password -eq 'q') {return}

    # 从 PowerShell 获取当前语言标识；也可做简单映射，如 "zh-CN" or "en-US"
    $psLang = $PSCulture  

    try {
        # 调用 WSL 内的 add_user.sh 并传入 username/password/语言
        # 注意：你需要在对应的 WSL 实例根目录或某个路径放置 add_user.sh
        #       如果脚本位置不在 ~，可先复制脚本或使用相对路径
        wsl -d $distroName -u root bash -c "./adduser.sh '$username' '$password' '$psLang'"

        # 如果上一步执行成功，我们再执行 wsl --shutdown
        # 也可以把 wsl --shutdown 放在 Bash 脚本内部调用，这取决于你的设计
        # wsl --shutdown

        Write-Host (Get-Message "adduser_UserCreated" $username) -ForegroundColor Green
        Write-Host (Get-Message "adduser_LoginInfo"   @($distroName, $username)) -ForegroundColor Cyan
    }
    catch {
        Write-Host (Get-Message "adduser_Error" $_) -ForegroundColor Red
    }
}

# 运行函数
Set-WslDefaultUser

