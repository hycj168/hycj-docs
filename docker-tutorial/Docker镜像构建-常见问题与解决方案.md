# Docker 镜像构建常见问题与解决方案 🔧

## 📋 概述

本文档总结了 Docker 镜像构建过程中常见的问题及其解决方案，帮助开发者快速定位和解决问题。

---

## 🚨 构建阶段常见问题

### 1. 构建失败 - 网络连接问题

**问题描述：**
```
ERROR: failed to solve: rpc error: code = Unknown desc = failed to solve with frontend dockerfile.v0: 
failed to build LLB: failed to load cache key: pull access denied, repository does not exist or may require authorization
```

**解决方案：**
```bash
# 1. 检查网络连接
ping registry-1.docker.io

# 2. 配置 Docker 镜像加速器（中国用户）
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}

# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 3. 使用代理（如果需要）
# 设置环境变量
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
```

---

### 2. 构建失败 - 基础镜像不存在

**问题描述：**
```
ERROR: failed to solve: eclipse-temurin:21-jre: pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
```

**解决方案：**
```bash
# 1. 检查镜像名称拼写
docker pull eclipse-temurin:21-jre    # 正确
docker pull eclipse-temurin:21-jdk     # 错误，镜像不存在

# 2. 查找可用版本
docker search eclipse-temurin
docker pull eclipse-temurin:21-jre-alpine  # 使用 Alpine 版本

# 3. 使用替代镜像
FROM openjdk:21-jre-slim              # 替代方案
FROM amazoncorretto:21-alpine-jre      # AWS 替代方案
FROM azul/zulu-openjdk:21-jre         # Azul 替代方案
```

---

### 3. 构建失败 - 依赖下载超时

**问题描述：**
```
Could not resolve dependencies for project com.example:myapp:jar:1.0.0
Could not transfer artifact org.springframework.boot:spring-boot-starter-web:jar:3.2.0 from/to central (https://repo.maven.apache.org/maven2): Connection timed out
```

**解决方案：**
```dockerfile
# 1. 增加重试机制和超时设置
FROM maven:3.9-eclipse-temurin-21 AS builder

# 设置 Maven 配置
COPY settings.xml /root/.m2/settings.xml

# 增加重试次数和超时时间
RUN mvn dependency:go-offline -B \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -Dmaven.wagon.http.retryHandler.count=3 \
    -Dmaven.wagon.http.pool=false

# 2. 使用国内镜像源
# settings.xml 内容：
"""
<settings>
  <mirrors>
    <mirror>
      <id>aliyunmaven</id>
      <mirrorOf>*</mirrorOf>
      <name>阿里云公共仓库</name>
      <url>https://maven.aliyun.com/repository/public</url>
    </mirror>
  </mirrors>
</settings>
"""

# 3. 分阶段下载依赖
RUN mvn dependency:resolve -B || mvn dependency:resolve -B || mvn dependency:resolve -B
```

---

### 4. 构建失败 - 内存不足

**问题描述：**
```
OpenJDK 64-Bit Server VM warning: INFO: os::commit_memory(0x00000000c0000000, 536870912, 0) failed; error='Not enough space' (errno=12)
```

**解决方案：**
```bash
# 1. 增加 Docker 构建内存限制
export DOCKER_BUILDKIT=1
export BUILDKIT_STEP_LOG_MAX_SIZE=104857600

# 2. 优化 JVM 参数
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:MaxMetaspaceSize=256m"

# 3. 使用更小的基础镜像
FROM eclipse-temurin:21-jre-alpine  # 比完整版小很多

# 4. 清理不必要的文件
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

---

## 🐳 镜像大小优化问题

### 1. 镜像过大

**问题描述：**
基础镜像 500MB，最终镜像 1.2GB

**解决方案：**
```dockerfile
# 优化前（1.2GB）
FROM openjdk:21-jdk
COPY target/app.jar app.jar
CMD ["java", "-jar", "app.jar"]

# 优化后（200MB）
FROM eclipse-temurin:21-jre-alpine AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache curl
COPY --from=builder /build/target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

---

### 2. 层缓存未命中

**问题描述：**
每次构建都重新下载依赖，构建时间很长

**解决方案：**
```dockerfile
# 错误做法（缓存未命中）
COPY . .
RUN mvn package -DskipTests

# 正确做法（缓存优化）
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests
```

---

## 🔒 安全问题

### 1. 以 root 用户运行

**问题描述：**
容器以 root 用户运行，存在安全风险

**解决方案：**
```dockerfile
# 错误做法
FROM openjdk:21-jre
COPY app.jar app.jar
CMD ["java", "-jar", "app.jar"]

# 正确做法
FROM openjdk:21-jre
RUN groupadd -r appuser && useradd -r -g appuser appuser
COPY app.jar app.jar
RUN chown appuser:appuser app.jar
USER appuser
CMD ["java", "-jar", "app.jar"]
```

---

### 2. 敏感信息泄露

**问题描述：**
Dockerfile 中包含密码、密钥等敏感信息

**解决方案：**
```dockerfile
# 错误做法（泄露密码）
ENV DB_PASSWORD=mysecretpassword

# 正确做法（使用构建参数）
ARG DB_PASSWORD
ENV DB_PASSWORD=${DB_PASSWORD}

# 构建时使用
# docker build --build-arg DB_PASSWORD=$DB_PASSWORD -t myapp .

# 或者使用 Docker Secret（Swarm 模式）
echo "mysecretpassword" | docker secret create db_password -

# 在 Docker Compose 中使用
secrets:
  db_password:
    external: true
```

---

### 3. 镜像包含敏感文件

**问题描述：**
`.env` 文件、私钥等被复制到镜像中

