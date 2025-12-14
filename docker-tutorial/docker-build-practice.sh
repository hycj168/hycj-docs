#!/bin/bash

# =============================================================================
# Docker 镜像构建实战练习脚本
# =============================================================================
# 这个脚本包含了 Dockerfile 构建的各种练习，从基础到高级
# 使用方法: ./docker-build-practice.sh
# =============================================================================

set -e

echo "🐳 Docker 镜像构建实战练习"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 练习项目目录
PRACTICE_DIR="./docker-build-practice"
IMAGE_NAME="practice-app"

# 创建练习目录
mkdir -p $PRACTICE_DIR
cd $PRACTICE_DIR

echo -e "${BLUE}📁 创建练习目录: $PRACTICE_DIR${NC}"

# =============================================================================
# 练习 1: 基础 Dockerfile 构建
# =============================================================================

echo -e "${YELLOW}📝 练习 1: 基础 Dockerfile 构建${NC}"

# 创建简单的 Java 应用模拟文件
cat > app.java << 'EOF'
public class App {
    public static void main(String[] args) {
        System.out.println("Hello Docker!");
        System.out.println("This is a practice application.");
        
        // 保持应用运行
        while (true) {
            try {
                Thread.sleep(1000);
                System.out.println("App is running...");
            } catch (InterruptedException e) {
                break;
            }
        }
    }
}
EOF

# 创建基础 Dockerfile
cat > Dockerfile.basic << 'EOF'
# 基础 Dockerfile - 练习1
FROM openjdk:21-jdk-slim

WORKDIR /app

# 复制应用文件
COPY app.java .

# 编译 Java 应用
RUN javac app.java

# 暴露端口（模拟）
EXPOSE 8080

# 运行应用
CMD ["java", "App"]
EOF

echo -e "${GREEN}✅ 基础 Dockerfile 创建完成${NC}"
echo -e "${BLUE}📋 文件内容:${NC}"
cat Dockerfile.basic

# 构建基础镜像
echo -e "${YELLOW}🔨 构建基础镜像...${NC}"
docker build -f Dockerfile.basic -t ${IMAGE_NAME}:basic .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 基础镜像构建成功${NC}"
    docker images | grep ${IMAGE_NAME}:basic
else
    echo -e "${RED}❌ 基础镜像构建失败${NC}"
fi

# =============================================================================
# 练习 2: 多阶段构建优化
# =============================================================================

echo -e "${YELLOW}📝 练习 2: 多阶段构建优化${NC}"

# 创建多阶段构建 Dockerfile
cat > Dockerfile.multi-stage << 'EOF'
# 多阶段构建 - 练习2

# 构建阶段
FROM openjdk:21-jdk-slim AS builder

WORKDIR /build

# 复制源码
COPY app.java .

# 编译应用
RUN javac app.java

# 运行阶段
FROM openjdk:21-jre-slim

WORKDIR /app

# 从构建阶段复制编译好的类文件
COPY --from=builder /build/App.class .

# 创建非root用户
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

EXPOSE 8080

CMD ["java", "App"]
EOF

echo -e "${GREEN}✅ 多阶段构建 Dockerfile 创建完成${NC}"

# 构建多阶段镜像
echo -e "${YELLOW}🔨 构建多阶段镜像...${NC}"
docker build -f Dockerfile.multi-stage -t ${IMAGE_NAME}:multi-stage .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 多阶段镜像构建成功${NC}"
    docker images | grep ${IMAGE_NAME}:multi-stage
else
    echo -e "${RED}❌ 多阶段镜像构建失败${NC}"
fi

# =============================================================================
# 练习 3: 添加健康检查和安全加固
# =============================================================================

echo -e "${YELLOW}📝 练习 3: 健康检查和安全加固${NC}"

# 创建模拟的 Spring Boot 应用（简化版）
cat > App.java << 'EOF'
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

public class App {
    public static void main(String[] args) {
        System.out.println("🚀 Enhanced Practice App Starting...");
        
        try {
            // 模拟 HTTP 服务器
            ServerSocket serverSocket = new ServerSocket(8080);
            System.out.println("✅ Server started on port 8080");
            
            while (true) {
                try {
                    Socket clientSocket = serverSocket.accept();
                    // 简单的健康检查响应
                    String response = "HTTP/1.1 200 OK\r\n" +
                                    "Content-Type: text/plain\r\n" +
                                    "\r\n" +
                                    "OK - Application is healthy\n";
                    clientSocket.getOutputStream().write(response.getBytes());
                    clientSocket.close();
                } catch (IOException e) {
                    System.err.println("Error handling client: " + e.getMessage());
                }
            }
        } catch (IOException e) {
            System.err.println("Could not start server: " + e.getMessage());
            System.exit(1);
        }
    }
}
EOF

