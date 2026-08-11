-----------------------------------------------------------------------
-- xmake script file for ML307N platform
-- 基于 CM8620OC-V1.1.1-SDK 构建 iot-os 固件
--
-- @author      iot-os
-- @file        xmake.lua
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- 参数配置 (从命令行传入)
-- 用法: xmake f --board=ml307n_dc --sdkver=mdl
-----------------------------------------------------------------------
local BOARD_NAME  = get_config("board") or "ml307n_dc"
local SDK_VER     = get_config("sdkver") or "mdl"

-----------------------------------------------------------------------
-- 路径定义
-----------------------------------------------------------------------
local PLAT_DIR   = os.scriptdir()
local SDK_ROOT   = PLAT_DIR .. "/CM8620OC-V1.1.1-SDK"
local SDK_CODE   = SDK_ROOT .. "/code"
local SDK_TOOLCHAIN = SDK_ROOT .. "/ict-build/ZCnuclei/win"
local SDK_PREBUILD_LIB = SDK_CODE .. "/prebuild/" .. SDK_VER .. "/lib"
local SDK_CUSTOM_LIB = SDK_CODE .. "/custom/" .. BOARD_NAME .. "/lib"
local LOCAL_INCLUDE = PLAT_DIR .. "/include/" .. SDK_VER
local LOCAL_OPINCLUDE = PLAT_DIR .. "/include/opencpu/include"
local SDK_MKTOOLS = SDK_CODE .. "/tools/mkimg"
local PROJECT_ROOT = PLAT_DIR .. "/../.."
local BOARD_DIR   = SDK_CODE .. "/src/board/" .. BOARD_NAME

-- 日志输出
cprint("${bright green}============================================${clear}")
cprint("${bright green}  ML307N iot-os 编译配置${clear}")
cprint("${bright green}  开发板: ${clear}" .. BOARD_NAME)
cprint("${bright green}  SDK版本: ${clear}" .. SDK_VER)
cprint("${bright green}  平台目录: ${clear}" .. PLAT_DIR)
cprint("${bright green}============================================${clear}")

-----------------------------------------------------------------------
-- 平台配置
-----------------------------------------------------------------------
set_plat("cross")
set_config("chip", "ict2110")
set_config("cpu_arch", "ZCrisc-v")
set_config("cpu_type", "cpu-ap")
set_config("buildir", "build/ml307n")
set_optimize("smallest")
set_warnings("all")

-----------------------------------------------------------------------
-- 芯片和CPU宏定义
-----------------------------------------------------------------------
add_defines("_CHIP_ICT2110", "_CPU_AP")
add_defines("USE_TOP_DEBUG")
add_defines("BUILD_IN_SDK")
add_defines("ML307N_DC_TOP")
add_defines("ML307N_DC_CONFIG")

-----------------------------------------------------------------------
-- 工具链定义 (Nuclei RISC-V)
-----------------------------------------------------------------------
toolchain("ZCrisc-v_gcc")
    set_kind("standalone")
    set_sdkdir(SDK_TOOLCHAIN)
    set_toolset("cc",     "riscv64-unknown-elf-gcc")
    set_toolset("cxx",    "riscv64-unknown-elf-g++")
    set_toolset("ld",     "riscv64-unknown-elf-gcc")
    set_toolset("ar",     "riscv64-unknown-elf-ar")
    set_toolset("strip",  "riscv64-unknown-elf-strip")
    set_toolset("as",     "riscv64-unknown-elf-gcc")
    set_toolset("objcopy","riscv64-unknown-elf-objcopy")

    on_load(function(toolchain)
        toolchain:add("cxflags",
            "-march=rv32imac -mabi=ilp32 -mcmodel=medlow -mdiv " ..
            "-ffunction-sections -fno-builtin-printf -fno-common " ..
            "-fdata-sections -fshort-enums -fno-builtin -mstrict-align " ..
            "-MMD -MP -msave-restore -fno-unroll-loops " ..
            "-Werror=int-conversion -D_USE_CMPL_GCC -Dgcc -DN310 " ..
            "-Wno-unused-function -Wno-unknown-pragmas " ..
            "-Wno-builtin-macro-redefined -Wno-address " ..
            "-std=gnu99 " ..
            "-D__FILE__=" .. "\"iot-os\"",
            {force = true})
        toolchain:add("asflags", "-march=rv32imac -mabi=ilp32", {force = true})
        toolchain:add("ldflags",
            "-march=rv32imac -mabi=ilp32 " ..
            "-Wl,--whole-archive -Wl,--start-group",
            {force = true})
    end)
