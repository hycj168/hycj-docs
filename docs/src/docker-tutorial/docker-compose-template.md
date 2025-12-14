# Docker Compose 模板学习

---

以 **MySQL 8.0.40** 为例：

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0.40
    container_name: mysql-production
    restart: unless-stopped

    environment:
      # 根密码（必须设置）
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-StrongRootPass123!}

      # 数据库配置
      MYSQL_DATABASE: ${MYSQL_DATABASE:-myapp}
      MYSQL_USER: ${MYSQL_USER:-appuser}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-AppPass123!}

      # 时区配置
      TZ: Asia/Shanghai

      # 内存配置（根据服务器调整）
      MYSQL_MEMORY_LIMIT: 4G

    ports:
      - "${MYSQL_PORT:-3306}:3306"

    volumes:
      # 数据持久化
      - ./data:/var/lib/mysql

      # 配置文件
      - ./config/mysql.cnf:/etc/mysql/conf.d/mysql.cnf:ro

      # 日志文件
      - ./logs:/var/log/mysql

      # 初始化脚本
      - ./scripts/init:/docker-entrypoint-initdb.d:ro

      # 时区配置
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro

    command:
      - --default-authentication-plugin=mysql_native_password
      - --sql-mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION
      - --max-connections=1000
      - --innodb-buffer-pool-size=2G

    healthcheck:
      test: [ "CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G

    networks:
      - mysql-network

  # MySQL 备份服务
  mysql-backup:
    image: mysql:8.0.40
    container_name: mysql-backup
    restart: unless-stopped

    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-StrongRootPass123!}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-myapp}
      BACKUP_SCHEDULE: "0 2 * * *"  # 每天凌晨2点备份
      BACKUP_RETENTION: 7

    volumes:
      - ./backup:/backup
      - ./scripts/backup.sh:/backup.sh:ro
      - ./data:/var/lib/mysql:ro

    depends_on:
      - mysql

    command: |
      bash -c '
        echo "0 2 * * * /backup.sh" | crontab - &&
        cron -f
      '

    networks:
      - mysql-network

  # MySQL 监控服务（可选）
  mysql-exporter:
    image: prom/mysqld-exporter:latest
    container_name: mysql-exporter
    restart: unless-stopped

    environment:
      DATA_SOURCE_NAME: "root:${MYSQL_ROOT_PASSWORD}@(mysql:3306)/"

    ports:
      - "9104:9104"

    depends_on:
      - mysql

    networks:
      - mysql-network

  # phpMyAdmin（可选，仅开发环境）
  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    container_name: phpmyadmin
    restart: unless-stopped

    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      PMA_USER: root
      PMA_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      UPLOAD_LIMIT: 100M

    ports:
      - "8080:80"

    depends_on:
      - mysql

    networks:
      - mysql-network

networks:
  mysql-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  mysql-data:
    driver: local
  mysql-logs:
    driver: local
  mysql-backup:
    driver: local
```

```yaml

# MySQL 主从复制 Docker Compose 配置

version: '3.8'