**解决方案：**
```dockerfile
# 创建 .dockerignore 文件
cat > .dockerignore << 'EOF'
# 环境变量文件
.env
.env.local
.env.production

# 密钥文件
*.pem
*.key
id_rsa

# 日志文件
*.log
logs/

# IDE 文件
.idea/
.vscode/
*.swp
*.swo

# Git 文件
.git/
.gitignore

# 构建产物（不需要的）
target/*.original
*.tar.gz
EOF
```

---

## 🏃 运行时问题

### 1. 健康检查失败

**问题描述：**
```
Health check failed: curl: (7) Failed to connect to localhost port 8080: Connection refused
```

**解决方案：**
```dockerfile
# 问题：健康检查太早执行
HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost:8080/health || exit 1

# 解决方案：增加启动延迟
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 或者使用更简单的健康检查
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD pgrep java || exit 1
```

---

### 2. 内存溢出

**问题描述：**
```
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
```

**解决方案：**
```dockerfile
# 设置合适的 JVM 内存参数
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:MaxMetaspaceSize=256m"

# 在运行时使用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# 或者在 Docker Compose 中设置
# docker-compose.yml
services:
  app:
    image: myapp:latest
    environment:
      - JAVA_OPTS=-Xms1g -Xmx2g
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

---

### 3. 时区问题

**问题描述：**
容器内时间不正确，日志时间戳错误

**解决方案：**
```dockerfile
# 设置正确的时区
FROM openjdk:21-jre

# 方法1：设置环境变量
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 方法2：复制时区文件（Alpine）
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata
```

---

### 4. 文件权限问题

**问题描述：**
```
java.io.FileNotFoundException: /app/logs/application.log (Permission denied)
```

**解决方案：**
```dockerfile
# 确保目录权限正确
FROM openjdk:21-jre
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# 创建目录并设置权限
RUN mkdir -p /app/logs /app/uploads /app/temp && \
    chown -R appuser:appuser /app

COPY app.jar app.jar
RUN chown appuser:appuser app.jar

USER appuser

# 或者使用数据卷
VOLUME ["/app/logs", "/app/uploads"]
```

---

## 🌐 网络问题

### 1. 无法连接到数据库

**问题描述：**
```
com.mysql.cj.jdbc.exceptions.CommunicationsException: Communications link failure
```

**解决方案：**
```bash
# 1. 检查网络连接
docker exec myapp ping mysql-host

# 2. 检查端口连通性
docker exec myapp nc -zv mysql-host 3306

# 3. 等待数据库启动（在 entrypoint 中添加）
#!/bin/bash
set -e

echo "等待数据库服务..."
while ! nc -z ${DB_HOST} ${DB_PORT:-3306}; do
  sleep 1
done
echo "数据库已就绪！"

exec java -jar app.jar
```

---

### 2. DNS 解析问题

**问题描述：**
```
java.net.UnknownHostException: mysql-service
```

**解决方案：**
```bash
# 1. 检查容器网络
docker network ls
docker network inspect bridge

# 2. 使用 Docker Compose 网络
docker-compose.yml:
services:
  app:
    networks:
      - app-network
  mysql:
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

# 3. 使用 IP 地址测试
docker exec myapp nslookup mysql-service
```

---

## 📊 调试技巧

### 1. 查看构建日志

```bash
# 详细构建日志
docker build --progress=plain --no-cache -t myapp:latest .

# 查看特定步骤
docker build --target builder -t myapp:builder .
```

---

### 2. 调试运行中的容器

```bash
# 进入容器调试
docker exec -it myapp /bin/bash

# 查看环境变量
docker exec myapp env

# 查看进程
docker exec myapp ps aux

# 查看网络
docker exec myapp netstat -tlnp
```

---

### 3. 镜像分析

```bash
# 查看镜像历史
docker history myapp:latest

# 分析镜像大小
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest myapp:latest

# 安全扫描
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image myapp:latest
```

---

## 🎯 性能优化建议

### 1. 构建速度优化

```dockerfile
# 使用 BuildKit
export DOCKER_BUILDKIT=1

# 并行构建
export BUILDKIT_PROGRESS=plain

# 缓存优化
RUN --mount=type=cache,target=/root/.m2 mvn package
```

---

### 2. 镜像大小优化

```dockerfile
# 多阶段构建
FROM maven:3.9-eclipse-temurin-21 AS builder
RUN mvn package

FROM eclipse-temurin:21-jre-alpine
COPY --from=builder /app/target/app.jar app.jar

# 清理缓存
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

---

### 3. 运行时性能优化

```dockerfile
# JVM 优化
ENV JAVA_OPTS="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxGCPauseMillis=200"

# 容器感知
ENV JAVA_OPTS="$JAVA_OPTS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
```

---

## 📚 相关资源

### 官方文档
- [Dockerfile 最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile 参考](https://docs.docker.com/engine/reference/builder/)
- [Docker 安全](https://docs.docker.com/engine/security/)

### 工具推荐
- [Dive](https://github.com/wagoodman/dive) - 镜像分析工具
- [Trivy](https://github.com/aquasecurity/trivy) - 安全扫描工具
- [Hadolint](https://github.com/hadolint/hadolint) - Dockerfile 检查工具

### 社区资源
- [Docker 官方论坛](https://forums.docker.com/)
- [Stack Overflow - Docker](https://stackoverflow.com/questions/tagged/docker)
- [GitHub - Docker](https://github.com/docker)

---

**💡 记住**：遇到问题时，先查看日志，再搜索错误信息，最后参考官方文档。大多数问题都有解决方案，关键是要有系统性的排查思路。

**🚀 建议**：定期更新基础镜像，关注安全公告，使用自动化工具进行安全扫描。