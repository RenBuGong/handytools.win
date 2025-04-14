import sys
import os
from write_color import write_error, write_warning, write_success

def config(config_file, config_patch_str):
    """
    将配置补丁写入配置文件
    
    Args:
        config_file: 配置文件路径
        config_patch_str: 自定义配置字符串
    """
    try:
        # 移除首尾的引号(如果有)
        if config_file.startswith(('r"', "r'", '"', "'")):
            config_file = eval(config_file)
            
        # 打开文件进行追加
        with open(config_file, 'a', encoding='utf-8') as f:
            f.write(config_patch_str)
            
        write_success(f"自定义配置已写入: {config_file}")
        
    except Exception as e:
        raise Exception(f"自定义配置写入出错: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"参数错误, 使用方法: python {os.path.basename(__file__)} <config_file> <config_patch_var_name>")
        sys.exit(1)

    try:
        # 添加上级目录到 Python 路径, 然后导入配置模块
        parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sys.path.insert(0, parent_dir)
        import config as cfg
        
        # 获取配置补丁变量
        config_patch_str = getattr(cfg, sys.argv[2])
        
        # 执行配置写入
        config(sys.argv[1], config_patch_str)
        sys.exit(0)
    except Exception as e:
        write_error(f"执行错误Error: {e}")
        sys.exit(1)