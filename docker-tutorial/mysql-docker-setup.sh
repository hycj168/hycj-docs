#!/bin/bash

# MySQL Docker 企业级配置脚本
# 适用于 Ubuntu 24.04 和其他 Linux 发行版

set -e

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

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用 root 权限运行此脚本"
        exit 1
    fi
}

# 检查 Docker 安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! systemctl is_active --quiet docker; then
        log_error "Docker 服务未运行"
        exit 1
    fi
    
    log_success "Docker 已安装并运行"
}

# 检查 Docker Compose 安装
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        log_warning "Docker Compose 未安装，正在安装..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    log_success "Docker Compose 已安装"
}

# 创建项目结构
create_project_structure() {
    local project_dir="$1"
    
    log_info "创建 MySQL Docker 项目结构..."
    
    mkdir -p "${project_dir}"/{data,config,logs,backup,scripts,init}
    
    # 设置权限
    chown -R 999:999 "${project_dir}/data"  # MySQL 容器用户
    chmod 750 "${project_dir}/data"
    chmod 755 "${project_dir}"/{config,logs,backup,scripts,init}
    
    log_success "项目结构创建完成: ${project_dir}"
}

# 创建 MySQL 配置文件
create_mysql_config() {
    local config_dir="$1"
    
    log_info "创建 MySQL 配置文件..."
    
    cat > "${config_dir}/mysql.cnf" << 'EOF'
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
EOF

    log_success "MySQL 配置文件创建完成"
}

# 创建主服务器配置文件
create_master_config() {
    local config_dir="$1"
    
    log_info "创建主服务器配置文件..."
    
    cat > "${config_dir}/master.cnf" << 'EOF'
[mysqld]
server-id=1
log-bin=mysql-bin
binlog-format=ROW
expire_logs_days=7
max_binlog_size=100M
binlog-do-db=production_db
EOF

    log_success "主服务器配置文件创建完成"
}

# 创建从服务器配置文件
create_slave_config() {
    local config_dir="$1"
    
    log_info "创建从服务器配置文件..."
    
    cat > "${config_dir}/slave.cnf" << 'EOF'
[mysqld]
server-id=2
relay-log=mysql-relay-bin
log-slave-updates=1
read-only=1
EOF

    log_success "从服务器配置文件创建完成"
}

# 创建环境变量文件
create_env_file() {
    local project_dir="$1"
    
    log_info "创建环境变量文件..."
    
    cat > "${project_dir}/.env" << 'EOF'
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

# 主从复制配置
REPL_USER=repl
REPL_PASSWORD=ReplPass123!
EOF

    log_success "环境变量文件创建完成"
}

# 创建备份脚本
create_backup_script() {
    local scripts_dir="$1"
    
    log_info "创建备份脚本..."
    
    cat > "${scripts_dir}/backup.sh" << 'EOF'
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
EOF

    chmod +x "${scripts_dir}/backup.sh"
    log_success "备份脚本创建完成"
}

# 创建恢复脚本
create_restore_script() {
    local scripts_dir="$1"
    
    log_info "创建恢复脚本..."
    
    cat > "${scripts_dir}/restore.sh" << 'EOF'
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
EOF

    chmod +x "${scripts_dir}/restore.sh"
    log_success "恢复脚本创建完成"
}

# 创建健康检查脚本
create_healthcheck_script() {
    local scripts_dir="$1"
    
    log_info "创建健康检查脚本..."
    
    cat > "${scripts_dir}/healthcheck.sh" << 'EOF'
#!/bin/bash

# MySQL 健康检查
MYSQL_HOST="mysql"
MYSQL_USER="root"
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"

# 检查 MySQL 连接
if mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; then
    echo "MySQL 服务正常运行"
    exit 0
else
    echo "MySQL 服务异常！"
    exit 1
fi
EOF

    chmod +x "${scripts_dir}/healthcheck.sh"
    log_success "健康检查脚本创建完成"
}

# 创建初始化脚本
create_init_scripts() {
    local init_dir="$1"
    
    log_info "创建初始化脚本..."
    
    # 主服务器初始化
    cat > "${init_dir}/master-init.sql" << 'EOF'
-- 创建复制用户
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'ReplPass123!';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;

-- 显示主服务器状态
SHOW MASTER STATUS;
EOF

    # 从服务器初始化
    cat > "${init_dir}/slave-init.sql" << 'EOF'
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
EOF

    log_success "初始化脚本创建完成"
}

# 创建 Docker Compose 文件
create_docker_compose() {
    local project_dir="$1"
    
    log_info "创建 Docker Compose 配置文件..."
    
    # 复制已有的 docker-compose.yml 文件
    if [ -f "mysql-docker-compose.yml" ]; then
        cp "mysql-docker-compose.yml" "${project_dir}/docker-compose.yml"
        log_success "Docker Compose 文件已复制"
    else
        log_warning "未找到 docker-compose.yml 模板文件"
    fi
}

# 设置系统优化
setup_system_optimization() {
    log_info "设置系统优化..."
    
    # 设置内核参数
    cat >> /etc/sysctl.conf << 'EOF'

# MySQL 优化
vm.swappiness=1
vm.dirty_ratio=5
vm.dirty_background_ratio=2
fs.file-max=65536
net.core.somaxconn=65536
EOF

    sysctl -p
    
    # 设置文件描述符限制
    cat >> /etc/security/limits.conf << 'EOF'

# MySQL 限制
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF

    log_success "系统优化设置完成"
}

# 主函数
main() {
    local project_dir="/opt/mysql-docker"
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  MySQL Docker 企业级配置脚本${NC}"
    echo -e "${BLUE}  适用于 Ubuntu 24.04${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # 检查权限
    check_root
    
    # 检查 Docker
    check_docker
    
    # 检查 Docker Compose
    check_docker_compose
    
    # 创建项目结构
    create_project_structure "${project_dir}"
    
    # 创建配置文件
    create_mysql_config "${project_dir}/config"
    create_master_config "${project_dir}/config"
    create_slave_config "${project_dir}/config"
    
    # 创建环境变量文件
    create_env_file "${project_dir}"
    
    # 创建脚本
    create_backup_script "${project_dir}/scripts"
    create_restore_script "${project_dir}/scripts"
    create_healthcheck_script "${project_dir}/scripts"
    create_init_scripts "${project_dir}/init"
    
    # 创建 Docker Compose 文件
    create_docker_compose "${project_dir}"
    
    # 系统优化
    setup_system_optimization
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  MySQL Docker 配置完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "项目目录: ${BLUE}${project_dir}${NC}"
    echo -e "使用方法:"
    echo -e "  1. 进入项目目录: ${BLUE}cd ${project_dir}${NC}"
    echo -e "  2. 启动 MySQL: ${BLUE}docker-compose up -d${NC}"
    echo -e "  3. 查看状态: ${BLUE}docker-compose ps${NC}"
    echo -e "  4. 查看日志: ${BLUE}docker-compose logs -f${NC}"
    echo
    echo -e "${YELLOW}重要提示:${NC}"
    echo -e "  - 请修改 ${BLUE}.env${NC} 文件中的密码"
    echo -e "  - 请根据服务器内存调整配置"
    echo -e "  - 建议配置防火墙规则"
    echo -e "  - 建议配置 SSL 连接"
    echo
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi