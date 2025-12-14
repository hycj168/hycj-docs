#!/bin/bash
# SSH连接脚本 - 用于连接远程服务器

# 服务器配置
SERVER_IP="192.168.157.129"
DEFAULT_USER="root"

# 显示使用方法
show_usage() {
    echo "SSH连接脚本"
    echo "用法: $0 [用户名]"
    echo "默认用户: $DEFAULT_USER"
    echo "服务器IP: $SERVER_IP"
    echo ""
    echo "示例:"
    echo "  $0          # 使用默认用户连接"
    echo "  $0 ubuntu   # 使用ubuntu用户连接"
    echo "  $0 root     # 使用root用户连接"
}

# 检查是否安装了SSH客户端
check_ssh_client() {
    if ! command -v ssh &> /dev/null; then
        echo "错误: 未找到SSH客户端"
        echo "请安装SSH客户端:"
        echo "  Windows: 安装OpenSSH或使用PuTTY"
        echo "  Ubuntu/Debian: sudo apt install openssh-client"
        echo "  CentOS/RHEL: sudo yum install openssh-clients"
        exit 1
    fi
}

# 主函数
main() {
    check_ssh_client
    
    # 获取用户名参数
    local username="${1:-$DEFAULT_USER}"
    
    echo "正在连接到服务器..."
    echo "服务器IP: $SERVER_IP"
    echo "用户名: $username"
    echo ""
    
    # 执行SSH连接
    ssh "${username}@${SERVER_IP}"
}

# 如果传入了-h或--help参数，显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# 运行主函数
main "$@"