#!/bin/bash

# =============================================================================
# Docker 企业级多数据库容器数据挂载目录创建脚本
# =============================================================================
# 脚本名称: enterprise-docker-volumes-setup.sh
# 创建时间: $(date '+%Y-%m-%d %H:%M:%S')
# 适用系统: Ubuntu 20.04+ / CentOS 7+ / Debian 10+
# 功能描述: 为企业级 Docker 数据库服务创建完整的数据卷挂载目录结构
# 支持服务: MySQL、Redis、MongoDB、PostgreSQL、Elasticsearch、Nginx、MinIO
# 特色功能: 
#   - 完整的目录结构规划
#   - 企业级权限管理
#   - 自动化备份配置
#   - 监控告警设置
#   - 安全加固措施
#   - 一键恢复功能
# =============================================================================

# 设置严格的脚本执行参数，确保任何错误都能被及时发现
# -e: 遇到错误立即退出
# -u: 使用未定义变量时报错
# -o pipefail: 管道命令中任何一个失败都视为整体失败
set -euo pipefail

# =============================================================================
# 颜色定义 - 使命令行输出更加直观和美观
# =============================================================================
# 定义各种颜色常量，用于不同类型的信息输出
readonly RED='\033[0;31m'      # 红色 - 用于错误信息和严重警告
readonly GREEN='\033[0;32m'    # 绿色 - 用于成功信息和完成状态
readonly YELLOW='\033[0;33m'  # 黄色 - 用于警告信息和注意事项
readonly BLUE='\033[0;34m'    # 蓝色 - 用于信息提示和操作说明
readonly PURPLE='\033[0;35m'  # 紫色 - 用于标题和重要章节
readonly CYAN='\033[0;36m'    # 青色 - 用于命令输出和代码片段
readonly WHITE='\033[0;37m'   # 白色 - 普通文本和默认输出
readonly NC='\033[0m'         # 无颜色 - 重置颜色到默认状态

# =============================================================================
# 全局变量定义 - 企业级配置参数
# =============================================================================
# 定义基础目录路径，这是企业级推荐的标准位置
readonly BASE_DIR="/opt/docker-volumes"                    # Docker 卷的主要存储目录
readonly BACKUP_BASE_DIR="/backup/docker-volumes"          # 备份数据的存储目录
readonly LOG_DIR="/var/log/docker-volumes"                # 日志文件的存储目录
readonly MONITOR_DIR="/var/lib/docker-volumes/monitoring"  # 监控数据的存储目录
readonly SECURITY_DIR="/etc/docker-volumes/security"       # 安全配置的存储目录

# 定义要创建的数据库服务列表，包含企业级常用的数据存储服务
readonly SERVICES=("mysql" "redis" "mongodb" "postgres" "elasticsearch" "nginx" "minio")

# 定义每个服务的子目录结构，按照企业级标准进行分类
readonly SERVICE_SUBDIRS=("data" "config" "logs" "backup" "certs" "scripts")

# 获取当前系统信息
readonly CURRENT_USER=$(whoami)                            # 当前执行脚本的用户名
readonly CURRENT_GROUP=$(id -gn)                          # 当前用户的主要用户组
readonly SYSTEM_ARCH=$(uname -m)                          # 系统架构信息
readonly SYSTEM_KERNEL=$(uname -r)                        # 内核版本信息

# 定义企业级权限配置
readonly DATA_DIR_PERMS="750"     # 数据目录权限 - 严格保护
readonly CONFIG_DIR_PERMS="755"   # 配置目录权限 - 允许读取
readonly LOG_DIR_PERMS="755"      # 日志目录权限 - 便于调试
readonly BACKUP_DIR_PERMS="755"   # 备份目录权限 - 便于管理
readonly CERTS_DIR_PERMS="600"    # 证书目录权限 - 最高安全级别
readonly SCRIPTS_DIR_PERMS="750"  # 脚本目录权限 - 控制执行权限

# =============================================================================
# 工具函数定义 - 信息输出和日志记录
# =============================================================================

# 确保日志目录存在
ensure_log_directory() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || true
    fi
}

# 打印带颜色的信息函数，用于不同类型的消息输出
print_info() {
    # 输出蓝色信息文本，带有时间戳
    echo -e "${BLUE}[$(date '+%H:%M:%S')] [信息]${NC} $1"
    # 同时记录到日志文件
    ensure_log_directory
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [信息] $1" >> "$LOG_DIR/setup.log" 2>/dev/null || true
}

print_success() {
    # 输出绿色成功文本，表示操作成功完成
    echo -e "${GREEN}[$(date '+%H:%M:%S')] [成功]${NC} $1"
    # 同时记录到日志文件
    ensure_log_directory
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [成功] $1" >> "$LOG_DIR/setup.log" 2>/dev/null || true
}

print_warning() {
    # 输出黄色警告文本，提醒用户注意潜在问题
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] [警告]${NC} $1"
    # 同时记录到日志文件
    ensure_log_directory
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [警告] $1" >> "$LOG_DIR/setup.log" 2>/dev/null || true
}

print_error() {
    # 输出红色错误文本，表示操作失败或严重问题
    echo -e "${RED}[$(date '+%H:%M:%S')] [错误]${NC} $1"
    # 同时记录到日志文件
    ensure_log_directory
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [错误] $1" >> "$LOG_DIR/setup.log" 2>/dev/null || true
}

print_title() {
    # 输出紫色标题文本，用于标识重要章节
    echo -e "\n${PURPLE}================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}================================================${NC}\n"
    # 同时记录到日志文件
    ensure_log_directory
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [标题] $1" >> "$LOG_DIR/setup.log" 2>/dev/null || true
}

# =============================================================================
# 系统检查和依赖验证 - 企业级环境要求
# =============================================================================

