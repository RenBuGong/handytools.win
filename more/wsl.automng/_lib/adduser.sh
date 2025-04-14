#!/usr/bin/env bash

# add_user.sh
# 用法：
#   ./add_user.sh <username> <password> [lang]
#
# 说明：
#   在当前 WSL 实例中创建给定用户名，并设置默认用户为该用户名。
#   可选第三参数 lang 指定多语言(如 "zh-CN" / "en-US")，默认为 en-US。
#   如果用户已存在，则提示并退出。

USERNAME="$1"
PASSWORD="$2"
LANG_CODE="$3"

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
  echo "Usage: $0 <username> <password> [lang]"
  exit 1
fi

if [[ -z "$LANG_CODE" ]]; then
  LANG_CODE="en-US"
fi

# 定义多语言关联数组
declare -A MSG_EN=(
    ["user_exists"]="User already exists:"
    ["creating_user"]="Creating user:"
    ["adduser_failed"]="Failed to create user:"
    ["mod_sudo_failed"]="Failed to add user to sudo group:"
    ["passwd_failed"]="Failed to set password for user:"
    ["sudoers_failed"]="Failed to modify /etc/sudoers for user:"
    ["set_default_failed"]="Failed to set default user in /etc/wsl.conf:"
    ["user_created"]="User creation complete."
)
declare -A MSG_ZH=(
    ["user_exists"]="用户已存在："
    ["creating_user"]="正在创建用户："
    ["adduser_failed"]="创建用户时出错："
    ["mod_sudo_failed"]="将用户添加到 sudo 组时出错："
    ["passwd_failed"]="设置用户密码时出错："
    ["sudoers_failed"]="修改 /etc/sudoers 时出错："
    ["set_default_failed"]="设置默认用户到 /etc/wsl.conf 时出错："
    ["user_created"]="用户创建完成。"
)

function t() {
  local key="$1"
  if [[ "$LANG_CODE" == "zh-CN" ]]; then
    echo "${MSG_ZH[$key]}"
  else
    echo "${MSG_EN[$key]}"
  fi
}

# 1. 检查用户是否已经存在
if id -u "$USERNAME" &>/dev/null; then
  echo "$(t user_exists) $USERNAME"
  exit 2
fi

echo "$(t creating_user) $USERNAME"

# 2. 创建用户（不设置密码）
if ! DEBIAN_FRONTEND=noninteractive adduser --quiet --disabled-password --gecos '' "$USERNAME"; then
  echo "$(t adduser_failed) $USERNAME"
  exit 3
fi

# 3. 将用户加入 sudo 组
if ! usermod -aG sudo "$USERNAME"; then
  echo "$(t mod_sudo_failed) $USERNAME"
  exit 4
fi

# 4. 设置密码
if ! echo "${USERNAME}:${PASSWORD}" | chpasswd; then
  echo "$(t passwd_failed) $USERNAME"
  exit 5
fi

# 5. 添加到 /etc/sudoers，免密 sudo
#    注意：实际生产环境中须谨慎，让用户使用 sudo 时仍需输入密码可能更安全
if ! echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; then
  echo "$(t sudoers_failed) $USERNAME"
  exit 6
fi

# 6. 设置默认用户
if ! echo -e "[user]\ndefault=${USERNAME}" > /etc/wsl.conf; then
  echo "$(t set_default_failed) $USERNAME"
  exit 7
fi

echo "$(t user_created)"
exit 0
