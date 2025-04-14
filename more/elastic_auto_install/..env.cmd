@echo off
:: 下列参数,务必根据 安装后实际情况 进行修订, 否则一些脚本无法运行.
SET "ELASTICSEARCH_USER=elastic"
SET "ELASTICSEARCH_PASS=I*V**gFw4Z1191sO99TJ"

:: 注意http 还是 https, 新版ES 基本是https
SET "ELASTICSEARCH_HOST=https://localhost:9200"
SET "ELASTICSEARCH_HTTP_CA_CRT=%SEARCH_INSTALL_DIR%\config\certs\http_ca.crt"

:: SET "ELASTICSEARCH_HTTP_CA_SHA_256=50407a0286e826dd8c36cae6452de522b31c452a1b1fe9561e1a4e393b3a5087"
SET "KIBANA_HOST=https://localhost:5601"


