#!/bin/bash

# =============================================================================
# Docker 企业级数据库容器数据卷挂载目录创建脚本
# =============================================================================
# 脚本名称: docker-volumes-setup.sh
# 创建时间: $(date '+%Y-%m-%d %H:%M:%S')
# 适用系统: Ubuntu 20.04+ / CentOS 7+ / Debian 10+
# 功能描述: 自动创建 Docker 数据库容器的数据卷挂载目录结构
# 支持数据库: MySQL、Redis、MongoDB、PostgreSQL、Elasticsearch、Nginx 等
# =============================================================================

# 设置脚本执行参数，确保遇到错误时立即退出
set -euo pipefail

# =============================================================================
# 颜色定义 - 用于美化输出信息
# =============================================================================
# 定义各种颜色常量，使命令行输出更加直观
readonly RED='\033[0;31m'      # 红色 - 用于错误信息
readonly GREEN='\033[0;32m'    # 绿色 - 用于成功信息  
readonly YELLOW='\033[0;33m'  # 黄色 - 用于警告信息
readonly BLUE='\033[0;34m'    # 蓝色 - 用于信息提示
readonly PURPLE='\033[0;35m'  # 紫色 - 用于标题
readonly CYAN='\033[0;36m'    # 青色 - 用于命令输出
readonly WHITE='\033[0;37m'   # 白色 - 普通文本
readonly NC='\033[0m'         # 无颜色 - 重置颜色

# =============================================================================
# 全局变量定义
# =============================================================================
# 定义基础目录路径，这是企业级推荐的标准位置
readonly BASE_DIR="/opt/docker-volumes"                    # Docker 卷的基础目录
readonly BACKUP_BASE_DIR="/backup/docker-volumes"          # 备份数据的基础目录
readonly LOG_DIR="/var/log/docker-volumes"                # 日志文件目录

# 定义要创建的数据库服务列表
readonly SERVICES=("mysql" "redis" "mongodb" "postgres" "elasticsearch" "nginx")

# 定义每个服务的子目录结构
readonly SERVICE_SUBDIRS=("data" "config" "logs" "backup")  # 数据、配置、日志、备份

# 获取当前系统用户名和主要用户组
CURRENT_USER=$(whoami)                                     # 当前执行脚本的用户
CURRENT_GROUP=$(id -gn)                                   # 当前用户的主要用户组

# =============================================================================
# 工具函数定义
# =============================================================================

# 打印带颜色的信息函数
print_info() {
    # 输出蓝色信息文本
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    # 输出绿色成功文本
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    # 输出黄色警告文本
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    # 输出红色错误文本
    echo -e "${RED}[错误]${NC} $1"
}

print_title() {
    # 输出紫色标题文本，带有边框美化
    echo -e "\n${PURPLE}================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}================================================${NC}\n"
}

# =============================================================================
# 系统检查和依赖验证
# =============================================================================

