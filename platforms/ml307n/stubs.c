/**
 * @file stubs.c
 * @brief ML307N SDK 未定义符号的桩实现
 *
 * 此文件提供 SDK 预编译库所需的外部符号定义, 避免链接错误.
 * 实际项目应提供完整实现 (board.c 等).
 */
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

typedef uint8_t bool_t_def;
#define bool_t bool_t_def

/*===========================================================
 * Dump 日志控制 (libramdump.a 引用)
 *===========================================================*/
bool_t g_dumpLogEnable = 1;
bool_t g_consoleOutputEnable = 1;

/*===========================================================
 * Board 相关函数 (libramdump.a / libshell.a 引用)
 *===========================================================*/
uint32_t Board_GetLogUartBaudRate(void) { return 115200; }
bool_t Board_GetLogUartFlowCtrlEnable(void) { return 0; }

/*===========================================================
 * UART 相关 (libshell.a / libat_command.a 引用)
 *===========================================================*/
int UART_PollSend(int uart, const uint8_t* data, uint32_t len) { (void)uart; (void)data; (void)len; return 0; }
int AT_UARTWaitTxComplete(int uart) { (void)uart; return 0; }
void* osGetDumpUartRegBase(void) { return 0; }

/*===========================================================
 * 网络接口查询 (libat_ps.a / libonemo.a 引用)
 *===========================================================*/
typedef struct {
    uint32_t ip_flg;
    uint32_t ip4_addr;
    uint8_t  ip6_addr[16];
} NET_ApiIfInfo;

int NET_ApiIfInfoGetByCid(uint8_t cid, NET_ApiIfInfo* info) {
    (void)cid;
    if (info) {
        memset(info, 0, sizeof(*info));
    }
    return -1;
}

/*===========================================================
 * URC 处理 (libonemo.a 引用)
 *===========================================================*/
int APP_URC_AddHandler(void* handler) { (void)handler; return 0; }
int APP_URC_DelHandler(void* handler) { (void)handler; return 0; }

/*===========================================================
 * Audio Codec (libaudio.a 引用)
 *===========================================================*/
int es8311_read_reg(uint8_t reg, uint8_t* val) { (void)reg; if (val) *val = 0; return 0; }
int es8311_write_reg(uint8_t reg, uint8_t val) { (void)reg; (void)val; return 0; }

/*===========================================================
 * 电源/时钟/系统控制 (libdrv.a / libramdump.a 引用)
 *===========================================================*/
int SYSCTRL_SetAonRegGen(uint32_t addr, uint32_t val) { (void)addr; (void)val; return 0; }
int SYSCTRL_SetPdRegGen(uint32_t addr, uint32_t val) { (void)addr; (void)val; return 0; }
int CLK_SetregGenLbAonCrmRegs(uint32_t mask) { (void)mask; return 0; }
int LDO_BaseInfoInit(void) { return 0; }

/*===========================================================
 * 多路复用/代理 (libnet_startup.a 引用)
 *===========================================================*/
int MuxProxy_Control_IpConnect(int enable) { (void)enable; return 0; }
int MuxProxy_IP_ShowStatistic(int type) { (void)type; return 0; }

/*===========================================================
 * OTA/AT 相关 (libota.a 引用)
 *===========================================================*/
void* Board_GetAtUartHandle(void) { return 0; }
uint32_t UART_GetCurrentBaudRate(int uart) { (void)uart; return 115200; }
int UART_CheckUartIdleSupport(int uart) { (void)uart; return 1; }

/*===========================================================
 * 版本信息 (libramdump.a 引用)
 *===========================================================*/
const char* VER_GetBuildVersion(void) { return "iot-os-ml307n"; }

/*===========================================================
 * 底层驱动桩 (libdrv.a 引用: LDO/PIN/GPIO)
 *===========================================================*/
int LDO_SetReg(uint32_t addr, uint32_t val) { (void)addr; (void)val; return 0; }
int PIN_SetDrCap(uint32_t pin, uint32_t cap) { (void)pin; (void)cap; return 0; }
int PIN_SetMux(uint32_t pin, uint32_t mux) { (void)pin; (void)mux; return 0; }
int GPIO_Write(uint32_t pin, uint32_t val) { (void)pin; (void)val; return 0; }
int GPIO_SetDir(uint32_t pin, uint32_t dir) { (void)pin; (void)dir; return 0; }
