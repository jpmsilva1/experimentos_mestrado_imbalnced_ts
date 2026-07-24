#!/usr/bin/env bash
# monitor_mem.sh — watch memory while generate_inds.R runs
# Usage: bash scratch/monitor_mem.sh
# Polls every 10s. Ctrl+C to stop.

WARN_GB=50        # warn if RAM used exceeds this
LOG="scratch/monitor_mem.log"
INTERVAL=10

# macOS: get total physical RAM in GB
TOTAL_RAM_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))

echo "=========================================="
echo "  Memory Monitor — paper 003 experiment"
echo "  Total RAM: ${TOTAL_RAM_GB} GB"
echo "  Warning threshold: ${WARN_GB} GB used"
echo "  Log: $LOG"
echo "  Ctrl+C to stop"
echo "=========================================="
echo ""

# Write header to log
echo "timestamp,r_pid,r_rss_gb,r_cpu_pct,sys_used_gb,sys_free_gb,pressure" > "$LOG"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

    # --- Find R process ---
    R_PID=$(pgrep -f "generate_inds.R" | head -1)

    if [ -z "$R_PID" ]; then
        R_INFO="no R process"
        R_RSS_GB="0"
        R_CPU="0"
    else
        # RSS in KB from ps, convert to GB
        R_RSS_KB=$(ps -o rss= -p "$R_PID" 2>/dev/null | tr -d ' ')
        R_RSS_GB=$(awk "BEGIN {printf \"%.2f\", ${R_RSS_KB:-0}/1024/1024}")
        R_CPU=$(ps -o %cpu= -p "$R_PID" 2>/dev/null | tr -d ' ')
        R_INFO="PID=$R_PID RSS=${R_RSS_GB}GB CPU=${R_CPU}%"
    fi

    # --- System memory (macOS vm_stat) ---
    VM=$(vm_stat)
    PAGE_SIZE=$(pagesize)
    FREE_PAGES=$(echo "$VM" | awk '/Pages free/ {gsub(/\./, "", $3); print $3}')
    INACTIVE_PAGES=$(echo "$VM" | awk '/Pages inactive/ {gsub(/\./, "", $3); print $3}')
    WIRED_PAGES=$(echo "$VM" | awk '/Pages wired down/ {gsub(/\./, "", $4); print $4}')
    ACTIVE_PAGES=$(echo "$VM" | awk '/Pages active/ {gsub(/\./, "", $3); print $3}')

    SYS_FREE_GB=$(awk "BEGIN {printf \"%.1f\", (${FREE_PAGES:-0}+${INACTIVE_PAGES:-0})*${PAGE_SIZE}/1024/1024/1024}")
    SYS_USED_GB=$(awk "BEGIN {printf \"%.1f\", (${WIRED_PAGES:-0}+${ACTIVE_PAGES:-0})*${PAGE_SIZE}/1024/1024/1024}")

    # --- Memory pressure ---
    PRESSURE=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $NF}' || echo "?")

    # --- Print and log ---
    LINE="${TIMESTAMP} | R: ${R_INFO} | Sys used: ${SYS_USED_GB}GB / ${TOTAL_RAM_GB}GB free: ${SYS_FREE_GB}GB | pressure: ${PRESSURE}"
    echo "$LINE"
    echo "${TIMESTAMP},${R_PID:-none},${R_RSS_GB},${R_CPU:-0},${SYS_USED_GB},${SYS_FREE_GB},${PRESSURE}" >> "$LOG"

    # --- Warn if approaching limit ---
    WARN=$(awk "BEGIN {print (${SYS_USED_GB} >= ${WARN_GB}) ? \"YES\" : \"NO\"}")
    if [ "$WARN" = "YES" ]; then
        echo "⚠️  WARNING: System used RAM (${SYS_USED_GB}GB) exceeded ${WARN_GB}GB threshold!"
        # macOS notification
        osascript -e "display notification \"RAM at ${SYS_USED_GB}GB — consider stopping R\" with title \"⚠️ Memory Warning\"" 2>/dev/null || true
    fi

    sleep "$INTERVAL"
done