check_system_requirements() {
    print_title "系统环境检查和依赖验证"
    
    # 检查当前用户是否具有 sudo 权限
    print_info "检查当前用户权限..."
    if ! sudo -n true 2>/dev/null; then
        print_warning "当前用户可能需要 sudo 权限来创建系统目录"
        print_info "脚本将尝试使用 sudo 执行需要特权的操作"
    fi
    
    # 检查 Docker 是否已安装
    print_info "检查 Docker 安装状态..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker 已安装，版本: $DOCKER_VERSION"
    else
        print_warning "Docker 未安装，建议先安装 Docker"
        print_info "Docker 安装命令: curl -fsSL https://get.docker.com | sh"
    fi
    
    # 检查磁盘空间是否充足
    print_info "检查磁盘空间..."
    AVAILABLE_SPACE=$(df -BG /opt | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$AVAILABLE_SPACE" -lt 5 ]; then
        print_warning "可用磁盘空间不足 5GB，建议清理空间或扩展磁盘"
    else
        print_success "磁盘空间充足: ${AVAILABLE_SPACE}GB 可用"
    fi
    
    # 检查系统类型和版本
    print_info "检查系统信息..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_success "系统: $NAME $VERSION"
    fi
}

# =============================================================================
# 创建基础目录结构
# =============================================================================

create_base_directories() {
    print_title "创建 Docker 卷基础目录结构"
    
    # 创建主要的 Docker 卷目录
    print_info "创建基础目录: $BASE_DIR"
    sudo mkdir -p "$BASE_DIR"
    
    # 创建备份目录
    print_info "创建备份目录: $BACKUP_BASE_DIR"
    sudo mkdir -p "$BACKUP_BASE_DIR"
    
    # 创建日志目录
    print_info "创建日志目录: $LOG_DIR"
    sudo mkdir -p "$LOG_DIR"
    
    # 设置基础目录权限
    print_info "设置基础目录权限..."
    sudo chown root:root "$BASE_DIR" "$BACKUP_BASE_DIR" "$LOG_DIR"
    sudo chmod 755 "$BASE_DIR" "$BACKUP_BASE_DIR" "$LOG_DIR"
    
    print_success "基础目录创建完成"
}

# =============================================================================
# 创建服务专用目录
# =============================================================================

create_service_directories() {
    local service=$1
    local service_dir="$BASE_DIR/$service"
    
    print_info "创建 $service 服务目录结构..."
    
    # 为每个服务创建子目录
    for subdir in "${SERVICE_SUBDIRS[@]}"; do
        local full_path="$service_dir/$subdir"
        sudo mkdir -p "$full_path"
        print_info "  创建目录: $full_path"
        
        # 根据不同子目录设置不同权限
        case $subdir in
            "data")
                # 数据目录：严格权限，仅所有者可读写
                sudo chmod 750 "$full_path"
                ;;
            "config")
                # 配置目录：允许读取，需要时可写入
                sudo chmod 755 "$full_path"
                ;;
            "logs")
                # 日志目录：允许读取，便于调试
                sudo chmod 755 "$full_path"
                ;;
            "backup")
                # 备份目录：允许读写，便于管理
                sudo chmod 755 "$full_path"
                ;;
        esac
    done
    
    # 设置服务目录的所有者和权限
    sudo chown -R root:root "$service_dir"
    sudo chmod 755 "$service_dir"
    
    print_success "$service 服务目录创建完成"
}

# =============================================================================
# 创建共享资源目录
# =============================================================================

create_shared_directories() {
    print_title "创建共享资源目录"
    
    local shared_dir="$BASE_DIR/shared"
    
    # 创建共享目录结构
    print_info "创建共享目录: $shared_dir"
    sudo mkdir -p "$shared_dir"/{ssl,certs,scripts,configs,templates}
    
    # 设置共享目录权限
    sudo chown root:root "$shared_dir"
    sudo chmod 755 "$shared_dir"
    
    # 为不同类型的共享资源设置专门权限
    sudo chmod 755 "$shared_dir/ssl"      # SSL 证书目录
    sudo chmod 755 "$shared_dir/certs"    # 证书目录
    sudo chmod 755 "$shared_dir/scripts"  # 脚本目录
    sudo chmod 755 "$shared_dir/configs"  # 配置文件目录
    sudo chmod 755 "$shared_dir/templates" # 模板目录
    
    # 创建示例文件
    create_example_files "$shared_dir"
    
    print_success "共享目录创建完成"
}

# =============================================================================
# 创建示例配置文件
# =============================================================================

