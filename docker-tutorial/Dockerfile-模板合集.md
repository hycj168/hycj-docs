# Dockerfile 模板合集 - 企业级后端服务

## 📝 使用说明

这个模板合集提供了各种场景下的 Dockerfile 模板，从基础到企业级，你可以根据项目需求选择合适的模板进行修改。

## 🎯 模板 1：基础模板（适合学习）

```dockerfile
# 基础模板 - 适合简单项目和初学者
FROM openjdk:21-jdk-slim

WORKDIR /app

# 复制应用文件
COPY target/myapp.jar app.jar

# 暴露端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**构建命令：**
```bash
docker build -t myapp:basic .
docker run -p 8080:8080 myapp:basic
```

---

## 🚀 模板 2：优化模板（适合开发环境）

```dockerfile
# 优化模板 - 添加了健康检查和非root用户
FROM openjdk:21-jre-slim

# 创建应用用户
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# 复制应用文件
COPY target/myapp.jar app.jar

# 设置权限
RUN chown appuser:appuser app.jar

# 切换到非root用户
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

**构建命令：**
```bash
docker build -t myapp:optimized .
docker run -p 8080:8080 myapp:optimized
```

---

## ⚡ 模板 3：多阶段构建模板（推荐）

```dockerfile
# 多阶段构建模板 - 显著减小镜像大小
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /build

# 复制依赖文件
COPY pom.xml .
COPY src/main/resources/application.yml src/main/resources/

# 下载依赖（缓存层）
RUN mvn dependency:go-offline -B

# 复制源代码
COPY src ./src

# 构建应用
RUN mvn clean package -DskipTests

# 运行阶段
FROM eclipse-temurin:21-jre

# 安装必要工具
RUN apt-get update && apt-get install -y \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN groupadd -r appuser && useradd -r -g appuser -s /bin/bash appuser

WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=builder /build/target/*.jar app.jar

# 创建日志目录
RUN mkdir -p /app/logs && chown -R appuser:appuser /app

# 切换到非root用户
USER appuser

# 环境变量
ENV JAVA_OPTS="-Xms256m -Xmx512m"
ENV SPRING_PROFILES_ACTIVE=prod

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 数据卷
VOLUME ["/app/logs"]

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE -jar app.jar"]
```

**构建命令：**
```bash
docker build -t myapp:multi-stage .
docker run -p 8080:8080 -v ./logs:/app/logs myapp:multi-stage
```

---

## 🏢 模板 4：企业级模板（生产推荐）

```dockerfile
# 企业级模板 - 完整的生产环境配置
FROM gradle:8.11.1-jdk21-alpine AS builder

# 标签信息
LABEL maintainer="Your Team <team@company.com>"
LABEL version="1.0.0"
LABEL description="Enterprise Backend Service"

WORKDIR /build

# 复制构建文件
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle

# 下载依赖
RUN gradle dependencies --no-daemon

# 复制源代码
COPY src ./src

# 构建应用
RUN gradle build -x test --no-daemon --info

# 运行阶段
FROM eclipse-temurin:21-jre

# 安装必要工具
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    netcat-openbsd \
    jq \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN groupadd -r appservice && useradd -r -g appservice -s /bin/bash appservice

WORKDIR /app

# 参数定义
ARG JAR_FILE=build/libs/*.jar
ARG JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication"

# 环境变量
ENV JAVA_OPTS=${JAVA_OPTS}
ENV SPRING_PROFILES_ACTIVE=prod
ENV SERVER_PORT=8080
ENV LOG_PATH=/app/logs

# 创建必要目录
RUN mkdir -p /app/logs /app/uploads /app/temp /app/config && \
    chown -R appservice:appservice /app

# 复制构建好的 JAR 文件
COPY --from=builder /build/build/libs/*.jar app.jar

# 设置文件权限
RUN chown appservice:appservice app.jar && chmod 755 app.jar

# 切换到非root用户
USER appservice

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 暴露端口
EXPOSE 8080

# 入口脚本
COPY <<'EOF' /app/entrypoint.sh
#!/bin/bash
set -e

echo "🚀 Enterprise Backend Service Starting..."

# 等待数据库服务
if [ ! -z "$DB_HOST" ]; then
    echo "等待数据库服务就绪..."
    while ! nc -z ${DB_HOST} ${DB_PORT:-3306}; do
        sleep 1
    done
    echo "数据库连接成功 ✓"
fi

# 等待Redis服务
if [ ! -z "$REDIS_HOST" ]; then
    echo "等待Redis服务就绪..."
    while ! nc -z ${REDIS_HOST} ${REDIS_PORT:-6379}; do
        sleep 1
    done
    echo "Redis连接成功 ✓"
fi

# 创建必要的目录
mkdir -p ${LOG_PATH} /app/uploads /app/temp

# 启动应用
echo "启动 Spring Boot 应用..."
exec java ${JAVA_OPTS} \
  -Djava.security.egd=file:/dev/./urandom \
  -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} \
  -Dserver.port=${SERVER_PORT} \
  -Dlogging.file.path=${LOG_PATH} \
  -jar app.jar
EOF

# 设置入口脚本权限
USER root
RUN chmod +x /app/entrypoint.sh
USER appservice

# 数据卷
VOLUME ["/app/logs", "/app/uploads", "/app/temp"]

# 入口点
ENTRYPOINT ["/app/entrypoint.sh"]

# OCI 标准标签
LABEL org.opencontainers.image.title="Enterprise Backend Service"
LABEL org.opencontainers.image.description="Production-ready backend service"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="Your Team"
LABEL org.opencontainers.image.source="https://github.com/your-org/your-service"
LABEL org.opencontainers.image.licenses="MIT"
```

