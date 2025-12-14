#!/bin/bash

# ==================== Osmanthus Music Backend 企业级数据卷初始化脚本 ====================
# 描述: 在服务器上创建企业级 Docker 数据卷目录结构
# 版本: 1.0.0
# 维护者: Osmanthus Team
# =================================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "请使用 root 权限运行此脚本"
        exit 1
    fi
}

# 创建企业级数据卷目录
create_enterprise_volumes() {
    print_info "创建企业级 Docker 数据卷目录结构..."
    
    # 基础目录
    local base_dir="/opt/docker-volumes"
    
    # 创建 Osmanthus Music Backend 所需目录
    print_info "创建 MySQL 目录结构..."
    mkdir -p "${base_dir}/mysql"/{data,config,logs,backup}
    
    print_info "创建 Redis 目录结构..."
    mkdir -p "${base_dir}/redis"/{data,config,logs}
    
    print_info "创建 MinIO 目录结构..."
    mkdir -p "${base_dir}/minio"/{data,config,logs,backup}
    
    print_info "创建 Backend 目录结构..."
    mkdir -p "${base_dir}/backend"/{data,config,logs,backup,temp,uploads}
    
    print_info "创建 Nginx 目录结构..."
    mkdir -p "${base_dir}/nginx"/{config,conf.d,logs,ssl,html}
    
    print_info "创建共享目录..."
    mkdir -p "${base_dir}/shared"/{ssl,templates,configs,scripts}
    
    print_success "企业级数据卷目录创建完成 ✓"
}

# 设置目录权限
set_permissions() {
    print_info "设置目录权限..."
    
    local base_dir="/opt/docker-volumes"
    
    # MySQL 目录权限（MySQL 容器用户通常为 999）
    chown -R 999:999 "${base_dir}/mysql"
    chmod -R 755 "${base_dir}/mysql"
    
    # Redis 目录权限（Redis 容器用户通常为 999）
    chown -R 999:999 "${base_dir}/redis"
    chmod -R 755 "${base_dir}/redis"
    
    # MinIO 目录权限（MinIO 容器用户通常为 1000）
    chown -R 1000:1000 "${base_dir}/minio"
    chmod -R 755 "${base_dir}/minio"
    
    # Backend 目录权限（应用用户通常为 1000）
    chown -R 1000:1000 "${base_dir}/backend"
    chmod -R 755 "${base_dir}/backend"
    
    # Nginx 目录权限（Nginx 容器用户通常为 101）
    chown -R 101:101 "${base_dir}/nginx"
    chmod -R 755 "${base_dir}/nginx"
    
    # 共享目录权限
    chown -R root:root "${base_dir}/shared"
    chmod -R 755 "${base_dir}/shared"
    
    print_success "目录权限设置完成 ✓"
}

# 创建示例配置文件
create_sample_configs() {
    print_info "创建示例配置文件..."
    
    local base_dir="/opt/docker-volumes"
    
    # MySQL 配置示例
    cat > "${base_dir}/mysql/config/my.cnf" << 'EOF'
[mysqld]
# 基础配置
default_authentication_plugin=mysql_native_password
character_set_server=utf8mb4
collation_server=utf8mb4_unicode_ci
max_connections=200
max_connect_errors=1000
wait_timeout=600
interactive_timeout=600

# 性能优化
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT

# 日志配置
log_error=/var/log/mysql/error.log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2

# 时区配置
default_time_zone='+8:00'
EOF
    
    # Redis 配置示例
    cat > "${base_dir}/redis/config/redis.conf" << 'EOF'
# Redis 配置文件 - 企业级配置
bind 0.0.0.0
port 6379
timeout 300
tcp-keepalive 60
loglevel notice
databases 16

# 持久化配置
save 900 1
save 300 10
save 60 10000
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data
appendonly yes
appendfsync everysec

# 内存管理
maxmemory 512mb
maxmemory-policy allkeys-lru

# 安全设置
# requirepass your_redis_password
EOF
    
    # Nginx 配置示例
    cat > "${base_dir}/nginx/conf.d/default.conf" << 'EOF'
upstream backend {
    server osmanthus-backend:8080;
}

server {
    listen 80;
    server_name localhost;
    
    client_max_body_size 100M;
    
    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # 静态资源缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # 备份脚本
    cat > "${base_dir}/shared/scripts/backup.sh" << 'EOF'
#!/bin/bash
# 企业级数据卷备份脚本

BACKUP_DIR="/opt/backups/docker-volumes"
DATE=$(date +%Y%m%d_%H%M%S)
VOLUME_DIR="/opt/docker-volumes"

# 创建备份目录
mkdir -p "${BACKUP_DIR}"

# 备份所有数据卷
tar -czf "${BACKUP_DIR}/docker-volumes-${DATE}.tar.gz" -C "${VOLUME_DIR}" .

# 删除 7 天前的备份
find "${BACKUP_DIR}" -name "docker-volumes-*.tar.gz" -mtime +7 -delete

echo "备份完成: ${BACKUP_DIR}/docker-volumes-${DATE}.tar.gz"
EOF
    
    chmod +x "${base_dir}/shared/scripts/backup.sh"
    
    print_success "示例配置文件创建完成 ✓"
}

# 显示目录结构
show_directory_structure() {
    print_info "企业级数据卷目录结构："
    echo
    tree /opt/docker-volumes/ 2>/dev/null || ls -la /opt/docker-volumes/
    echo
    print_success "企业级 Docker 数据卷初始化完成！"
    echo
    echo "📋 使用说明："
    echo "1. 所有数据将持久化到 /opt/docker-volumes/ 目录"
    echo "2. 配置文件位于各服务的 config 子目录"
    echo "3. 日志文件位于各服务的 logs 子目录"
    echo "4. 备份文件位于各服务的 backup 子目录"
    echo "5. 使用 /opt/docker-volumes/shared/scripts/backup.sh 进行数据备份"
    echo
    echo "🔧 下一步："
    echo "1. 根据需要修改配置文件"
    echo "2. 运行 Osmanthus Music Backend 部署脚本"
    echo "3. 配置定期备份任务"
}

# 主函数
main() {
    print_info "开始初始化企业级 Docker 数据卷..."
    
    check_root
    create_enterprise_volumes
    set_permissions
    create_sample_configs
    show_directory_structure
}

# 如果脚本被直接执行，运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi