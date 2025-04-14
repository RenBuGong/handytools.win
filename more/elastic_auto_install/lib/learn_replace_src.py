import sys
import os
from write_color import write_error, write_warning, write_success



def find_block_boundaries(source_file_path, target_line):
    """
    在Java文件中查找代码块的起始和结束行号
    
    参数:
    source_file_path (str): 原文件的路径
    target_line (str): 要查找的代码块起始行(如函数定义或代码块开始)
    
    返回:
    tuple: (起始行号, 结束行号)，如果未找到则返回 (-1, -1)
    """
    try:
        # 读取Java文件
        with open(source_file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        # 去除每行末尾的换行符
        lines = [line.rstrip('\n') for line in lines]
        
        # 查找目标行
        start_line_num = -1
        for i, line in enumerate(lines, 1):  # 使用1为起始行号
            if line.strip() == target_line.strip():
                start_line_num = i
                break
        
        if start_line_num == -1:
            write_error(f"未找到匹配的行: {target_line}")
            sys.exit(1)
        
        # 从目标行开始计算括号匹配
        brace_count = 0
        found_first_brace = False
        
        # 从起始行继续遍历
        for i in range(start_line_num - 1, len(lines)):
            line = lines[i]
            
            # 计算当前行的左右括号
            for char in line:
                if char == '{':
                    brace_count += 1
                    found_first_brace = True
                elif char == '}':
                    brace_count -= 1
            
            # 如果已经找到第一个左括号，且括号计数归零，说明找到匹配的右括号
            if found_first_brace and brace_count == 0:
                write_success(f"找到指定代码块, 开头和结尾行号: {start_line_num}  {i + 1}")
                return (start_line_num, i + 1)
        
        write_error("未找到匹配的结束括号")
        sys.exit(1)
        
    except FileNotFoundError:
        write_error(f"文件未找到: {source_file_path}")
        sys.exit(1)
    except Exception as e:
        write_error(f"处理文件时出错: {str(e)}")
        sys.exit(1)





def replace_lines(source_file_path, start_line, end_line, new_content, target_file_path):
    """
    从源文件读取内容，替换指定行范围的内容后写入目标文件
    
    参数:
    source_file_path (str): 源文件路径
    target_file_path (str): 目标文件路径（替换后的文件将保存在这里）
    new_content (str): 要替换的新内容
    start_line (int): 开始行号(从1开始)
    end_line (int): 结束行号(从1开始)
    
    返回:
    bool: 操作是否成功
    """
    try:
        # 读取源文件的所有行
        with open(source_file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        # 验证行号
        if start_line < 1 or end_line > len(lines) or start_line > end_line:
            write_error(f"错误：无效的行号范围（文件共{len(lines)}行）")
            sys.exit(1)

            
        # 将新内容分割成行并确保每行末尾有换行符
        new_lines = [
            line if line.endswith('\n') else line + '\n'
            for line in new_content.split('\n')
        ]
        
        # 替换指定范围的行
        lines[start_line-1:end_line] = new_lines
        
        # 写入目标文件
        with open(target_file_path, 'w', encoding='utf-8') as file:
            file.writelines(lines)
            
        write_success(f"替换成功！新文件已保存到：{target_file_path}")
        return True
        
    except FileNotFoundError as e:
        write_error(f"错误：文件未找到 - {e.filename}")
        sys.exit(1)

    except Exception as e:
        write_error(f"错误：{str(e)}")
        sys.exit(1)

    



if __name__ == "__main__":
    if len(sys.argv) != 5 :
        print(f"参数错误, 使用方法: python {os.path.basename(__file__)} <source_file_path> <target_line> <new_content> <target_file_path>")
        sys.exit(1)


    try:
        # 添加上级目录到 Python 路径, 然后导入配置模块
        parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sys.path.insert(0, parent_dir)
        import config as cfg
        
        # 获取配置补丁变量
        source_file_path = sys.argv[1]
        target_line =  getattr(cfg, sys.argv[2])
        new_content =  getattr(cfg, sys.argv[3])
        target_file_path = sys.argv[4]


        start_line, end_line = find_block_boundaries(source_file_path, target_line)
        replace_lines(source_file_path, start_line, end_line, new_content, target_file_path)
        sys.exit(0)

    except Exception as e:
        write_error(f"执行错误Error: {e}")
        sys.exit(1)