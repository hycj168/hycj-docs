# RustFS Docker 镜像使用指南 📁

## 🚀 简介

RustFS 是一个基于 Rust 语言开发的高性能分布式文件系统，专为容器化环境设计。本指南将详细介绍如何拉取和使用 RustFS Docker
镜像。

---

## 📥 镜像拉取

### 基础拉取命令

```bash
# 拉取指定版本的 RustFS 镜像
docker pull rustfs/rustfs:v1.0.0-alpha.72

# 验证镜像是否成功拉取
docker images rustfs/rustfs:v1.0.0-alpha.72

# 查看镜像详细信息
docker inspect rustfs/rustfs:v1.0.0-alpha.72
```

---

## 🔍 镜像信息详解

### 镜像标签说明

- `v1.0.0-alpha.72`: 这是 RustFS 的预发布版本，包含最新的实验性功能
- `alpha` 版本适合测试和开发环境使用
- 生产环境建议使用稳定版本（如 `v1.0.0`）

### 镜像架构支持

```bash
# 查看支持的架构
docker manifest inspect rustfs/rustfs:v1.0.0-alpha.72

# 拉取特定架构的镜像（例如 ARM64）
docker pull --platform linux/arm64 rustfs/rustfs:v1.0.0-alpha.72
```

---

## 🏃‍♂️ 快速开始

### 1. 核心端口说明

| 端口   | 说明        | 用途                           |
|------|-----------|------------------------------|
| 9000 | S3 API 端口 | 主要的 S3 兼容 API 接口，用于文件上传下载等操作 |
| 9001 | Web 控制台端口 | Web 管理界面访问端口，用于可视化管理和监控      |
| 7000 | Gossip 端口 | 集群节点间通信端口                    |
| 7001 | Raft 端口   | 分布式一致性协议端口                   |
| 9090 | 监控端口      | Prometheus 指标暴露端口            |

### 2. 基础运行命令

```bash
# 运行 RustFS 容器（基础配置）
docker run -d \\
  --name rustfs-server \\
  -p 9000:9000 \\
  -p 9001:9001 \\
  -v rustfs-data:/data \\
  rustfs/rustfs:v1.0.0-alpha.72
```

**端口说明：**

- `9000`: S3 API 端口，用于文件操作
- `9001`: Web 控制台端口，用于可视化界面访问

### 3. 企业级配置

```bash
# 企业级 RustFS 部署配置
docker run -d \\
  --name rustfs-prod \\
  --restart unless-stopped \\
  --network rustfs-network \\
  -p 9000:9000 \\
  -p 9001:9001 \\
  -p 7000:7000 \\
  -v rustfs-config:/etc/rustfs \\
  -v rustfs-data:/data \\
  -v rustfs-logs:/var/log/rustfs \\
  -e RUSTFS_NODE_ID=node1 \\
  -e RUSTFS_CLUSTER_ID=rustfs-cluster-1 \\
  -e RUSTFS_DATA_DIR=/data \\
  -e RUSTFS_LOG_LEVEL=info \\
  -e RUSTFS_MAX_CONNECTIONS=1000 \\
  -e RUSTFS_CACHE_SIZE=1GB \\
  -e RUSTFS_CONSOLE_ENABLE=true \\
  -e RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001 \\
  --memory=4g \\
  --cpus=2 \\
  --health-cmd="curl -f http://localhost:9000/minio/health/live || exit 1" \\
  --health-interval=30s \\
  --health-timeout=10s \\
  --health-retries=3 \\
  rustfs/rustfs:v1.0.0-alpha.72
```

---

## ⚙️ 环境变量配置

### 核心配置参数

