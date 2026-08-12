#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

if [ ! -d "$DIR/build/LiteStats.app" ]; then
    echo "⚠️ 尚未编译，正在进行首次编译..."
    chmod +x build.sh
    ./build.sh
fi

echo "🚀 启动 LiteStats (常驻菜单栏)..."
open "$DIR/build/LiteStats.app"
