@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd


echo 生成 kibana 注册令牌.
echo 文档: https://www.elastic.co/guide/en/elasticsearch/reference/current/zip-windows.html#windows-running
echo.
pause



CALL %SEARCH_SERVER_TOKEN_MNG%  -s  kibana



pause
