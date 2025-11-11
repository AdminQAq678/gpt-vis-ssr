# 图片清理功能说明

本项目已集成自动图片清理功能，可以定期清理 `images` 目录下的旧图片文件。

## 方案一：Node.js 定时任务（已集成，推荐）

### 特性

- ✅ 自动定时清理旧图片
- ✅ 可配置清理周期和保留时长
- ✅ 提供手动清理接口
- ✅ 提供统计查询接口
- ✅ 启动时自动执行一次清理
- ✅ 详细的日志输出

### 配置说明

在 `docker-compose.yml` 中可以配置以下环境变量：

```yaml
environment:
  # 是否启用自动清理（默认：true）
  - CLEANUP_ENABLED=true
  
  # Cron 表达式，定义清理执行时间（默认：每6小时）
  - CLEANUP_SCHEDULE=0 */6 * * *
  
  # 图片保留时长（小时），超过此时间的图片将被删除（默认：24小时）
  - MAX_IMAGE_AGE_HOURS=24
```

### Cron 表达式示例

```
# 格式：秒 分 时 日 月 星期
# * * * * * *
# │ │ │ │ │ │
# │ │ │ │ │ └─ 星期几 (0-7, 0或7表示周日)
# │ │ │ │ └─── 月份 (1-12)
# │ │ │ └───── 日期 (1-31)
# │ │ └─────── 小时 (0-23)
# │ └───────── 分钟 (0-59)
# └─────────── 秒 (0-59, 可选)

0 */6 * * *      # 每6小时执行一次（0点、6点、12点、18点）
0 0 * * *        # 每天凌晨0点执行
0 2 * * *        # 每天凌晨2点执行
0 */12 * * *     # 每12小时执行一次
*/30 * * * *     # 每30分钟执行一次
0 0 */2 * *      # 每2天执行一次
```

### API 接口

#### 1. 手动触发清理

```bash
# 使用默认配置清理
curl -X POST http://localhost:8084/cleanup

# 指定保留时长（小时）
curl -X POST http://localhost:8084/cleanup \
  -H "Content-Type: application/json" \
  -d '{"maxAgeHours": 12}'
```

响应示例：
```json
{
  "success": true,
  "result": {
    "deleted": 15,
    "errors": 0,
    "scanned": 20,
    "remaining": {
      "count": 5,
      "totalSize": 2457600
    }
  }
}
```

#### 2. 查询统计信息

```bash
curl http://localhost:8084/stats
```

响应示例：
```json
{
  "success": true,
  "stats": {
    "count": 5,
    "totalSizeMB": "2.34"
  }
}
```

### 部署步骤

1. **重新构建镜像**：
```bash
docker-compose build
```

2. **启动服务**：
```bash
docker-compose up -d
```

3. **查看日志**：
```bash
docker-compose logs -f
```

你应该能看到类似以下的日志：
```
[定时任务] 图片清理已启用
[定时任务] Cron 表达式: 0 */6 * * *
[定时任务] 保留时长: 24小时
[启动任务] 执行首次图片清理...
[清理任务] 开始清理图片，保留时长: 24小时
[清理任务] 完成 - 扫描: 10, 删除: 5, 错误: 0
```

### 禁用自动清理

如果需要禁用自动清理功能，设置环境变量：

```yaml
environment:
  - CLEANUP_ENABLED=false
```

---

## 方案二：系统级 Cron Job（备选方案）

如果你更喜欢使用系统级的 cron job，可以使用以下方案。

### 1. 创建清理脚本

创建 `scripts/cleanup-cron.sh`：

```bash
#!/bin/sh

# 配置参数
IMAGES_DIR="/app/public/images"
MAX_AGE_HOURS=24

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始清理图片..."

# 计算时间戳（分钟）
MAX_AGE_MINUTES=$((MAX_AGE_HOURS * 60))

# 删除超过指定时间的图片文件
find "$IMAGES_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" \) -mmin +$MAX_AGE_MINUTES -delete

# 统计剩余文件
REMAINING=$(find "$IMAGES_DIR" -type f | wc -l)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 清理完成，剩余文件: $REMAINING"
```

### 2. 修改 Dockerfile

在 Dockerfile 末尾添加：

```dockerfile
# 安装 crond
RUN apk add --no-cache dcron

# 复制清理脚本
COPY scripts/cleanup-cron.sh /app/scripts/
RUN chmod +x /app/scripts/cleanup-cron.sh

# 设置 cron job
RUN echo "0 */6 * * * /app/scripts/cleanup-cron.sh >> /var/log/cleanup.log 2>&1" > /etc/crontabs/root

# 修改启动命令
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh
CMD ["/app/docker-entrypoint.sh"]
```

### 3. 创建启动脚本

创建 `docker-entrypoint.sh`：

```bash
#!/bin/sh

# 启动 crond
crond -b -l 2

# 启动应用
exec npm start
```

### 优缺点对比

| 特性 | 方案一（Node.js） | 方案二（系统Cron） |
|------|-------------------|-------------------|
| 实现复杂度 | 简单 | 中等 |
| 配置灵活性 | 高（环境变量） | 中（需修改镜像） |
| 调试便利性 | 高（应用日志） | 中（需查看系统日志） |
| 资源占用 | 低（单进程） | 稍高（多进程） |
| 手动触发 | 支持（API） | 不支持 |
| 统计查询 | 支持（API） | 不支持 |

---

## 注意事项

1. **时区设置**：确保 `TZ=Asia/Shanghai` 环境变量正确设置，这样定时任务会按照中国时区执行。

2. **数据持久化**：`images` 目录已通过 volume 映射到宿主机，清理操作会影响宿主机上的文件。

3. **生产环境建议**：
   - 根据实际业务量调整 `MAX_IMAGE_AGE_HOURS`
   - 监控磁盘使用情况
   - 定期检查清理日志
   - 考虑使用对象存储服务（如 OSS、S3）替代本地存储

4. **测试建议**：
   - 先使用较短的保留时长（如1小时）测试
   - 观察日志确认清理正常工作
   - 手动调用 `/cleanup` 接口测试

---

## 故障排查

### 问题1：定时任务没有执行

**解决方法**：
```bash
# 查看日志
docker-compose logs -f

# 检查环境变量
docker exec <container_id> env | grep CLEANUP
```

### 问题2：文件没有被删除

**可能原因**：
- 文件还未达到保留时长
- 文件权限问题
- 目录路径不正确

**解决方法**：
```bash
# 进入容器检查
docker exec -it <container_id> sh

# 查看文件列表和修改时间
ls -lh /app/public/images/

# 手动触发清理
curl -X POST http://localhost:8084/cleanup
```

### 问题3：查看清理历史

```bash
# 查看最近的日志
docker-compose logs --tail=100 | grep "清理任务"
```

---

## 扩展建议

1. **基于文件大小清理**：除了时间，还可以根据目录总大小进行清理
2. **清理通知**：集成邮件或消息推送，清理后发送通知
3. **备份功能**：清理前先备份到其他位置
4. **云存储集成**：将图片上传到 OSS/S3，本地只保留缓存

