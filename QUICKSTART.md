# 快速开始指南

## 方案一：Node.js 应用级清理（推荐）⭐

这是最简单的方案，无需修改 Dockerfile，只需更新依赖即可。

### 步骤1：安装依赖

```bash
# 如果是在宿主机开发
npm install

# 如果使用 Docker，重新构建镜像
docker-compose build
```

### 步骤2：配置环境变量（可选）

编辑 `docker-compose.yml`，根据需要调整配置：

```yaml
environment:
  - CLEANUP_ENABLED=true              # 启用/禁用清理
  - CLEANUP_SCHEDULE=0 */6 * * *      # 每6小时执行
  - MAX_IMAGE_AGE_HOURS=24            # 保留24小时
```

### 步骤3：启动服务

```bash
docker-compose up -d
```

### 步骤4：查看日志

```bash
docker-compose logs -f
```

你应该能看到：
```
[定时任务] 图片清理已启用
[定时任务] Cron 表达式: 0 */6 * * *
[定时任务] 保留时长: 24小时
[启动任务] 执行首次图片清理...
```

### 步骤5：测试（可选）

```bash
# 查看统计
curl http://localhost:8084/stats

# 手动触发清理
curl -X POST http://localhost:8084/cleanup

# 指定保留时长（1小时）
curl -X POST http://localhost:8084/cleanup \
  -H "Content-Type: application/json" \
  -d '{"maxAgeHours": 1}'
```

---

## 方案二：系统级 Cron Job

如果你更喜欢传统的系统 cron 方式。

### 步骤1：使用专用的 Dockerfile

```bash
# 构建镜像
docker-compose -f docker-compose.cron.yml build

# 启动服务
docker-compose -f docker-compose.cron.yml up -d
```

### 步骤2：查看日志

```bash
# 查看应用日志
docker-compose -f docker-compose.cron.yml logs -f

# 查看清理日志（需要进入容器）
docker exec -it <container_id> tail -f /var/log/cleanup.log
```

### 步骤3：手动测试清理

```bash
# 进入容器
docker exec -it <container_id> sh

# 手动执行清理脚本
/app/scripts/cleanup-cron.sh

# 查看 cron 配置
cat /etc/crontabs/root
```

---

## 常用命令

### 查看容器 ID

```bash
docker-compose ps
```

### 进入容器

```bash
docker exec -it <container_id> sh
```

### 查看图片目录

```bash
# 在容器内
ls -lh /app/public/images/

# 在宿主机
ls -lh ./images/
```

### 查看文件修改时间

```bash
# 在容器内
find /app/public/images -type f -name "*.png" -exec ls -lh {} \;
```

### 重启服务

```bash
# 方案一
docker-compose restart

# 方案二
docker-compose -f docker-compose.cron.yml restart
```

---

## 配置建议

### 开发环境

```yaml
environment:
  - CLEANUP_ENABLED=true
  - CLEANUP_SCHEDULE=*/10 * * * *    # 每10分钟执行一次（便于测试）
  - MAX_IMAGE_AGE_HOURS=1            # 保留1小时
```

### 生产环境

```yaml
environment:
  - CLEANUP_ENABLED=true
  - CLEANUP_SCHEDULE=0 2 * * *       # 每天凌晨2点执行
  - MAX_IMAGE_AGE_HOURS=168          # 保留7天
```

### 高负载环境

```yaml
environment:
  - CLEANUP_ENABLED=true
  - CLEANUP_SCHEDULE=0 */4 * * *     # 每4小时执行一次
  - MAX_IMAGE_AGE_HOURS=24           # 保留24小时
```

---

## 测试脚本

我们提供了一个测试脚本来验证清理功能：

```bash
# 给予执行权限
chmod +x scripts/test-cleanup.sh

# 运行测试
./scripts/test-cleanup.sh
```

这个脚本会：
1. 创建一些测试图片文件
2. 修改部分文件的时间戳（模拟旧文件）
3. 提供测试指令

---

## 监控和维护

### 监控磁盘使用

```bash
# 在宿主机
du -sh ./images/

# 在容器内
du -sh /app/public/images/
```

### 定期检查日志

```bash
# 查看最近的清理记录
docker-compose logs --tail=50 | grep "清理任务"
```

### 设置告警（可选）

可以配合监控工具（如 Prometheus + Grafana）监控：
- 目录文件数量
- 目录总大小
- 清理执行频率
- 清理错误数量

---

## 故障排查

### 问题：定时任务没有执行

```bash
# 检查环境变量
docker exec <container_id> env | grep CLEANUP

# 检查 node-cron 是否正确加载
docker-compose logs | grep "定时任务"
```

### 问题：文件没有被删除

```bash
# 检查文件时间
docker exec <container_id> find /app/public/images -type f -exec ls -lh {} \;

# 手动触发清理（测试）
curl -X POST http://localhost:8084/cleanup -d '{"maxAgeHours": 0}' -H "Content-Type: application/json"
```

### 问题：容器启动失败

```bash
# 查看错误日志
docker-compose logs

# 检查依赖是否安装
docker exec <container_id> npm list node-cron
```

---

## 更新和升级

### 更新清理配置

1. 修改 `docker-compose.yml` 中的环境变量
2. 重启服务：`docker-compose restart`

### 更新代码

```bash
# 停止服务
docker-compose down

# 拉取最新代码
git pull

# 重新构建和启动
docker-compose build
docker-compose up -d
```

---

## 其他方案（扩展）

### 方案三：使用对象存储

对于生产环境，建议使用对象存储服务（如阿里云 OSS、AWS S3）：

优点：
- 无需管理本地磁盘
- 自动扩容
- 高可用性
- 支持生命周期策略（自动清理）

实现思路：
1. 修改 `index.js`，渲染后上传到 OSS
2. 返回 OSS 的 URL
3. 在 OSS 控制台配置生命周期规则

### 方案四：使用 Redis 缓存

对于临时图片，可以使用 Redis：

优点：
- 自动过期（TTL）
- 无需清理脚本
- 性能高

实现思路：
1. 图片转为 Base64 存入 Redis
2. 设置过期时间（如 24 小时）
3. 前端展示时从 Redis 读取并解码

---

## 支持

如有问题，请查看：
- [CLEANUP_README.md](./CLEANUP_README.md) - 详细文档
- [index.js](./index.js) - 源代码
- [cleanupImages.js](./cleanupImages.js) - 清理模块

或提交 Issue。

