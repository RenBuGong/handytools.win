@echo off
chcp 65001 > nul
CALL %~dp0..\config.cmd



echo 1 编译学习过的.java 源代码, 输出.class 文件.
if exist "%LICENSE_FILE_1_LEARNED%.class" del /f /q "%LICENSE_FILE_1_LEARNED%.class"
if exist "%LICENSE_FILE_2_LEARNED%.class" del /f /q "%LICENSE_FILE_2_LEARNED%.class"
:: -cp 设置类路径的分隔符在 Windows下使用 ;  Linux下使用 :
%SRARCH_LEARNED_DIR%\jdk\bin\javac  -cp "%SRARCH_LEARNED_DIR%/lib/*;%SRARCH_LEARNED_DIR%/modules/x-pack-core/*"  %LICENSE_FILE_1_LEARNED%.java
%SRARCH_LEARNED_DIR%\jdk\bin\javac  -cp "%SRARCH_LEARNED_DIR%/lib/*;%SRARCH_LEARNED_DIR%/modules/x-pack-core/*"  %LICENSE_FILE_2_LEARNED%.java -Xlint:-options
echo.



echo 2 解压原始 x-pack-core 模块包...
:: 解压xpack jar 模块文件 (linux 下使用 unzip x.jar -d /path/to/dir).
if exist "%SEARCH_TEMP_DIR%\x-pack-core-%VER%" rd /s /q "%SEARCH_TEMP_DIR%\x-pack-core-%VER%"
md %SEARCH_TEMP_DIR%\x-pack-core-%VER%
tar -xf "%SRARCH_LEARNED_DIR%\modules\x-pack-core\x-pack-core-%VER%.jar" -C %SEARCH_TEMP_DIR%\x-pack-core-%VER%
echo.



echo 3 复制学习好的.class 文件, 替换到解压解压目录, 重新打包...
copy /Y %LICENSE_FILE_1_LEARNED%.class  %SEARCH_TEMP_DIR%\x-pack-core-%VER%\org\elasticsearch\license\
copy /Y %LICENSE_FILE_2_LEARNED%.class  %SEARCH_TEMP_DIR%\x-pack-core-%VER%\org\elasticsearch\xpack\core\
if exist "%SRARCH_LEARNED_JAR%" del /f /q "%SRARCH_LEARNED_JAR%"
%SRARCH_LEARNED_DIR%\jdk\bin\jar cf %SRARCH_LEARNED_JAR% -C %SEARCH_TEMP_DIR%\x-pack-core-%VER%\ .
echo.

echo 4 学习好的x-pack-core 包, 已生成: %SRARCH_LEARNED_JAR%
echo.


PAUSE