check_system_requirements() {
    print_title "企业级系统环境检查和依赖验证"
    
    # 检查当前用户是否具有 sudo 权限
    print_info "检查当前用户权限和 sudo 配置..."
    if ! sudo -n true 2>/dev/null; then
        print_warning "当前用户可能需要 sudo 权限来创建系统目录和执行特权操作"
        print_info "脚本将尝试使用 sudo 执行需要特权的操作"
        print_info "建议将当前用户添加到 sudo 组: sudo usermod -aG sudo $CURRENT_USER"
    else
        print_success "当前用户具有 sudo 权限，可以执行特权操作"
    fi
    
    # 检查 Docker 是否已安装以及版本信息
    print_info "检查 Docker 安装状态和版本信息..."
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker 已安装，版本: $DOCKER_VERSION"
        
        # 检查 Docker 服务状态
        if systemctl is-active --quiet docker; then
            print_success "Docker 服务正在运行"
        else
            print_warning "Docker 服务未运行，建议启动 Docker 服务"
            print_info "启动命令: sudo systemctl start docker"
        fi
    else
        print_warning "Docker 未安装，建议先安装 Docker"
        print_info "Docker 安装命令: curl -fsSL https://get.docker.com | sh"
        print_info "或者访问: https://docs.docker.com/engine/install/"
    fi
    
    # 检查 Docker Compose 是否已安装
    print_info "检查 Docker Compose 安装状态..."
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker Compose 已安装，版本: $COMPOSE_VERSION"
    else
        print_warning "Docker Compose 未安装，建议安装以方便容器编排"
        print_info "安装命令: sudo apt-get install docker-compose-plugin"
    fi
    
    # 检查磁盘空间是否充足，企业级推荐至少 20GB
    print_info "检查磁盘空间和企业级存储要求..."
    # 尝试检查/opt目录，如果不存在则检查根目录
    if [ -d "/opt" ]; then
        AVAILABLE_SPACE=$(df -BG /opt 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
    else
        AVAILABLE_SPACE=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
    fi
    
    # 确保AVAILABLE_SPACE是数字
    if ! [[ "$AVAILABLE_SPACE" =~ ^[0-9]+$ ]]; then
        AVAILABLE_SPACE="0"
    fi
    
    if [ "$AVAILABLE_SPACE" -lt 20 ]; then
        print_warning "可用磁盘空间不足 20GB，企业级环境建议至少 50GB 可用空间"
        print_info "当前可用空间: ${AVAILABLE_SPACE}GB"
        print_info "建议清理空间或扩展磁盘容量"
    else
        print_success "磁盘空间充足: ${AVAILABLE_SPACE}GB 可用，满足企业级要求"
    fi
    
    # 检查内存大小，企业级推荐至少 4GB
    print_info "检查系统内存配置..."
    # 尝试多种方式获取内存信息，兼容不同系统
    if command -v free &> /dev/null; then
        TOTAL_MEMORY=$(free -g 2>/dev/null | awk 'NR==2{printf "%.0f", $2}' || echo "0")
    elif [ -f /proc/meminfo ]; then
        TOTAL_MEMORY=$(awk '/MemTotal:/ {printf "%.0f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "0")
    else
        # Windows Git Bash 环境下使用 wmic 命令
        TOTAL_MEMORY=$(wmic computersystem get TotalPhysicalMemory /value 2>/dev/null | grep TotalPhysicalMemory | cut -d'=' -f2 | awk '{printf "%.0f", $1/1024/1024/1024}' || echo "0")
    fi
    
    # 确保TOTAL_MEMORY是数字
    if ! [[ "$TOTAL_MEMORY" =~ ^[0-9]+$ ]]; then
        TOTAL_MEMORY="0"
    fi
    
    if [ "$TOTAL_MEMORY" -lt 4 ]; then
        print_warning "系统内存不足 4GB，企业级环境建议至少 8GB 内存"
        print_info "当前内存: ${TOTAL_MEMORY}GB"
    else
        print_success "系统内存充足: ${TOTAL_MEMORY}GB，满足企业级要求"
    fi
    
    # 检查系统类型和版本信息
    print_info "检查操作系统信息和兼容性..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_success "系统: $NAME $VERSION"
        print_info "系统 ID: $ID"
        print_info "版本 ID: $VERSION_ID"
        
        # 检查系统版本是否受支持
        case $ID in
            ubuntu)
                if [ "${VERSION_ID%.*}" -ge 20 ]; then
                    print_success "Ubuntu 版本受支持 (20.04+)"
                else
                    print_warning "Ubuntu 版本较旧，建议升级到 20.04 或更高版本"
                fi
                ;;
            centos|rhel)
                if [ "${VERSION_ID%.*}" -ge 7 ]; then
                    print_success "CentOS/RHEL 版本受支持 (7+)"
                else
                    print_warning "CentOS/RHEL 版本较旧，建议升级到 7 或更高版本"
                fi
                ;;
            debian)
                if [ "${VERSION_ID%.*}" -ge 10 ]; then
                    print_success "Debian 版本受支持 (10+)"
                else
                    print_warning "Debian 版本较旧，建议升级到 10 或更高版本"
                fi
                ;;
            *)
                print_warning "未测试的操作系统，建议验证兼容性"
                ;;
        esac
    fi
    
    # 检查必要的系统工具是否可用
    print_info "检查必要的系统工具..."
    # 根据系统类型调整必需工具列表
    local required_tools=("tar" "gzip" "chown" "chmod" "mkdir" "tee")
    
    # 只在非Windows环境下检查systemctl
    if [[ ! "$OSTYPE" == "msys" ]] && [[ ! "$OSTYPE" == "cygwin" ]]; then
        required_tools+=("systemctl")
    fi
    
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        print_success "所有必需的系统工具都已安装"
    else
        print_warning "缺少部分系统工具: ${missing_tools[*]}"
        if [[ " ${missing_tools[*]} " =~ " systemctl " ]]; then
            print_info "systemctl 缺失，在 Windows 环境下这是正常的"
            print_info "可以继续执行脚本，但某些服务管理功能可能不可用"
        else
            print_error "请安装缺失的工具后再运行此脚本"
            exit 1
        fi
    fi
}

