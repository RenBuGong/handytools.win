@echo off
rem === 找到 git-bash.exe 的路径（你也可以写死）===
set "GITBASH=%ProgramFiles%\Git\git-bash.exe"
if not exist "%GITBASH%" (
    echo 未找到 git-bash.exe，请手动修改 GITBASH 变量。
    pause
    exit /b 1
)

rem === 创建文件类型 shfile，并指定执行器 ===
ftype shfile="\"%GITBASH%\"" --login -c "\"%1\" %*"
rem === 把 .sh 扩展名关联到 shfile ===
assoc .sh=shfile

echo 关联完成！以后雙擊 .sh 就直接跑 Git Bash 了。
pause
