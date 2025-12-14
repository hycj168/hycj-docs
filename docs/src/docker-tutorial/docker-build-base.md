# Docker 镜像构建详细教程 - 手把手教你构建后端服务镜像

## 📚 教程概述

本教程将手把手教你如何将一个后端服务项目构建成 Docker 镜像，涵盖从基础概念到高级优化的完整流程。以 Osmanthus Music Backend
项目为例，详细讲解每个步骤。

## 🎯 学习目标

✅ 理解 Docker 镜像构建原理  
✅ 掌握 Dockerfile 编写技巧  
✅ 学会多阶段构建优化  
✅ 了解安全最佳实践  
✅ 掌握镜像调试和优化方法

## 🏗️ 项目结构准备

首先，让我们了解一个标准的后端项目结构：

```bash
osmanthus-music-backend/
├── src/
│   ├── main/
│   │   ├── kotlin/          # Kotlin 源代码
│   │   ├── resources/       # 配置文件
│   │   │   ├── application.yml
│   │   │   ├── application-prod.yml
│   │   │   └── logback-spring.xml
│   │   └── docker/
│   │       └── Dockerfile    # Docker 文件
├── build.gradle.kts         # Gradle 构建文件
├── settings.gradle.kts
├── gradle.properties
├── .env.example             # 环境变量示例
├── docker-compose.yml       # Docker Compose 配置
└── README.md
```

## 📝 第一步：编写 Dockerfile（基础版）

### 1.1 创建基础 Dockerfile

创建一个名为 `Dockerfile` 的文件：

```dockerfile
# 使用 OpenJDK 21 作为基础镜像
FROM openjdk:21-jdk-slim

# 设置工作目录
WORKDIR /app

# 复制 JAR 文件
COPY build/libs/osmanthus-music-backend-0.0.1-SNAPSHOT.jar app.jar

# 暴露端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 1.2 构建基础镜像

```bash
# 构建镜像
docker build -t osmanthus-backend:basic .

# 查看镜像
docker images

# 运行容器测试
docker run -p 8080:8080 osmanthus-backend:basic
```

## 🔧 第二步：优化 Dockerfile（进阶版）

### 2.1 添加多阶段构建

```dockerfile
# ==================== 构建阶段 ====================
FROM gradle:8.11.1-jdk21-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制构建文件
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle

# 下载依赖（利用缓存）
RUN gradle dependencies --no-daemon

# 复制源代码
COPY src ./src

# 构建应用
RUN gradle build -x test --no-daemon

# ==================== 运行阶段 ====================
FROM eclipse-temurin:21-jre

# 设置工作目录
WORKDIR /app

