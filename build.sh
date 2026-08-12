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
if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

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

echo "📦 正在安装至 macOS 应用程序文件夹 (/Applications/LiteStats.app)..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_BUNDLE" "/Applications/$APP_NAME.app"

echo "✅ 编译与安装完成！图标已更新至 AppIcon.icns！"
echo "🚀 您可以通过 Finder -> 应用程序、Spotlight 聚焦搜索 (Cmd + Space 搜索 LiteStats) 或执行 ./run.sh 手动启动！"
