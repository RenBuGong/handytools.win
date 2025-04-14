@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd



echo 启动Logstash查看是否会有异常.
echo 如果一切正常可停止本脚本,然后将Logstash安装为后台服务.
echo 对于绑定的服务端口(包括pipeline配置的), 如果从其他机器访问, 注意防火墙放行!!
echo.
pause
echo 启动中, 请耐心等待...


CALL %LOGSTASH_SERVER_BIN%



pause