services:
  mysql-master:
    image: mysql:8.0.40
    container_name: mysql-master
    restart: unless-stopped

    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-MasterRootPass123!}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-replication_db}
      MYSQL_USER: ${MYSQL_USER:-repl_user}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-ReplUserPass123!}
      TZ: Asia/Shanghai

    ports:
      - "3306:3306"

    volumes:
      - ./master-data:/var/lib/mysql
      - ./config/master.cnf:/etc/mysql/conf.d/master.cnf:ro
      - ./logs/master:/var/log/mysql
      - ./scripts/master-init.sql:/docker-entrypoint-initdb.d/init.sql:ro

    networks:
      mysql-replication:
        ipv4_address: 172.20.0.2

  mysql-slave:
    image: mysql:8.0.40
    container_name: mysql-slave
    restart: unless-stopped

    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-SlaveRootPass123!}
      TZ: Asia/Shanghai

    ports:
      - "3307:3306"

    volumes:
      - ./slave-data:/var/lib/mysql
      - ./config/slave.cnf:/etc/mysql/conf.d/slave.cnf:ro
      - ./logs/slave:/var/log/mysql
      - ./scripts/slave-init.sql:/docker-entrypoint-initdb.d/init.sql:ro

    depends_on:
      - mysql-master

    networks:
      mysql-replication:
        ipv4_address: 172.20.0.3

  # MySQL 路由器（用于读写分离）
  mysql-router:
    image: mysql/mysql-router:latest
    container_name: mysql-router
    restart: unless-stopped

    environment:
      MYSQL_HOST: mysql-master
      MYSQL_PORT: 3306
      MYSQL_USER: root
      MYSQL_PASSWORD: ${MYSQL_ROOT_PASSWORD}

    ports:
      - "6446:6446"  # 读写端口
      - "6447:6447"  # 只读端口

    depends_on:
      - mysql-master
      - mysql-slave

    networks:
      mysql-replication:
        ipv4_address: 172.20.0.4

  # 备份服务
  mysql-backup:
    image: mysql:8.0.40
    container_name: mysql-backup
    restart: unless-stopped

    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      BACKUP_SCHEDULE: "0 2 * * *"
      BACKUP_RETENTION: 7

    volumes:
      - ./backup:/backup
      - ./scripts/backup-replication.sh:/backup.sh:ro

    depends_on:
      - mysql-master

    command: |
      bash -c '
        echo "0 2 * * * /backup.sh" | crontab - &&
        cron -f
      '

    networks:
      - mysql-replication

networks:
  mysql-replication:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  master-data:
    driver: local
  slave-data:
    driver: local
```

```yaml
# ==================== Osmanthus Music Backend Docker Compose 配置 ====================
# 项目名称: Osmanthus Music Backend - 企业级音乐管理系统
# 技术栈: Kotlin + Spring Boot 3.5.8 + MySQL + Redis + MinIO
# 版本: 1.0.0
# 维护者: Osmanthus Team
# 描述: 基于 Spring Boot 3.5.8 的企业级音乐管理系统，使用企业级 Docker 数据卷
# =================================================================================

version: '3.8'

