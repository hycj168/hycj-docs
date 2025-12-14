# Docker 镜像构建实战练习 🚀

## 📋 练习目标

通过 3 个循序渐进的实战练习，掌握 Docker 镜像构建的核心技能：

1. **基础练习**：构建简单的 Java 应用镜像
2. **优化练习**：使用多阶段构建优化镜像
3. **企业级练习**：构建生产级镜像

---

## 🎯 练习 1：基础镜像构建

### 📖 场景描述

你是一个刚接触 Docker 的开发人员，需要将一个 Spring Boot 应用打包成 Docker 镜像。

### 🛠️ 准备工作

```bash
# 1. 创建练习目录
mkdir docker-practice-1
cd docker-practice-1

# 2. 创建模拟的 Spring Boot 应用 JAR 文件
mkdir -p target
echo "模拟 JAR 文件" > target/myapp.jar

# 3. 创建基础 Dockerfile
cat > Dockerfile << 'EOF'
FROM openjdk:21-jdk-slim

WORKDIR /app

# 复制应用文件
COPY target/myapp.jar app.jar

# 暴露端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
```

### 🚀 构建和运行

```bash
# 1. 构建镜像
docker build -t myapp:v1 .

# 2. 查看镜像信息
docker images myapp:v1

# 3. 运行容器
docker run -d --name myapp-v1 -p 8080:8080 myapp:v1

# 4. 查看容器状态
docker ps

# 5. 查看容器日志
docker logs myapp-v1

# 6. 进入容器
docker exec -it myapp-v1 /bin/bash

# 7. 停止并删除容器
docker stop myapp-v1
docker rm myapp-v1
```

### 📊 分析结果

```bash
# 查看镜像大小
docker images myapp:v1

# 查看镜像历史
docker history myapp:v1

# 查看镜像详细信息
docker inspect myapp:v1
```

### 💡 学习要点

1. **理解镜像分层**：每个指令都会创建一个新的层
2. **基础镜像选择**：openjdk:21-jdk-slim 包含了运行 Java 应用所需的环境
3. **WORKDIR 的作用**：设置工作目录，后续指令都在此目录下执行
4. **COPY 指令**：将本地文件复制到镜像中
5. **EXPOSE 指令**：声明容器运行时监听的端口
6. **ENTRYPOINT vs CMD**：理解两者的区别和使用场景

---

## 🎯 练习 2：多阶段构建优化

### 📖 场景描述

你发现基础镜像太大了，需要优化镜像大小，同时添加一些生产环境的功能。

### 🛠️ 准备工作

```bash
# 1. 创建练习目录
mkdir docker-practice-2
cd docker-practice-2

# 2. 创建模拟项目结构
mkdir -p src/main/java/com/example
mkdir -p target

# 3. 创建模拟源码文件
cat > src/main/java/com/example/Application.java << 'EOF'
package com.example;
public class Application {
    public static void main(String[] args) {
        System.out.println("Hello from optimized Docker container!");
    }
}
EOF

# 4. 创建模拟的构建产物
echo "优化后的 JAR 文件" > target/myapp-optimized.jar
```

### 🚀 创建优化版 Dockerfile

```bash
cat > Dockerfile << 'EOF'
# 构建阶段
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /build

# 复制依赖文件（利用缓存）
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 复制源码并构建
COPY src ./src
RUN mvn clean package -DskipTests

# 运行阶段（更小的基础镜像）
FROM eclipse-temurin:21-jre

# 安装必要工具
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建非root用户
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=builder /build/target/*.jar app.jar

# 设置权限
RUN chown appuser:appuser app.jar

# 切换到非root用户
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
```

### 🚀 构建和对比

```bash
# 1. 构建优化版镜像
docker build -t myapp:v2 .

# 2. 对比镜像大小
echo "=== 镜像大小对比 ==="
docker images | grep myapp

# 3. 对比构建时间
time docker build -t myapp:v2-timed .

# 4. 运行优化版容器
docker run -d --name myapp-v2 -p 8080:8080 myapp:v2

# 5. 查看容器详情
docker inspect myapp-v2 | grep -A 10 -B 10 "User"

# 6. 测试健康检查
curl -f http://localhost:8080/actuator/health || echo "健康检查失败（预期，因为没有真实应用）"

# 7. 清理
docker stop myapp-v2
docker rm myapp-v2
```

### 📊 性能分析

```bash
# 1. 查看镜像层详情
docker history myapp:v2

# 2. 分析镜像大小组成
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest myapp:v2

# 3. 安全扫描
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image myapp:v2
```

### 💡 学习要点