| 环境变量                         | 说明     | 默认值                | 示例                               |
|------------------------------|--------|--------------------|----------------------------------|
| `RUSTFS_NODE_ID`             | 节点唯一标识 | `node-$(hostname)` | `rustfs-node-1`                  |
| `RUSTFS_CLUSTER_ID`          | 集群ID   | `default-cluster`  | `production-cluster`             |
| `RUSTFS_DATA_DIR`            | 数据存储目录 | `/data`            | `/var/lib/rustfs`                |
| `RUSTFS_LOG_LEVEL`           | 日志级别   | `info`             | `debug`, `info`, `warn`, `error` |
| `RUSTFS_MAX_CONNECTIONS`     | 最大连接数  | `1000`             | `5000`                           |
| `RUSTFS_CACHE_SIZE`          | 缓存大小   | `512MB`            | `2GB`                            |
| `RUSTFS_REPLICATION_FACTOR`  | 副本因子   | `3`                | `2`, `3`, `5`                    |
| `RUSTFS_CONSISTENCY_LEVEL`   | 一致性级别  | `quorum`           | `one`, `quorum`, `all`           |
| `RUSTFS_COMPRESSION_ENABLED` | 是否启用压缩 | `true`             | `true`, `false`                  |
| `RUSTFS_ENCRYPTION_ENABLED`  | 是否启用加密 | `false`            | `true`, `false`                  |

### 高级配置参数

```bash
#### 网络配置
```bash
RUSTFS_BIND_ADDRESS=0.0.0.0:9000
RUSTFS_ADVERTISE_ADDRESS=192.168.1.100:9000
RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001
RUSTFS_GOSSIP_PORT=7000
RUSTFS_RAFT_PORT=7001

# 存储配置
RUSTFS_STORAGE_BACKEND=local
RUSTFS_STORAGE_PATH=/data
RUSTFS_STORAGE_COMPRESSION=zstd
RUSTFS_STORAGE_ENCRYPTION=aes-256-gcm

# 性能调优
RUSTFS_WORKER_THREADS=8
RUSTFS_IO_THREADS=16
RUSTFS_BACKGROUND_THREADS=4
RUSTFS_MEMORY_LIMIT=2GB

# 监控配置
RUSTFS_METRICS_ENABLED=true
RUSTFS_METRICS_PORT=9090
RUSTFS_METRICS_PATH=/metrics
RUSTFS_TRACING_ENABLED=true
RUSTFS_TRACING_ENDPOINT=http://jaeger:14268/api/traces
```

---

## 📁 数据卷配置

### 1. 创建数据卷

```bash
# 创建 RustFS 数据卷
docker volume create rustfs-data

# 创建配置卷
docker volume create rustfs-config

# 创建日志卷
docker volume create rustfs-logs

# 查看数据卷信息
docker volume inspect rustfs-data
```

### 2. 挂载本地目录

```bash
# 使用本地目录作为数据存储
docker run -d \\
  --name rustfs-local \\
  -p 9000:9000 \\
  -p 9001:9001 \\
  -v /opt/rustfs/data:/data \\
  -v /opt/rustfs/config:/etc/rustfs \\
  -v /opt/rustfs/logs:/var/log/rustfs \\
  -e RUSTFS_CONSOLE_ENABLE=true \\
  -e RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001 \\
  rustfs/rustfs:v1.0.0-alpha.72
```

---

## 🌐 Docker Compose 部署

### 1. 单节点部署

```yaml
# docker-compose.yml
version: '3.8'

services:
  rustfs:
    image: rustfs/rustfs:v1.0.0-alpha.72
    container_name: rustfs-single
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - rustfs-data:/data
      - rustfs-config:/etc/rustfs
      - rustfs-logs:/var/log/rustfs
    environment:
      - RUSTFS_NODE_ID=single-node
      - RUSTFS_CLUSTER_ID=single-cluster
      - RUSTFS_LOG_LEVEL=info
      - RUSTFS_DATA_DIR=/data
      - RUSTFS_MAX_CONNECTIONS=1000
      - RUSTFS_CACHE_SIZE=1GB
      - RUSTFS_CONSOLE_ENABLE=true
      - RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001
    networks:
      - rustfs-network
    restart: unless-stopped
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:9000/minio/health/live" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.5'
        reservations:
          memory: 1G
          cpus: '0.5'

