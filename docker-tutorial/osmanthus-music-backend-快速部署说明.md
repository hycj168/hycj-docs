# Osmanthus Music Backend 快速部署说明（企业级数据卷版）

## 📦 文件清单

在当前目录下已生成以下文件：

1. **osmanthus-music-backend-docker-compose.yml** - Docker Compose 主配置文件（企业级数据卷版）
2. **osmanthus-music-backend.env** - 环境变量配置模板
3. **osmanthus-music-backend-Dockerfile** - 应用镜像构建文件
4. **osmanthus-music-backend-deploy.sh** - 一键部署脚本（企业级数据卷版）
5. **osmanthus-music-backend-docker部署指南.md** - 详细部署文档
6. **osmanthus-music-backend-快速部署说明.md** - 本快速说明

### 📦 服务组件版本
- **MySQL**: `latest` 版本
- **Redis**: `latest` 版本  
- **MinIO**: `latest` 版本
- **Nginx**: `latest` 版本（可选）
- **应用**: 自定义构建 `latest` 版本

## 🚀 快速部署步骤

### 1. 复制文件到目标项目

```bash
# 进入 Osmanthus Music Backend 项目目录
cd E:\github-projects\osmanthus-music-backend

# 复制文件（从 docker-tutorial 目录）
cp e:\docs-dev\docker-tutorial\osmanthus-music-backend-docker-compose.yml ./docker-compose.yml
cp e:\docs-dev\docker-tutorial\osmanthus-music-backend.env ./.env
cp e:\docs-dev\docker-tutorial\osmanthus-music-backend-Dockerfile ./Dockerfile
cp e:\docs-dev\docker-tutorial\osmanthus-music-backend-deploy.sh ./deploy.sh
```

### 2. 确保企业级数据卷目录存在

**重要**：此版本使用企业级 Docker 数据卷，需要服务器上已创建以下目录结构：

```
/opt/docker-volumes/
├── mysql/{data,config,logs,backup}
├── redis/{data,config,logs}
├── minio/{data,config,logs,backup}
├── backend/{data,config,logs,backup,temp,uploads}
└── nginx/{config,conf.d,logs}
```

如果目录不存在，部署脚本会自动创建，但需要确保有相应权限。

### 3. 修改配置

编辑 `.env` 文件，修改以下关键配置：

```bash
# 必须修改的密码
MYSQL_ROOT_PASSWORD=你的强密码
MYSQL_PASSWORD=你的数据库密码
REDIS_PASSWORD=你的Redis密码
MINIO_ROOT_PASSWORD=你的MinIO密码
JWT_SECRET=你的64位随机JWT密钥
```

### 4. 一键部署

```bash
# Linux/Mac 执行
chmod +x deploy.sh
./deploy.sh

# 或者直接使用 Docker Compose
docker-compose up -d
```

### 5. 验证部署

```bash
# 检查服务状态
docker-compose ps

# 测试 API
curl http://localhost:8080/actuator/health

# 访问服务
# 应用: http://localhost:8080
# MinIO: http://localhost:9001
```

## 🔗 服务端口

| 服务 | 端口 | 地址 |
|------|------|------|
| 应用服务 | 8080 | http://localhost:8080 |
| MinIO 控制台 | 9001 | http://localhost:9001 |
| MySQL | 3306 | localhost:3306 |
| Redis | 6379 | localhost:6379 |

## � 数据存储说明

### 企业级数据卷（生产环境）
所有数据持久化到服务器的企业级目录：

- **MySQL 数据**：`/opt/docker-volumes/mysql/data/`
- **Redis 数据**：`/opt/docker-volumes/redis/data/`
- **MinIO 数据**：`/opt/docker-volumes/minio/data/`
- **应用日志**：`/opt/docker-volumes/backend/logs/`
- **文件上传**：`/opt/docker-volumes/backend/uploads/`
- **临时文件**：`/opt/docker-volumes/backend/temp/`

### 本地配置目录（开发环境）
仅用于存放配置文件：

- **MySQL 配置**：`./docker/mysql/conf.d/`
- **Redis 配置**：`./docker/redis/`
- **MinIO 配置**：`./docker/minio/config/`
- **Nginx 配置**：`./docker/nginx/conf.d/`

## �🔧 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f osmanthus-backend

# 重启服务
docker-compose restart osmanthus-backend

# 进入容器
docker-compose exec osmanthus-backend bash

# 备份企业级数据卷
tar -czf backup-$(date +%Y%m%d).tar.gz /opt/docker-volumes/
```

## ⚠️ 安全提醒

1. **修改默认密码** - 生产环境必须修改所有默认密码
2. **配置防火墙** - 限制不必要的端口访问
3. **启用 SSL** - 生产环境建议使用 HTTPS
4. **定期备份** - 设置数据库和文件备份策略
5. **权限管理** - 确保企业级数据卷目录权限正确

## 📞 技术支持

- 详细文档: 查看 `osmanthus-music-backend-docker部署指南.md`
- 故障排除: 参考部署指南的故障排除章节
- 性能优化: 查看部署指南的高级配置部分

## 🔄 版本区别

此版本与标准版的区别：
- ✅ 使用企业级数据卷，数据更安全
- ✅ 支持集中化数据管理
- ✅ 便于备份和迁移
- ✅ 支持多环境部署
- ✅ 符合企业运维标准

## 🎯 下一步

1. 访问 Swagger API 文档: http://localhost:8080/doc.html
2. 配置 Nginx 反向代理（可选）
3. 设置 SSL 证书（生产环境）
4. 配置监控和日志收集
5. 设置自动化备份

**🌸 部署完成！祝您使用愉快！**