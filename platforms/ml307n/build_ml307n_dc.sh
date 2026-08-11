#!/bin/bash
###################################################################################
#
#  iot-os ML307N-DC 固件一键编译脚本
#  基于 CM8620OC-V1.1.1-SDK 构建 iot-os 固件升级包
#
#  用法:
#    ./build_ml307n_dc.sh              # 完整构建 (清理+配置+编译+打包)
#    ./build_ml307n_dc.sh clean        # 仅清理
#    ./build_ml307n_dc.sh build        # 仅编译 (不清理)
#    ./build_ml307n_dc.sh package      # 仅打包 (使用已有编译产物)
#    ./build_ml307n_dc.sh lvgl         # 启用 LVGL 编译
#
###################################################################################

set -e

# ============================================================
# 路径定义
# ============================================================
PLAT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_ROOT="${PLAT_DIR}/CM8620OC-V1.1.1-SDK"
SDK_CODE="${SDK_ROOT}/code"
SDK_TOOLCHAIN="${SDK_ROOT}/ict-build/ZCnuclei/win"
SDK_PREBUILD="${SDK_CODE}/prebuild/mdl"
SDK_MKTOOLS="${SDK_CODE}/tools/mkimg"
PROJECT_ROOT="${PLAT_DIR}/../.."
BUILD_DIR="${PLAT_DIR}/build/ml307n"
OUTPUT_DIR="${BUILD_DIR}/iot-os/ap"
STAGING_DIR="${BUILD_DIR}/staging"

# ============================================================
# 配置
# ============================================================
PROJECT_NAME="ml307n-dc"
BOARD_NAME="ml307n_dc"
BUILD_TYPE="${1:-all}"
ENABLE_LVGL="${ENABLE_LVGL:-n}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step()  { echo -e "\n${CYAN}======== $* ========${NC}\n"; }

# ============================================================
# 检查环境
# ============================================================
check_env() {
    log_step "检查环境"

    # 检查路径
    if [ ! -d "${PLAT_DIR}" ]; then
        log_error "平台目录不存在: ${PLAT_DIR}"
        exit 1
    fi

    if [ ! -d "${SDK_CODE}" ]; then
        log_error "SDK 代码目录不存在: ${SDK_CODE}"
        exit 1
    fi

    if [ ! -f "${PLAT_DIR}/xmake.lua" ]; then
        log_error "平台 xmake.lua 不存在: ${PLAT_DIR}/xmake.lua"
        exit 1
    fi

    # 检查 xmake
    if ! command -v xmake &>/dev/null; then
        log_error "未找到 xmake，请先安装 xmake 构建工具"
        log_error "下载地址: https://github.com/xmake-io/xmake"
        exit 1
    fi
    log_info "xmake 版本: $(xmake --version 2>&1 | head -1)"

    # 检查 Python
    if ! command -v python &>/dev/null && ! command -v python3 &>/dev/null; then
        log_error "未找到 Python (bin2one.py 需要)"
        exit 1
    fi
    PYTHON_BIN="python3"
    if command -v python &>/dev/null; then
        PYTHON_BIN="python"
    fi
    log_info "Python: ${PYTHON_BIN}"

    # 检查工具链
    if [ -d "${SDK_TOOLCHAIN}" ]; then
        log_info "工具链: ${SDK_TOOLCHAIN}"
    else
        log_warn "工具链目录不存在: ${SDK_TOOLCHAIN} (编译时会再次检查)"
    fi

    log_info "平台目录: ${PLAT_DIR}"
    log_info "SDK 目录: ${SDK_CODE}"
    log_info "项目根目录: ${PROJECT_ROOT}"
}

