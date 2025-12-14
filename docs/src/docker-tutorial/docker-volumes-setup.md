# Docker 企业级数据库卷挂载目录创建脚本

## 📋 脚本概述

这个脚本为企业级 Docker 数据库容器提供了完整的数据卷挂载目录创建解决方案，支持
MySQL、Redis、MongoDB、PostgreSQL、Elasticsearch、Nginx 等常用服务。

## 🎯 主要特性

- ✅ **企业级目录结构**：遵循 Linux FHS 标准，使用 `/opt/docker-volumes/` 作为基础目录
- ✅ **完整的服务支持**：MySQL、Redis、MongoDB、PostgreSQL、Elasticsearch、Nginx
- ✅ **标准化子目录**：每个服务包含 data、config、logs、backup 四个子目录
- ✅ **权限安全控制**：不同目录设置不同的权限级别，确保数据安全
- ✅ **监控和维护**：包含磁盘监控、权限检查、日志轮转等功能
- ✅ **Docker Compose 模板**：提供完整和简化的配置模板
- ✅ **环境变量管理**：集中管理所有服务的配置参数
- ✅ **一键创建**：自动化完成所有目录和配置文件的创建

## 📁 目录结构

```
/opt/docker-volumes/
├── mysql/                    # MySQL 服务目录
│   ├── data/                 # 数据库文件（权限：750）
│   ├── config/               # 配置文件（权限：755）
│   ├── logs/                 # 日志文件（权限：755）
│   └── backup/               # 备份文件（权限：755）
├── redis/                    # Redis 服务目录
├── mongodb/                  # MongoDB 服务目录
├── postgres/                 # PostgreSQL 服务目录
├── elasticsearch/            # Elasticsearch 服务目录
├── nginx/                    # Nginx 服务目录
├── shared/                   # 共享资源目录
│   ├── ssl/                  # SSL 证书
│   ├── certs/                # 其他证书
│   ├── scripts/              # 脚本文件
│   ├── configs/              # 通用配置文件
│   └── templates/            # 配置模板
└── docker-compose-full.yml   # Docker Compose 配置文件
```

## 🚀 快速开始

### 1. 下载并运行脚本

```bash
# 给脚本添加执行权限
chmod +x docker-volumes-setup.sh

# 运行脚本
./docker-volumes-setup.sh

# 或者使用 sudo 运行（如果需要）
sudo ./docker-volumes-setup.sh
```

### 2. 脚本执行过程

脚本会自动执行以下步骤：

1. **系统检查**：验证系统环境、Docker 安装状态、磁盘空间
2. **创建基础目录**：建立 `/opt/docker-volumes/` 基础结构
3. **创建服务目录**：为每个数据库服务创建专用目录
4. **设置权限**：为不同目录设置合适的安全权限
5. **创建配置文件**：生成 Docker Compose 模板和环境变量文件
6. **创建监控脚本**：提供磁盘监控和权限检查功能
7. **验证安装**：检查所有目录和文件是否正确创建

### 3. 配置环境变量

```bash
# 进入配置目录
cd /opt/docker-volumes/shared/templates

# 复制环境变量模板
cp .env.example ../../.env

# 编辑环境变量文件（必须修改密码！）
nano ../../.env
```

### 4. 启动服务

```bash
# 使用完整配置启动所有服务
cd /opt/docker-volumes
docker-compose -f docker-compose-full.yml up -d

# 或者使用简化配置启动基础服务
docker-compose -f docker-compose-simple.yml up -d
```

## 🔧 详细使用说明

### MySQL 容器启动示例

```bash
# 基本启动命令
docker run -d \
  --name mysql-production \
  -p 3306:3306 \
  -v /opt/docker-volumes/mysql/data:/var/lib/mysql \
  -v /opt/docker-volumes/mysql/config:/etc/mysql/conf.d \
  -v /opt/docker-volumes/mysql/logs:/var/log/mysql \
  -e MYSQL_ROOT_PASSWORD=YourSecurePassword123! \
  -e MYSQL_DATABASE=appdb \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=UserSecurePassword123! \
  mysql:8.0

# 使用环境变量文件启动
docker run -d \
  --name mysql-production \
  -p 3306:3306 \
  -v /opt/docker-volumes/mysql/data:/var/lib/mysql \
  -v /opt/docker-volumes/mysql/config:/etc/mysql/conf.d \
  -v /opt/docker-volumes/mysql/logs:/var/log/mysql \
  --env-file /opt/docker-volumes/.env \
  mysql:8.0
```

