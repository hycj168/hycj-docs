# Docker 企业级多数据库容器数据挂载目录创建指南

## 📋 概述

本指南提供了企业级 Docker 多数据库容器环境的一键部署解决方案，支持 MySQL、Redis、MongoDB、PostgreSQL、Elasticsearch、Nginx、MinIO 等主流数据库和服务。

## 🚀 快速开始

### 1. 系统要求

- **操作系统**: Ubuntu 20.04+ / CentOS 7+ / Debian 10+
- **内存**: 最少 8GB，推荐 16GB+
- **磁盘空间**: 最少 50GB，推荐 100GB+
- **Docker**: 20.10+
- **Docker Compose**: 1.29+

### 2. 安装步骤

```bash
# 1. 下载脚本
git clone <your-repository>
cd docker-tutorial

# 2. 赋予执行权限
chmod +x enterprise-docker-volumes-setup.sh

# 3. 运行企业级安装脚本
sudo ./enterprise-docker-volumes-setup.sh

# 4. 创建环境变量文件
cp .env.example .env
nano .env  # 修改密码等敏感信息

# 5. 启动服务
docker-compose -f docker-compose-enterprise.yml up -d
```

## 📁 目录结构

```
/opt/docker-volumes/
├── mysql/
│   ├── data/          # MySQL 数据文件
│   ├── config/        # MySQL 配置文件
│   ├── logs/          # MySQL 日志文件
│   ├── backup/        # MySQL 备份文件
│   ├── certs/         # MySQL SSL 证书
│   ├── scripts/       # MySQL 自动化脚本
│   └── README.md      # MySQL 使用说明
├── redis/
│   ├── data/          # Redis 数据文件
│   ├── config/        # Redis 配置文件
│   ├── logs/          # Redis 日志文件
│   ├── backup/        # Redis 备份文件
│   ├── certs/         # Redis SSL 证书
│   ├── scripts/       # Redis 自动化脚本
│   └── README.md      # Redis 使用说明
├── mongodb/
│   ├── data/          # MongoDB 数据文件
│   ├── config/        # MongoDB 配置文件
│   ├── logs/          # MongoDB 日志文件
│   ├── backup/        # MongoDB 备份文件
│   ├── certs/         # MongoDB SSL 证书
│   ├── scripts/       # MongoDB 自动化脚本
│   └── README.md      # MongoDB 使用说明
├── postgres/
│   ├── data/          # PostgreSQL 数据文件
│   ├── config/        # PostgreSQL 配置文件
│   ├── logs/          # PostgreSQL 日志文件
│   ├── backup/        # PostgreSQL 备份文件
│   ├── certs/         # PostgreSQL SSL 证书
│   ├── scripts/       # PostgreSQL 自动化脚本
│   └── README.md      # PostgreSQL 使用说明
├── elasticsearch/
│   ├── data/          # Elasticsearch 数据文件
│   ├── config/        # Elasticsearch 配置文件
│   ├── logs/          # Elasticsearch 日志文件
│   ├── backup/        # Elasticsearch 备份文件
│   ├── certs/         # Elasticsearch SSL 证书
│   ├── scripts/       # Elasticsearch 自动化脚本
│   └── README.md      # Elasticsearch 使用说明
├── nginx/
│   ├── data/          # Nginx 数据文件
│   ├── config/        # Nginx 配置文件
│   ├── logs/          # Nginx 日志文件
│   ├── backup/        # Nginx 备份文件
│   ├── certs/         # Nginx SSL 证书
│   ├── scripts/       # Nginx 自动化脚本
│   └── README.md      # Nginx 使用说明
├── minio/
│   ├── data/          # MinIO 数据文件
│   ├── config/        # MinIO 配置文件
│   ├── logs/          # MinIO 日志文件
│   ├── backup/        # MinIO 备份文件
│   ├── certs/         # MinIO SSL 证书
│   ├── scripts/       # MinIO 自动化脚本
│   └── README.md      # MinIO 使用说明
└── shared/
    ├── ssl/           # 共享 SSL 证书
    ├── certs/         # 共享证书文件
    ├── scripts/       # 共享脚本文件
    ├── configs/       # 共享配置文件
    ├── templates/     # 配置模板文件
    ├── monitoring/    # 监控数据文件
    ├── security/      # 安全配置文件
    ├── docs/          # 文档文件
    └── backups/       # 共享备份文件
```

## 🔧 企业级特性

### 1. 安全特性

- **多层网络隔离**: database-network、application-network、web-network、monitoring-network
- **严格权限控制**: 每个目录都有特定的权限设置 (600, 750, 755)
- **SSL/TLS 加密**: 支持证书管理和加密通信
- **用户权限管理**: 非 root 用户运行容器服务
- **安全标签**: 每个服务都有安全级别标签