toolchain_end()

set_arch("risc-v")
set_toolchains("ZCrisc-v_gcc")

-----------------------------------------------------------------------
-- SDK 头文件路径 (本地拷贝)
-----------------------------------------------------------------------
add_includedirs(PLAT_DIR .. "/include", {public = true})
add_includedirs(LOCAL_INCLUDE, {public = true})
add_includedirs(LOCAL_INCLUDE .. "/agt", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/amr", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/at_api", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/at_func", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/audio", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/busmux", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/cert", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/cmn", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/cpu", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/drv", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/drv/chip", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/fs", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/ipsec", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/kernel", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/libdl", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/lwip", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/lwip/lwip", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/lwip/priv", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/lwip/prot", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/lwip_ports", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/lwip_ports/arch", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/mbedtls", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/mbedtls/mbedtls", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/mbedtls_ports", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/mobvoi", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/modem", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/modem/nv", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/net", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/ota", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/psm", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/ramdump", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/service", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/shell", {public = true})
add_includedirs(LOCAL_INCLUDE .. "/voice_proc", {public = true})

-- OpenCPU 头文件
add_includedirs(LOCAL_OPINCLUDE, {public = true})

-----------------------------------------------------------------------
-- iot-os 头文件路径
-----------------------------------------------------------------------
add_includedirs(PROJECT_ROOT .. "/core", {public = true})
add_includedirs(PROJECT_ROOT .. "/vendor/lua", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/zlib", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/filters", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/pack", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/wdt", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/net", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/fs", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/http", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/mqtt", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/modbus", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/crypto", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/lvgl", {public = true})
add_includedirs(PROJECT_ROOT .. "/vendor/lvgl-9.5.0", {public = true})
add_includedirs(PROJECT_ROOT .. "/vendor/lvgl-9.5.0/src", {public = true})
add_includedirs(PROJECT_ROOT .. "/modules/ai", {public = true})
add_includedirs(PROJECT_ROOT .. "/platforms", {public = true})
add_includedirs(PROJECT_ROOT .. "/drivers", {public = true})
add_includedirs(PROJECT_ROOT .. "/vendor/miniz", {public = true})
add_includedirs(PROJECT_ROOT .. "/vendor/lua-cjson", {public = true})
add_includedirs(PROJECT_ROOT .. "/vendor/gmssl/include", {public = true})
add_includedirs(PLAT_DIR, {public = true})

-----------------------------------------------------------------------
-- SDK 预编译库链接
-----------------------------------------------------------------------
add_linkdirs(SDK_PREBUILD_LIB)
add_linkdirs(SDK_CUSTOM_LIB)

-- SDK 基础库 (prebuild)
local sdk_prebuild_libs = {
    "agt", "busmux", "cert", "cfg", "common", "cpu",
    "drv", "fs", "libdl", "lzma", "mobvoidsp", "net_startup",
    "nvm", "ota", "ps", "psm", "pub", "ramdump",
    "service", "shell",
}
for _, lib in ipairs(sdk_prebuild_libs) do
    add_links(lib)
end

-- SDK 第三方库
add_links("opencore-amr-0.1.6")
add_links("vo-amrwbenc-0.1.3")

-- SDK 自定义库 (ml307n-dc)
local sdk_custom_libs = {
    "at", "at_command", "at_ps", "audio", "cmmqtt",
    "ftp", "http", "ipsec", "lwip", "mbedtls",
    "oc", "ocaudiodecoders", "onemo", "os", "tts", "voice_proc",
}
for _, lib in ipairs(sdk_custom_libs) do
    add_links(lib)
end

-----------------------------------------------------------------------
-- 编译选项
-----------------------------------------------------------------------
add_cflags("-Wall", "-Wextra", "-Wno-unused-parameter", "-std=gnu99")

-----------------------------------------------------------------------
-- 目标: cpu-ap.elf
-----------------------------------------------------------------------
target("cpu-ap.elf")
    set_kind("binary")
    set_targetdir("$(buildir)/iot-os")

    -- 构建前生成链接脚本 (使用 gcc -E 预处理以展开 AP_XIP_START 等宏)
    before_build(function(target)
        local BIN_DIR = "$(buildir)/iot-os"
        if not os.exists(BIN_DIR) then
            os.mkdir(BIN_DIR)
        end
        local LD_SCRIPT = BOARD_DIR .. "/cfg/cpu-ap.lds"
        local LD_OUTPUT = BIN_DIR .. "/cpu-ap.ld"
        local GCC = SDK_TOOLCHAIN .. "/bin/riscv64-unknown-elf-gcc"

        if os.exists(LD_SCRIPT) then
            -- 使用 gcc -E 预处理, -x c 将 .lds 作为 C 源文件处理, 展开宏
            local cmd = GCC .. " -E -DAP_XIP_START=0xC8000020 -DAP_XIP_ON=0 -x c -P " .. LD_SCRIPT .. " -o " .. LD_OUTPUT
            os.exec(cmd)
            if not os.exists(LD_OUTPUT) then
                raise("链接脚本预处理失败: " .. cmd)
            end
            cprint("${bright green}链接脚本: ${clear}" .. LD_OUTPUT)
        else
            raise("未找到链接脚本 cpu-ap.lds")
        end
    end)

    -- 链接脚本
    add_ldflags(
        "-Xlinker --gc-sections " ..
        "-Wl,-Map,$(buildir)/iot-os/cpu-ap.map " ..
        "--specs=nano.specs --specs=nosys.specs " ..
        "-T $(buildir)/iot-os/cpu-ap.ld",
        {force = true})

    -- 额外链接选项
    add_ldflags("-Wl,--unresolved-symbols=ignore-all", {force = true})
    add_ldflags("-lm -Wl,--end-group -Wl,--no-whole-archive", {force = true})

    -- iot-os 平台源码
    add_files(PLAT_DIR .. "/*.c")
    add_files(PLAT_DIR .. "/modules/*.c|*_stub.c")

    -- SDK 未定义符号桩
    add_files(PLAT_DIR .. "/stubs.c")

    -- iot-os 核心源码
    add_files(PROJECT_ROOT .. "/core/*.c")

    -- Lua 解释器
    add_files(PROJECT_ROOT .. "/vendor/lua/*.c")

    -- 模块源码
    add_files(PROJECT_ROOT .. "/modules/zlib/*.c")
    add_files(PROJECT_ROOT .. "/modules/filters/*.c")
    add_files(PROJECT_ROOT .. "/modules/pack/*.c")
    add_files(PROJECT_ROOT .. "/modules/wdt/*.c")
    -- net 模块暂不加入 (依赖 gmssl, ml307n 用 SDK 原生 API)
    -- add_files(PROJECT_ROOT .. "/modules/net/*.c")
    add_files(PROJECT_ROOT .. "/modules/fs/*.c")
    -- http/mqtt 模块暂不加入 (依赖 net/gmssl)
    -- add_files(PROJECT_ROOT .. "/modules/http/*.c")
    -- add_files(PROJECT_ROOT .. "/modules/mqtt/*.c")
    add_files(PROJECT_ROOT .. "/modules/modbus/*.c")
    -- LVGL 模块暂不加入 (LVGL 9 API 需适配, 体积大)
    -- add_files(PROJECT_ROOT .. "/modules/lvgl/*.c")
    -- AI 模块暂不加入 (依赖 http/net 模块)
    -- add_files(PROJECT_ROOT .. "/modules/ai/*.c")

    -- 设备驱动源码
    add_files(PROJECT_ROOT .. "/drivers/*.c")
    add_files(PROJECT_ROOT .. "/drivers/ads1115/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/bh1750/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/bme280/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/dht/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/ds18b20/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/lcd1602/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/led/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/mpu6050/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/pcf8574/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/relay/*.c", {optional = true})
    add_files(PROJECT_ROOT .. "/drivers/ssd1306/*.c", {optional = true})

    -- gmssl 密码库 (ml307n 使用 SDK mbedtls, gmssl 待移植)
    -- add_files(PROJECT_ROOT .. "/vendor/gmssl/src/*.c")

    -- Lua CJSON (排除 dtoa.c 和 g_fmt.c, 它们与 fpconv.c 中的包装函数重复定义)
    add_files(PROJECT_ROOT .. "/vendor/lua-cjson/*.c|dtoa.c|g_fmt.c")

    -- miniz 压缩库
    add_files(PROJECT_ROOT .. "/vendor/miniz/*.c")

    -- LVGL (可选，占空间大)
    local ENABLE_LVGL = get_config("enable_lvgl") or os.getenv("ENABLE_LVGL") or "n"
    if ENABLE_LVGL == "y" or ENABLE_LVGL == "1" then
        add_defines("ENABLE_LVGL")
        add_files(PROJECT_ROOT .. "/vendor/lvgl-9.5.0/src/**/*.c")
        add_includedirs(PROJECT_ROOT .. "/vendor/lvgl-9.5.0", {public = true})
        add_includedirs(PROJECT_ROOT .. "/vendor/lvgl-9.5.0/src", {public = true})
        cprint("${bright green}LVGL: 已启用${clear}")
    end

    -- 后处理: 提取固件段并打包
    after_build(function(target)
        local BIN_DIR    = "$(buildir)/iot-os/ap"
        local VERSION_DIR = "$(buildir)/iot-os/version"
        local OBJCPY     = target:tool("objcopy")
        local TARGET     = target:targetfile()
        local CP_BIN_DIR = SDK_CODE .. "/prebuild/" .. SDK_VER .. "/cp"

        -- 工具路径 (Windows/Linux 兼容)
        local MK_MERGE  = SDK_MKTOOLS .. "/merge"
        local MK_IMAGE  = SDK_MKTOOLS .. "/mkimage"
        local MK_JOINT  = SDK_MKTOOLS .. "/joint"
        if is_os("windows") then
            MK_MERGE = MK_MERGE .. ".exe"
            MK_IMAGE = MK_IMAGE .. ".exe"
            MK_JOINT = MK_JOINT .. ".exe"
        end

        -- 创建输出目录
        if not os.exists(BIN_DIR) then
            os.mkdir(BIN_DIR)
        end
        if not os.exists(VERSION_DIR) then
            os.mkdir(VERSION_DIR)
        end

        -- 读取分区表获取 zknl 大小
        local PARTITION_NAME = "xpartition.ini"
        local XIP_MODE = os.getenv("ENABLE_XIP") or "y"
        if XIP_MODE == "n" or XIP_MODE == "normal" then
            PARTITION_NAME = "npartition.ini"
        end
        local PARTITION_PATH = BOARD_DIR .. "/cfg/" .. PARTITION_NAME
        local ZKNL_SIZE = "0x000D2000"  -- 默认 xpartition.ini 中的 zknl 大小
        if os.exists(PARTITION_PATH) then
            local PART_TBL = io.open(PARTITION_PATH, "r")
            if PART_TBL then
                for LINE in PART_TBL:lines() do
                    local PART_NAME = string.match(LINE, "zknl")
                    if PART_NAME == "zknl" then
                        local WORDS = {}
                        for W in string.gmatch(LINE, "%w+") do
                            WORDS[#WORDS + 1] = W
                        end
                        if WORDS[3] then
                            ZKNL_SIZE = WORDS[3]
                            cprint("  分区 zknl 大小: " .. ZKNL_SIZE)
                        end
                    end
                end
                PART_TBL:close()
            end
        end

        -- 注: iot-os 固件较大 (~900KB)，默认 zknl 分区 (0x000D2000 = 840KB) 不够
        -- 使用更大的打包尺寸，实际烧录时需根据分区调整
        local ZKNL_SIZE_NUM = tonumber(ZKNL_SIZE)
        -- 如果分区尺寸小于 2MB，使用 4MB 作为打包尺寸 (适配 iot-os 大固件)
        if ZKNL_SIZE_NUM < 0x200000 then
            cprint("${bright yellow}注意: zknl 分区较小 (" .. ZKNL_SIZE .. "), 使用更大的打包尺寸${clear}")
            ZKNL_SIZE = "0x400000"
            cprint("  打包尺寸: " .. ZKNL_SIZE)
        end

        -- 提取各段为二进制
        os.exec(OBJCPY .. " -j .itcm -I elf32-littleriscv " .. TARGET .. " -O binary " .. BIN_DIR .. "/ap_ilm.bin\n")
        os.exec(OBJCPY .. " -j .dtcm -I elf32-littleriscv " .. TARGET .. " -O binary " .. BIN_DIR .. "/ap_dlm.bin\n")
        os.exec(OBJCPY .. " -j .iram0_psm_re -I elf32-littleriscv " .. TARGET .. " -O binary " .. BIN_DIR .. "/ap_psm.bin\n")
        os.exec(OBJCPY .. " -j .iram2 -I elf32-littleriscv " .. TARGET .. " -O binary " .. BIN_DIR .. "/ap_iram2.bin\n")
        os.exec(OBJCPY .. " -j .psram -j .text -j .rodata -j .dlmo -j .data -I elf32-littleriscv " .. TARGET .. " -O binary " .. BIN_DIR .. "/ap_ddr.bin\n")

        -- 合并各段为 zap.bin
        os.exec(MK_MERGE ..
            " --addr=0x800FE800 --bin=" .. BIN_DIR .. "/ap_ddr.bin" ..
            " --addr=0x00008000 --bin=" .. BIN_DIR .. "/ap_ilm.bin" ..
            " --addr=0x00010000 --bin=" .. BIN_DIR .. "/ap_dlm.bin" ..
            " --addr=0xC0200800 --bin=" .. BIN_DIR .. "/ap_psm.bin" ..
            " --addr=0xC026C800 --bin=" .. BIN_DIR .. "/ap_iram2.bin" ..
            " --output=" .. BIN_DIR .. "/zap.bin\n")

        -- 清理临时二进制
        os.rm(BIN_DIR .. "/ap_ilm.bin")
        os.rm(BIN_DIR .. "/ap_dlm.bin")
        os.rm(BIN_DIR .. "/ap_psm.bin")
        os.rm(BIN_DIR .. "/ap_iram2.bin")
        os.rm(BIN_DIR .. "/ap_ddr.bin")

        -- 拷贝 ELF 和 MAP 到输出目录
        local ELF_SRC = "$(buildir)/iot-os/cpu-ap.elf"
        local MAP_SRC = "$(buildir)/iot-os/cpu-ap.map"
        if os.exists(ELF_SRC) then os.cp(ELF_SRC, BIN_DIR) end
        if os.exists(MAP_SRC) then os.cp(MAP_SRC, BIN_DIR) end

        -- 打包 zknl.img (CP + AP 固件)
        if os.exists(CP_BIN_DIR .. "/zcp.bin") then
            os.exec(MK_IMAGE ..
                " --size=" .. ZKNL_SIZE ..
                " --cpuCp=" .. CP_BIN_DIR .. "/zcp.bin" ..
                " --cpuCpLoadAddr=0x80000000 --cpuCpEntry=0xF5000000 --cpuCpMultiSections" ..
                " --cpuAp=" .. BIN_DIR .. "/zap.bin" ..
                " --cpuApLoadAddr=0x800FE800 --cpuApEntry=0x00008000 --cpuApMultiSections" ..
                " --packSize=0x40 --output=" .. BIN_DIR .. "/zknl.img\n")
            cprint("${bright green}zknl.img 生成成功${clear}")
        else
            cprint("${bright yellow}注意: 未找到 CP 固件 (zcp.bin), 跳过 zknl.img 打包${clear}")
            cprint("  AP 固件已生成: " .. BIN_DIR .. "/zap.bin")
        end

        -- 拷贝固件到版本目录
        if os.exists(BIN_DIR .. "/cpu-ap.elf") then os.cp(BIN_DIR .. "/cpu-ap.elf", VERSION_DIR) end
        if os.exists(BIN_DIR .. "/zknl.img") then os.cp(BIN_DIR .. "/zknl.img", VERSION_DIR) end
        if os.exists(BIN_DIR .. "/cpu-ap.map") then os.cp(BIN_DIR .. "/cpu-ap.map", VERSION_DIR) end

        cprint("============================================================")
        cprint("  ML307N 固件构建完成!")
        cprint("  输出目录: " .. BIN_DIR)
        if os.exists(BIN_DIR .. "/zknl.img") then
            cprint("  固件文件: " .. BIN_DIR .. "/zknl.img")
        else
            cprint("  AP 固件:  " .. BIN_DIR .. "/zap.bin")
        end
        cprint("============================================================")
    end)

target_end()

-----------------------------------------------------------------------
-- 辅助目标已合并到 cpu-ap.elf 的 before_build 钩子
-----------------------------------------------------------------------
