#!/bin/sh

# 图片自动清理脚本（基于文件修改时间）
# 用于系统级 cron job

# 配置参数
IMAGES_DIR="${IMAGES_DIR:-/app/public/images}"
MAX_AGE_HOURS="${MAX_AGE_HOURS:-24}"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 检查目录是否存在
if [ ! -d "$IMAGES_DIR" ]; then
    log "错误: 目录不存在 - $IMAGES_DIR"
    exit 1
fi

log "========================================="
log "开始清理图片..."
log "目录: $IMAGES_DIR"
log "保留时长: ${MAX_AGE_HOURS}小时"

# 计算时间戳（分钟）
MAX_AGE_MINUTES=$((MAX_AGE_HOURS * 60))

# 统计清理前的文件数量
BEFORE_COUNT=$(find "$IMAGES_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) | wc -l)
log "清理前文件数: $BEFORE_COUNT"

# 删除超过指定时间的图片文件
DELETED_FILES=$(find "$IMAGES_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) -mmin +$MAX_AGE_MINUTES)

if [ -n "$DELETED_FILES" ]; then
    echo "$DELETED_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            rm -f "$file"
            log "已删除: $(basename "$file")"
        fi
    done
else
    log "没有需要清理的文件"
fi

# 统计清理后的文件数量
AFTER_COUNT=$(find "$IMAGES_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) | wc -l)
DELETED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

log "清理后文件数: $AFTER_COUNT"
log "已删除文件数: $DELETED_COUNT"

# 计算目录大小
if command -v du > /dev/null 2>&1; then
    DIR_SIZE=$(du -sh "$IMAGES_DIR" 2>/dev/null | cut -f1)
    log "当前目录大小: $DIR_SIZE"
fi

log "清理完成"
log "========================================="

