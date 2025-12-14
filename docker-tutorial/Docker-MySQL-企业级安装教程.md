# Docker 安装 MySQL 企业级完整教程

## 概述

本教程提供从基础到高级的 Docker MySQL 安装配置指南，涵盖企业级部署、性能优化、高可用配置、备份恢复等完整解决方案。

## 目录

1. [基础安装](#基础安装)
2. [企业级配置](#企业级配置)
3. [高级配置](#高级配置)
4. [高可用部署](#高可用部署)
5. [性能优化](#性能优化)
6. [备份恢复](#备份恢复)
7. [监控告警](#监控告警)
8. [故障排除](#故障排除)

## 基础安装

### 1. 环境要求

- Docker 20.10+
- Docker Compose 1.29+
- 最低 2GB RAM（生产环境建议 8GB+）
- 最低 10GB 磁盘空间（生产环境建议 100GB+）

### 2. 拉取 MySQL 镜像

```bash
# 拉取最新版本
docker pull mysql:latest

# 拉取指定版本（推荐用于生产环境）
docker pull mysql:8.0.40

# 查看可用版本
docker search mysql --filter "is-official=true"
```

### 3. 基础容器运行

```bash
# 简单运行（不推荐用于生产）
docker run --name mysql-basic \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -p 3306:3306 \
  -d mysql:latest

# 带数据持久化的运行
docker run --name mysql-production \
  -e MYSQL_ROOT_PASSWORD=yourpassword \
  -e MYSQL_DATABASE=myapp \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=apppassword \
  -p 3306:3306 \
  -v mysql-data:/var/lib/mysql \
  -v mysql-config:/etc/mysql/conf.d \
  --restart=unless-stopped \
  -d mysql:latest
```

## 企业级配置

### 1. 目录结构规划

```bash
# 创建项目目录
mkdir -p /opt/mysql-docker/{data,config,logs,backup,scripts}
cd /opt/mysql-docker

# 设置权限
sudo chown -R 999:999 data/  # MySQL容器用户ID
sudo chmod 750 data/
```

### 2. 企业级配置文件

创建 `config/mysql.cnf`：

```ini
[mysqld]
# 基础配置
server-id=1
port=3306
socket=/var/run/mysqld/mysqld.sock
pid-file=/var/run/mysqld/mysqld.pid
basedir=/usr
datadir=/var/lib/mysql
tmpdir=/tmp

# 字符集配置
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
init_connect='SET NAMES utf8mb4'

# 连接配置
max_connections=1000
max_user_connections=800
max_connect_errors=1000
wait_timeout=600
interactive_timeout=600

# 内存配置（根据服务器内存调整）
innodb_buffer_pool_size=2G
innodb_log_buffer_size=64M
innodb_log_file_size=256M
query_cache_size=128M
query_cache_limit=2M

# InnoDB配置
innodb_file_per_table=1
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT
innodb_io_capacity=2000

# 日志配置
log-error=/var/log/mysql/error.log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2
log_queries_not_using_indexes=1

# 二进制日志（用于主从复制）
log-bin=mysql-bin
binlog-format=ROW
expire_logs_days=7
max_binlog_size=100M

# 安全配置
skip-symbolic-links
skip-name-resolve
secure-file-priv=/var/lib/mysql-files

[mysql]
default-character-set=utf8mb4

[client]
default-character-set=utf8mb4
port=3306
socket=/var/run/mysqld/mysqld.sock
```

### 3. Docker Compose 企业级配置

创建 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0.40
    container_name: mysql-production
    restart: unless-stopped
    
    environment:
      # 根密码（必须设置）
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-StrongRootPass123!}
      
      # 数据库配置
      MYSQL_DATABASE: ${MYSQL_DATABASE:-myapp}
      MYSQL_USER: ${MYSQL_USER:-appuser}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-AppPass123!}
      
      # 时区配置
      TZ: Asia/Shanghai
      
      # 内存配置（根据服务器调整）
      MYSQL_MEMORY_LIMIT: 4G
      
    ports:
      - "${MYSQL_PORT:-3306}:3306"
    
    volumes:
      # 数据持久化
      - ./data:/var/lib/mysql
      
      # 配置文件
      - ./config/mysql.cnf:/etc/mysql/conf.d/mysql.cnf:ro
      
      # 日志文件
      - ./logs:/var/log/mysql
      
      # 初始化脚本
      - ./scripts/init:/docker-entrypoint-initdb.d:ro
      
      # 时区配置
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    
    command: 
      - --default-authentication-plugin=mysql_native_password
      - --sql-mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION
      - --max-connections=1000
      - --innodb-buffer-pool-size=2G
    
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
    
    networks:
      - mysql-network

  # MySQL 备份服务
  mysql-backup:
    image: mysql:8.0.40
    container_name: mysql-backup
    restart: unless-stopped
    
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-StrongRootPass123!}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-myapp}
      BACKUP_SCHEDULE: "0 2 * * *"  # 每天凌晨2点备份
      BACKUP_RETENTION: 7
      
    volumes:
      - ./backup:/backup
      - ./scripts/backup.sh:/backup.sh:ro
      - ./data:/var/lib/mysql:ro
    
    depends_on:
      - mysql
    
    command: |
      bash -c '
        echo "0 2 * * * /backup.sh" | crontab - &&
        cron -f
      '
    
    networks:
      - mysql-network

networks:
  mysql-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  mysql-data:
    driver: local
  mysql-logs:
    driver: local
  mysql-backup:
    driver: local
```

### 4. 环境变量配置

创建 `.env` 文件：

```bash
# MySQL 配置
MYSQL_ROOT_PASSWORD=YourSuperStrongRootPass123!
MYSQL_DATABASE=production_db
MYSQL_USER=appuser
MYSQL_PASSWORD=AppUserStrongPass123!
MYSQL_PORT=3306

# 备份配置
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION=7

# 时区配置
TZ=Asia/Shanghai
```

## 高级配置

### 1. 主从复制配置

#### 主服务器配置

创建 `config/master.cnf`：

```ini
[mysqld]
server-id=1
log-bin=mysql-bin
binlog-format=ROW
expire_logs_days=7
max_binlog_size=100M
binlog-do-db=production_db
```

#### 从服务器配置

创建 `config/slave.cnf`：

```ini
[mysqld]
server-id=2
relay-log=mysql-relay-bin
log-slave-updates=1
read-only=1
```

#### Docker Compose 主从配置

创建 `docker-compose-replication.yml`：

```yaml
version: '3.8'

services:
  mysql-master:
    image: mysql:8.0.40
    container_name: mysql-master
    restart: unless-stopped
    
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      
    ports:
      - "3306:3306"
    
    volumes:
      - ./master-data:/var/lib/mysql
      - ./config/master.cnf:/etc/mysql/conf.d/master.cnf:ro
      - ./logs/master:/var/log/mysql
      - ./scripts/master-init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    
    networks:
      - mysql-replication

  mysql-slave:
    image: mysql:8.0.40
    container_name: mysql-slave
    restart: unless-stopped
    
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      
    ports:
      - "3307:3306"
    
    volumes:
      - ./slave-data:/var/lib/mysql
      - ./config/slave.cnf:/etc/mysql/conf.d/slave.cnf:ro
      - ./logs/slave:/var/log/mysql
      - ./scripts/slave-init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    
    depends_on:
      - mysql-master
    
    networks:
      - mysql-replication

networks:
  mysql-replication:
    driver: bridge
```

### 2. 初始化脚本

创建 `scripts/master-init.sql`：

```sql
-- 创建复制用户
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'ReplPass123!';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;

-- 显示主服务器状态
SHOW MASTER STATUS;
```

创建 `scripts/slave-init.sql`：

```sql
-- 配置从服务器
CHANGE MASTER TO
  MASTER_HOST='mysql-master',
  MASTER_USER='repl',
  MASTER_PASSWORD='ReplPass123!',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=0;

-- 启动从服务器复制
START SLAVE;

-- 检查从服务器状态
SHOW SLAVE STATUS\G
```

## 性能优化

### 1. 内存优化配置

根据服务器内存大小调整配置：

```ini
# 8GB 内存服务器
innodb_buffer_pool_size=5G
innodb_log_buffer_size=128M
query_cache_size=256M

# 16GB 内存服务器
innodb_buffer_pool_size=12G
innodb_log_buffer_size=256M
query_cache_size=512M

# 32GB 内存服务器
innodb_buffer_pool_size=24G
innodb_log_buffer_size=512M
query_cache_size=1G
```

### 2. 连接池优化

```ini
# 连接配置
max_connections=2000
max_user_connections=1500
max_connect_errors=10000

# 线程池
thead_cache_size=100
thread_pool_size=16
```

### 3. 查询优化

```ini
# 查询缓存
query_cache_type=1
query_cache_size=256M
query_cache_limit=4M

# 临时表
tmp_table_size=256M
max_heap_table_size=256M

# 排序和连接
sort_buffer_size=4M
join_buffer_size=4M
read_buffer_size=2M
read_rnd_buffer_size=8M
```

## 备份恢复

### 1. 自动备份脚本

创建 `scripts/backup.sh`：

```bash
#!/bin/bash

# 配置变量
MYSQL_HOST="mysql"
MYSQL_USER="root"
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# 创建备份目录
mkdir -p "${BACKUP_DIR}"

# 备份所有数据库
echo "开始备份所有数据库..."
mysqldump -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
  --all-databases \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --hex-blob \
  --master-data=2 \
  > "${BACKUP_DIR}/all_databases_${DATE}.sql"

# 压缩备份文件
gzip "${BACKUP_DIR}/all_databases_${DATE}.sql"

# 删除过期备份
echo "清理过期备份文件..."
find "${BACKUP_DIR}" -name "*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete

echo "备份完成: all_databases_${DATE}.sql.gz"
```

### 2. 恢复脚本

创建 `scripts/restore.sh`：

```bash
#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法: $0 <备份文件路径>"
    exit 1
fi

BACKUP_FILE="$1"
MYSQL_HOST="mysql"
MYSQL_USER="root"
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"

# 检查备份文件是否存在
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "错误: 备份文件不存在: ${BACKUP_FILE}"
    exit 1
fi

# 解压备份文件（如果是压缩的）
if [[ "${BACKUP_FILE}" == *.gz ]]; then
    echo "解压备份文件..."
    gunzip -c "${BACKUP_FILE}" > /tmp/restore.sql
    RESTORE_FILE="/tmp/restore.sql"
else
    RESTORE_FILE="${BACKUP_FILE}"
fi

# 执行恢复
echo "开始恢复数据库..."
mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" < "${RESTORE_FILE}"

# 清理临时文件
if [[ "${BACKUP_FILE}" == *.gz ]]; then
    rm -f /tmp/restore.sql
fi

echo "数据库恢复完成！"
```

### 3. 定时备份配置

创建 `scripts/setup-cron.sh`：

```bash
#!/bin/bash

# 设置定时备份任务
echo "设置 MySQL 自动备份任务..."

# 添加定时任务
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/mysql-docker/scripts/backup.sh >> /var/log/mysql/backup.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * * find /opt/mysql-docker/backup -name '*.sql.gz' -mtime +7 -delete") | crontab -

echo "定时备份任务设置完成！"
echo "备份时间: 每天凌晨 2:00"
echo "备份保留: 7天"
```

## 监控告警

### 1. 健康检查脚本

创建 `scripts/healthcheck.sh`：

```bash
#!/bin/bash

# MySQL 健康检查
MYSQL_HOST="localhost"
MYSQL_USER="root"
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"

# 检查 MySQL 连接
if mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; then
    echo "MySQL 服务正常运行"
    exit 0
else
    echo "MySQL 服务异常！"
    # 这里可以添加告警逻辑，如发送邮件、短信等
    exit 1
fi
```

### 2. 性能监控脚本

创建 `scripts/monitor.sh`：

```bash
#!/bin/bash

# MySQL 性能监控
MYSQL_HOST="localhost"
MYSQL_USER="root"
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"
LOG_FILE="/var/log/mysql/performance.log"

# 获取性能指标
echo "=== MySQL 性能监控 $(date) ===" >> "${LOG_FILE}"

# 连接数
connections=$(mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW STATUS LIKE 'Threads_connected';" | tail -1 | awk '{print $2}')
echo "当前连接数: ${connections}" >> "${LOG_FILE}"

# 查询缓存命中率
qcache_hits=$(mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW STATUS LIKE 'Qcache_hits';" | tail -1 | awk '{print $2}')
qcache_inserts=$(mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW STATUS LIKE 'Qcache_inserts';" | tail -1 | awk '{print $2}')
if [ "${qcache_hits}" -gt 0 ] && [ "${qcache_inserts}" -gt 0 ]; then
    hit_rate=$(echo "scale=2; ${qcache_hits} / (${qcache_hits} + ${qcache_inserts}) * 100" | bc)
    echo "查询缓存命中率: ${hit_rate}%" >> "${LOG_FILE}"
fi

# InnoDB 缓冲池命中率
innodb_reads=$(mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW STATUS LIKE 'Innodb_buffer_pool_reads';" | tail -1 | awk '{print $2}')
innodb_read_requests=$(mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW STATUS LIKE 'Innodb_buffer_pool_read_requests';" | tail -1 | awk '{print $2}')
if [ "${innodb_reads}" -gt 0 ] && [ "${innodb_read_requests}" -gt 0 ]; then
    hit_rate=$(echo "scale=2; (${innodb_read_requests} - ${innodb_reads}) / ${innodb_read_requests} * 100" | bc)
    echo "InnoDB 缓冲池命中率: ${hit_rate}%" >> "${LOG_FILE}"
fi

echo "=======================================" >> "${LOG_FILE}"
```

## 故障排除

### 1. 常见问题

#### 容器无法启动

```bash
# 查看容器日志
docker logs mysql-production

# 检查配置文件语法
docker exec mysql-production mysqld --verbose --help

# 检查文件权限
ls -la /opt/mysql-docker/data/
```

#### 连接被拒绝

```bash
# 检查端口监听
netstat -tlnp | grep 3306

# 检查防火墙
ufw status

# 检查 MySQL 用户权限
mysql -u root -p -e "SELECT host, user FROM mysql.user;"
```

#### 性能问题

```bash
# 查看慢查询
 tail -f /opt/mysql-docker/logs/slow.log

# 检查当前连接
mysql -u root -p -e "SHOW PROCESSLIST;"

# 查看 InnoDB 状态
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G"
```

### 2. 日志分析

```bash
# 查看错误日志
tail -f /opt/mysql-docker/logs/error.log

# 查看慢查询日志
tail -f /opt/mysql-docker/logs/slow.log

# Docker 容器日志
docker logs -f mysql-production
```

## 最佳实践

### 1. 安全建议

- 使用强密码
- 限制网络访问
- 定期更新镜像
- 启用 SSL 连接
- 定期备份数据
- 监控异常访问

### 2. 性能建议

- 合理配置内存参数
- 使用 SSD 存储
- 优化查询语句
- 建立合适索引
- 定期维护表

### 3. 运维建议

- 自动化部署
- 监控告警
- 定期备份
- 文档记录
- 灾备演练

## 总结

本教程提供了完整的 Docker MySQL 企业级部署方案，从基础安装到高级配置，从性能优化到故障排除，涵盖了生产环境所需的所有方面。通过合理的配置和管理，可以构建高可用、高性能、安全的 MySQL 数据库服务。

## 相关资源

- [MySQL 官方文档](https://dev.mysql.com/doc/)
- [Docker Hub MySQL](https://hub.docker.com/_/mysql)
- [MySQL 性能优化指南](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [Docker 最佳实践](https://docs.docker.com/develop/dev-best-practices/)

---

*最后更新：2025年12月6日*