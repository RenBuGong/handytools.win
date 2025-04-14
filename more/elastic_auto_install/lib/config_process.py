# lib\config_process.py
import os
import sys
from string import Template
from write_color import write_error, write_warning, write_success



def load_template(template_path):
    """
    加载配置模板文件
    """
    try:
        with open(template_path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        write_error(f"错误: 找不到模板文件 '{template_path}'")
        sys.exit(1)
    except Exception as e:
        write_error(f"读取模板文件时出错: {e}")
        sys.exit(1)

def save_config(content, output_path):
    """
    保存处理后的配置到文件
    """
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
        write_success(f"配置已成功保存到: {output_path}")
    except Exception as e:
        write_error(f"保存配置文件时出错: {e}")
        sys.exit(1)

def process_template(template_content, variables):
    """
    处理模板，替换变量
    """
    template = Template(template_content)
    try:
        return template.substitute(variables)
    except KeyError as e:
        write_error(f"错误: 模板中使用的变量 {e} 未提供值")
        sys.exit(1)





if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"参数错误, 使用方法: python {os.path.basename(__file__)} <tamplate_path> <patch_args> <target_path>")
        sys.exit(1)

    try:
        # 添加上级目录到 Python 路径, 然后导入配置模块
        parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sys.path.insert(0, parent_dir)
        import config as cfg
        
        # 获取配置补丁变量
        tamplate_path = sys.argv[1]
        patch_args = getattr(cfg, sys.argv[2])
        target_path =  sys.argv[3]
        
        # 执行配置写入
        template_content = load_template(tamplate_path)
        processed_config = process_template(template_content, patch_args)
        save_config(processed_config, target_path)
        sys.exit(0)
    except Exception as e:
        write_error(f"执行错误Error: {e}")
        sys.exit(1)