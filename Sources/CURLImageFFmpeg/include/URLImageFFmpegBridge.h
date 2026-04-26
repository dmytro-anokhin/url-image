#ifndef URLImageFFmpegBridge_h
#define URLImageFFmpegBridge_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int32_t urlimage_ffmpeg_is_linked(void);
int32_t urlimage_ffmpeg_execute(int32_t argc, char * const argv[]);
const char *urlimage_ffmpeg_configuration(void);

#ifdef __cplusplus
}
#endif

#endif