1. **多阶段构建原理**：不同阶段可以使用不同的基础镜像
2. **缓存优化**：将不经常变化的步骤放在前面
3. **镜像大小优化**：使用更小的运行时基础镜像
4. **安全加固**：使用非 root 用户运行应用
5. **健康检查**：确保容器健康运行
6. **层缓存**：理解 Docker 的层缓存机制

---

## 🎯 练习 3：企业级镜像构建

### 📖 场景描述

你需要为一个企业级应用构建 Docker 镜像，要求包含完整的安全、监控、日志等功能。

### 🛠️ 准备工作

```bash
# 1. 创建练习目录
mkdir docker-practice-3
cd docker-practice-3

# 2. 创建企业级项目结构
mkdir -p src/main/{java/com/example,resources}
mkdir -p {config,scripts,logs}

# 3. 创建模拟配置文件
cat > src/main/resources/application.yml << 'EOF'
spring:
  application:
    name: enterprise-service
  profiles:
    active: prod

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: always
EOF

# 4. 创建模拟 JAR 文件
echo "企业级应用 JAR" > target/enterprise-service.jar
```

### 🚀 创建企业级 Dockerfile

```bash
cat > Dockerfile << 'EOF'
# 企业级多阶段构建
FROM gradle:8.11.1-jdk21-alpine AS builder

# 标签信息
LABEL maintainer="DevOps Team <devops@company.com>"
LABEL version="1.0.0"
LABEL description="Enterprise Backend Service"

WORKDIR /build

# 复制构建文件
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle

# 下载依赖（缓存层）
RUN gradle dependencies --no-daemon

# 复制源码
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
ARG JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"

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

# 复制配置文件
COPY config/ /app/config/

# 设置文件权限
RUN chown appservice:appservice app.jar && chmod 755 app.jar

# 切换到非root用户
USER appservice

# 健康检查（更详细的检查）
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health && \
      curl -f http://localhost:8080/actuator/info || exit 1

# 数据卷
VOLUME ["/app/logs", "/app/uploads", "/app/temp", "/app/config"]

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

# 入口点
ENTRYPOINT ["/app/entrypoint.sh"]

# OCI 标准标签
LABEL org.opencontainers.image.title="Enterprise Backend Service"
LABEL org.opencontainers.image.description="Production-ready backend service"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="DevOps Team"
LABEL org.opencontainers.image.source="https://github.com/company/enterprise-service"
LABEL org.opencontainers.image.licenses="Apache-2.0"
EOF
```

### 🚀 创建配套脚本

```bash
# 创建构建脚本
cat > build.sh << 'EOF'
#!/bin/bash
set -e

echo "🏗️  开始构建企业级镜像..."

# 参数设置
IMAGE_NAME="enterprise-service"
IMAGE_TAG="${1:-latest}"
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# 构建镜像
docker build \
  --build-arg JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication" \
  --build-arg BUILD_TIMESTAMP="${BUILD_TIMESTAMP}" \
  --build-arg GIT_COMMIT="${GIT_COMMIT}" \
  -t ${IMAGE_NAME}:${IMAGE_TAG} \
  -t ${IMAGE_NAME}:latest \
  .

echo "✅ 镜像构建完成: ${IMAGE_NAME}:${IMAGE_TAG}"

# 显示镜像信息
echo "📊 镜像信息："
docker images ${IMAGE_NAME}:${IMAGE_TAG}

# 安全扫描
echo "🔍 开始安全扫描..."
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image ${IMAGE_NAME}:${IMAGE_TAG} || true

echo "🎉 构建流程完成！"
EOF

chmod +x build.sh
```

### 🚀 创建运行脚本

```bash
cat > run.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 启动企业级服务..."

# 参数设置
CONTAINER_NAME="enterprise-service"
IMAGE_NAME="enterprise-service"
IMAGE_TAG="${1:-latest}"

# 停止并删除旧容器（如果存在）
if docker ps -a | grep -q ${CONTAINER_NAME}; then
    echo "🛑 停止旧容器..."
    docker stop ${CONTAINER_NAME} || true
    docker rm ${CONTAINER_NAME} || true
fi

# 创建必要的目录
mkdir -p ./logs ./uploads ./temp ./config

# 启动容器
docker run -d \
  --name ${CONTAINER_NAME} \
  --restart unless-stopped \
  -p 8080:8080 \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e DB_NAME=enterprise_db \
  -e DB_USER=enterprise_user \
  -e DB_PASSWORD=secure_password \
  -e REDIS_HOST=redis \
  -e REDIS_PORT=6379 \
  -e REDIS_PASSWORD=redis_password \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e JAVA_OPTS="-Xms1g -Xmx2g -XX:+UseG1GC" \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/uploads:/app/uploads \
  -v $(pwd)/temp:/app/temp \
  -v $(pwd)/config:/app/config \
  --health-cmd="curl -f http://localhost:8080/actuator/health || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  ${IMAGE_NAME}:${IMAGE_TAG}

echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
if docker ps | grep -q ${CONTAINER_NAME}; then
    echo "✅ 服务启动成功！"
    echo "📊 容器信息："
    docker ps | grep ${CONTAINER_NAME}
    
    echo "🌐 服务访问地址："
    echo "  健康检查: http://localhost:8080/actuator/health"
    echo "  应用信息: http://localhost:8080/actuator/info"
    echo "  指标监控: http://localhost:8080/actuator/metrics"
else
    echo "❌ 服务启动失败！"
    echo "📋 容器日志："
    docker logs ${CONTAINER_NAME} --tail 50
    exit 1
fi
EOF

chmod +x run.sh
```

