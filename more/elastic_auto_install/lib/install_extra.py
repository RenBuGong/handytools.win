import os
import sys
import shutil
import zipfile
from write_color import write_error, write_warning, write_success

def extract(zip_file_path, install_dir, temp_path):
    print("正在解压 ...")
    with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
        zip_ref.extractall(temp_path)

    elasticsearch_folder = next((d for d in os.listdir(temp_path) if os.path.isdir(os.path.join(temp_path, d))), None)

    if elasticsearch_folder:
        shutil.move(os.path.join(temp_path, elasticsearch_folder), install_dir)
    else:
        os.makedirs(install_dir, exist_ok=True)
        for item in os.listdir(temp_path):
            shutil.move(os.path.join(temp_path, item), install_dir)
    write_success(f"已解压到: {install_dir}")
    # 清理临时目录
    # shutil.rmtree(temp_path)




if __name__ == "__main__":
    if len(sys.argv) != 4 :
        print(f"参数错误, 使用方法: python {os.path.basename(__file__)} <zip_file_path> <install_dir> <temp_path>")
        sys.exit(1)

    extract(zip_file_path=sys.argv[1], install_dir=sys.argv[2], temp_path=sys.argv[3])
    sys.exit(0)

