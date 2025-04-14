#!/usr/bin/env bash

# configure_ssh.sh
# 用法：
#   ./configure_ssh.sh start [port] [lang]
#       - 启动并启用 SSH，设置端口 = port（默认为22）
#       - lang可选，默认为 "en-US" 或你想要的默认语言
#   ./configure_ssh.sh stop [lang]
#       - 停止并禁用 SSH
#       - lang可选，默认为 "en-US" 或你想要的默认语言

# Bash Associative Arrays 用于多语言提示
declare -A MSG_EN=(
    ["installing"]="Installing/updating openssh-server ..."
    ["backup_config"]="Backing up original /etc/ssh/sshd_config ..."
    ["set_port"]="Setting SSH port to"
    ["use_systemd"]="Detected systemd is enabled, using systemctl to manage SSH."
    ["enable_ssh_autostart"]="Enabling SSH service on startup (systemctl enable sshd)..."
    ["restart_ssh"]="Restarting SSH service..."
    ["ssh_started"]="SSH service is now running on port"
    ["no_systemd"]="Detected systemd is NOT enabled."
    ["update_wsl_conf"]="Updating /etc/wsl.conf to enable systemd..."
    ["ssh_started_no_systemd"]="SSH service is started on port"
    ["stop_ssh"]="Stopping SSH service (systemctl stop ssh & disable ssh)..."
    ["ssh_stopped"]="SSH service has been stopped."
    ["done_update"]="Done. You may need to 'wsl --shutdown' and restart for changes to take effect."
    ["invalid_action"]="Invalid action: "
)

declare -A MSG_ZH=(
    ["installing"]="正在安装/更新 openssh-server ..."
    ["backup_config"]="正在备份原始 /etc/ssh/sshd_config ..."
    ["set_port"]="设置 SSH 端口为"
    ["use_systemd"]="检测到 systemd 已启用，使用 systemctl 管理 SSH。"
    ["enable_ssh_autostart"]="启用 SSH 开机自启 (systemctl enable sshd)..."
    ["restart_ssh"]="正在重启 SSH 服务..."
    ["ssh_started"]="SSH 服务已启动，当前监听端口："
    ["no_systemd"]="检测到 systemd 未启用。"
    ["update_wsl_conf"]="更新 /etc/wsl.conf 以启用 systemd..."
    ["ssh_started_no_systemd"]="SSH 服务已启动，当前监听端口："
    ["stop_ssh"]="正在停止 SSH 服务 (systemctl stop ssh 并禁用开机自启)..."
    ["ssh_stopped"]="SSH 服务已停止。"
    ["done_update"]="操作完成。如需生效，请运行 'wsl --shutdown' 后重新启动。"
    ["invalid_action"]="无效操作："
)

# 获取第一个参数(操作类型：start 或 stop)
ACTION="$1"

# 对于 "start" 模式，第二个参数可能是端口
if [[ "$ACTION" == "start" ]]; then
    PORT="$2"
    # 第三个参数可能是语言
    LANG_CODE="$3"
elif [[ "$ACTION" == "stop" ]]; then
    # 第二个参数可能是语言
    LANG_CODE="$2"
fi

# 如果端口为空，则默认22
if [[ -z "$PORT" && "$ACTION" == "start" ]]; then
    PORT=22
fi

# 如果语言为空，则默认 en-US
if [[ -z "$LANG_CODE" ]]; then
    LANG_CODE="en-US"
fi

# 简单函数，根据 LANG_CODE 在两个关联数组间切换
function t() {
    local key="$1"
    if [[ "$LANG_CODE" == "zh-CN" ]]; then
        echo "${MSG_ZH[$key]}"
    else
        echo "${MSG_EN[$key]}"
    fi
}

# 根据操作类型分支
case "$ACTION" in
    "start")
        # 1. 安装/更新 SSH
        echo "$(t installing)"
        sudo apt-get update -y
        sudo apt-get install -y openssh-server

        # 2. 备份 SSH 配置（只在首次备份）
        if [ ! -f /etc/ssh/sshd_config.bak ]; then
            echo "$(t backup_config)"
            sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        fi

        # 3. 设置端口
        echo "$(t set_port) $PORT"
        sudo sed -i '/^Port /d' /etc/ssh/sshd_config
        echo "Port $PORT" | sudo tee -a /etc/ssh/sshd_config >/dev/null

        # 4. 判断 systemd 是否已启用
        if [ "$(ps -p 1 -o comm=)" = "systemd" ]; then
            echo "$(t use_systemd)"
            echo "$(t enable_ssh_autostart)"
            sudo systemctl enable ssh
            echo "$(t restart_ssh)"
            sudo systemctl restart ssh
            echo "$(t ssh_started) $PORT"
        else
            echo "$(t no_systemd)"
            echo "$(t update_wsl_conf)"
            # 如果 /etc/wsl.conf 不存在或需要修改
            if [ -f /etc/wsl.conf ]; then
                # 如果文件存在，则检查是否包含 [boot] 段
                if grep -q "^\[boot\]" /etc/wsl.conf; then
                    sudo sed -i '/^\[boot\]/,/^\[.*\]/ s/^[[:space:]]*systemd\s*=.*/systemd=true/' /etc/wsl.conf
                    # 如果 [boot] 段内还没有 systemd 行，则追加
                    if ! sudo awk '/^\[boot\]/{flag=1;next} /^\[/{flag=0} flag && /systemd\s*=/' /etc/wsl.conf | grep -q .; then
                        sudo sed -i '/^\[boot\]/a systemd=true' /etc/wsl.conf
                    fi
                else
                    # 不存在 [boot] 段，则追加
                    echo -e "\n[boot]\nsystemd=true" | sudo tee -a /etc/wsl.conf >/dev/null
                fi
            else
                echo "/etc/wsl.conf not found, creating..."
                echo -e "[boot]\nsystemd=true" | sudo tee /etc/wsl.conf >/dev/null
            fi

            sudo service ssh --full-restart
            echo "$(t ssh_started_no_systemd) $PORT"
        fi

        # 可选：防止 WSL 因空闲而自动关闭
        if ! pgrep -u "$(whoami)" -x "dbus-daemon" >/dev/null; then
            dbus-launch true &>/dev/null &
        fi

        echo "$(t done_update)"
        ;;

    "stop")
        # 停止并禁用 SSH
        echo "$(t stop_ssh)"
        if [ "$(ps -p 1 -o comm=)" = "systemd" ]; then
            sudo systemctl stop ssh
            sudo systemctl disable ssh
        else
            # 如果没启用 systemd，则用 service
            sudo service ssh stop
            # disable ssh for sysvinit (如果真的需要的话，具体做法可能不一样)
        fi
        echo "$(t ssh_stopped)"
        echo "$(t done_update)"
        ;;

    *)
        echo "$(t invalid_action)$ACTION"
        exit 1
        ;;
esac
