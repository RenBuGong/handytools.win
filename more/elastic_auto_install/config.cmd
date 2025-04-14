@ECHO OFF


SET "VER=8.15.3"





SET "ROOT_DIR=%~dp0"
SET "DATA_DIR=%ROOT_DIR%data"
SET "ENV_FILE=%ROOT_DIR%..env.cmd"
SET "LIB_DIR=%ROOT_DIR%lib"
SET "NSSMEXE=%ROOT_DIR%lib\nssm.exe"





:: elasticsearch
SET "SEARCH_ROOT=%ROOT_DIR%es_elasticsearch"
SET "SEARCH_DOWNLOAD_DIR=%SEARCH_ROOT%\download"
SET "SEARCH_TEMP_DIR=%SEARCH_ROOT%\download\temp.%VER%"
SET "SEARCH_DOWNLOAD_URL=https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-%VER%-windows-x86_64.zip"
SET "SEARCH_DOWNLOAD_ZIP=%SEARCH_DOWNLOAD_DIR%\elasticsearch-%VER%-windows-x86_64.zip"
SET "SEARCH_INSTALL_DIR=%SEARCH_ROOT%\%VER%"
SET "SEARCH_CONFIG_FILE=%SEARCH_INSTALL_DIR%\config\elasticsearch.yml"
SET "SEARCH_DATA_DIR=%DATA_DIR%\data.elasticsearch"
:: 关于配置文件具体的修改, 在 %ROOT_DIR%config.py SEARCH_CONFIG_PATCH
SET "SEARCH_SERVER_INSTALL_NAME=Elasticsearch-service-x64"
SET "SEARCH_SERVER_BIN=%SEARCH_INSTALL_DIR%\bin\elasticsearch.bat"
SET "SEARCH_SERVER_MNG=%SEARCH_INSTALL_DIR%\bin\elasticsearch-service.bat"
SET "SEARCH_SERVER_TOKEN_MNG=%SEARCH_INSTALL_DIR%\bin\elasticsearch-create-enrollment-token.bat"
SET "SEARCH_SERVER_LOG_DIR=%SEARCH_INSTALL_DIR%\logs"
::递归创建需要的目录
if not exist %SEARCH_DOWNLOAD_DIR% mkdir %SEARCH_DOWNLOAD_DIR%
if not exist %SEARCH_TEMP_DIR% mkdir %SEARCH_TEMP_DIR%




:: kibana
SET "KIBANA_ROOT=%ROOT_DIR%es_kibana"
SET "KIBANA_DOWNLOAD_DIR=%KIBANA_ROOT%\download"
SET "KIBANA_TEMP_DIR=%KIBANA_ROOT%\download\temp.%VER%"
SET "KIBANA_DOWNLOAD_URL=https://artifacts.elastic.co/downloads/kibana/kibana-%VER%-windows-x86_64.zip"
SET "KIBANA_DOWNLOAD_ZIP=%KIBANA_DOWNLOAD_DIR%\kibana-%VER%-windows-x86_64.zip"
SET "KIBANA_INSTALL_DIR=%KIBANA_ROOT%\%VER%"
SET "KIBANA_CONFIG_FILE=%KIBANA_INSTALL_DIR%\config\kibana.yml"
SET "KIBANA_DATA_DIR=%DATA_DIR%\data.kibana"
:: 关于配置文件具体的修改, 在 %ROOT_DIR%config.py KIBANA_CONFIG_PATCH
SET "KIBANA_SERVER_INSTALL_NAME=Elastic-kibana-service-x64"
SET "KIBANA_SERVER_BIN=%KIBANA_INSTALL_DIR%\bin\kibana.bat"
SET "KIBANA_SERVER_LOG_DIR=%KIBANA_INSTALL_DIR%\logs"
::递归创建需要的目录
if not exist %KIBANA_DOWNLOAD_DIR% mkdir %KIBANA_DOWNLOAD_DIR%
if not exist %KIBANA_TEMP_DIR% mkdir %KIBANA_TEMP_DIR%





