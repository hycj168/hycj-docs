# Ubuntu 24.04 LTS 企业级Docker安装详细教程

> 当前北京时间：2025年12月06日
>
> 本教程基于Ubuntu 24.04 LTS (Noble Numbat)系统，提供企业级Docker CE安装和配置方案

## 目录

1. [系统要求和准备](#系统要求和准备)
2. [卸载旧版本Docker](#卸载旧版本docker)
3. [安装必要依赖包](#安装必要依赖包)
4. [配置Docker官方仓库](#配置docker官方仓库)
5. [安装Docker CE](#安装docker-ce)
6. [企业级配置优化](#企业级配置优化)
7. [Docker Compose安装](#docker-compose安装)
8. [安全配置和最佳实践](#安全配置和最佳实践)
9. [性能监控和调优](#性能监控和调优)
10. [故障排除和维护](#故障排除和维护)

## 系统要求和准备

### 系统要求

- **操作系统**：Ubuntu 24.04 LTS (Noble Numbat)
- **架构**：x86_64 或 arm64
- **内核版本**：建议 5.15 或更高版本
- **内存**：最小 2GB，推荐 4GB 或更多
- **存储**：最小 20GB 可用空间，推荐使用 SSD

### 系统更新

```bash
# 更新系统软件包索引
sudo apt update

# 升级所有已安装的软件包
sudo apt upgrade -y

# 安装必要的系统工具
sudo apt install -y curl wget gnupg lsb-release ca-certificates software-properties-common apt-transport-https
```

### 验证系统版本

```bash
# 检查Ubuntu版本
lsb_release -a

# 检查内核版本
uname -r

# 检查系统架构
uname -m
```

## 卸载旧版本Docker

在安装新版本之前，需要彻底清理系统中可能存在的旧版本Docker组件：

```bash
# 停止所有运行的Docker容器
docker stop $(docker ps -aq) 2>/dev/null || true

# 卸载旧版本Docker及相关包
sudo apt remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli docker-ce-rootless-extras docker-buildx-plugin docker-compose-plugin

# 清理残留的配置文件和数据目录
sudo apt purge -y docker*

# 删除Docker数据目录（谨慎操作，会删除所有容器和镜像）
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 删除Docker配置文件
sudo rm -rf /etc/docker

# 删除旧的Docker组
sudo groupdel docker 2>/dev/null || true
```

## 安装必要依赖包

安装Docker所需的前置依赖包：

```bash
# 安装必要的依赖包
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    uidmap

# 创建Docker GPG密钥环目录
sudo install -m 0755 -d /etc/apt/keyrings
```

## 配置Docker官方仓库

### 添加Docker官方GPG密钥

```bash
# 下载并添加Docker官方GPG密钥
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# 设置密钥文件权限
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 验证密钥
sudo gpg --show-keys /etc/apt/keyrings/docker.asc
```

### 配置Docker仓库

```bash
# 获取系统信息
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)
ARCH=$(dpkg --print-architecture)

# 添加Docker仓库到APT源列表
echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/${DISTRO} \
  ${CODENAME} stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新APT包索引
sudo apt update
```

### 验证仓库配置

```bash
# 检查Docker包是否可用
apt-cache policy docker-ce

# 查看可用的Docker版本
apt list -a docker-ce
```

## 安装Docker CE

### 安装最新版本的Docker CE

```bash
# 安装最新版本的Docker CE和相关组件
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 或者安装特定版本（可选）
# VERSION_STRING=5:24.0.7-1~ubuntu.24.04~noble
# sudo apt install -y docker-ce=${VERSION_STRING} docker-ce-cli=${VERSION_STRING} containerd.io docker-buildx-plugin docker-compose-plugin
```

### 验证安装

```bash
# 检查Docker版本
docker --version
docker version

# 检查Docker服务状态
sudo systemctl status docker

# 测试Docker安装
sudo docker run hello-world

# 检查Docker系统信息
sudo docker info
```

### 配置用户权限

```bash
# 创建docker用户组
sudo groupadd docker 2>/dev/null || true

# 将当前用户添加到docker组
sudo usermod -aG docker $USER

# 使组权限生效（需要重新登录或执行以下命令）
newgrp docker

# 验证用户权限
docker ps
```

## 企业级配置优化

### 创建daemon.json配置文件

```bash
# 创建Docker配置目录
sudo mkdir -p /etc/docker

# 创建企业级daemon.json配置文件
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3",
    "labels": "production_status",
    "env": "LOGSPOUT,ROUTESPOUT"
  },
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com"
  ],
  "insecure-registries": [],
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

# 设置配置文件权限
sudo chmod 644 /etc/docker/daemon.json
```

### 配置容器默认资源限制

```bash
# 创建Docker系统级配置文件
sudo mkdir -p /etc/systemd/system/docker.service.d

# 创建资源限制配置
sudo tee /etc/systemd/system/docker.service.d/resource-limits.conf > /dev/null <<EOF
[Service]
# 内存限制
MemoryLimit=4G

# CPU限制
CPUQuota=200%

# 进程数限制
TasksMax=8192

# 文件描述符限制
LimitNOFILE=1048576
LimitNPROC=1048576

# 重启策略
Restart=always
RestartSec=5
EOF

# 重新加载systemd配置
sudo systemctl daemon-reload

# 重启Docker服务
sudo systemctl restart docker

# 验证配置
sudo systemctl status docker
```

### 配置防火墙规则

```bash
# 安装防火墙（如果未安装）
sudo apt install -y ufw

# 允许Docker相关端口
sudo ufw allow 2376/tcp comment "Docker API"
sudo ufw allow 7946/tcp comment "Docker Swarm"
sudo ufw allow 7946/udp comment "Docker Swarm"
sudo ufw allow 4789/udp comment "Docker Swarm"
sudo ufw allow 9323/tcp comment "Docker Metrics"

# 启用防火墙
sudo ufw --force enable

# 查看防火墙状态
sudo ufw status verbose
```

## Docker Compose安装

### 安装最新版本的Docker Compose

```bash
# 下载最新版本的Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

# 下载Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 设置执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 创建符号链接
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 验证安装
docker-compose --version
```

### 配置Docker Compose自动补全

```bash
# 安装bash-completion
sudo apt install -y bash-completion

# 下载Docker Compose自动补全脚本
curl -L https://raw.githubusercontent.com/docker/compose/${DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

# 重新加载bash配置
source /etc/bash_completion.d/docker-compose
```

## 安全配置和最佳实践

### 配置TLS访问

```bash
# 创建TLS证书目录
sudo mkdir -p /etc/docker/certs.d

# 生成自签名证书（生产环境建议使用CA签名的证书）
sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout /etc/docker/certs.d/ca-key.pem -x509 -days 365 -out /etc/docker/certs.d/ca.pem

# 生成服务器证书
sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout /etc/docker/certs.d/server-key.pem -out /etc/docker/certs.d/server.csr

# 签署服务器证书
sudo openssl x509 -req -days 365 -in /etc/docker/certs.d/server.csr -CA /etc/docker/certs.d/ca.pem -CAkey /etc/docker/certs.d/ca-key.pem -CAcreateserial -out /etc/docker/certs.d/server-cert.pem

# 生成客户端证书
sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout /etc/docker/certs.d/client-key.pem -out /etc/docker/certs.d/client.csr

# 签署客户端证书
sudo openssl x509 -req -days 365 -in /etc/docker/certs.d/client.csr -CA /etc/docker/certs.d/ca.pem -CAkey /etc/docker/certs.d/ca-key.pem -CAcreateserial -out /etc/docker/certs.d/client-cert.pem

# 设置证书权限
sudo chmod 0400 /etc/docker/certs.d/server-key.pem
sudo chmod 0400 /etc/docker/certs.d/client-key.pem
sudo chmod 0444 /etc/docker/certs.d/server-cert.pem
sudo chmod 0444 /etc/docker/certs.d/client-cert.pem
sudo chmod 0444 /etc/docker/certs.d/ca.pem
```

### 更新daemon.json启用TLS

```bash
# 备份当前配置
sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup

# 更新daemon.json添加TLS配置
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
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
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "live-restore": true,
  "userland-proxy": false,
  "tls": true,
  "tlscert": "/etc/docker/certs.d/server-cert.pem",
  "tlskey": "/etc/docker/certs.d/server-key.pem",
  "tlsverify": true,
  "tlscacert": "/etc/docker/certs.d/ca.pem",
  "hosts": ["tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"]
}
EOF

# 重启Docker服务
sudo systemctl restart docker
```

### 配置容器运行时安全

```bash
# 安装AppArmor（如果未安装）
sudo apt install -y apparmor apparmor-utils

# 启用AppArmor
sudo systemctl enable apparmor
sudo systemctl start apparmor

# 检查AppArmor状态
sudo aa-status
```

### 配置用户命名空间

```bash
# 启用用户命名空间
sudo tee /etc/sysctl.d/99-docker.conf > /dev/null <<EOF
kernel.unprivileged_userns_clone = 1
EOF

# 应用配置
sudo sysctl -p /etc/sysctl.d/99-docker.conf
```

## 性能监控和调优

### 安装监控工具

```bash
# 安装系统监控工具
sudo apt install -y htop iotop nethogs sysstat

# 安装Docker监控工具
docker run -d --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  -p 8080:8080 \
  --restart=always \
  gcr.io/cadvisor/cadvisor:latest
```

### 配置日志轮转

```bash
# 创建日志轮转配置
sudo tee /etc/logrotate.d/docker > /dev/null <<EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=10M
    missingok
    delaycompress
    copytruncate
    notifempty
}
EOF

# 测试日志轮转
sudo logrotate -d /etc/logrotate.d/docker
```

### 配置系统资源限制

```bash
# 编辑系统限制配置
sudo tee /etc/security/limits.d/docker.conf > /dev/null <<EOF
# Docker用户限制
docker soft nofile 1048576
docker hard nofile 1048576
docker soft nproc 1048576
docker hard nproc 1048576

# 系统级限制
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
EOF

# 编辑内核参数
sudo tee /etc/sysctl.d/99-docker-performance.conf > /dev/null <<EOF
# 网络性能优化
net.core.somaxconn = 1024
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

# 文件句柄优化
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

# 应用内核参数
sudo sysctl -p /etc/sysctl.d/99-docker-performance.conf
```

## 故障排除和维护

### 常见故障排除

```bash
# 检查Docker服务状态
sudo systemctl status docker

# 查看Docker日志
sudo journalctl -u docker -f

# 检查Docker配置
sudo docker info

# 清理未使用的资源
docker system prune -a -f

# 清理特定资源
docker container prune -f
docker image prune -a -f
docker volume prune -f
docker network prune -f
```

### 备份和恢复

```bash
# 备份Docker配置和数据
sudo tar -czf docker-backup-$(date +%Y%m%d).tar.gz \
  /etc/docker \
  /var/lib/docker \
  /etc/systemd/system/docker.service.d

# 恢复Docker配置和数据
sudo tar -xzf docker-backup-YYYYMMDD.tar.gz -C /
```

### 更新和维护

```bash
# 更新Docker到最新版本
sudo apt update
sudo apt upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 重启Docker服务
sudo systemctl restart docker

# 验证更新
docker --version
sudo docker info
```

### 创建维护脚本

```bash
# 创建Docker维护脚本
sudo tee /usr/local/bin/docker-maintenance.sh > /dev/null <<'EOF'
#!/bin/bash

# Docker维护脚本

# 清理未使用的资源
echo "清理未使用的Docker资源..."
docker system prune -a -f

# 清理日志文件
echo "清理Docker日志文件..."
find /var/lib/docker/containers/ -type f -name "*.log" -exec truncate -s 0 {} \;

# 重启Docker服务
echo "重启Docker服务..."
systemctl restart docker

# 检查Docker状态
echo "检查Docker状态..."
systemctl status docker --no-pager

echo "Docker维护完成！"
EOF

# 设置执行权限
sudo chmod +x /usr/local/bin/docker-maintenance.sh

# 创建定时任务（可选）
echo "0 2 * * 0 root /usr/local/bin/docker-maintenance.sh" | sudo tee -a /etc/crontab
```

## 验证安装和配置

### 综合测试

```bash
# 创建测试目录
mkdir -p ~/docker-test && cd ~/docker-test

# 创建测试Dockerfile
cat > Dockerfile <<EOF
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y curl
CMD ["curl", "https://www.google.com"]
EOF

# 创建测试docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8080:80"
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
EOF

# 测试Docker构建
docker build -t test-image .

# 测试Docker运行
docker run --rm test-image

# 测试Docker Compose
docker-compose up -d

# 检查容器状态
docker ps

# 清理测试资源
docker-compose down
docker rmi test-image
```

### 性能测试

```bash
# 运行性能测试容器
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  --name docker-bench-security \
  docker/docker-bench-security

# 运行容器性能测试
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  --name container-perf-test \
  jessfraz/docker-perf
```

## 总结

本教程提供了在Ubuntu 24.04 LTS系统上安装和配置企业级Docker CE的完整方案，包括：

1. ✅ 系统准备和清理
2. ✅ 官方仓库配置
3. ✅ Docker CE安装
4. ✅ 企业级优化配置
5. ✅ Docker Compose安装
6. ✅ 安全配置
7. ✅ 性能调优
8. ✅ 监控和维护

### 后续建议

1. **定期更新**：保持Docker和相关组件的最新版本
2. **监控告警**：配置监控告警系统
3. **备份策略**：制定定期备份策略
4. **安全审计**：定期进行安全审计
5. **文档维护**：保持配置文档的更新

### 相关资源

- [Docker官方文档](https://docs.docker.com/)
- [Ubuntu官方文档](https://ubuntu.com/server/docs)
- [Docker安全最佳实践](https://docs.docker.com/engine/security/)
- [Docker企业级配置指南](https://docs.docker.com/engine/reference/commandline/dockerd/)

---

> 📅 **创建日期**：2025年12月
>
> 🏷️ **版本**：v1.0
>
> 👨‍💻 **作者**：企业级Docker部署专家
>
> 📧 **支持**：如有问题请联系技术支持团队

*本教程会定期更新以保持与最新版本的兼容性*