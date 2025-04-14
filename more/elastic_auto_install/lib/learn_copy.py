import time
import shutil
import sys
import os.path
from write_color import write_error, write_warning, write_success


def learned_copy(source_file, target_file, max_retries=36, wait_seconds=5):
    """
    复制文件并验证
    
    Args:
        source_file: 源文件路径
        target_file: 目标文件路径
        max_retries: 最大重试次数
        wait_seconds: 重试等待时间(秒)
    """
    # 规范化路径
    source_file = os.path.normpath(source_file)
    target_file = os.path.normpath(target_file)
    
    # 确保目标目录存在
    target_dir = os.path.dirname(target_file)
    if not os.path.exists(target_dir):
        try:
            os.makedirs(target_dir)
        except Exception as e:
            write_error(f"无法拷贝, 创建目标文件父目录失败: {str(e)}")
            sys.exit(1)

    for attempt in range(max_retries):
        try:
            # 使用shutil复制文件
            shutil.copy2(source_file, target_file)
            write_success("拷贝成功!")
            return True
        except Exception as e:
            write_warning(f"Copy failed: {str(e)}")
        if attempt < max_retries - 1:
            print(f"等待 {wait_seconds} 秒重试...")
            time.sleep(wait_seconds)
    
    write_error(f"拷贝失败, 请手动排查问题")
    sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"参数错误, 使用方法: python {os.path.basename(__file__)} <source_file> <target_file>")
        sys.exit(1)

    success = learned_copy(source_file=sys.argv[1], target_file=sys.argv[2])
    sys.exit(0)