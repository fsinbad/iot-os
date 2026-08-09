/**
 * @file iot_qrcode.h
 * @brief ML307N QR码接口定义
 */

#ifndef IOT_PLATFORM_ML307N_QRCODE_H
#define IOT_PLATFORM_ML307N_QRCODE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* QR码纠错等级 */
#define IOT_QR_ECC_L  0    /**< 低纠错 (~7%) */
#define IOT_QR_ECC_M  1    /**< 中纠错 (~15%) */
#define IOT_QR_ECC_Q  2    /**< 高纠错 (~25%) */
#define IOT_QR_ECC_H  3    /**< 最高纠错 (~30%) */

/**
 * @brief QR码编码结果
 */
typedef struct {
    uint8_t width;      /**< QR码宽度 (模块数) */
    uint8_t version;    /**< QR码版本 (1-40) */
    uint8_t *data;      /**< QR码模块数据 (0=白, 1=黑) */
    uint32_t data_len;  /**< 数据长度 */
} iot_qrcode_t;

/**
 * @brief 编码QR码
 * @param text 输入文本
 * @param ecc_level 纠错等级 (0-3)
 * @param version 版本 (0=自动, 1-40)
 * @param qr 输出QR码结构 (调用者负责释放data)
 * @return 成功返回 0，失败返回错误码
 */
int iot_qrcode_encode(const char *text, uint8_t ecc_level, uint8_t version, iot_qrcode_t *qr);

/**
 * @brief 解码QR码 (灰度图像)
 * @param image_data 图像数据 (灰度图)
 * @param width 图像宽度
 * @param height 图像高度
 * @param payload 输出数据缓冲区
 * @param payload_size 输入/输出缓冲区大小
 * @return 成功返回 0，失败返回错误码
 */
int iot_qrcode_decode(const uint8_t *image_data, int width, int height, char *payload, uint32_t *payload_size);

/**
 * @brief 统计图像中QR码数量
 * @param image_data 图像数据 (灰度图)
 * @param width 图像宽度
 * @param height 图像高度
 * @return QR码数量，失败返回 -1
 */
int iot_qrcode_count(const uint8_t *image_data, int width, int height);

#ifdef __cplusplus
}
#endif

#endif /* IOT_PLATFORM_ML307N_QRCODE_H */
