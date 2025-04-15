# HandyTools.win

Windows 日常管理和远程登录工具集合，提供了一系列便捷工具来简化 Windows 环境中的系统管理、SSH 连接、环境配置等操作。

## 功能概述

- **远程连接工具**: 快速 SSH 连接、SCP 文件传输、VSCode 远程开发
- **本地工具**: 快速打开目录、Python 虚拟环境管理、防火墙规则管理等
- **环境配置**: PATH 环境变量管理
- **WSL 自动管理**: 自动启动和管理 WSL 实例

## 安装方法

1. 克隆或下载本仓库到本地
2. 运行 `path.add.cmd` 将工具添加到系统 PATH 环境变量
3. 重新打开命令行终端，工具就可以全局使用了

## 主要工具

### 远程连接工具

基于 `_lib/remote_kit.cmd` 实现，提供以下功能：

#### SSH 连接

```
# 使用默认用户连接
<工具名>

# 指定用户连接
<工具名> username
```

#### VSCode 远程开发

```
# 使用指定用户打开远程目录
<工具名> username /path/to/directory

# 使用默认用户打开远程目录
<工具名> /path/to/directory
```

#### SFTP 同步

```
# 将远程目录同步到本地(指定用户)
<工具名> username /remote/path/ local/path/

# 将远程目录同步到本地(默认用户)
<工具名> /remote/path/ local/path/
```

#### SCP 文件传输

```
# 远程到远程传输(默认用户)
<工具名> :remote/path1 :remote/path2

# 远程到本地传输(默认用户)
<工具名> :remote/path local/path:

# 本地到远程传输(默认用户)
<工具名> local/path: :remote/path

# 本地到本地传输
<工具名> local/path1: local/path2:
```

#### SSH 密钥管理

```
# 为默认用户添加SSH密钥
<工具名> __add.key__

# 为默认用户移除SSH密钥
<工具名> __remove.key__

# 为指定用户添加SSH密钥
<工具名> username __add.key__ [公钥路径]

# 为指定用户移除SSH密钥
<工具名> username __remove.key__ [公钥路径]
```

### 本地工具

#### 目录快速打开

```
# 在资源管理器中打开目录
<工具名> ___local___ 路径

# 用VSCode打开目录
<工具名> ___local___ 路径 v
```

#### Python 虚拟环境管理 (`pyvenvhere.cmd`)

在当前目录创建、管理和使用 Python 虚拟环境：

```
pyvenvhere
```

运行后会显示菜单：
1. 安装 requirements.txt
2. 生成 requirements.txt
3. 进入虚拟环境 Shell

#### 防火墙规则管理 (`portrule.cmd`)

Windows 防火墙端口管理工具：

```
portrule
```

提供菜单：
1. 添加入站规则(允许端口)
2. 查看现有规则
3. 删除现有规则

## 自定义工具

### 创建远程连接工具

复制 `handy_tools_custom/_example_remote.cmd` 并修改以下参数：

```
call  %~dp0..\_lib\remote_kit.cmd  端口 主机名/IP 默认用户 SSH私钥路径 %1 %2 %3
```

### 创建本地工具

复制 `handy_tools_custom/_example_local.cmd` 并修改以下参数：

```
call  %~dp0..\_lib\remote_kit.cmd  ___local___  默认目录路径  %1
```

## 其他功能

- `more/wsl.automng/`: WSL 实例自动管理工具
- `more/elastic_auto_install/`: Elastic Stack 自动化安装脚本
- `more/enable_ssh/`: 快速配置 SSH 服务
- `more/enable_powershell/`: PowerShell 脚本执行策略配置
- `more/enable_PsExec/`: PsExec 远程执行配置

## 卸载方法

运行 `path.remove.cmd` 将工具从 PATH 环境变量中移除。

## 注意事项

- 部分工具需要管理员权限
- 密钥管理功能支持 OpenSSH 和 PuTTY 工具链
- 自定义工具可以放置在 `handy_tools_custom/` 目录中

## 支持情况

- Windows 10/11
- 需要安装 OpenSSH 客户端
- 部分功能需要安装 VSCode 及相关插件 