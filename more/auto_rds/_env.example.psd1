# ===================================================================
#
#                 将本文件复制为.env.psd1 后按需修改
#
# ===================================================================
#
# 说明:
#   - 这个文件包含了项目所需的所有配置。
#   - deploy_main.ps1 脚本会读取 [Deployment] 部分。
#   - apps_publish.ps1 脚本会读取 [RemoteApps] 部分。
#
# ===================================================================

@{
    # ==================================
    #    基础环境部署配置
    # ==================================
    Deployment = @{
        # === 步骤 1：Active Directory 域服务 ===
        # 你的内部域名 (例如： "corp.contoso.com")
        DomainName = "example.com"
        # 你的 NetBIOS 域名 (通常是 DomainName 的第一部分, 例如："CORP")
        DomainNetbios = "MYAD"
        # 域控目录服务还原模式(DSRM)的密码，请务必修改为一个强密码
        SafeModePassword = "P@ssw0rd!ChangeMe!"

        # === 步骤 3：RDS 授权 ===
        # RDS 客户端访问许可证(CAL)的模式, 可选 "PerUser" 或 "PerDevice"
        LicenseMode = "PerUser"
        # 你的 RDS CAL 企业协议号或许可证密钥包ID
        LicenseKeyPackID = "6565792"
        # 你购买的 CAL 数量
        LicenseCount = 99
        # 激活许可证所需的公司信息
        CompanyInfo = @{
            FirstName     = "Admin"
            LastName      = "User"
            Company       = "Contoso Inc."
            CountryRegion = "US" # 使用两位国家代码
        }

        # === 步骤 4：RD Web Client & SSL ===
        # RD Web 对外服务的完整域名 (FQDN)
        PublicFqdn = "myrds.example.com"
        # 你的 SSL 证书 (.pfx) 在服务器上的完整路径
        SslCertPath = "./example.com.pfx"
        # 你的 SSL 证书的密码
        SslCertPassword = "mypasswd"

        Steps = @{
            Step1_AD_DNS      = $true
            Step2_RDS_Role    = $true
            Step3_RDS_License = $true
            Step4_Web_Client  = $true
            Step5_WebSocket   = $true
        }

        # 是否使用 RD Gateway。当前脚本仅支持 $false，一体化服务器请保持默认。
        UseGateway = $false
    }



    
    # ==================================
    #    RemoteApp 发布配置
    # ==================================
    RemoteApps = @(
        # --- 示例 1: 简单的经典应用 ---
        @{
            DisplayName = "画图"
            FilePath    = "C:\Windows\System32\mspaint.exe"
        },

        # --- 示例 2: UWP (商店) 应用 ---
        @{
            DisplayName = "计算器"
            AppAlias    = "Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"
        },

        # --- 示例 3: 带参数的应用 (例如: 用记事本默认打开一个文件) ---
        @{
            DisplayName = "查看服务器日志"
            FilePath    = "C:\Windows\System32\notepad.exe"
            CommandLine = "C:\Windows\Logs\CBS\CBS.log"
            IconPath    = "C:\Windows\System32\notepad.exe"
            IconIndex   = 0
        },

        # --- 示例 4: 自定义安装的程序 ---
        # @{
        #     DisplayName = "7-Zip File Manager"
        #     FilePath    = "C:\Program Files\7-Zip\7zFM.exe"
        #     IconPath    = "C:\Program Files\7-Zip\7zFM.exe"
        #     IconIndex   = 0
        # },

        @{
            DisplayName = "Edge浏览器"
            FilePath    = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        }
    )

    # 安装包缓存路径
    PkgCachePath = "PkgCache"

    # ==================================
    #    防火墙规则配置
    # ==================================
    Firewall = @{
        RulePrefix = "_custom_rule_"
        Rules      = @(
            @{
                Description = "Web-HTTP"
                Port        = 80
                Protocol    = "TCP"
            },
            @{
                Description = "Web-HTTPS"
                Port        = 443
                Protocol    = "TCP"
            },
            @{
                Description = "RDP-WebSocket"
                Port        = 3392
                Protocol    = "TCP"
            }
        )
    }
} 