### 2. 性能优化

- **资源限制**: CPU 和内存限制，防止资源滥用
- **内存优化**: 针对每个数据库服务的内存参数优化
- **连接池配置**: 合理的数据库连接数设置
- **缓存策略**: Redis 内存管理和缓存策略

### 3. 监控告警

- **健康检查**: 每个服务都有详细的健康检查配置
- **日志管理**: 结构化日志和轮转配置
- **性能监控**: 集成监控网络，便于监控系统接入
- **告警标签**: 标准化的监控标签

### 4. 备份恢复

- **自动化备份**: 包含完整的企业级备份脚本
- **数据加密**: 备份数据支持加密存储
- **版本管理**: 支持备份版本管理和清理策略
- **恢复验证**: 备份完整性验证机制

## 🛡️ 安全最佳实践

### 1. 密码安全

```bash
# 生成强密码示例
openssl rand -base64 32

# 密码要求：
# - 至少 12 个字符
# - 包含大小写字母、数字和特殊字符
# - 每个服务使用不同的密码
# - 定期更换密码（建议每 90 天）
```

### 2. 网络安全

```bash
# 配置防火墙规则（Ubuntu/Debian）
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 9000/tcp  # MinIO API
sudo ufw allow 9001/tcp  # MinIO Console
sudo ufw enable

# 配置防火墙规则（CentOS/RHEL）
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --permanent --add-port=9001/tcp
sudo firewall-cmd --reload
```

### 3. 访问控制

```bash
# 创建专用用户组
sudo groupadd docker-admin
sudo usermod -aG docker-admin $USER

# 设置目录权限
sudo chown -R root:docker-admin /opt/docker-volumes
sudo chmod -R 750 /opt/docker-volumes
```

## 📊 性能调优

### 1. MySQL 优化

```bash
# 查看 MySQL 性能状态
docker exec mysql-production mysql -u root -p -e "SHOW STATUS LIKE 'Threads_%';"
docker exec mysql-production mysql -u root -p -e "SHOW STATUS LIKE 'Connections';"
docker exec mysql-production mysql -u root -p -e "SHOW STATUS LIKE 'Slow_queries';"

# 优化建议：
# - 根据内存大小调整 innodb_buffer_pool_size
# - 根据连接数调整 max_connections
# - 启用查询缓存（如果适用）
# - 定期分析和优化表
```

### 2. Redis 优化

```bash
# 查看 Redis 内存使用
docker exec redis-production redis-cli INFO memory
docker exec redis-production redis-cli INFO stats

# 优化建议：
# - 合理设置 maxmemory 和 maxmemory-policy
# - 使用合适的数据结构
# - 配置持久化策略
# - 监控慢查询
```

### 3. 系统级优化

```bash
# 调整系统参数
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_ratio=15" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 文件描述符限制
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
```

## 🔍 监控和日志

### 1. 查看服务状态

```bash
# 查看所有服务状态
docker-compose -f docker-compose-enterprise.yml ps

# 查看服务日志
docker-compose -f docker-compose-enterprise.yml logs mysql-production
docker-compose -f docker-compose-enterprise.yml logs redis-production

# 实时查看日志
docker-compose -f docker-compose-enterprise.yml logs -f mysql-production
```

### 2. 健康检查

```bash
# MySQL 健康检查
docker exec mysql-production mysqladmin ping -u root -p

# Redis 健康检查
docker exec redis-production redis-cli ping

# MongoDB 健康检查
docker exec mongodb-production mongosh --eval "db.adminCommand('ping')"

# PostgreSQL 健康检查
docker exec postgres-production pg_isready -U postgres

# Elasticsearch 健康检查
curl -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health

# MinIO 健康检查
curl -f http://localhost:9000/minio/health/live
```

### 3. 性能监控

```bash
# 查看容器资源使用
docker stats

# 查看容器详情
docker inspect mysql-production

# 查看磁盘使用
df -h /opt/docker-volumes
du -sh /opt/docker-volumes/*
```

## 💾 备份和恢复

### 1. 自动备份

```bash
# 运行企业级备份脚本
sudo /opt/docker-volumes/shared/scripts/enterprise-backup.sh

# 查看备份文件
ls -la /backup/docker-volumes/
```

### 2. 手动备份

```bash
# MySQL 手动备份
docker exec mysql-production mysqldump -u root -p --all-databases > backup-all-databases.sql

# Redis 手动备份
docker exec redis-production redis-cli BGSAVE
# 等待备份完成后复制 dump.rdb
docker cp redis-production:/data/dump.rdb redis-dump-$(date +%Y%m%d).rdb

# MongoDB 手动备份
docker exec mongodb-production mongodump --username=admin --password=yourpassword --authenticationDatabase=admin --out=/tmp/backup
docker cp mongodb-production:/tmp/backup ./mongodb-backup-$(date +%Y%m%d)

# PostgreSQL 手动备份
docker exec postgres-production pg_dumpall -U postgres > backup-all-postgres.sql
```

