# Osmanthus Music Backend 详细使用文档

## 📋 项目概述

Osmanthus Music Backend 是一个基于 Kotlin + Spring Boot 3.5.8 开发的企业级音乐管理系统后端服务。采用微服务架构，集成了 MySQL、Redis、MinIO 等主流技术栈，提供完整的音乐管理解决方案。

### 🏗️ 技术架构
- **后端框架**: Kotlin + Spring Boot 3.5.8
- **数据库**: MySQL 8.0+ (主数据库)
- **缓存**: Redis 7.0+ (缓存和会话管理)
- **对象存储**: MinIO (文件存储和管理)
- **容器化**: Docker + Docker Compose
- **安全**: JWT 认证 + 权限控制
- **监控**: Spring Boot Actuator + 健康检查

## 🚀 快速开始

### 📋 前置要求
- Docker 20.10+
- Docker Compose 2.0+
- 服务器内存: 建议 4GB+
- 服务器存储: 建议 20GB+

### 🔧 环境准备

#### 1. 获取项目代码
```bash
# 克隆项目仓库（示例路径）
cd /opt
git clone <your-repository-url> osmanthus-music-backend
cd osmanthus-music-backend
```

#### 2. 配置环境变量
```bash
# 复制环境变量模板
cp osmanthus-music-backend.env .env

# 编辑环境变量文件
vim .env
```

#### 3. 关键配置项说明

| 配置项 | 说明 | 默认值 | 建议 |
|--------|------|--------|------|
| `MYSQL_ROOT_PASSWORD` | MySQL root 密码 | sakura_dev_root | **必须修改** |
| `MYSQL_PASSWORD` | 应用数据库密码 | osmanthus_pass_2024 | **必须修改** |
| `REDIS_PASSWORD` | Redis 密码 | osmanthus_redis_2024 | **必须修改** |
| `MINIO_ROOT_PASSWORD` | MinIO 管理员密码 | minioadmin2024 | **必须修改** |
| `JWT_SECRET` | JWT 密钥 | 默认密钥 | **必须修改** |
| `SPRING_PROFILES_ACTIVE` | 运行环境 | prod | 可选: dev/test/prod |
| `SWAGGER_ENABLED` | 是否启用 API 文档 | false | 开发环境可设为 true |

### 🚀 服务启动

#### 方法 1：快速启动（推荐）
```bash
# 一键部署脚本
chmod +x osmanthus-music-backend-deploy.sh
./osmanthus-music-backend-deploy.sh
```

#### 方法 2：手动启动
```bash
# 进入项目目录
cd /opt/osmanthus-music-backend

# 启动所有服务
docker-compose -f osmanthus-music-backend-docker-compose.yml up -d

# 等待服务启动完成
sleep 30

# 检查服务状态
docker-compose -f osmanthus-music-backend-docker-compose.yml ps
```

#### 方法 3：分步启动（调试模式）
```bash
# 1. 启动基础设施服务
docker-compose -f osmanthus-music-backend-docker-compose.yml up -d osmanthus-mysql osmanthus-redis osmanthus-minio

# 2. 等待数据库初始化完成（约 60 秒）
sleep 60

# 3. 启动后端应用
docker-compose -f osmanthus-music-backend-docker-compose.yml up -d osmanthus-backend

# 4. 检查服务状态
docker-compose -f osmanthus-music-backend-docker-compose.yml logs -f
```

## 🔍 服务验证

### 📊 服务状态检查
```bash
# 查看所有容器状态
docker ps

# 查看服务健康状态
curl http://localhost:8080/actuator/health

# 查看服务日志
docker logs -f osmanthus-backend
```

### 🌐 访问地址

| 服务 | 访问地址 | 说明 |
|------|----------|------|
| **后端 API** | http://localhost:8080 | 主服务接口 |
| **MinIO 控制台** | http://localhost:9001 | 文件管理界面 |
| **MinIO API** | http://localhost:9000 | 对象存储接口 |
| **MySQL** | localhost:3306 | 数据库连接 |
| **Redis** | localhost:6379 | 缓存服务 |

### 🔑 默认登录信息

#### MinIO 对象存储
- **访问地址**: http://localhost:9001
- **用户名**: minioadmin
- **密码**: minioadmin2024（以实际 .env 配置为准）

#### API 文档（如启用 Swagger）
- **访问地址**: http://localhost:8080/doc.html
- **用户名**: admin
- **密码**: 123456

## ⚙️ 配置管理

### 📝 环境配置详解

#### 数据库配置
```bash
# MySQL 配置
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=osmanthus_music_db
MYSQL_USER=osmanthus_user
MYSQL_PASSWORD=your_secure_app_password
```

#### Redis 配置
```bash
# Redis 配置
REDIS_PASSWORD=your_secure_redis_password
```

#### MinIO 配置
```bash
# MinIO 配置
MINIO_ROOT_USER=your_custom_username
MINIO_ROOT_PASSWORD=your_secure_minio_password
```

#### 安全配置
```bash
# JWT 配置（生产环境务必修改）
JWT_SECRET=YourSuperSecretJWTKeyThatShouldBeAtLeast64CharactersLong

# Swagger 配置
SWAGGER_ENABLED=false  # 生产环境建议关闭
```

### 🔧 性能调优

#### JVM 参数配置
```bash
# JVM 性能调优
JAVA_OPTS=-Xms1g -Xmx2g -XX:+UseG1GC -XX:+UseStringDeduplication
```

#### 数据库连接池配置
```bash
# 数据库连接参数（在应用配置中）
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
```