volumes:
  rustfs-data:
    driver: local
  rustfs-config:
    driver: local
  rustfs-logs:
    driver: local

networks:
  rustfs-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 2. 多节点集群部署

```yaml
# docker-compose-cluster.yml
version: '3.8'

services:
  rustfs-node1:
    image: rustfs/rustfs:v1.0.0-alpha.72
    container_name: rustfs-node1
    hostname: rustfs-node1
    ports:
      - "9001:9000"
      - "9004:9001"
      - "7001:7000"
    volumes:
      - rustfs-data-1:/data
      - rustfs-config-1:/etc/rustfs
      - rustfs-logs-1:/var/log/rustfs
    environment:
      - RUSTFS_NODE_ID=node1
      - RUSTFS_CLUSTER_ID=rustfs-cluster
      - RUSTFS_SEED_NODES=rustfs-node2:7000,rustfs-node3:7000
      - RUSTFS_LOG_LEVEL=info
      - RUSTFS_REPLICATION_FACTOR=3
      - RUSTFS_CONSISTENCY_LEVEL=quorum
      - RUSTFS_CONSOLE_ENABLE=true
      - RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001
    networks:
      - rustfs-cluster
    restart: unless-stopped
    depends_on:
      - rustfs-node2
      - rustfs-node3

  rustfs-node2:
    image: rustfs/rustfs:v1.0.0-alpha.72
    container_name: rustfs-node2
    hostname: rustfs-node2
    ports:
      - "9002:9000"
      - "9005:9001"
      - "7002:7000"
    volumes:
      - rustfs-data-2:/data
      - rustfs-config-2:/etc/rustfs
      - rustfs-logs-2:/var/log/rustfs
    environment:
      - RUSTFS_NODE_ID=node2
      - RUSTFS_CLUSTER_ID=rustfs-cluster
      - RUSTFS_SEED_NODES=rustfs-node1:7000,rustfs-node3:7000
      - RUSTFS_LOG_LEVEL=info
      - RUSTFS_REPLICATION_FACTOR=3
      - RUSTFS_CONSISTENCY_LEVEL=quorum
      - RUSTFS_CONSOLE_ENABLE=true
      - RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001
    networks:
      - rustfs-cluster
    restart: unless-stopped

  rustfs-node3:
    image: rustfs/rustfs:v1.0.0-alpha.72
    container_name: rustfs-node3
    hostname: rustfs-node3
    ports:
      - "9003:9000"
      - "9006:9001"
      - "7003:7000"
    volumes:
      - rustfs-data-3:/data
      - rustfs-config-3:/etc/rustfs
      - rustfs-logs-3:/var/log/rustfs
    environment:
      - RUSTFS_NODE_ID=node3
      - RUSTFS_CLUSTER_ID=rustfs-cluster
      - RUSTFS_SEED_NODES=rustfs-node1:7000,rustfs-node2:7000
      - RUSTFS_LOG_LEVEL=info
      - RUSTFS_REPLICATION_FACTOR=3
      - RUSTFS_CONSISTENCY_LEVEL=quorum
      - RUSTFS_CONSOLE_ENABLE=true
      - RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001
    networks:
      - rustfs-cluster
    restart: unless-stopped

volumes:
  rustfs-data-1:
  rustfs-config-1:
  rustfs-logs-1:
  rustfs-data-2:
  rustfs-config-2:
  rustfs-logs-2:
  rustfs-data-3:
  rustfs-config-3:
  rustfs-logs-3:

networks:
  rustfs-cluster:
    driver: overlay
    attachable: true
```

---

## 🔧 集群管理

### 1. 初始化集群