# ============================================================
# 清理构建
# ============================================================
clean_build() {
    log_step "清理构建产物"

    if [ -d "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}"
        log_info "已删除: ${BUILD_DIR}"
    fi

    # 清理 SDK bin 目录中的临时文件
    if [ -d "${SDK_CODE}/bin/version" ]; then
        rm -rf "${SDK_CODE}/bin/version"
        log_info "已清理 SDK bin/version"
    fi

    # 清理 xmake 缓存
    if [ -d "${PLAT_DIR}/.xmake" ]; then
        rm -rf "${PLAT_DIR}/.xmake"
        log_info "已清理 xmake 缓存"
    fi

    log_info "清理完成"
}

# ============================================================
# 配置编译
# ============================================================
configure_build() {
    log_step "配置 xmake 编译"

    cd "${PLAT_DIR}"

    local CONFIG_OPTS=""

    # 基本配置
    CONFIG_OPTS="--board=${BOARD_NAME} --sdkver=mdl"

    # LVGL 选项
    if [ "${ENABLE_LVGL}" = "y" ]; then
        CONFIG_OPTS="${CONFIG_OPTS} --enable_lvgl=y"
        log_info "LVGL: 已启用"
    fi

    # 使用默认 buildir (build/ml307n)
    log_info "xmake 配置选项: ${CONFIG_OPTS}"
    xmake f ${CONFIG_OPTS} 2>&1 | tee configure.log

    log_info "配置完成"
}

# ============================================================
# 执行编译
# ============================================================
run_build() {
    log_step "执行 xmake 编译"

    cd "${PLAT_DIR}"

    local BUILD_OPTS=""
    if [ "${ENABLE_LVGL}" = "y" ]; then
        export ENABLE_LVGL=y
    fi

    log_info "开始编译..."
    local START_TIME=$(date +%H:%M:%S)

    xmake -r -w 2>&1 | tee build_ml307n.log
    local BUILD_RESULT=$?

    local END_TIME=$(date +%H:%M:%S)

    if [ ${BUILD_RESULT} -ne 0 ]; then
        log_error "编译失败! 请查看 build_ml307n.log"
        exit 1
    fi

    log_info "编译完成 (${START_TIME} - ${END_TIME})"

    # 检查输出
    if [ -f "${OUTPUT_DIR}/zap.bin" ]; then
        log_info "AP 固件: ${OUTPUT_DIR}/zap.bin ($(stat -c%s "${OUTPUT_DIR}/zap.bin" 2>/dev/null || stat -f%z "${OUTPUT_DIR}/zap.bin" 2>/dev/null || echo '?') bytes)"
    fi

    if [ -f "${OUTPUT_DIR}/zknl.img" ]; then
        log_info "全固件: ${OUTPUT_DIR}/zknl.img"
    else
        log_warn "未找到 zknl.img (可能缺少 CP 固件 zcp.bin)，将使用 zap.bin"
    fi
}

# ============================================================
# 收集固件文件到暂存目录
# ============================================================
stage_files() {
    log_step "收集固件文件"

    local VERSION_DIR="${SDK_CODE}/bin/version"

    # 清理旧的暂存
    rm -rf "${VERSION_DIR}"
    mkdir -p "${VERSION_DIR}"

    # 1. 复制启动文件 (mbl, xboot)
    log_info "复制启动文件..."
    for f in mbl.bin mbl.img mbl.elf xboot.bin xboot.img xboot.elf; do
        if [ -f "${SDK_PREBUILD}/boot/${f}" ]; then
            cp -f "${SDK_PREBUILD}/boot/${f}" "${VERSION_DIR}/"
            log_info "  ${f}"
        fi
    done

    # 2. 复制 NV 文件
    log_info "复制 NV 文件..."
    if [ -f "${SDK_PREBUILD}/nv/nv_submod/nvd_full_0x00000000.bin" ]; then
        cp -f "${SDK_PREBUILD}/nv/nv_submod/nvd_full_0x00000000.bin" "${VERSION_DIR}/"
        log_info "  nvd_full_0x00000000.bin"
    elif [ -f "${SDK_PREBUILD}/nv/nv_submod/nvd_Modem_0x00000000.bin" ]; then
        cp -f "${SDK_PREBUILD}/nv/nv_submod/nvd_Modem_0x00000000.bin" "${VERSION_DIR}/nvd_full_0x00000000.bin"
        log_info "  nvd_full_0x00000000.bin (from nvd_Modem_0x00000000.bin)"
    fi

    # 3. 复制固件
    log_info "复制编译产物..."
    local FW_FILE=""
    if [ -f "${OUTPUT_DIR}/zknl.img" ]; then
        cp -f "${OUTPUT_DIR}/zknl.img" "${VERSION_DIR}/"
        FW_FILE="zknl.img"
        log_info "  zknl.img"
    elif [ -f "${OUTPUT_DIR}/zap.bin" ]; then
        cp -f "${OUTPUT_DIR}/zap.bin" "${VERSION_DIR}/zknl.img"
        FW_FILE="zap.bin (重命名为 zknl.img)"
        log_info "  zap.bin -> zknl.img"
    else
        log_error "未找到编译产物 (zknl.img 或 zap.bin)!"
        log_error "请先执行编译: ./build_ml307n_dc.sh build"
        exit 1
    fi

    # 4. 复制 xknl.img (XIP 模式, 可选)
    if [ -f "${OUTPUT_DIR}/xknl.img" ]; then
        cp -f "${OUTPUT_DIR}/xknl.img" "${VERSION_DIR}/"
        log_info "  xknl.img"
    else
        log_warn "  xknl.img 不存在 (XIP 模式固件)，跳过"
    fi

    # 5. 生成 partition.cfg (如果不存在)
    if [ ! -f "${OUTPUT_DIR}/partition.cfg" ]; then
        log_info "生成 partition.cfg..."
        local PARTITION_NAME="xpartition.ini"
        local BOARD_CFG="${SDK_CODE}/src/board/${BOARD_NAME}/cfg/${PARTITION_NAME}"
        if [ ! -f "${BOARD_CFG}" ]; then
            PARTITION_NAME="npartition.ini"
            BOARD_CFG="${SDK_CODE}/src/board/${BOARD_NAME}/cfg/${PARTITION_NAME}"
        fi

        if [ -f "${BOARD_CFG}" ]; then
            ${PYTHON_BIN} "${SDK_CODE}/tools/partition.py" "${BOARD_CFG}" "${VERSION_DIR}/partition.cfg" 2>&1 || {
                log_warn "partition.cfg 生成失败，尝试复制 ${PARTITION_NAME}"
                cp -f "${BOARD_CFG}" "${VERSION_DIR}/partition.cfg" 2>/dev/null || true
            }
        else
            log_warn "未找到分区配置文件，跳过 partition.cfg"
        fi
    else
        cp -f "${OUTPUT_DIR}/partition.cfg" "${VERSION_DIR}/"
        log_info "  partition.cfg"
    fi

    # 6. 复制配置 XML 文件
    for f in type.xml rule.xml nvToolCfg.json; do
        if [ -f "${SDK_PREBUILD}/${f}" ]; then
            cp -f "${SDK_PREBUILD}/${f}" "${VERSION_DIR}/"
            log_info "  ${f}"
        fi
    done

    # 显示暂存目录内容
    log_info "暂存目录内容 (${VERSION_DIR}):"
    ls -lh "${VERSION_DIR}/" 2>/dev/null || true
}

# ============================================================
# 生成升级包 (one.bin)
# ============================================================
package_upgrade() {
    log_step "生成升级包 one.bin"

    local VERSION_DIR="${SDK_CODE}/bin/version"

    if [ ! -d "${VERSION_DIR}" ]; then
        log_error "暂存目录不存在: ${VERSION_DIR}"
        log_error "请先执行: ./build_ml307n_dc.sh build"
        exit 1
    fi

    # 显示 binfiles.ini 中各文件的状态
    log_info "检查 binfiles.ini 中的文件:"
    local INI_FILE="${SDK_CODE}/tools/binfiles.ini"
    if [ -f "${INI_FILE}" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            local fname=$(echo "$line" | tr -d '[:space:]')
            [ -z "$fname" ] && continue
            if [ -f "${VERSION_DIR}/${fname}" ]; then
                local fsize=$(stat -c%s "${VERSION_DIR}/${fname}" 2>/dev/null || stat -f%z "${VERSION_DIR}/${fname}" 2>/dev/null || echo "?")
                log_info "  [存在] ${fname} (${fsize} bytes)"
            else
                log_warn "  [缺失] ${fname} - 将跳过"
            fi
        done < "${INI_FILE}"
    fi

    # 执行 bin2one.py
    cd "${SDK_CODE}"
    log_info "执行 bin2one.py ..."
    ${PYTHON_BIN} tools/bin2one.py "${SDK_CODE}" 2>&1
    local RESULT=$?

    if [ ${RESULT} -ne 0 ]; then
        log_error "one.bin 生成失败!"
        exit 1
    fi

    # 复制 one.bin 到输出目录
    local ONE_BIN="${SDK_CODE}/bin/one.bin"
    if [ -f "${ONE_BIN}" ]; then
        mkdir -p "${BUILD_DIR}/release"
        cp -f "${ONE_BIN}" "${BUILD_DIR}/release/one.bin"

        # 同时复制固件文件到 release
        cp -f "${OUTPUT_DIR}/zap.bin" "${BUILD_DIR}/release/" 2>/dev/null || true
        cp -f "${OUTPUT_DIR}/zknl.img" "${BUILD_DIR}/release/" 2>/dev/null || true
        cp -f "${OUTPUT_DIR}/xknl.img" "${BUILD_DIR}/release/" 2>/dev/null || true
        cp -f "${OUTPUT_DIR}/cpu-ap.elf" "${BUILD_DIR}/release/" 2>/dev/null || true
        cp -f "${OUTPUT_DIR}/cpu-ap.map" "${BUILD_DIR}/release/" 2>/dev/null || true

        log_info "升级包已生成: ${BUILD_DIR}/release/"
        ls -lh "${BUILD_DIR}/release/"
    fi
}

# ============================================================
# 显示结果
# ============================================================
show_result() {
    log_step "构建完成"

    log_info "=============================================="
    log_info "  iot-os ML307N-DC 固件构建完成"
    log_info "=============================================="
    log_info ""
    log_info "编译产物:"
    if [ -d "${OUTPUT_DIR}" ]; then
        ls -lh "${OUTPUT_DIR}/" 2>/dev/null | head -20
    fi
    log_info ""
    log_info "升级包:"
    if [ -d "${BUILD_DIR}/release" ]; then
        ls -lh "${BUILD_DIR}/release/" 2>/dev/null
    fi
    log_info ""
    log_info "输出目录: ${BUILD_DIR}"
    log_info "=============================================="
}

# ============================================================
# 主流程
# ============================================================
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║   iot-os ML307N-DC 固件一键编译脚本             ║"
    echo "║   基于 CM8620OC-V1.1.1-SDK                     ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    case "${BUILD_TYPE}" in
        clean)
            check_env
            clean_build
            log_info "清理完成，可执行 ./build_ml307n_dc.sh 开始构建"
            ;;
        build)
            check_env
            configure_build
            run_build
            stage_files
            show_result
            ;;
        package)
            check_env
            stage_files
            package_upgrade
            show_result
            ;;
        all|"")
            check_env
            clean_build
            configure_build
            run_build
            stage_files
            package_upgrade
            show_result
            ;;
        *)
            echo "用法: $0 {all|clean|build|package}"
            echo ""
            echo "  all      完整构建 (清理+配置+编译+打包) [默认]"
            echo "  clean    仅清理构建产物"
            echo "  build    编译固件 (不清理)"
            echo "  package  仅打包 (使用已有编译产物)"
            echo ""
            echo "环境变量:"
            echo "  ENABLE_LVGL=y    启用 LVGL 编译 (体积较大)"
            exit 1
            ;;
    esac
}

main