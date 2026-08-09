@echo off
REM ============================================================
REM  iot-os ML307N 平台固件构建脚本
REM  使用方法: build_ml307n.bat
REM ============================================================

setlocal enabledelayedexpansion

REM 切换到项目根目录
cd /d "%~dp0"

echo ============================================================
echo   iot-os ML307N 固件构建
echo ============================================================
echo.

REM 检查 xmake 是否可用
where xmake >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 xmake，请先安装 xmake 构建工具
    echo 下载地址: https://xmake.io
    pause
    exit /b 1
)

REM 清理旧构建
echo [1/3] 清理旧构建...
if exist "bin\.build\cpu-ap" (
    rmdir /s /q "bin\.build\cpu-ap"
)

REM 配置项目 (指定 ML307N 平台)
echo [2/3] 配置构建 (platform=ml307n)...
xmake f -y --platform=ml307n --buildir=bin/.build/cpu-ap
if %errorlevel% neq 0 (
    echo [错误] 配置失败
    pause
    exit /b 1
)

REM 编译项目
echo [3/3] 编译 iot-os 固件...
xmake build -y
if %errorlevel% neq 0 (
    echo [错误] 编译失败
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   构建完成!
echo   输出目录: bin\.build\cpu-ap\iot-os\ap\
echo   固件文件: bin\.build\cpu-ap\iot-os\ap\zknl.img
echo ============================================================
pause
