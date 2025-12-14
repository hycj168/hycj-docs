#!/bin/bash
# 远程命令执行脚本 - 在远程服务器上执行命令

# 服务器配置
SERVER_IP="192.168.157.129"
DEFAULT_USER="root"

# 显示使用方法
show_usage() {
    echo "远程命令执行脚本"
    echo "用法: $0 [命令] [用户名]"
    echo ""
    echo "参数:"
    echo "  命令     - 要在远程服务器上执行的命令"
    echo "  用户名   - 可选，默认用户: $DEFAULT_USER"
    echo ""
    echo "示例:"
    echo "  $0 'ls -la /opt'                    # 查看/opt目录"
    echo "  $0 'df -h'                          # 查看磁盘空间"
    echo "  $0 'docker ps'                      # 查看Docker容器"
    echo "  $0 'uptime' ubuntu                  # 使用ubuntu用户执行"
    echo "  $0 'cat /etc/os-release'            # 查看系统信息"
    echo ""
    echo "常用命令:"
    echo "  系统信息: uname -a, cat /etc/os-release, uptime"
    echo "  磁盘空间: df -h, du -sh /opt/*"
    echo "  Docker: docker ps, docker images, docker system df"
    echo "  网络: ip addr, netstat -tulpn, ss -tulpn"
}

# 检查是否安装了SSH客户端
check_ssh_client() {
    if ! command -v ssh &> /dev/null; then
        echo "错误: 未找到SSH客户端"
        echo "请安装SSH客户端"
        exit 1
    fi
}

# 主函数
main() {
    check_ssh_client
    
    # 检查是否提供了命令
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    # 解析参数
    local command="$1"
    local username="${2:-$DEFAULT_USER}"
    
    echo "在远程服务器上执行命令..."
    echo "服务器IP: $SERVER_IP"
    echo "用户名: $username"
    echo "命令: $command"
    echo ""
    echo "========================================"
    
    # 执行远程命令
    ssh "${username}@${SERVER_IP}" "$command"
    
    echo ""
    echo "========================================"
    echo "命令执行完成"
}

# 如果传入了-h或--help参数，显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# 运行主函数
main "$@"