**构建命令：**
```bash
# 构建企业级镜像
docker build -t myapp:enterprise .

# 运行企业级容器
docker run -d \
  --name myapp-prod \
  -p 8080:8080 \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e REDIS_HOST=redis \
  -e REDIS_PORT=6379 \
  -v ./logs:/app/logs \
  -v ./uploads:/app/uploads \
  myapp:enterprise
```

---

## 🔧 模板 5：微服务模板（Spring Cloud）

```dockerfile
# 微服务模板 - 适用于 Spring Cloud 微服务架构
FROM gradle:8.11.1-jdk21-alpine AS builder

WORKDIR /build

# 复制构建配置
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle

# 预下载依赖
RUN gradle dependencies --no-daemon

# 复制源码
COPY src ./src

# 构建
RUN gradle build -x test --no-daemon

# 运行阶段
FROM eclipse-temurin:21-jre

# 安装监控工具
RUN apt-get update && apt-get install -y \
    curl \
    htop \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# 创建服务用户
RUN groupadd -r microservice && useradd -r -g microservice microservice

WORKDIR /app

# 环境变量
ENV JAVA_OPTS="-Xms256m -Xmx512m"
ENV SPRING_PROFILES_ACTIVE=docker
ENV EUREKA_CLIENT_ENABLED=true
ENV CONFIG_SERVER_ENABLED=true

# 复制 JAR
COPY --from=builder /build/build/libs/*.jar service.jar

# 权限设置
RUN chown microservice:microservice service.jar

USER microservice

# 健康检查（针对微服务）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health && \
      (test -z "$EUREKA_CLIENT_ENABLED" || curl -f http://localhost:8080/actuator/info) || exit 1

EXPOSE 8080

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE -jar service.jar"]
```

**构建命令：**
```bash
# 构建微服务镜像
docker build -t myservice:microservice .

# 在 Docker Compose 中使用
# docker-compose.yml
version: '3.8'
services:
  myservice:
    image: myservice:microservice
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://eureka:8761/eureka/
      - CONFIG_SERVER_URI=http://config-server:8888
    ports:
      - "8080:8080"
    depends_on:
      - eureka
      - config-server
```

---

## 🚀 模板 6：快速开发模板（带热重载）

```dockerfile
# 快速开发模板 - 支持热重载和开发工具
FROM gradle:8.11.1-jdk21-alpine AS builder

WORKDIR /build

# 复制构建文件
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle

# 下载依赖
RUN gradle dependencies --no-daemon

# 复制源码
COPY src ./src

# 构建
RUN gradle build -x test --no-daemon

# 开发阶段
FROM gradle:8.11.1-jdk21-alpine

WORKDIR /app

# 安装开发工具
RUN apk add --no-cache \
    curl \
    vim \
    htop \
    net-tools \
    && rm -rf /var/cache/apk/*

# 环境变量
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:MaxMetaspaceSize=256m"
ENV SPRING_PROFILES_ACTIVE=dev
ENV SPRING_DEVTOOLS_RESTART_ENABLED=true

# 创建源码目录
RUN mkdir -p /app/src

# 复制构建文件
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle

# 复制构建好的 JAR
COPY --from=builder /build/build/libs/*.jar app.jar

# 复制源码（用于热重载）
COPY src ./src

# 暴露调试端口
EXPOSE 8080 5005

# 开发模式启动
CMD ["gradle", "bootRun", "--continuous"]
```

**构建命令：**
```bash
# 构建开发镜像
docker build -t myapp:dev .

# 运行开发容器（带热重载）
docker run -d \
  --name myapp-dev \
  -p 8080:8080 \
  -p 5005:5005 \
  -v $(pwd)/src:/app/src \
  -e SPRING_PROFILES_ACTIVE=dev \
  myapp:dev
```

---

## 🏭 模板 7：CI/CD 优化模板

