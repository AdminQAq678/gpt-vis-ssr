#!/bin/bash

# 图片清理功能测试脚本
# 用于创建测试文件并验证清理功能

echo "========================================="
echo "图片清理功能测试脚本"
echo "========================================="

# 配置
IMAGES_DIR="./public/images"
TEST_FILE_PREFIX="test_"

# 创建测试目录
mkdir -p "$IMAGES_DIR"

echo ""
echo "1. 创建测试文件..."

# 创建一些测试图片文件（空文件）
for i in {1..5}; do
    touch "$IMAGES_DIR/${TEST_FILE_PREFIX}old_$i.png"
    echo "创建: ${TEST_FILE_PREFIX}old_$i.png"
done

# 修改文件时间戳，模拟旧文件（25小时前）
echo ""
echo "2. 修改文件时间戳（模拟25小时前创建）..."
for i in {1..5}; do
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        touch -t $(date -v-25H +"%Y%m%d%H%M") "$IMAGES_DIR/${TEST_FILE_PREFIX}old_$i.png"
    else
        # Linux
        touch -d "25 hours ago" "$IMAGES_DIR/${TEST_FILE_PREFIX}old_$i.png"
    fi
    echo "已修改: ${TEST_FILE_PREFIX}old_$i.png"
done

# 创建新文件
echo ""
echo "3. 创建新文件（不应被清理）..."
for i in {1..3}; do
    touch "$IMAGES_DIR/${TEST_FILE_PREFIX}new_$i.png"
    echo "创建: ${TEST_FILE_PREFIX}new_$i.png"
done

# 显示当前文件列表
echo ""
echo "4. 当前文件列表:"
echo "----------------------------------------"
ls -lh "$IMAGES_DIR" | grep "$TEST_FILE_PREFIX"

echo ""
echo "5. 文件统计:"
TOTAL=$(find "$IMAGES_DIR" -name "${TEST_FILE_PREFIX}*.png" | wc -l)
echo "总文件数: $TOTAL"

echo ""
echo "========================================="
echo "测试文件创建完成！"
echo ""
echo "接下来请执行以下操作之一："
echo ""
echo "方案一：测试 Node.js 应用级清理"
echo "  1. 启动服务: docker-compose up -d"
echo "  2. 查看日志: docker-compose logs -f"
echo "  3. 或手动触发: curl -X POST http://localhost:8084/cleanup"
echo ""
echo "方案二：测试系统级 cron 清理"
echo "  1. 进入容器: docker exec -it <container_id> sh"
echo "  2. 执行脚本: /app/scripts/cleanup-cron.sh"
echo ""
echo "清理后应该："
echo "  - 5个旧文件被删除（${TEST_FILE_PREFIX}old_*.png）"
echo "  - 3个新文件保留（${TEST_FILE_PREFIX}new_*.png）"
echo "========================================="

