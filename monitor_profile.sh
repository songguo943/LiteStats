#!/usr/bin/env bash

PID=$(pgrep -i MacMonitor | head -n 1)

if [ -z "$PID" ]; then
    echo "❌ MacMonitor 未在运行，请先启动程序！"
    exit 1
fi

LOG_FILE="perf_monitor.log"
echo "Timestamp,CPU_Percent,RAM_MB,Threads,Power" > "$LOG_FILE"

echo "📊 开始对 MacMonitor (PID: $PID) 进行长时间性能采样监控..."
echo "采样日志保存至: $(pwd)/$LOG_FILE"

for i in $(seq 1 30); do
    TIMESTAMP=$(date "+%H:%M:%S")
    TOP_LINE=$(top -l 1 -pid $PID | grep "^$PID" || true)
    if [ -n "$TOP_LINE" ]; then
        CPU=$(echo "$TOP_LINE" | awk '{print $3}')
        MEM=$(echo "$TOP_LINE" | awk '{print $8}' | sed 's/M//' | sed 's/K//')
        TH=$(echo "$TOP_LINE" | awk '{print $5}')
        POWER=$(echo "$TOP_LINE" | awk '{print $19}')
        
        echo "[$TIMESTAMP] CPU: ${CPU}% | RAM: ${MEM}MB | Threads: ${TH} | Power: ${POWER}"
        echo "$TIMESTAMP,$CPU,$MEM,$TH,$POWER" >> "$LOG_FILE"
    fi
    sleep 2
done

echo ""
echo "✅ 60 秒连续采样完成！分析报告如下："
awk -F',' 'NR>1 {
    cpu_sum+=$2; mem_sum+=$3;
    if(min_cpu=="" || $2<min_cpu) min_cpu=$2;
    if(max_cpu=="" || $2>max_cpu) max_cpu=$2;
    if(min_mem=="" || $3<min_mem) min_mem=$3;
    if(max_mem=="" || $3>max_mem) max_mem=$3;
    count++;
} END {
    if (count > 0) {
        printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        printf "⏱ 采样总次数: %d 次 (连续 60 秒实时监控)\n", count;
        printf "⚡ CPU 使用率: 平均 %.2f%%  |  最小 %.1f%%  |  最大 %.1f%%\n", cpu_sum/count, min_cpu, max_cpu;
        printf "🧠 内存占用 (RSS): 平均 %.2f MB |  最小 %.1f MB |  最大 %.1f MB\n", mem_sum/count, min_mem, max_mem;
        printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    }
}' "$LOG_FILE"
