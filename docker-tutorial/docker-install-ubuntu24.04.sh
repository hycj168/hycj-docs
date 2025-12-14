#!/bin/bash

# Ubuntu 24.04 LTS 企业级Docker安装脚本
# 创建日期：2025年12月
# 版本：v1.0

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

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要以root权限运行"
        exit 1
    fi
}

# 检查系统版本
check_system() {
    log_info "检查系统版本..."
    
    if ! command -v lsb_release &> /dev/null; then
        apt install -y lsb-release
    fi
    
    UBUNTU_VERSION=$(lsb_release -rs)
    UBUNTU_CODENAME=$(lsb_release -cs)
    
    if [[ "$UBUNTU_VERSION" != "24.04" ]]; then
        log_warning "此脚本专为Ubuntu 24.04设计，当前版本：$UBUNTU_VERSION"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "系统版本检查通过：Ubuntu $UBUNTU_VERSION ($UBUNTU_CODENAME)"
}

# 卸载旧版本
cleanup_old_docker() {
    log_info "清理旧版本Docker..."
    
    # 停止所有运行的容器
    if command -v docker &> /dev/null; then
        docker stop $(docker ps -aq) 2>/dev/null || true
    fi
    
    # 卸载旧版本
    apt remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli docker-ce-rootless-extras docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt purge -y docker* 2>/dev/null || true
    
    # 删除残留文件
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    rm -rf /etc/docker
    
    log_success "旧版本清理完成"
}

# 安装依赖包
install_dependencies() {
    log_info "安装依赖包..."
    
    apt update
    apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https \
        uidmap \
        apparmor \
        apparmor-utils \
        bash-completion
    
    log_success "依赖包安装完成"
}

# 配置Docker仓库
setup_docker_repo() {
    log_info "配置Docker官方仓库..."
    
    # 创建密钥目录
    install -m 0755 -d /etc/apt/keyrings
    
    # 下载GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    
    # 添加仓库
    DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    CODENAME=$(lsb_release -cs)
    ARCH=$(dpkg --print-architecture)
    
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DISTRO} ${CODENAME} stable" > /etc/apt/sources.list.d/docker.list
    
    apt update
    
    log_success "Docker仓库配置完成"
}

# 安装Docker
install_docker() {
    log_info "安装Docker CE..."
    
    apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    
    log_success "Docker安装完成"
}

# 验证安装
verify_installation() {
    log_info "验证Docker安装..."
    
    # 检查版本
    docker --version
    
    # 启动并启用服务
    systemctl enable docker
    systemctl start docker
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet docker; then
        log_success "Docker服务运行正常"
    else
        log_error "Docker服务启动失败"
        exit 1
    fi
    
    # 运行测试容器
    if docker run --rm hello-world > /dev/null 2>&1; then
        log_success "Docker功能测试通过"
    else
        log_error "Docker功能测试失败"
        exit 1
    fi
}

# 配置用户权限
setup_user_permissions() {
    log_info "配置用户权限..."
    
    # 创建docker组
    groupadd docker 2>/dev/null || true
    
    # 添加当前用户到docker组
    usermod -aG docker $SUDO_USER 2>/dev/null || true
    
    log_success "用户权限配置完成"
}

# 企业级配置
enterprise_config() {
    log_info "应用企业级配置..."
    
    # 创建配置目录
    mkdir -p /etc/docker
    
    # 创建daemon.json
    cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "live-restore": true,
  "userland-proxy": false,
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "default-ulimits": {
    "nofile": {
      "Soft": 65536,
      "Hard": 65536
    },
    "nproc": {
      "Soft": 32768,
      "Hard": 32768
    }
  },
  "exec-opts": ["native.cgroupdriver=systemd"],
  "group": "docker",
  "hosts": ["unix:///var/run/docker.sock"],
  "experimental": false,
  "metrics-addr": "0.0.0.0:9323",
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "path": "runc"
    }
  }
}
EOF

    # 创建systemd配置目录
    mkdir -p /etc/systemd/system/docker.service.d
    
    # 创建资源限制配置
    cat > /etc/systemd/system/docker.service.d/resource-limits.conf <<EOF
[Service]
MemoryLimit=4G
CPUQuota=200%
TasksMax=8192
LimitNOFILE=1048576
LimitNPROC=1048576
Restart=always
RestartSec=5
EOF

    # 重新加载配置
    systemctl daemon-reload
    systemctl restart docker
    
    # 等待服务重启
    sleep 5
    
    # 验证配置
    if systemctl is-active --quiet docker; then
        log_success "企业级配置应用完成"
    else
        log_error "企业级配置应用失败"
        exit 1
    fi
}

# 安装Docker Compose
install_docker_compose() {
    log_info "安装Docker Compose..."
    
    # 获取最新版本
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    # 下载Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 设置权限
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    # 安装自动补全
    curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
    
    # 验证安装
    if docker-compose --version > /dev/null 2>&1; then
        log_success "Docker Compose安装完成"
    else
        log_error "Docker Compose安装失败"
        exit 1
    fi
}

