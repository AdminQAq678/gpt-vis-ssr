# gpt_vis_ssr

服务化部署 gpt-vis-ssr，可以作为MCP工具 mcp-server-chart 私有制图服务后端

> 参考1：https://github.com/antvis/GPT-Vis/tree/main/bindings/gpt-vis-ssr

> 参考2：https://github.com/antvis/mcp-server-chart

# 安装

docker-compose.yml

```
version: '3.8'

services:
  gpt-vis-ssr:
    image: ghcr.io/luler/gpt_vis_ssr:latest
    ports:
      - 3000:3000
    volumes:
      - ./images:/app/public/images
    environment:
      - NODE_ENV=production
      - TZ=Asia/Shanghai
    restart: unless-stopped
```

运行

```
docker-compose up -d
```

# 使用
- 提供接口：`POST` http://127.0.0.1:3000/render
- 请求参数：
```json
{
    "type": "column",
    "data": [
        {
            "category": "交通",
            "value": 2000
        },
        {
            "category": "住宿",
            "value": 1200
        },
        {
            "category": "吃喝",
            "value": 1000
        },
        {
            "category": "门票",
            "value": 800
        },
        {
            "category": "其他",
            "value": 300
        }
    ],
    "title": "旅行计划费用统计",
    "axisXTitle": "费用类别",
    "axisYTitle": "金额 (元)"
}
```
- 返回数据
```json
{
    "success": true,
    "resultObj": "http://127.0.0.1:3000/images/c1e17b0f-513d-46de-ae74-e0d20ae52bd7.png"
}
```

- 结果图示例
![](./example.png)

# 图片自动清理功能

为了防止图片文件积累过多占用磁盘空间，本项目已集成自动清理功能。

## 快速配置

在 `docker-compose.yml` 中配置环境变量：

```yaml
environment:
  - CLEANUP_ENABLED=true              # 启用自动清理
  - CLEANUP_SCHEDULE=0 */6 * * *      # 每6小时执行一次
  - MAX_IMAGE_AGE_HOURS=24            # 保留24小时内的图片
```

## 特性

✅ 自动定时清理旧图片  
✅ 可自定义清理周期和保留时长  
✅ 提供手动清理接口：`POST /cleanup`  
✅ 提供统计查询接口：`GET /stats`  
✅ 启动时自动执行一次清理  

## 详细文档

- [快速开始指南](./QUICKSTART.md) - 快速上手
- [完整功能文档](./CLEANUP_README.md) - 详细配置和故障排查

## 示例

```bash
# 查看统计
curl http://localhost:8084/stats

# 手动触发清理
curl -X POST http://localhost:8084/cleanup
```