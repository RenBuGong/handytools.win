@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd


echo 检查 %ELASTICSEARCH_HOST% 运行情况.
echo 需确保 %ENV_FILE% 中已填写了Elasticsearch 账号密码.
echo 返回的信息中有 "status":"green" 表示运行状态ok.
echo.
pause



curl -k --cacert %SEARCH_INSTALL_DIR%\config\certs\http_ca.crt -u %ELASTICSEARCH_USER%:%ELASTICSEARCH_PASS%  %ELASTICSEARCH_HOST%/_cluster/health




echo.
pause
