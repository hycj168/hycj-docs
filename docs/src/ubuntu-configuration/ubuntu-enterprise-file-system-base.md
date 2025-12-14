# Ubuntu 企业级文件系统详解

## 📋 目录导航

- [1. Ubuntu 文件系统总览](#1-ubuntu-文件系统总览)
- [2. 核心系统目录详解](#2-核心系统目录详解)
- [3. /usr 目录结构详解](#3-usr-目录结构详解)
- [4. /var 目录结构详解](#4-var-目录结构详解)
- [5. 企业级权限管理](#5-企业级权限管理)
- [6. 企业级最佳实践](#6-企业级最佳实践)
- [7. Docker 数据库数据卷挂载最佳实践](#7-docker-数据库数据卷挂载最佳实践)
- [8. 权限速查表](#8-权限速查表)
- [9. 总结](#9-总结)

---

## 1. Ubuntu 文件系统总览

```bash
/
├── bin/          # 基础用户命令
├── boot/         # 启动加载器文件
├── dev/          # 设备文件
├── etc/          # 系统配置文件
├── home/         # 用户主目录
├── lib/          # 共享库文件
├── media/        # 可移动媒体挂载点
├── mnt/          # 临时挂载点
├── opt/          # 可选软件包
├── proc/         # 进程信息虚拟文件系统
├── root/         # root用户主目录
├── run/          # 运行时变量数据
├── sbin/         # 系统管理员命令
├── srv/          # 服务数据
├── sys/          # 系统设备信息
├── tmp/          # 临时文件
├── usr/          # 用户程序和数据
└── var/          # 可变数据文件
```

---

## 2. 核心系统目录详解

### 1. `/bin` - 基础用户命令

```bash
# 目录用途：存放系统启动和单用户模式下必需的基础命令
# 包含命令：ls, cp, mv, rm, mkdir, rmdir, echo, cat 等
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root

# 企业级最佳实践
drwxr-xr-x  2 root root  4096 Dec  6 10:00 /bin
```

**重要文件说明：**

- `bash`: Bourne Again Shell
- `ls`: 列出目录内容
- `cp`: 复制文件
- `mv`: 移动/重命名文件
- `rm`: 删除文件
- `cat`: 查看文件内容

### 2. `/boot` - 启动加载器文件

```bash
# 目录用途：存放启动Linux系统所需的文件
# 包含内容：内核文件、启动加载器配置文件、初始化内存盘
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 建议大小：1GB-2GB（企业级推荐）

# 企业级最佳实践
drwxr-xr-x  5 root root  4096 Dec  6 10:00 /boot
```

**重要文件说明：**

- `vmlinuz-*`: Linux内核文件
- `initrd.img-*`: 初始化内存盘
- `grub/`: GRUB启动加载器配置
- `config-*`: 内核编译配置
- `System.map-*`: 内核符号表

### 3. `/dev` - 设备文件

```bash
# 目录用途：包含所有设备文件（字符设备和块设备）
# 特殊性质：虚拟文件系统，不占用磁盘空间
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 重要提示：不要手动修改此目录内容

drwxr-xr-x 20 root root  4260 Dec  6 10:00 /dev
```

**重要设备说明：**

- `sda*`: 第一块SCSI/SATA硬盘
- `sdb*`: 第二块SCSI/SATA硬盘
- `nvme0n1*`: NVMe固态硬盘
- `tty*`: 终端设备
- `null`: 空设备（数据黑洞）
- `zero`: 零设备（提供无限零字节）
- `random`: 随机数设备

### 4. `/etc` - 系统配置文件

```bash
# 目录用途：存放系统范围内的配置文件
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 备份重点：企业级环境中必须定期备份

drwxr-xr-x 140 root root 12288 Dec  6 10:00 /etc
```

**重要配置文件：**

- `passwd`: 用户账户信息
- `group`: 用户组信息
- `shadow`: 用户密码（加密）
- `fstab`: 文件系统挂载表
- `hosts`: 主机名到IP地址映射
- `hostname`: 主机名配置
- `network/`: 网络配置
- `ssh/`: SSH服务配置
- `cron.*`: 定时任务配置
- `systemd/`: 系统服务配置

### 5. `/home` - 用户主目录

```bash
# 目录用途：普通用户的主目录
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 子目录权限：700 (drwx------) 用户私有
# 建议大小：根据用户数量和数据量确定

drwxr-xr-x  6 root root  4096 Dec  6 10:00 /home
```

**企业级最佳实践：**

```bash
# 创建用户时自动设置权限
useradd -m -s /bin/bash username
# 设置主目录权限
chmod 700 /home/username
chown username:username /home/username
```

### 6. `/lib` - 共享库文件

```bash
# 目录用途：系统启动和/bin、/sbin命令所需的共享库
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 重要提示：不要手动删除或修改

drwxr-xr-x 20 root root 12288 Dec  6 10:00 /lib
```

**重要库文件：**

- `libc.so.*`: C标准库
- `libm.so.*`: 数学库
- `ld-linux.so.*`: 动态链接器
- `modules/`: 内核模块

### 7. `/media` - 可移动媒体挂载点

```bash
# 目录用途：系统自动挂载可移动设备的挂载点
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 使用场景：U盘、CD/DVD、移动硬盘等

drwxr-xr-x  2 root root  4096 Dec  6 10:00 /media
```

### 8. `/mnt` - 临时挂载点

```bash
# 目录用途：系统管理员临时挂载文件系统的挂载点
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 使用场景：手动挂载网络共享、临时文件系统等

drwxr-xr-x  2 root root  4096 Dec  6 10:00 /mnt
```

**企业级使用示例：**

```bash
# 挂载NFS共享
mount -t nfs server:/share /mnt/nfs
# 挂载ISO镜像
mount -o loop image.iso /mnt/iso
```

### 9. `/opt` - 可选软件包

```bash
# 目录用途：存放可选的第三方应用程序和软件包
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 企业级推荐：用于安装大型商业软件、自定义应用

drwxr-xr-x  5 root root  4096 Dec  6 10:00 /opt
```

**企业级最佳实践：**

```bash
# 创建应用程序目录
mkdir -p /opt/application-name
# 设置合适的权限
chown -R app-user:app-group /opt/application-name
chmod -R 755 /opt/application-name
```

### 10. `/proc` - 进程信息虚拟文件系统

```bash
# 目录用途：内核和进程信息的虚拟文件系统
# 特殊性质：不占用磁盘空间，内存中的虚拟文件系统
# 权限设置：555 (dr-xr-xr-x)
# 所属用户：root:root
# 重要提示：只读文件系统，不要尝试写入

dr-xr-xr-x 20 root root     0 Dec  6 10:00 /proc
```

**重要信息文件：**

- `cpuinfo`: CPU信息
- `meminfo`: 内存信息
- `loadavg`: 系统负载
- `mounts`: 已挂载文件系统
- `version`: 内核版本
- `sys/`: 系统参数和设置

### 11. `/root` - root用户主目录

```bash
# 目录用途：root用户的主目录
# 权限设置：550 (dr-xr-x---)
# 所属用户：root:root
# 安全建议：严格控制访问权限

dr-xr-x---  8 root root  4096 Dec  6 10:00 /root
```

### 12. `/run` - 运行时变量数据

```bash
# 目录用途：存放系统启动以来的运行时数据
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 特殊性质：tmpfs文件系统，重启后清空

drwxr-xr-x 20 root root   860 Dec  6 10:00 /run
```

### 13. `/sbin` - 系统管理员命令

```bash
# 目录用途：存放系统管理员使用的基础命令
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 包含命令：fsck, init, ifconfig, route 等

drwxr-xr-x  2 root root 12288 Dec  6 10:00 /sbin
```

### 14. `/srv` - 服务数据

```bash
# 目录用途：存放系统提供的服务数据
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 使用场景：Web服务器文档根目录、FTP文件等

drwxr-xr-x  2 root root  4096 Dec  6 10:00 /srv
```

**企业级使用示例：**

```bash
# Web服务器文档根目录
mkdir -p /srv/www/domain.com
# FTP服务数据目录
mkdir -p /srv/ftp/shared
# 设置Web服务器权限
chown -R www-data:www-data /srv/www
```

### 15. `/tmp` - 临时文件

```bash
# 目录用途：存放临时文件
# 权限设置：1777 (drwxrwxrwt)
# 所属用户：root:root
# 特殊权限：粘滞位(t)，防止用户删除他人文件
# 清理策略：通常重启后清空或定期清理

drwxrwxrwt 20 root root  4096 Dec  6 10:00 /tmp
```

**企业级安全设置：**

```bash
# 设置合适的权限
chmod 1777 /tmp
# 创建独立tmp分区（推荐）
mount -o nodev,nosuid,noexec /dev/sdaX /tmp
```

---

## 3. /usr 目录结构详解

```
/usr/
├── bin/          # 用户命令
├── sbin/         # 系统管理员命令
├── lib/          # 库文件
├── local/        # 本地安装软件
├── share/        # 架构无关的共享数据
├── include/      # C头文件
├── src/          # 源代码
└── games/        # 游戏程序
```

### /usr/local - 本地安装软件

```bash
# 目录用途：存放本地编译安装的软件
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 企业级推荐：用于安装自定义编译的软件

drwxr-xr-x 10 root root  4096 Dec  6 10:00 /usr/local
```

**目录结构：**

```
/usr/local/
├── bin/          # 本地安装的用户命令
├── sbin/         # 本地安装的系统命令
├── lib/          # 本地安装的库文件
├── etc/          # 本地安装的配置文件
├── share/        # 本地安装的共享数据
└── man/          # 本地安装的手册页
```

---

## 4. /var 目录结构详解

```
/var/
├── log/          # 日志文件
├── lib/          # 可变状态信息
├── spool/        # 任务队列
├── cache/        # 缓存数据
├── tmp/          # 临时文件（持久化）
├── run/          # 运行时数据（符号链接到/run）
└── www/          # Web服务器数据（自定义）
```

### /var/log - 日志文件

```bash
# 目录用途：存放系统和应用程序日志文件
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 企业级重点：必须定期轮转和监控

drwxr-xr-x 20 root root  4096 Dec  6 10:00 /var/log
```

**重要日志文件：**

- `syslog`: 系统通用日志
- `auth.log`: 认证日志
- `kern.log`: 内核日志
- `dmesg`: 启动信息
- `apache2/`: Apache日志目录
- `nginx/`: Nginx日志目录
- `mysql/`: MySQL日志目录

### /var/lib - 可变状态信息

```bash
# 目录用途：存放应用程序的状态信息
# 权限设置：755 (drwxr-xr-x)
# 所属用户：root:root
# 包含内容：数据库、包管理器状态等

drwxr-xr-x 40 root root  4096 Dec  6 10:00 /var/lib
```

**重要子目录：**

- `dpkg/`: 包管理器状态
- `mysql/`: MySQL数据库文件
- `postgresql/`: PostgreSQL数据库文件
- `docker/`: Docker数据

---

## 5. 企业级权限管理

### 标准权限设置

```bash
# 系统目录权限标准
chmod 755 /bin /boot /etc /lib /sbin /usr /var
chmod 1777 /tmp
chmod 555 /proc /sys
chmod 700 /root

# 设置正确的所有者
chown root:root / /bin /boot /etc /lib /sbin /usr
```

### 特殊权限位说明

```bash
# 粘滞位 (Sticky Bit) - 用于/tmp目录
chmod 1777 /tmp  # 只有文件所有者能删除自己的文件

# SetGID位 - 用于共享目录
chmod 2775 /shared  # 新文件继承目录的组

# SetUID位 - 谨慎使用
chmod 4755 /usr/bin/special-command  # 以文件所有者身份运行
```

---

## 6. 企业级最佳实践

### 1. 分区规划建议

```bash
# 推荐的分区方案（企业级）
/          20-50GB      根分区
/boot      1-2GB        启动分区
/home      根据需求     用户数据
/tmp       5-10GB       临时文件
/var       20-50GB      日志和可变数据
/opt       10-20GB      第三方软件
/usr       10-20GB      系统程序
swap       内存1-2倍    交换分区（现代系统可减小）
```

### 2. 安全加固措施

```bash
# 设置严格的挂载选项
/dev/sda1  /     ext4  defaults,nodev,nosuid  0  1
/dev/sda2  /tmp  ext4  defaults,nodev,nosuid,noexec  0  2
/dev/sda3  /var  ext4  defaults,nodev,nosuid  0  2
/dev/sda4  /home ext4  defaults,nodev,nosuid  0  2

# 创建专用分区
mkdir /opt/application
mount /dev/sdb1 /opt/application
chown app-user:app-group /opt/application
```

### 3. 监控和维护

```bash
# 磁盘空间监控
df -h
# 目录大小分析
du -sh /var/log/*
# 查找大文件
find /var -type f -size +100M -exec ls -lh {} \;
# 清理旧日志
find /var/log -name "*.log" -mtime +30 -delete
```

### 4. 备份策略

```bash
# 必须备份的目录
/etc          # 配置文件
/home         # 用户数据
/var/lib      # 应用程序数据
/opt          # 第三方软件
/boot         # 启动文件

# 备份脚本示例
#!/bin/bash
BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/etc.tar.gz /etc
tar -czf $BACKUP_DIR/home.tar.gz /home
tar -czf $BACKUP_DIR/var-lib.tar.gz /var/lib
```

---

## 8. 权限速查表

| 目录     | 权限   | 所有者       | 特殊说明      |
|--------|------|-----------|-----------|
| /      | 755  | root:root | 根目录       |
| /bin   | 755  | root:root | 基础命令      |
| /boot  | 755  | root:root | 启动文件      |
| /dev   | 755  | root:root | 设备文件      |
| /etc   | 755  | root:root | 配置文件      |
| /home  | 755  | root:root | 用户主目录     |
| /lib   | 755  | root:root | 共享库       |
| /media | 755  | root:root | 可移动媒体     |
| /mnt   | 755  | root:root | 临时挂载点     |
| /opt   | 755  | root:root | 可选软件      |
| /proc  | 555  | root:root | 虚拟文件系统    |
| /root  | 550  | root:root | root用户主目录 |
| /run   | 755  | root:root | 运行时数据     |
| /sbin  | 755  | root:root | 系统命令      |
| /srv   | 755  | root:root | 服务数据      |
| /tmp   | 1777 | root:root | 粘滞位       |
| /usr   | 755  | root:root | 用户程序      |
| /var   | 755  | root:root | 可变数据      |

---

## 9. 总结

Ubuntu 文件系统结构遵循标准规范，理解每个目录的用途对于系统管理和安全至关重要。企业级环境中应特别注意：

1. **权限管理** - 严格控制目录权限，防止未授权访问
2. **分区规划** - 合理分配磁盘空间，避免单一分区过大
3. **安全挂载** - 使用适当的挂载选项增强安全性
4. **定期监控** - 监控磁盘使用和目录增长
5. **备份策略** - 制定完善的备份计划，确保数据安全

掌握这些知识将帮助您构建更安全、更高效的 Ubuntu 企业级系统。

---

## 🐳 Docker 数据库数据卷挂载最佳实践

在企业级环境中，使用 Docker 部署数据库（MySQL、Redis、MongoDB 等）时，数据卷的挂载位置选择至关重要。

### 📁 推荐挂载目录：`/opt/docker-volumes/`

**为什么选择 `/opt` 目录？**

- ✅ **符合 FHS 标准**：`/opt` 专门用于可选的第三方应用程序
- ✅ **权限管理清晰**：便于设置和管理权限
- ✅ **结构清晰**：易于组织和维护
- ✅ **企业级适用**：适合生产环境使用

### 🏗️ 推荐的目录结构

```
/opt/docker-volumes/
├── mysql/
│   ├── data/          # MySQL 数据文件
│   ├── config/        # MySQL 配置文件
│   ├── logs/          # MySQL 日志文件
│   └── backup/        # MySQL 备份文件
├── redis/
│   ├── data/          # Redis 数据文件
│   ├── config/        # Redis 配置文件
│   └── logs/          # Redis 日志文件
├── mongodb/
│   ├── data/          # MongoDB 数据文件
│   ├── config/        # MongoDB 配置文件
│   └── logs/          # MongoDB 日志文件
└── shared/            # 共享数据（可选）
    ├── ssl/           # SSL 证书
    └── scripts/       # 通用脚本
```

### 🔧 目录创建和权限设置

```bash
# 创建基础目录结构
sudo mkdir -p /opt/docker-volumes/{mysql,redis,mongodb}/{data,config,logs,backup}
sudo mkdir -p /opt/docker-volumes/shared/{ssl,scripts}

# 设置权限（Docker 默认使用 root 用户）
sudo chown -R root:root /opt/docker-volumes
sudo chmod -R 755 /opt/docker-volumes

# 数据目录设置更严格权限
sudo chmod 750 /opt/docker-volumes/*/data
```

### 🚀 Docker 挂载示例

#### MySQL 容器挂载

```bash
docker run -d \
  --name mysql-production \
  -p 3306:3306 \
  -v /opt/docker-volumes/mysql/data:/var/lib/mysql \
  -v /opt/docker-volumes/mysql/config:/etc/mysql/conf.d \
  -v /opt/docker-volumes/mysql/logs:/var/log/mysql \
  -e MYSQL_ROOT_PASSWORD=your-secure-password \
  --restart=unless-stopped \
  mysql:8.0
```

#### Redis 容器挂载

```bash
docker run -d \
  --name redis-production \
  -p 6379:6379 \
  -v /opt/docker-volumes/redis/data:/data \
  -v /opt/docker-volumes/redis/config:/usr/local/etc/redis \
  -v /opt/docker-volumes/redis/logs:/var/log/redis \
  --restart=unless-stopped \
  redis:7-alpine
```

#### MongoDB 容器挂载

```bash
docker run -d \
  --name mongodb-production \
  -p 27017:27017 \
  -v /opt/docker-volumes/mongodb/data:/data/db \
  -v /opt/docker-volumes/mongodb/config:/etc/mongo \
  -v /opt/docker-volumes/mongodb/logs:/var/log/mongodb \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=your-secure-password \
  --restart=unless-stopped \
  mongo:6
```

### 📊 挂载目录对比分析

| 目录选项                       | 是否推荐       | 原因说明                |
|----------------------------|------------|---------------------|
| `/opt/docker-volumes/`     | ✅ **强烈推荐** | 符合 FHS 标准，权限清晰，结构明确 |
| `/var/lib/docker/volumes/` | ❌ **不推荐**  | Docker 内部管理，不应手动操作  |
| `/home/docker/`            | ⚠️ 次选      | 用户目录，不够专业           |
| `/srv/docker/`             | ⚠️ 可选      | 服务数据，但 `/opt` 更合适   |
| `/mnt/docker/`             | ❌ 不推荐      | 临时挂载点，不适合长期使用       |
| `/data/`                   | ⚠️ 可选      | 非标准目录，需要额外配置        |

### 🛡️ 企业级安全最佳实践

#### 1. 权限最小化原则

```bash
# 只为必要用户授权
sudo chmod 750 /opt/docker-volumes/mysql/data    # 仅数据目录严格权限
sudo chmod 755 /opt/docker-volumes/mysql/config # 配置文件可读
sudo chmod 750 /opt/docker-volumes/mysql/logs   # 日志文件保护
```

#### 2. 独立分区建议

```bash
# 为 Docker 卷创建独立分区（推荐）
sudo mkdir /opt/docker-volumes
sudo mount /dev/sdb1 /opt/docker-volumes

# 设置自动挂载
 echo "/dev/sdb1 /opt/docker-volumes ext4 defaults,nodev,nosuid 0 2" | sudo tee -a /etc/fstab
```

#### 3. 备份策略

```bash
# 创建备份脚本
#!/bin/bash
BACKUP_DIR="/backup/docker-volumes/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# 备份 MySQL 数据
tar -czf "$BACKUP_DIR/mysql-data.tar.gz" -C /opt/docker-volumes mysql/data

# 备份 Redis 数据
tar -czf "$BACKUP_DIR/redis-data.tar.gz" -C /opt/docker-volumes redis/data

# 备份 MongoDB 数据
tar -czf "$BACKUP_DIR/mongodb-data.tar.gz" -C /opt/docker-volumes mongodb/data
```

### 🔄 Docker Compose 配置示例

```yaml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    container_name: mysql-production
    ports:
      - "3306:3306"
    volumes:
      - /opt/docker-volumes/mysql/data:/var/lib/mysql
      - /opt/docker-volumes/mysql/config:/etc/mysql/conf.d
      - /opt/docker-volumes/mysql/logs:/var/log/mysql
    environment:
      MYSQL_ROOT_PASSWORD: your-secure-password
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: redis-production
    ports:
      - "6379:6379"
    volumes:
      - /opt/docker-volumes/redis/data:/data
      - /opt/docker-volumes/redis/config:/usr/local/etc/redis
      - /opt/docker-volumes/redis/logs:/var/log/redis
    restart: unless-stopped

  mongodb:
    image: mongo:6
    container_name: mongodb-production
    ports:
      - "27017:27017"
    volumes:
      - /opt/docker-volumes/mongodb/data:/data/db
      - /opt/docker-volumes/mongodb/config:/etc/mongo
      - /opt/docker-volumes/mongodb/logs:/var/log/mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: your-secure-password
    restart: unless-stopped
```

### 📋 一键创建脚本

```bash
#!/bin/bash
# create-docker-volumes.sh - 创建 Docker 数据库卷目录结构

BASE_DIR="/opt/docker-volumes"
DATABASES=("mysql" "redis" "mongodb" "postgres")

echo "🚀 创建 Docker 数据库卷目录结构..."

# 创建基础目录
sudo mkdir -p "$BASE_DIR"

# 为每个数据库创建目录结构
for db in "${DATABASES[@]}"; do
    echo "📁 创建 $db 目录结构..."
    sudo mkdir -p "$BASE_DIR/$db"/{data,config,logs,backup}
    
    # 设置权限
    sudo chown -R root:root "$BASE_DIR/$db"
    sudo chmod -R 755 "$BASE_DIR/$db"
    sudo chmod 750 "$BASE_DIR/$db/data"  # 数据目录更严格
    
    # 创建 .gitkeep 文件（便于 Git 管理）
    sudo touch "$BASE_DIR/$db"/{data,config,logs,backup}/.gitkeep
done

# 创建共享目录
echo "📁 创建共享目录..."
sudo mkdir -p "$BASE_DIR/shared"/{ssl,scripts}
sudo chmod -R 755 "$BASE_DIR/shared"

# 创建 README 文件
sudo tee "$BASE_DIR/README.md" > /dev/null << 'EOF'
# Docker Volumes Directory

此目录用于存放 Docker 容器的数据卷，特别是数据库服务的数据。

## 目录结构

- `mysql/` - MySQL 数据库数据
- `redis/` - Redis 缓存数据
- `mongodb/` - MongoDB 数据库数据
- `postgres/` - PostgreSQL 数据库数据
- `shared/` - 共享数据（SSL 证书、脚本等）

## 权限说明

- `data/` 目录权限为 750（严格保护）
- `config/` 目录权限为 755（配置文件可读）
- `logs/` 目录权限为 755（日志文件可读）
- `backup/` 目录权限为 755（备份文件可管理）

## 使用说明

请参考具体的 Docker 部署文档进行容器挂载配置。
EOF

echo "✅ 目录创建完成！结构如下："
ls -la "$BASE_DIR"
echo ""
echo "📊 磁盘使用情况："
df -h "$BASE_DIR"
```

### 🔍 验证和监控

```bash
# 验证挂载状态
docker exec mysql-production df -h

# 检查数据目录权限
ls -la /opt/docker-volumes/mysql/data

# 监控磁盘使用
df -h /opt/docker-volumes

# 查看容器日志
docker logs mysql-production
```

### ⚠️ 重要注意事项

1. **权限问题**：确保 Docker 容器有权限访问挂载目录
2. **SELinux/AppArmor**：可能需要配置额外的安全策略
3. **备份策略**：定期备份数据目录
4. **监控告警**：设置磁盘空间监控
5. **日志轮转**：配置日志文件轮转防止磁盘满

通过使用 `/opt/docker-volumes/` 目录结构，您可以构建一个专业、安全、易于管理的 Docker 数据库环境，完全符合企业级生产环境的要求。