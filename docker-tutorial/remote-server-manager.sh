#!/bin/bash
# 远程服务器管理工具 - 综合SSH管理脚本

# 服务器配置
SERVER_IP="192.168.157.129"
DEFAULT_USER="root"

# 显示主菜单
show_main_menu() {
    clear
    echo "========================================"
    echo "  远程服务器管理工具"
    echo "  服务器: $SERVER_IP"
    echo "========================================"
    echo ""
    echo "1. 测试SSH连接"
    echo "2. 连接服务器（交互式）"
    echo "3. 执行系统检查"
    echo "4. 部署Docker环境"
    echo "5. 创建Docker卷目录"
    echo "6. 查看系统状态"
    echo "7. 查看Docker状态"
    echo "8. 查看磁盘空间"
    echo "9. 重启服务器"
    echo "10. 关机服务器"
    echo ""
    echo "0. 退出"
    echo ""
    echo -n "请选择操作 [0-10]: "
}

# 测试连接
test_connection() {
    echo "正在测试SSH连接..."
    bash ./test-ssh-connection.sh
    read -p "按回车键继续..."
}

# 连接服务器
connect_server() {
    echo "正在连接到服务器..."
    bash ./ssh-connect.sh
}

# 系统检查
system_check() {
    echo "执行系统检查..."
    bash ./ssh-execute.sh "uname -a && cat /etc/os-release && uptime && df -h && free -h"
    read -p "按回车键继续..."
}

# 部署Docker
deploy_docker() {
    echo "部署Docker环境..."
    bash ./deploy-remote-docker.sh full
    read -p "按回车键继续..."
}

# 创建Docker卷目录
create_volumes() {
    echo "创建Docker卷目录..."
    bash ./ssh-execute.sh "cd /tmp && wget -O enterprise-docker-volumes-setup.sh 'https://raw.githubusercontent.com/your-repo/docker-tutorial/main/enterprise-docker-volumes-setup.sh' && bash enterprise-docker-volumes-setup.sh"
    read -p "按回车键继续..."
}

# 查看系统状态
view_system_status() {
    echo "查看系统状态..."
    bash ./ssh-execute.sh "top -bn1 | head -20"
    read -p "按回车键继续..."
}

# 查看Docker状态
view_docker_status() {
    echo "查看Docker状态..."
    bash ./ssh-execute.sh "docker ps && docker system df"
    read -p "按回车键继续..."
}

# 查看磁盘空间
view_disk_space() {
    echo "查看磁盘空间..."
    bash ./ssh-execute.sh "df -h && du -sh /opt/* 2>/dev/null || echo '/opt目录不存在'"
    read -p "按回车键继续..."
}

# 重启服务器
restart_server() {
    echo "警告：这将重启服务器！"
    read -p "确定要重启服务器吗？ [y/N]: " confirm
    if [[ $confirm == [yY] ]]; then
        bash ./ssh-execute.sh "sudo reboot"
    else
        echo "取消重启操作"
        read -p "按回车键继续..."
    fi
}

# 关机服务器
shutdown_server() {
    echo "警告：这将关闭服务器！"
    read -p "确定要关闭服务器吗？ [y/N]: " confirm
    if [[ $confirm == [yY] ]]; then
        bash ./ssh-execute.sh "sudo shutdown -h now"
    else
        echo "取消关机操作"
        read -p "按回车键继续..."
    fi
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if ! command -v ssh &> /dev/null; then
        missing_deps+=("ssh")
    fi
    
    if ! command -v bash &> /dev/null; then
        missing_deps+=("bash")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "错误：缺少必要的依赖: ${missing_deps[*]}"
        echo "请安装缺失的工具"
        exit 1
    fi
}

# 主函数
main() {
    check_dependencies
    
    while true; do
        show_main_menu
        read -r choice
        
        case $choice in
            1) test_connection ;;
            2) connect_server ;;
            3) system_check ;;
            4) deploy_docker ;;
            5) create_volumes ;;
            6) view_system_status ;;
            7) view_docker_status ;;
            8) view_disk_space ;;
            9) restart_server ;;
            10) shutdown_server ;;
            0) 
                echo "退出程序..."
                exit 0
                ;;
            *)
                echo "无效的选择，请重新输入"
                read -p "按回车键继续..."
                ;;
        esac
    done
}

# 如果传入了-h或--help参数，显示帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "远程服务器管理工具"
    echo "用法: $0"
    echo ""
    echo "这是一个交互式菜单工具，用于管理远程服务器"
    echo "支持的操作包括：连接测试、系统检查、Docker部署等"
    exit 0
fi

# 运行主函数
main "$@"