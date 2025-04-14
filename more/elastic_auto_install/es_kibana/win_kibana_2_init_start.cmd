@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd



echo 初次运行 kibana
echo 1 本脚本会在命令行终端, 生成一个唯一链接(用浏览器打开), 它用于将Kibana 注册到Elasticsearch.
echo 2 打开连接后的注册与登录, 需使用Elasticsearch 初次启动时, 命令行终端生成的kibana注册令牌、用户名(例如elastic)和密码.
echo 3 如果一切正常,可停止本脚本, 然后将Kibana安装为后台服务.
echo 4 如果后续修改了接口地址, 请也对应修改%ENV_FILE% 中的参数配置, 有些脚本需要它.
echo 5 对于绑定的服务端口, 如果从其他机器访问, 注意防火墙放行!!
echo 官方文档: https://www.elastic.co/guide/en/kibana/current/windows.html
echo.
pause
echo 启动中, 请耐心等待...


CALL %KIBANA_SERVER_BIN%

pause