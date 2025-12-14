#!/bin/bash

# RustFS Docker 实战练习脚本
# 作者: Docker 教程系列
# 功能: 提供 RustFS Docker 镜像的实战练习

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 检查 Docker 环境
check_docker() {
    print_info "检查 Docker 环境..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker 服务未运行，请启动 Docker 服务"
        exit 1
    fi
    
    print_success "Docker 环境正常"
}

# 清理环境
cleanup() {
    print_header "清理环境"
    
    print_info "停止并删除所有 RustFS 容器..."
    docker ps -a | grep rustfs | awk '{print $1}' | xargs -r docker stop
    docker ps -a | grep rustfs | awk '{print $1}' | xargs -r docker rm
    
    print_info "删除 RustFS 相关网络..."
    docker network ls | grep rustfs | awk '{print $1}' | xargs -r docker network rm
    
    print_info "删除 RustFS 相关数据卷（可选）..."
    read -p "是否删除 RustFS 数据卷？(y/N): " delete_volumes
    if [[ $delete_volumes == "y" || $delete_volumes == "Y" ]]; then
        docker volume ls | grep rustfs | awk '{print $2}' | xargs -r docker volume rm
        print_success "数据卷已删除"
    else
        print_info "保留数据卷"
    fi
    
    print_success "环境清理完成"
}

# 练习 1: 基础镜像拉取和运行
practice_1_basic() {
    print_header "练习 1: RustFS 基础镜像拉取和运行"
    
    print_info "步骤 1: 拉取 RustFS 镜像..."
    docker pull rustfs/rustfs:v1.0.0-alpha.72
    
    if [ $? -eq 0 ]; then
        print_success "镜像拉取成功"
    else
        print_error "镜像拉取失败，请检查网络连接"
        exit 1
    fi
    
    print_info "步骤 2: 查看镜像信息..."
    docker images rustfs/rustfs:v1.0.0-alpha.72
    
    print_info "步骤 3: 运行基础容器..."
    docker run -d \\
      --name rustfs-basic \\
      --network rustfs-network \\
      --user "$(id -u):$(id -g)" \\
      -p 9000:9000 \\
      -p 9001:9001 \\
      -e RUSTFS_ROOT_USER=admin \\
      -e RUSTFS_ROOT_PASSWORD=admin123 \\
      -e RUSTFS_CONSOLE_ENABLE=true \\
      -e RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001 \\
      rustfs/rustfs:v1.0.0-alpha.72
    
    if [ $? -eq 0 ]; then
        print_success "容器启动成功"
    else
        print_error "容器启动失败"
        exit 1
    fi
    
    print_info "步骤 4: 等待服务启动..."
    sleep 30
    
    print_info "步骤 5: 检查服务状态..."
    if curl -f http://localhost:9000/minio/health/live &> /dev/null; then
        print_success "服务运行正常"
    else
        print_warning "服务可能还在启动中，请稍后再试"
    fi
    
    print_info "步骤 6: 查看容器日志..."
    docker logs --tail 20 rustfs-basic
    
    print_success "练习 1 完成！"
    read -p "按回车键继续..."
}

# 练习 2: 数据卷和网络配置
practice_2_volumes() {
    print_header "练习 2: 数据卷和网络配置"
    
    print_info "步骤 1: 创建数据卷..."
    docker volume create rustfs-data
    docker volume create rustfs-config
    docker volume create rustfs-logs
    
    print_success "数据卷创建完成"
    
    print_info "步骤 2: 创建网络..."
    docker network create rustfs-network
    
    print_success "网络创建完成"
    
    print_info "步骤 3: 运行带数据卷的容器..."
    docker run -d \\
      --name rustfs-with-volumes \\
      --network rustfs-network \\
      -p 9001:9000 \\
      -p 9002:9001 \\
      -v rustfs-data:/data \\
      -v rustfs-config:/etc/rustfs \\
      -v rustfs-logs:/var/log/rustfs \\
      -e RUSTFS_NODE_ID=volume-node \\
      -e RUSTFS_DATA_DIR=/data \\
      -e RUSTFS_LOG_LEVEL=info \\
      -e RUSTFS_CONSOLE_ENABLE=true \\
      -e RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001 \\
      rustfs/rustfs:v1.0.0-alpha.72
    
    print_success "带数据卷的容器启动成功"
    
    print_info "步骤 4: 验证数据卷挂载..."
    docker exec rustfs-with-volumes ls -la /data
    docker exec rustfs-with-volumes ls -la /etc/rustfs
    docker exec rustfs-with-volumes ls -la /var/log/rustfs
    
    print_info "步骤 5: 测试文件上传..."
    # 创建一个测试文件
    echo "Hello RustFS!" > test-file.txt
    
    # 上传文件（假设 API 支持）
    if curl -X POST http://localhost:8081/v1/files/upload \
      -F "file=@test-file.txt" \
      -F "path=/test/test-file.txt" &> /dev/null; then
        print_success "文件上传成功"
    else
        print_warning "文件上传功能可能需要额外配置"
    fi
    
    print_info "步骤 6: 查看数据卷内容..."
    docker exec rustfs-with-volumes find /data -type f -name "*test*" 2>/dev/null || echo "未找到测试文件"
    
    print_success "练习 2 完成！"
    read -p "按回车键继续..."
}

