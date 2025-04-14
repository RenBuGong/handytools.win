import os
import sys
import requests
from datetime import datetime, timedelta
from write_color import write_error, write_warning, write_success

def download(download_url, save_path):
    """通用下载函数,支持文本和二进制文件"""
    if os.path.exists(save_path):
        file_age = datetime.now() - datetime.fromtimestamp(os.path.getmtime(save_path))
        if file_age < timedelta(days=7):
            write_success(f"使用现有的下载包: {save_path}")
            return save_path

    print("正在下载 ...")
    try:
        response = requests.get(download_url)
        response.raise_for_status()
        
        # 如果是文本文件扩展名,使用文本模式写入
        if save_path.lower().endswith(('.txt', '.java', '.py', '.xml', '.json')):
            with open(save_path, 'w', encoding='utf-8') as f:
                f.write(response.text)
        else:
            with open(save_path, 'wb') as f:
                f.write(response.content)
        
        write_success(f"成功下载 {save_path}")
        return save_path
        
    except Exception as e:
        write_error(f"下载 {save_path} 失败: {e}", file=sys.stderr)
        sys.exit(1)




if __name__ == "__main__":
    if len(sys.argv) != 3 :
        print(f"参数错误, 使用方法: python {os.path.basename(__file__)} <download_url> <save_path>")
        sys.exit(1)

    download(download_url=sys.argv[1], save_path=sys.argv[2])
    sys.exit(0)