```bash
# 启动第一个节点（种子节点）
docker run -d \\
  --name rustfs-seed \\
  --network rustfs-cluster \\
  -e RUSTFS_NODE_ID=seed-node \\
  -e RUSTFS_CLUSTER_ID=my-cluster \\
  -e RUSTFS_SEED_NODES= \\
  rustfs/rustfs:v1.0.0-alpha.72

# 获取种子节点地址
SEED_IP=$(docker inspect -f '{{.NetworkSettings.Networks.rustfs-cluster.IPAddress}}' rustfs-seed)
echo "种子节点地址: $SEED_IP:7000"
```

### 2. 添加节点到集群

```bash
# 添加工作节点
docker run -d \\
  --name rustfs-worker-1 \\
  --network rustfs-cluster \\
  -e RUSTFS_NODE_ID=worker-1 \\
  -e RUSTFS_CLUSTER_ID=my-cluster \\
  -e RUSTFS_SEED_NODES=$SEED_IP:7000 \\
  rustfs/rustfs:v1.0.0-alpha.72

# 添加更多节点
docker run -d \\
  --name rustfs-worker-2 \\
  --network rustfs-cluster \\
  -e RUSTFS_NODE_ID=worker-2 \\
  -e RUSTFS_CLUSTER_ID=my-cluster \\
  -e RUSTFS_SEED_NODES=$SEED_IP:7000 \\
  rustfs/rustfs:v1.0.0-alpha.72
```

### 3. 集群状态检查

```bash
# 检查集群状态
curl http://localhost:9000/v1/cluster/status

# 查看节点列表
curl http://localhost:9000/v1/cluster/nodes

# 检查数据分布
curl http://localhost:9000/v1/cluster/distribution
```

---

## 📊 监控与运维

### 1. 健康检查

```bash
# 容器健康检查
docker exec rustfs-prod curl -f http://localhost:8080/health

# 详细健康状态
docker exec rustfs-prod curl -f http://localhost:8080/health/detailed

# 集群健康状态
curl http://localhost:8080/v1/cluster/health
```

### 2. 性能监控

```bash
# 查看性能指标
curl http://localhost:8080/metrics

# Prometheus 格式指标
curl http://localhost:8080/metrics/prometheus

# 实时性能统计
curl http://localhost:8080/v1/stats
```

### 3. 日志管理

```bash
# 查看容器日志
docker logs -f rustfs-prod

# 查看特定级别日志
docker logs rustfs-prod | grep ERROR

# 导出日志
docker logs rustfs-prod > rustfs-logs-$(date +%Y%m%d).log

# 实时错误监控
docker logs -f rustfs-prod | grep --line-buffered ERROR | while read line; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"
    # 可以添加告警通知
    # send_alert "$line"
done
```

---

## 🔄 数据管理

### 1. 数据备份

```bash
# 创建数据备份
docker run --rm \\
  -v rustfs-data:/data \\
  -v $(pwd):/backup \\
  alpine \\
  tar czf /backup/rustfs-data-backup-$(date +%Y%m%d).tar.gz -C /data .

# 备份元数据
curl http://localhost:8080/v1/metadata/backup > metadata-backup-$(date +%Y%m%d).json
```

### 2. 数据恢复

```bash
# 恢复数据备份
docker run --rm \\
  -v rustfs-data:/data \\
  -v $(pwd):/backup \\
  alpine \\
  tar xzf /backup/rustfs-data-backup-20240101.tar.gz -C /data

# 恢复元数据
curl -X POST http://localhost:9000/v1/metadata/restore \
  -H "Content-Type: application/json" \
  -d @metadata-backup-20240101.json
```

---

## 🛠️ 故障排除

### 1. 常见问题

#### 容器启动失败

```bash
# 检查日志
docker logs rustfs-prod

# 检查配置
docker exec rustfs-prod cat /etc/rustfs/config.toml

# 检查端口冲突
netstat -tlnp | grep 9000
netstat -tlnp | grep 9001
```

