# Osmanthus Music Backend Docker 部署指南（企业级数据卷版）

## 📋 项目概述

Osmanthus Music Backend 是一个基于 **Kotlin + Spring Boot 3.5.8** 的企业级音乐管理系统，采用现代化的微服务架构设计。本指南提供完整的企业级 Docker 容器化部署方案，使用企业级数据卷进行数据持久化，支持生产环境部署。

### 🏗️ 技术栈
- **后端框架**: Kotlin + Spring Boot 3.5.8
- **数据库**: MySQL `latest`
- **缓存**: Redis `latest`
- **对象存储**: MinIO `latest`
- **构建工具**: Gradle 8.11.1
- **容器化**: Docker + Docker Compose
- **反向代理**: Nginx `latest` (可选)

### 🏗️ 架构特点
- **企业级数据卷**：使用 `/opt/docker-volumes/` 进行数据持久化
- **微服务设计**：MySQL、Redis、MinIO、应用服务分离部署
- **高可用性**：健康检查、自动重启、资源限制
- **安全设计**：非 root 用户运行、密码管理、网络安全
- **性能优化**：JVM 调优、数据库优化、缓存策略
- **监控友好**：健康检查端点、结构化日志、指标收集
- **运维友好**：企业级目录结构、备份策略、日志管理

### ✨ 核心功能
- 🎵 音乐管理（上传、存储、分类）
- 👥 用户管理（注册、登录、权限）
- 📱 RESTful API 设计
- 🔐 JWT 身份认证
- 📊 监控和日志
- 🚀 容器化部署
- 📁 文件存储（支持本地和对象存储）

## 📦 文件清单

部署 Osmanthus Music Backend 需要以下文件：

```
osmanthus-music-backend/
├── docker-compose.yml              # 主 Docker Compose 配置
├── .env                          # 环境变量配置
├── Dockerfile                    # 应用镜像构建文件
├── osmanthus-music-backend-deploy.sh  # 一键部署脚本
└── docker/                       # Docker 配置目录
    ├── mysql/                    # MySQL 配置
    │   ├── conf.d/               # MySQL 配置文件
    │   ├── init/                 # 初始化 SQL 脚本
    │   └── logs/                 # MySQL 日志
    ├── redis/                    # Redis 配置
    │   ├── redis.conf            # Redis 配置文件
    │   └── logs/                 # Redis 日志
    ├── minio/                    # MinIO 配置
    │   ├── config/               # MinIO 配置
    │   └── logs/                 # MinIO 日志
    ├── backend/                  # 后端应用配置
    │   ├── logs/                 # 应用日志
    │   ├── uploads/              # 文件上传目录
    │   └── temp/                 # 临时文件目录
    └── nginx/                    # Nginx 配置（可选）
        ├── nginx.conf            # Nginx 主配置
        ├── conf.d/               # 虚拟主机配置
        ├── ssl/                  # SSL 证书
        ├── html/                 # 静态资源
        └── logs/                 # Nginx 日志
```

## 🚀 快速部署

### 1. 环境准备

确保系统已安装：
- Docker 20.10+
- Docker Compose 2.0+
- Linux/Unix 环境

```bash
# 检查 Docker 版本
docker --version

# 检查 Docker Compose 版本
docker-compose --version

# 检查系统要求
uname -a
```

### 2. 文件准备

将所有部署文件复制到项目目录：

```bash
# 创建项目目录
mkdir -p /opt/osmanthus-music-backend
cd /opt/osmanthus-music-backend

# 复制所有部署文件（已在当前目录生成）
cp /path/to/osmanthus-music-backend-docker-compose.yml ./docker-compose.yml
cp /path/to/osmanthus-music-backend.env ./.env
cp /path/to/osmanthus-music-backend-Dockerfile ./Dockerfile
cp /path/to/osmanthus-music-backend-deploy.sh ./deploy.sh

# 设置执行权限
chmod +x deploy.sh
```

### 3. 配置修改

编辑 `.env` 文件，修改关键配置：

```bash
# 编辑环境变量配置
vim .env
```

**必须修改的配置项：**
```env
# MySQL Root 密码（必须修改）
MYSQL_ROOT_PASSWORD=your_strong_mysql_root_password

# 应用数据库密码（必须修改）
MYSQL_PASSWORD=your_strong_mysql_password

# Redis 密码（必须修改）
REDIS_PASSWORD=your_strong_redis_password

# MinIO 密码（建议修改）
MINIO_ROOT_PASSWORD=your_strong_minio_password

# JWT 密钥（必须修改，建议64位以上随机字符）
JWT_SECRET=YourVeryStrongAndRandomJWTSecretKeyHerePleaseChangeInProduction2024

# Spring 环境（开发环境用 dev，生产环境用 prod）
SPRING_PROFILES_ACTIVE=prod
```

### 4. 一键部署

执行部署脚本：

```bash
# 执行部署
./deploy.sh

# 或者手动部署
docker-compose --env-file .env up -d
```

### 5. 验证部署

部署完成后，检查服务状态：

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 健康检查
curl -f http://localhost:8080/actuator/health
```

## 🔗 服务访问

部署成功后，可以通过以下地址访问服务：

| 服务 | 地址 | 说明 |
|------|------|------|
| 应用服务 | http://localhost:8080 | 主 API 服务 |
| MinIO 控制台 | http://localhost:9001 | 对象存储管理 |
| MinIO API | http://localhost:9000 | 对象存储 API |
| 健康检查 | http://localhost:8080/actuator/health | 服务健康状态 |
| 应用信息 | http://localhost:8080/actuator/info | 应用信息 |
| 指标监控 | http://localhost:8080/actuator/metrics | 性能指标 |

### 🔐 默认访问凭据

**MinIO 控制台：**
- 用户名: `minioadmin`
- 密码: `.env` 文件中配置的 `MINIO_ROOT_PASSWORD`

**Swagger API 文档（如果启用）：**
- 地址: http://localhost:8080/doc.html
- 用户名: `admin`
- 密码: `.env` 文件中配置的 `SWAGGER_PASSWORD`

## ⚙️ 高级配置

### MySQL 性能优化

编辑 `docker/mysql/conf.d/mysql.cnf`：

```ini
[mysqld]
# 连接数配置
max_connections=500
max_user_connections=400