### Redis 容器启动示例

```bash
docker run -d \
  --name redis-production \
  -p 6379:6379 \
  -v /opt/docker-volumes/redis/data:/data \
  -v /opt/docker-volumes/redis/config:/usr/local/etc/redis \
  -v /opt/docker-volumes/redis/logs:/var/log/redis \
  redis:7-alpine redis-server /usr/local/etc/redis/redis.conf
```

### MongoDB 容器启动示例

```bash
docker run -d \
  --name mongodb-production \
  -p 27017:27017 \
  -v /opt/docker-volumes/mongodb/data:/data/db \
  -v /opt/docker-volumes/mongodb/config:/etc/mongo \
  -v /opt/docker-volumes/mongodb/logs:/var/log/mongodb \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=YourMongoPassword123! \
  -e MONGO_INITDB_DATABASE=appdb \
  mongo:6
```

### PostgreSQL 容器启动示例

```bash
docker run -d \
  --name postgres-production \
  -p 5432:5432 \
  -v /opt/docker-volumes/postgres/data:/var/lib/postgresql/data \
  -v /opt/docker-volumes/postgres/config:/etc/postgresql \
  -v /opt/docker-volumes/postgres/logs:/var/log/postgresql \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=YourPostgresPassword123! \
  postgres:15-alpine
```

## 🛡️ 安全最佳实践

### 1. 密码安全

- ✅ **必须修改默认密码**：不要使用脚本中的示例密码
- ✅ **使用强密码**：包含大小写字母、数字、特殊字符，长度至少 16 位
- ✅ **定期更换密码**：建议每 3-6 个月更换一次
- ✅ **不同服务不同密码**：每个数据库服务使用独立的密码

```bash
# 生成安全密码
cd /opt/docker-volumes/shared/templates
./generate-passwords.sh
```

### 2. 权限管理

- ✅ **目录权限控制**：
    - `data/` 目录：750 权限（仅所有者可读写）
    - `config/` 目录：755 权限（可读，需要时可写）
    - `logs/` 目录：755 权限（便于查看和调试）
    - `backup/` 目录：755 权限（便于管理和恢复）

- ✅ **文件所有权**：所有目录归 root 用户所有，确保系统安全

### 3. 网络安全

- ✅ **防火墙配置**：限制数据库端口访问

```bash
# 只允许特定 IP 访问 MySQL
sudo ufw allow from 192.168.1.0/24 to any port 3306

# 禁止外部访问 Redis（仅本地访问）
sudo ufw deny 6379
```

- ✅ **Docker 网络隔离**：使用专用网络隔离数据库服务

### 4. 数据备份

- ✅ **定期备份**：设置自动备份计划
- ✅ **多地备份**：本地 + 远程备份
- ✅ **备份验证**：定期测试备份恢复
- ✅ **加密备份**：敏感数据备份加密存储

## 📊 监控和维护

### 1. 磁盘空间监控

```bash
# 手动检查磁盘空间
/opt/docker-volumes/shared/scripts/disk-monitor.sh

# 查看磁盘使用情况
df -h /opt/docker-volumes

# 查看目录大小
du -sh /opt/docker-volumes/*
```

### 2. 权限检查

```bash
# 检查所有目录权限
/opt/docker-volumes/shared/scripts/permission-check.sh

# 查看特定目录权限
ls -la /opt/docker-volumes/mysql/
```

### 3. 日志管理

```bash
# 查看日志文件
tail -f /var/log/docker-volumes/*.log

# 查看特定服务日志
docker logs mysql-production

# 日志轮转（自动配置）
logrotate -f /etc/logrotate.d/docker-volumes
```

### 4. 性能监控

```bash
# 监控容器资源使用
docker stats

# 查看容器详情
docker inspect mysql-production

# 检查容器健康状态
docker-compose -f docker-compose-full.yml ps
```

## 🔧 故障排除

### 常见问题

#### 1. 权限问题

**问题**：容器无法写入数据目录

```bash
# 错误信息：Permission denied
```

**解决方案**：

```bash
# 检查目录权限
ls -la /opt/docker-volumes/mysql/data/

# 重新设置权限
sudo chmod 750 /opt/docker-volumes/mysql/data/
sudo chown -R 999:999 /opt/docker-volumes/mysql/data/  # MySQL 容器用户
```

#### 2. 磁盘空间不足

**问题**：磁盘空间不足导致服务无法启动

**解决方案**：

