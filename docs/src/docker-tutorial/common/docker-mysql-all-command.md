# Docker 安装 MySQL 完整指令集（带详细中文注释）

本教程提供 Docker 安装 MySQL 最新版本的完整指令集，包含各种数据卷映射、挂载配置和高级选项，每个指令都配有详细的中文注释。

## 📋 目录

1. [基础安装指令](#基础安装指令)
2. [数据卷映射配置](#数据卷映射配置)
3. [Docker数据卷挂载机制详解](#docker数据卷挂载机制详解)
4. [高级配置指令](#高级配置指令)
5. [主从复制配置](#主从复制配置)
6. [备份恢复指令](#备份恢复指令)
7. [性能优化指令](#性能优化指令)
8. [监控管理指令](#监控管理指令)
9. [故障排除指令](#故障排除指令)

## 🚀 基础安装指令

### 1.1 拉取 MySQL 镜像

```bash
# 拉取最新版本的 MySQL 镜像
docker pull mysql:latest

# 拉取指定版本的 MySQL 镜像（推荐生产环境使用特定版本）
docker pull mysql:8.0.40

# 拉取 MySQL 5.7 版本（兼容性考虑）
docker pull mysql:5.7.43

# 查看本地已有的 MySQL 镜像
docker images | grep mysql

# 查看镜像详细信息
docker inspect mysql:latest
```

### 1.2 基础容器运行（无数据持久化）

```bash
# 最简单的运行方式 - 仅设置 root 密码，数据不持久化（不推荐用于生产）
docker run --name mysql-basic \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -p 3306:3306 \
  -d mysql:latest

# 带数据库和用户创建的简单运行
docker run --name mysql-with-db \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=myapp \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=userpassword \
  -p 3306:3306 \
  -d mysql:latest
```

## 💾 数据卷映射配置

### 2.1 基础数据持久化

```bash
# 创建数据卷（Docker 管理卷）- 推荐方式
docker run --name mysql-volume \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -v mysql-data:/var/lib/mysql \
  -p 3306:3306 \
  -d mysql:latest

# 使用主机目录挂载 - 更直观的数据管理
docker run --name mysql-host-dir \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -v /opt/mysql/data:/var/lib/mysql \
  -p 3306:3306 \
  -d mysql:latest
```

### 2.2 完整数据卷映射（推荐配置）

```bash
# 完整的目录结构映射 - 生产环境推荐配置
docker run --name mysql-production \
  -e MYSQL_ROOT_PASSWORD=StrongRootPass123! \
  -e MYSQL_DATABASE=production_db \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=AppUserPass123! \
  \
  # 数据文件映射 - 必须配置，确保数据持久化
  -v /opt/mysql/data:/var/lib/mysql \
  \
  # 配置文件映射 - 自定义 MySQL 配置
  -v /opt/mysql/config:/etc/mysql/conf.d \
  \
  # 日志文件映射 - 便于日志管理和分析
  -v /opt/mysql/logs:/var/log/mysql \
  \
  # 初始化脚本映射 - 容器启动时自动执行
  -v /opt/mysql/init:/docker-entrypoint-initdb.d \
  \
  # 时区配置映射 - 确保容器时间正确
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  \
  # 端口映射
  -p 3306:3306 \
  \
  # 重启策略 - 确保容器异常退出后自动重启
  --restart=unless-stopped \
  \
  # 资源限制 - 防止容器占用过多资源
  --memory=4g \
  --cpus=2 \
  \
  -d mysql:8.0.40
```

### 2.3 Docker 数据卷挂载机制详解

#### 🔍 自动创建机制分析

**重要结论：Docker 会自动创建挂载的数据卷，但行为因挂载类型而异**

#### 1. **Docker 管理卷（命名卷）**
```bash
# 这种形式会自动创建数据卷 - 完全自动化
-v mysql-data:/var/lib/mysql
```
- ✅ **完全自动创建**：Docker 会自动创建名为 `mysql-data` 的卷
- ✅ **Docker 自动管理**：存储位置、权限都由 Docker 管理
- ✅ **无需手动干预**：即使目录不存在也会自动创建

#### 2. **主机目录挂载（绑定挂载）**
```bash
# 这种形式的主机目录行为不同 - 需要特别注意
-v /opt/mysql/data:/var/lib/mysql
```
- ✅ **容器内目录** `/var/lib/mysql` **总是自动创建**
- ⚠️ **主机目录** `/opt/mysql/data` **需要手动创建**（强烈推荐）
- ⚠️ **如果主机目录不存在**，Docker 会**自动创建但权限可能不正确**

#### 🚨 权限问题（最常见故障原因）
```bash
# 主机目录自动创建时的问题：
drwxr-xr-x 2 root root 4096 /opt/mysql/data/  # ❌ 权限错误 - MySQL无法写入
# MySQL 容器需要：
drwxr-xr-x 2 999 999 4096 /opt/mysql/data/    # ✅ 正确权限 - UID 999是MySQL用户
```

#### 💡 验证挂载状态
```bash
# 检查容器挂载信息
docker inspect mysql-container | grep -A 10 Mounts

# 查看数据卷列表
docker volume ls

# 检查特定数据卷详情
docker volume inspect mysql-data

# 查看容器内挂载点
docker exec mysql-container ls -la /var/lib/mysql

# 查看主机挂载点权限
docker exec mysql-container ls -la /opt/mysql/data
```

#### 📊 不同挂载类型对比

| 挂载类型 | 自动创建 | 权限管理 | 适用场景 | 推荐程度 |
|---------|---------|---------|---------|----------|
| Docker管理卷 | ✅ 完全自动 | ✅ Docker管理 | 数据持久化 | ⭐⭐⭐⭐⭐ |
| 主机目录挂载 | ⚠️ 部分自动 | ⚠️ 需手动设置 | 配置文件、日志 | ⭐⭐⭐⭐ |
| tmpfs挂载 | ✅ 内存自动 | ✅ 系统管理 | 临时数据 | ⭐⭐ |

### 2.4 推荐的目录结构创建脚本（生产环境标准）

```bash
#!/bin/bash
# MySQL Docker 完整目录结构创建脚本 - 生产环境标准
# 作者：Docker MySQL 企业级部署指南
# 版本：2025年12月最新版

set -euo pipefail  # 严格错误处理

# 配置变量
MYSQL_BASE_DIR="/opt/mysql"
MYSQL_USER_UID="999"  # MySQL容器内用户UID
MYSQL_USER_GID="999"  # MySQL容器内用户GID

echo "🚀 开始创建 MySQL Docker 目录结构..."
echo "📁 基础目录：${MYSQL_BASE_DIR}"

# 创建完整的目录结构
mkdir -p ${MYSQL_BASE_DIR}/{data,config,logs,backup,init,scripts,ssl,certs}

echo "✅ 目录结构创建完成"

# 设置权限 - 这是最关键的一步
echo "🔒 设置目录权限..."

# 数据目录 - 必须设置正确的用户和权限
sudo chown -R ${MYSQL_USER_UID}:${MYSQL_USER_GID} ${MYSQL_BASE_DIR}/data
sudo chmod 750 ${MYSQL_BASE_DIR}/data

# 配置目录 - 需要读写权限
sudo chown -R ${MYSQL_USER_UID}:${MYSQL_USER_GID} ${MYSQL_BASE_DIR}/config
sudo chmod 755 ${MYSQL_BASE_DIR}/config

# 日志目录 - 需要写入权限
sudo chown -R ${MYSQL_USER_UID}:${MYSQL_USER_GID} ${MYSQL_BASE_DIR}/logs
sudo chmod 755 ${MYSQL_BASE_DIR}/logs

# 备份目录 - 需要读写权限
sudo chown -R ${MYSQL_USER_UID}:${MYSQL_USER_GID} ${MYSQL_BASE_DIR}/backup
sudo chmod 755 ${MYSQL_BASE_DIR}/backup

# 初始化脚本目录
sudo chown -R ${MYSQL_USER_UID}:${MYSQL_USER_GID} ${MYSQL_BASE_DIR}/init
sudo chmod 755 ${MYSQL_BASE_DIR}/init

# 脚本目录
sudo chmod 755 ${MYSQL_BASE_DIR}/scripts

# SSL证书目录
sudo chown -R ${MYSQL_USER_UID}:${MYSQL_USER_GID} ${MYSQL_BASE_DIR}/ssl
sudo chmod 700 ${MYSQL_BASE_DIR}/ssl

# 证书目录
sudo chown -R ${MYSQL_USER_UID}:${MYSQL_USER_GID} ${MYSQL_BASE_DIR}/certs
sudo chmod 700 ${MYSQL_BASE_DIR}/certs

echo "✅ 权限设置完成"

# 创建基础配置文件
echo "⚙️ 创建基础配置文件..."

# 主配置文件
cat > ${MYSQL_BASE_DIR}/config/mysql.cnf << 'EOF'
[mysqld]
# 基础配置
server-id=1
port=3306
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# 内存配置 - 根据服务器内存调整
innodb_buffer_pool_size=2G
max_connections=1000

# 日志配置
log-error=/var/log/mysql/error.log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2

# 二进制日志配置
log-bin=mysql-bin
binlog-format=ROW
expire_logs_days=7
max_binlog_size=100M

# 安全配置
skip-name-resolve
secure-file-priv=/var/lib/mysql-files
EOF

# 性能优化配置
cat > ${MYSQL_BASE_DIR}/config/performance.cnf << 'EOF'
[mysqld]
# 查询缓存
query_cache_type=1
query_cache_size=256M
query_cache_limit=4M

# InnoDB 优化
innodb_log_buffer_size=64M
innodb_log_file_size=256M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT
innodb_io_capacity=2000
innodb_read_io_threads=8
innodb_write_io_threads=8

# 表缓存
table_open_cache=2000
table_definition_cache=1400

# 线程缓存
thread_cache_size=100
EOF

# 安全配置
cat > ${MYSQL_BASE_DIR}/config/security.cnf << 'EOF'
[mysqld]
# 密码策略
validate_password_policy=MEDIUM
validate_password_length=8

# 连接限制
max_connect_errors=1000
max_user_connections=100

# SSL配置（如需要）
# ssl-ca=/etc/mysql/ssl/ca.pem
# ssl-cert=/etc/mysql/ssl/server-cert.pem
# ssl-key=/etc/mysql/ssl/server-key.pem

# 禁用危险功能
local-infile=0
skip-symbolic-links
EOF

echo "✅ 配置文件创建完成"

# 创建日志文件（确保MySQL有权限写入）
echo "📝 初始化日志文件..."
touch ${MYSQL_BASE_DIR}/logs/{error.log,slow.log,general.log}
chown ${MYSQL_USER_UID}:${MYSQL_USER_GID} ${MYSQL_BASE_DIR}/logs/*.log
chmod 644 ${MYSQL_BASE_DIR}/logs/*.log

echo "✅ 日志文件初始化完成"

# 显示最终目录结构
echo "📂 最终目录结构："
ls -la ${MYSQL_BASE_DIR}/
echo ""
echo "📁 子目录详情："
for dir in data config logs backup init scripts ssl certs; do
    echo "  📁 ${dir}: $(ls -la ${MYSQL_BASE_DIR}/${dir} | wc -l) 个项目"
done

echo ""
echo "🎉 MySQL Docker 目录结构创建完成！"
echo "📍 目录位置：${MYSQL_BASE_DIR}"
echo "👤 文件所有者：UID ${MYSQL_USER_UID}, GID ${MYSQL_USER_GID}"
echo "🔒 权限已设置为生产环境标准"
echo ""
echo "💡 使用提示："
echo "   1. 现在可以安全地运行 MySQL Docker 容器"
echo "   2. 所有权限都已正确设置"
echo "   3. 配置文件已准备就绪"
echo "   4. 日志文件已初始化"
```

### 2.5 数据卷挂载验证脚本

```bash
#!/bin/bash
# MySQL Docker 数据卷挂载验证脚本
# 用于验证挂载是否正确，权限是否合适

MYSQL_CONTAINER="${1:-mysql-production}"
MYSQL_BASE_DIR="/opt/mysql"

echo "🔍 验证 MySQL 容器数据卷挂载状态..."
echo "🐳 容器名称：${MYSQL_CONTAINER}"

# 检查容器是否运行
if ! docker ps | grep -q ${MYSQL_CONTAINER}; then
    echo "❌ 容器 ${MYSQL_CONTAINER} 未运行"
    exit 1
fi

echo "✅ 容器正在运行"

# 1. 检查挂载信息
echo "📋 挂载信息检查："
docker inspect ${MYSQL_CONTAINER} | grep -A 20 '"Mounts"' | head -30

# 2. 检查容器内目录权限
echo ""
echo "🔒 容器内目录权限检查："
docker exec ${MYSQL_CONTAINER} ls -la /var/lib/mysql/ | head -10
docker exec ${MYSQL_CONTAINER} ls -la /etc/mysql/conf.d/ | head -5
docker exec ${MYSQL_CONTAINER} ls -la /var/log/mysql/ | head -5

# 3. 检查MySQL用户权限
echo ""
echo "👤 MySQL用户权限检查："
docker exec ${MYSQL_CONTAINER} id mysql || echo "MySQL用户UID: $(docker exec ${MYSQL_CONTAINER} id -u mysql 2>/dev/null || echo '999')"

# 4. 测试写入权限
echo ""
echo "✍️ 写入权限测试："
docker exec ${MYSQL_CONTAINER} touch /var/lib/mysql/test_write.tmp && \
docker exec ${MYSQL_CONTAINER} rm /var/lib/mysql/test_write.tmp && \
echo "✅ 数据目录写入权限正常" || echo "❌ 数据目录写入权限异常"

# 5. 检查配置文件读取
echo ""
echo "📖 配置文件读取测试："
docker exec ${MYSQL_CONTAINER} test -f /etc/mysql/conf.d/mysql.cnf && \
echo "✅ 主配置文件存在并可读" || echo "❌ 主配置文件无法读取"

# 6. 检查日志写入
echo ""
echo "📝 日志写入测试："
docker exec ${MYSQL_CONTAINER} test -w /var/log/mysql/ && \
echo "✅ 日志目录可写" || echo "❌ 日志目录不可写"

echo ""
echo "🎯 验证完成！"
echo "💡 如果发现异常，请检查："
echo "   1. 主机目录权限是否正确"
echo "   2. 文件所有者是否为UID 999"
echo "   3. 挂载配置是否正确"
echo "   4. SELinux/AppArmor是否阻止访问"
```

#### 🎯 最佳实践总结

1. **预先创建目录**：避免Docker自动创建导致的权限问题
2. **设置正确权限**：数据目录必须为UID 999所有
3. **验证挂载状态**：使用验证脚本确保挂载正确
4. **监控权限变化**：定期检查权限是否被意外修改
5. **使用标准脚本**：采用提供的完整脚本确保一致性

echo "MySQL 目录结构创建完成！"
ls -la /opt/mysql/

## ⚙️ 高级配置指令

### 3.1 环境变量完整配置

```bash
# 完整的环境变量配置 - 覆盖 MySQL 的所有基本设置
docker run --name mysql-advanced \
  # 根用户密码 - 必须设置
  -e MYSQL_ROOT_PASSWORD=StrongRootPass123! \
  \
  # 默认数据库 - 容器启动时自动创建
  -e MYSQL_DATABASE=production_db \
  \
  # 默认用户 - 与数据库一起创建
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=AppUserStrongPass123! \
  \
  # 根主机访问 - 允许从任意主机连接
  -e MYSQL_ROOT_HOST=% \
  \
  # 时区设置 - 重要的时间配置
  -e TZ=Asia/Shanghai \
  \
  # 字符集配置 - 确保中文支持
  -e MYSQL_CHARSET=utf8mb4 \
  -e MYSQL_COLLATION=utf8mb4_unicode_ci \
  \
  # 初始化脚本执行 - 是否执行 /docker-entrypoint-initdb.d 中的脚本
  -e MYSQL_INITDB_SKIP_TZINFO=1 \
  \
  # 性能配置 - 根据服务器内存调整
  -e MYSQL_MEMORY_LIMIT=4G \
  \
  -p 3306:3306 \
  -v /opt/mysql/data:/var/lib/mysql \
  -v /opt/mysql/config:/etc/mysql/conf.d \
  -v /opt/mysql/logs:/var/log/mysql \
  --restart=unless-stopped \
  -d mysql:8.0.40
```

### 3.2 命令行参数配置

```bash
# 通过命令行参数传递 MySQL 配置 - 覆盖配置文件设置
docker run --name mysql-command-line \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -p 3306:3306 \
  -v /opt/mysql/data:/var/lib/mysql \
  \
  # 命令行参数 - 直接传递给 mysqld 进程
  mysql:8.0.40 \
  --default-authentication-plugin=mysql_native_password \
  --sql-mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION \
  --max-connections=2000 \
  --innodb-buffer-pool-size=3G \
  --query-cache-size=256M \
  --slow-query-log=1 \
  --long-query-time=2
```

### 3.3 网络配置

```bash
# 创建自定义网络 - 更好的网络隔离和管理
docker network create --driver bridge \
  --subnet=172.20.0.0/16 \
  --gateway=172.20.0.1 \
  mysql-network

# 在自定义网络中运行 MySQL
docker run --name mysql-custom-network \
  --network mysql-network \
  --ip 172.20.0.10 \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -v /opt/mysql/data:/var/lib/mysql \
  -d mysql:8.0.40

# 查看网络信息
docker network inspect mysql-network
```

## 🔄 主从复制配置

### 4.1 主服务器配置

```bash
# 主服务器容器 - 开启二进制日志
docker run --name mysql-master \
  -e MYSQL_ROOT_PASSWORD=MasterRootPass123! \
  \
  # 主服务器配置 - 通过命令行参数
  mysql:8.0.40 \
  --server-id=1 \
  --log-bin=mysql-bin \
  --binlog-format=ROW \
  --expire-logs-days=7 \
  --max-binlog-size=100M \
  --binlog-do-db=replication_db

# 或者使用配置文件方式 - 更清晰的配置管理
docker run --name mysql-master \
  -e MYSQL_ROOT_PASSWORD=MasterRootPass123! \
  -v /opt/mysql/master/data:/var/lib/mysql \
  -v /opt/mysql/master/config:/etc/mysql/conf.d \
  -v /opt/mysql/master/logs:/var/log/mysql \
  -p 3306:3306 \
  -d mysql:8.0.40
```

主服务器配置文件 `/opt/mysql/master/config/master.cnf`：
```ini
[mysqld]
server-id=1
log-bin=mysql-bin
binlog-format=ROW
expire_logs_days=7
max_binlog_size=100M
binlog-do-db=replication_db
```

### 4.2 从服务器配置

```bash
# 从服务器容器 - 配置中继日志
docker run --name mysql-slave \
  -e MYSQL_ROOT_PASSWORD=SlaveRootPass123! \
  -v /opt/mysql/slave/data:/var/lib/mysql \
  -v /opt/mysql/slave/config:/etc/mysql/conf.d \
  -v /opt/mysql/slave/logs:/var/log/mysql \
  -p 3307:3306 \
  -d mysql:8.0.40
```

从服务器配置文件 `/opt/mysql/slave/config/slave.cnf`：
```ini
[mysqld]
server-id=2
relay-log=mysql-relay-bin
log-slave-updates=1
read-only=1
```

### 4.3 主从复制设置脚本

```bash
#!/bin/bash
# MySQL 主从复制配置脚本

# 获取主服务器状态
echo "获取主服务器状态..."
docker exec mysql-master mysql -uroot -pMasterRootPass123! -e "SHOW MASTER STATUS;"

# 在主服务器上创建复制用户
echo "创建复制用户..."
docker exec mysql-master mysql -uroot -pMasterRootPass123! -e "
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'ReplPass123!';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
"

# 在从服务器上配置主服务器信息
echo "配置从服务器..."
docker exec mysql-slave mysql -uroot -pSlaveRootPass123! -e "
CHANGE MASTER TO
  MASTER_HOST='mysql-master',
  MASTER_USER='repl',
  MASTER_PASSWORD='ReplPass123!',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=0;
"

# 启动从服务器复制
echo "启动从服务器复制..."
docker exec mysql-slave mysql -uroot -pSlaveRootPass123! -e "START SLAVE;"

# 检查从服务器状态
echo "检查从服务器状态..."
docker exec mysql-slave mysql -uroot -pSlaveRootPass123! -e "SHOW SLAVE STATUS\G"
```

## 💾 备份恢复指令

### 5.1 数据备份

```bash
# 进入 MySQL 容器执行备份
docker exec mysql-container mysqldump -uroot -pYourPassword \
  --all-databases \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# 使用 Docker 卷备份数据目录
docker run --rm \
  -v mysql-data:/data \
  -v $(pwd):/backup \
  alpine:latest \
  tar czf /backup/mysql-data-backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# 备份特定数据库
docker exec mysql-container mysqldump -uroot -pYourPassword \
  production_db \
  --single-transaction \
  --routines \
  --triggers \
  > production_db_backup.sql
```

### 5.2 数据恢复

```bash
# 从 SQL 文件恢复数据
docker exec -i mysql-container mysql -uroot -pYourPassword < backup.sql

# 恢复特定数据库
docker exec -i mysql-container mysql -uroot -pYourPassword production_db < production_db_backup.sql

# 从压缩包恢复数据卷
docker run --rm \
  -v mysql-data:/data \
  -v $(pwd):/backup \
  alpine:latest \
  tar xzf /backup/mysql-data-backup.tar.gz -C /data
```

### 5.3 自动备份脚本

```bash
#!/bin/bash
# MySQL Docker 自动备份脚本

# 配置变量
BACKUP_DIR="/opt/mysql/backup"
MYSQL_CONTAINER="mysql-production"
MYSQL_USER="root"
MYSQL_PASSWORD="YourStrongRootPass123!"
RETENTION_DAYS=7

# 创建备份目录
mkdir -p "${BACKUP_DIR}"

# 生成备份文件名
BACKUP_FILE="mysql_backup_$(date +%Y%m%d_%H%M%S).sql"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

echo "开始备份 MySQL 数据库..."

# 执行备份
docker exec "${MYSQL_CONTAINER}" mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
  --all-databases \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --hex-blob \
  > "${BACKUP_PATH}"

# 检查备份是否成功
if [ $? -eq 0 ]; then
    echo "备份成功: ${BACKUP_FILE}"
    
    # 压缩备份文件
    gzip "${BACKUP_PATH}"
    echo "备份文件已压缩: ${BACKUP_FILE}.gz"
    
    # 清理过期备份
    find "${BACKUP_DIR}" -name "mysql_backup_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
    echo "清理了 ${RETENTION_DAYS} 天前的备份文件"
    
else
    echo "备份失败！"
    rm -f "${BACKUP_PATH}"
    exit 1
fi
```

## ⚡ 性能优化指令

### 6.1 内存优化配置

```bash
# 根据服务器内存大小配置 MySQL 内存参数
docker run --name mysql-memory-optimized \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -v /opt/mysql/data:/var/lib/mysql \
  -v /opt/mysql/config:/etc/mysql/conf.d \
  --memory=8g \
  --memory-swap=8g \
  -d mysql:8.0.40 \
  --innodb-buffer-pool-size=6G \
  --query-cache-size=512M \
  --tmp-table-size=256M \
  --max-heap-table-size=256M \
  --sort-buffer-size=8M \
  --join-buffer-size=8M
```

### 6.2 查询缓存配置

```bash
# 启用查询缓存的 MySQL 配置
docker run --name mysql-query-cache \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -v /opt/mysql/data:/var/lib/mysql \
  -d mysql:8.0.40 \
  --query-cache-type=1 \
  --query-cache-size=256M \
  --query-cache-limit=4M \
  --table-open-cache=2000 \
  --thread-cache-size=100
```

### 6.3 InnoDB 优化

```bash
# InnoDB 存储引擎优化配置
docker run --name mysql-innodb-optimized \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -v /opt/mysql/data:/var/lib/mysql \
  -d mysql:8.0.40 \
  --innodb-buffer-pool-size=4G \
  --innodb-log-buffer-size=64M \
  --innodb-log-file-size=256M \
  --innodb-flush-log-at-trx-commit=2 \
  --innodb-flush-method=O_DIRECT \
  --innodb-io-capacity=2000 \
  --innodb-read-io-threads=8 \
  --innodb-write-io-threads=8
```

## 📊 监控管理指令

### 7.1 容器健康检查

```bash
# 检查容器运行状态
docker ps | grep mysql

# 查看容器详细信息
docker inspect mysql-container

# 查看容器日志
docker logs mysql-container

# 实时查看日志输出
docker logs -f mysql-container

# 查看最近 100 行日志
docker logs --tail 100 mysql-container
```

### 7.2 MySQL 状态监控

```bash
# 检查 MySQL 服务状态
docker exec mysql-container mysqladmin -uroot -pYourPassword ping

# 查看 MySQL 进程列表
docker exec mysql-container mysql -uroot -pYourPassword -e "SHOW PROCESSLIST;"

# 查看 MySQL 状态变量
docker exec mysql-container mysql -uroot -pYourPassword -e "SHOW STATUS;"

# 查看 MySQL 系统变量
docker exec mysql-container mysql -uroot -pYourPassword -e "SHOW VARIABLES;"

# 查看 InnoDB 状态
docker exec mysql-container mysql -uroot -pYourPassword -e "SHOW ENGINE INNODB STATUS\G"
```

### 7.3 性能监控脚本

```bash
#!/bin/bash
# MySQL Docker 性能监控脚本

MYSQL_CONTAINER="mysql-production"
MYSQL_USER="root"
MYSQL_PASSWORD="YourPassword"

echo "=== MySQL 性能监控 $(date) ==="

# 连接数检查
echo "当前连接数:"
docker exec "${MYSQL_CONTAINER}" mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
  -e "SHOW STATUS LIKE 'Threads_connected';"

# 查询缓存命中率
echo "查询缓存命中率:"
docker exec "${MYSQL_CONTAINER}" mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
  -e "SHOW STATUS LIKE 'Qcache%';"

# InnoDB 缓冲池命中率
echo "InnoDB 缓冲池命中率:"
docker exec "${MYSQL_CONTAINER}" mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
  -e "SHOW STATUS LIKE 'Innodb_buffer_pool%';"

# 慢查询数量
echo "慢查询数量:"
docker exec "${MYSQL_CONTAINER}" mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
  -e "SHOW STATUS LIKE 'Slow_queries';"
```

## 🔧 故障排除指令

### 8.1 容器启动问题

```bash
# 查看容器启动失败原因
docker logs mysql-container

# 检查容器状态
docker ps -a | grep mysql

# 查看容器资源使用情况
docker stats mysql-container

# 进入容器内部检查
docker exec -it mysql-container bash

# 在容器内检查 MySQL 进程
ps aux | grep mysql

# 检查 MySQL 错误日志
docker exec mysql-container tail -f /var/log/mysql/error.log
```

### 8.2 连接问题排查

```bash
# 检查端口监听
netstat -tlnp | grep 3306

# 检查容器端口映射
docker port mysql-container

# 测试容器内 MySQL 连接
docker exec mysql-container mysql -uroot -pYourPassword -e "SELECT 1;"

# 从主机测试 MySQL 连接
mysql -h127.0.0.1 -P3306 -uroot -pYourPassword -e "SELECT 1;"

# 检查防火墙状态（Ubuntu）
sudo ufw status

# 检查防火墙状态（CentOS）
sudo firewall-cmd --state
sudo firewall-cmd --list-ports
```

### 8.3 权限问题解决

```bash
# 查看 MySQL 用户权限
docker exec mysql-container mysql -uroot -pYourPassword -e "SELECT host, user FROM mysql.user;"

# 授权用户远程访问
docker exec mysql-container mysql -uroot -pYourPassword -e "
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'YourPassword' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"

# 创建新用户并授权
docker exec mysql-container mysql -uroot -pYourPassword -e "
CREATE USER 'newuser'@'%' IDENTIFIED BY 'NewUserPassword';
GRANT ALL PRIVILEGES ON *.* TO 'newuser'@'%';
FLUSH PRIVILEGES;
"

# 重置 root 密码（如果忘记密码）
docker exec -it mysql-container bash
# 在容器内执行：
mysql -uroot -p
# 然后执行：
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword';
```

### 8.4 数据卷挂载故障排除

#### 🔍 挂载状态检查
```bash
# 检查容器挂载信息 - 查看所有挂载点
docker inspect mysql-container | grep -A 30 '"Mounts"'

# 查看数据卷列表
docker volume ls

# 检查特定数据卷详情
docker volume inspect mysql-data

# 检查容器内挂载点权限
docker exec mysql-container ls -la /var/lib/mysql/

# 检查主机挂载点权限
docker exec mysql-container ls -la /opt/mysql/data
```

#### 🚨 常见挂载问题及解决方案

##### 1. 权限问题（最常见）
```bash
# 问题：MySQL容器无法写入数据目录
# 错误信息：mysqld: Can't create/write to file '/var/lib/mysql/ibdata1'

# 解决方案：
# 1. 检查主机目录权限
ls -la /opt/mysql/data

# 2. 修正权限为UID 999（MySQL用户）
sudo chown -R 999:999 /opt/mysql/data
sudo chmod 750 /opt/mysql/data

# 3. 验证权限修正
docker exec mysql-container ls -la /var/lib/mysql/
```

##### 2. SELinux/AppArmor阻止访问
```bash
# 问题：SELinux阻止容器访问主机目录
# 解决方案：

# CentOS/RHEL系统：
# 临时禁用SELinux（测试用）
sudo setenforce 0

# 或者设置正确的SELinux上下文
sudo chcon -Rt svirt_sandbox_file_t /opt/mysql/data

# Ubuntu系统：
# 检查AppArmor状态
sudo aa-status

# 临时禁用AppArmor（测试用）
sudo systemctl stop apparmor
```

##### 3. 挂载点不存在
```bash
# 问题：挂载的主机目录不存在
# 错误信息：Error response from daemon: invalid mount config

# 解决方案：
# 1. 创建缺失的目录
mkdir -p /opt/mysql/{data,config,logs}

# 2. 设置正确权限
sudo chown -R 999:999 /opt/mysql/data
sudo chmod 750 /opt/mysql/data

# 3. 重新创建容器
docker rm mysql-container
docker run --name mysql-container ...
```

##### 4. 磁盘空间不足
```bash
# 问题：磁盘空间不足导致挂载失败
# 解决方案：

# 检查磁盘空间
df -h

# 清理Docker无用数据
docker system prune -a

# 检查Docker存储位置
docker info | grep "Docker Root Dir"

# 移动Docker存储位置（如果需要）
# 停止Docker服务
sudo systemctl stop docker

# 移动数据目录
sudo mv /var/lib/docker /home/docker

# 创建软链接
sudo ln -s /home/docker /var/lib/docker

# 启动Docker服务
sudo systemctl start docker
```

#### 🔧 挂载验证和修复工具

```bash
#!/bin/bash
# MySQL Docker 挂载问题诊断和修复脚本

MYSQL_CONTAINER="${1:-mysql-container}"
MYSQL_BASE_DIR="/opt/mysql"

echo "🔧 MySQL Docker 挂载问题诊断和修复工具"
echo "🐳 容器：${MYSQL_CONTAINER}"
echo "📁 主机目录：${MYSQL_BASE_DIR}"

# 1. 检查容器状态
echo "📋 检查容器状态..."
if docker ps | grep -q ${MYSQL_CONTAINER}; then
    echo "✅ 容器正在运行"
elif docker ps -a | grep -q ${MYSQL_CONTAINER}; then
    echo "⚠️ 容器存在但未运行"
    echo "🔄 尝试启动容器..."
    docker start ${MYSQL_CONTAINER}
else
    echo "❌ 容器不存在"
    exit 1
fi

# 2. 检查挂载状态
echo ""
echo "🔍 检查挂载状态..."
docker inspect ${MYSQL_CONTAINER} | grep -A 50 '"Mounts"' | head -50

# 3. 检查权限问题
echo ""
echo "🔒 检查权限问题..."

# 检查主机目录是否存在
for dir in data config logs; do
    if [ -d "${MYSQL_BASE_DIR}/${dir}" ]; then
        echo "✅ ${MYSQL_BASE_DIR}/${dir} 存在"
        
        # 检查权限
        owner=$(stat -c '%u:%g' "${MYSQL_BASE_DIR}/${dir}")
        if [ "$owner" = "999:999" ] || [ "$owner" = "999" ]; then
            echo "✅ ${dir} 目录权限正确: ${owner}"
        else
            echo "⚠️ ${dir} 目录权限错误: ${owner}，需要 999:999"
            echo "🔄 修复权限..."
            sudo chown -R 999:999 "${MYSQL_BASE_DIR}/${dir}"
            echo "✅ 权限已修复"
        fi
    else
        echo "❌ ${MYSQL_BASE_DIR}/${dir} 不存在"
        echo "🔄 创建目录..."
        mkdir -p "${MYSQL_BASE_DIR}/${dir}"
        sudo chown -R 999:999 "${MYSQL_BASE_DIR}/${dir}"
        echo "✅ 目录已创建并设置权限"
    fi
done

# 4. 测试容器内访问
echo ""
echo "🧪 测试容器内访问..."
docker exec ${MYSQL_CONTAINER} ls -la /var/lib/mysql/ > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ 容器可以访问数据目录"
else
    echo "❌ 容器无法访问数据目录"
fi

# 5. 测试写入权限
echo ""
echo "✍️ 测试写入权限..."
docker exec ${MYSQL_CONTAINER} touch /var/lib/mysql/test_write.tmp 2>/dev/null
if [ $? -eq 0 ]; then
    docker exec ${MYSQL_CONTAINER} rm /var/lib/mysql/test_write.tmp
    echo "✅ 数据目录写入权限正常"
else
    echo "❌ 数据目录写入权限异常"
fi

# 6. 检查SELinux/AppArmor
echo ""
echo "🛡️ 检查安全模块..."
if command -v getenforce >/dev/null 2>&1; then
    selinux_status=$(getenforce)
    echo "SELinux状态：${selinux_status}"
    if [ "$selinux_status" = "Enforcing" ]; then
        echo "⚠️ SELinux可能阻止访问，考虑临时禁用或设置正确上下文"
    fi
fi

if command -v aa-status >/dev/null 2>&1; then
    if aa-status | grep -q "apparmor module is loaded"; then
        echo "⚠️ AppArmor正在运行，可能阻止访问"
    fi
fi

# 7. 磁盘空间检查
echo ""
echo "💾 磁盘空间检查..."
df -h ${MYSQL_BASE_DIR}

# 8. 提供修复建议
echo ""
echo "🔧 修复建议："
echo "   1. 如果权限问题：sudo chown -R 999:999 ${MYSQL_BASE_DIR}/data"
echo "   2. 如果SELinux问题：sudo chcon -Rt svirt_sandbox_file_t ${MYSQL_BASE_DIR}/data"
echo "   3. 如果磁盘空间不足：清理无用文件或扩展磁盘"
echo "   4. 如果挂载配置错误：重新创建容器并检查挂载参数"

echo ""
echo "🎯 诊断完成！"
```

#### 💾 数据恢复故障排除

```bash
# 检查数据卷挂载是否正确
docker exec mysql-container ls -la /var/lib/mysql/

# 检查数据目录权限
docker exec mysql-container ls -la /var/lib/mysql/

# 检查磁盘空间
df -h

# 检查内存使用
docker exec mysql-container free -h

# 检查 MySQL 配置是否正确
docker exec mysql-container mysqld --verbose --help | grep -A 1 "Default options"
```

## 📋 Docker Compose 完整配置示例

### 9.1 基础 Docker Compose 配置

```yaml
# docker-compose.yml - 基础配置
version: '3.8'

services:
  mysql:
    image: mysql:8.0.40
    container_name: mysql-production
    restart: unless-stopped
    
    environment:
      # 根密码配置
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-StrongRootPass123!}
      
      # 默认数据库和用户
      MYSQL_DATABASE: ${MYSQL_DATABASE:-production_db}
      MYSQL_USER: ${MYSQL_USER:-appuser}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-AppUserPass123!}
      
      # 时区配置
      TZ: Asia/Shanghai
      
    ports:
      - "${MYSQL_PORT:-3306}:3306"
    
    volumes:
      # 数据持久化 - 必须配置
      - ./data:/var/lib/mysql
      
      # 配置文件挂载
      - ./config:/etc/mysql/conf.d
      
      # 日志文件挂载
      - ./logs:/var/log/mysql
      
      # 时区同步
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    
    # 健康检查 - 确保服务可用性
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    
    # 资源限制 - 防止资源耗尽
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G

volumes:
  mysql-data:
    driver: local
```

### 9.2 环境变量文件

```bash
# .env 文件 - 环境变量配置
# MySQL 配置
MYSQL_ROOT_PASSWORD=YourSuperStrongRootPass123!
MYSQL_DATABASE=production_db
MYSQL_USER=appuser
MYSQL_PASSWORD=AppUserStrongPass123!
MYSQL_PORT=3306

# 时区配置
TZ=Asia/Shanghai

# 备份配置
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION=7
```

### 9.3 启动和管理命令

```bash
# 使用 Docker Compose 启动 MySQL
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志输出
docker-compose logs -f mysql

# 停止服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v

# 重新构建服务
docker-compose build

# 重启服务
docker-compose restart mysql

# 进入容器
docker-compose exec mysql bash

# 执行 MySQL 命令
docker-compose exec mysql mysql -uroot -p
```

## 🎯 最佳实践总结

### 10.1 生产环境配置清单

```bash
#!/bin/bash
# MySQL Docker 生产环境部署脚本

echo "开始部署 MySQL 生产环境..."

# 1. 创建目录结构
mkdir -p /opt/mysql/{data,config,logs,backup,scripts}
chown -R 999:999 /opt/mysql/data
chmod 750 /opt/mysql/data

# 2. 创建配置文件
cat > /opt/mysql/config/mysql.cnf << 'EOF'
[mysqld]
# 基础配置
server-id=1
port=3306
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# 内存配置 - 根据服务器内存调整
innodb_buffer_pool_size=4G
max_connections=1000

# 日志配置
log-error=/var/log/mysql/error.log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2

# 二进制日志
log-bin=mysql-bin
binlog-format=ROW
expire_logs_days=7

# 安全配置
skip-name-resolve
secure-file-priv=/var/lib/mysql-files
EOF

# 3. 创建环境变量
cat > /opt/mysql/.env << 'EOF'
MYSQL_ROOT_PASSWORD=YourSuperStrongRootPass123!
MYSQL_DATABASE=production_db
MYSQL_USER=appuser
MYSQL_PASSWORD=AppUserStrongPass123!
MYSQL_PORT=3306
TZ=Asia/Shanghai
EOF

# 4. 启动 MySQL 容器
docker run --name mysql-production \
  --env-file /opt/mysql/.env \
  -p 3306:3306 \
  -v /opt/mysql/data:/var/lib/mysql \
  -v /opt/mysql/config:/etc/mysql/conf.d \
  -v /opt/mysql/logs:/var/log/mysql \
  -v /etc/localtime:/etc/localtime:ro \
  --restart=unless-stopped \
  --memory=8g \
  --cpus=4 \
  -d mysql:8.0.40

echo "MySQL 生产环境部署完成！"
```

### 10.2 安全注意事项

1. **密码安全**：使用强密码，定期更换
2. **网络安全**：限制访问端口，配置防火墙
3. **数据安全**：定期备份，加密敏感数据
4. **访问控制**：最小权限原则，审计访问日志
5. **更新维护**：及时更新镜像，修复安全漏洞

### 10.3 性能优化要点

1. **内存配置**：根据服务器内存合理分配
2. **存储优化**：使用 SSD，优化 I/O 性能
3. **查询优化**：建立合适索引，优化慢查询
4. **连接池**：合理配置连接数，使用连接池
5. **监控告警**：实时监控，及时发现问题

---

**总结**：本指令集涵盖了 Docker MySQL 的完整部署流程，从基础安装到高级配置，从单机部署到主从复制，每个指令都配有详细的中文注释，是生产环境部署的完整参考指南。

## 🎯 快速使用指南

### 🚀 一键部署流程
```bash
# 1. 创建目录结构（使用完整脚本）
bash mysql-docker-setup.sh

# 2. 验证目录和权限
ls -la /opt/mysql/

# 3. 运行MySQL容器（使用推荐配置）
docker run --name mysql-production \
  --env-file /opt/mysql/.env \
  -p 3306:3306 \
  -v /opt/mysql/data:/var/lib/mysql \
  -v /opt/mysql/config:/etc/mysql/conf.d \
  -v /opt/mysql/logs:/var/log/mysql \
  -v /etc/localtime:/etc/localtime:ro \
  --restart=unless-stopped \
  --memory=4g \
  --cpus=2 \
  -d mysql:8.0.40

# 4. 验证挂载状态
bash mysql-volume-check.sh mysql-production

# 5. 测试连接
docker exec mysql-production mysql -uroot -p -e "SELECT 1;"
```

### 📋 常见问题快速排查表

| 问题现象 | 可能原因 | 快速解决方案 |
|---------|---------|-------------|
| 容器启动失败 | 权限错误 | `sudo chown -R 999:999 /opt/mysql/data` |
| 无法连接数据库 | 端口未开放 | 检查防火墙和端口映射 |
| 数据丢失 | 未正确挂载 | 验证挂载配置和权限 |
| 性能缓慢 | 内存配置不当 | 调整`innodb_buffer_pool_size` |
| 中文乱码 | 字符集配置错误 | 设置`character-set-server=utf8mb4` |

### 🔧 维护命令速查
```bash
# 查看容器状态
docker ps | grep mysql

# 查看日志
docker logs -f mysql-production

# 进入容器
docker exec -it mysql-production bash

# 备份数据库
docker exec mysql-production mysqldump -uroot -p --all-databases > backup.sql

# 重启容器
docker restart mysql-production

# 停止并删除容器
docker stop mysql-production && docker rm mysql-production
```