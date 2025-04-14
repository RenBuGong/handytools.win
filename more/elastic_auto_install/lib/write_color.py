import os
import sys
import platform
from contextlib import contextmanager

class TerminalColors:
    """终端颜色工具类"""
    
    def __init__(self):
        # 定义颜色代码
        self.COLORS = {
            'RED': '\033[91m',
            'GREEN': '\033[92m',
            'YELLOW': '\033[93m',
            'BLUE': '\033[94m',
            'MAGENTA': '\033[95m',
            'CYAN': '\033[96m',
            'WHITE': '\033[97m',
            'RESET': '\033[0m'
        }
        
        # 检查是否支持颜色输出
        self.has_colors = self._setup_colors()
        
    def _setup_colors(self):
        """
        检测并设置终端的颜色支持
        """
        # 如果是Windows系统
        if platform.system() == 'Windows':
            # 尝试启用Windows的VT100支持
            try:
                import ctypes
                kernel32 = ctypes.windll.kernel32
                # 启用ANSI转义序列
                kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
                return True
            except:
                # 如果启用失败，检查是否在支持颜色的终端中
                return os.environ.get('TERM') in ['xterm', 'xterm-color', 'xterm-256color', 'screen', 'screen-256color']
                
        # 对于类Unix系统，检查是否在终端中且支持颜色
        return hasattr(sys.stdout, 'isatty') and sys.stdout.isatty()
    
    def colorize(self, text, color):
        """
        为文本添加颜色
        """
        if not self.has_colors:
            return text
        color_code = self.COLORS.get(color.upper(), '')
        if not color_code:
            return text
        return f"{color_code}{text}{self.COLORS['RESET']}"
    
    @contextmanager
    def color_context(self, color):
        """
        创建一个颜色上下文
        """
        if self.has_colors:
            color_code = self.COLORS.get(color.upper(), '')
            sys.stdout.write(color_code)
            sys.stdout.flush()
        try:
            yield
        finally:
            if self.has_colors:
                sys.stdout.write(self.COLORS['RESET'])
                sys.stdout.flush()

# 创建全局颜色工具实例
terminal_colors = TerminalColors()

def write_colored(message, color):
    """输出彩色文本"""
    print(terminal_colors.colorize(message, color))

def write_warning(message):
    """输出警告信息"""
    write_colored(message, 'YELLOW')

def write_error(message):
    """输出错误信息"""
    write_colored(message, 'RED')

def write_info(message):
    """输出信息"""
    write_colored(message, 'CYAN')

def write_success(message):
    """输出成功信息"""
    write_colored(message, 'GREEN')

# 使用示例
if __name__ == "__main__":
    # 基本使用
    write_info("这是一条信息")
    write_warning("这是一条警告")
    write_error("这是一条错误")
    write_success("这是一条成功消息")
    
    # 使用上下文管理器
    with terminal_colors.color_context('BLUE'):
        print("这段文字是蓝色的")
    print("这段文字是正常颜色")
    
    # 直接使用colorize
    print(terminal_colors.colorize("自定义颜色文本", 'MAGENTA'))