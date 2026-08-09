/**
 * @file iot_camera.h
 * @brief ML307N 相机接口定义
 */

#ifndef IOT_PLATFORM_ML307N_CAMERA_H
#define IOT_PLATFORM_ML307N_CAMERA_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* 输出格式常量 */
#define IOT_CAMERA_FMT_YUV422_YUYV    0
#define IOT_CAMERA_FMT_YUV422_YVYU    1
#define IOT_CAMERA_FMT_YUV422_UYVY    2
#define IOT_CAMERA_FMT_YUV422_VYUY    3
#define IOT_CAMERA_FMT_YUV420_NV12    6
#define IOT_CAMERA_FMT_RAW8          10
#define IOT_CAMERA_FMT_RGB565        11
#define IOT_CAMERA_FMT_JPEG          12

/**
 * @brief 相机信息
 */
typedef struct {
    uint32_t width;     /**< 宽度 (像素) */
    uint32_t height;    /**< 高度 (像素) */
    uint32_t format;    /**< 输出格式 */
} iot_camera_info_t;

/**
 * @brief 打开相机
 * @return 成功返回 0，失败返回错误码
 */
int iot_camera_open(void);

/**
 * @brief 关闭相机
 * @return 成功返回 0，失败返回错误码
 */
int iot_camera_close(void);

/**
 * @brief 获取相机信息
 * @param info 相机信息指针
 * @return 成功返回 0，失败返回错误码
 */
int iot_camera_get_info(iot_camera_info_t *info);

/**
 * @brief 拍照并保存到文件
 * @param filename 保存路径
 * @return 成功返回 0，失败返回错误码
 */
int iot_camera_capture_file(const char *filename);

/**
 * @brief 拍照并获取数据
 * @param data 数据缓冲区指针 (由调用者释放)
 * @param len 数据长度
 * @return 成功返回 0，失败返回错误码
 */
int iot_camera_capture_data(uint8_t **data, uint32_t *len);

#ifdef __cplusplus
}
#endif

#endif /* IOT_PLATFORM_ML307N_CAMERA_H */