# 重新编译
javac App.java

# 创建高级 Dockerfile
cat > Dockerfile.advanced << 'EOF'
# 高级 Dockerfile - 练习3
FROM openjdk:21-jre-slim

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN groupadd -r appuser && useradd -r -g appuser -s /bin/bash appuser

WORKDIR /app

# 复制应用文件
COPY App.class .

# 创建日志目录
RUN mkdir -p /app/logs && chown -R appuser:appuser /app

# 切换到非root用户
USER appuser

# 环境变量
ENV JAVA_OPTS="-Xms256m -Xmx512m"
ENV LOG_PATH="/app/logs"

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 暴露端口
EXPOSE 8080

# 入口脚本
COPY <<'SCRIPT' /app/entrypoint.sh
#!/bin/bash
set -e

echo "🌸 Starting Enhanced Practice Application..."

# 创建必要的目录
mkdir -p ${LOG_PATH}

# 启动应用
echo "Starting Java application..."
exec java ${JAVA_OPTS} -cp . App
SCRIPT

# 设置脚本权限
USER root
RUN chmod +x /app/entrypoint.sh
USER appuser

# 设置数据卷
VOLUME ["/app/logs"]

# 入口点
ENTRYPOINT ["/app/entrypoint.sh"]
EOF

echo -e "${GREEN}✅ 高级 Dockerfile 创建完成${NC}"

# 构建高级镜像
echo -e "${YELLOW}🔨 构建高级镜像...${NC}"
docker build -f Dockerfile.advanced -t ${IMAGE_NAME}:advanced .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 高级镜像构建成功${NC}"
    docker images | grep ${IMAGE_NAME}:advanced
else
    echo -e "${RED}❌ 高级镜像构建失败${NC}"
fi

# =============================================================================
# 镜像对比分析
# =============================================================================

echo -e "${YELLOW}📊 镜像对比分析${NC}"
echo "=================================="

echo -e "${BLUE}📋 镜像大小对比:${NC}"
docker images | grep ${IMAGE_NAME} | sort -k2,2

echo -e "${BLUE}📋 详细镜像信息:${NC}"
echo "基础镜像历史:"
docker history ${IMAGE_NAME}:basic | head -10

echo -e "\n多阶段镜像历史:"
docker history ${IMAGE_NAME}:multi-stage | head -10

echo -e "\n高级镜像历史:"
docker history ${IMAGE_NAME}:advanced | head -10

# =============================================================================
# 容器测试
# =============================================================================

echo -e "${YELLOW}🧪 容器测试${NC}"
echo "=================================="

# 测试高级镜像
echo -e "${BLUE}🚀 启动高级容器进行测试...${NC}"
docker run -d --name ${IMAGE_NAME}-test -p 8080:8080 ${IMAGE_NAME}:advanced

# 等待容器启动
sleep 5

# 检查容器状态
echo -e "${BLUE}🔍 检查容器状态...${NC}"
docker ps | grep ${IMAGE_NAME}-test

# 健康检查测试
echo -e "${BLUE}🏥 健康检查测试...${NC}"
for i in {1..10}; do
    if curl -f http://localhost:8080 2>/dev/null; then
        echo -e "${GREEN}✅ 健康检查通过${NC}"
        break
    else
        echo -e "${YELLOW}⏳ 等待健康检查... ($i/10)${NC}"
        sleep 2
    fi
done

# 查看容器日志
echo -e "${BLUE}📋 容器日志:${NC}"
docker logs ${IMAGE_NAME}-test --tail 20

# =============================================================================
# 清理测试容器
# =============================================================================

echo -e "${YELLOW}🧹 清理测试容器${NC}"
docker stop ${IMAGE_NAME}-test
docker rm ${IMAGE_NAME}-test

# =============================================================================
# 最佳实践检查
# =============================================================================

echo -e "${YELLOW}✅ 最佳实践检查清单${NC}"
echo "=================================="

echo -e "${BLUE}✅ 完成的项目:${NC}"
echo "1. 基础 Dockerfile 构建"
echo "2. 多阶段构建优化"
echo "3. 健康检查和安全加固"
echo "4. 镜像大小对比分析"
echo "5. 容器运行测试"

echo -e "${BLUE}📚 学习要点:${NC}"
echo "- 多阶段构建可以显著减小镜像大小"
echo "- 使用非 root 用户提高安全性"
echo "- 健康检查确保容器正常运行"
echo "- 环境变量和参数化配置"
echo "- 数据卷用于持久化数据"

echo -e "${GREEN}🎉 Docker 构建实战练习完成！${NC}"
echo "=================================="
echo "练习文件位置: $PRACTICE_DIR"
echo "你可以继续在这些文件基础上进行更多练习！"

# 返回原目录
cd ..