## 📊 监控与维护

### 🏥 健康检查
```bash
# 查看应用健康状态
curl http://localhost:8080/actuator/health

# 查看详细健康信息
curl http://localhost:8080/actuator/health/detailed
```

### 📈 性能监控
```bash
# 查看应用指标
curl http://localhost:8080/actuator/metrics

# 查看 JVM 信息
curl http://localhost:8080/actuator/info
```

### 🚨 日志管理
```bash
# 查看实时日志
docker logs -f osmanthus-backend

# 查看最近 100 行日志
docker logs --tail 100 osmanthus-backend

# 查看 MySQL 日志
docker logs -f osmanthus-mysql

# 查看 Redis 日志
docker logs -f osmanthus-redis
```

## 🔒 安全建议

### 🛡️ 生产环境安全配置

#### 1. 密码安全
- 所有默认密码必须修改
- 使用强密码策略（12位以上，包含大小写字母、数字、特殊字符）
- 定期更换密码（建议每90天）

#### 2. 网络安全
- 配置防火墙规则
- 启用 SSL/TLS 加密
- 限制访问来源IP

#### 3. 应用安全
- 关闭不必要的接口（如 Swagger）
- 使用强 JWT 密钥
- 启用安全审计日志

#### 4. 数据安全
- 定期备份数据库
- 加密敏感数据
- 配置访问控制

### 🔐 SSL/TLS 配置
```bash
# 生成 SSL 证书（使用 Let's Encrypt）
certbot certonly --standalone -d your-domain.com

# 配置 Nginx 反向代理（参考 with-nginx profile）
docker-compose --profile with-nginx up -d
```

## 🔧 常见问题排查

### ❌ 服务启动失败

#### 问题 1：MySQL 启动失败
```bash
# 检查 MySQL 日志
docker logs osmanthus-mysql

# 清理数据卷（谨慎操作）
docker volume rm osmanthus-music-backend_mysql_data

# 重新初始化
docker-compose down
docker-compose up -d osmanthus-mysql
```

#### 问题 2：后端应用连接数据库失败
```bash
# 检查数据库连接配置
echo $DB_HOST $DB_PORT $DB_NAME

# 测试数据库连接
docker exec osmanthus-backend mysql -h osmanthus-mysql -u osmanthus_user -p

# 检查网络连通性
docker network ls
docker network inspect osmanthus-network
```

#### 问题 3：MinIO 访问失败
```bash
# 检查 MinIO 状态
docker logs osmanthus-minio

# 测试 MinIO 连接
curl -f http://localhost:9000/minio/health/live
```

### 🐛 性能问题

#### 数据库性能优化
```bash
# 查看慢查询日志
docker exec osmanthus-mysql tail -f /var/log/mysql/slow.log

# 优化数据库配置
docker exec osmanthus-mysql mysql -u root -p -e "SHOW VARIABLES LIKE 'innodb_%';"
```

#### 内存使用优化
```bash
# 查看内存使用情况
docker stats

# 调整 JVM 内存参数
vim .env  # 修改 JAVA_OPTS
```

## 📋 备份与恢复

### 💾 数据备份
```bash
# 备份 MySQL 数据
docker exec osmanthus-mysql mysqldump -u root -p osmanthus_music_db > backup.sql

# 备份 Redis 数据
docker exec osmanthus-redis redis-cli SAVE
docker cp osmanthus-redis:/data/dump.rdb ./redis-dump.rdb

# 备份 MinIO 数据
docker exec osmanthus-minio mc alias set local http://localhost:9000 minioadmin minioadmin2024
docker exec osmanthus-minio mc mirror local/osamanthus-music ./minio-backup
```

### 🔄 数据恢复
```bash
# 恢复 MySQL 数据
docker exec -i osmanthus-mysql mysql -u root -p osmanthus_music_db < backup.sql

# 恢复 Redis 数据
docker cp redis-dump.rdb osmanthus-redis:/data/dump.rbd
docker restart osmanthus-redis
```

## 🚀 高级功能

### 📊 监控集成
```bash
# 启用 Prometheus 监控（需要额外配置）
PROMETHEUS_ENABLED=true

# 配置 Grafana 仪表板
# 导入 Spring Boot 监控模板
```

### 🔍 日志收集
```bash
# 配置 ELK 日志收集
# 使用 Filebeat 收集日志
docker-compose -f docker-compose-logging.yml up -d
```

### 🔄 CI/CD 集成
```bash
# 配置自动化部署
# 使用 GitLab CI/CD 或 GitHub Actions
```

## 📞 技术支持

### 🆘 获取帮助
1. **查看日志**：`docker logs -f <container-name>`
2. **健康检查**：`curl http://localhost:8080/actuator/health`
3. **文档查询**：查看项目 README 文档
4. **社区支持**：提交 Issue 或联系技术支持

### 📋 常用命令速查
```bash
# 快速命令参考
docker-compose up -d          # 启动服务
docker-compose down           # 停止服务
docker-compose restart        # 重启服务
docker-compose logs -f        # 查看日志
docker-compose ps            # 查看状态
docker exec -it <container> bash  # 进入容器
```

## 📄 版本信息
- **文档版本**: v1.0.0
- **最后更新**: 2024年
- **适用版本**: Osmanthus Music Backend 1.0.0+
- **Docker 版本**: 20.10+
- **Docker Compose 版本**: 2.0+

---

**💡 提示**: 本文档基于企业级部署经验编写，建议在生产环境部署前充分测试。如有问题，请及时联系技术支持团队。