chcp 65001 > nul
%~dp0miniserve.exe c:\ -p 443 -q -o -U  --tls-cert %~dp0..\_KEY\fio.inz.cc\crt.pem  --tls-key %~dp0..\_KEY\fio.inz.cc\key.pem  -u --
:: -p 端口
:: -q 显示二维码
:: -o 允许覆盖已存在的同名文件
:: -U 允许新建目录
:: -u 允许上传文件
pause