# 练习 3: 多节点集群部署
practice_3_cluster() {
    print_header "练习 3: 多节点集群部署"
    
    print_info "步骤 1: 创建集群网络..."
    docker network create --driver overlay --attachable rustfs-cluster
    
    print_success "集群网络创建完成"
    
    print_info "步骤 2: 启动种子节点..."
    docker run -d \\
      --name rustfs-seed \\
      --network rustfs-cluster \\
      --user "$(id -u):$(id -g)" \\
      -p 7001:7000 \\
      -e RUSTFS_NODE_ID=seed-node \\
      -e RUSTFS_CLUSTER_ID=practice-cluster \\
      -e RUSTFS_SEED_NODES= \\
      rustfs/rustfs:v1.0.0-alpha.72
    
    print_info "等待种子节点启动..."
    sleep 30
    
    print_info "步骤 3: 获取种子节点地址..."
    SEED_IP=$(docker inspect -f '{{.NetworkSettings.Networks.rustfs-cluster.IPAddress}}' rustfs-seed)
    echo "种子节点 IP: $SEED_IP"
    
    print_info "步骤 4: 启动工作节点..."
    for i in {1..2}; do
        docker run -d \\
          --name rustfs-worker-$i \\
          --network rustfs-cluster \\
          --user "$(id -u):$(id -g)" \\
          -p $((7001+i)):7000 \\
          -e RUSTFS_NODE_ID=worker-$i \\
          -e RUSTFS_CLUSTER_ID=practice-cluster \\
          -e RUSTFS_SEED_NODES=$SEED_IP:7000 \\
          rustfs/rustfs:v1.0.0-alpha.72
        
        print_success "工作节点 $i 启动成功"
        sleep 10
    done
    
    print_info "步骤 5: 检查集群状态..."
    sleep 20
    
    # 尝试检查集群状态
    if command -v curl &> /dev/null; then
        print_info "使用 curl 检查集群状态..."
        curl -s http://localhost:9000/minio/v1/cluster/status | head -20 || print_warning "集群状态 API 可能不可用"
    else
        print_warning "curl 未安装，跳过 API 检查"
    fi
    
    print_info "步骤 6: 查看所有容器状态..."
    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}" | grep rustfs
    
    print_success "练习 3 完成！"
    read -p "按回车键继续..."
}

# 练习 4: 监控和运维
practice_4_monitoring() {
    print_header "练习 4: 监控和运维"
    
    print_info "步骤 1: 容器资源监控..."
    docker stats --no-stream --format "table {{.Name}}\\t{{.CPUPerc}}\\t{{.MemUsage}}\\t{{.NetIO}}" | grep rustfs
    
    print_info "步骤 2: 查看容器详细信息..."
    docker inspect rustfs-with-volumes | jq -r '.[0] | {
        "容器ID": .Id[:12],
        "创建时间": .Created,
        "状态": .State.Status,
        "镜像": .Config.Image,
        "网络模式": .HostConfig.NetworkMode,
        "挂载卷": .Mounts | length
    }'
    
    print_info "步骤 3: 日志分析..."
    echo "最近的错误日志:"
    docker logs rustfs-with-volumes 2>&1 | grep -i error | tail -5 || echo "未找到错误日志"
    
    print_info "步骤 4: 健康检查..."
    # 尝试健康检查
    if docker exec rustfs-with-volumes curl -f http://localhost:9000/minio/health/live &> /dev/null; then
        print_success "健康检查通过"
    else
        print_warning "健康检查失败或 API 不可用"
    fi
    
    print_info "步骤 5: 数据备份演示..."
    # 创建备份目录
    mkdir -p rustfs-backup
    
    # 备份数据卷
    docker run --rm \\
      -v rustfs-data:/data \\
      -v $(pwd)/rustfs-backup:/backup \\
      alpine \\
      tar czf /backup/rustfs-data-$(date +%Y%m%d-%H%M%S).tar.gz -C /data . \\n      2>/dev/null && print_success "数据备份完成" || print_warning "数据备份失败"
    
    print_info "步骤 6: 性能测试..."
    # 简单的压力测试（如果 API 可用）
    for i in {1..10}; do
        echo "测试请求 $i"
        curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" http://localhost:9000/minio/health/live || echo "请求失败"
        sleep 1
    done
    
    print_success "练习 4 完成！"
    read -p "按回车键继续..."
}