#### 权限问题（Permission Denied）

**症状**: 日志中出现 `Permission denied (os error 13)` 错误

**原因**: RustFS 容器内进程没有足够的权限访问数据目录

**解决方案**:

1. **使用用户命名空间映射**（推荐）:

```bash
docker run -d \
  --name rustfs-prod \
  --user "$(id -u):$(id -g)" \
  -p 9000:9000 \
  -p 9001:9001 \
  -v rustfs-data:/data \
  -v rustfs-logs:/logs \
  -e RUSTFS_ROOT_USER=admin \
  -e RUSTFS_ROOT_PASSWORD=admin123 \
  -e RUSTFS_CONSOLE_ENABLE=true \
  -e RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001 \
  rustfs/rustfs:latest
```

2. **调整数据目录权限**:

```bash
# 创建数据目录并设置权限
mkdir -p /var/lib/rustfs/data
mkdir -p /var/lib/rustfs/logs
chmod -R 755 /var/lib/rustfs

# 使用主机目录挂载
docker run -d \
  --name rustfs-prod \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /var/lib/rustfs/data:/data \
  -v /var/lib/rustfs/logs:/logs \
  -e RUSTFS_ROOT_USER=admin \
  -e RUSTFS_ROOT_PASSWORD=admin123 \
  -e RUSTFS_CONSOLE_ENABLE=true \
  -e RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001 \
  rustfs/rustfs:v1.0.0-alpha.72
```

3. **使用初始化容器设置权限**:

```bash
# 先运行权限设置容器
docker run --rm \
  -v rustfs-data:/data \
  -v rustfs-logs:/logs \
  alpine:latest \
  sh -c "chown -R 1000:1000 /data /logs && chmod -R 755 /data /logs"

# 然后再启动 RustFS 容器
docker run -d \
  --name rustfs-prod \
  -p 9000:9000 \
  -p 9001:9001 \
  -v rustfs-data:/data \
  -v rustfs-logs:/logs \
  -e RUSTFS_ROOT_USER=admin \
  -e RUSTFS_ROOT_PASSWORD=admin123 \
  -e RUSTFS_CONSOLE_ENABLE=true \
  -e RUSTFS_CONSOLE_ADDRESS=0.0.0.0:9001 \
  rustfs/rustfs:v1.0.0-alpha.72
```

#### 集群连接问题

```bash
# 检查网络连接
docker exec rustfs-prod ping rustfs-seed-node

# 检查端口连通性
docker exec rustfs-prod nc -zv rustfs-seed-node 7000

# 检查API端口连通性
docker exec rustfs-prod nc -zv rustfs-seed-node 9000

# 检查控制台端口连通性
docker exec rustfs-prod nc -zv rustfs-seed-node 9001

# 检查防火墙设置
iptables -L -n | grep -E "(7000|9000|9001)"
```

#### 性能问题

```bash
# 检查资源使用
docker stats rustfs-prod

# 检查磁盘空间
docker exec rustfs-prod df -h

# 检查内存使用
docker exec rustfs-prod free -m

# 检查端口监听状态
docker exec rustfs-prod netstat -tlnp | grep 9000
docker exec rustfs-prod netstat -tlnp | grep 9001
```

### 2. 调试工具

```bash
# 进入容器调试
docker exec -it rustfs-prod /bin/bash

# 检查进程
docker exec rustfs-prod ps aux

# 检查网络连接
docker exec rustfs-prod netstat -tlnp

# 检查文件系统
docker exec rustfs-prod ls -la /data

# 检查配置文件
docker exec rustfs-prod find /etc -name "*.toml" -exec cat {} \;
```

---

## 🔐 安全配置

### 1. 访问控制

