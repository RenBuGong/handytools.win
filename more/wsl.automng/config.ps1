# config.ps1
#
# 这是一个示例的配置脚本文件，用于保存配置数据。
# 在此你可以编写注释，也可以定义更多变量或逻辑。
# 注意：我们会在 common.ps1 中使用 `. $configFile` 方式加载该文件。
#
# 建议定义一个全局变量 $PSConfig (也可命名其它名称)，以哈希表形式保存所有配置。
# 这里面的路径既可写成绝对路径，也可写相对于 proj_root 的相对路径。

# 全局变量命名示例
$Global:PSConfig = @{
    # 如果写相对路径，比如 "images"，将被视为相对于 config.ps1 所在目录的路径。
    # 如果写绝对路径，如 "D:\MyImages"，则不做拼接。
    "sys_image_lib_dir"   = "images"  # 发行版系统镜像下载、或备份镜像的存储目录
    "new_wsl_install_dir" = "$env:USERPROFILE\WSL"  # wsl新增实例的安装目录
}
