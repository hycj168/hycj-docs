#!/bin/bash

# ==================== Osmanthus Music Backend Docker 部署脚本 ====================
# 项目名称: Osmanthus Music Backend
# 描述: 一键部署 Osmanthus Music Backend 到 Docker 容器（使用企业级数据卷）
# 版本: 1.0.0
# 维护者: Osmanthus Team
# =================================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 环境
check_docker() {
    log_info "检查 Docker 环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    # 检查 Docker 服务状态
    if ! systemctl is_active --quiet docker; then
        log_warning "Docker 服务未启动，正在启动..."
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    log_success "Docker 环境检查通过 ✓"
}

# 检查配置文件
check_config() {
    log_info "检查配置文件..."
    
    # 检查必需文件
    local required_files=(
        "docker-compose.yml"
        ".env"
        "Dockerfile"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "缺少必需文件: $file"
            exit 1
        fi
    done
    
    # 检查 .env 文件中的关键配置
    if grep -q "your_database_password" .env; then
        log_warning ".env 文件中包含默认密码，建议修改"
    fi
    
    if grep -q "YourVeryStrongSecretKeyHerePleaseChangeItInProduction" .env; then
        log_warning ".env 文件中包含默认 JWT 密钥，建议修改"
    fi
    
    log_success "配置文件检查通过 ✓"
}

# 检查企业级数据卷目录
check_enterprise_volumes() {
    log_info "检查企业级数据卷目录..."
    
    local enterprise_dirs=(
        "/opt/docker-volumes/mysql/data"
        "/opt/docker-volumes/redis/data"
        "/opt/docker-volumes/minio/data"
        "/opt/docker-volumes/backend/logs"
        "/opt/docker-volumes/backend/uploads"
        "/opt/docker-volumes/backend/temp"
    )
    
    for dir in "${enterprise_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_warning "企业级数据卷目录不存在，将创建: $dir"
            sudo mkdir -p "$dir"
            sudo chown -R 999:999 "$dir" 2>/dev/null || true
        fi
    done
    
    log_success "企业级数据卷目录检查通过 ✓"
}

# 创建本地配置目录（仅用于配置文件）
create_directories() {
    log_info "创建本地配置目录（仅用于配置文件）..."
    
    local directories=(
        "docker/mysql/conf.d"
        "docker/redis"
        "docker/minio/config"
        "docker/nginx/conf.d"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        log_info "创建目录: $dir"
    done
    
    log_success "本地配置目录创建完成 ✓"
}

# 创建配置文件
create_config_files() {
    log_info "创建配置文件..."
    
    # MySQL 配置文件
    cat > docker/mysql/conf.d/mysql.cnf << 'EOF'
[mysqld]
# 基础配置
default_authentication_plugin=mysql_native_password
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# 性能优化
max_connections=200
max_connect_errors=1000
wait_timeout=600
interactive_timeout=600

# InnoDB 优化
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT
innodb_file_per_table=1
innodb_open_files=400
innodb_io_capacity=2000
innodb_io_capacity_max=4000

# 查询缓存
query_cache_type=1
query_cache_size=32M
query_cache_limit=2M

# 日志配置
log_error=/var/log/mysql/error.log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2

# 时区配置
default_time_zone='+8:00'

[mysql]
default-character-set=utf8mb4

[client]
default-character-set=utf8mb4
EOF

    # Redis 配置文件
    cat > docker/redis/redis.conf << 'EOF'
# Redis 配置文件
bind 0.0.0.0
port 6379
protected-mode yes
timeout 300
tcp-keepalive 300
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile /var/log/redis/redis.log
databases 16

# 持久化配置
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# AOF 配置
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes

# 内存管理
maxmemory 512mb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# 网络配置
tcp-backlog 511
EOF

    # Nginx 配置文件
    cat > docker/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Gzip 配置
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    include /etc/nginx/conf.d/*.conf;
}
EOF

    cat > docker/nginx/conf.d/osmanthus.conf << 'EOF'
upstream osmanthus_backend {
    server osmanthus-backend:8080;
    keepalive 32;
}

server {
    listen 80;
    server_name localhost;
    
    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # API 代理
    location /api/ {
        proxy_pass http://osmanthus_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # 缓冲设置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
    
    # 管理端点
    location /actuator/ {
        proxy_pass http://osmanthus_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 限制访问IP（生产环境建议配置）
        # allow 192.168.1.0/24;
        # deny all;
    }
    
    # 静态资源
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # 缓存设置
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

    log_success "配置文件创建完成 ✓"
}

# 构建和启动服务
build_and_start() {
    log_info "构建和启动服务..."
    
    # 拉取镜像
    log_info "拉取 Docker 镜像..."
    docker-compose pull
    
    # 构建应用镜像
    log_info "构建 Osmanthus Backend 镜像..."
    docker-compose build --no-cache osmanthus-backend
    
    # 启动服务
    log_info "启动所有服务..."
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    check_services_status
    
    log_success "服务启动完成 ✓"
}

# 检查服务状态
check_services_status() {
    log_info "检查服务状态..."
    
    services=("osmanthus-mysql" "osmanthus-redis" "osmanthus-minio" "osmanthus-backend")
    
    for service in "${services[@]}"; do
        if docker-compose ps | grep -q "$service.*Up"; then
            log_success "$service 运行正常 ✓"
        else
            log_error "$service 未正常运行"
            docker-compose logs "$service" | tail -20
        fi
    done
}

# 显示访问信息
show_access_info() {
    log_info "服务访问信息："
    echo "========================================"
    echo "🌸 Osmanthus Music Backend 已部署完成！"
    echo "========================================"
    echo ""
    echo "📋 服务访问地址："
    echo "  • 应用服务: http://localhost:8080"
    echo "  • API 文档: http://localhost:8080/swagger-ui.html"
    echo "  • Knife4j 文档: http://localhost:8080/doc.html"
    echo "  • MinIO 控制台: http://localhost:9001"
    echo "  • MinIO API: http://localhost:9000"
    echo ""
    echo "📊 管理端点："
    echo "  • 健康检查: http://localhost:8080/actuator/health"
    echo "  • 应用信息: http://localhost:8080/actuator/info"
    echo "  • 指标监控: http://localhost:8080/actuator/metrics"
    echo ""
    echo "🔧 常用命令："
    echo "  • 查看日志: docker-compose logs -f [服务名]"
    echo "  • 停止服务: docker-compose down"
    echo "  • 重启服务: docker-compose restart [服务名]"
    echo "  • 进入容器: docker-compose exec [服务名] bash"
    echo ""
    echo "📁 企业级数据卷目录："
    echo "  • MySQL 数据:      /opt/docker-volumes/mysql/data"
    echo "  • Redis 数据:      /opt/docker-volumes/redis/data"
    echo "  • MinIO 数据:      /opt/docker-volumes/minio/data"
    echo "  • 应用日志:        /opt/docker-volumes/backend/logs"
    echo "  • 文件上传:        /opt/docker-volumes/backend/uploads"
    echo "  • 临时文件:        /opt/docker-volumes/backend/temp"
    echo ""
    echo "📁 本地配置文件目录："
    echo "  • MySQL 配置:      ./docker/mysql/conf.d/"
    echo "  • Redis 配置:      ./docker/redis/"
    echo "  • MinIO 配置:      ./docker/minio/config/"
    echo "  • Nginx 配置:      ./docker/nginx/conf.d/"
    echo ""
    echo "⚠️  安全提醒："
    echo "  • 请及时修改默认密码"
    echo "  • 生产环境建议启用 SSL"
    echo "  • 配置防火墙规则"
    echo "  • 定期备份企业级数据卷"
    echo "========================================"
}

# 主函数
main() {
    echo "🌸 Osmanthus Music Backend Docker 部署脚本（企业级数据卷版本）"
    echo "=============================================================="
    
    # 检查是否为 root 用户
    if [[ $EUID -eq 0 ]]; then
        log_warning "不建议使用 root 用户运行，建议使用普通用户并加入 docker 组"
    fi
    
    # 执行部署步骤
    check_docker
    check_config
    check_enterprise_volumes
    create_directories
    create_config_files
    build_and_start
    show_access_info
    
    log_success "部署完成！🎉"
}

# 错误处理
trap 'log_error "脚本执行失败，请检查错误信息"; exit 1' ERR

# 运行主函数
main "$@"