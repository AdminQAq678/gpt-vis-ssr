#!/bin/sh

# Docker 容器启动脚本
# 用于同时运行 crond 和 Node.js 应用

echo "========================================="
echo "容器启动中..."
echo "========================================="

# 检查是否启用 cron
if [ "$ENABLE_CRON" = "true" ]; then
    echo "[Cron] 启用系统级定时任务"
    
    # 创建日志目录
    mkdir -p /var/log
    touch /var/log/cleanup.log
    
    # 启动 crond（后台运行）
    crond -b -l 2
    
    echo "[Cron] crond 已启动"
    
    # 执行一次清理（延迟5秒）
    (sleep 5 && /app/scripts/cleanup-cron.sh >> /var/log/cleanup.log 2>&1) &
else
    echo "[Cron] 系统级定时任务已禁用"
fi

echo "========================================="
echo "启动 Node.js 应用..."
echo "========================================="

# 启动 Node.js 应用
exec npm start

