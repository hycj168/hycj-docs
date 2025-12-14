# Docker 企业级命令集合大全 🚀

## 📋 使用说明

本文档整理了企业级环境中常用的 **Docker** 命令，每个命令都配有详细的中文注释和参数说明，适合作为日常参考手册。

---

## 🏃‍♂️ 容器生命周期管理

### 容器创建与运行

```bash
# 创建并运行容器（最常用）
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]

# 企业级示例：运行一个生产级的 Spring Boot 应用
docker run -d \\
  --name myapp-prod \\
  --restart unless-stopped \\
  -p 8080:8080 \\
  -p 5005:5005 \\
  -e JAVA_OPTS="-Xms1g -Xmx2g" \\
  -e SPRING_PROFILES_ACTIVE=prod \\
  -v /app/logs:/app/logs \\
  -v /app/config:/app/config \\
  --health-cmd="curl -f http://localhost:8080/actuator/health || exit 1" \\
  --health-interval=30s \\
  --health-timeout=10s \\
  --health-retries=3 \\
  --memory=2g \\
  --cpus=1.5 \\
  --security-opt no-new-privileges \\
  myapp:latest
```

**参数详解：**

- `-d, --detach`: 后台运行容器，返回容器ID
- `--name`: 容器名称，便于管理和识别
- `--restart`: 重启策略，`unless-stopped` 表示除非手动停止，否则总是重启
- `-p, --publish`: 端口映射，`主机端口:容器端口`
- `-e, --env`: 设置环境变量
- `-v, --volume`: 数据卷挂载，`主机路径:容器路径`
- `--health-cmd`: 健康检查命令
- `--health-interval`: 健康检查间隔
- `--health-timeout`: 健康检查超时时间
- `--health-retries`: 健康检查失败重试次数
- `--memory`: 内存限制
- `--cpus`: CPU限制
- `--security-opt`: 安全选项，`no-new-privileges` 禁止提升权限

---

### 容器启动、停止与重启

```bash
# 启动已存在的容器
docker start [OPTIONS] CONTAINER [CONTAINER...]

# 企业级启动（带交互式）
docker start -i myapp-prod  # -i: 交互式模式，附加到容器标准输入

# 停止容器（优雅关闭）
docker stop [OPTIONS] CONTAINER [CONTAINER...]

# 企业级停止（设置超时时间）
docker stop -t 30 myapp-prod  # -t: 等待超时时间（秒），默认10秒

# 强制停止容器
docker kill [OPTIONS] CONTAINER [CONTAINER...]

# 重启容器
docker restart [OPTIONS] CONTAINER [CONTAINER...]

# 企业级重启
docker restart -t 30 myapp-prod  # -t: 停止前等待时间

# 暂停容器（不终止进程）
docker pause CONTAINER [CONTAINER...]

# 恢复暂停的容器
docker unpause CONTAINER [CONTAINER...]
```

---

### 容器删除

```bash
# 删除容器
docker rm [OPTIONS] CONTAINER [CONTAINER...]

# 企业级删除（强制删除运行中的容器）
docker rm -f myapp-prod  # -f: 强制删除

# 删除所有已停止的容器
docker container prune

# 删除容器及其数据卷
docker rm -v myapp-prod  # -v: 同时删除关联的数据卷

# 强制删除所有容器（慎用！）
docker rm -f $(docker ps -aq)
```

---

## 📊 容器监控与查看

### 容器状态查看

```bash
# 查看正在运行的容器
docker ps [OPTIONS]

# 企业级查看（包含所有信息）
```bash
docker ps -a \
  --format "table {&#8203;.ID}}\\t{&#8203;.Names}}\\t{&#8203;.Image}}\\t{&#8203;.Status}}\\t{&#8203;.Ports}}\\t{&#8203;.CreatedAt}}"
