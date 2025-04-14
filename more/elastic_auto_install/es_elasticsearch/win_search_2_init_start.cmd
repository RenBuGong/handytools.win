@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd

echo 初次运行 Elasticsearch
echo 1 本脚本, 会打印初始用户名(默认为elastic)与密码、及Kibana安装令牌(有效期30分钟), 请注意保存!!!
echo 2 正确启动(或后续修改密码/接口地址/证书…)后, 请也对应修改%ENV_FILE% 中的参数配置, 有些脚本需要它.
echo 2 正确启动(或后续修改密码/接口地址/证书…)后, 请也对应修改%ENV_FILE% 中的参数配置, 有些脚本需要它.
echo 2 正确启动(或后续修改密码/接口地址/证书…)后, 请也对应修改%ENV_FILE% 中的参数配置, 有些脚本需要它.
echo 3 待kibana安装好, 可终止本脚本, 然后将Elasticsearch 安装为后台服务.
echo 4 对于绑定的服务端口, 如果从其他机器访问, 注意防火墙放行!!
pause
echo 启动中, 请耐心等待...


CALL %SEARCH_SERVER_BIN%

pause