# 配置系统优化
system_optimization() {
    log_info "配置系统优化..."
    
    # 配置内核参数
    cat > /etc/sysctl.d/99-docker.conf <<EOF
# Docker优化
net.core.somaxconn = 1024
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

    # 配置系统限制
    cat > /etc/security/limits.d/docker.conf <<EOF
docker soft nofile 1048576
docker hard nofile 1048576
docker soft nproc 1048576
docker hard nproc 1048576
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
EOF

    # 应用内核参数
    sysctl -p /etc/sysctl.d/99-docker.conf
    
    log_success "系统优化配置完成"
}

# 创建维护脚本
create_maintenance_scripts() {
    log_info "创建维护脚本..."
    
    # 创建维护脚本
    cat > /usr/local/bin/docker-maintenance.sh <<'EOF'
#!/bin/bash
# Docker维护脚本

echo "开始Docker维护..."

# 清理未使用的资源
echo "清理未使用的Docker资源..."
docker system prune -a -f

# 清理日志文件
echo "清理Docker日志文件..."
find /var/lib/docker/containers/ -type f -name "*.log" -exec truncate -s 0 {} \;

# 重启Docker服务
echo "重启Docker服务..."
systemctl restart docker

# 检查状态
echo "检查Docker状态..."
systemctl status docker --no-pager

echo "Docker维护完成！"
EOF

    chmod +x /usr/local/bin/docker-maintenance.sh
    
    # 创建备份脚本
    cat > /usr/local/bin/docker-backup.sh <<'EOF'
#!/bin/bash
# Docker备份脚本

BACKUP_DIR="/backup/docker"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份Docker配置和数据
tar -czf $BACKUP_DIR/docker-backup-${DATE}.tar.gz \
  /etc/docker \
  /var/lib/docker \
  /etc/systemd/system/docker.service.d

echo "Docker备份完成：$BACKUP_DIR/docker-backup-${DATE}.tar.gz"
EOF

    chmod +x /usr/local/bin/docker-backup.sh
    
    log_success "维护脚本创建完成"
}

# 运行测试
run_tests() {
    log_info "运行功能测试..."
    
    # 创建测试目录
    TEST_DIR="/tmp/docker-test"
    rm -rf $TEST_DIR
    mkdir -p $TEST_DIR
    cd $TEST_DIR
    
    # 创建测试Dockerfile
    cat > Dockerfile <<EOF
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y curl
CMD ["echo", "Docker测试成功"]
EOF

    # 创建测试Compose文件
    cat > docker-compose.yml <<EOF
version: '3.8'
services:
  test:
    build: .
    restart: "no"
EOF

    # 测试Docker构建
    if docker build -t docker-test . > /dev/null 2>&1; then
        log_success "Docker构建测试通过"
    else
        log_error "Docker构建测试失败"
        exit 1
    fi
    
    # 测试Docker运行
    if docker run --rm docker-test > /dev/null 2>&1; then
        log_success "Docker运行测试通过"
    else
        log_error "Docker运行测试失败"
        exit 1
    fi
    
    # 测试Compose
    if docker-compose up --build > /dev/null 2>&1; then
        log_success "Docker Compose测试通过"
    else
        log_error "Docker Compose测试失败"
        exit 1
    fi
    
    # 清理测试资源
    docker-compose down > /dev/null 2>&1
    docker rmi docker-test > /dev/null 2>&1
    rm -rf $TEST_DIR
    
    log_success "所有测试通过"
}

# 显示安装信息
show_installation_info() {
    log_info "安装信息汇总："
    echo "=================================="
    echo "Docker版本：$(docker --version)"
    echo "Docker Compose版本：$(docker-compose --version)"
    echo "Docker服务状态：$(systemctl is-active docker)"
    echo ""
    echo "重要信息："
    echo "1. 请重新登录以使docker组权限生效"
    echo "2. 维护脚本：/usr/local/bin/docker-maintenance.sh"
    echo "3. 备份脚本：/usr/local/bin/docker-backup.sh"
    echo "4. 配置文件：/etc/docker/daemon.json"
    echo "5. 日志文件：/var/log/docker.log"
    echo ""
    echo "常用命令："
    echo "  docker info                    # 查看Docker信息"
    echo "  docker system df               # 查看磁盘使用情况"
    echo "  docker system prune -a -f      # 清理未使用资源"
    echo "  sudo docker-maintenance.sh     # 运行维护脚本"
    echo "=================================="
}

# 主函数
main() {
    echo "=================================="
    echo "Ubuntu 24.04 LTS Docker企业级安装脚本"
    echo "版本：v1.0"
    echo "创建日期：2024年12月"
    echo "=================================="
    echo
    
    # 检查root权限
    check_root
    
    # 检查系统版本
    check_system
    
    # 确认开始安装
    read -p "是否开始安装？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    # 执行安装步骤
    cleanup_old_docker
    install_dependencies
    setup_docker_repo
    install_docker
    verify_installation
    setup_user_permissions
    enterprise_config
    install_docker_compose
    system_optimization
    create_maintenance_scripts
    run_tests
    
    # 显示安装信息
    show_installation_info
    
    log_success "Docker企业级安装完成！"
    echo
    echo "请重新登录系统以使所有配置生效。"
    echo "感谢使用本安装脚本！"
}

# 运行主函数
main "$@"