```

# 参数详解：

# -a, --all: 显示所有容器（包括已停止的）

# --format: 自定义输出格式

# -q, --quiet: 只显示容器ID

# -s, --size: 显示文件大小

# --no-trunc: 不截断输出

# 查看容器详细信息

docker inspect [OPTIONS] CONTAINER|IMAGE [CONTAINER|IMAGE...]

# 企业级查看（格式化输出）

```bash
docker inspect -f '
容器名称: {&#8203;{.Name}}
状态: {&#8203;{.State.Status}}
镜像: {&#8203;{.Config.Image}}
IP地址: {&#8203;{.NetworkSettings.IPAddress}}
创建时间: {&#8203;{.Created}}
启动时间: {&#8203;{.State.StartedAt}}
健康状态: {&#8203;{.State.Health.Status}}
内存限制: {&#8203;{.HostConfig.Memory}}
CPU限制: {&#8203;{.HostConfig.NanoCpus}}
' myapp-prod
```

```

---

### 容器日志管理

```bash
# 查看容器日志
docker logs [OPTIONS] CONTAINER

# 企业级日志查看
docker logs -f \\
  --tail 100 \\
  --since 2h \\
  --until 1h \\
  --timestamps \\
  myapp-prod

# 参数详解：
# -f, --follow: 跟踪日志输出（类似 tail -f）
# --tail: 显示最后多少行日志
# --since: 显示从指定时间开始的日志（如 2h, 2023-01-01T00:00:00）
# --until: 显示到指定时间结束的日志
# --timestamps: 显示时间戳
# --details: 显示额外的日志详细信息

# 实时日志监控
docker logs -f --tail 50 myapp-prod | grep ERROR

# 导出日志到文件
docker logs myapp-prod > myapp-prod.log 2>&1
```

---

### 容器资源监控

```bash
# 实时资源使用情况
docker stats [OPTIONS] [CONTAINER...]

# 企业级资源监控
docker stats \
  --no-stream \
  --format "table {&#8203;.Container}}\\t{&#8203;.Name}}\\t{&#8203;.CPUPerc}}\\t{&#8203;.MemUsage}}\\t{&#8203;.NetIO}}\\t{&#8203;.BlockIO}}"

# 参数详解：
# --no-stream: 只显示一次结果，不持续监控
# --format: 自定义输出格式
# --no-trunc: 不截断输出

# 查看容器进程
docker top CONTAINER [ps OPTIONS]

# 企业级进程查看
docker top myapp-prod aux  # aux: ps命令的参数

# 查看容器内文件系统变更
docker diff CONTAINER

# 企业级文件系统检查
docker diff myapp-prod | head -20  # 显示前20个变更的文件
```

---

## 🎯 容器执行与调试

### 在容器中执行命令

```bash
# 在运行中的容器中执行命令
docker exec [OPTIONS] CONTAINER COMMAND [ARG...]

# 企业级执行（交互式 shell）
docker exec -it \\
  --user root \\
  --workdir /app \\
  --env DEBUG=true \\
  myapp-prod \\
  /bin/bash

# 参数详解：
# -i, --interactive: 保持标准输入打开
# -t, --tty: 分配伪终端
# --user: 指定执行命令的用户（如 root, appuser）
# --workdir: 设置工作目录
# --env: 设置环境变量
# -d, --detach: 后台执行
# --privileged: 给予扩展权限（慎用！）

# 企业级调试命令集合
docker exec myapp-prod netstat -tlnp      # 查看网络连接
docker exec myapp-prod ps aux              # 查看进程
docker exec myapp-prod df -h                # 查看磁盘使用
docker exec myapp-prod free -m              # 查看内存使用
docker exec myapp-prod curl http://localhost:8080/actuator/health  # 健康检查
docker exec myapp-prod jstack 1            # Java 线程转储（PID为1）
docker exec myapp-prod jmap -heap 1         # Java 内存映射
docker exec -u root myapp-prod apt update   # 以 root 身份更新包
```

---

### 容器文件操作

```bash
# 从容器复制文件到主机
docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH

# 企业级文件复制
docker cp myapp-prod:/app/logs/application.log ./logs/
docker cp myapp-prod:/app/config/application.yml ./backup/

# 从主机复制文件到容器
docker cp [OPTIONS] SRC_PATH CONTAINER:DEST_PATH

# 企业级文件更新
docker cp ./config/new-config.yml myapp-prod:/app/config/application.yml
docker cp ./scripts/debug.sh myapp-prod:/app/scripts/

# 参数详解：
# -a, --archive: 归档模式（保留文件属性）
# -L, --follow-link: 跟随符号链接
```

---

## 🏗️ 镜像管理

### 镜像构建

```bash
# 构建镜像
docker build [OPTIONS] PATH | URL | -

# 企业级镜像构建
docker build \\
  --file Dockerfile.prod \\
  --tag myapp:1.0.0 \\
  --tag myapp:latest \\
  --build-arg JAVA_OPTS="-Xms1g -Xmx2g" \\
  --build-arg SPRING_PROFILES_ACTIVE=prod \\
  --target production \\
  --no-cache \\
  --pull \\
  --progress=plain \\
  --label "version=1.0.0" \\
  --label "maintainer=DevOps Team" \\
  --platform linux/amd64 \\
  .

# 参数详解：
# --file, -f: 指定 Dockerfile 路径
# --tag, -t: 镜像标签（可指定多个）
# --build-arg: 构建参数
# --target: 多阶段构建的目标阶段
# --no-cache: 不使用缓存
# --pull: 总是拉取最新基础镜像
# --progress: 构建进度显示方式（auto, plain, tty）
# --label: 镜像标签
# --platform: 目标平台（如 linux/amd64, linux/arm64）
# --squash: 合并层（实验性功能）
# --compress: 压缩构建上下文
```

---

### 镜像查看与管理

```bash
# 查看镜像
docker images [OPTIONS] [REPOSITORY[:TAG]]

# 企业级镜像查看
```bash
docker images \
  --format "table {&#8203;.Repository}}\t{&#8203;.Tag}}\t{&#8203;.ID}}\t{&#8203;.Size}}\t{&#8203;.CreatedAt}}" \
  --filter "dangling=false" \
  --filter "label=version"
```

# 参数详解：

# --all, -a: 显示所有镜像（包括中间层）

# --digests: 显示摘要

# --filter, -f: 过滤条件

# --format: 自定义输出格式

# --no-trunc: 不截断输出

# --quiet, -q: 只显示镜像ID

# 查看镜像详细信息

docker inspect [OPTIONS] IMAGE [IMAGE...]

# 企业级镜像检查

```bash
docker inspect -f '
镜像: {&#8203;.RepoTags}}
大小: {&#8203;.Size}}
创建时间: {&#8203;.Created}}
架构: {&#8203;.Architecture}}
OS: {&#8203;.Os}}
标签: {&#8203;.Config.Labels}}
环境变量: {&#8203;.Config.Env}}
工作目录: {&#8203;.Config.WorkingDir}}
入口点: {&#8203;.Config.Entrypoint}}
命令: {&#8203;.Config.Cmd}}
' myapp:latest
```

# 查看镜像历史

docker history [OPTIONS] IMAGE

# 企业级历史查看

```bash
docker history --no-trunc --format "table {&#8203;.CreatedBy}}\t{&#8203;.Size}}\t{&#8203;.CreatedAt}}" myapp:latest
```

```

---

### 镜像标签与推送

```bash
# 给镜像打标签
docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]

# 企业级标签管理
docker tag myapp:latest myregistry.com/team/myapp:1.0.0
docker tag myapp:latest myregistry.com/team/myapp:stable

# 推送镜像到仓库
docker push [OPTIONS] NAME[:TAG]

# 企业级推送
docker push myregistry.com/team/myapp:1.0.0

# 拉取镜像
docker pull [OPTIONS] NAME[:TAG|@DIGEST]

# 企业级拉取
docker pull myregistry.com/team/myapp:1.0.0

# 登录私有仓库
docker login [OPTIONS] [SERVER]

# 企业级登录
docker login \\
  --username myuser \\
  --password-stdin \\
  myregistry.com < mypassword.txt
```

---

### 镜像清理

```bash
# 删除镜像
docker rmi [OPTIONS] IMAGE [IMAGE...]

# 企业级镜像删除
docker rmi -f myapp:old-version  # -f: 强制删除

# 删除未使用的镜像
docker image prune [OPTIONS]

# 企业级镜像清理
docker image prune \\
  --all \\
  --filter "until=24h" \\
  --filter "label=maintainer=old-team"

# 参数详解：
# --all, -a: 删除所有未使用的镜像（不仅是悬空镜像）
# --filter: 过滤条件
# -f, --force: 强制删除，不提示确认
```

---

## 🌐 网络管理

### 网络创建与配置

```bash
# 创建网络
docker network create [OPTIONS] NETWORK

# 企业级网络创建
docker network create \\
  --driver bridge \\
  --subnet 172.20.0.0/16 \\
  --gateway 172.20.0.1 \\
  --ip-range 172.20.1.0/24 \\
  --opt com.docker.network.driver.mtu=1450 \\
  --label "env=production" \\
  --label "team=backend" \\
  production-network

# 参数详解：
# --driver: 网络驱动（bridge, overlay, host, macvlan）
# --subnet: 子网地址
# --gateway: 网关地址
# --ip-range: IP地址范围
# --opt: 驱动特定选项
# --label: 网络标签
# --internal: 限制外部访问
# --attachable: 允许容器连接到网络

# 查看网络
docker network ls [OPTIONS]

# 企业级网络查看
```bash
docker network ls \
  --filter "driver=bridge" \
  --filter "label=env=production" \
  --format "table {&#8203;.ID}}\t{&#8203;.Name}}\t{&#8203;.Driver}}\t{&#8203;.Scope}}\t{&#8203;.Labels}}"
```

# 查看网络详细信息

docker network inspect [OPTIONS] NETWORK [NETWORK...]

# 企业级网络检查

```bash
docker network inspect -f '
网络名称: {&#8203;.Name}}
驱动: {&#8203;.Driver}}
子网: {&#8203;{range .IPAM.Config}}{&#8203;.Subnet}}{&#8203;{end}}
网关: {&#8203;{range .IPAM.Config}}{&#8203;.Gateway}}{&#8203;{end}}
容器数量: {&#8203;{len .Containers}}
标签: {&#8203;.Labels}}
' production-network
```

```

---

### 网络连接管理

```bash
# 将容器连接到网络
docker network connect [OPTIONS] NETWORK CONTAINER

# 企业级网络连接
docker network connect \\
  --ip 172.20.1.100 \\
  --alias myapp.db \\
  --alias database \\
  production-network \\
  myapp-container

# 参数详解：
# --ip: 指定IP地址
# --alias: 网络别名
# --link: 连接到其他容器（已废弃）

# 断开网络连接
docker network disconnect [OPTIONS] NETWORK CONTAINER

# 企业级网络断开
docker network disconnect -f production-network myapp-container  # -f: 强制断开

# 删除网络
docker network rm NETWORK [NETWORK...]

# 清理未使用的网络
docker network prune [OPTIONS]

# 企业级网络清理
docker network prune --filter "until=24h"  # 删除24小时前创建的未使用网络
```

---

## 💾 数据卷管理

### 数据卷创建与使用

```bash
# 创建数据卷
docker volume create [OPTIONS] [VOLUME]

# 企业级数据卷创建
docker volume create \\
  --driver local \\
  --label "app=myapp" \\
  --label "env=production" \\
  --opt type=nfs \\
  --opt o=addr=192.168.1.100,rw \\
  --opt device=:/path/to/dir \\
  myapp-data

# 参数详解：
# --driver: 卷驱动（local, nfs, etc.）
# --label: 卷标签
# --opt: 驱动特定选项
# -d, --driver: 指定驱动

# 查看数据卷
docker volume ls [OPTIONS]

# 企业级数据卷查看
```bash
docker volume ls \
  --filter "label=app=myapp" \
  --filter "dangling=false" \
  --format "table {&#8203;.Name}}\t{&#8203;.Driver}}\t{&#8203;.Labels}}\t{&#8203;.CreatedAt}}"
```

# 查看数据卷详细信息

docker volume inspect [OPTIONS] VOLUME [VOLUME...]

# 企业级数据卷检查

```bash
docker volume inspect -f '
卷名称: {&#8203;.Name}}
驱动: {&#8203;.Driver}}
挂载点: {&#8203;.Mountpoint}}
标签: {&#8203;.Labels}}
创建时间: {&#8203;.CreatedAt}}
' myapp-data
```

```

---

### 数据卷备份与恢复

```bash
# 备份数据卷
docker run --rm \\
  -v myapp-data:/data \\
  -v $(pwd):/backup \\
  alpine \\
  tar czf /backup/myapp-data-backup.tar.gz -C /data .

# 恢复数据卷
docker run --rm \\
  -v myapp-data:/data \\
  -v $(pwd):/backup \\
  alpine \\
  tar xzf /backup/myapp-data-backup.tar.gz -C /data

# 复制数据卷
docker run --rm \\
  -v source-data:/source \\
  -v target-data:/target \\
  alpine \\
  cp -a /source/. /target/

# 删除数据卷
docker volume rm [OPTIONS] VOLUME [VOLUME...]

# 清理未使用的数据卷
docker volume prune [OPTIONS]

# 企业级数据卷清理
docker volume prune --filter "label!=keep=true"  # 删除没有 keep=true 标签的卷
```

---

## 🏗️ Docker Compose 企业级命令

### 服务生命周期管理

```bash
# 启动服务
docker-compose up [OPTIONS] [SERVICE...]

# 企业级服务启动
docker-compose -f docker-compose.yml \\
  -f docker-compose.prod.yml \\
  --env-file .env.prod \\
  --project-name myapp-prod \\
  --compatibility \\
  up \\
  -d \\
  --build \\
  --force-recreate \\
  --remove-orphans \\
  --scale web=3 \\
  --scale worker=2

# 参数详解：
# -f, --file: 指定 compose 文件（可指定多个）
# --env-file: 环境变量文件
# --project-name: 项目名称
# --compatibility: 兼容性模式
# -d, --detach: 后台运行
# --build: 构建镜像
# --force-recreate: 强制重新创建容器
# --remove-orphans: 删除孤立容器
# --scale: 扩展服务数量
# --no-build: 不构建镜像
# --no-recreate: 不重新创建容器
# --no-deps: 不启动依赖服务

# 停止服务
docker-compose down [OPTIONS]

# 企业级服务停止
docker-compose \\
  -f docker-compose.yml \\
  --project-name myapp-prod \\
  down \\
  --volumes \\
  --remove-orphans \\
  --rmi all \\
  --timeout 30

# 参数详解：
# --volumes: 删除数据卷
# --remove-orphans: 删除孤立容器
# --rmi: 删除镜像（local, all）
# --timeout, -t: 超时时间

# 重启服务
docker-compose restart [OPTIONS] [SERVICE...]

# 企业级重启
docker-compose restart -t 30 web worker  # 只重启 web 和 worker 服务
```

---

### 服务状态查看

```bash
# 查看服务状态
docker-compose ps [OPTIONS] [SERVICE...]

# 企业级服务查看
docker-compose ps \\
  --all \\
  --services \\
  --filter "source=build"

# 查看服务日志
docker-compose logs [OPTIONS] [SERVICE...]

# 企业级日志查看
docker-compose logs \\
  -f \\
  --tail 100 \\
  --timestamps \\
  --no-color \\
  web worker

# 参数详解：
# -f, --follow: 跟踪日志
# --tail: 显示最后多少行
# --timestamps, -t: 显示时间戳
# --no-color: 不使用颜色
# --no-log-prefix: 不显示服务名称前缀

# 查看服务配置
docker-compose config [OPTIONS]

# 企业级配置验证
docker-compose config \\
  --services \\
  --volumes \\
  --hash="*" \\
  --profiles
```

---

### 服务执行与调试

```bash
# 在服务中执行命令
docker-compose exec [OPTIONS] SERVICE COMMAND [ARG...]

# 企业级服务执行
docker-compose exec \\
  -T \\
  --index 1 \\
  --user root \\
  --workdir /app \\
  --env DEBUG=true \\
  web \\
  /bin/bash

# 参数详解：
# -T: 禁用伪终端
# --index: 服务实例索引（当服务有多个副本时）
# --user, -u: 执行命令的用户
# --workdir, -w: 工作目录
# --env, -e: 环境变量
# -d, --detach: 后台执行

# 运行一次性命令
docker-compose run [OPTIONS] SERVICE [COMMAND] [ARG...]

# 企业级一次性命令
docker-compose run \\
  --name migration-job \\
  --no-deps \\
  --rm \\
  --user appuser \\
  --volume /host/data:/app/data \\
  --workdir /app \\
  --service-ports \\
  --use-aliases \\
  web \\
  python manage.py migrate

# 参数详解：
# --name: 容器名称
# --no-deps: 不启动依赖服务
# --rm: 运行后删除容器
# --service-ports: 启用服务端口映射
# --use-aliases: 使用服务网络别名
```

---

## 🔧 系统管理命令

### Docker 服务管理

```bash
# 查看 Docker 系统信息
docker system df [OPTIONS]

# 企业级磁盘使用分析
```bash
docker system df \
  --format "table {&#8203;.Type}}\\t{&#8203;.TotalCount}}\\t{&#8203;.Active}}\\t{&#8203;.Size}}\\t{&#8203;.Reclaimable}}"
```

# 清理未使用的资源

docker system prune [OPTIONS]

# 企业级系统清理

docker system prune \\
--all \\
--volumes \\
--filter "until=24h" \\
--filter "label!=keep=true"

# 参数详解：

# --all, -a: 删除所有未使用的镜像

# --volumes: 删除未使用的数据卷

# --filter: 过滤条件

# -f, --force: 强制删除，不提示确认

# 查看 Docker 系统信息

docker info [OPTIONS]

# 企业级系统信息

```bash
docker info -f '
Docker 根目录: {&#8203;{.DockerRootDir}}
存储驱动: {&#8203;{.Driver}}
日志驱动: {&#8203;{.LoggingDriver}}
Cgroup 驱动: {&#8203;{.CgroupDriver}}
Cgroup 版本: {&#8203;{.CgroupVersion}}
内核版本: {&#8203;{.KernelVersion}}
操作系统: {&#8203;{.OperatingSystem}}
架构: {&#8203;{.Architecture}}
CPU 数量: {&#8203;{.NCPU}}
总内存: {&#8203;{.MemTotal}}
注册表: {&#8203;{.IndexServerAddress}}
'
```

---

### 容器资源限制

```bash
# 运行时资源限制
docker run \\
  --memory=2g \\
  --memory-swap=4g \\
  --memory-reservation=1g \\
  --kernel-memory=500m \\
  --cpus=1.5 \\
  --cpu-shares=1024 \\
  --cpu-period=100000 \\
  --cpu-quota=150000 \\
  --cpuset-cpus=0,1 \\
  --blkio-weight=500 \\
  --device-read-bps /dev/sda:1mb \\
  --device-write-bps /dev/sda:1mb \\
  --device-read-iops /dev/sda:1000 \\
  --device-write-iops /dev/sda:1000 \\
  --pids-limit 1000 \\
  --ulimit nofile=1024:2048 \\
  --ulimit nproc=512:1024 \\
  --shm-size=1g \\
  myapp:latest

# 参数详解：
# --memory, -m: 内存限制（单位：b, k, m, g）
# --memory-swap: 内存+交换分区限制
# --memory-reservation: 内存软限制
# --kernel-memory: 内核内存限制
# --cpus: CPU数量限制（小数表示）
# --cpu-shares: CPU份额（相对权重）
# --cpu-period: CPU周期（微秒）
# --cpu-quota: CPU配额（微秒）
# --cpuset-cpus: 允许使用的CPU核心
# --blkio-weight: 块IO权重（10-1000）
# --device-read-bps: 设备读取速率限制
# --device-write-bps: 设备写入速率限制
# --device-read-iops: 设备读取IOPS限制
# --device-write-iops: 设备写入IOPS限制
# --pids-limit: 进程数量限制
# --ulimit: 资源限制
# --shm-size: /dev/shm 大小
```

---

## 🔒 安全相关命令

### 容器安全设置

```bash
# 安全选项
docker run \\
  --security-opt apparmor:myprofile \\
  --security-opt seccomp:myprofile.json \\
  --security-opt no-new-privileges \\
  --security-opt label=level:s0:c100,c200 \\
  --cap-drop ALL \\
  --cap-add CHOWN \\
  --cap-add SETUID \\
  --cap-add SETGID \\
  --cap-add NET_BIND_SERVICE \\
  --privileged=false \\
  --read-only \\
  --tmpfs /tmp \\
  --tmpfs /var/run \\
  --user 1000:1000 \\
  myapp:latest

# 参数详解：
# --security-opt: 安全选项
# --cap-drop: 移除能力
# --cap-add: 添加能力
# --privileged: 是否给予特权
# --read-only: 只读根文件系统
# --tmpfs: 临时文件系统挂载
# --user: 运行用户和用户组

# 查看容器能力
docker exec myapp-prod capsh --print

# 查看 AppArmor 状态
docker exec myapp-prod aa-status

# 查看 SELinux 状态
docker exec myapp-prod getenforce
```

---

### 镜像安全扫描

```bash
# 使用 Trivy 进行安全扫描
docker run --rm \\
  -v /var/run/docker.sock:/var/run/docker.sock \\
  aquasec/trivy:latest \\
  image \\
  --severity HIGH,CRITICAL \\
  --format table \\
  myapp:latest

# 使用 Clair 进行安全扫描
docker run --rm \\
  -v /var/run/docker.sock:/var/run/docker.sock \\
  quay.io/coreos/clair:latest \\
  analyze \\
  myapp:latest

# 使用 Docker Scout 进行安全扫描
docker scout cves \\
  --only-package \\
  --format json \\
  myapp:latest
```

---

## 📚 实用脚本集合

### 企业级容器管理脚本

```bash
#!/bin/bash
# 容器健康检查脚本

# 检查容器健康状态
::: details Bash 函数代码
```bash
check_container_health() {
    local container=$1
    local health_status=$(docker inspect -f '{&#8203;.State.Health.Status}}' $container 2>/dev/null)
    
    case $health_status in
        "healthy")
            echo "✅ $container: 健康"
            return 0
            ;;
        "unhealthy")
            echo "❌ $container: 不健康"
            return 1
            ;;
        "starting")
            echo "⏳ $container: 启动中"
            return 2
            ;;
        *)
            echo "⚠️  $container: 无健康检查"
            return 3
            ;;
    esac
}
```

:::

# 批量检查所有容器健康状态

::: details Bash 函数代码

```bash
check_all_containers_health() {
    echo "=== 容器健康检查 ==="
    local containers=$(docker ps -q)
    local healthy=0
    local unhealthy=0
    local starting=0
    local no_health=0
    
    for container in $containers; do
        local name=$(docker inspect -f '{&#8203;.Name}}' $container | sed 's/^\///')
        check_container_health $container
        case $? in
            0) ((healthy++)) ;;
            1) ((unhealthy++)) ;;
            2) ((starting++)) ;;
            3) ((no_health++)) ;;
        esac
    done
    
    echo ""
    echo "健康统计:"
    echo "  ✅ 健康: $healthy"
    echo "  ❌ 不健康: $unhealthy"
    echo "  ⏳ 启动中: $starting"
    echo "  ⚠️  无检查: $no_health"
}
```

:::

# 容器资源监控脚本

monitor_container_resources() {
local container=$1
local duration=${2:-60} # 默认监控60秒

    echo "=== 监控容器 $container 资源使用 ==="
    echo "监控时长: ${duration}秒"
    echo ""
    
    docker stats \
  --no-stream \
  --format "table {&#8203;.Container}}\\t{&#8203;.Name}}\\t{&#8203;.CPUPerc}}\\t{&#8203;.MemUsage}}\\t{&#8203;.NetIO}}\\t{&#8203;.BlockIO}}" $container
    
    echo ""
    echo "详细进程信息:"
    docker top $container aux | head -10

}

# 容器日志分析脚本

analyze_container_logs() {
local container=$1
local pattern=${2:-"ERROR"}
local lines=${3:-100}

    echo "=== 分析容器 $container 日志 ==="
    echo "搜索模式: $pattern"
    echo "显示行数: $lines"
    echo ""
    
    # 统计错误数量
    local error_count=$(docker logs $container 2>&1 | grep -c "$pattern" || echo "0")
    echo "找到 $error_count 个匹配项"
    echo ""
    
    # 显示最近的错误
    echo "最近 $lines 条包含 '$pattern' 的日志:"
    docker logs --tail $lines $container 2>&1 | grep "$pattern" | tail -20
    
    # 显示日志统计
    echo ""
    echo "日志级别统计:"
    docker logs --tail 1000 $container 2>&1 | grep -oE "(ERROR|WARN|INFO|DEBUG)" | sort | uniq -c | sort -nr

}

# 执行函数

check_all_containers_health

```

---

### 镜像管理脚本

```bash
#!/bin/bash
# 企业级镜像管理脚本

# 清理旧镜像
::: details Bash 函数代码
```bash
cleanup_old_images() {
    local keep_days=${1:-7}
    local registry=${2:-""}
    
    echo "=== 清理 $keep_days 天前的旧镜像 ==="
    
    # 查找并删除旧镜像
    local images=$(docker images --format "table {&#8203;.Repository}}\\t{&#8203;.Tag}}\\t{&#8203;.ID}}\\t{&#8203;.CreatedAt}}" | \
                   grep -v "REPOSITORY" | \
                   while IFS=$'\t' read repo tag id created; do
                       echo "$id $repo:$tag $created"
                   done)
    
    echo "需要清理的镜像:"
    echo "$images" | while read id repo_tag created; do
        echo "  - $repo_tag ($id)"
    done
    
    # 确认后删除
    read -p "确认删除这些镜像吗? (y/N): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        echo "$images" | while read id repo_tag created; do
            echo "删除镜像: $repo_tag"
            docker rmi -f $id
        done
    else
        echo "取消删除操作"
    fi
}
```

:::

# 批量重打标签

retag_images() {
local old_pattern=$1
local new_pattern=$2

    echo "=== 批量重打标签 ==="
    echo "旧模式: \$old_pattern"
    echo "新模式: \$new_pattern"
    echo ""
    
    docker images --format "{&#8203;.Repository}}:{&#8203;.Tag}}" | grep "\$old_pattern" | while read image; do
        local new_image=$(echo \$image | sed "s/\$old_pattern/\$new_pattern/g")
        echo "重打标签: \$image -> \$new_image"
        docker tag \$image \$new_image
    done

}

# 镜像安全扫描

scan_image_security() {
local image=$1
local severity=${2:-"HIGH,CRITICAL"}

    echo "=== 安全扫描镜像 \$image ==="
    echo "扫描级别: \$severity"
    echo ""
    
    # 使用 Trivy 扫描
    if command -v trivy &> /dev/null; then
        echo "使用 Trivy 扫描:"
        trivy image --severity \$severity --format table \$image
    else
        echo "Trivy 未安装，使用 Docker Scout:"
        docker scout cves --only-package --format json \$image | jq '.'
    fi

}

# 镜像大小分析函数

::: details Bash 函数代码

```bash
analyze_image_size() {
    local image=$1
    
    echo "=== 分析镜像 \$image 大小 ==="
    echo ""
    
    # 查看镜像历史
    echo "镜像层历史:"
    docker history --no-trunc --format "table {&#8203;.CreatedBy}}\t{&#8203;.Size}}\t{&#8203;.CreatedAt}}" \$image
    
    echo ""
    echo "镜像统计:"
    local total_size=\$(docker inspect -f '{&#8203;.Size}}' \$image | numfmt --to=iec)
    echo "总大小: \$total_size"
    
    # 使用 dive 分析（如果已安装）
    if command -v dive &> /dev/null; then
        echo ""
        echo "使用 dive 进行详细分析:"
        dive \$image
    fi
}
```

:::

# 执行示例

echo "镜像管理工具"
echo "1. 清理旧镜像"
echo "2. 批量重打标签"
echo "3. 安全扫描"
echo "4. 大小分析"
read -p "选择操作 (1-4): " choice

case \$choice in
1) cleanup_old_images ;;
2)
read -p "旧模式: " old_pattern
read -p "新模式: " new_pattern
retag_images "\$old_pattern" "\$new_pattern"
;;
3)
read -p "镜像名称: " image
scan_image_security \$image
;;
4)
read -p "镜像名称: " image
analyze_image_size \$image
;;
*) echo "无效选择" ;;
esac

```

---

## 📖 最佳实践建议

### 1. 命令使用规范

```bash
# ✅ 推荐做法
docker run -d --name myapp --restart unless-stopped myimage
docker logs -f --tail 100 myapp
docker exec -it myapp /bin/bash

# ❌ 不推荐做法
docker run myimage  # 没有名称，难以管理
docker logs myapp   # 没有限制，可能输出过多
docker attach myapp # 容易意外退出容器
```

### 2. 资源管理规范

```bash
# 始终设置资源限制
docker run --memory=1g --cpus=1 myimage

# 使用健康检查
docker run --health-cmd="curl -f http://localhost:8080/health" myimage

# 使用非 root 用户
docker run --user 1000:1000 myimage
```

### 3. 安全管理规范

```bash
# 最小权限原则
docker run --cap-drop ALL --cap-add CHOWN myimage

# 只读文件系统
docker run --read-only --tmpfs /tmp myimage

# 网络隔离
docker network create --internal internal-network
```

---

## 🎯 常用命令速查表

| 场景             | 命令                                                   |
|----------------|------------------------------------------------------|
| **快速启动容器**     | `docker run -d --name app -p 8080:8080 myimage`      |
| **查看日志**       | `docker logs -f --tail 100 app`                      |
| **进入容器**       | `docker exec -it app /bin/bash`                      |
| **复制文件**       | `docker cp app:/path/to/file ./local/`               |
| **查看资源使用**     | `docker stats app`                                   |
| **健康检查**       | `docker inspect -f \{\{.State.Health.Status\}\} app` |
| **批量停止容器**     | `docker stop $(docker ps -q)`                        |
| **清理未使用资源**    | `docker system prune -a`                             |
| **构建镜像**       | `docker build -t myimage:tag .`                      |
| **推送镜像**       | `docker push registry.com/myimage:tag`               |
| **Compose 启动** | `docker-compose up -d`                               |
| **Compose 日志** | `docker-compose logs -f`                             |
| **Compose 停止** | `docker-compose down`                                |

---

## 📚 相关资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker CLI 参考](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker Compose 参考](https://docs.docker.com/compose/reference/)
- [Docker 最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [Docker 安全指南](https://docs.docker.com/engine/security/)

---

**💡 使用建议：**

1. **从简单开始**：先掌握基础命令，再逐步学习高级功能
2. **多练习**：通过实际操作加深理解
3. **查阅文档**：遇到问题时先查看官方文档
4. **关注安全**：始终遵循安全最佳实践
5. **自动化**：将常用命令编写成脚本，提高效率

**🚀 进阶方向：**

- Docker Swarm 集群管理
- Kubernetes 容器编排
- CI/CD 集成
- 监控和日志系统
- 安全扫描和加固