# 练习 5: 故障排除
practice_5_troubleshooting() {
    print_header "练习 5: 故障排除"
    
    print_info "步骤 1: 模拟故障场景..."
    
    # 场景 1: 停止一个节点
    print_info "停止工作节点 1..."
    docker stop rustfs-worker-1
    
    print_info "检查集群状态..."
    docker ps --format "table {{.Names}}\\t{{.Status}}" | grep rustfs
    
    # 场景 2: 网络问题
    print_info "断开网络连接..."
    docker network disconnect rustfs-cluster rustfs-worker-2
    
    sleep 10
    
    print_info "重新连接网络..."
    docker network connect rustfs-cluster rustfs-worker-2
    
    # 场景 3: 资源限制
    print_info "模拟资源限制..."
    docker update --memory 256m --cpus 0.5 rustfs-with-volumes
    
    print_info "检查资源限制效果..."
    docker stats --no-stream rustfs-with-volumes
    
    print_info "步骤 2: 故障诊断..."
    
    # 检查日志
    echo "查看错误日志:"
    docker logs rustfs-worker-1 2>&1 | grep -i error | tail -3 || echo "无错误日志"
    
    # 检查网络
    echo "检查网络连接:"
    docker exec rustfs-seed ping -c 2 rustfs-worker-2 2>/dev/null && print_success "网络连接正常" || print_error "网络连接失败"
    
    # 检查资源
    echo "检查资源使用:"
    docker exec rustfs-with-volumes free -m 2>/dev/null || echo "无法获取内存信息"
    
    print_info "步骤 3: 恢复服务..."
    docker start rustfs-worker-1
    docker update --memory 2g --cpus 1.5 rustfs-with-volumes
    
    print_success "故障排除练习完成！"
    read -p "按回车键继续..."
}

# 练习 6: 性能调优
practice_6_optimization() {
    print_header "练习 6: 性能调优"
    
    print_info "步骤 1: 创建高性能配置..."
    
    # 创建优化的容器
    docker run -d \\
      --name rustfs-optimized \\
      --network rustfs-network \\
      --user "$(id -u):$(id -g)" \\
      -p 9002:9000 \\
      -p 9003:9001 \\
      -v rustfs-data:/data \\
      -e RUSTFS_NODE_ID=optimized-node \\
      -e RUSTFS_LOG_LEVEL=warn \\
      -e RUSTFS_CACHE_SIZE=2GB \\
      -e RUSTFS_MAX_CONNECTIONS=5000 \\
      -e RUSTFS_WORKER_THREADS=8 \\
      -e RUSTFS_IO_THREADS=16 \\
      -e RUSTFS_CONSOLE_ENABLE=true \\
      -e RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001 \\
      --memory=4g \\
      --cpus=2 \\
      --cpu-shares=1024 \\
      rustfs/rustfs:v1.0.0-alpha.72
    
    print_success "优化容器启动成功"
    
    print_info "步骤 2: 性能对比测试..."
    
    echo "原始容器性能:"
    docker stats --no-stream rustfs-with-volumes
    
    echo "优化容器性能:"
    docker stats --no-stream rustfs-optimized
    
    print_info "步骤 3: I/O 性能测试..."
    
    # 测试磁盘 I/O
    docker exec rustfs-with-volumes dd if=/dev/zero of=/data/test-file bs=1M count=100 2>&1 | grep -oP '\d+\.?\d* MB/s' || echo "I/O 测试失败"
    docker exec rustfs-optimized dd if=/dev/zero of=/data/test-file bs=1M count=100 2>&1 | grep -oP '\d+\.?\d* MB/s' || echo "I/O 测试失败"
    
    print_info "步骤 4: 网络性能测试..."
    
    # 测试网络延迟
    echo "网络延迟测试:"
    for container in rustfs-with-volumes rustfs-optimized; do
        echo "容器 $container:"
        docker exec $container ping -c 2 google.com 2>/dev/null | grep "avg" || echo "网络测试失败"
    done
    
    print_info "步骤 5: 内存使用优化..."
    
    # 对比内存使用
    echo "内存使用对比:"
    for container in rustfs-with-volumes rustfs-optimized; do
        mem_usage=$(docker stats --no-stream --format "{{.MemUsage}}" $container)
        echo "$container: $mem_usage"
    done
    
    print_success "性能调优练习完成！"
    read -p "按回车键继续..."
}