### 3. 数据恢复

```bash
# MySQL 数据恢复
docker exec -i mysql-production mysql -u root -p < backup-all-databases.sql

# Redis 数据恢复
# 停止 Redis 容器，复制 dump.rdb 文件，然后重启容器
docker-compose -f docker-compose-enterprise.yml stop redis-production
cp redis-dump-20240101.rdb /opt/docker-volumes/redis/data/dump.rdb
docker-compose -f docker-compose-enterprise.yml start redis-production

# MongoDB 数据恢复
docker exec -i mongodb-production mongorestore --username=admin --password=yourpassword --authenticationDatabase=admin /tmp/backup

# PostgreSQL 数据恢复
docker exec -i postgres-production psql -U postgres < backup-all-postgres.sql
```

## 🚨 故障排除

### 1. 常见问题

#### 容器无法启动

```bash
# 查看容器日志
docker-compose -f docker-compose-enterprise.yml logs [服务名]

# 检查配置文件
docker-compose -f docker-compose-enterprise.yml config

# 重新创建容器
docker-compose -f docker-compose-enterprise.yml down
docker-compose -f docker-compose-enterprise.yml up -d
```

#### 权限问题

```bash
# 检查目录权限
ls -la /opt/docker-volumes/
sudo chown -R 999:999 /opt/docker-volumes/mysql/data  # MySQL 用户
sudo chown -R 999:999 /opt/docker-volumes/redis/data   # Redis 用户
sudo chown -R 999:999 /opt/docker-volumes/mongodb/data # MongoDB 用户
sudo chown -R 999:999 /opt/docker-volumes/postgres/data # PostgreSQL 用户
```

#### 端口冲突

```bash
# 检查端口占用
sudo netstat -tulnp | grep :3306  # MySQL
sudo netstat -tulnp | grep :6379  # Redis
sudo netstat -tulnp | grep :27017 # MongoDB
sudo netstat -tulnp | grep :5432  # PostgreSQL
sudo netstat -tulnp | grep :9200  # Elasticsearch
sudo netstat -tulnp | grep :9000  # MinIO API
sudo netstat -tulnp | grep :9001  # MinIO Console
```

#### 内存不足

```bash
# 查看内存使用
free -h

# 查看容器内存限制
docker stats

# 调整内存限制（修改 docker-compose 文件）
deploy:
  resources:
    limits:
      memory: 1G  # 调整为合适的值
    reservations:
      memory: 512M
```

### 2. 日志分析

```bash
# 查看系统日志
sudo journalctl -u docker.service -f

# 查看容器日志
docker-compose -f docker-compose-enterprise.yml logs --tail=100 mysql-production

# 查看特定时间段的日志
docker-compose -f docker-compose-enterprise.yml logs --since="2024-01-01T00:00:00" mysql-production
```

### 3. 性能调优

```bash
# 查看慢查询（MySQL）
docker exec mysql-production mysql -u root -p -e "SHOW PROCESSLIST;"
docker exec mysql-production mysql -u root -p -e "SHOW FULL PROCESSLIST;"

# 查看连接数（Redis）
docker exec redis-production redis-cli INFO clients

# 查看数据库统计（MongoDB）
docker exec mongodb-production mongosh --eval "db.stats()"

# 查看连接数（PostgreSQL）
docker exec postgres-production psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
```

## 🔧 维护操作

### 1. 更新服务

```bash
# 拉取最新镜像
docker-compose -f docker-compose-enterprise.yml pull

# 重新创建容器（零停机时间）
docker-compose -f docker-compose-enterprise.yml up -d --force-recreate

# 清理旧镜像
docker image prune -f
```

### 2. 数据清理

```bash
# 清理日志文件
sudo find /opt/docker-volumes -name "*.log" -mtime +30 -delete
sudo find /var/log/docker-volumes -name "*.log" -mtime +30 -delete

# 清理备份文件（保留最近 30 天）
sudo find /backup/docker-volumes -name "*.tar.gz" -mtime +30 -delete

# 清理 Docker 日志
docker system prune -f
docker volume prune -f
```

### 3. 系统监控