create_example_files() {
    local shared_dir=$1
    
    print_info "创建示例配置文件..."
    
    # 创建 Docker 网络配置示例
    cat > "/tmp/docker-network-example.yml" << 'EOF'
# Docker 网络配置示例
# 使用方法: docker-compose -f docker-network-example.yml up -d

version: '3.8'

networks:
  database-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
  
  web-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.21.0.0/16
          gateway: 172.21.0.1
EOF

    # 创建备份脚本示例
    cat > "/tmp/backup-example.sh" << 'EOF'
#!/bin/bash
# Docker 卷备份脚本示例

BACKUP_DIR="/backup/docker-volumes/$(date +%Y%m%d)"
LOG_FILE="/var/log/docker-volumes/backup.log"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 记录备份开始时间
echo "[$(date)] 开始备份 Docker 卷..." >> "$LOG_FILE"

# 备份 MySQL 数据
tar -czf "$BACKUP_DIR/mysql-data.tar.gz" -C /opt/docker-volumes mysql/data 2>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    echo "[$(date)] MySQL 数据备份成功" >> "$LOG_FILE"
else
    echo "[$(date)] MySQL 数据备份失败" >> "$LOG_FILE"
fi

# 备份 Redis 数据
tar -czf "$BACKUP_DIR/redis-data.tar.gz" -C /opt/docker-volumes redis/data 2>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    echo "[$(date)] Redis 数据备份成功" >> "$LOG_FILE"
else
    echo "[$(date)] Redis 数据备份失败" >> "$LOG_FILE"
fi

# 清理 7 天前的备份
find /backup/docker-volumes -type d -mtime +7 -exec rm -rf {} \; 2>> "$LOG_FILE"

echo "[$(date)] 备份完成" >> "$LOG_FILE"
EOF

    # 移动示例文件到共享目录
    sudo mv "/tmp/docker-network-example.yml" "$shared_dir/templates/"
    sudo mv "/tmp/backup-example.sh" "$shared_dir/scripts/"
    
    # 设置脚本可执行权限
    sudo chmod +x "$shared_dir/scripts/backup-example.sh"
    
    print_success "示例文件创建完成"
}

# =============================================================================
# 创建日志轮转配置
# =============================================================================