# 复制构建好的 JAR
COPY --from=builder /app/build/libs/*.jar app.jar

# 创建非 root 用户
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 暴露端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 2.2 构建优化镜像

```bash
# 构建优化版本
docker build -t osmanthus-backend:optimized .

# 比较镜像大小
docker images | grep osmanthus-backend

# 测试运行
docker run -p 8080:8080 osmanthus-backend:optimized
```

## 🛡️ 第三步：企业级 Dockerfile（高级版）

### 3.1 完整的企业级 Dockerfile

```dockerfile
# ==================== Osmanthus Music Backend Dockerfile ====================
# 多阶段构建，优化镜像大小
# 基础镜像: OpenJDK 21 Alpine
# 构建工具: Gradle
# 最终镜像: JRE 21 Alpine
# ========================================================================

# ==================== 构建阶段 ====================
FROM gradle:8.11.1-jdk21-alpine AS builder

# 维护者信息
LABEL maintainer="Osmanthus Team <osmanthus@example.com>"
LABEL version="1.0.0"
LABEL description="Osmanthus Music Backend - 企业级音乐管理系统"

# 设置工作目录
WORKDIR /app

# 复制 Gradle 构建文件（利用构建缓存）
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle

# 下载依赖（这一步会被缓存，除非构建文件改变）
RUN gradle dependencies --no-daemon

# 复制源代码
COPY src ./src

# 设置 Gradle 构建参数
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs='-Xmx1g -XX:MaxMetaspaceSize=512m'"

# 执行构建（跳过测试，可在CI/CD中配置）
RUN gradle build -x test --no-daemon --info

# ==================== 运行阶段 ====================
FROM eclipse-temurin:21-jre

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户（非root用户，提高安全性）
RUN groupadd -r osmanthus && useradd -r -g osmanthus -s /bin/bash osmanthus

# 设置工作目录
WORKDIR /app

# 参数定义
ARG JAR_FILE=build/libs/osmanthus-music-backend-0.0.1-SNAPSHOT.jar
ARG JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication"

# 环境变量
ENV JAVA_OPTS=${JAVA_OPTS}
ENV SPRING_PROFILES_ACTIVE=prod
ENV SERVER_PORT=8080
ENV LOG_PATH=/app/logs

# 创建必要的目录
RUN mkdir -p /app/logs /app/uploads /app/temp /app/config && \
    chown -R osmanthus:osmanthus /app

# 复制构建好的 JAR 文件
COPY --from=builder /app/build/libs/*.jar app.jar

# 设置文件权限
RUN chown osmanthus:osmanthus app.jar && chmod 755 app.jar

# 切换到非root用户
USER osmanthus

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 暴露端口
EXPOSE 8080

# 入口脚本
COPY <<'EOF' /app/entrypoint.sh
#!/bin/bash
set -e

echo "🌸 Osmanthus Music Backend 启动中..."

# 等待数据库连接
echo "等待数据库服务就绪..."
while ! nc -z ${DB_HOST:-mysql} ${DB_PORT:-3306}; do
  sleep 1
done
echo "数据库连接成功 ✓"

# 等待Redis连接
echo "等待Redis服务就绪..."
while ! nc -z ${REDIS_HOST:-redis} ${REDIS_PORT:-6379}; do
  sleep 1
done
echo "Redis连接成功 ✓"

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
USER osmanthus

# 设置数据卷
VOLUME ["/app/logs", "/app/uploads", "/app/temp"]

# 入口点
ENTRYPOINT ["/app/entrypoint.sh"]

# ==================== 标签信息 ====================
LABEL org.opencontainers.image.title="Osmanthus Music Backend"
LABEL org.opencontainers.image.description="企业级音乐管理系统后端服务"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="Osmanthus Team"
LABEL org.opencontainers.image.source="https://github.com/your-org/osmanthus-music-backend"
LABEL org.opencontainers.image.licenses="MIT"
```

### 3.2 构建企业级镜像

```bash
# 构建企业级镜像
docker build -t osmanthus-backend:enterprise .

# 查看构建过程
docker build --progress=plain -t osmanthus-backend:enterprise .

# 标记镜像
docker tag osmanthus-backend:enterprise your-registry.com/osmanthus-backend:latest
```

## 🧪 第四步：镜像测试与验证

### 4.1 创建测试脚本

创建 `test-image.sh`：

```bash
#!/bin/bash

echo "🧪 开始测试 Docker 镜像..."

# 变量定义
IMAGE_NAME="osmanthus-backend:enterprise"
CONTAINER_NAME="test-osmanthus-backend"
TEST_PORT=8080

# 清理旧容器
echo "清理旧容器..."
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# 启动测试容器
echo "启动测试容器..."
docker run -d \
  --name $CONTAINER_NAME \
  -p $TEST_PORT:8080 \
  -e SPRING_PROFILES_ACTIVE=test \
  -e DB_HOST=mock-host \
  -e REDIS_HOST=mock-host \
  $IMAGE_NAME

# 等待容器启动
echo "等待容器启动..."
sleep 10

# 检查容器状态
echo "检查容器状态..."
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ 容器启动成功"
else
    echo "❌ 容器启动失败"
    docker logs $CONTAINER_NAME
    exit 1
fi

# 检查健康状态
echo "检查健康状态..."
for i in {1..30}; do
    if curl -f http://localhost:$TEST_PORT/actuator/health 2>/dev/null; then
        echo "✅ 健康检查通过"
        break
    fi
    echo "等待健康检查... ($i/30)"
    sleep 5
done

# 检查镜像大小
echo "检查镜像信息..."
docker images $IMAGE_NAME

# 清理测试容器
echo "清理测试容器..."
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME

echo "🎉 镜像测试完成！"
```

### 4.2 运行测试

```bash
# 给脚本添加执行权限
chmod +x test-image.sh

# 运行测试
./test-image.sh
```

## 🔍 第五步：镜像分析与优化

### 5.1 镜像大小分析

```bash
# 查看镜像分层历史
docker history osmanthus-backend:enterprise

# 查看详细镜像信息
docker inspect osmanthus-backend:enterprise

# 比较不同版本大小
docker images | grep osmanthus-backend
```

### 5.2 安全扫描

```bash
# 使用 Trivy 进行安全扫描（需要安装 Trivy）
trivy image osmanthus-backend:enterprise

# 使用 Docker Scout（Docker Desktop 自带）
docker scout cves osmanthus-backend:enterprise
```

### 5.3 性能测试

```bash
# 启动性能测试容器
docker run -d --name perf-test \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  osmanthus-backend:enterprise

# 等待启动完成
sleep 30

# 进行压力测试（需要安装 wrk 或类似工具）
wrk -t12 -c400 -d30s http://localhost:8080/actuator/health
```

## 🚀 第六步：高级构建技巧

### 6.1 使用 BuildKit 加速构建

```bash
# 启用 BuildKit
export DOCKER_BUILDKIT=1

# 构建时使用 BuildKit
docker build --progress=plain --secret id=gradle-cache,src=$HOME/.gradle -t osmanthus-backend:fast .
```

### 6.2 多平台构建

```bash
# 创建构建器
docker buildx create --name multi-platform --use

# 构建多平台镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t your-registry.com/osmanthus-backend:latest \
  --push .
```

### 6.3 CI/CD 集成

创建 `.gitlab-ci.yml`：

```yaml
stages:
  - build
  - test
  - security
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  LATEST_IMAGE: $CI_REGISTRY_IMAGE:latest

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $DOCKER_IMAGE .
    - docker tag $DOCKER_IMAGE $LATEST_IMAGE
    - docker push $DOCKER_IMAGE
    - docker push $LATEST_IMAGE
  only:
    - main

test:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker run --rm $DOCKER_IMAGE java -version
    - docker run --rm $DOCKER_IMAGE curl --version
  dependencies:
    - build

security:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --severity HIGH,CRITICAL $DOCKER_IMAGE
  allow_failure: true
  dependencies:
    - build

deploy:
  stage: deploy
  image: alpine:latest
  script:
    - echo "Deploying to production..."
    - echo "Image: $DOCKER_IMAGE deployed"
  when: manual
  only:
    - main
```

## 📋 第七步：最佳实践总结

### 7.1 Dockerfile 编写原则

1. **使用多阶段构建**
    - 减少最终镜像大小
    - 分离构建和运行环境

2. **选择合适的基础镜像**
    - Alpine Linux 适合轻量级应用
    - Distroless 适合安全要求高的场景
    - 官方镜像优先

3. **利用构建缓存**
    - 将不常变化的指令放在前面
    - 合理使用 COPY 指令

4. **安全性考虑**
    - 使用非 root 用户运行
    - 定期更新基础镜像
    - 扫描安全漏洞

5. **镜像大小优化**
    - 清理不必要的文件
    - 使用 .dockerignore
    - 选择轻量级基础镜像

### 7.2 构建优化技巧

```dockerfile
# .dockerignore 文件示例
# 忽略不需要的文件
.gradle/
build/
*.md
.git/
.gitignore
Dockerfile
docker-compose.yml
.env
node_modules/
*.log
```

### 7.3 标签管理

```bash
# 语义化版本标签
docker tag osmanthus-backend:latest osmanthus-backend:1.0.0
docker tag osmanthus-backend:latest osmanthus-backend:1.0
docker tag osmanthus-backend:latest osmanthus-backend:1

# 环境标签
docker tag osmanthus-backend:latest osmanthus-backend:prod
docker tag osmanthus-backend:latest osmanthus-backend:staging
docker tag osmanthus-backend:latest osmanthus-backend:dev
```

## 🎯 第八步：实战练习

### 8.1 练习 1：基础构建

```bash
# 1. 创建简单的 Dockerfile
echo "FROM openjdk:21-jdk-slim
WORKDIR /app
COPY target/myapp.jar app.jar
EXPOSE 8080
ENTRYPOINT [\"java\", \"-jar\", \"app.jar\"]" > Dockerfile

# 2. 构建镜像
docker build -t myapp:basic .

# 3. 运行测试
docker run -p 8080:8080 myapp:basic
```

### 8.2 练习 2：多阶段构建

```dockerfile
# 挑战：优化这个 Dockerfile
FROM maven:3.8.6-openjdk-21-slim AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

FROM openjdk:21-jre-slim
WORKDIR /app
COPY --from=build /app/target/myapp.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 8.3 练习 3：安全加固

```dockerfile
# 挑战：添加安全加固
FROM openjdk:21-jre-slim

# 创建非 root 用户
RUN groupadd -r appuser && useradd -r -g appuser appuser

# 设置工作目录
WORKDIR /app

# 复制应用
COPY app.jar app.jar

# 切换用户
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## 📚 第九步：学习资源

### 9.1 官方文档

- [Docker 官方文档](https://docs.docker.com/)
- [Dockerfile 最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [Docker 安全指南](https://docs.docker.com/engine/security/)

### 9.2 实用工具

- [Hadolint](https://github.com/hadolint/hadolint) - Dockerfile 静态检查
- [Dive](https://github.com/wagoodman/dive) - 镜像分析工具
- [Trivy](https://github.com/aquasecurity/trivy) - 安全扫描工具

### 9.3 相关教程

- [Docker 官方入门教程](https://docs.docker.com/get-started/)
- [Spring Boot Docker 化指南](https://spring.io/guides/gs/spring-boot-docker/)
- [多阶段构建详解](https://docs.docker.com/develop/dev-best-practices/dockerfile_best-practices/#use-multi-stage-builds)

## 🎉 总结

通过本教程，你学会了：

✅ **基础构建**：编写简单的 Dockerfile  
✅ **多阶段构建**：优化镜像大小和构建速度  
✅ **安全实践**：使用非 root 用户和安全扫描  
✅ **企业级实践**：完整的生产级 Dockerfile  
✅ **测试验证**：镜像测试和性能分析  
✅ **CI/CD 集成**：自动化构建流程

### 🚀 下一步学习建议

1. **实践项目**：尝试为自己的项目构建 Docker 镜像
2. **Kubernetes 学习**：学习容器编排
3. **云原生实践**：了解微服务架构
4. **安全深化**：学习容器安全最佳实践

### 💡 小贴士

- **从小开始**：先构建简单镜像，逐步优化
- **多测试**：每个阶段都要充分测试
- **看日志**：构建失败时仔细查看日志
- **用工具**：善用各种分析和扫描工具
- **学最佳实践**：持续学习新的最佳实践

---

**🎯 记住**：构建好的 Docker 镜像是容器化部署的基础，花时间学习和实践是非常值得的投资！

祝你构建愉快！🚀