```bash
# 创建监控脚本
sudo tee /opt/docker-volumes/shared/scripts/system-monitor.sh << 'EOF'
#!/bin/bash
# 系统监控脚本

echo "=== 系统资源使用情况 ==="
echo "内存使用:"
free -h
echo ""
echo "磁盘使用:"
df -h /opt/docker-volumes
echo ""
echo "CPU 使用:"
top -bn1 | grep "Cpu(s)"
echo ""
echo "=== Docker 容器状态 ==="
docker-compose -f /opt/docker-volumes/docker-compose-enterprise.yml ps
echo ""
echo "=== 服务健康检查 ==="
echo "MySQL: $(docker exec mysql-production mysqladmin ping -u root -pMySQL@2024!Secure 2>/dev/null && echo '正常' || echo '异常')"
echo "Redis: $(docker exec redis-production redis-cli ping 2>/dev/null && echo '正常' || echo '异常')"
echo "MongoDB: $(docker exec mongodb-production mongosh --eval "db.adminCommand('ping')" 2>/dev/null && echo '正常' || echo '异常')"
echo "PostgreSQL: $(docker exec postgres-production pg_isready -U postgres 2>/dev/null && echo '正常' || echo '异常')"
echo "Elasticsearch: $(curl -s -u elastic:ElasticSearch@2024!Secure http://localhost:9200/_cluster/health 2>/dev/null | grep -q '"status":"green"' && echo '正常' || echo '异常')"
echo "MinIO: $(curl -s http://localhost:9000/minio/health/live 2>/dev/null && echo '正常' || echo '异常')"
EOF

sudo chmod +x /opt/docker-volumes/shared/scripts/system-monitor.sh

# 运行监控脚本
sudo /opt/docker-volumes/shared/scripts/system-monitor.sh
```

## 📚 相关命令速查

### Docker Compose 命令

```bash
# 启动所有服务
docker-compose -f docker-compose-enterprise.yml up -d

# 停止所有服务
docker-compose -f docker-compose-enterprise.yml down

# 重启服务
docker-compose -f docker-compose-enterprise.yml restart [服务名]

# 查看服务状态
docker-compose -f docker-compose-enterprise.yml ps

# 查看服务日志
docker-compose -f docker-compose-enterprise.yml logs [服务名]

# 更新服务
docker-compose -f docker-compose-enterprise.yml pull
docker-compose -f docker-compose-enterprise.yml up -d --force-recreate
```

### 数据库连接命令

```bash
# MySQL
docker exec -it mysql-production mysql -u root -p

# Redis
docker exec -it redis-production redis-cli

# MongoDB
docker exec -it mongodb-production mongosh -u admin -p

# PostgreSQL
docker exec -it postgres-production psql -U postgres

# Elasticsearch
curl -u elastic:yourpassword http://localhost:9200

# MinIO
# 访问 http://your-server-ip:9001
# 用户名: minioadmin
# 密码: 在 .env 文件中配置
```

### 备份恢复命令

```bash
# 全量备份
sudo /opt/docker-volumes/shared/scripts/enterprise-backup.sh

# 查看备份
ls -la /backup/docker-volumes/

# 清理旧备份
sudo find /backup/docker-volumes -name "*.tar.gz" -mtime +30 -delete
```

## 🆘 获取帮助

### 1. 查看帮助信息

```bash
# 查看脚本帮助
./enterprise-docker-volumes-setup.sh --help

# 查看系统状态
sudo /opt/docker-volumes/shared/scripts/system-monitor.sh
```

### 2. 日志文件位置

```
/var/log/docker-volumes/
├── setup.log              # 安装日志
├── mysql-error.log        # MySQL 错误日志
├── redis-error.log        # Redis 错误日志
├── mongodb-error.log      # MongoDB 错误日志
├── postgres-error.log     # PostgreSQL 错误日志
├── elasticsearch-error.log # Elasticsearch 错误日志
├── nginx-error.log        # Nginx 错误日志
└── minio-error.log        # MinIO 错误日志
```

### 3. 常见问题 FAQ

**Q: 容器启动失败怎么办？**
A: 检查日志文件，确认端口是否被占用，检查配置文件语法，验证环境变量是否正确。

**Q: 如何修改数据库密码？**
A: 修改 .env 文件中的密码，然后重启相应的服务容器。

**Q: 磁盘空间不足怎么办？**
A: 清理日志文件，删除旧备份，压缩数据文件，或扩展磁盘容量。

**Q: 如何备份数据？**
A: 使用提供的自动备份脚本，或手动执行数据库备份命令。

**Q: 如何恢复数据？**
A: 使用对应的数据库工具导入备份文件，确保服务已停止，按文档步骤操作。

## 📞 技术支持

如遇到技术问题，请按以下步骤操作：

1. **查看日志文件**: 检查相关服务的错误日志
2. **运行诊断脚本**: 使用系统监控脚本获取状态信息
3. **检查配置文件**: 验证 Docker Compose 和环境变量配置
4. **搜索已知问题**: 查看文档中的故障排除部分
5. **收集诊断信息**: 准备系统信息、配置文件、错误日志

---

**注意**: 本指南基于企业级最佳实践设计，建议在生产环境部署前先在测试环境验证所有配置。