```bash
# 启用认证
docker run -d \\
  -e RUSTFS_AUTH_ENABLED=true \\
  -e RUSTFS_AUTH_TYPE=jwt \\
  -e RUSTFS_JWT_SECRET=your-secret-key \\
  -e RUSTFS_ADMIN_USER=admin \\
  -e RUSTFS_ADMIN_PASSWORD=secure-password \\
  rustfs/rustfs:v1.0.0-alpha.72
```

### 2. TLS/SSL 配置

```bash
# 启用 TLS
docker run -d \\
  -v /path/to/certs:/etc/rustfs/certs \\
  -e RUSTFS_TLS_ENABLED=true \\
  -e RUSTFS_TLS_CERT_PATH=/etc/rustfs/certs/server.crt \\
  -e RUSTFS_TLS_KEY_PATH=/etc/rustfs/certs/server.key \\
  -e RUSTFS_TLS_CA_PATH=/etc/rustfs/certs/ca.crt \\
  rustfs/rustfs:v1.0.0-alpha.72
```

### 3. 网络隔离

```bash
# 创建隔离网络
docker network create --internal rustfs-internal

# 运行在内网
docker run -d \\
  --network rustfs-internal \\
  --publish 8080:8080 \\
  rustfs/rustfs:v1.0.0-alpha.72
```

---

## 📈 性能调优

### 1. 内存优化

```bash
# 调整内存参数
docker run -d \\
  -e RUSTFS_CACHE_SIZE=2GB \\
  -e RUSTFS_BUFFER_SIZE=64MB \\
  -e RUSTFS_MEMORY_LIMIT=4GB \\
  --memory=8g \\
  --memory-swap=16g \\
  rustfs/rustfs:v1.0.0-alpha.72
```

### 2. I/O 优化

```bash
# 优化 I/O 性能
docker run -d \\
  -e RUSTFS_IO_THREADS=32 \\
  -e RUSTFS_BACKGROUND_THREADS=8 \\
  -e RUSTFS_SYNC_INTERVAL=1000 \\
  --device-read-bps /dev/sda:100mb \\
  --device-write-bps /dev/sda:100mb \\
  rustfs/rustfs:v1.0.0-alpha.72
```

### 3. 网络优化

```bash
# 优化网络参数
docker run -d \\
  -e RUSTFS_NETWORK_THREADS=16 \\
  -e RUSTFS_CONNECTION_TIMEOUT=30s \\
  -e RUSTFS_KEEPALIVE_INTERVAL=60s \\
  --network-opt com.docker.network.driver.mtu=1450 \\
  rustfs/rustfs:v1.0.0-alpha.72
```

---

## 🚀 升级与维护

### 1. 滚动升级

```bash
# 备份数据
docker exec rustfs-prod curl -f http://localhost:8080/v1/metadata/backup > backup-$(date +%Y%m%d).json

# 停止旧版本
docker stop rustfs-prod

# 拉取新版本
docker pull rustfs/rustfs:v1.0.0-alpha.73

# 启动新版本
docker run -d \\
  --name rustfs-prod-new \\
  # ... 相同的配置参数 ...
  rustfs/rustfs:v1.0.0-alpha.73

# 验证新版本
curl http://localhost:8080/health

# 删除旧容器
docker rm rustfs-prod
```

### 2. 配置更新

```bash
# 更新配置
docker exec rustfs-prod kill -HUP 1

# 动态配置重载
curl -X POST http://localhost:9000/v1/config/reload \
  -H "Content-Type: application/json" \
  -d @new-config.json
```

---

## 📚 API 使用示例

### 1. 基本文件操作

```bash
# 上传文件
curl -X POST http://localhost:9000/v1/files/upload \
  -F "file=@local-file.txt" \
  -F "path=/remote/path/file.txt"

# 下载文件
curl -O http://localhost:9000/v1/files/download?path=/remote/path/file.txt

# 删除文件
curl -X DELETE http://localhost:9000/v1/files/delete?path=/remote/path/file.txt

# 列出文件
curl http://localhost:8080/v1/files/list?path=/remote/path
```

