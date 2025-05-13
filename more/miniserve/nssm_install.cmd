%~dp0nssm.exe  install  miniserve  "%~dp0miniserve.exe"  ". -p 443 -q -o -U  --tls-cert %~dp0..\_KEY\fio.inz.cc\crt.pem  --tls-key %~dp0..\_KEY\fio.inz.cc\key.pem  -u --"

pause