#!/usr/bin/env bash
#
# 用法:
#   toggle_systemd.sh enable [lang]
#   toggle_systemd.sh disable [lang]
#

set -e

ACTION="$1"  # enable or disable
LANG_CODE="$2"

if [[ -z "$ACTION" ]]; then
  echo "Usage: $0 [enable | disable] [lang]"
  exit 1
fi

if [[ -z "$LANG_CODE" ]]; then
  LANG_CODE="en-US"
fi

# 定义多语言关联数组
declare -A MSG_EN=(
    ["file_not_exist"]="/etc/wsl.conf not found, creating..."
    ["has_boot"]="Detected [boot] section in /etc/wsl.conf"
    ["no_boot"]="No [boot] section found in /etc/wsl.conf"
    ["enable_done"]="systemd enabled. Please run 'wsl --shutdown' in Windows and restart this distro."
    ["disable_done"]="systemd disabled. Please run 'wsl --shutdown' in Windows and restart this distro."
    ["invalid_param"]="Invalid parameter: "
)
declare -A MSG_ZH=(
    ["file_not_exist"]="/etc/wsl.conf 文件不存在，正在创建..."
    ["has_boot"]="检测到 /etc/wsl.conf 中已有 [boot] 段"
    ["no_boot"]="未检测到 /etc/wsl.conf 中的 [boot] 段"
    ["enable_done"]="已启用 systemd. 请在 Windows 中执行 'wsl --shutdown' 并重新启动此发行版。"
    ["disable_done"]="已禁用 systemd. 请在 Windows 中执行 'wsl --shutdown' 并重新启动此发行版。"
    ["invalid_param"]="无效参数："
)

function t() {
    local key="$1"
    if [[ "$LANG_CODE" == "zh-CN" ]]; then
        echo "${MSG_ZH[$key]}"
    else
        echo "${MSG_EN[$key]}"
    fi
}

function set_systemd_in_wslconf {
  local newSetting="$1" # "systemd=true" or "systemd=false"

  if [[ ! -f /etc/wsl.conf ]]; then
    echo "$(t file_not_exist)"
    echo -e "[boot]\n${newSetting}" | sudo tee /etc/wsl.conf >/dev/null
    return
  fi

  if grep -q "^\[boot\]" /etc/wsl.conf; then
    echo "$(t has_boot)"
    # 替换或插入 systemd=xxx
    sudo sed -i "/^\[boot\]/,/^\[.*\]/ s/^[[:space:]]*systemd\s*=.*/$newSetting/" /etc/wsl.conf
    if ! sudo awk '/^\[boot\]/{flag=1;next} /^\[/{flag=0} flag && /^[[:space:]]*systemd\s*=/' /etc/wsl.conf | grep -q .; then
      sudo sed -i "/^\[boot\]/a $newSetting" /etc/wsl.conf
    fi
  else
    echo "$(t no_boot)"
    echo -e "\n[boot]\n$newSetting" | sudo tee -a /etc/wsl.conf >/dev/null
  fi
}

case "$ACTION" in
  "enable")
    set_systemd_in_wslconf "systemd=true"
    echo "$(t enable_done)"
    ;;
  "disable")
    set_systemd_in_wslconf "systemd=false"
    echo "$(t disable_done)"
    ;;
  *)
    echo "$(t invalid_param)$ACTION"
    exit 1
    ;;
esac
