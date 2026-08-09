-- iot-os xmake 构建脚本
-- 物联网操作系统（基于FreeRTOS和4G模组）

set_project("iot-os")
set_version("1.0.0")

-- 设置 C 语言标准
set_languages("c99")

-- 添加编译规则
add_rules("mode.debug", "mode.release")

-- 添加镜像仓库（优先使用清华镜像）
-- add_repositories("tuna https://mirrors.tuna.tsinghua.edu.cn/xmake-repo.git", {priority = 999})
-- add_repositories("xmake-repo https://gitcode.com/xmake-mirror/xmake-repo.git")

--===========================================================
-- 平台配置
--===========================================================
option("platform")
    set_default("windows")
    set_showmenu(true)
    set_description("选择目标平台")
    set_values("linux", "windows", "esp32", "ml307n", "yopen", "wasm")
option_end()

local plat = get_config("platform") or "windows"

if plat == "ml307n" then
    -- ML307N 嵌入式平台: 跳转到平台专用构建脚本
    includes("platforms/ml307n/xmake.lua")
else
    -- 桌面平台: 使用宿主机 gcc 工具链
    set_toolchains("gcc")

    -- 公共头文件目录
    add_includedirs("platforms/"..plat)
    add_includedirs("platforms")
    add_includedirs("vendor/lua")
    add_includedirs("modules/zlib")
    add_includedirs("core")

    -- MSYS/Mingw 宿主上 is_plat("windows") 为 false，但仍在用 Windows 工具链
    function is_windows_toolchain()
        return is_plat("windows") or is_plat("msys") or is_plat("mingw") or is_plat("cygwin")
    end

    --===========================================================
    -- 包含子目录 (排除 ml307n 嵌入式平台，使用专用构建脚本)
    --===========================================================
    includes("core", "modules", "drivers", "vendor")
    -- 桌面平台专用
    includes("platforms/windows")
    includes("platforms/linux")
    includes("platforms/esp32")
    includes("platforms/yopen")
    includes("platforms/wasm")

    --===========================================================
    -- 默认构建目标（桌面平台使用）
    --===========================================================
    target("iot-os")
        set_kind("binary")
        set_languages("c99")
        add_files("core/*.c")
        add_files("modules/**/*.c")
        add_files("drivers/**/*.c")
        add_files("vendor/lua/*.c")
        add_files("platforms/" .. plat .. "/*.c")
    target_end()
end