:: logstash
SET "LOGSTASH_ROOT=%ROOT_DIR%es_logstash"
SET "LOGSTASH_DOWNLOAD_DIR=%LOGSTASH_ROOT%\download"
SET "LOGSTASH_TEMP_DIR=%LOGSTASH_ROOT%\download\temp.%VER%"
SET "LOGSTASH_DOWNLOAD_URL=https://artifacts.elastic.co/downloads/logstash/logstash-%VER%-windows-x86_64.zip"
SET "LOGSTASH_DOWNLOAD_ZIP=%LOGSTASH_DOWNLOAD_DIR%\logstash-%VER%-windows-x86_64.zip"
SET "LOGSTASH_INSTALL_DIR=%LOGSTASH_ROOT%\%VER%"
SET "LOGSTASH_CONFIG_FILE=%LOGSTASH_INSTALL_DIR%\config\logstash.yml"
SET "LOGSTASH_DATA_DIR=%DATA_DIR%\data.logstash"
:: 关于配置文件具体的修改, 在 %ROOT_DIR%config.py LOGSTASH_CONFIG_PATCH
SET "LOGSTASH_SERVER_INSTALL_NAME=Elastic-logstash-service-x64"
SET "LOGSTASH_SERVER_BIN=%LOGSTASH_INSTALL_DIR%\bin\logstash.bat"
SET "LOGSTASH_SERVER_LOG_DIR=%LOGSTASH_INSTALL_DIR%\logs"
if not exist %LOGSTASH_DOWNLOAD_DIR% mkdir %LOGSTASH_DOWNLOAD_DIR%
if not exist %LOGSTASH_TEMP_DIR% mkdir %LOGSTASH_TEMP_DIR%

SET "LOGSTASH_PIPELINE_YAML=%LOGSTASH_INSTALL_DIR%\config\pipelines.yml"
SET "LOGSTASH_PIPELINE_CONF_DIR=%DATA_DIR%\conf.logstash"
SET "LOGSTASH_PIPELINE_TAMPLATE_1_SYSLOG=%LIB_DIR%\logstash.syslog.514.conf"
SET "LOGSTASH_PIPELINE_CONIF_1_SYSLOG=%DATA_DIR%\conf.logstash\syslog.514.conf"
if not exist %LOGSTASH_PIPELINE_CONF_DIR% mkdir %LOGSTASH_PIPELINE_CONF_DIR%




:: elasticsearch crack
SET "SRARCH_LICENSE_TARG_JAR=%SEARCH_INSTALL_DIR%\modules\x-pack-core\x-pack-core-%VER%.jar"
SET "SRARCH_LEARNED_DIR=%SEARCH_TEMP_DIR%\elasticsearch-%VER%-learn"
SET "SRARCH_LEARNED_JAR=%SEARCH_TEMP_DIR%\x-pack-core-%VER%.learned.jar"
SET "SRARCH_LEARNED_LICENSE_JSON=%LIB_DIR%\learn.license.json"
SET "LICENSE_FILE_1_URL=https://raw.githubusercontent.com/elastic/elasticsearch/v%VER%/x-pack/plugin/core/src/main/java/org/elasticsearch/license/LicenseVerifier.java"
SET "LICENSE_FILE_1=%SEARCH_DOWNLOAD_DIR%\LicenseVerifier.java"
SET "LICENSE_FILE_1_LEARNED=%SEARCH_TEMP_DIR%\LicenseVerifier"
SET "LICENSE_FILE_2_URL=https://raw.githubusercontent.com/elastic/elasticsearch/v%VER%/x-pack/plugin/core/src/main/java/org/elasticsearch/xpack/core/XPackBuild.java"
SET "LICENSE_FILE_2=%SEARCH_DOWNLOAD_DIR%\XPackBuild.java"
SET "LICENSE_FILE_2_LEARNED=%SEARCH_TEMP_DIR%\XPackBuild"




CALL %ENV_FILE%