# Docker MySQL 企业级部署项目

一个完整的 Docker MySQL 企业级部署解决方案，包含从基础安装到高级配置的全套文档和脚本。

## 🎯 项目概述

本项目提供了一套完整的 Docker MySQL 企业级部署方案，涵盖：

- ✅ 基础 Docker MySQL 安装
- ✅ 企业级配置优化
- ✅ 主从复制配置
- ✅ 自动备份恢复
- ✅ 性能监控
- ✅ 故障排除指南
- ✅ 一键部署脚本

## 📁 文件结构

```
docker-tutorial/
├── Docker-MySQL-企业级安装教程.md    # 详细安装教程
├── mysql-docker-compose.yml          # 基础 Docker Compose 配置
├── mysql-replication-compose.yml     # 主从复制配置
├── mysql-docker-setup.sh            # 自动化安装脚本
├── mysql-backup-restore.sh          # 备份恢复管理脚本
├── README.md                          # 项目说明文档
└── LICENSE                           # MIT 许可证
```

## 🚀 快速开始

### 方法一：自动化安装（推荐）

```bash
# 下载并运行自动化安装脚本
wget https://raw.githubusercontent.com/your-repo/mysql-docker-setup.sh
chmod +x mysql-docker-setup.sh
sudo ./mysql-docker-setup.sh

# 进入项目目录
cd /opt/mysql-docker

# 启动 MySQL
docker-compose up -d
```

### 方法二：手动安装

```bash
# 1. 创建项目目录
mkdir -p /opt/mysql-docker/{data,config,logs,backup,scripts}
cd /opt/mysql-docker

# 2. 下载配置文件
wget https://raw.githubusercontent.com/your-repo/mysql-docker-compose.yml

# 3. 创建环境变量文件
cat > .env << EOF
MYSQL_ROOT_PASSWORD=YourStrongRootPass123!
MYSQL_DATABASE=myapp
MYSQL_USER=appuser
MYSQL_PASSWORD=AppUserPass123!
MYSQL_PORT=3306
TZ=Asia/Shanghai
EOF

# 4. 启动 MySQL
docker-compose up -d
```

## 📋 系统要求

- **操作系统**: Ubuntu 24.04 LTS (推荐) / CentOS 8+ / Debian 11+
- **Docker**: 20.10+
- **Docker Compose**: 1.29+
- **内存**: 最低 2GB (生产环境建议 8GB+)
- **磁盘空间**: 最低 10GB (生产环境建议 100GB+)
- **CPU**: 最低 1 核 (生产环境建议 2 核+)

## 🔧 配置选项

### 基础配置

在 `.env` 文件中配置以下参数：

```bash
# MySQL 配置
MYSQL_ROOT_PASSWORD=YourStrongRootPass123!    # 根密码（必须修改）
MYSQL_DATABASE=production_db                   # 默认数据库
MYSQL_USER=appuser                            # 应用用户
MYSQL_PASSWORD=AppUserPass123!                # 应用用户密码
MYSQL_PORT=3306                               # 端口
TZ=Asia/Shanghai                             # 时区
```

### 高级配置

编辑 `config/mysql.cnf` 文件进行高级配置：

- **内存优化**: 根据服务器内存调整 `innodb_buffer_pool_size`
- **连接数**: 调整 `max_connections` 参数
- **查询缓存**: 配置查询缓存大小和限制
- **日志配置**: 设置错误日志、慢查询日志等

## 🏗️ 部署架构

### 单实例部署

```
┌─────────────────┐
│   Application   │
└─────────┬───────┘
          │
┌─────────▼───────┐
│  MySQL Docker   │
│   Container     │
└─────────┬───────┘
          │
┌─────────▼───────┐
│   Data Volume   │
└─────────────────┘
```

### 主从复制部署