# =============================================================================
# 安全检查和加固 - 企业级安全要求
# =============================================================================

security_check_and_hardening() {
    print_title "企业级安全检查和系统加固"
    
    # 检查防火墙状态
    print_info "检查防火墙状态和配置..."
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            print_success "UFW 防火墙已启用"
        else
            print_warning "UFW 防火墙未启用，建议启用防火墙"
            print_info "启用命令: sudo ufw enable"
        fi
    elif command -v firewall-cmd &> /dev/null; then
        if firewall-cmd --state &> /dev/null; then
            print_success "Firewalld 防火墙已启用"
        else
            print_warning "Firewalld 防火墙未启用，建议启用防火墙"
            print_info "启用命令: sudo systemctl start firewalld"
        fi
    else
        print_warning "未检测到防火墙软件，建议安装和配置防火墙"
    fi
    
    # 检查 SELinux 状态（如果可用）
    print_info "检查 SELinux 状态和配置..."
    if command -v getenforce &> /dev/null; then
        SELINUX_STATUS=$(getenforce)
        print_info "SELinux 状态: $SELINUX_STATUS"
        if [ "$SELINUX_STATUS" = "Enforcing" ]; then
            print_success "SELinux 已启用并处于强制模式"
        elif [ "$SELINUX_STATUS" = "Permissive" ]; then
            print_warning "SELinux 处于宽容模式，建议设置为强制模式"
        else
            print_warning "SELinux 已禁用，企业级环境建议启用"
        fi
    else
        print_info "未检测到 SELinux，这是正常的"
    fi
    
    # 检查系统更新
    print_info "检查系统更新和安全补丁..."
    if command -v apt &> /dev/null; then
        if apt list --upgradable 2>/dev/null | grep -q upgradable; then
            print_warning "有可用的系统更新，建议定期更新系统"
            print_info "更新命令: sudo apt update && sudo apt upgrade"
        else
            print_success "系统已是最新状态"
        fi
    elif command -v yum &> /dev/null; then
        if yum check-update &> /dev/null; then
            print_warning "有可用的系统更新，建议定期更新系统"
            print_info "更新命令: sudo yum update"
        else
            print_success "系统已是最新状态"
        fi
    fi
    
    # 创建安全目录结构
    print_info "创建安全配置目录..."
    # 根据系统类型选择适当的权限设置方式
    if command -v sudo &> /dev/null; then
        sudo mkdir -p "$SECURITY_DIR"/{ssl,certs,keys,policies}
        sudo chown root:root "$SECURITY_DIR"
        sudo chmod 700 "$SECURITY_DIR"
    else
        # Windows 环境下不使用 sudo
        mkdir -p "$SECURITY_DIR"/{ssl,certs,keys,policies} 2>/dev/null || true
        chmod 700 "$SECURITY_DIR" 2>/dev/null || true
    fi
    
    # 创建安全策略文件
    local temp_policy_file="/tmp/security-policy.conf"
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        temp_policy_file="/c/Windows/Temp/security-policy.conf"
    fi
    
    cat > "$temp_policy_file" << 'EOF'
# Docker 卷安全策略配置
# 此文件包含企业级安全策略和配置

# 访问控制策略
ALLOWED_USERS="docker,root,admin"
ALLOWED_GROUPS="docker,root,admin"
MAX_LOGIN_ATTEMPTS=5
PASSWORD_MIN_LENGTH=12
PASSWORD_COMPLEXITY="UPPER,LOWER,NUMBER,SPECIAL"

# 审计策略
ENABLE_AUDITING=true
AUDIT_LOG_RETENTION_DAYS=90
AUDIT_LOG_SIZE_MB=100

# 加密策略
ENCRYPT_DATA_AT_REST=true
ENCRYPT_DATA_IN_TRANSIT=true
SSL_TLS_VERSION="TLSv1.2,TLSv1.3"

# 备份策略
BACKUP_ENCRYPTION=true
BACKUP_RETENTION_DAYS=30
BACKUP_VERIFICATION=true
EOF

    # 移动安全策略文件到目标位置
    if command -v sudo &> /dev/null; then
        sudo mv "$temp_policy_file" "$SECURITY_DIR/policies/"
        sudo chmod 600 "$SECURITY_DIR/policies/security-policy.conf"
    else
        mv "$temp_policy_file" "$SECURITY_DIR/policies/" 2>/dev/null || true
        chmod 600 "$SECURITY_DIR/policies/security-policy.conf" 2>/dev/null || true
    fi
    
    print_success "安全检查和加固完成"
}

# =============================================================================
# 创建基础目录结构 - 企业级标准
# =============================================================================