### 🚀 执行企业级构建

```bash
# 1. 构建企业级镜像
./build.sh v1.0.0

# 2. 查看构建结果
echo "=== 镜像大小对比 ==="
docker images enterprise-service

# 3. 运行企业级容器
./run.sh v1.0.0

# 4. 验证服务状态
echo "=== 服务状态检查 ==="
curl -f http://localhost:8080/actuator/health || echo "健康检查失败（预期）"

# 5. 查看容器详情
docker inspect enterprise-service | grep -A 5 -B 5 "Health"

# 6. 性能测试
echo "=== 容器性能分析 ==="
docker stats enterprise-service --no-stream

# 7. 日志查看
echo "=== 服务日志 ==="
docker logs enterprise-service --tail 20
```

### 📊 企业级特性验证

```bash
# 1. 安全验证
echo "=== 安全检查 ==="
docker exec enterprise-service whoami
docker exec enterprise-service ps aux

# 2. 权限验证
echo "=== 权限检查 ==="
docker exec enterprise-service ls -la /app/

# 3. 网络验证
echo "=== 网络检查 ==="
docker exec enterprise-service netstat -tlnp

# 4. 资源限制验证
echo "=== 资源使用 ==="
docker exec enterprise-service cat /proc/meminfo | head -5

# 5. 健康检查验证
echo "=== 健康检查历史 ==="
docker inspect enterprise-service | grep -A 10 "Health"
```

### 💡 学习要点

1. **企业级安全**：
   - 非 root 用户运行
   - 最小权限原则
   - 安全扫描集成

2. **生产级功能**：
   - 健康检查
   - 日志管理
   - 配置外部化
   - 服务依赖等待

3. **镜像优化**：
   - 多阶段构建
   - 缓存优化
   - 层优化

4. **可观测性**：
   - 指标暴露
   - 健康检查
   - 日志收集

5. **CI/CD 集成**：
   - 构建参数化
   - 版本管理
   - 自动化测试

---

## 🎯 总结与进阶

### 📚 学习成果

通过这三个练习，你已经掌握了：

1. ✅ **基础镜像构建**：理解 Docker 基本概念
2. ✅ **多阶段构建优化**：掌握镜像优化技巧
3. ✅ **企业级镜像构建**：具备生产环境部署能力

### 🚀 进阶建议

#### 1. 性能优化
```dockerfile
# JVM 优化
ENV JAVA_OPTS="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxGCPauseMillis=200"

# 启动优化
ENTRYPOINT ["java", "-XX:+UnlockExperimentalVMOptions", "-jar", "app.jar"]
```

#### 2. 安全加固
```dockerfile
# 使用 distroless 镜像
FROM gcr.io/distroless/java21-debian12

# 或者使用 Alpine + 安全扫描
FROM alpine:3.18
RUN apk upgrade --no-cache
```

#### 3. 多架构支持
```dockerfile
# 多平台构建
FROM --platform=$BUILDPLATFORM gradle:8.11.1-jdk21-alpine AS builder
```

#### 4. 缓存优化
```dockerfile
# 依赖缓存优化
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package
```

### 🎯 最佳实践总结

1. **🏗️ 构建优化**
   - 使用多阶段构建
   - 合理利用缓存
   - 最小化镜像大小

2. **🔒 安全加固**
   - 非 root 用户
   - 定期安全扫描
   - 最小权限原则

3. **📊 可观测性**
   - 健康检查
   - 指标收集
   - 结构化日志

4. **🚀 生产就绪**
   - 优雅关闭
   - 资源限制
   - 自动重启

5. **🔧 可维护性**
   - 参数化配置
   - 版本管理
   - 文档完善

---

**🎉 恭喜完成所有练习！** 

你现在具备了从零开始构建企业级 Docker 镜像的完整技能。继续实践，不断优化，你将成为 Docker 镜像构建专家！ 💪