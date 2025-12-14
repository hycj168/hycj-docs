#!/bin/bash
# SSH连接测试脚本 - 测试与远程服务器的连接

# 服务器配置
SERVER_IP="192.168.157.129"
DEFAULT_USER="root"

# 显示使用方法
show_usage() {
    echo "SSH连接测试脚本"
    echo "用法: $0 [用户名]"
    echo ""
    echo "测试与远程服务器的连接状态"
    echo ""
    echo "示例:"
    echo "  $0          # 使用默认用户测试连接"
    echo "  $0 ubuntu   # 使用ubuntu用户测试连接"
}

# 测试SSH连接
test_ssh_connection() {
    local username="$1"
    local server="${username}@${SERVER_IP}"
    
    echo "正在测试SSH连接..."
    echo "服务器: $server"
    echo ""
    
    # 使用timeout命令设置超时时间
    if command -v timeout &> /dev/null; then
        # 5秒超时
        timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes "$server" "echo '连接成功！'" 2>/dev/null
        local result=$?
    else
        # 没有timeout命令，直接测试
        ssh -o ConnectTimeout=3 -o BatchMode=yes "$server" "echo '连接成功！'" 2>/dev/null
        local result=$?
    fi
    
    if [ $result -eq 0 ]; then
        echo "✅ SSH连接测试通过！"
        echo "可以正常连接到服务器 $SERVER_IP"
        return 0
    else
        echo "❌ SSH连接测试失败！"
        echo "无法连接到服务器 $SERVER_IP"
        echo ""
        echo "可能的原因："
        echo "  1. 服务器IP地址不正确"
        echo "  2. SSH服务未启动"
        echo "  3. 防火墙阻止了SSH连接"
        echo "  4. 用户名或密码错误"
        echo "  5. SSH密钥认证失败"
        echo ""
        echo "建议检查："
        echo "  - 确认服务器IP地址: $SERVER_IP"
        echo "  - 确认SSH服务正在运行"
        echo "  - 检查防火墙设置"
        echo "  - 确认用户名和密码"
        return 1
    fi
}

# 检查SSH客户端
check_ssh_client() {
    if ! command -v ssh &> /dev/null; then
        echo "错误: 未找到SSH客户端"
        echo "请安装SSH客户端:"
        echo "  Windows: 使用Git Bash或安装OpenSSH"
        echo "  安装OpenSSH命令: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
        exit 1
    fi
}

# 主函数
main() {
    check_ssh_client
    
    # 获取用户名参数
    local username="${1:-$DEFAULT_USER}"
    
    # 测试连接
    test_ssh_connection "$username"
}

# 如果传入了-h或--help参数，显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# 运行主函数
main "$@"