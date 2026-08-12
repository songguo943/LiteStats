#!/usr/bin/env bash

PID=$(pgrep -i MacMonitor | head -n 1)

if [ -z "$PID" ]; then
    echo "❌ MacMonitor 未在运行，请先启动程序！"
    exit 1
fi

LOG_FILE="longterm_perf.log"
REPORT_FILE="longterm_perf_report.log"

echo "Timestamp,CPU_Percent,RAM_MB,Threads,Power" > "$LOG_FILE"

echo "📊 开始对 MacMonitor (PID: $PID) 进行长达 10 分钟 (600秒/120次采样) 的长时间性能追踪..."
echo "采样数据文件: $(pwd)/$LOG_FILE"
echo "日志分析报告: $(pwd)/$REPORT_FILE"

TOTAL_SAMPLES=120
INTERVAL=5

for i in $(seq 1 $TOTAL_SAMPLES); do
    TIMESTAMP=$(date "+%H:%M:%S")
    TOP_LINE=$(top -l 1 -pid $PID | grep "^$PID" || true)
    if [ -n "$TOP_LINE" ]; then
        CPU=$(echo "$TOP_LINE" | awk '{print $3}')
        MEM=$(echo "$TOP_LINE" | awk '{print $8}' | sed 's/M//' | sed 's/K//')
        TH=$(echo "$TOP_LINE" | awk '{print $5}')
        POWER=$(echo "$TOP_LINE" | awk '{print $19}')
        
        echo "[$i/$TOTAL_SAMPLES] [$TIMESTAMP] CPU: ${CPU}% | RAM: ${MEM}MB | Threads: ${TH} | Power: ${POWER}"
        echo "$TIMESTAMP,$CPU,$MEM,$TH,$POWER" >> "$LOG_FILE"
    fi
    sleep $INTERVAL
done

echo ""
echo "✅ 10 分钟长时间采样完成！生成统计报告..."

awk -F',' 'NR>1 {
    cpu_sum+=$2; mem_sum+=$3;
    if(min_cpu=="" || $2<min_cpu) min_cpu=$2;
    if(max_cpu=="" || $2>max_cpu) max_cpu=$2;
    if(min_mem=="" || $3<min_mem) min_mem=$3;
    if(max_mem=="" || $3>max_mem) max_mem=$3;
    count++;
} END {
    if (count > 0) {
        printf "==================================================\n" > "'$REPORT_FILE'";
        printf "⏱ 采样时间: %s ~ %s (共 %d 次连续采样，每5秒一次)\n", "10分钟监控", "完成", count >> "'$REPORT_FILE'";
        printf "⚡ CPU 使用率: 平均 %.2f%%  |  最小 %.1f%%  |  最大 %.1f%%\n", cpu_sum/count, min_cpu, max_cpu >> "'$REPORT_FILE'";
        printf "🧠 内存占用 (RSS): 平均 %.2f MB |  最小 %.1f MB |  最大 %.1f MB\n", mem_sum/count, min_mem, max_mem >> "'$REPORT_FILE'";
        printf "==================================================\n" >> "'$REPORT_FILE'";
    }
}' "$LOG_FILE"

cat "$REPORT_FILE"
