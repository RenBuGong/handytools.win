import os
import sys
import requests
import time
from requests.auth import HTTPBasicAuth
from urllib3.exceptions import InsecureRequestWarning
from  write_color import write_error, write_warning, write_success

# 禁用不安全HTTPS警告
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)



def http_service_check(http_user, http_pass, http_url="https://localhost:9200/_cluster/health", max_retries=36, wait_seconds=5):
    """
    检查 Elasticsearch 服务状态
    
    参数:
        http_user (str): 用户名
        http_pass (str): 密码
        http_url (str): 服务URL
        max_retries (int): 最大重试次数, 默认36次(3分钟)
        wait_seconds (int): 重试等待时间(秒), 默认5秒
    
    返回:
        bool: http服务是否可用
    """
    health_url = f"{http_url.rstrip('/')}"
    
    for attempt in range(max_retries):
        try:
            print(f"检查http接口服务状态... (Attempt {attempt + 1}/{max_retries})")
            response = requests.get(
                health_url,
                auth=HTTPBasicAuth(http_user, http_pass),
                verify=False,
                timeout=5
            )
            
            if response.status_code == 200:
                write_success("http接口服务, 目前可用!")
                return True
                
        except requests.exceptions.RequestException as e:
            write_warning(f"http接口服务仍不可用, 连接的失败信息:\n {str(e)}")
            
        if attempt < max_retries - 1:
            print(f"等待 {wait_seconds} 秒后再次检查连接...")
            time.sleep(wait_seconds)
    
    write_error(f"连接服务失败, 请手动排查问题")
    sys.exit(1)






if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"参数错误, 使用方法: python {os.path.basename(__file__)} <http_user> <http_pass> <http_url>")
        sys.exit(1)
    
    http_service_check(http_user=sys.argv[1], http_pass=sys.argv[2], http_url=sys.argv[3])
    sys.exit(0)