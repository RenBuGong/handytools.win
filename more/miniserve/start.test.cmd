chcp 65001 > nul
%~dp0miniserve.exe ./test -p 8896 -q -o -U  --tls-cert %~dp0wao.cc\cert.cer  --tls-key %~dp0wao.cc\private.key --index index.html  -u --

:: -p 端口
:: -q 显示二维码
:: -o 允许覆盖已存在的同名文件
:: -U 允许新建目录
:: -u 允许上传文件
pause