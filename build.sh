#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔨 开始编译 LiteStats (Swift 原生轻量级 CPU/内存/风扇监控程序)..."

SDK_PATH=$(xcrun --show-sdk-path)
APP_NAME="LiteStats"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "⚡ 编译 C SMCBridge..."
clang -O2 \
    -isysroot "$SDK_PATH" \
    -target arm64-apple-macosx13.0 \
    -c Sources/SMCBridge.c \
    -o "$BUILD_DIR/SMCBridge.o"

echo "⚡ 编译 Swift 源文件..."
swiftc -O \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx13.0 \
    -import-objc-header Sources/SMCBridge.h \
    "$BUILD_DIR/SMCBridge.o" \
    Sources/SettingsStore.swift \
    Sources/SMCReader.swift \
    Sources/SystemMonitor.swift \
    Sources/ProcessManager.swift \
    Sources/MonitorView.swift \
    Sources/StatusBarController.swift \
    Sources/Main.swift \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "✅ 编译完成！程序已生成至: $APP_BUNDLE"
echo "🚀 可双击 $APP_BUNDLE 运行或执行 ./run.sh 启动！"
