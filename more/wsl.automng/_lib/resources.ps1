# resources.ps1
# 这里定义一个大哈希表 $Messages，外层 key 是语言标识（如 zh-CN, en-US），
# 内层 key 是消息标识（如 adduser_EnterDistro, backup_ExportWslPrompt 等）。
# 值则是要显示的文本字符串。

$Messages = @{
    "zh-CN" = @{
        # -----------------------------------------
        # common.ps1
        # -----------------------------------------
        "common_sys_image_lib_dir"    = "镜像库存储目录：{0}"
        "common_new_wsl_install_dir"  = "新实例安装目录：{0}"
        "common_PressAnyToContinue"   = "按任意键继续..."
        
        # 针对 Initialize-Config 的多语言提示
        "common_FirstRun"             = "(较老的win系统,可能要先手动打开WSL功能,方法请查看:https://ipzu.com/zh-cn/software/wsl/practical/ `n`n使用前,请先查看/定义配置文件 config.ps1 `n按任意键将继续..."
        "common_ConfigNotFound"       = "在路径 {0} 未找到 config.ps1。"
        "common_PleaseCreateConfig"   = "请创建或放置一个有效的 config.ps1 后再重试。"
        "common_ConfigMissingFields"  = "PSConfig 缺少必需字段:sys_image_lib_dir 或 new_wsl_install_dir。"
        "common_PathIsEmpty"          = "展开后的目录路径为空，请检查 config.ps1。"
        "common_DirNotExist"          = "目录不存在：{0}"
        "common_PromptCreateDir"      = "是否现在创建此目录？(y/n)"
        "common_DirCreated"           = "已创建目录：{0}"
        "common_CannotProceed"        = "无法继续操作，缺失目录：{0}"
        "common_PleaseConfirmConfig"  = "请确认你的 config.ps1 配置如下："
        "common_PressYToContinue"     = "按 'y' 确认并继续 (y/n)"
        "common_InitCompleted"        = "初始化完成，已创建标志文件：{0}"
        "common_OperationCancelled"   = "操作已取消，请先修正 config.ps1 后再重试。"

        # backup.ps1 相关
        "backup_ExportWslPrompt"   = "请输入要导出的WSL 实例名称(当前存储目录为{0}) 或输入 'q' 返回主菜单"
        "backup_ExportWslStarting" = "开始导出 WSL 实例：{0} 到 {1}"
        "backup_ExportWslCompleted"= "WSL 实例导出完成：{0}"
        "backup_ExportWslFailed"   = "导出失败：{0}"

        # 如果 adduser.ps1 或者其他脚本需要多语言提示，也放这里
        "adduser_EnterDistro"       = "请输入发行版名称(或 'q' 返回主菜单)"
        "adduser_EnterUsername"     = "请输入用户名(或 'q' 返回主菜单)"
        "adduser_EnterPassword"     = "请输入密码(或 'q' 返回主菜单)"
        "adduser_UserCreated"       = "`n默认用户已设置为 '{0}'，请重启 WSL。"
        "adduser_LoginInfo"         = "现在可以使用以下命令登录: wsl -d {0} -u {1}"
        "adduser_Error"             = "错误: {0}"

        # ====== download.ps1 相关 ======
        "download_EnterDistroPrompt"  = "请输入要下载的发行版名称(当前存储目录为{0})或输入 'q' 返回主菜单"
        "download_Cancelled"          = "[Save-WslImage] 已取消操作。"
        "download_DistroNotFound"     = "[Save-WslImage] 未找到发行版：{0}"
        "download_DistributionName"   = "[Save-WslImage] 发行版: {0}"
        "download_Url"                = "[Save-WslImage] 下载链接: {0}"
        "download_PathDownload"       = "[Save-WslImage] 下载路径: {0}"
        "download_PathFinalTar"       = "[Save-WslImage] 最终 .tar 路径: {0}"
        "download_FileExists"         = "[Save-WslImage] {0} 已存在。使用 -Force 可覆盖，或按 'Y' 确认。"
        "download_StartDownload"      = "[Save-WslImage] 开始下载..."
        "download_DownloadCompleted"  = "[Save-WslImage] 下载完成。"
        "download_DownloadFailed"     = "[Save-WslImage] 下载失败: {0}"
        "download_UnsupportedFormat"  = "[Save-WslImage] 不支持的文件格式: {0}"
        "download_AppxBundleDetected" = "[Save-WslImage] 检测到 .AppxBundle。正在解压..."
        "download_AppxBundleNoAppx"   = "[Save-WslImage] 未在 .AppxBundle 中找到 .appx 文件。"
        "download_AppxDetected"       = "[Save-WslImage] 检测到 .appx。正在解压..."
        "download_NoTarGzFound"       = "[Save-WslImage] 未在 .appx 中找到 install.tar.gz 或 rootfs.tar.gz。"
        "download_TarCreated"         = "[Save-WslImage] 已生成最终 TAR: {0}"
        "download_Cleanup"            = "[Save-WslImage] 清理临时目录: {0}"
        "download_Done"               = "[Save-WslImage] 处理完成。"
        "download_Failed"             = "[Save-WslImage] 失败: {0}"
        "download_SystemArch"         = "[Save-WslImage] 系统架构: {0}"

        # ====== 新增用于处理 .appxbundle 和 .appx 的提示 ======
        "download_ProcessAppxBundle"  = "正在处理 .AppxBundle 文件..."
        "download_SearchAppxFilter"   = "按过滤条件查找 .appx: {0}"
        "download_NoArchMatch"        = "未找到适配该架构的 .appx, 尝试使用其他 .appx ..."
        "download_AppxSelected"       = "已选中的 .appx => {0}"
        "download_ExpandAsZip"        = "当作 zip 解压: {0} -> {1}"
        "download_ExtractSucceeded"   = "解压成功。"
        "download_ExtractFailed"      = "解压失败：{0}"
        "download_FindTarGz"          = "查找 install.tar.gz 或 rootfs.tar.gz 于 {0}"
        "download_FoundTarGz"         = "找到 tar.gz => {0}"
        "download_ExtractGzip"        = "解压 Gzip: {0} -> {1}"

        # ------------------ show_help.ps1 ------------------
        "help_Title"             = "`nWSL2 子系统使用帮助"
        "help_CommonCommands"    = "常用 WSL 命令："
        "help_cmd_wsl_l_v"       = "  wsl -l -v                    : 列出已安装的发行版"
        "help_cmd_wsl_d"         = "  wsl -d <发行版名>             : 启动指定的发行版"
        "help_cmd_wsl_shutdown"  = "  wsl --shutdown               : 关闭所有正在运行的发行版"
        "help_cmd_wsl_unreg"     = "  wsl --unregister <发行版名>   : 注销/卸载指定发行版"
        "help_cmd_wsl_setdef"    = "  wsl --set-default <发行版名>  : 设置默认发行版"
        "help_cmd_wsl_status"    = "  wsl --status                 : 显示 WSL 状态"
        "help_cmd_wsl_update"    = "  wsl --update                 : 更新 WSL"
        "help_PortForwardTitle"  = "端口转发命令："
        "help_PortForwardCmd"    = "  netsh interface portproxy add v4tov4 listenport=<外部端口> connectaddress=<WSL_IP> connectport=<内部端口>"
        "help_PortForwardExample"= "  示例: netsh interface portproxy add v4tov4 listenport=80 connectaddress=172.17.xxx.xxx connectport=80"
        "help_FirewalldTitle"    = "防火墙放行命令:"
        "help_FirewalldCmd"      = "  netsh advfirewall firewall add rule name=<you_rule_name> protocol=<TCP|UDP> dir=in localport=<rule_local_port> action=allow"
        "help_FirewalldExample"  = "  示例: netsh advfirewall firewall add rule name='WSL2-SSH' protocol=TCP dir=in localport=22 action=allow"

        "help_MoreInfo"          = "`n更多信息请参阅: https://ipzu.com/zh-cn/software/wsl/practical/"


        # ------------------ install.ps1 ------------------
        "install_Starting"       = "开始安装新的 WSL 实例: {0}"
        "install_Completed"      = "WSL 实例安装完成: {0}"
        "install_Failed"         = "安装失败: {0}"
        
        "install_NoTar"          = "镜像库目录中未找到可用的 .tar 镜像。"
        "install_AvailableImgs"  = "`n可用镜像列表: "
        "install_SelectPrompt"   = "`n请选择要安装的镜像 (1-{0}) (当前安装目录为{1}) 或输入 'q' 返回主菜单"
        "install_NewDistroPrompt"= "请输入新发行版名称 (或 'q' 返回主菜单)"

        
        # ------------------ main.ps1 ------------------
        "main_Title"           = "`n========================================================`n自动化管理 WSL`n作者: ipzu.com`n当前版本: 2025.4.2`n文档: https://ipzu.com/zh-cn/software/wsl/automng`n========================================================`n`n菜单选项:"
        "main_MenuS"           = "S. 显示已安装的实例"
        "main_MenuD"           = "D. 下载镜像"
        "main_MenuC"           = "C. 从当前实例创建备份镜像"
        "main_MenuI"           = "I. 还原或安装新实例"
        "main_MenuU"           = "U. 设置 WSL 实例的默认用户"
        "main_MenuR"           = "R. 删除一个实例"
        "main_MenuM"           = "M. 迁移安装位置"
        "main_MenuH"           = "H. 查看 WSL2 使用帮助"
        "main_MenuE"           = "E. 退出"
        "main_SelectPrompt"    = "`n请选择一个操作 (S/D/C/I/U/R/M/H/1/2/3/4/E)"
        "main_PressAnyKey"     = "`n按任意键返回主菜单..."
        "main_InvalidChoice"    = "无效的选择，请重试。"
        "main_Menu1"           = "1. 启用用户登录时自动运行指定 WSL 实例"
        "main_Menu2"           = "2. 配置 WSL 中的 SSH 服务(设端口，必要时启用 systemd)"
        "main_Menu3"           = "3. 启用或禁用 WSL 实例的 systemd"
        "main_Menu4"           = "4. 切换 WSL 网络模式"
        "main_ExitMsg"         = "感谢使用 WSL 管理工具，再见！"

        # ------------------ migrate.ps1 ------------------
        "migrate_EnterDistro"   = "请输入要迁移的WSL 实例名称(当前安装目录为{0}) 或 'q' 返回主菜单"
        "migrate_InstRunning"   = "WSL 实例 '{0}' 当前正在运行。请先关闭后再迁移。" 
        "migrate_NewDistroName" = "请输入新实例名称 (或 'q' 返回主菜单)"
        "migrate_ExportStarting"= "开始导出 WSL 实例: {0} 至 {1}"
        "migrate_ExportCompleted" = "WSL 实例导出完成: {0}"
        "migrate_ExportFailed"  = "导出失败: {0}"
        "migrate_Deleting"      = "正在删除 WSL 实例: {0}"
        "migrate_DeletedOK"     = "WSL 实例 '{0}' 已成功删除。"
        "migrate_DeletedFail"   = "删除 WSL 实例失败: {0}"
        "migrate_Importing"     = "正在导入 WSL 实例，从 {0} (新名称: {1}) 至 {2}"
        "migrate_ImportedOK"    = "WSL 实例 '{0}' 已成功导入。"
        "migrate_ImportedFail"  = "导入失败: {0}"

        #------------ delete.ps1 相关 ------------
        "delete_EnterInstanceName" = "请输入要删除的实例名称 (或 'q' 返回主菜单)"
        "delete_InstRunning"       = "实例 '{0}' 正在运行，请先关闭再删除。"
        "delete_ConfirmDelete"     = "确定要删除实例 '{0}' 吗？(Y/N)"
        "delete_Deleted"           = "实例 '{0}' 已被删除。"
        "delete_Cancelled"         = "删除操作已取消。"
        "delete_NoInstName"        = "未提供实例名称。"

        #------------ show_info.ps1 相关 ------------
        "showinfo_OptionalParams"  = "可调参数: NameWidth={0}, StateWidth={1}, VersionWidth={2}, BasePathWidth={3}"
        "showinfo_Heading"         = "WSL 实例信息："
        "showinfo_NotAvailable"    = "不可用"


        # autostart.ps1
        "autostart_PromptDistro"   = "请输入要设置开机自启的 WSL 实例名称（或输入 'q' 返回主菜单）"
        "autostart_TemplateMissing"= "未找到 VBS 模板文件：{0}"
        "autostart_StartupMissing" = "未找到启动文件夹，正在创建..."
        "autostart_CreatedScript"  = "创建了自启动脚本：{0}"
        "autostart_Success"        = "WSL 实例 '{0}' 已设置为用户登录自动运行。"

        # ---------------------
        # configure_ssh.ps1 相关
        # ---------------------
        "configure_ssh_EnterDistro"  = "请输入要配置 SSH 服务的 WSL 实例名称（或输入 'q' 返回主菜单）"
        "configure_ssh_OptionMenu"   = @"
请选择 SSH 配置操作：
1. 启动/启用 SSH
2. 停止/关闭 SSH
输入 'q' 返回上级菜单
"@
        "configure_ssh_EnterPort"    = "请输入 SSH 端口(如 22022),或直接回车使用默认 22"
        "configure_ssh_Configuring"  = "正在为 WSL 实例 {0} 配置 SSH 端口 = {1} ..."
        "configure_ssh_StartingOK"   = "SSH 服务已配置并启动。"
        "configure_ssh_StoppingOK"   = "SSH 服务已停止。"
        "configure_ssh_Failed"       = "配置 SSH 失败：{0}"
        "configure_ssh_InvalidOpt"   = "无效选项，已取消。"

        # ---------------------
        # systemd_toggle.ps1 相关
        # ---------------------
        "systemd_toggle_EnterDistro"   = "请输入要启用/禁用 systemd 的 WSL 实例名称（或输入 'q' 返回主菜单）"
        "systemd_toggle_OptionMenu"    = @"
1. 启用 systemd
2. 禁用 systemd
输入 'q' 返回上级菜单
"@
        "systemd_toggle_Enabling"      = "正在为 {0} 启用 systemd ..."
        "systemd_toggle_Disabling"     = "正在为 {0} 禁用 systemd ..."
        "systemd_toggle_InvalidChoice" = "无效选项，已取消。"
        # ---------------------
        # toggle_network.ps1 相关
        # ---------------------
        "toggle_network_EnterChoice"      = "切换网络模式('q' 返回主菜单):`n1. 开启(Mirrored)`n2. 恢复(NAT) `n输入 'q' 返回主菜单"
        "toggle_network_Enabling"         = "正在开启 Mirrored 模式..."
        "toggle_network_Disabling"        = "正在切换回 NAT 模式..."
        "toggle_network_Enabled"          = "Mirrored 模式已启用！"
        "toggle_network_Disabled"         = "NAT 模式已启用！"
        "toggle_network_RestartNotice"    = "请执行 'wsl --shutdown' 并重新启动。"
        "toggle_network_InvalidChoice"    = "无效输入！"
        "toggle_network_FileNotExist"     = ".wslconfig 文件不存在，正在创建..."
        "toggle_network_NoExperimental"   = "未检测到 [experimental] 段，已追加到文件末尾。"
        "toggle_network_HasExperimental"  = "检测到 [experimental] 段，正在更新..."
    }

    "en-US" = @{

        # -----------------------------------------
        # common.ps1
        # -----------------------------------------
        "common_sys_image_lib_dir"   = "Image Lib Storage Directory: {0}"
        "common_new_wsl_install_dir" = "New WSL install Directory:   {0}"
        "common_PressAnyToContinue"   = "Press any key to continue..."

        # For Initialize-Config messages
        "common_FirstRun"             = "(For older Windows, you may need to manually enable the WSL first.`nYou can visit: https://ipzu.com/en/software/wsl/practical/ `n`nPlease check/define the config-file config.ps1 before use. `nPress any key to continue..."
        "common_ConfigNotFound"       = "config.ps1 not found at: {0}"
        "common_PleaseCreateConfig"   = "Please create or place a valid config.ps1 and try again."
        "common_ConfigMissingFields"  = "PSConfig missing required fields: sys_image_lib_dir or new_wsl_install_dir."
        "common_PathIsEmpty"          = "One or more expanded paths are null/empty. Check config.ps1."
        "common_DirNotExist"          = "Directory does not exist: {0}"
        "common_PromptCreateDir"      = "Create this directory now? (y/n)"
        "common_DirCreated"           = "Directory created: {0}"
        "common_CannotProceed"        = "Cannot proceed without this directory: {0}"
        "common_PleaseConfirmConfig"  = "Please confirm your config.ps1 is correct:"
        "common_PressYToContinue"     = "Press 'y' if this is correct and you want to proceed (y/n)"
        "common_InitCompleted"        = "Initialization completed. Created flag file: {0}"
        "common_OperationCancelled"   = "Operation cancelled. Please fix config.ps1, then rerun."

        # backup.ps1 相关
        "backup_ExportWslPrompt"   = "Enter the name of the WSL instance to export(current storage dir is {0}) or 'q' to return to main menu"
        "backup_ExportWslStarting" = "Starting export of WSL instance: {0} to {1}"
        "backup_ExportWslCompleted"= "WSL instance export completed: {0}"
        "backup_ExportWslFailed"   = "Export failed: {0}"

        # adduser.ps1 相关
        "adduser_EnterDistro"       = "Enter distribution name"
        "adduser_EnterUsername"     = "Enter username"
        "adduser_EnterPassword"     = "Enter password"
        "adduser_UserCreated"       = "`nDefault user has been set to '{0}'. Please restart WSL."
        "adduser_LoginInfo"         = "You can now login with: wsl -d {0} -u {1}"
        "adduser_Error"             = "adduser_Error: {0}"

        # ====== download.ps1 相关 ======
        "download_EnterDistroPrompt"  = "Enter the name of the distribution to download (current storage dir is  {0}) or 'q' to return to main menu"
        "download_Cancelled"          = "[Save-WslImage] Cancelled."
        "download_DistroNotFound"     = "[Save-WslImage] Distribution not found: {0}"
        "download_DistributionName"   = "[Save-WslImage] Distro: {0}"
        "download_Url"                = "[Save-WslImage] URL   : {0}"
        "download_PathDownload"       = "[Save-WslImage] Download path: {0}"
        "download_PathFinalTar"       = "[Save-WslImage] Final .tar   : {0}"
        "download_FileExists"         = "[Save-WslImage] {0} already exists. Use -Force to overwrite, or press 'Y' to confirm."
        "download_StartDownload"      = "[Save-WslImage] Starting download..."
        "download_DownloadCompleted"  = "[Save-WslImage] Download completed."
        "download_DownloadFailed"     = "[Save-WslImage] Download failed: {0}"
        "download_UnsupportedFormat"  = "[Save-WslImage] Unsupported file format: {0}"
        "download_AppxBundleDetected" = "[Save-WslImage] Detected .AppxBundle. Extracting..."
        "download_AppxBundleNoAppx"   = "[Save-WslImage] No .appx found in .AppxBundle"
        "download_AppxDetected"       = "[Save-WslImage] Detected .appx. Extracting..."
        "download_NoTarGzFound"       = "[Save-WslImage] No install.tar.gz or rootfs.tar.gz found inside .appx"
        "download_TarCreated"         = "[Save-WslImage] Created final TAR: {0}"
        "download_Cleanup"            = "[Save-WslImage] Cleanup: {0}"
        "download_Done"               = "[Save-WslImage] Done."
        "download_Failed"             = "[Save-WslImage] Failed: {0}"
        "download_SystemArch"         = "[Save-WslImage] System Architecture: {0}"

        # ====== New keys for processing .appxbundle and .appx ======
        "download_ProcessAppxBundle"  = "Processing .AppxBundle..."
        "download_SearchAppxFilter"   = "Searching .appx with filter: {0}"
        "download_NoArchMatch"        = "No .appx found for the given arch, fallback to any .appx ..."
        "download_AppxSelected"       = "Selected .appx => {0}"
        "download_ExpandAsZip"        = "Extracting as zip: {0} -> {1}"
        "download_ExtractSucceeded"   = "Extraction succeeded."
        "download_ExtractFailed"      = "Extraction failed: {0}"
        "download_FindTarGz"          = "Searching for install.tar.gz or rootfs.tar.gz in {0}"
        "download_FoundTarGz"         = "Found tar.gz => {0}"
        "download_ExtractGzip"        = "Extracting Gzip: {0} -> {1}"

        # ------------------ show_help.ps1 ------------------
        "help_Title"            = "`nWSL2 Subsystem Usage Help"
        "help_CommonCommands"    = "Common WSL commands:"
        "help_cmd_wsl_l_v"      = "  wsl -l -v                    : List installed distributions"
        "help_cmd_wsl_d"        = "  wsl -d <DistroName>          : Start a specific distribution"
        "help_cmd_wsl_shutdown" = "  wsl --shutdown               : Shut down all running distributions"
        "help_cmd_wsl_unreg"    = "  wsl --unregister <DistroName>: Unregister/uninstall a distribution"
        "help_cmd_wsl_setdef"   = "  wsl --set-default <DistroName>: Set the default distribution"
        "help_cmd_wsl_status"   = "  wsl --status                 : Show WSL status"
        "help_cmd_wsl_update"   = "  wsl --update                 : Update WSL"
        "help_PortForwardTitle"  = "Port forwarding command:"
        "help_PortForwardCmd"    = "  netsh interface portproxy add v4tov4 listenport=<ExternalPort> connectaddress=<WSL_IP> connectport=<InternalPort>"
        "help_PortForwardExample"= "  Example: netsh interface portproxy add v4tov4 listenport=80 connectaddress=172.17.xxx.xxx connectport=80"
        "help_FirewalldTitle"    = "Firewalld Enable command:"
        "help_FirewalldCmd"      = "netsh advfirewall firewall add rule name=<you_rule_name> protocol=<TCP|UDP> dir=in localport=<rule_local_port> action=allow"
        "help_FirewalldExample"  = "Example: netsh advfirewall firewall add rule name='WSL2-SSH' protocol=TCP dir=in localport=22 action=allow"
        
        "help_MoreInfo"          = "`nFor more information, visit: https://ipzu.com/en/software/wsl/practical/"

        # ------------------ install.ps1 ------------------
        "install_Starting"       = "Starting installation of WSL instance from image file: {0}"
        "install_Completed"      = "WSL instance installation completed: {0}"
        "install_Failed"         = "Installation failed: {0}"

        "install_NoTar"          = "No available .tar images found in the image library directory."
        "install_AvailableImgs"  = "`nAvailable images:"
        "install_SelectPrompt"   = "`nSelect an image to install (1-{0}) (current install dir is {1}) or 'q' to return to main menu"
        "install_NewDistroPrompt"= "Enter a name for the new distribution (or 'q' to return to main menu)"

        # ------------------ main.ps1 ------------------
        "main_Title"           = "`n==========================================================`nAutomate management of WSL`nAuthor: ipzu.com`nCurrent version: 2025.4.2`nDocument: https://ipzu.com/zh-cn/software/wsl/automng`n=============================================================`n`nMenu options:"
        "main_MenuS"           = "S. Show installed instances"
        "main_MenuD"           = "D. Download image"
        "main_MenuC"           = "C. Create backup image from current instance"
        "main_MenuI"           = "I. Restore or Install new instance"
        "main_MenuU"           = "U. Set default user for WSL instance"
        "main_MenuR"           = "R. Remove an instance"
        "main_MenuM"           = "M. Migrate installation location"
        "main_MenuH"           = "H. Help for WSL2 usage"
        "main_MenuE"           = "E. Exit"
        "main_SelectPrompt"    = "`nSelect an operation (S/D/C/I/U/R/M/H/1/2/3/4/E)"
        "main_PressAnyKey"     = "`nPress any key to return to the main menu..."
        "main_InvalidChoice"   = "Invalid choice, please try again."
        "main_Menu1"           = "1. Enable auto-run WSL instance at user login"
        "main_Menu2"           = "2. Configure SSH service in WSL instance (set port, enable systemd if needed)"
        "main_Menu3"           = "3. Enable or disable systemd for WSL instance"
        "main_Menu4"           = "4. Toggle WSL Network Mode"
        "main_ExitMsg"         = "Thank you for using the WSL Management Tool. Goodbye!"


        # ------------------ migrate.ps1 ------------------
        "migrate_EnterDistro"   = "Enter the name of the WSL instance to migrate(current install dir is {0}) or 'q' to return to main menu"
        "migrate_InstRunning"   = "WSL instance '{0}' is currently running. Please shut it down before migrating."
        "migrate_NewDistroName" = "Enter the new name for the imported instance (or 'q' to return to main menu)"
        "migrate_ExportStarting"= "Starting export of WSL instance: {0} to {1}"
        "migrate_ExportCompleted"= "WSL instance export completed: {0}"
        "migrate_ExportFailed"  = "Export failed: {0}"
        "migrate_Deleting"      = "Deleting WSL instance: {0}"
        "migrate_DeletedOK"     = "WSL instance '{0}' deleted successfully."
        "migrate_DeletedFail"   = "Failed to delete WSL instance: {0}"
        "migrate_Importing"     = "Importing WSL instance from {0} with new name: {1} to {2}"
        "migrate_ImportedOK"    = "WSL instance '{0}' imported successfully."
        "migrate_ImportedFail"  = "Import failed: {0}"

        #------------ delete.ps1 相关 ------------
        "delete_EnterInstanceName" = "Enter the name of the instance to delete (or 'q' to return to main menu)"
        "delete_InstRunning"       = "Instance '{0}' is currently running. Please shut it down before deletion."
        "delete_ConfirmDelete"     = "Are you sure you want to delete the instance '{0}'? (Y/N)"
        "delete_Deleted"           = "Instance '{0}' has been deleted."
        "delete_Cancelled"         = "Deletion cancelled."
        "delete_NoInstName"        = "No instance name provided."

        #------------ show_info.ps1 相关 ------------
        "showinfo_OptionalParams"  = "Optional params: NameWidth={0}, StateWidth={1}, VersionWidth={2}, BasePathWidth={3}"
        "showinfo_Heading"         = "WSL Instances Information:"
        "showinfo_NotAvailable"    = "N/A"

        # autostart.ps1
        "autostart_PromptDistro"   = "Enter the WSL instance name to auto-run on user login (or 'q' to return to main menu)"
        "autostart_TemplateMissing"= "Template VBS file not found: {0}"
        "autostart_StartupMissing" = "Startup folder not found, creating..."
        "autostart_CreatedScript"  = "Created autostart script: {0}"
        "autostart_Success"        = "WSL instance '{0}' has been set to auto-run at user login."


        # ---------------------
        # configure_ssh.ps1 相关
        # ---------------------
        "configure_ssh_EnterDistro"  = "Enter the WSL instance name to configure SSH (or 'q' to return to main menu)"
        "configure_ssh_OptionMenu"   = @"
Choose an SSH operation:
1. Start/Enable SSH
2. Stop/Disable SSH
Enter 'q' to return
"@
        "configure_ssh_EnterPort"    = "Enter the SSH port you want to use (e.g. 22022), or press Enter for default 22"
        "configure_ssh_Configuring"  = "Configuring SSH in instance {0} with port = {1} ..."
        "configure_ssh_StartingOK"   = "SSH service has been started/enabled successfully."
        "configure_ssh_StoppingOK"   = "SSH service has been stopped/disabled."
        "configure_ssh_Failed"       = "Failed to configure SSH: {0}"
        "configure_ssh_InvalidOpt"   = "Invalid choice, cancelled."

        # ---------------------
        # systemd_toggle.ps1 相关
        # ---------------------
        "systemd_toggle_EnterDistro"   = "Enter the WSL instance name to enable/disable systemd (or 'q' to return to main menu)"
        "systemd_toggle_OptionMenu"    = @"
1. Enable systemd
2. Disable systemd
Enter 'q' to return
"@
        "systemd_toggle_Enabling"      = "Enabling systemd for {0} ..."
        "systemd_toggle_Disabling"     = "Disabling systemd for {0} ..."
        "systemd_toggle_InvalidChoice" = "Invalid choice, cancelled."


        # ---------------------
        # toggle_network.ps1 相关
        # ---------------------
        "toggle_network_EnterChoice"      = "Toggle network mode: Enter 1=Enable Mirrored, 2=Switch back to NAT (or 'q' to return):"
        "toggle_network_Enabling"         = "Enabling Mirrored mode..."
        "toggle_network_Disabling"        = "Switching back to NAT mode..."
        "toggle_network_Enabled"          = "Mirrored mode is now enabled!"
        "toggle_network_Disabled"         = "NAT mode is now enabled!"
        "toggle_network_RestartNotice"    = "Please run 'wsl --shutdown' and then restart."
        "toggle_network_InvalidChoice"    = "Invalid choice!"
        "toggle_network_FileNotExist"     = ".wslconfig not found, creating..."
        "toggle_network_NoExperimental"   = "No [experimental] section found. Appending to end of file..."
        "toggle_network_HasExperimental"  = "Detected [experimental] section, updating..."
    
    }
}
