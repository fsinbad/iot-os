#!/usr/bin/env python3
# generate_luac.py - 通用 Lua 编译脚本
# 将 app/*.lua 编译为 core/*.luac 和 core/*.luac.h
#
# 用法: python generate_luac.py [module_name]
# 示例: python generate_luac.py master
#       python generate_luac.py all  (编译所有模块)
#
# 需要: luac53.exe (位于 tools/lua536/)

import subprocess
import sys
from pathlib import Path

# 路径配置
SCRIPT_DIR = Path(__file__).parent.resolve()
LUA_CMD = SCRIPT_DIR / "tools" / "lua536" / "luac53.exe"
APP_DIR = SCRIPT_DIR / "app"
CORE_DIR = SCRIPT_DIR / "core"

# 需要编译的模块列表
MODULES = ["iot", "master"]


def check_luac():
    """检查 Lua 编译器"""
    if not LUA_CMD.exists():
        print(f"错误: 未找到 Lua 编译器: {LUA_CMD}")
        sys.exit(1)
    print(f"使用 Lua 编译器: {LUA_CMD}")


def compile_lua_module(module_name):
    """编译单个 Lua 模块"""
    lua_file = APP_DIR / f"{module_name}.lua"
    luac_file = CORE_DIR / f"{module_name}.luac"
    header_file = CORE_DIR / f"{module_name}.luac.h"
    
    if not lua_file.exists():
        print(f"错误: {module_name}.lua 不存在: {lua_file}")
        return False
    
    print(f"\n===> 编译 {module_name}.lua ...")
    
    try:
        # 编译为字节码
        result = subprocess.run(
            [str(LUA_CMD), "-o", str(luac_file), str(lua_file)],
            capture_output=True,
            text=True,
            check=True
        )
        print(f"      编译成功 -> {luac_file}")
        
        # 生成头文件
        generate_header(module_name, luac_file, header_file)
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"错误: 编译 {module_name}.lua 失败")
        print(f"      stdout: {e.stdout}")
        print(f"      stderr: {e.stderr}")
        return False


def generate_header(module_name, luac_file, header_file):
    """生成 C 头文件"""
    print(f"===> 生成 {module_name}.luac.h ...")
    
    luac_data = luac_file.read_bytes()
    
    # 转换为 C 数组格式
    lines = []
    for offset in range(0, len(luac_data), 12):
        chunk = luac_data[offset:offset + 12]
        line = ", ".join(f"0x{b:02x}" for b in chunk)
        lines.append("    " + line + ",")
    
    if lines:
        lines[-1] = lines[-1].rstrip(",")
    
    # 头文件内容
    macro_prefix = module_name.upper()
    var_prefix = module_name.lower()
    
    header_content = (
        f"#ifndef {macro_prefix}_LUAC_H\n"
        f"#define {macro_prefix}_LUAC_H\n\n"
        f"/* {module_name}.luac - compiled Lua bytecode */\n"
        f"static const unsigned char {var_prefix}_luac[] = {{\n"
        + "\n".join(lines)
        + f"\n}};\n\n"
        f"static const unsigned int {var_prefix}_luac_len = sizeof({var_prefix}_luac);\n\n"
        f"#endif /* {macro_prefix}_LUAC_H */\n"
    )
    
    header_file.write_text(header_content, encoding="ascii")
    print(f"      生成成功 -> {header_file} ({len(luac_data)} bytes)")


def main():
    print("generate_luac.py - Lua 模块编译工具")
    print("=" * 50)
    
    if len(sys.argv) > 1:
        target = sys.argv[1].lower()
    else:
        target = "all"
    
    check_luac()
    
    success_count = 0
    fail_count = 0
    
    if target == "all":
        # 编译所有模块
        for module in MODULES:
            if compile_lua_module(module):
                success_count += 1
            else:
                fail_count += 1
    else:
        # 编译指定模块
        if compile_lua_module(target):
            success_count += 1
        else:
            fail_count += 1
    
    print(f"\n===> 完成! 成功: {success_count}, 失败: {fail_count}")
    
    if fail_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