setup_log_rotation() {
    print_title "配置日志轮转"
    
    # 创建日志轮转配置
    cat > "/tmp/docker-volumes" << 'EOF'
# Docker 卷日志轮转配置
/var/log/docker-volumes/*.log {
    daily                    # 每天轮转
    rotate 30               # 保留 30 个备份
    compress                # 压缩旧日志
    delaycompress           # 延迟压缩
    missingok               # 如果日志文件不存在，不报错
    notifempty              # 如果日志文件为空，不轮转
    create 644 root root    # 创建新日志文件的权限
}
EOF

    # 安装日志轮转配置
    sudo mv "/tmp/docker-volumes" "/etc/logrotate.d/docker-volumes"
    sudo chmod 644 "/etc/logrotate.d/docker-volumes"
    
    print_success "日志轮转配置完成"
}

# =============================================================================
# 创建系统服务监控脚本
# =============================================================================

create_monitoring_scripts() {
    print_title "创建监控和维护脚本"
    
    local scripts_dir="$BASE_DIR/shared/scripts"
    
    # 创建磁盘空间监控脚本
    cat > "/tmp/disk-monitor.sh" << 'EOF'
#!/bin/bash
# Docker 卷磁盘空间监控脚本

ALERT_THRESHOLD=80      # 警告阈值 80%
CRITICAL_THRESHOLD=90   # 严重阈值 90%
LOG_FILE="/var/log/docker-volumes/disk-monitor.log"

# 获取 Docker 卷目录使用情况
USAGE=$(df -h /opt/docker-volumes | awk 'NR==2 {print $5}' | sed 's/%//')

# 记录监控信息
echo "[$(date)] 磁盘使用率: ${USAGE}%" >> "$LOG_FILE"

# 判断是否超过阈值
if [ "$USAGE" -ge "$CRITICAL_THRESHOLD" ]; then
    echo "[$(date)] 严重警告: 磁盘使用率超过 ${CRITICAL_THRESHOLD}%！" >> "$LOG_FILE"
    # 这里可以添加邮件通知或其他告警机制
    # mail -s "磁盘空间严重不足" admin@example.com < /dev/null
elif [ "$USAGE" -ge "$ALERT_THRESHOLD" ]; then
    echo "[$(date)] 警告: 磁盘使用率超过 ${ALERT_THRESHOLD}%！" >> "$LOG_FILE"
fi

# 输出当前状态
echo "Docker 卷磁盘使用率: ${USAGE}%"
EOF

    # 创建权限检查脚本
    cat > "/tmp/permission-check.sh" << 'EOF'
#!/bin/bash
# Docker 卷权限检查脚本

BASE_DIR="/opt/docker-volumes"
LOG_FILE="/var/log/docker-volumes/permission-check.log"

echo "[$(date)] 开始检查 Docker 卷权限..." >> "$LOG_FILE"

# 检查基础目录权限
if [ "$(stat -c '%a' "$BASE_DIR")" = "755" ]; then
    echo "[$(date)] 基础目录权限正确" >> "$LOG_FILE"
else
    echo "[$(date)] 基础目录权限异常: $(stat -c '%a' "$BASE_DIR")" >> "$LOG_FILE"
fi

# 检查各服务目录
for service in mysql redis mongodb postgres elasticsearch nginx; do
    SERVICE_DIR="$BASE_DIR/$service"
    if [ -d "$SERVICE_DIR" ]; then
        DATA_PERM=$(stat -c '%a' "$SERVICE_DIR/data")
        CONFIG_PERM=$(stat -c '%a' "$SERVICE_DIR/config")
        
        if [ "$DATA_PERM" = "750" ]; then
            echo "[$(date)] $service 数据目录权限正确" >> "$LOG_FILE"
        else
            echo "[$(date)] $service 数据目录权限异常: $DATA_PERM" >> "$LOG_FILE"
        fi
        
        if [ "$CONFIG_PERM" = "755" ]; then
            echo "[$(date)] $service 配置目录权限正确" >> "$LOG_FILE"
        else
            echo "[$(date)] $service 配置目录权限异常: $CONFIG_PERM" >> "$LOG_FILE"
        fi
    fi
done

echo "[$(date)] 权限检查完成" >> "$LOG_FILE"
EOF

    # 移动脚本并设置权限
    sudo mv "/tmp/disk-monitor.sh" "$scripts_dir/"
    sudo mv "/tmp/permission-check.sh" "$scripts_dir/"
    
    # 设置脚本可执行权限
    sudo chmod +x "$scripts_dir/disk-monitor.sh"
    sudo chmod +x "$scripts_dir/permission-check.sh"
    
    # 创建 cron 任务（可选）
    cat > "/tmp/docker-volumes-cron" << 'EOF'
# Docker 卷监控任务
# 每 30 分钟检查一次磁盘空间
*/30 * * * * /opt/docker-volumes/shared/scripts/disk-monitor.sh

# 每天凌晨 2 点检查权限
0 2 * * * /opt/docker-volumes/shared/scripts/permission-check.sh

# 每天凌晨 3 点执行备份（需要配置备份脚本）
0 3 * * * /opt/docker-volumes/shared/scripts/backup-example.sh
EOF

    print_info "Cron 任务配置示例已创建: /tmp/docker-volumes-cron"
    print_success "监控脚本创建完成"
}

# =============================================================================
# 创建 Docker Compose 配置模板
# =============================================================================