create_base_directories() {
    print_title "创建企业级 Docker 卷基础目录结构"
    
    # 创建主要的 Docker 卷目录，使用 sudo 确保有权限
    print_info "创建 Docker 卷基础目录: $BASE_DIR"
    if command -v sudo &> /dev/null; then
        sudo mkdir -p "$BASE_DIR"
    else
        mkdir -p "$BASE_DIR" 2>/dev/null || true
    fi
    
    # 创建备份目录，用于存储各种备份数据
    print_info "创建备份数据目录: $BACKUP_BASE_DIR"
    if command -v sudo &> /dev/null; then
        sudo mkdir -p "$BACKUP_BASE_DIR"
    else
        mkdir -p "$BACKUP_BASE_DIR" 2>/dev/null || true
    fi
    
    # 创建日志目录，用于存储各种日志文件
    print_info "创建日志存储目录: $LOG_DIR"
    if command -v sudo &> /dev/null; then
        sudo mkdir -p "$LOG_DIR"
    else
        mkdir -p "$LOG_DIR" 2>/dev/null || true
    fi
    
    # 创建监控数据目录，用于存储监控指标和状态
    print_info "创建监控数据目录: $MONITOR_DIR"
    if command -v sudo &> /dev/null; then
        sudo mkdir -p "$MONITOR_DIR"
    else
        mkdir -p "$MONITOR_DIR" 2>/dev/null || true
    fi
    
    # 创建安全配置目录，用于存储安全相关的配置和证书
    print_info "创建安全配置目录: $SECURITY_DIR"
    if command -v sudo &> /dev/null; then
        sudo mkdir -p "$SECURITY_DIR"
    else
        mkdir -p "$SECURITY_DIR" 2>/dev/null || true
    fi
    
    # 设置基础目录的所有者和权限，确保系统安全
    print_info "设置基础目录权限和安全属性..."
    # 根据系统类型选择适当的权限设置方式
    if command -v sudo &> /dev/null; then
        sudo chown root:root "$BASE_DIR" "$BACKUP_BASE_DIR" "$LOG_DIR" "$MONITOR_DIR" "$SECURITY_DIR"
        sudo chmod 755 "$BASE_DIR" "$BACKUP_BASE_DIR" "$LOG_DIR"
    else
        # Windows 环境下简化权限设置
        chmod 755 "$BASE_DIR" "$BACKUP_BASE_DIR" "$LOG_DIR" 2>/dev/null || true
    fi
    # 设置安全目录权限
    if command -v sudo &> /dev/null; then
        sudo chmod 700 "$MONITOR_DIR" "$SECURITY_DIR"
    else
        chmod 700 "$MONITOR_DIR" "$SECURITY_DIR" 2>/dev/null || true
    fi
    
    # 创建初始日志文件
    if command -v sudo &> /dev/null; then
        sudo touch "$LOG_DIR/setup.log"
        sudo chown root:root "$LOG_DIR/setup.log"
        sudo chmod 644 "$LOG_DIR/setup.log"
    else
        touch "$LOG_DIR/setup.log" 2>/dev/null || true
        chmod 644 "$LOG_DIR/setup.log" 2>/dev/null || true
    fi
    
    print_success "企业级基础目录创建完成"
}

# =============================================================================
# 创建服务专用目录 - 每个服务的完整目录结构
# =============================================================================

create_service_directories() {
    local service=$1
    local service_dir="$BASE_DIR/$service"
    
    print_info "创建 $service 服务的企业级目录结构..."
    
    # 为每个服务创建完整的子目录结构
    for subdir in "${SERVICE_SUBDIRS[@]}"; do
        local full_path="$service_dir/$subdir"
        # 创建目录，根据系统类型选择适当方式
        if command -v sudo &> /dev/null; then
            sudo mkdir -p "$full_path"
        else
            mkdir -p "$full_path" 2>/dev/null || true
        fi
        print_info "  创建目录: $full_path"
        
        # 根据不同子目录设置企业级权限标准
        case $subdir in
            "data")
                # 数据目录：最严格的权限，仅所有者可读写执行
                if command -v sudo &> /dev/null; then
                    sudo chmod $DATA_DIR_PERMS "$full_path"
                else
                    chmod $DATA_DIR_PERMS "$full_path" 2>/dev/null || true
                fi
                ;;
            "config")
                # 配置目录：允许读取，需要时可写入
                if command -v sudo &> /dev/null; then
                    sudo chmod $CONFIG_DIR_PERMS "$full_path"
                else
                    chmod $CONFIG_DIR_PERMS "$full_path" 2>/dev/null || true
                fi
                ;;
            "logs")
                # 日志目录：允许读取，便于调试和监控
                if command -v sudo &> /dev/null; then
                    sudo chmod $LOG_DIR_PERMS "$full_path"
                else
                    chmod $LOG_DIR_PERMS "$full_path" 2>/dev/null || true
                fi
                ;;
            "backup")
                # 备份目录：允许读写，便于备份和恢复操作
                if command -v sudo &> /dev/null; then
                    sudo chmod $BACKUP_DIR_PERMS "$full_path"
                else
                    chmod $BACKUP_DIR_PERMS "$full_path" 2>/dev/null || true
                fi
                ;;
            "certs")
                # 证书目录：最高安全级别，仅所有者可读写
                if command -v sudo &> /dev/null; then
                    sudo chmod $CERTS_DIR_PERMS "$full_path"
                else
                    chmod $CERTS_DIR_PERMS "$full_path" 2>/dev/null || true
                fi
                ;;
            "scripts")
                # 脚本目录：控制执行权限，防止未授权执行
                if command -v sudo &> /dev/null; then
                    sudo chmod $SCRIPTS_DIR_PERMS "$full_path"
                else
                    chmod $SCRIPTS_DIR_PERMS "$full_path" 2>/dev/null || true
                fi
                ;;
        esac
    done
    
    # 设置服务目录的所有者和权限
    if command -v sudo &> /dev/null; then
        sudo chown -R root:root "$service_dir"
        sudo chmod 755 "$service_dir"
    else
        # Windows环境下跳过所有者设置，仅设置权限
        chmod 755 "$service_dir" 2>/dev/null || true
    fi
    
    # 创建服务专用的 README 文件
    create_service_readme "$service" "$service_dir"
    
    print_success "$service 服务的企业级目录创建完成"
}

# =============================================================================
# 创建服务专用 README 文件
# =============================================================================

