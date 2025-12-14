# Docker Compose 环境变量优先级详细说明

## 概述

在 Docker Compose 中，环境变量的设置有多种方式，它们之间存在优先级顺序。理解这个优先级对于正确配置容器化应用至关重要。

## 环境变量设置方式

### 1. Docker Compose 文件中的默认值（最低优先级）
```yaml
environment:
  MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-sakura_dev_root}
  MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
  MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minioadmin2025}
```

**说明：**
- `${VARIABLE:-default}` 语法表示：如果环境变量 `VARIABLE` 未设置，则使用默认值 `default`
- 这是最低优先级的设置方式

### 2. .env 文件中的变量值（中等优先级）
```bash
# .env 文件内容
MYSQL_ROOT_PASSWORD=my_custom_password
MINIO_ROOT_USER=my_custom_user
MINIO_ROOT_PASSWORD=my_custom_password_2024
```

**说明：**
- `.env` 文件位于 Docker Compose 文件同级目录
- 会覆盖 Docker Compose 文件中的默认值
- 属于中等优先级

### 3. Shell 环境变量（最高优先级）
```bash
# 在命令行中设置
export MYSQL_ROOT_PASSWORD=shell_password
export MINIO_ROOT_USER=shell_user

# 启动服务
docker-compose up -d
```

**说明：**
- Shell 环境变量具有最高优先级
- 会覆盖 .env 文件和 Docker Compose 文件中的设置

## 优先级总结

**从高到低：**
1. **Shell 环境变量**（最高优先级）
2. **.env 文件中的变量**
3. **Docker Compose 文件中的默认值**（最低优先级）

## 实际应用示例

### 场景 1：仅使用 Docker Compose 默认值
```yaml
# docker-compose.yml
environment:
  MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
  MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minioadmin2025}
```

**结果：**
- 用户名：minioadmin
- 密码：minioadmin2025

### 场景 2：使用 .env 文件覆盖
```yaml
# docker-compose.yml
environment:
  MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
  MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minioadmin2025}
```

```bash
# .env 文件
MINIO_ROOT_USER=custom_user
MINIO_ROOT_PASSWORD=custom_password_2024
```

**结果：**
- 用户名：custom_user
- 密码：custom_password_2024

### 场景 3：使用 Shell 环境变量覆盖
```yaml
# docker-compose.yml
environment:
  MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
  MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minioadmin2025}
```

```bash
# .env 文件
MINIO_ROOT_USER=custom_user
MINIO_ROOT_PASSWORD=custom_password_2024
```

```bash
# Shell 环境变量
export MINIO_ROOT_USER=shell_user
export MINIO_ROOT_PASSWORD=shell_password_2024
```

**结果：**
- 用户名：shell_user
- 密码：shell_password_2024

## 最佳实践建议

### 1. 开发环境
- 使用 `.env` 文件管理配置
- 将 `.env` 文件添加到 `.gitignore`
- 提供 `.env.example` 作为模板

### 2. 生产环境
- 使用 Shell 环境变量或密钥管理工具
- 避免在代码库中存储敏感信息
- 定期轮换密码和密钥

### 3. 配置管理
```bash
# 推荐的项目结构
project/
├── docker-compose.yml
├── .env.example          # 配置模板
├── .env                 # 实际配置（不提交到版本控制）
└── README.md            # 配置说明
```

## 常见问题排查

### 问题 1：环境变量不生效
**检查步骤：**
1. 确认变量名拼写正确
2. 检查优先级顺序
3. 重启容器使配置生效

### 问题 2：MinIO 登录失败
**检查步骤：**
1. 查看当前生效的用户名密码
2. 检查环境变量设置
3. 验证容器内的环境变量

```bash
# 查看容器内环境变量
docker exec osmanthus-minio env | grep MINIO
```

## 安全建议

1. **生产环境必修改默认密码**
2. **使用强密码策略**
3. **定期更新敏感配置**
4. **启用 SSL/TLS 加密**
5. **配置防火墙规则**

## 相关命令

```bash
# 查看当前环境变量
docker exec osmanthus-minio env

# 查看容器日志
docker logs osmanthus-minio

# 重启服务使配置生效
docker-compose restart osmanthus-minio

# 验证配置
curl -f http://localhost:9000/minio/health/live
```

## 总结

理解 Docker Compose 环境变量的优先级对于正确配置应用非常重要。建议按照以下优先级使用：

1. **开发环境**：使用 `.env` 文件
2. **测试环境**：使用 `.env` 文件 + 部分 Shell 变量
3. **生产环境**：使用 Shell 环境变量或专业密钥管理工具

这样可以确保配置的灵活性和安全性。