create_docker_compose_templates() {
    print_title "创建 Docker Compose 配置模板"
    
    local templates_dir="$BASE_DIR/shared/templates"
    
    # 创建完整的 Docker Compose 配置
    cat > "$templates_dir/docker-compose-full.yml" << 'EOF'
# Docker 企业级数据库服务配置
# 包含 MySQL、Redis、MongoDB、PostgreSQL、Elasticsearch、Nginx

version: '3.8'

# 网络配置
networks:
  database-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
  
  web-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.21.0.0/16
          gateway: 172.21.0.1

# 数据卷配置
volumes:
  # 命名卷（可选使用）
  mysql-data:
  redis-data:
  mongodb-data:
  postgres-data:
  elasticsearch-data:

services:
  # MySQL 服务配置
  mysql:
    image: mysql:8.0
    container_name: mysql-production
    restart: unless-stopped
    ports:
      - "3306:3306"
    volumes:
      # 数据卷挂载 - 存储数据库文件
      - /opt/docker-volumes/mysql/data:/var/lib/mysql
      # 配置卷挂载 - 存储自定义配置文件
      - /opt/docker-volumes/mysql/config:/etc/mysql/conf.d
      # 日志卷挂载 - 存储数据库日志
      - /opt/docker-volumes/mysql/logs:/var/log/mysql
      # 备份卷挂载 - 存储备份文件（可选）
      - /opt/docker-volumes/mysql/backup:/backup
    environment:
      # MySQL root 用户密码 - 必须设置强密码
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-YourSecurePassword123!}
      # MySQL 数据库名 - 可选创建
      MYSQL_DATABASE: ${MYSQL_DATABASE:-appdb}
      # MySQL 用户名 - 可选创建
      MYSQL_USER: ${MYSQL_USER:-appuser}
      # MySQL 用户密码 - 必须设置强密码
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-UserSecurePassword123!}
      # 时区设置
      TZ: Asia/Shanghai
    networks:
      - database-network
    # 健康检查配置
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      interval: 30s
      start_period: 30s
    # 资源限制（根据服务器配置调整）
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M

  # Redis 服务配置
  redis:
    image: redis:7-alpine
    container_name: redis-production
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      # Redis 数据持久化目录
      - /opt/docker-volumes/redis/data:/data
      # Redis 配置文件目录
      - /opt/docker-volumes/redis/config:/usr/local/etc/redis
      # Redis 日志目录
      - /opt/docker-volumes/redis/logs:/var/log/redis
    command: redis-server /usr/local/etc/redis/redis.conf
    environment:
      TZ: Asia/Shanghai
    networks:
      - database-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.2'
          memory: 256M

  # MongoDB 服务配置
  mongodb:
    image: mongo:6
    container_name: mongodb-production
    restart: unless-stopped
    ports:
      - "27017:27017"
    volumes:
      # MongoDB 数据目录
      - /opt/docker-volumes/mongodb/data:/data/db
      # MongoDB 配置目录
      - /opt/docker-volumes/mongodb/config:/etc/mongo
      # MongoDB 日志目录
      - /opt/docker-volumes/mongodb/logs:/var/log/mongodb
    environment:
      # MongoDB root 用户名
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_ROOT_USERNAME:-admin}
      # MongoDB root 密码 - 必须设置强密码
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_ROOT_PASSWORD:-MongoSecurePassword123!}
      # MongoDB 数据库名 - 可选
      MONGO_INITDB_DATABASE: ${MONGO_DATABASE:-appdb}
      TZ: Asia/Shanghai
    networks:
      - database-network
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M

  # PostgreSQL 服务配置
  postgres:
    image: postgres:15-alpine
    container_name: postgres-production
    restart: unless-stopped
    ports:
      - "5432:5432"
    volumes:
      # PostgreSQL 数据目录
      - /opt/docker-volumes/postgres/data:/var/lib/postgresql/data
      # PostgreSQL 配置目录
      - /opt/docker-volumes/postgres/config:/etc/postgresql
      # PostgreSQL 日志目录
      - /opt/docker-volumes/postgres/logs:/var/log/postgresql
    environment:
      # PostgreSQL 数据库名
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
      # PostgreSQL 用户名
      POSTGRES_USER: ${POSTGRES_USER:-appuser}
      # PostgreSQL 密码 - 必须设置强密码
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-PostgresSecurePassword123!}
      TZ: Asia/Shanghai
    networks:
      - database-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-appuser} -d ${POSTGRES_DB:-appdb}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M

  # Elasticsearch 服务配置（可选）
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
    container_name: elasticsearch-production
    restart: unless-stopped
    ports:
      - "9200:9200"
      - "9300:9300"
    volumes:
      # Elasticsearch 数据目录
      - /opt/docker-volumes/elasticsearch/data:/usr/share/elasticsearch/data
      # Elasticsearch 配置目录
      - /opt/docker-volumes/elasticsearch/config:/usr/share/elasticsearch/config
      # Elasticsearch 日志目录
      - /opt/docker-volumes/elasticsearch/logs:/usr/share/elasticsearch/logs
    environment:
      # 单节点模式（开发环境）
      discovery.type: single-node
      # Elasticsearch 密码 - 必须设置强密码
      ELASTIC_PASSWORD: ${ELASTIC_PASSWORD:-ElasticSecurePassword123!}
      # 内存设置
      ES_JAVA_OPTS: "-Xms1g -Xmx1g"
      TZ: Asia/Shanghai
    networks:
      - database-network
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 3G
        reservations:
          cpus: '1.0'
          memory: 1G

  # Nginx 反向代理配置（可选）
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      # Nginx 配置目录
      - /opt/docker-volumes/nginx/config:/etc/nginx
      # Nginx 日志目录
      - /opt/docker-volumes/nginx/logs:/var/log/nginx
      # SSL 证书目录
      - /opt/docker-volumes/shared/ssl:/etc/ssl/certs
      # 网站内容目录
      - /opt/docker-volumes/nginx/html:/usr/share/nginx/html
    networks:
      - database-network
      - web-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/nginx-health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.1'
          memory: 128M