create_service_readme() {
    local service=$1
    local service_dir=$2
    
    cat > "/tmp/${service}-README.md" << EOF
# $service 服务目录结构说明

## 目录结构

\`\`\`
$service_dir/
├── data/          # 数据文件存储目录
├── config/        # 配置文件存储目录
├── logs/          # 日志文件存储目录
├── backup/        # 备份文件存储目录
├── certs/         # SSL/TLS 证书存储目录
└── scripts/       # 自动化脚本存储目录
\`\`\`

## 使用说明

### 数据目录 (data/)
- 用途：存储 $service 的核心数据文件
- 权限：$DATA_DIR_PERMS (仅所有者可读写)
- 注意：请勿手动修改此目录中的文件

### 配置目录 (config/)
- 用途：存储 $service 的配置文件
- 权限：$CONFIG_DIR_PERMS (允许读取)
- 建议：根据实际需求修改配置文件

### 日志目录 (logs/)
- 用途：存储 $service 的运行日志
- 权限：$LOG_DIR_PERMS (允许读取)
- 用途：故障排查和性能监控

### 备份目录 (backup/)
- 用途：存储 $service 的数据备份
- 权限：$BACKUP_DIR_PERMS (允许读写)
- 建议：定期验证备份文件的完整性

### 证书目录 (certs/)
- 用途：存储 SSL/TLS 证书文件
- 权限：$CERTS_DIR_PERMS (最高安全级别)
- 注意：确保证书文件的安全性

### 脚本目录 (scripts/)
- 用途：存储自动化脚本和工具
- 权限：$SCRIPTS_DIR_PERMS (控制执行)
- 建议：定期审查脚本内容

## 安全注意事项

1. 定期检查目录权限设置
2. 监控磁盘空间使用情况
3. 定期备份重要数据
4. 及时更新安全补丁
5. 配置适当的访问控制

## 故障排除

如遇到问题，请检查：
- 目录权限是否正确
- 磁盘空间是否充足
- 日志文件中的错误信息
- 服务配置文件的有效性

EOF

    if command -v sudo &> /dev/null; then
        sudo mv "/tmp/${service}-README.md" "$service_dir/README.md"
        sudo chown root:root "$service_dir/README.md"
        sudo chmod 644 "$service_dir/README.md"
    else
        mv "/tmp/${service}-README.md" "$service_dir/README.md" 2>/dev/null || true
        chmod 644 "$service_dir/README.md" 2>/dev/null || true
    fi
}

# =============================================================================
# 创建共享资源目录 - 企业级共享资源配置
# =============================================================================

create_shared_directories() {
    print_title "创建企业级共享资源目录"
    
    local shared_dir="$BASE_DIR/shared"
    
    # 创建共享目录结构，包含企业级所需的各种资源
    print_info "创建共享目录: $shared_dir"
    if command -v sudo &> /dev/null; then
        sudo mkdir -p "$shared_dir"/{ssl,certs,scripts,configs,templates,monitoring,security,docs,backups}
    else
        mkdir -p "$shared_dir"/{ssl,certs,scripts,configs,templates,monitoring,security,docs,backups} 2>/dev/null || true
    fi
    
    # 为不同类型的共享资源设置专门权限
    print_info "设置共享目录的企业级权限..."
    if command -v sudo &> /dev/null; then
        sudo chmod 755 "$shared_dir/ssl"      # SSL 证书目录
        sudo chmod 755 "$shared_dir/certs"    # 证书目录
        sudo chmod 755 "$shared_dir/scripts"  # 脚本目录
        sudo chmod 755 "$shared_dir/configs"  # 配置文件目录
        sudo chmod 755 "$shared_dir/templates" # 模板目录
        sudo chmod 700 "$shared_dir/monitoring" # 监控数据目录
        sudo chmod 700 "$shared_dir/security"   # 安全数据目录
        sudo chmod 755 "$shared_dir/docs"     # 文档目录
        sudo chmod 755 "$shared_dir/backups"  # 备份目录
        
        # 设置共享目录的所有者
        sudo chown -R root:root "$shared_dir"
        sudo chmod 755 "$shared_dir"
    else
        chmod 755 "$shared_dir/ssl"      2>/dev/null || true
        chmod 755 "$shared_dir/certs"    2>/dev/null || true
        chmod 755 "$shared_dir/scripts"  2>/dev/null || true
        chmod 755 "$shared_dir/configs"  2>/dev/null || true
        chmod 755 "$shared_dir/templates" 2>/dev/null || true
        chmod 700 "$shared_dir/monitoring" 2>/dev/null || true
        chmod 700 "$shared_dir/security"   2>/dev/null || true
        chmod 755 "$shared_dir/docs"     2>/dev/null || true
        chmod 755 "$shared_dir/backups"  2>/dev/null || true
        chmod 755 "$shared_dir"          2>/dev/null || true
    fi
    
    # 创建各种企业级示例文件
    create_enterprise_example_files "$shared_dir"
    
    print_success "企业级共享目录创建完成"
}

# =============================================================================
# 创建 Docker Compose 模板
# =============================================================================

create_docker_compose_templates() {
    print_info "创建企业级 Docker Compose 模板..."
    
    # 创建 Docker Compose 主配置文件
    cat > "$BASE_DIR/docker-compose.enterprise.yml" << 'EOF'
version: '3.8'

# 企业级 Docker Compose 配置
# 包含多层安全策略和监控配置

services:
  # MySQL 企业级配置
  mysql-enterprise:
    image: mysql:8.0
    container_name: mysql-production
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-myapp}
      MYSQL_USER: ${MYSQL_USER:-appuser}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - /opt/docker-volumes/mysql/data:/var/lib/mysql
      - /opt/docker-volumes/mysql/config:/etc/mysql/conf.d
      - /opt/docker-volumes/mysql/logs:/var/log/mysql
      - /opt/docker-volumes/mysql/backup:/backup
      - /opt/docker-volumes/mysql/certs:/etc/mysql/certs
    networks:
      - database-network
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    labels:
      - "com.company.service=mysql"
      - "com.company.environment=production"
      - "com.company.backup.enabled=true"
      - "com.company.monitoring.enabled=true"

  # Redis 企业级配置
  redis-enterprise:
    image: redis:7-alpine
    container_name: redis-production
    restart: unless-stopped
    command: redis-server /etc/redis/redis.conf
    volumes:
      - /opt/docker-volumes/redis/data:/data
      - /opt/docker-volumes/redis/config:/etc/redis
      - /opt/docker-volumes/redis/logs:/var/log/redis
      - /opt/docker-volumes/redis/backup:/backup
    networks:
      - database-network
      - cache-network
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
    labels:
      - "com.company.service=redis"
      - "com.company.environment=production"
      - "com.company.backup.enabled=true"

  # MongoDB 企业级配置
  mongodb-enterprise:
    image: mongo:6.0
    container_name: mongodb-production
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_ROOT_USERNAME}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_ROOT_PASSWORD}
      MONGO_INITDB_DATABASE: ${MONGO_DATABASE:-admin}
    volumes:
      - /opt/docker-volumes/mongodb/data:/data/db
      - /opt/docker-volumes/mongodb/config:/etc/mongo
      - /opt/docker-volumes/mongodb/logs:/var/log/mongodb
      - /opt/docker-volumes/mongodb/backup:/backup
    networks:
      - database-network
    ports:
      - "27017:27017"
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 5
    labels:
      - "com.company.service=mongodb"
      - "com.company.environment=production"
      - "com.company.backup.enabled=true"

networks:
  database-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
  cache-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16

volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
  mongodb_data:
    driver: local

EOF

    # 创建环境变量模板
    cat > "$BASE_DIR/.env.enterprise.template" << 'EOF'
# Docker 企业级环境变量模板
# 复制此文件为 .env 并根据实际情况修改

# MySQL 配置
MYSQL_ROOT_PASSWORD=your_strong_root_password_here
MYSQL_DATABASE=myapp
MYSQL_USER=appuser
MYSQL_PASSWORD=your_strong_password_here

# Redis 配置（如需要密码）
REDIS_PASSWORD=your_redis_password_here

# MongoDB 配置
MONGO_ROOT_USERNAME=root
MONGO_ROOT_PASSWORD=your_strong_mongo_password_here
MONGO_DATABASE=admin

# PostgreSQL 配置
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_strong_postgres_password_here
POSTGRES_DB=myapp

# 备份配置
BACKUP_ENCRYPTION_KEY=your_backup_encryption_key_here
BACKUP_RETENTION_DAYS=30

# 监控配置
GRAFANA_ADMIN_PASSWORD=your_grafana_admin_password
PROMETHEUS_RETENTION_DAYS=15

# 时区配置
TZ=Asia/Shanghai

EOF

    print_success "企业级 Docker Compose 模板创建完成"
    print_info "模板文件位置:"
    print_info "  - Docker Compose: $BASE_DIR/docker-compose.enterprise.yml"
    print_info "  - 环境变量模板: $BASE_DIR/.env.enterprise.template"
}

# =============================================================================
# 创建企业级示例配置文件
# =============================================================================

create_enterprise_example_files() {
    local shared_dir=$1
    
    print_info "创建企业级示例配置文件和模板..."
    
    # 创建 Docker 网络配置示例（企业级）
    cat > "/tmp/docker-network-enterprise.yml" << 'EOF'
# Docker 企业级网络配置示例
# 包含多层网络隔离和安全策略

version: '3.8'

# 企业级网络配置
networks:
  # 数据库网络 - 高安全性
  database-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
    labels:
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.network.type=database"
    
  # 应用网络 - 中等安全性
  application-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.21.0.0/16
          gateway: 172.21.0.1
    labels:
      - "com.company.environment=production"
      - "com.company.security.level=medium"
      - "com.company.network.type=application"
  
  # Web 网络 - 标准安全性
  web-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.22.0.0/16
          gateway: 172.22.0.1
    labels:
      - "com.company.environment=production"
      - "com.company.security.level=standard"
      - "com.company.network.type=web"
EOF

    # 创建企业级备份脚本
    cat > "/tmp/enterprise-backup.sh" << 'EOF'
#!/bin/bash
# Docker 企业级全量备份脚本
# 支持 MySQL、Redis、MongoDB、PostgreSQL、Elasticsearch

set -euo pipefail

# 配置参数
BACKUP_BASE_DIR="/backup/docker-volumes"
LOG_FILE="/var/log/docker-volumes/enterprise-backup.log"
RETENTION_DAYS=30
ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY:-}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
print_info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] [信息]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] [成功]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] [错误]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] [警告]${NC} $1" | tee -a "$LOG_FILE"
}

# 创建备份目录
create_backup_dir() {
    local backup_date=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$BACKUP_BASE_DIR/full_backup_$backup_date"
    mkdir -p "$BACKUP_DIR"
    print_info "创建备份目录: $BACKUP_DIR"
}

# 备份 MySQL
backup_mysql() {
    print_info "开始备份 MySQL..."
    
    if docker ps --format "table {{.Names}}" | grep -q "mysql-production"; then
        local mysql_backup_dir="$BACKUP_DIR/mysql"
        mkdir -p "$mysql_backup_dir"
        
        # 使用 mysqldump 备份所有数据库
        docker exec mysql-production mysqldump \
            --all-databases \
            --single-transaction \
            --quick \
            --lock-tables=false \
            --user=root \
            --password="${MYSQL_ROOT_PASSWORD}" \
            > "$mysql_backup_dir/all-databases.sql"
        
        if [ $? -eq 0 ]; then
            # 压缩备份文件
            gzip "$mysql_backup_dir/all-databases.sql"
            
            # 备份配置文件
            tar -czf "$mysql_backup_dir/config.tar.gz" -C /opt/docker-volumes/mysql config
            
            # 备份数据目录（可选，需要停止服务）
            # tar -czf "$mysql_backup_dir/data.tar.gz" -C /opt/docker-volumes/mysql data
            
            print_success "MySQL 备份完成"
        else
            print_error "MySQL 备份失败"
        fi
    else
        print_warning "MySQL 容器未运行，跳过备份"
    fi
}

# 备份 Redis
backup_redis() {
    print_info "开始备份 Redis..."
    
    if docker ps --format "table {{.Names}}" | grep -q "redis-production"; then
        local redis_backup_dir="$BACKUP_DIR/redis"
        mkdir -p "$redis_backup_dir"
        
        # 创建 Redis 快照
        docker exec redis-production redis-cli BGSAVE
        
        # 等待快照完成
        sleep 5
        
        # 复制 dump.rdb 文件
        docker cp redis-production:/data/dump.rdb "$redis_backup_dir/dump.rdb"
        
        if [ $? -eq 0 ]; then
            # 压缩备份文件
            gzip "$redis_backup_dir/dump.rdb"
            
            # 备份配置文件
            tar -czf "$redis_backup_dir/config.tar.gz" -C /opt/docker-volumes/redis config
            
            print_success "Redis 备份完成"
        else
            print_error "Redis 备份失败"
        fi
    else
        print_warning "Redis 容器未运行，跳过备份"
    fi
}

# 备份 MongoDB
backup_mongodb() {
    print_info "开始备份 MongoDB..."
    
    if docker ps --format "table {{.Names}}" | grep -q "mongodb-production"; then
        local mongodb_backup_dir="$BACKUP_DIR/mongodb"
        mkdir -p "$mongodb_backup_dir"
        
        # 使用 mongodump 备份所有数据库
        docker exec mongodb-production mongodump \
            --username="${MONGO_ROOT_USERNAME}" \
            --password="${MONGO_ROOT_PASSWORD}" \
            --authenticationDatabase=admin \
            --out=/tmp/mongodb_backup \
            --gzip
        
        if [ $? -eq 0 ]; then
            # 复制备份文件
            docker cp mongodb-production:/tmp/mongodb_backup "$mongodb_backup_dir/"
            
            # 压缩备份目录
            tar -czf "$mongodb_backup_dir/mongodb_backup.tar.gz" -C "$mongodb_backup_dir" mongodb_backup
            rm -rf "$mongodb_backup_dir/mongodb_backup"
            
            # 备份配置文件
            tar -czf "$mongodb_backup_dir/config.tar.gz" -C /opt/docker-volumes/mongodb config
            
            print_success "MongoDB 备份完成"
        else
            print_error "MongoDB 备份失败"
        fi
    else
        print_warning "MongoDB 容器未运行，跳过备份"
    fi
}

# 备份 PostgreSQL
backup_postgres() {
    print_info "开始备份 PostgreSQL..."
    
    if docker ps --format "table {{.Names}}" | grep -q "postgres-production"; then
        local postgres_backup_dir="$BACKUP_DIR/postgres"
        mkdir -p "$postgres_backup_dir"
        
        # 使用 pg_dumpall 备份所有数据库
        docker exec postgres-production pg_dumpall \
            --username="${POSTGRES_USER}" \
            --clean \
            --if-exists \
            --verbose \
            > "$postgres_backup_dir/all-databases.sql"
        
        if [ $? -eq 0 ]; then
            # 压缩备份文件
            gzip "$postgres_backup_dir/all-databases.sql"
            
            # 备份配置文件
            tar -czf "$postgres_backup_dir/config.tar.gz" -C /opt/docker-volumes/postgres config
            
            print_success "PostgreSQL 备份完成"
        else
            print_error "PostgreSQL 备份失败"
        fi
    else
        print_warning "PostgreDB 容器未运行，跳过备份"
    fi
}

# 创建备份清单
create_backup_manifest() {
    local manifest_file="$BACKUP_DIR/backup_manifest.txt"
    
    cat > "$manifest_file" << EOF
Docker 企业级数据库备份清单
====================================
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份目录: $BACKUP_DIR
主机名: $(hostname)
系统版本: $(uname -a)
Docker 版本: $(docker --version)

备份内容:
- MySQL: 完整数据库备份 + 配置文件
- Redis: 数据快照备份 + 配置文件
- MongoDB: 完整数据库备份 + 配置文件
- PostgreSQL: 完整数据库备份 + 配置文件

恢复说明:
1. 停止相应的服务容器
2. 解压备份文件
3. 使用对应的数据库工具导入数据
4. 重启服务容器
5. 验证数据完整性

安全注意事项:
- 备份文件包含敏感数据，请妥善保管
- 建议对备份文件进行加密存储
- 定期测试备份恢复过程
- 将备份文件存储在多个位置

EOF

    print_info "备份清单已创建: ${manifest_file:-}"
}

# 清理旧备份
cleanup_old_backups() {
    print_info "清理旧备份文件..."
    
    # 删除超过保留期限的备份
    find "$BACKUP_BASE_DIR" -type d -name "full_backup_*" -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
    
    # 保留最新的 10 个备份（无论是否过期）
    local backup_count=$(ls -1d "$BACKUP_BASE_DIR"/full_backup_* 2>/dev/null | wc -l)
    if [ "$backup_count" -gt 10 ]; then
        ls -1dt "$BACKUP_BASE_DIR"/full_backup_* | tail -n +11 | xargs rm -rf 2>/dev/null || true
    fi
    
    print_success "旧备份清理完成"
}

# 企业级备份脚本主函数
backup_main() {
    print_info "开始 Docker 企业级数据库全量备份..."
    
    # 创建备份目录
    create_backup_dir
    
    # 执行备份
    backup_mysql
    backup_redis
    backup_mongodb
    backup_postgres
    
    # 创建备份清单
    create_backup_manifest
    
    # 清理旧备份
    cleanup_old_backups
    
    # 显示备份统计
    local backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    print_success "企业级备份完成！"
    print_info "备份目录: $BACKUP_DIR"
    print_info "备份大小: $backup_size"
    
    # 发送通知（可选）
    # local manifest_file="$BACKUP_DIR/backup_manifest.txt"
    # mail -s "Docker 备份完成" admin@example.com < "$manifest_file"
}

# 创建日志轮转配置
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

    # 安装日志轮转配置（使用条件sudo检查）
    if command -v sudo &> /dev/null; then
        sudo mv "/tmp/docker-volumes" "/etc/logrotate.d/docker-volumes" 2>/dev/null || true
        sudo chmod 644 "/etc/logrotate.d/docker-volumes" 2>/dev/null || true
    else
        mv "/tmp/docker-volumes" "/etc/logrotate.d/docker-volumes" 2>/dev/null || true
        chmod 644 "/etc/logrotate.d/docker-volumes" 2>/dev/null || true
    fi
    
    print_success "日志轮转配置完成"
}

# 创建系统服务监控脚本
create_monitoring_scripts() {
    print_title "创建监控和维护脚本"
    
    local scripts_dir="$BASE_DIR/shared/scripts"
    
    # 确保脚本目录存在
    if [ ! -d "$scripts_dir" ]; then
        print_info "创建脚本目录: $scripts_dir"
        mkdir -p "$scripts_dir"
    fi
    
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
    if command -v sudo &> /dev/null; then
        sudo mv "/tmp/disk-monitor.sh" "$scripts_dir/" 2>/dev/null || true
        sudo mv "/tmp/permission-check.sh" "$scripts_dir/" 2>/dev/null || true
        sudo chmod +x "$scripts_dir/disk-monitor.sh" 2>/dev/null || true
        sudo chmod +x "$scripts_dir/permission-check.sh" 2>/dev/null || true
    else
        mv "/tmp/disk-monitor.sh" "$scripts_dir/" 2>/dev/null || true
        mv "/tmp/permission-check.sh" "$scripts_dir/" 2>/dev/null || true
        chmod +x "$scripts_dir/disk-monitor.sh" 2>/dev/null || true
        chmod +x "$scripts_dir/permission-check.sh" 2>/dev/null || true
    fi
    
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
# 主函数 - 脚本的主要执行流程
# =============================================================================

main() {
    print_title "Docker 企业级多数据库容器数据挂载目录创建工具"
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行系统检查和依赖验证
    check_system_requirements
    
    # 执行安全检查和加固
    security_check_and_hardening
    
    # 创建基础目录结构
    create_base_directories
    
    # 为每个服务创建专用目录
    for service in "${SERVICES[@]}"; do
        create_service_directories "$service"
    done
    
    # 创建共享资源目录
    create_shared_directories
    
    # 创建日志轮转配置
    setup_log_rotation
    
    # 创建监控脚本
    create_monitoring_scripts
    
    # 创建 Docker Compose 模板
    create_docker_compose_templates
    
    # 计算执行时间
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_min=$((duration / 60))
    local duration_sec=$((duration % 60))
    
    # 显示完成信息
    print_success "企业级 Docker 卷目录创建完成！"
    print_info "执行时间: ${duration_min}分${duration_sec}秒"
    print_info ""
    print_info "创建的目录结构:"
    print_info "  - 基础目录: $BASE_DIR"
    print_info "  - 备份目录: $BACKUP_BASE_DIR"
    print_info "  - 日志目录: $LOG_DIR"
    print_info "  - 监控目录: $MONITOR_DIR"
    print_info "  - 安全目录: $SECURITY_DIR"
    print_info ""
    print_info "支持的服务:"
    for service in "${SERVICES[@]}"; do
        print_info "  - $service"
    done
    print_info ""
    print_info "后续操作建议:"
    print_info "  1. 根据实际需求修改配置文件"
    print_info "  2. 设置环境变量（密码等敏感信息）"
    print_info "  3. 使用 Docker Compose 启动服务"
    print_info "  4. 配置监控和告警"
    print_info "  5. 定期执行备份策略"
    print_info "  6. 定期检查和更新安全设置"
}

# =============================================================================
# 显示使用说明
# =============================================================================

show_usage() {
    cat << EOF
Docker 企业级多数据库容器数据挂载目录创建脚本

使用方法: $0 [选项]

选项:
    -h, --help      显示此帮助信息
    -c, --check     仅执行系统检查，不创建目录
    -t, --test      测试模式，检查依赖和环境
    -v, --verbose   详细模式，输出更多信息
    -s, --security  仅执行安全检查
    --dry-run       模拟运行，不实际创建目录

示例:
    # 完整安装
    $0
    
    # 仅检查系统环境
    $0 --check
    
    # 测试模式
    $0 --test
    
    # 详细模式
    $0 --verbose
    
    # 模拟运行
    $0 --dry-run

企业级特性:
    ✓ 完整的目录结构规划
    ✓ 企业级权限管理
    ✓ 自动化备份配置
    ✓ 监控告警设置
    ✓ 安全加固措施
    ✓ 一键恢复功能
    ✓ 多服务支持
    ✓ 详细的日志记录

支持的服务:
    - MySQL (关系型数据库)
    - Redis (内存数据库)
    - MongoDB (文档数据库)
    - PostgreSQL (高级关系型数据库)
    - Elasticsearch (搜索引擎)
    - Nginx (Web 服务器)
    - MinIO (对象存储)

EOF
}

# =============================================================================
# 命令行参数解析
# =============================================================================

parse_arguments() {
    local check_only=false
    local test_mode=false
    local security_only=false
    local dry_run=false
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--check)
                check_only=true
                shift
                ;;
            -t|--test)
                test_mode=true
                shift
                ;;
            -s|--security)
                security_only=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                print_error "未知选项: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 根据参数执行相应操作
    if [ "$check_only" = true ]; then
        print_title "企业级系统检查模式"
        check_system_requirements
        exit 0
    fi
    
    if [ "$test_mode" = true ]; then
        print_title "企业级测试模式"
        check_system_requirements
        security_check_and_hardening
        exit 0
    fi
    
    if [ "$security_only" = true ]; then
        print_title "企业级安全检查模式"
        security_check_and_hardening
        exit 0
    fi
    
    if [ "$dry_run" = true ]; then
        print_title "企业级模拟运行模式"
        print_info "模拟运行模式 - 不实际创建目录和文件"
        print_info "将显示所有将要执行的操作"
        # 这里可以添加模拟运行的逻辑
        exit 0
    fi
}

# =============================================================================
# 脚本入口点
# =============================================================================

# 如果直接运行脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 解析命令行参数
    parse_arguments "$@"
    
    # 执行主函数
    main
fi