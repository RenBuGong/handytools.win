1 下载最新的 rd web client 离线包:
1.1 先下载最新版本powershell （可以应用商店中搜索'powershell'进行安装）
1.2 安装后，双击运行download_offline_cache.cmd , 成功后会生成或刷新 ./PkgCache/

2 配置
复制 _env.example.psd1 为 .env.psd1 , 按需修改 .env.psd1 中Deployment 的定义配置， 需要提前准备好：
2.1 一台干净的 windwos server 2022 或2025 目标主机, 它将用来安装 AD域控 + RDS + Web Client
2.2 设置静态ip地址, 例如 192.168.1.100
2.3 修改目标主机名, 例如 myrds
2.4 一个用来设置AD根的域名，例如 examele.com
2.5 本脚本使用单机部署，rd web client 的域名将自动设置为 <主机名>.<AD根域名>, 例如 myrds.example.com
2.6 rd web client 域名的 SSL证书（pfx格式）


3 使用
3.1 将系统更新补丁，更新到最新状态。如果有挂起待重启的更新任务
3.2 将本脚本目录(auto_deploy_rds/) 完整复制到目标主机
3.3 在目标主机上, 双击运行 deploy_main.cmd （会自动申请管理员权限）
脚本会提示多次计算机重启，请按要求重启

4 发布应用
4.1 按需修改 .env.psd1 中RemoteApps 的定义配置
4.2 双击运行 apps_publish.cmd
4.3 访问 https://<主机名>.<AD根域名>/rdweb/webclient/ 使用你发布的应用, 整个配置流程便已经完成.



FAQ

a. 转换 pfx 密钥
openssl pkcs12 -export -out example.com.pfx -inkey example.com.key -in fullchain.cer

b. 查看服务器是否有待重启的任务：
(Get-CimInstance -ClassName Win32_QuickFixEngineering).HotFixID | Out-Null   # 触发 WMI
Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -EA Ignore
（如果返回 pending xxx 则是有挂起待重启的）


c.授权失败，脚本目前授权不会成功，需要手动设置：
先查看这个 手动设置，企业协议号：6565792
https://www.clicksun.com.cn/mis/bbs/showbbs.asp?id=29239 （或 https://99zc.com/Skills/96.html）