### 2. 集群管理 API

```bash
# 查看节点状态
curl http://localhost:8080/v1/cluster/nodes

# 添加节点
curl -X POST http://localhost:8080/v1/cluster/nodes \
  -H "Content-Type: application/json" \
  -d '{"node_id": "new-node", "address": "192.168.1.101:7000"}'

# 移除节点
curl -X DELETE http://localhost:8080/v1/cluster/nodes/new-node

# 重新平衡数据
curl -X POST http://localhost:8080/v1/cluster/rebalance
```

---

## 🔧 实用脚本

### 1. 集群部署脚本

```bash
#!/bin/bash
# RustFS 集群部署脚本

# 配置参数
CLUSTER_NAME="rustfs-cluster"
NODE_COUNT=3
NETWORK_NAME="rustfs-cluster"
IMAGE="rustfs/rustfs:v1.0.0-alpha.72"

# 创建网络
echo "创建集群网络..."
docker network create --driver overlay --attachable $NETWORK_NAME

# 启动种子节点
echo "启动种子节点..."
docker run -d \\
  --name rustfs-seed \\
  --network $NETWORK_NAME \\
  -e RUSTFS_NODE_ID=seed \\
  -e RUSTFS_CLUSTER_ID=$CLUSTER_NAME \\
  -e RUSTFS_SEED_NODES= \\
  $IMAGE

# 等待种子节点启动
sleep 30

# 获取种子节点地址
SEED_IP=$(docker inspect -f '{{.NetworkSettings.Networks.'$NETWORK_NAME'.IPAddress}}' rustfs-seed)
echo "种子节点地址: $SEED_IP:7000"

# 启动工作节点
echo "启动工作节点..."
for i in $(seq 1 $NODE_COUNT); do
    docker run -d \\
      --name rustfs-worker-$i \\
      --network $NETWORK_NAME \\
      -e RUSTFS_NODE_ID=worker-$i \\
      -e RUSTFS_CLUSTER_ID=$CLUSTER_NAME \\
      -e RUSTFS_SEED_NODES=$SEED_IP:7000 \\
      $IMAGE
    echo "工作节点 $i 已启动"
done

# 检查集群状态
echo "检查集群状态..."
sleep 60
curl http://localhost:9000/v1/cluster/status

echo "集群部署完成！"
```

### 2. 监控脚本

