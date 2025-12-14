# 远程服务器管理工具使用说明

这个工具集用于连接和管理你的远程服务器（192.168.157.129）。

## 快速开始

### 1. 测试连接
首先测试是否能连接到服务器：
```bash
# 使用默认用户(root)测试连接
./test-ssh-connection.sh

# 使用指定用户测试连接
./test-ssh-connection.sh ubuntu
```

### 2. 连接服务器
使用交互式SSH连接：
```bash
# 使用默认用户连接
./ssh-connect.sh

# 使用指定用户连接
./ssh-connect.sh ubuntu
```

### 3. 执行命令
在服务器上执行单个命令：
```bash
# 查看系统信息
./ssh-execute.sh "uname -a"

# 查看磁盘空间
./ssh-execute.sh "df -h"

# 查看Docker状态
./ssh-execute.sh "docker ps"

# 使用指定用户执行命令
./ssh-execute.sh "uptime" ubuntu
```

### 4. 完整部署Docker环境
一键部署Docker企业级环境：
```bash
# 完整部署（系统更新 + Docker安装 + 目录创建）
./deploy-remote-docker.sh full

# 仅安装Docker
./deploy-remote-docker.sh docker-only

# 检查环境状态
./deploy-remote-docker.sh check
```

### 5. 使用交互式管理工具
使用菜单驱动的管理界面：
```bash
./remote-server-manager.sh
```

## 常用命令示例

### 系统检查
```bash
# 查看系统版本
./ssh-execute.sh "cat /etc/os-release"

# 查看内存使用
./ssh-execute.sh "free -h"

# 查看磁盘空间
./ssh-execute.sh "df -h"

# 查看系统负载
./ssh-execute.sh "uptime"
```

### Docker相关
```bash
# 查看Docker版本
./ssh-execute.sh "docker --version"

# 查看运行中的容器
./ssh-execute.sh "docker ps"

# 查看所有镜像
./ssh-execute.sh "docker images"

# 查看Docker系统信息
./ssh-execute.sh "docker system df"
```

### 文件和目录
```bash
# 查看/opt目录内容
./ssh-execute.sh "ls -la /opt"

# 查看Docker卷目录
./ssh-execute.sh "ls -la /opt/docker-volumes/"

# 查看日志文件
./ssh-execute.sh "ls -la /var/log/docker-volumes/"
```

## 故障排除

### 连接失败
如果连接失败，请检查：
1. 服务器IP地址是否正确（192.168.157.129）
2. SSH服务是否在服务器上运行
3. 防火墙是否允许SSH连接（端口22）
4. 用户名和密码是否正确
5. 网络是否连通

### 权限问题
如果遇到权限问题：
1. 确保使用具有sudo权限的用户
2. 对于某些操作，可能需要使用root用户
3. 检查服务器上的文件和目录权限

### Windows用户
在Windows上使用这些脚本：
1. 安装Git Bash
2. 或者安装OpenSSH客户端
3. 在PowerShell中运行脚本

## 安全提示

1. **密码安全**：不要在命令行中明文输入密码
2. **密钥认证**：建议使用SSH密钥认证
3. **权限控制**：使用具有适当权限的用户
4. **网络安全**：确保网络连接安全

## 扩展功能

你可以根据需要修改这些脚本：
- 修改服务器IP地址
- 添加新的命令
- 自定义部署流程
- 添加监控和告警功能

## 获取帮助

如果需要更多帮助，可以：
1. 查看脚本的帮助信息：`./script-name.sh --help`
2. 检查脚本中的注释
3. 根据你的具体需求修改脚本