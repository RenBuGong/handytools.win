@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd


echo 生成, 集群新增节点, 需要的, 注册令牌.
echo 获取, 然后在新节点的安装根目录中执行: bin\elasticsearch --enrollment-token '生成的令牌'
echo 如果要加入的节点是其他机器, 需要配置文件中修改(或添加)字段值: "transport.host": "0.0.0.0"
echo 具体文档: https://www.elastic.co/guide/en/elasticsearch/reference/current/zip-windows.html#windows-running
echo.
pause


CALL %SEARCH_SERVER_TOKEN_MNG% -s node



pause