# InnoDB 缓冲池（根据服务器内存调整）
innodb_buffer_pool_size=1G
innodb_log_file_size=256M

# 查询缓存
query_cache_size=64M
query_cache_limit=4M

# 表缓存
table_open_cache=1024
table_definition_cache=512
```

### Redis 性能优化

编辑 `docker/redis/redis.conf`：

```conf
# 内存管理
maxmemory 1gb
maxmemory-policy allkeys-lru

# 持久化优化
save 900 1
save 300 10
save 60 10000

# 网络优化
tcp-backlog 1024
tcp-keepalive 300
```

### JVM 性能调优

编辑 `.env` 文件中的 `JAVA_OPTS`：

```env
# JVM 参数（根据服务器配置调整）
JAVA_OPTS=-Xms1g -Xmx2g -XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxGCPauseMillis=200
```

## 🔒 安全配置

### 1. 密码安全

**生产环境必须修改所有默认密码：**
- MySQL Root 密码
- 应用数据库密码
- Redis 密码
- MinIO 密码
- JWT 密钥（建议使用 64 位以上随机字符）

### 2. 网络安全

**配置防火墙规则：**
```bash
# 只允许必要端口
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8080/tcp  # 应用端口（内部使用）
sudo ufw enable
```

### 3. SSL/TLS 配置

**启用 HTTPS：**
1. 获取 SSL 证书
2. 配置 Nginx SSL
3. 修改应用配置支持 HTTPS

### 4. 访问控制

**限制管理端点访问：**
```nginx
# Nginx 配置示例
location /actuator/ {
    allow 192.168.1.0/24;  # 只允许内网访问
    deny all;
    proxy_pass http://osmanthus_backend;
}
```

## 📊 监控和维护

### 日志管理

```bash
# 查看实时日志
docker-compose logs -f osmanthus-backend

# 查看特定服务的日志
docker-compose logs osmanthus-mysql

# 导出日志
docker-compose logs osmanthus-backend > backend.log
```

### 性能监控

```bash
# 查看容器资源使用
docker stats

# 查看系统资源
df -h  # 磁盘使用
free -h  # 内存使用
top  # CPU 使用
```

### 备份策略

**数据库备份：**
```bash
# MySQL 备份
docker-compose exec osmanthus-mysql mysqldump -u root -p osmanthus_music_db > backup.sql

# Redis 备份
docker-compose exec osmanthus-redis redis-cli save
docker cp $(docker-compose ps -q osmanthus-redis):/data/dump.rdb ./
```

**文件备份：**
```bash
# 备份上传文件
docker-compose exec osmanthus-backend tar -czf /tmp/uploads_backup.tar.gz /app/uploads
```

## 🛠️ 故障排除

### 常见问题

**1. 服务启动失败**
```bash
# 查看详细日志
docker-compose logs [服务名]

# 检查端口冲突
netstat -tulnp | grep :8080

# 重启服务
docker-compose restart [服务名]
```

**2. 数据库连接失败**
```bash
# 检查数据库状态
docker-compose exec osmanthus-mysql mysql -u root -p

# 检查网络连接
docker-compose exec osmanthus-backend nc -zv osmanthus-mysql 3306
```

**3. 内存不足**
```bash
# 调整 JVM 参数
vim .env  # 修改 JAVA_OPTS

# 调整容器内存限制
vim docker-compose.yml  # 修改 deploy.resources
```

**4. 磁盘空间不足**
```bash
# 清理 Docker 镜像
docker system prune -a

# 清理日志文件
docker-compose exec osmanthus-backend rm -rf /app/logs/*.log
```

### 性能调优

**数据库优化：**
- 添加合适的索引
- 优化查询语句
- 调整缓冲池大小

**应用优化：**
- 启用 Redis 缓存
- 配置 CDN 加速
- 使用连接池

**系统优化：**
- 调整内核参数
- 优化文件描述符限制
- 配置 swap 空间

## 📚 API 文档

### RESTful API

应用提供完整的 RESTful API，主要端点：

```
# 用户管理
POST /api/users/register     # 用户注册
POST /api/users/login        # 用户登录
GET  /api/users/profile      # 用户信息

# 音乐管理
GET  /api/music              # 获取音乐列表
POST /api/music/upload       # 上传音乐
GET  /api/music/{id}         # 获取音乐详情

# 文件上传
POST /api/files/upload       # 文件上传
GET  /api/files/{id}         # 获取文件
```

### Swagger 文档

如果启用了 Swagger，可以访问：
- 地址: http://localhost:8080/doc.html
- JSON: http://localhost:8080/v3/api-docs

## 🤝 技术支持

### 获取帮助
- 📧 邮箱: support@osmanthus.com
- 💬 社区: https://github.com/your-org/osmanthus-music-backend/discussions
- 📖 文档: https://docs.osmanthus.com

### 贡献代码
欢迎提交 Issue 和 Pull Request！

### 更新日志
查看 [CHANGELOG.md](CHANGELOG.md) 了解版本更新内容。

---

**🌸 祝您使用愉快！** 
*Osmanthus Music Backend Team*