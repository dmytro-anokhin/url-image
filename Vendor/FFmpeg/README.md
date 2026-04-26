# URLImage FFmpeg Vendor Drop

This directory is reserved for the vendored FFmpeg binary used by `URLImageFFmpeg`.

Recommended final shape:

1. Build or vendor a signed Apple-platform FFmpeg CLI/library wrapper as an `.xcframework` with slices for `ios-arm64`, `ios-arm64_x86_64-simulator`, `macos-arm64_x86_64`.
2. Expose a C entry point compatible with `urlimage_ffmpeg_execute(int32_t argc, char * const argv[])`, or replace `Sources/CURLImageFFmpeg/URLImageFFmpegBridge.c` with a bridge that calls the vendor's `ffmpeg_main`.
3. Add a local SwiftPM binary target in `Package.swift`, for example:

```swift
.binaryTarget(
    name: "CFFmpegBinary",
    path: "Vendor/FFmpeg/CFFmpegBinary.xcframework"
)
```

4. Add `"CFFmpegBinary"` as a dependency of the `CURLImageFFmpeg` target after the binary exists locally.

Do not rely on `/opt/homebrew/bin/ffmpeg`, `/usr/local/bin/ffmpeg`, or any other host command-line path. CloudSailor/SnowX macOS builds are sandboxed and hardened, and iOS cannot use an external executable path.

Prefer a VideoToolbox-backed H.264 encoder (`h264_videotoolbox`) for iOS/macOS distribution. Bundling `libx264` normally changes the licensing obligations and should be treated as an explicit product/legal decision.
