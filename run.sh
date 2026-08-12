#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

if [ ! -d "/Applications/LiteStats.app" ]; then
    echo "⚠️ 尚未安装，正在进行编译与安装..."
    chmod +x build.sh
    ./build.sh
fi

echo "🚀 启动 LiteStats (/Applications/LiteStats.app)..."
open "/Applications/LiteStats.app"