```bash
#!/bin/bash
# RustFS 监控脚本

# 配置参数
RUSTFS_URL="http://localhost:9000"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90

# 检查集群健康
check_cluster_health() {
    local health_status=$(curl -s $RUSTFS_URL/minio/health/live | jq -r '.status // "healthy"')
    if [ "$health_status" != "healthy" ]; then
        echo "⚠️ 集群健康状态异常: $health_status"
        return 1
    fi
    echo "✅ 集群健康状态正常"
    return 0
}

# 检查节点状态
check_node_status() {
    local nodes=$(curl -s $RUSTFS_URL/minio/v1/cluster/nodes | jq -r '.nodes[] // empty')
    local failed_nodes=0
    
    if [ -z "$nodes" ]; then
        echo "ℹ️ 使用基础健康检查"
        return 0
    fi
    
    echo "$nodes" | while read node; do
        local node_id=$(echo $node | jq -r '.id // "unknown"')
        local node_status=$(echo $node | jq -r '.status // "unknown"')
        
        if [ "$node_status" != "online" ]; then
            echo "⚠️ 节点 $node_id 状态异常: $node_status"
            ((failed_nodes++))
        else
            echo "✅ 节点 $node_id 状态正常"
        fi
    done
    
    if [ $failed_nodes -gt 0 ]; then
        echo "❌ 有 $failed_nodes 个节点异常"
        return 1
    fi
    
    return 0
}

# 检查资源使用
check_resource_usage() {
    local stats=$(curl -s $RUSTFS_URL/minio/v1/stats 2>/dev/null || echo '{}')
    
    local cpu_usage=$(echo $stats | jq -r '.cpu_usage_percent // "N/A"')
    local memory_usage=$(echo $stats | jq -r '.memory_usage_percent // "N/A"')
    local disk_usage=$(echo $stats | jq -r '.disk_usage_percent // "N/A"')
    
    echo "📊 资源使用情况:"
    echo "  CPU: ${cpu_usage}%"
    echo "  内存: ${memory_usage}%"
    echo "  磁盘: ${disk_usage}%"
    
    # 检查阈值（仅当数值可用时）
    if [ "$cpu_usage" != "N/A" ] && (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        echo "⚠️ CPU 使用率超过阈值: $cpu_usage% > $ALERT_THRESHOLD_CPU%"
    fi
    
    if [ "$memory_usage" != "N/A" ] && (( $(echo "$memory_usage > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
        echo "⚠️ 内存使用率超过阈值: $memory_usage% > $ALERT_THRESHOLD_MEMORY%"
    fi
    
    if [ "$disk_usage" != "N/A" ] && (( $(echo "$disk_usage > $ALERT_THRESHOLD_DISK" | bc -l) )); then
        echo "⚠️ 磁盘使用率超过阈值: $disk_usage% > $ALERT_THRESHOLD_DISK%"
    fi
}

# 主监控循环
main() {
    echo "=== RustFS 集群监控 ==="
    echo "时间: $(date)"
    echo ""
    
    check_cluster_health
    check_node_status
    check_resource_usage
    
    echo ""
    echo "监控完成"
}

# 执行监控
main
```

---

## 📖 常见问题解答

### Q1: 镜像拉取失败怎么办？

```bash
# 检查网络连接
ping docker.io

# 检查 Docker 配置
docker info

# 尝试使用代理
docker pull --platform linux/amd64 rustfs/rustfs:v1.0.0-alpha.72

# 使用国内镜像源
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
```

### Q2: 容器启动后立即退出？

```bash
# 检查日志
docker logs rustfs-container

# 检查配置
docker exec rustfs-container cat /etc/rustfs/config.toml

# 检查端口冲突
netstat -tlnp | grep 8080

# 检查权限
docker exec rustfs-container ls -la /data
```

### Q3: 集群节点无法互相发现？

```bash
# 检查网络连接
docker exec rustfs-node1 ping rustfs-node2

# 检查端口开放
docker exec rustfs-node1 nc -zv rustfs-node2 7000

# 检查防火墙
docker exec rustfs-node1 iptables -L -n

# 检查配置
docker exec rustfs-node1 env | grep RUSTFS
```

### Q4: 性能调优建议？

```bash
# 增加内存
docker update --memory 8g rustfs-container

# 调整线程数
docker exec rustfs-container sed -i 's/worker_threads = 4/worker_threads = 16/' /etc/rustfs/config.toml

# 重启服务
docker restart rustfs-container
```

---

## 📚 相关资源

- [RustFS 官方文档](https://rustfs.io/docs)
- [RustFS GitHub 仓库](https://github.com/rustfs/rustfs)
- [RustFS Docker Hub](https://hub.docker.com/r/rustfs/rustfs)
- [RustFS 配置参考](https://rustfs.io/docs/configuration)
- [RustFS API 文档](https://rustfs.io/docs/api)

---

**💡 使用建议：**

1. **开发环境**：使用单节点部署，开启调试日志
2. **测试环境**：使用多节点集群，模拟生产环境
3. **生产环境**：使用集群部署，启用安全认证和监控
4. **定期备份**：设置自动备份策略，确保数据安全
5. **监控告警**：配置监控和告警系统，及时发现问题

**🎯 下一步学习：**

- 深入学习 RustFS 的分布式原理
- 了解数据分片和复制机制
- 学习性能调优和容量规划
- 掌握故障恢复和数据迁移