EOF

    # 创建简化的 Docker Compose 配置
    cat > "$templates_dir/docker-compose-simple.yml" << 'EOF'
# Docker 简化版数据库服务配置
# 仅包含 MySQL 和 Redis

version: '3.8'

networks:
  app-network:
    driver: bridge

services:
  mysql:
    image: mysql:8.0
    container_name: mysql-simple
    restart: unless-stopped
    ports:
      - "3306:3306"
    volumes:
      - /opt/docker-volumes/mysql/data:/var/lib/mysql
      - /opt/docker-volumes/mysql/config:/etc/mysql/conf.d
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword123
      MYSQL_DATABASE: appdb
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    container_name: redis-simple
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - /opt/docker-volumes/redis/data:/data
    command: redis-server --appendonly yes
    networks:
      - app-network
EOF

    print_success "Docker Compose 模板创建完成"
}

# =============================================================================
# 创建环境变量模板
# =============================================================================

create_environment_templates() {
    print_title "创建环境变量配置模板"
    
    local templates_dir="$BASE_DIR/shared/templates"
    
    # 创建环境变量模板
    cat > "$templates_dir/.env.example" << 'EOF'
# Docker 数据库服务环境变量配置模板
# 复制此文件为 .env 并根据实际情况修改

# MySQL 配置
MYSQL_ROOT_PASSWORD=YourSecureRootPassword123!
MYSQL_DATABASE=appdb
MYSQL_USER=appuser
MYSQL_PASSWORD=YourSecureUserPassword123!

# Redis 配置（无密码，如需密码请配置）
# REDIS_PASSWORD=YourRedisPassword123!

# MongoDB 配置
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=YourMongoRootPassword123!
MONGO_DATABASE=appdb

# PostgreSQL 配置
POSTGRES_DB=appdb
POSTGRES_USER=appuser
POSTGRES_PASSWORD=YourPostgresPassword123!

# Elasticsearch 配置
ELASTIC_PASSWORD=YourElasticPassword123!

# 通用配置
TZ=Asia/Shanghai

# 备份配置
BACKUP_RETENTION_DAYS=7
BACKUP_TIME=03:00

# 监控配置
DISK_ALERT_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90

# 网络配置（如需自定义）
# MYSQL_PORT=3306
# REDIS_PORT=6379
# MONGODB_PORT=27017
# POSTGRES_PORT=5432
# ELASTICSEARCH_PORT=9200
EOF

    # 创建密码生成脚本
    cat > "$templates_dir/generate-passwords.sh" << 'EOF'
#!/bin/bash
# 生成安全密码的脚本

echo "生成安全密码..."
echo "=================="
echo ""

# MySQL 密码
echo "MySQL Root 密码: $(openssl rand -base64 32)"
echo "MySQL User 密码: $(openssl rand -base64 32)"
echo ""

# MongoDB 密码
echo "MongoDB Root 密码: $(openssl rand -base64 32)"
echo ""

# PostgreSQL 密码
echo "PostgreSQL 密码: $(openssl rand -base64 32)"
echo ""

# Elasticsearch 密码
echo "Elasticsearch 密码: $(openssl rand -base64 32)"
echo ""

echo "=================="
echo "请将这些密码复制到 .env 文件中"
EOF

    chmod +x "$templates_dir/generate-passwords.sh"
    
    print_success "环境变量模板创建完成"
}

