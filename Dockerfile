# 使用 Node.js 官方镜像作为基础镜像
FROM registry.cn-hangzhou.aliyuncs.com/node/node:18-alpine
# 安装构建依赖、字体支持和 crond
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    giflib-dev \
    pixman-dev \
    pangomm-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    # 添加字体和语言支持
    fontconfig \
    ttf-dejavu \
    ttf-liberation \
    font-noto \
    font-noto-cjk \
    font-noto-emoji \
    # 添加中文支持
    icu-libs \
    icu-data-full \
    font-wqy-zenhei \
    # 安装 dcron（定时任务）
    dcron

# 设置语言环境
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制项目文件
COPY . .

# 复制并设置脚本权限
RUN chmod +x /app/scripts/cleanup-cron.sh && \
    chmod +x /app/scripts/docker-entrypoint.sh

# 创建日志目录
RUN mkdir -p /var/log && touch /var/log/cleanup.log

# 设置 cron job（每6小时执行一次）
# 可以通过环境变量 CLEANUP_SCHEDULE 自定义
RUN echo "0 */6 * * * /app/scripts/cleanup-cron.sh >> /var/log/cleanup.log 2>&1" > /etc/crontabs/root && \
    chmod 0644 /etc/crontabs/root && \
    cat /etc/crontabs/root
# 暴露端口
EXPOSE 8084

# 使用自定义启动脚本
CMD ["/app/scripts/docker-entrypoint.sh"]