```dockerfile
# CI/CD 优化模板 - 专为持续集成设计
FROM gradle:8.11.1-jdk21-alpine AS dependencies

WORKDIR /build

# 只复制依赖文件（最大化缓存）
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle

# 下载所有依赖
RUN gradle dependencies --no-daemon

FROM dependencies AS builder

# 复制源码
COPY src ./src

# 参数化构建
ARG BUILD_ARGS=""
ARG SKIP_TESTS="false"

# 条件化构建
RUN if [ "$SKIP_TESTS" = "true" ]; then \
        gradle build -x test --no-daemon $BUILD_ARGS; \
    else \
        gradle build --no-daemon $BUILD_ARGS; \
    fi

# 测试阶段（可选）
FROM builder AS test
RUN gradle test --no-daemon

# 安全扫描阶段
FROM aquasec/trivy:latest AS security-scan
COPY --from=builder /build/build/libs/*.jar /app.jar
RUN trivy fs --severity HIGH,CRITICAL /app.jar

# 最终镜像
FROM eclipse-temurin:21-jre

# 安全加固
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# 创建用户
RUN groupadd -r app && useradd -r -g app app

WORKDIR /app

# 复制构建产物
COPY --from=builder /build/build/libs/*.jar app.jar

# 设置用户和权限
RUN chown app:app app.jar
USER app

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

**构建命令：**
```bash
# CI/CD 构建（跳过测试）
docker build \
  --build-arg SKIP_TESTS=true \
  --build-arg BUILD_ARGS="--info" \
  -t myapp:cicd .

# 完整构建（包含测试）
docker build -t myapp:full .
```

---

## 📋 模板选择指南

| 模板 | 适用场景 | 镜像大小 | 构建时间 | 推荐用途 |
|------|----------|----------|----------|----------|
| **基础模板** | 学习测试 | ⭐⭐ | ⭐⭐⭐⭐⭐ | 教学、快速原型 |
| **优化模板** | 开发环境 | ⭐⭐⭐ | ⭐⭐⭐⭐ | 日常开发 |
| **多阶段模板** | 生产环境 | ⭐⭐⭐⭐ | ⭐⭐⭐ | 生产部署 |
| **企业级模板** | 企业生产 | ⭐⭐⭐⭐⭐ | ⭐⭐ | 企业级应用 |
| **微服务模板** | 微服务架构 | ⭐⭐⭐⭐ | ⭐⭐ | 云原生应用 |
| **开发模板** | 热重载开发 | ⭐⭐ | ⭐ | 开发调试 |
| **CI/CD模板** | 持续集成 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 自动化部署 |

## 🎯 选择建议

### 🔰 初学者
- **从基础模板开始**，理解 Docker 基本概念
- **逐步添加功能**，如健康检查、用户权限等
- **学习多阶段构建**，理解镜像优化原理

### 👨‍💻 开发者
- **使用多阶段模板**，平衡构建速度和镜像大小
- **添加开发工具**，如调试端口、热重载等
- **配置环境变量**，支持不同环境部署

### 🏢 企业用户
- **使用企业级模板**，完整的生产环境配置
- **安全加固**，非 root 用户、最小权限原则
- **监控集成**，健康检查、日志收集等

### ☁️ 云原生用户
- **使用微服务模板**，支持服务发现和配置中心
- **多平台构建**，支持不同 CPU 架构
- **服务网格集成**，支持 Istio 等服务网格

## 🔧 自定义建议

### 1. 根据项目类型调整
```dockerfile
# Spring Boot 项目
FROM eclipse-temurin:21-jre

# Node.js 项目
FROM node:18-alpine

# Python 项目
FROM python:3.11-alpine

# .NET 项目
FROM mcr.microsoft.com/dotnet/aspnet:7.0
```

### 2. 根据性能需求调整
```dockerfile
# 高内存应用
ENV JAVA_OPTS="-Xms2g -Xmx4g -XX:+UseG1GC"

# 低延迟应用
ENV JAVA_OPTS="-Xms1g -Xmx2g -XX:+UseZGC"

# 小内存应用
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseSerialGC"
```

### 3. 根据安全要求调整
```dockerfile
# 高安全要求
FROM alpine:3.18
RUN apk add --no-cache openjdk21-jre
# 最小化攻击面

# 合规要求
LABEL com.company.security.classification="confidential"
LABEL com.company.compliance.gdpr="true"
```

## 📚 相关资源

- [Docker 官方最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile 参考文档](https://docs.docker.com/engine/reference/builder/)
- [OCI 镜像规范](https://github.com/opencontainers/image-spec)
- [容器安全最佳实践](https://kubernetes.io/docs/concepts/security/)

---

**💡 提示**：选择模板时，要从项目实际需求出发，不要盲目追求复杂。简单的项目用简单的模板，复杂的项目用功能完整的模板。

**🚀 建议**：先从基础模板开始，逐步理解和添加高级功能，最终形成适合自己项目的定制化 Dockerfile。