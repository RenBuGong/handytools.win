import os
import sys
from write_color import write_error, write_warning, write_success

def check_env(install_dir):
    # 检查安装目录
    if os.path.exists(install_dir) and os.listdir(install_dir):
        write_success(f"安装目录已存在: {install_dir}")
        sys.exit(0)
    else:
        print(f"安装目录不存在: {install_dir}")
        sys.exit(1)



if __name__ == "__main__":
    if len(sys.argv) != 2 :
        print(f"参数错误, 使用方法: : python {os.path.basename(__file__)} <install_dir>")
        sys.exit(1)
    
    check_env(install_dir=sys.argv[1])
    sys.exit(0)