```bash
# 检查磁盘空间
df -h

# 清理日志
docker system prune -a

# 扩展磁盘或清理数据
```

#### 3. 端口冲突

**问题**：端口已被占用

**解决方案**：

```bash
# 查看端口占用
sudo netstat -tulpn | grep :3306

# 修改 Docker Compose 配置中的端口映射
nano docker-compose-full.yml
```

#### 4. 容器启动失败

**问题**：容器无法正常启动

**解决方案**：

```bash
# 查看容器日志
docker logs mysql-production

# 检查配置文件
ls -la /opt/docker-volumes/mysql/config/

# 验证挂载路径
docker inspect mysql-production | grep Mounts -A 10
```

## 📈 性能优化

### 1. 资源限制

在 Docker Compose 中设置资源限制：

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
    reservations:
      cpus: '0.5'
      memory: 512M
```

### 2. 存储优化

- ✅ **使用 SSD**：数据目录建议使用 SSD 存储
- ✅ **分离日志**：日志文件存储在独立磁盘
- ✅ **定期清理**：清理过期日志和备份
- ✅ **压缩备份**：备份文件启用压缩

### 3. 内存优化

```bash
# MySQL 内存配置
# 在 config 目录创建 my.cnf 文件
echo "[mysqld]
innodb_buffer_pool_size = 1G
max_connections = 200" > /opt/docker-volumes/mysql/config/my.cnf

# Redis 内存配置
echo "maxmemory 512mb
maxmemory-policy allkeys-lru" > /opt/docker-volumes/redis/config/redis.conf
```

## 🔄 升级和维护

### 1. 容器升级

```bash
# 拉取最新镜像
docker-compose -f docker-compose-full.yml pull

# 重新创建容器
docker-compose -f docker-compose-full.yml up -d --force-recreate

# 清理旧镜像
docker image prune -f
```

### 2. 数据迁移

```bash
# 备份当前数据
cp -r /opt/docker-volumes/mysql/data /backup/mysql-data-$(date +%Y%m%d)

# 导出数据库
docker exec mysql-production mysqldump -u root -p --all-databases > all-databases.sql

# 导入到新容器
docker exec -i mysql-production mysql -u root -p < all-databases.sql
```

### 3. 系统更新

```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 更新 Docker
curl -fsSL https://get.docker.com | sh

# 重启 Docker 服务
sudo systemctl restart docker
```

## 📚 相关命令速查

### 目录操作

```bash
# 创建目录结构
./docker-volumes-setup.sh

# 查看目录树
tree /opt/docker-volumes -L 3

# 检查权限
ls -la /opt/docker-volumes/
```

### 容器操作

```bash
# 启动所有服务
docker-compose -f docker-compose-full.yml up -d

# 停止所有服务
docker-compose -f docker-compose-full.yml down

# 查看服务状态
docker-compose -f docker-compose-full.yml ps

# 查看日志
docker-compose -f docker-compose-full.yml logs -f
```

### 备份操作

```bash
# 执行备份脚本
/opt/docker-volumes/shared/scripts/backup-example.sh

# 手动备份
tar -czf backup-$(date +%Y%m%d).tar.gz -C /opt/docker-volumes .

# 恢复备份
tar -xzf backup-20240101.tar.gz -C /opt/docker-volumes/
```

## 🆘 获取帮助

### 1. 查看帮助信息

```bash
# 查看脚本使用说明
./docker-volumes-setup.sh --help

# 查看 Docker 帮助
docker --help
docker-compose --help
```

### 2. 日志文件

```bash
# 脚本执行日志
tail -f /var/log/docker-volumes/setup.log

# 监控日志
tail -f /var/log/docker-volumes/disk-monitor.log

# Docker 日志
journalctl -u docker -f
```

### 3. 在线资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [MySQL Docker 镜像](https://hub.docker.com/_/mysql)
- [Redis Docker 镜像](https://hub.docker.com/_/redis)
- [MongoDB Docker 镜像](https://hub.docker.com/_/mongo)
- [PostgreSQL Docker 镜像](https://hub.docker.com/_/postgres)

## 📄 许可证

本脚本遵循 MIT 许可证，可以自由使用、修改和分发。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个脚本。

---

**⚠️ 重要提醒**：

1. **安全第一**：请务必修改所有默认密码！
2. **定期备份**：设置自动备份计划，确保数据安全
3. **监控维护**：定期检查系统状态和性能
4. **及时更新**：保持 Docker 镜像和系统更新

**祝您使用愉快！** 🎉