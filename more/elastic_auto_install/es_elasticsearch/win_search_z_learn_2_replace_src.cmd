@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd


echo 学习相关模块的源代码.


:: 处理 LICENSE_FILE_1
if exist "%LICENSE_FILE_1_LEARNED%.java" del /f /q "%LICENSE_FILE_1_LEARNED%.java"
python %LIB_DIR%\learn_replace_src.py  %LICENSE_FILE_1%  LEARNED_1_SRC_LINE  LEARNED_1_BLOCK  %LICENSE_FILE_1_LEARNED%.java
python %LIB_DIR%\learn_replace_src.py  %LICENSE_FILE_1_LEARNED%.java  LEARNED_2_SRC_LINE  LEARNED_2_BLOCK  %LICENSE_FILE_1_LEARNED%.java

:: 处理 LICENSE_FILE_2
if exist "%LICENSE_FILE_2_LEARNED%.java" del /f /q "%LICENSE_FILE_2_LEARNED%.java"
python %LIB_DIR%\learn_replace_src.py  %LICENSE_FILE_2%  LEARNED_3_SRC_LINE  LEARNED_3_BLOCK  %LICENSE_FILE_2_LEARNED%.java





PAUSE