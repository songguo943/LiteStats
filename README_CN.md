# 🚀 LiteStats - 原生极轻量级 macOS CPU / 内存 / 风扇 菜单栏监控工具

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013.0%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-brightgreen" alt="Arch">
  <img src="https://img.shields.io/badge/Language-Swift%206%20%7C%20C-orange" alt="Language">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

[English README](./README.md) | [中文说明](./README_CN.md)

---

## 📌 背景与设计初衷 (Background & Motivation)

在 macOS 上，我们经常需要监控 CPU 负载、内存使用和风扇转速。然而，市面上许多知名的监控工具（如 Stats、iStat Menus 或基于 Electron / Webview 的小工具）：
- ❌ **资源占用偏大**：往往需要占用 **150MB ~ 300MB** 的内存及 **2% ~ 5%** 的常驻 CPU 负载。
- ❌ **任务栏空间浪费**：横向文本过长，严重挤占 MacBook 刘海屏（Notch）及顶部菜单栏空间。
- ❌ **发热与续航隐患**：后台轮询效率低下，容易导致轻微发热和电池额外消耗。

**LiteStats** 由此诞生！旨在打造一款 **真正的原生零负担 (Zero-Bloat)** macOS 常驻监控应用：
- ⚡ **内存占用低于 37 MB**，**CPU 占用率稳定在 0.0%**（相比同类减少 **99%** 性能开销）。
- 📐 **上下双层精紧凑排版**（上层 `CPU / RAM / FAN`，下层实时数值），极致节省刘海屏横向空间。
- 🌀 **原生 C 语言 AppleSMC 硬件对接**，完美支持 MacBook Pro / Air / Mac Studio 等双风扇及静音架构。

---

## ✨ 核心功能特性 (Key Features)

1. **常驻顶部菜单栏 (上下垂直紧凑排版)**
   - 采用 22pt 高度空间上下双层对齐（`CPU  RAM  FAN` / `24%  66% 2320`），横向宽度收窄 60%。
   - 支持独立开关 CPU、内存、风扇单项显示。
   - 自动适应 macOS 深色 (Dark Mode) 与浅色 (Light Mode) 主题高对比自适应。

2. **PopOver 弹层与详细数据视图**
   - 📈 **60s 动态趋势折线图**：实时显示 CPU 与内存的动态波动。
   - 🔲 **CPU 核心独立监控**：多核心（P核/E核）粒度独立负载柱状图。
   - 🧠 **内存使用分布**：精准统计 App 内存、紧致 (Wired)、已压缩 (Compressed)、空闲 (Free) 与 Swap 交换区。
   - 🌀 **SMC 双风扇转速监控**：底层 C 语言精准解析左风扇与右风扇 RPM 转速（无风扇机型自动智能识别为 Fanless）。
   - 🔝 **Top 5 资源大户进程**：实时刷新 CPU/内存占用最高的前 5 个进程，支持一键强行结束进程 (Kill)。

3. **原生高效驱动 (Native Performance)**
   - 使用 Swift 6 + Mach 内核 C API (`host_processor_info` / `host_statistics64`) + IOKit AppleSMC 80 字节数据对齐，无任何第三方臃肿依赖。

---

## 📊 性能实测数据 (Benchmark)

在 M-Series MacBook Pro 上的 10 分钟 (120 次采样) 连续实测结果：

| 性能指标 | LiteStats 实测数据 | 同类工具 (如 Electron 类) | 优势 |
| :--- | :--- | :--- | :--- |
| **应用包体积** | **656 KB** | ~150 MB - 300 MB | 🟢 小 **99.6%** |
| **物理内存 (RSS)** | **37 MB** | ~150 MB - 350 MB | 🟢 节省 80%+ 内存 |
| **日常 CPU 占用** | **0.0%** | ~2.0% - 5.0% | 🟢 静默休眠，不耗电 |
| **功耗得分 (Power)**| **0.0** | ~15.0 - 30.0 | 🟢 零电池续航负担 |

---

## 🔨 编译与构建步骤 (Build Guide)

项目采用命令行纯 Swift / C 编译，无需打开庞大的 Xcode IDE，仅需标准 macOS 命令行工具 (Command Line Tools)。

### 前置要求
- macOS 13.0 (Ventura) 或更高版本
- Xcode Command Line Tools (`swiftc` 与 `clang`)

### 一键编译与运行

1. 克隆代码仓库：
   ```bash
   git clone https://github.com/your-username/LiteStats.git
   cd LiteStats
   ```

2. 赋予脚本执行权限并编译：
   ```bash
   chmod +x build.sh run.sh
   ./build.sh
   ```
   *编译成功后，应用包将自动生成至 `build/LiteStats.app`。*

3. 启动应用：
   ```bash
   ./run.sh
   ```
   *也可以在 Finder 中双击 `build/LiteStats.app` 或将其拖入 `/Applications` 文件夹随时使用。*

---

## 📁 项目目录结构

```
LiteStats/
├── build/
│   └── LiteStats.app            # 编译生成的打包应用
├── Sources/
│   ├── Main.swift              # 程序入口点与 NSApplication 声明
│   ├── SMCBridge.h             # C 语言 SMC 驱动头文件 (80 字节结构)
│   ├── SMCBridge.c             # C 语言 AppleSMC 读取实现 (FNum, F0Ac, F1Ac)
│   ├── SMCReader.swift         # Swift 风扇适配器
│   ├── SystemMonitor.swift     # Darwin / Mach C API 系统数据采样
│   ├── ProcessManager.swift    # Top 5 进程采样与强制 Kill 功能
│   ├── StatusBarController.swift # 菜单栏 2 行垂直布局控制
│   ├── MonitorView.swift       # SwiftUI Popover 下拉毛玻璃面板
│   └── SettingsStore.swift     # 偏好设置持久化存储
├── Info.plist                  # 隐藏 Dock 图标配置 (LSUIElement=true)
├── build.sh                    # 一键编译打包脚本
├── run.sh                      # 一键运行脚本
├── LICENSE                     # 开源协议
└── README.md                   # 项目说明
```

---

## 📜 开源协议与建议 (License Options)

本项目采用 **MIT License**。

### 协议建议说明：
- **MIT License (推荐)**：极其宽松，允许所有人免费使用、修改、分发及商业化，适合个人开发者开源实用工具。
- **GPL-3.0**：传染性开源协议，要求衍生作品必须同样开源，适合希望防止代码被闭源商业软件直接包含的项目。
- **Apache 2.0**：类似 MIT 但包含专利授权条款，适合大型团队项目。

---

## 🤝 贡献与反馈 (Contributing)

欢迎提交 Issue 和 Pull Request 来完善 LiteStats！如果你觉得这个工具对你有帮助，欢迎点个 ⭐ Star！