# =============================================================================
# 验证目录创建结果
# =============================================================================

verify_installation() {
    print_title "验证安装结果"
    
    local errors=0
    
    # 检查基础目录
    for dir in "$BASE_DIR" "$BACKUP_BASE_DIR" "$LOG_DIR"; do
        if [ -d "$dir" ]; then
            print_success "✓ 目录存在: $dir"
        else
            print_error "✗ 目录不存在: $dir"
            ((errors++))
        fi
    done
    
    # 检查服务目录
    for service in "${SERVICES[@]}"; do
        local service_dir="$BASE_DIR/$service"
        if [ -d "$service_dir" ]; then
            print_success "✓ 服务目录存在: $service"
            
            # 检查子目录
            for subdir in "${SERVICE_SUBDIRS[@]}"; do
                local subdir_path="$service_dir/$subdir"
                if [ -d "$subdir_path" ]; then
                    print_success "  ✓ 子目录存在: $service/$subdir"
                else
                    print_error "  ✗ 子目录不存在: $service/$subdir"
                    ((errors++))
                fi
            done
        else
            print_error "✗ 服务目录不存在: $service"
            ((errors++))
        fi
    done
    
    # 检查共享目录
    local shared_dir="$BASE_DIR/shared"
    if [ -d "$shared_dir" ]; then
        print_success "✓ 共享目录存在"
    else
        print_error "✗ 共享目录不存在"
        ((errors++))
    fi
    
    # 检查权限
    print_info "检查目录权限..."
    if [ "$(stat -c '%a' "$BASE_DIR")" = "755" ]; then
        print_success "✓ 基础目录权限正确"
    else
        print_error "✗ 基础目录权限错误"
        ((errors++))
    fi
    
    # 检查磁盘空间
    print_info "检查磁盘空间使用情况..."
    df -h "$BASE_DIR"
    
    if [ $errors -eq 0 ]; then
        print_success "✅ 所有检查通过！安装成功！"
        return 0
    else
        print_error "❌ 发现 $errors 个错误，请检查并修复"
        return 1
    fi
}

# =============================================================================
# 显示使用说明
# =============================================================================