```
┌─────────────────┐     ┌─────────────────┐
│   Application   │     │   Application   │
└─────────┬───────┘     └─────────┬───────┘
          │                         │
┌─────────▼───────┐     ┌─────────▼───────┐
│  MySQL Master   │────▶│  MySQL Slave    │
│   Container     │     │   Container     │
└─────────┬───────┘     └─────────────────┘
          │
┌─────────▼───────┐
│   Data Volume   │
└─────────────────┘
```

## 📊 性能优化

### 内存配置建议

| 服务器内存 | innodb_buffer_pool_size | 查询缓存 |
|------------|------------------------|----------|
| 4GB        | 2GB                    | 128MB    |
| 8GB        | 5GB                    | 256MB    |
| 16GB       | 12GB                   | 512MB    |
| 32GB       | 24GB                   | 1GB      |

### 连接数配置

```ini
max_connections=1000          # 最大连接数
max_user_connections=800      # 用户最大连接数
thread_cache_size=100       # 线程缓存
```

## 💾 备份恢复

### 自动备份

```bash
# 设置定时备份
./mysql-backup-restore.sh setup-cron

# 手动执行全量备份
./mysql-backup-restore.sh full-backup

# 手动执行增量备份
./mysql-backup-restore.sh incremental-backup
```

### 数据恢复

```bash
# 列出所有备份
./mysql-backup-restore.sh list-backups

# 恢复指定备份
./mysql-backup-restore.sh restore full_backup_20251206_120000.sql.gz
```

### 备份策略

- **全量备份**: 每天凌晨 2:00 执行
- **增量备份**: 每 4 小时执行一次（可选）
- **保留策略**: 保留 7 天内的备份
- **压缩存储**: 备份文件自动压缩，节省空间

## 🔍 监控告警

### 健康检查

```bash
# 检查 MySQL 状态
docker-compose exec mysql mysqladmin ping

# 查看容器状态
docker-compose ps

# 查看运行日志
docker-compose logs -f mysql
```

### 性能监控

- **连接数监控**: 实时监控数据库连接数
- **查询性能**: 慢查询日志分析
- **磁盘使用**: 数据文件和日志文件监控
- **内存使用**: 缓冲池命中率监控

## 🚨 故障排除

### 常见问题

#### 容器无法启动

```bash
# 检查日志
docker-compose logs mysql

# 检查配置文件
docker-compose exec mysql mysqld --verbose --help

# 检查文件权限
ls -la /opt/mysql-docker/data/
```

#### 连接被拒绝

```bash
# 检查端口监听
netstat -tlnp | grep 3306

# 检查防火墙
ufw status

# 检查用户权限
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

## 🔒 安全建议

### 密码安全

- 使用强密码（包含大小写字母、数字、特殊字符）
- 定期更换密码
- 不要在代码中硬编码密码
- 使用环境变量或密钥管理服务

### 网络安全

- 限制 MySQL 端口访问（仅允许应用服务器访问）
- 配置防火墙规则
- 使用 SSL/TLS 加密连接
- 禁用 root 用户远程登录

### 数据安全

- 定期备份数据
- 加密备份文件
- 测试恢复流程
- 实施访问控制

## 📚 相关文档

- [详细安装教程](Docker-MySQL-企业级安装教程.md)
- [Docker 官方文档](https://docs.docker.com/)
- [MySQL 官方文档](https://dev.mysql.com/doc/)
- [Docker Hub MySQL](https://hub.docker.com/_/mysql)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 📄 许可证

本项目基于 MIT 许可证开源，详见 [LICENSE](LICENSE) 文件。

## ⚠️ 免责声明

本项目的脚本和配置仅供参考，在生产环境使用前请充分测试。使用本项目即表示您同意承担相关风险。

## 📞 支持

如有问题，请通过以下方式联系：

- 提交 Issue
- 发送邮件
- 社区讨论

---

**最后更新**: 2025年12月6日

**维护者**: Docker MySQL 企业级部署项目团队