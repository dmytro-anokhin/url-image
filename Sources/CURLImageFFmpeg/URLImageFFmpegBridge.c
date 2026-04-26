#include "URLImageFFmpegBridge.h"

int32_t urlimage_ffmpeg_is_linked(void) {
    return 0;
}

int32_t urlimage_ffmpeg_execute(int32_t argc, char * const argv[]) {
    (void)argc;
    (void)argv;
    return -1;
}

const char *urlimage_ffmpeg_configuration(void) {
    return "URLImageFFmpeg bridge stub: FFmpeg binary is not linked";
}