show_usage_info() {
    print_title "使用说明和后续步骤"
    
    echo -e "${CYAN}📋 目录结构概览：${NC}"
    tree -L 3 "$BASE_DIR" 2>/dev/null || ls -la "$BASE_DIR"
    
    echo -e "\n${CYAN}🚀 快速开始命令：${NC}"
    echo -e "${YELLOW}# 查看目录结构：${NC}"
    echo -e "tree /opt/docker-volumes"
    echo -e ""
    echo -e "${YELLOW}# 启动 MySQL 容器示例：${NC}"
    echo -e "docker run -d \\"
    echo -e "  --name mysql-production \\"
    echo -e "  -p 3306:3306 \\"
    echo -e "  -v /opt/docker-volumes/mysql/data:/var/lib/mysql \\"
    echo -e "  -v /opt/docker-volumes/mysql/config:/etc/mysql/conf.d \\"
    echo -e "  -e MYSQL_ROOT_PASSWORD=yourpassword \\"
    echo -e "  mysql:8.0"
    echo -e ""
    echo -e "${YELLOW}# 使用 Docker Compose 启动所有服务：${NC}"
    echo -e "cd /opt/docker-volumes/shared/templates"
    echo -e "cp docker-compose-full.yml ../.."
    echo -e "cp .env.example ../../.env"
    echo -e "# 编辑 .env 文件设置密码"
    echo -e "nano ../../.env"
    echo -e "# 启动服务"
    echo -e "docker-compose -f ../../docker-compose-full.yml up -d"
    
    echo -e "\n${CYAN}📖 重要文件位置：${NC}"
    echo -e "• 配置模板: /opt/docker-volumes/shared/templates/"
    echo -e "• 环境变量: /opt/docker-volumes/shared/templates/.env.example"
    echo -e "• 监控脚本: /opt/docker-volumes/shared/scripts/"
    echo -e "• 备份脚本: /opt/docker-volumes/shared/scripts/backup-example.sh"
    echo -e "• 日志目录: /var/log/docker-volumes/"
    
    echo -e "\n${CYAN}🔧 维护命令：${NC}"
    echo -e "# 检查磁盘空间"
    echo -e "/opt/docker-volumes/shared/scripts/disk-monitor.sh"
    echo -e ""
    echo -e "# 检查权限"
    echo -e "/opt/docker-volumes/shared/scripts/permission-check.sh"
    echo -e ""
    echo -e "# 查看日志"
    echo -e "tail -f /var/log/docker-volumes/*.log"
    
    echo -e "\n${CYAN}⚠️ 安全提醒：${NC}"
    echo -e "• 请立即修改所有默认密码！"
    echo -e "• 配置防火墙规则，限制数据库端口访问"
    echo -e "• 设置定期备份计划"
    echo -e "• 监控磁盘空间使用情况"
    echo -e "• 定期更新 Docker 镜像"
}

# =============================================================================
# 主函数 - 脚本入口点
# =============================================================================

main() {
    # 显示脚本启动信息
    print_title "Docker 企业级数据库卷目录创建脚本"
    
    echo -e "${CYAN}脚本信息：${NC}"
    echo -e "• 创建时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "• 执行用户: $CURRENT_USER"
    echo -e "• 目标目录: $BASE_DIR"
    echo -e "• 支持服务: ${SERVICES[*]}"
    echo -e ""
    
    # 确认是否继续
    read -p "是否继续执行? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "用户取消操作，脚本退出"
        exit 0
    fi
    
    # 执行主要步骤
    check_system_requirements      # 系统检查和依赖验证
    create_base_directories          # 创建基础目录结构
    
    # 为每个服务创建专用目录
    for service in "${SERVICES[@]}"; do
        create_service_directories "$service"
    done
    
    create_shared_directories        # 创建共享资源目录
    setup_log_rotation              # 配置日志轮转
    create_monitoring_scripts       # 创建监控和维护脚本
    create_docker_compose_templates # 创建 Docker Compose 配置模板
    create_environment_templates    # 创建环境变量模板
    
    # 验证安装结果
    if verify_installation; then
        show_usage_info              # 显示使用说明
        print_success "🎉 所有任务完成！Docker 卷目录创建成功！"
        print_info "请查看上面的使用说明，开始部署您的 Docker 服务"
    else
        print_error "❌ 安装过程中出现问题，请查看错误信息并修复"
        exit 1
    fi
}

# =============================================================================
# 脚本执行入口
# =============================================================================

# 检查是否以 root 权限运行（推荐但不是必须）
if [ "$EUID" -eq 0 ]; then
    print_warning "检测到以 root 用户运行脚本"
    print_info "建议以普通用户身份运行，脚本会自动请求 sudo 权限"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# 执行主函数
main "$@"

# =============================================================================
# 脚本结束
# =============================================================================

echo -e "\n${GREEN}脚本执行完成！${NC}"
echo -e "${CYAN}感谢您的使用！${NC}"
echo -e "${CYAN}如有问题，请查看日志文件: /var/log/docker-volumes/setup.log${NC}"