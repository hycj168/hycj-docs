#!/bin/bash
# Docker企业级环境部署脚本 - 在远程服务器上部署Docker环境

# 服务器配置
SERVER_IP="192.168.157.129"
DEFAULT_USER="root"

# 显示使用方法
show_usage() {
    echo "Docker企业级环境部署脚本"
    echo "用法: $0 [部署类型] [用户名]"
    echo ""
    echo "部署类型:"
    echo "  full        - 完整部署（系统更新 + Docker安装 + 目录创建）"
    echo "  docker-only - 仅安装Docker"
    echo "  volumes     - 仅创建Docker卷目录"
    echo "  check       - 检查环境状态"
    echo ""
    echo "示例:"
    echo "  $0 full          # 完整部署"
    echo "  $0 docker-only   # 仅安装Docker"
    echo "  $0 volumes       # 仅创建目录"
    echo "  $0 check         # 检查状态"
    echo "  $0 full ubuntu   # 使用ubuntu用户完整部署"
}

# 检查是否安装了SSH客户端
check_ssh_client() {
    if ! command -v ssh &> /dev/null; then
        echo "错误: 未找到SSH客户端"
        echo "Windows用户可以使用Git Bash或安装OpenSSH"
        exit 1
    fi
}

# 完整部署命令
get_full_deploy_commands() {
    cat << 'EOF'
echo "开始完整部署Docker企业级环境..."

# 系统更新
echo "更新系统包..."
apt update && apt upgrade -y

# 安装必要工具
echo "安装必要工具..."
apt install -y curl wget git vim htop net-tools

# 安装Docker
echo "安装Docker..."
curl -fsSL https://get.docker.com | sh

# 启动Docker服务
systemctl start docker
systemctl enable docker

# 添加当前用户到docker组
usermod -aG docker $USER

# 创建Docker卷目录
echo "创建Docker卷目录..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/docker/docker-install/master/install.sh)"

# 下载并执行企业级目录创建脚本
echo "下载企业级目录创建脚本..."
cd /tmp
wget -O enterprise-docker-volumes-setup.sh "https://raw.githubusercontent.com/your-repo/docker-tutorial/main/enterprise-docker-volumes-setup.sh"

# 执行脚本
bash enterprise-docker-volumes-setup.sh

echo "部署完成！"
docker --version
docker-compose --version
EOF
}

# Docker安装命令
get_docker_install_commands() {
    cat << 'EOF'
echo "安装Docker..."

# 安装必要工具
apt update
apt install -y curl wget

# 安装Docker
curl -fsSL https://get.docker.com | sh

# 启动Docker服务
systemctl start docker
systemctl enable docker

# 添加当前用户到docker组
usermod -aG docker $USER

echo "Docker安装完成！"
docker --version
EOF
}

# 检查环境命令
get_check_commands() {
    cat << 'EOF'
echo "检查Docker环境状态..."

# 系统信息
echo "=== 系统信息 ==="
cat /etc/os-release
uname -a

# Docker信息
echo "=== Docker信息 ==="
docker --version 2>/dev/null || echo "Docker未安装"
docker-compose --version 2>/dev/null || echo "Docker Compose未安装"
docker ps 2>/dev/null || echo "Docker服务未运行"

# 磁盘空间
echo "=== 磁盘空间 ==="
df -h

# 内存信息
echo "=== 内存信息 ==="
free -h

# 检查目录
echo "=== Docker卷目录 ==="
ls -la /opt/docker-volumes/ 2>/dev/null || echo "目录不存在"

echo "检查完成！"
EOF
}

# 获取部署命令
get_deploy_commands() {
    local deploy_type="$1"
    case $deploy_type in
        full)
            get_full_deploy_commands
            ;;
        docker-only)
            get_docker_install_commands
            ;;
        check)
            get_check_commands
            ;;
        *)
            echo "echo '未知的部署类型: $deploy_type'"
            return 1
            ;;
    esac
}

# 主函数
main() {
    check_ssh_client
    
    # 检查参数
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    local deploy_type="$1"
    local username="${2:-$DEFAULT_USER}"
    
    echo "开始远程部署Docker环境..."
    echo "服务器IP: $SERVER_IP"
    echo "用户名: $username"
    echo "部署类型: $deploy_type"
    echo ""
    echo "========================================"
    
    # 获取部署命令
    local commands=$(get_deploy_commands "$deploy_type")
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # 执行远程部署
    ssh "${username}@${SERVER_IP}" "$commands"
    
    echo ""
    echo "========================================"
    echo "部署操作完成"
}

# 如果传入了-h或--help参数，显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# 运行主函数
main "$@"