services:
  # ==================== MySQL 数据库服务 ====================
  osmanthus-mysql:
    image: mysql:latest
    container_name: osmanthus-mysql
    restart: unless-stopped
    ports:
      - "3306:3306"
    environment:
      # MySQL Root 密码配置
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-sakura_dev_root}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-osmanthus_music_db}
      MYSQL_USER: ${MYSQL_USER:-osmanthus_user}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-osmanthus_pass_2025}

      # 时区设置
      TZ: Asia/Shanghai

    volumes:
      # 使用企业级数据卷 - 数据持久化
      - /opt/docker-volumes/mysql/data:/var/lib/mysql
      # 使用企业级数据卷 - 配置文件挂载
      - /opt/docker-volumes/mysql/config:/etc/mysql/conf.d:ro
      # 使用企业级数据卷 - 日志文件
      - /opt/docker-volumes/mysql/logs:/var/log/mysql
      # 使用企业级数据卷 - 备份目录（可选）
      - /opt/docker-volumes/mysql/backup:/backup

    command: >
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --max_connections=200
      --max_connect_errors=1000
      --wait_timeout=600
      --interactive_timeout=600
      --innodb_buffer_pool_size=256M
      --innodb_flush_log_at_trx_commit=2
      --innodb_flush_method=O_DIRECT

    networks:
      - osmanthus-network

    healthcheck:
      test: [ "CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD:-sakura_dev_root}" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '1.0'
          memory: 512M

  # ==================== Redis 缓存服务 ====================
  osmanthus-redis:
    image: redis:latest
    container_name: osmanthus-redis
    restart: unless-stopped
    ports:
      - "6379:6379"

    environment:
      # Redis 密码配置
      REDIS_PASSWORD: ${REDIS_PASSWORD:-osmanthus_redis_2025}
      # 时区设置
      TZ: Asia/Shanghai

    volumes:
      # 使用企业级数据卷 - 数据持久化
      - /opt/docker-volumes/redis/data:/data
      # 使用企业级数据卷 - Redis 配置文件
      - /opt/docker-volumes/redis/config:/usr/local/etc/redis/redis.conf:ro
      # 使用企业级数据卷 - 日志文件
      - /opt/docker-volumes/redis/logs:/var/log/redis

    command: >
      redis-server /usr/local/etc/redis/redis.conf
      --requirepass ${REDIS_PASSWORD:-osmanthus_redis_2025}
      --maxmemory 512mb
      --maxmemory-policy allkeys-lru
      --appendonly yes
      --appendfsync everysec

    networks:
      - osmanthus-network

    healthcheck:
      test: [ "CMD", "redis-cli", "--raw", "incr", "ping" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

  # ==================== MinIO 对象存储服务 ====================
  osmanthus-minio:
    image: minio/minio:latest
    container_name: osmanthus-minio
    restart: unless-stopped
    ports:
      - "9000:9000"   # MinIO API端口
      - "9001:9001"   # MinIO控制台端口

    environment:
      # MinIO Root 用户配置
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minioadmin2025}

      # MinIO 服务器配置
      MINIO_BROWSER: "on"
      MINIO_BROWSER_REDIRECT_URL: http://localhost:9001
      MINIO_SERVER_URL: http://localhost:9000
      # 时区设置
      TZ: Asia/Shanghai

    volumes:
      # 使用企业级数据卷 - MinIO 数据存储
      - /opt/docker-volumes/minio/data:/data
      # 使用企业级数据卷 - 配置文件
      - /opt/docker-volumes/minio/config:/root/.minio:ro
      # 使用企业级数据卷 - 日志文件
      - /opt/docker-volumes/minio/logs:/var/log/minio

    command: server /data --console-address ":9001"

    networks:
      - osmanthus-network

    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:9000/minio/health/live" ]
      interval: 30s
      timeout: 20s
      retries: 3
      start_period: 60s

    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

  # ==================== Osmanthus Backend 应用服务 ====================
  osmanthus-backend:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        # 构建参数
        JAR_FILE: build/libs/osmanthus-music-backend-0.0.1-SNAPSHOT.jar
        JAVA_OPTS: -Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication

    image: osmanthus-music-backend:latest
    container_name: osmanthus-backend
    restart: unless-stopped
    ports:
      - "8080:8080"

    environment:
      # Spring 环境配置
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE:-prod}
      SERVER_PORT: 8080

      # 数据库配置
      DB_HOST: osmanthus-mysql
      DB_PORT: 3306
      DB_NAME: ${MYSQL_DATABASE:-osmanthus_music_db}
      DB_USERNAME: ${MYSQL_USER:-osmanthus_user}
      DB_PASSWORD: ${MYSQL_PASSWORD:-osmanthus_pass_2024}

      # Redis 配置
      REDIS_HOST: osmanthus-redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD:-osmanthus_redis_2024}
      REDIS_DATABASE: 0
      REDIS_SSL_ENABLED: false

      # JWT 安全配置
      JWT_SECRET: ${JWT_SECRET:-OsmanthusMusicBackendSecretKeyForJWT2025PleaseChangeInProduction}
      JWT_ACCESS_TOKEN_EXPIRATION: 604800000
      JWT_REFRESH_TOKEN_EXPIRATION: 2592000000

      # Swagger 配置
      SWAGGER_ENABLED: ${SWAGGER_ENABLED:-false}
      SWAGGER_USERNAME: ${SWAGGER_USERNAME:-admin}
      SWAGGER_PASSWORD: ${SWAGGER_PASSWORD:-123456}

      # 日志配置
      LOG_PATH: /app/logs

      # MinIO 配置（可选）
      MINIO_ENABLED: ${MINIO_ENABLED:-true}
      MINIO_ENDPOINT: http://osmanthus-minio:9000
      MINIO_ACCESS_KEY: ${MINIO_ROOT_USER:-minioadmin}
      MINIO_SECRET_KEY: ${MINIO_ROOT_PASSWORD:-minioadmin2024}
      MINIO_DEFAULT_BUCKET: osmanthus-music

      # JVM 配置
      JAVA_OPTS: -Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseCompressedClassPointers -Djava.awt.headless=true

    volumes:
      # 使用企业级数据卷 - 应用日志
      - /opt/docker-volumes/backend/logs:/app/logs
      # 使用企业级数据卷 - 本地文件上传目录（当MinIO禁用时使用）
      - /opt/docker-volumes/backend/uploads:/app/uploads
      # 使用企业级数据卷 - 临时文件目录
      - /opt/docker-volumes/backend/temp:/app/temp

    depends_on:
      osmanthus-mysql:
        condition: service_healthy
      osmanthus-redis:
        condition: service_healthy
      osmanthus-minio:
        condition: service_healthy

    networks:
      - osmanthus-network

    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:8080/actuator/health" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s

    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "10"

  # ==================== Nginx 反向代理服务（可选） ====================
  osmanthus-nginx:
    image: nginx:latest
    container_name: osmanthus-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"

    volumes:
      # 使用企业级数据卷 - Nginx 配置
      - /opt/docker-volumes/nginx/config:/etc/nginx:ro
      - /opt/docker-volumes/nginx/conf.d:/etc/nginx/conf.d:ro
      # 使用企业级数据卷 - SSL 证书
      - /opt/docker-volumes/shared/ssl:/etc/nginx/ssl:ro
      # 使用企业级数据卷 - 静态资源
      - /opt/docker-volumes/nginx/html:/usr/share/nginx/html:ro
      # 使用企业级数据卷 - 日志文件
      - /opt/docker-volumes/nginx/logs:/var/log/nginx

    depends_on:
      - osmanthus-backend

    networks:
      - osmanthus-network

    profiles:
      - with-nginx

    healthcheck:
      test: [ "CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

# ==================== 网络配置 ====================
networks:
  osmanthus-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
    labels:
      - "com.osmanthus.network=backend"

# ==================== 数据卷配置 ====================
# 注意：这里使用服务器上已创建的企业级 Docker 数据卷目录
# 所有数据都持久化到 /opt/docker-volumes/ 目录下，确保数据安全和备份策略
```

更加完整的配置文件模板示例：

```yaml

# =============================================================================
# Docker 企业级多数据库容器编排配置文件
# =============================================================================
# 文件名称: docker-compose-enterprise.yml
# 创建时间: $(date '+%Y-%m-%d %H:%M:%S')
# 适用环境: 企业级生产环境
# 功能描述: 定义 MySQL、Redis、MongoDB、PostgreSQL 等企业级数据库服务
# 特色功能:
#   - 企业级安全配置
#   - 资源限制和监控
#   - 网络隔离策略
#   - 数据持久化配置
#   - 健康检查机制
#   - 自动重启策略
# =============================================================================

version: '3.8'

# =============================================================================
# 企业级网络配置 - 多层网络隔离
# =============================================================================
networks:
  # 数据库网络 - 高安全性，仅数据库服务可访问
  database-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
    labels:
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.network.type=database"
      - "com.company.network.isolation=strict"
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"  # 禁用容器间直接通信
      com.docker.network.bridge.enable_ip_masquerade: "true"
      com.docker.network.bridge.host_binding_ipv4: "0.0.0.0"

  # 应用网络 - 中等安全性，应用服务可访问
  application-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.21.0.0/16
          gateway: 172.21.0.1
    labels:
      - "com.company.environment=production"
      - "com.company.security.level=medium"
      - "com.company.network.type=application"
      - "com.company.network.isolation=moderate"

  # Web 网络 - 标准安全性，外部可访问
  web-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.22.0.0/16
          gateway: 172.22.0.1
    labels:
      - "com.company.environment=production"
      - "com.company.security.level=standard"
      - "com.company.network.type=web"
      - "com.company.network.isolation=basic"

  # 监控网络 - 专用网络，仅监控系统使用
  monitoring-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.23.0.0/16
          gateway: 172.23.0.1
    labels:
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.network.type=monitoring"
      - "com.company.network.isolation=strict"

# =============================================================================
# 企业级数据卷配置 - 持久化存储
# =============================================================================
volumes:
  # MySQL 数据卷
  mysql-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/mysql/data
  mysql-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/mysql/config
  mysql-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/mysql/logs
  mysql-backup:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/mysql/backup

  # Redis 数据卷
  redis-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/redis/data
  redis-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/redis/config
  redis-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/redis/logs

  # MongoDB 数据卷
  mongodb-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/mongodb/data
  mongodb-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/mongodb/config
  mongodb-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/mongodb/logs
  mongodb-backup:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/mongodb/backup

  # PostgreSQL 数据卷
  postgres-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/postgres/data
  postgres-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/postgres/config
  postgres-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/postgres/logs
  postgres-backup:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/postgres/backup

  # Elasticsearch 数据卷
  elasticsearch-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/elasticsearch/data
  elasticsearch-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/elasticsearch/config
  elasticsearch-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/elasticsearch/logs

  # Nginx 数据卷
  nginx-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/nginx/config
  nginx-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/nginx/logs
  nginx-certs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/nginx/certs

  # MinIO 数据卷
  minio-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/minio/data
  minio-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/minio/config
  minio-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/docker-volumes/minio/logs

# =============================================================================
# 企业级服务定义
# =============================================================================
services:

  # =============================================================================
  # MySQL 企业级配置 - 关系型数据库
  # =============================================================================
  mysql-production:
    image: mysql:8.0
    container_name: mysql-production
    restart: unless-stopped

    # 企业级环境变量配置
    environment:
      # 数据库配置
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-MySQL@2024!Secure}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-enterprise_db}
      MYSQL_USER: ${MYSQL_USER:-app_user}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-AppUser@2024!Secure}

      # 性能优化配置
      MYSQL_INNODB_BUFFER_POOL_SIZE: ${MYSQL_INNODB_BUFFER_POOL_SIZE:-1G}
      MYSQL_QUERY_CACHE_SIZE: ${MYSQL_QUERY_CACHE_SIZE:-64M}
      MYSQL_MAX_CONNECTIONS: ${MYSQL_MAX_CONNECTIONS:-500}

      # 安全配置
      MYSQL_ROOT_HOST: ${MYSQL_ROOT_HOST:-localhost}
      MYSQL_LOG_BIN: "ON"
      MYSQL_BINLOG_FORMAT: "ROW"

      # 时区和字符集
      TZ: Asia/Shanghai
      MYSQL_INITDB_SKIP_TZINFO: 0

    # 企业级资源限制
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

    # 数据卷挂载
    volumes:
      - mysql-data:/var/lib/mysql
      - mysql-config:/etc/mysql/conf.d
      - mysql-logs:/var/log/mysql
      - mysql-backup:/backup

    # 网络配置
    networks:
      - database-network
      - monitoring-network

    # 企业级健康检查
    healthcheck:
      test: [ "CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

    # 安全标签
    labels:
      - "com.company.service=mysql"
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.backup.required=true"
      - "com.company.monitoring.required=true"
      - "traefik.enable=false"

    # 日志配置
    logging:
      driver: json-file
      options:
        max-size: "100m"
        max-file: "5"
        labels: "com.company.service,mysql"
        env: "MYSQL_DATABASE,TZ"

    # 安全选项
    security_opt:
      - no-new-privileges:true

    # 用户权限（非 root 用户运行）
    user: "999:999"

  # =============================================================================
  # Redis 企业级配置 - 内存数据库
  # =============================================================================
  redis-production:
    image: redis:7-alpine
    container_name: redis-production
    restart: unless-stopped

    # 企业级命令配置
    command: >
      redis-server
      --port 6379
      --bind 0.0.0.0
      --protected-mode yes
      --requirepass ${REDIS_PASSWORD:-Redis@2024!Secure}
      --maxmemory ${REDIS_MAXMEMORY:-512mb}
      --maxmemory-policy ${REDIS_MAXMEMORY_POLICY:-allkeys-lru}
      --save 900 1
      --save 300 10
      --save 60 10000
      --appendonly yes
      --appendfsync everysec
      --loglevel notice
      --databases 16

    # 企业级资源限制
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

    # 数据卷挂载
    volumes:
      - redis-data:/data
      - redis-config:/usr/local/etc/redis
      - redis-logs:/var/log/redis

    # 网络配置
    networks:
      - database-network
      - application-network
      - monitoring-network

    # 企业级健康检查
    healthcheck:
      test: [ "CMD", "redis-cli", "ping" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

    # 安全标签
    labels:
      - "com.company.service=redis"
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.backup.required=true"
      - "com.company.monitoring.required=true"
      - "traefik.enable=false"

    # 日志配置
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "3"
        labels: "com.company.service,redis"

    # 安全选项
    security_opt:
      - no-new-privileges:true

  # =============================================================================
  # MongoDB 企业级配置 - 文档数据库
  # =============================================================================
  mongodb-production:
    image: mongo:6
    container_name: mongodb-production
    restart: unless-stopped

    # 企业级环境变量配置
    environment:
      # 数据库配置
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_ROOT_USERNAME:-admin}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_ROOT_PASSWORD:-MongoDB@2024!Secure}
      MONGO_INITDB_DATABASE: ${MONGO_INITDB_DATABASE:-admin}

      # 性能优化配置
      MONGO_STORAGE_ENGINE: wiredTiger
      MONGO_WIREDTIGER_CACHE_SIZE: ${MONGO_WIREDTIGER_CACHE_SIZE:-1G}

      # 安全配置
      TZ: Asia/Shanghai

    # 企业级命令配置
    command: >
      mongod
      --auth
      --bind_ip_all
      --port 27017
      --dbpath /data/db
      --logpath /var/log/mongodb/mongod.log
      --logappend
      --journal
      --storageEngine wiredTiger
      --wiredTigerCacheSizeGB 1
      --wiredTigerJournalCompressor snappy
      --wiredTigerCollectionBlockCompressor snappy
      --wiredTigerIndexPrefixCompression true

    # 企业级资源限制
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

    # 数据卷挂载
    volumes:
      - mongodb-data:/data/db
      - mongodb-config:/etc/mongod
      - mongodb-logs:/var/log/mongodb
      - mongodb-backup:/backup

    # 网络配置
    networks:
      - database-network
      - application-network
      - monitoring-network

    # 企业级健康检查
    healthcheck:
      test: [ "CMD", "mongosh", "--eval", "db.adminCommand('ping')" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

    # 安全标签
    labels:
      - "com.company.service=mongodb"
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.backup.required=true"
      - "com.company.monitoring.required=true"
      - "traefik.enable=false"

    # 日志配置
    logging:
      driver: json-file
      options:
        max-size: "100m"
        max-file: "5"
        labels: "com.company.service,mongodb"
        env: "TZ"

    # 安全选项
    security_opt:
      - no-new-privileges:true

  # =============================================================================
  # PostgreSQL 企业级配置 - 高级关系型数据库
  # =============================================================================
  postgres-production:
    image: postgres:15
    container_name: postgres-production
    restart: unless-stopped

    # 企业级环境变量配置
    environment:
      # 数据库配置
      POSTGRES_DB: ${POSTGRES_DB:-enterprise_db}
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-PostgreSQL@2024!Secure}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=en_US.UTF-8"

      # 性能优化配置
      POSTGRES_SHARED_BUFFERS: ${POSTGRES_SHARED_BUFFERS:-256MB}
      POSTGRES_EFFECTIVE_CACHE_SIZE: ${POSTGRES_EFFECTIVE_CACHE_SIZE:-1GB}
      POSTGRES_WORK_MEM: ${POSTGRES_WORK_MEM:-4MB}
      POSTGRES_MAINTENANCE_WORK_MEM: ${POSTGRES_MAINTENANCE_WORK_MEM:-64MB}
      POSTGRES_MAX_CONNECTIONS: ${POSTGRES_MAX_CONNECTIONS:-200}

      # 安全配置
      POSTGRES_LOG_STATEMENT: all
      POSTGRES_LOG_MIN_DURATION_STATEMENT: 1000
      POSTGRES_LOG_LINE_PREFIX: "%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h "

      # 时区配置
      TZ: Asia/Shanghai
      POSTGRES_TIMEZONE: Asia/Shanghai

    # 企业级资源限制
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

    # 数据卷挂载
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - postgres-config:/etc/postgresql
      - postgres-logs:/var/log/postgresql
      - postgres-backup:/backup

    # 网络配置
    networks:
      - database-network
      - application-network
      - monitoring-network

    # 企业级健康检查
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

    # 安全标签
    labels:
      - "com.company.service=postgres"
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.backup.required=true"
      - "com.company.monitoring.required=true"
      - "traefik.enable=false"

    # 日志配置
    logging:
      driver: json-file
      options:
        max-size: "100m"
        max-file: "5"
        labels: "com.company.service,postgres"
        env: "POSTGRES_DB,TZ"

    # 安全选项
    security_opt:
      - no-new-privileges:true

  # =============================================================================
  # Elasticsearch 企业级配置 - 搜索引擎
  # =============================================================================
  elasticsearch-production:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch-production
    restart: unless-stopped

    # 企业级环境变量配置
    environment:
      # 集群配置
      cluster.name: ${ELASTIC_CLUSTER_NAME:-enterprise-cluster}
      node.name: ${ELASTIC_NODE_NAME:-elasticsearch-master}
      discovery.type: single-node

      # 内存配置
      ES_JAVA_OPTS: "-Xms1g -Xmx1g"

      # 安全配置
      xpack.security.enabled: true
      xpack.security.transport.ssl.enabled: true
      ELASTIC_PASSWORD: ${ELASTIC_PASSWORD:-ElasticSearch@2024!Secure}

      # 性能优化
      bootstrap.memory_lock: true

      # 时区配置
      TZ: Asia/Shanghai

    # 企业级资源限制
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

    # 数据卷挂载
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
      - elasticsearch-config:/usr/share/elasticsearch/config
      - elasticsearch-logs:/usr/share/elasticsearch/logs

    # 网络配置
    networks:
      - application-network
      - monitoring-network

    # 系统配置
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536

    # 企业级健康检查
    healthcheck:
      test: [ "CMD-SHELL", "curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health | grep -q 'yellow\\|green'" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s

    # 安全标签
    labels:
      - "com.company.service=elasticsearch"
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.backup.required=true"
      - "com.company.monitoring.required=true"
      - "traefik.enable=true"
      - "traefik.http.routers.elasticsearch.rule=Host(\`elasticsearch.${DOMAIN:-localhost}\`)"
      - "traefik.http.routers.elasticsearch.tls=true"
      - "traefik.http.services.elasticsearch.loadbalancer.server.port=9200"

    # 日志配置
    logging:
      driver: json-file
      options:
        max-size: "100m"
        max-file: "5"
        labels: "com.company.service,elasticsearch"
        env: "cluster.name,TZ"

    # 安全选项
    security_opt:
      - no-new-privileges:true

  # =============================================================================
  # Nginx 企业级配置 - Web 服务器和反向代理
  # =============================================================================
  nginx-production:
    image: nginx:alpine
    container_name: nginx-production
    restart: unless-stopped

    # 端口映射
    ports:
      - "80:80"
      - "443:443"

    # 数据卷挂载
    volumes:
      - nginx-config:/etc/nginx
      - nginx-logs:/var/log/nginx
      - nginx-certs:/etc/ssl/certs

    # 网络配置
    networks:
      - web-network
      - application-network
      - monitoring-network

    # 企业级健康检查
    healthcheck:
      test: [ "CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

    # 安全标签
    labels:
      - "com.company.service=nginx"
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.monitoring.required=true"
      - "traefik.enable=false"

    # 日志配置
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "3"
        labels: "com.company.service,nginx"

    # 安全选项
    security_opt:
      - no-new-privileges:true

  # =============================================================================
  # MinIO 企业级配置 - 对象存储
  # =============================================================================
  minio-production:
    image: minio/minio:latest
    container_name: minio-production
    restart: unless-stopped

    # 端口映射
    ports:
      - "9000:9000"    # API 端口
      - "9001:9001"    # Web 控制台端口

    # 企业级环境变量配置
    environment:
      # 访问密钥配置
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-MinIO@2024!Secure}

      # 安全配置
      MINIO_BROWSER: "on"
      MINIO_PROMETHEUS_AUTH_TYPE: public

      # 性能优化
      MINIO_API_SELECT_PARQUET: "on"

      # 时区配置
      TZ: Asia/Shanghai

    # 企业级命令配置
    command: server /data --console-address ":9001"

    # 企业级资源限制
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

    # 数据卷挂载
    volumes:
      - minio-data:/data
      - minio-config:/root/.minio
      - minio-logs:/var/log/minio

    # 网络配置
    networks:
      - application-network
      - web-network
      - monitoring-network

    # 企业级健康检查
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:9000/minio/health/live" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

    # 安全标签
    labels:
      - "com.company.service=minio"
      - "com.company.environment=production"
      - "com.company.security.level=high"
      - "com.company.backup.required=true"
      - "com.company.monitoring.required=true"
      - "traefik.enable=true"
      - "traefik.http.routers.minio.rule=Host(\`minio.${DOMAIN:-localhost}\`)"
      - "traefik.http.routers.minio.tls=true"
      - "traefik.http.services.minio.loadbalancer.server.port=9001"

    # 日志配置
    logging:
      driver: json-file
      options:
        max-size: "100m"
        max-file: "5"
        labels: "com.company.service,minio"
        env: "TZ"

    # 安全选项
    security_opt:
      - no-new-privileges:true

# =============================================================================
# 企业级配置说明
# =============================================================================
# 
# 使用说明：
# 1. 首先创建环境变量文件 .env
# 2. 配置数据库密码等敏感信息
# 3. 使用命令启动服务：docker-compose -f docker-compose-enterprise.yml up -d
# 4. 查看服务状态：docker-compose -f docker-compose-enterprise.yml ps
# 5. 查看服务日志：docker-compose -f docker-compose-enterprise.yml logs [服务名]
# 6. 停止服务：docker-compose -f docker-compose-enterprise.yml down
#
# 安全注意事项：
# 1. 务必修改默认密码
# 2. 配置防火墙规则
# 3. 启用 SSL/TLS 加密
# 4. 定期更新镜像版本
# 5. 配置备份策略
# 6. 监控资源使用情况
# 7. 设置访问控制策略
#
# 性能优化建议：
# 1. 根据实际负载调整资源限制
# 2. 配置合适的内存参数
# 3. 优化数据库配置参数
# 4. 使用 SSD 存储
# 5. 配置读写分离
# 6. 使用连接池
#
# 监控告警：
# 1. 配置健康检查告警
# 2. 监控资源使用率
# 3. 监控磁盘空间
# 4. 监控网络流量
# 5. 监控数据库性能指标
# =============================================================================

```