# 总结和清理
summary_and_cleanup() {
    print_header "实战练习总结"
    
    echo -e "${GREEN}🎉 恭喜完成所有 RustFS Docker 实战练习！${NC}"
    echo ""
    echo "练习内容回顾:"
    echo "1. ✅ RustFS 基础镜像拉取和运行"
    echo "2. ✅ 数据卷和网络配置"
    echo "3. ✅ 多节点集群部署"
    echo "4. ✅ 监控和运维"
    echo "5. ✅ 故障排除"
    echo "6. ✅ 性能调优"
    echo ""
    echo "掌握的技能:"
    echo "- Docker 容器生命周期管理"
    echo "- 数据卷和网络配置"
    echo "- 集群部署和管理"
    echo "- 监控和故障排除"
    echo "- 性能优化和调优"
    echo ""
    
    read -p "是否清理所有练习容器？(y/N): " cleanup_confirm
    if [[ $cleanup_confirm == "y" || $cleanup_confirm == "Y" ]]; then
        cleanup
    fi
    
    print_success "实战练习全部完成！感谢参与！"
}

# 主菜单
main_menu() {
    while true; do
        print_header "RustFS Docker 实战练习"
        
        echo "请选择练习内容:"
        echo "1. 基础镜像拉取和运行"
        echo "2. 数据卷和网络配置"
        echo "3. 多节点集群部署"
        echo "4. 监控和运维"
        echo "5. 故障排除"
        echo "6. 性能调优"
        echo "7. 完整练习（全部执行）"
        echo "8. 清理环境"
        echo "9. 退出"
        echo ""
        
        read -p "请输入选项 (1-9): " choice
        
        case $choice in
            1)
                check_docker
                practice_1_basic
                ;;
            2)
                check_docker
                practice_2_volumes
                ;;
            3)
                check_docker
                practice_3_cluster
                ;;
            4)
                check_docker
                practice_4_monitoring
                ;;
            5)
                check_docker
                practice_5_troubleshooting
                ;;
            6)
                check_docker
                practice_6_optimization
                ;;
            7)
                check_docker
                print_header "完整练习模式"
                echo "将依次执行所有练习..."
                sleep 2
                
                practice_1_basic
                practice_2_volumes
                practice_3_cluster
                practice_4_monitoring
                practice_5_troubleshooting
                practice_6_optimization
                summary_and_cleanup
                ;;
            8)
                cleanup
                ;;
            9)
                print_success "感谢使用 RustFS Docker 实战练习脚本！"
                exit 0
                ;;
            *)
                print_error "无效选项，请重新输入"
                ;;
        esac
        
        echo ""
        read -p "按回车键返回主菜单..."
    done
}

# 脚本入口
main() {
    # 检查是否有参数
    if [ $# -eq 0 ]; then
        main_menu
    else
        case $1 in
            "cleanup")
                cleanup
                ;;
            "basic")
                check_docker
                practice_1_basic
                ;;
            "volumes")
                check_docker
                practice_2_volumes
                ;;
            "cluster")
                check_docker
                practice_3_cluster
                ;;
            "monitoring")
                check_docker
                practice_4_monitoring
                ;;
            "troubleshooting")
                check_docker
                practice_5_troubleshooting
                ;;
            "optimization")
                check_docker
                practice_6_optimization
                ;;
            "all")
                check_docker
                practice_1_basic
                practice_2_volumes
                practice_3_cluster
                practice_4_monitoring
                practice_5_troubleshooting
                practice_6_optimization
                summary_and_cleanup
                ;;
            *)
                echo "用法: $0 [cleanup|basic|volumes|cluster|monitoring|troubleshooting|optimization|all]"
                echo "或者直接运行: $0 (进入交互式菜单)"
                exit 1
                ;;
        esac
    fi
}

# 如果脚本被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi