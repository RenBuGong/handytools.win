import requests
import json
import sys
import os.path
from requests.auth import HTTPBasicAuth
from urllib3.exceptions import InsecureRequestWarning
from  write_color import write_error, write_warning, write_success

# 禁用不安全HTTPS警告
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)



def update_license(es_user, es_pass, license_file_path, license_url="https://localhost:9200/_license"):
    """
    更新 Elasticsearch license
    
    参数:
        es_user (str): ES用户名
        es_pass (str): ES密码
        license_file_path (str): license文件路径
        es_url (str): ES基础URL
    
    返回:
        bool: 是否更新成功
    """
    try:
        with open(license_file_path, 'r', encoding='utf-8') as f:
            license_content = f.read()
            # 尝试解析JSON以验证格式
            json.loads(license_content)
    except json.JSONDecodeError as e:
        write_error(f"授权文件, 不是有效的json: {str(e)}")
        sys.exit(1)
    except Exception as e:
        write_error(f"授权文件, 无法读取: {str(e)}")
        sys.exit(1)

    try:
        response = requests.put(
            license_url,
            auth=HTTPBasicAuth(es_user, es_pass),
            headers={"Content-Type": "application/json"},
            data=license_content,
            verify=False,
            timeout=10
        )
        
        # 格式化输出响应
        response_json = response.json()
        print("PUT授权文件, 服务器返回:")
        print(json.dumps(response_json, indent=2))
        
        if response.status_code in (200, 201):
            write_success("License updated successfully!")
            return True
        else:
            write_error(f"Failed to update license. Status code: {response.status_code}")
            sys.exit(1)
            
    except requests.exceptions.RequestException as e:
        write_error(f"PUT授权文件失败: {str(e)}")
        sys.exit(1)





if __name__ == "__main__":
    if len(sys.argv) != 5:
        print(f"参数错误, 使用方法: python {os.path.basename(__file__)} <es_user> <es_pass> <license_file_path> <es_url>")
        sys.exit(1)

    success = update_license(es_user=sys.argv[1], es_pass=sys.argv[2], license_file_path=os.path.normpath(sys.argv[3]), license_url=sys.argv[4])
    sys.exit(0)