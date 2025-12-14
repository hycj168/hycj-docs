#!/bin/bash

# =============================================================================
# Docker 数据库配置文件生成脚本
# =============================================================================
# 脚本名称: generate-configs.sh
# 功能描述: 为各种数据库生成优化的配置文件
# 支持数据库: MySQL、Redis、MongoDB、PostgreSQL、Elasticsearch
# =============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 基础目录
readonly BASE_DIR="/opt/docker-volumes"
readonly CONFIG_DIR="$BASE_DIR/shared/configs"

# 打印信息函数
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

print_title() {
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}================================================${NC}\n"
}

# 检查目录是否存在
check_directories() {
    if [ ! -d "$BASE_DIR" ]; then
        print_error "Docker 卷目录不存在: $BASE_DIR"
        print_info "请先运行 docker-volumes-setup.sh 脚本创建目录结构"
        exit 1
    fi
}

# 生成 MySQL 配置文件
generate_mysql_config() {
    print_title "生成 MySQL 配置文件"
    
    local mysql_config_dir="$BASE_DIR/mysql/config"
    
    # 创建配置文件
    cat > "$mysql_config_dir/my.cnf" << 'EOF'
# MySQL 企业级配置文件
# 适用于 Docker 容器环境
# 优化参数根据 2GB 内存环境调整，可根据实际情况修改

[mysqld]
# 基础设置
user = mysql
port = 3306
socket = /var/run/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking = ON

# 字符集设置（推荐使用 utf8mb4）
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'

# 存储引擎设置
default-storage-engine = InnoDB
sql-mode = STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION

# 连接设置
max_connections = 200                   # 最大连接数，根据服务器性能调整
max_user_connections = 180                # 单个用户最大连接数
max_connect_errors = 1000                 # 最大连接错误数
wait_timeout = 600                        # 非交互连接超时时间（秒）
interactive_timeout = 600                # 交互连接超时时间（秒）
connect_timeout = 30                      # 连接超时时间（秒）

# 内存设置（根据服务器内存调整）
key_buffer_size = 32M                    # MyISAM 索引缓冲区大小
max_allowed_packet = 64M                 # 最大允许数据包大小
thread_stack = 256K                       # 线程栈大小
thread_cache_size = 8                     # 线程缓存大小
query_cache_size = 0                      # 查询缓存大小（MySQL 8.0 已废弃）
query_cache_type = 0                      # 查询缓存类型（MySQL 8.0 已废弃）

# InnoDB 设置
innodb_buffer_pool_size = 1G              # InnoDB 缓冲池大小（建议为内存的 50-70%）
innodb_buffer_pool_instances = 8          # InnoDB 缓冲池实例数
innodb_log_file_size = 256M               # InnoDB 日志文件大小
innodb_log_buffer_size = 16M              # InnoDB 日志缓冲区大小
innodb_flush_log_at_trx_commit = 2        # 事务提交时刷新日志（1最安全，2性能更好）
innodb_lock_wait_timeout = 50             # InnoDB 锁等待超时时间（秒）
innodb_flush_method = O_DIRECT            # InnoDB 刷新方法（避免双重缓冲）
innodb_file_per_table = 1                 # 每个表独立表空间
innodb_io_capacity = 2000                 # InnoDB I/O 容量
innodb_io_capacity_max = 4000             # InnoDB 最大 I/O 容量
innodb_read_io_threads = 4                # InnoDB 读 I/O 线程数
innodb_write_io_threads = 4               # InnoDB 写 I/O 线程数

# 日志设置
log_error = /var/log/mysql/error.log      # 错误日志文件
slow_query_log = 1                        # 启用慢查询日志
slow_query_log_file = /var/log/mysql/slow.log  # 慢查询日志文件
long_query_time = 2                       # 慢查询时间阈值（秒）
log_queries_not_using_indexes = 1         # 记录未使用索引的查询

# 二进制日志设置（用于主从复制和点时间恢复）
server-id = 1                             # 服务器 ID（主从复制时需要唯一）
log_bin = /var/log/mysql/mysql-bin.log    # 二进制日志文件
binlog_format = ROW                       # 二进制日志格式（ROW、STATEMENT、MIXED）
binlog_row_image = FULL                   # 二进制日志行图像
expire_logs_days = 7                      # 二进制日志过期天数（MySQL 8.0 以下）
binlog_expire_logs_seconds = 604800       # 二进制日志过期秒数（MySQL 8.0+）
max_binlog_size = 100M                    # 最大二进制日志文件大小
sync_binlog = 1                           # 二进制日志同步（1最安全）

# 临时表设置
tmp_table_size = 64M                      # 内存临时表最大大小
max_heap_table_size = 64M                 # 内存表最大大小

# 排序和连接设置
sort_buffer_size = 2M                     # 排序缓冲区大小
read_buffer_size = 1M                     # 顺序读缓冲区大小
read_rnd_buffer_size = 4M                 # 随机读缓冲区大小
join_buffer_size = 2M                     # 连接缓冲区大小
bulk_insert_buffer_size = 64M             # 批量插入缓冲区大小

# 表缓存设置
open_files_limit = 65535                  # 打开文件数限制
table_open_cache = 4000                   # 表缓存数
max_tmp_tables = 32                       # 最大临时表数

[mysql]
# MySQL 客户端设置
prompt = "\\u@\\h [\\d]> "                  # 命令提示符格式
default-character-set = utf8mb4           # 默认字符集

[client]
# 客户端设置
port = 3306
socket = /var/run/mysqld/mysqld.sock
default-character-set = utf8mb4           # 默认字符集

[mysqldump]
# 导出工具设置
quick
quote-names
max_allowed_packet = 64M                  # 最大允许数据包大小

[mysql_safe]
# 安全启动设置
log-error = /var/log/mysql/error.log
EOF

    print_success "MySQL 配置文件生成完成: $mysql_config_dir/my.cnf"
}

# 生成 Redis 配置文件
generate_redis_config() {
    print_title "生成 Redis 配置文件"
    
    local redis_config_dir="$BASE_DIR/redis/config"
    
    cat > "$redis_config_dir/redis.conf" << 'EOF'
# Redis 企业级配置文件
# 适用于 Docker 容器环境
# 优化参数根据 1GB 内存环境调整

# 网络设置
bind 0.0.0.0                              # 绑定所有网络接口（Docker 环境需要）
port 6379                                  # Redis 端口
protected-mode yes                         # 保护模式（只允许本地连接）
timeout 300                                # 连接超时时间（秒）
tcp-keepalive 300                          # TCP 保持连接时间（秒）

# 通用设置
daemonize no                               # 不以守护进程方式运行（Docker 需要）
supervised no                              # 无监督模式
pidfile /var/run/redis/redis-server.pid    # PID 文件路径
loglevel notice                            # 日志级别（debug、verbose、notice、warning）
logfile /var/log/redis/redis-server.log    # 日志文件路径
databases 16                               # 数据库数量

# 持久化设置（RDB 快照）
save 900 1                                 # 900 秒（15 分钟）内至少有 1 个 key 改变则保存
save 300 10                                # 300 秒（5 分钟）内至少有 10 个 key 改变则保存
save 60 10000                              # 60 秒内至少有 10000 个 key 改变则保存
stop-writes-on-bgsave-error yes            # 后台保存出错时停止写入
rdbcompression yes                         # RDB 文件压缩
rdbchecksum yes                            # RDB 文件校验
dbfilename dump.rdb                        # RDB 文件名
dir /data                                  # 数据文件目录

# 持久化设置（AOF 日志）
appendonly yes                             # 启用 AOF 持久化
appendfilename "appendonly.aof"            # AOF 文件名
appendfsync everysec                       # AOF 同步策略（everysec、always、no）
no-appendfsync-on-rewrite no               # 重写时不暂停 AOF 同步
auto-aof-rewrite-percentage 100            # AOF 重写触发百分比
auto-aof-rewrite-min-size 64mb             # AOF 重写最小文件大小
aof-load-truncated yes                     # 加载截断的 AOF 文件
aof-use-rdb-preamble yes                   # AOF 文件使用 RDB 前缀

# 内存设置
maxmemory 512mb                            # 最大内存使用量（根据服务器调整）
maxmemory-policy allkeys-lru               # 内存淘汰策略（LRU 最近最少使用）
maxmemory-samples 5                        # LRU 采样数量

# 客户端设置
maxclients 10000                           # 最大客户端连接数
client-output-buffer-limit normal 0 0 0    # 普通客户端输出缓冲区限制
client-output-buffer-limit replica 256mb 64mb 60  # 从库客户端输出缓冲区限制
client-output-buffer-limit pubsub 32mb 8mb 60   # 发布订阅客户端输出缓冲区限制

# 安全设置（生产环境必须配置）
# requirepass your-strong-password-here     # 设置 Redis 密码（取消注释并设置强密码）
# rename-command FLUSHDB ""                  # 禁用危险命令（可选）
# rename-command FLUSHALL ""                 # 禁用危险命令（可选）
# rename-command CONFIG ""                   # 禁用危险命令（可选）

# 性能优化设置
tcp-backlog 511                            # TCP 连接队列长度
hz 10                                      # 后台任务执行频率（1-500）
dynamic-hz yes                             # 动态调整后台任务频率
aof-rewrite-incremental-fsync yes          # AOF 重写时增量同步
rdb-save-incremental-fsync yes             # RDB 保存时增量同步

# 高级设置
hash-max-ziplist-entries 512               # 哈希表使用 ziplist 的最大条目数
hash-max-ziplist-value 64                  # 哈希表使用 ziplist 的最大值大小
list-max-ziplist-size -2                   # 列表使用 ziplist 的最大大小
list-compress-depth 0                      # 列表压缩深度
set-max-intset-entries 512                 # 集合使用 intset 的最大条目数
zset-max-ziplist-entries 128               # 有序集合使用 ziplist 的最大条目数
zset-max-ziplist-value 64                  # 有序集合使用 ziplist 的最大值大小
hll-sparse-max-bytes 3000                  # HyperLogLog 稀疏表示的最大字节数
stream-node-max-bytes 4096                 # Stream 节点最大字节数
stream-node-max-entries 100                 # Stream 节点最大条目数
activerehashing yes                        # 启用主动重新哈希
client-query-buffer-limit 1gb              # 客户端查询缓冲区限制
EOF

    print_success "Redis 配置文件生成完成: $redis_config_dir/redis.conf"
}

# 生成 MongoDB 配置文件
generate_mongodb_config() {
    print_title "生成 MongoDB 配置文件"
    
    local mongodb_config_dir="$BASE_DIR/mongodb/config"
    
    cat > "$mongodb_config_dir/mongod.conf" << 'EOF'
# MongoDB 企业级配置文件
# 适用于 Docker 容器环境
# 优化参数根据 2GB 内存环境调整

# 存储引擎设置
storage:
  dbPath: /data/db                          # 数据文件目录
  journal:
    enabled: true                           # 启用日志（推荐）
  engine: wiredTiger                        # 存储引擎（WiredTiger 推荐）
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1                        # WiredTiger 缓存大小（建议内存的 50%）
      journalCompressor: snappy             # 日志压缩算法（snappy、zlib、none）
      directoryForIndexes: false            # 索引文件是否单独目录
    collectionConfig:
      blockCompressor: snappy               # 集合压缩算法（snappy、zlib、none）
    indexConfig:
      prefixCompression: true               # 索引前缀压缩

# 网络设置
net:
  port: 27017                              # MongoDB 端口
  bindIp: 0.0.0.0                          # 绑定所有网络接口（Docker 环境需要）
  maxIncomingConnections: 1000             # 最大连接数
  wireObjectCheck: true                    # 检查文档有效性
  ipv6: false                              # 禁用 IPv6

# 进程管理设置
processManagement:
  fork: false                              # 不以守护进程方式运行（Docker 需要）
  pidFilePath: /var/run/mongodb/mongod.pid # PID 文件路径

# 日志设置
systemLog:
  destination: file                        # 日志输出目标（file、syslog）
  path: /var/log/mongodb/mongod.log      # 日志文件路径
  logAppend: true                          # 日志追加模式
  logRotate: rename                        # 日志轮转方式（rename、reopen）
  timeStampFormat: iso8601-local          # 时间戳格式
  component:
    accessControl:
      verbosity: 0                         # 访问控制日志详细度
    command:
      verbosity: 0                         # 命令日志详细度
    control:
      verbosity: 0                         # 控制日志详细度
    executor:
      verbosity: 0                         # 执行器日志详细度
    geo:
      verbosity: 0                         # 地理空间日志详细度
    index:
      verbosity: 0                         # 索引日志详细度
    network:
      verbosity: 0                         # 网络日志详细度
    query:
      verbosity: 0                         # 查询日志详细度
    replication:
      verbosity: 0                         # 复制日志详细度
    sharding:
      verbosity: 0                         # 分片日志详细度
    storage:
      verbosity: 0                         # 存储日志详细度
      journal:
        verbosity: 0                       # 日志日志详细度
    write:
      verbosity: 0                         # 写入日志详细度

# 安全设置（生产环境必须配置）
security:
  authorization: enabled                   # 启用认证（必须）
  # keyFile: /etc/mongo/keyfile             # 密钥文件（副本集需要）
  # clusterAuthMode: keyFile                # 集群认证模式
  # javascriptEnabled: false                # 禁用服务器端 JavaScript（可选）

# 复制集设置（可选）
# replication:
#   replSetName: rs0                         # 复制集名称
#   enableMajorityReadConcern: true          # 启用多数读关注
#   secondaryIndexPrefetch: all              # 从节点索引预取

# 分片设置（可选）
# sharding:
#   clusterRole: configsvr                   # 集群角色（configsvr、shardsvr）
#   archiveMovedChunks: true                 # 归档移动的分片

# 操作日志设置（复制集需要）
# oplogSizeMB: 1024                        # 操作日志大小（MB）

# 性能优化设置
operationProfiling:
  slowOpThresholdMs: 100                   # 慢操作阈值（毫秒）
  mode: slowOp                              # 性能分析模式（off、slowOp、all）

# 性能监控设置
# setParameter:
#   enableLocalhostAuthBypass: false         # 禁用本地主机认证绕过
#   authenticationMechanisms: SCRAM-SHA-1    # 认证机制
#   failIndexKeyTooLong: true                # 索引键过长失败
#   maxTransactionLockRequestTimeoutMillis: 10 # 事务锁请求超时（毫秒）

# 审计日志设置（可选，需要企业版）
# auditLog:
#   destination: file                        # 审计日志目标
#   path: /var/log/mongodb/audit.log       # 审计日志文件路径
#   filter: '{}'                           # 审计日志过滤器
#   format: JSON                             # 审计日志格式
EOF

    print_success "MongoDB 配置文件生成完成: $mongodb_config_dir/mongod.conf"
}

# 生成 PostgreSQL 配置文件
generate_postgres_config() {
    print_title "生成 PostgreSQL 配置文件"
    
    local postgres_config_dir="$BASE_DIR/postgres/config"
    
    # 创建主配置文件
    cat > "$postgres_config_dir/postgresql.conf" << 'EOF'
# PostgreSQL 企业级配置文件
# 适用于 Docker 容器环境
# 优化参数根据 2GB 内存环境调整

# 连接和认证设置
listen_addresses = '*'                      # 监听地址（* 表示所有地址，Docker 需要）
port = 5432                                # PostgreSQL 端口
max_connections = 200                      # 最大连接数（根据服务器性能调整）
superuser_reserved_connections = 3           # 超级用户保留连接数

# 内存设置
shared_buffers = 512MB                      # 共享缓冲区（建议内存的 25%）
work_mem = 4MB                              # 工作内存（每个操作）
maintenance_work_mem = 64MB                 # 维护工作内存（VACUUM、CREATE INDEX 等）
effective_cache_size = 1536MB               # 有效缓存大小（建议内存的 75%）
wal_buffers = 16MB                          # WAL 缓冲区大小
temp_buffers = 8MB                          # 临时缓冲区大小

# WAL（预写日志）设置
wal_level = replica                         # WAL 级别（minimal、replica、logical）
wal_buffers = 16MB                          # WAL 缓冲区大小
wal_writer_delay = 200ms                    # WAL 写入延迟
commit_delay = 0                            # 提交延迟（微秒）
commit_siblings = 5                         # 提交兄弟事务数

# 检查点设置
checkpoint_timeout = 5min                   # 检查点超时时间
checkpoint_completion_target = 0.9         # 检查点完成目标（0.1-0.9）
checkpoint_flush_after = 256kB              # 检查点后刷新大小
max_wal_size = 1GB                          # 最大 WAL 大小
min_wal_size = 512MB                        # 最小 WAL 大小
checkpoint_warning = 30s                    # 检查点警告时间

# 日志设置
log_destination = 'stderr'                  # 日志目标（stderr、csvlog、syslog、eventlog）
logging_collector = on                      # 启用日志收集器
log_directory = '/var/log/postgresql'       # 日志目录
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'  # 日志文件名格式
log_file_mode = 0600                        # 日志文件权限
log_truncate_on_rotation = off              # 日志轮转时是否截断
log_rotation_age = 1d                       # 日志轮转时间（1天）
log_rotation_size = 100MB                 # 日志轮转大小（100MB）

# 日志级别设置
log_min_messages = warning                  # 最小日志级别（debug5、debug4、debug3、debug2、debug1、info、notice、warning、error、log、fatal、panic）
log_min_error_statement = error             # 最小错误语句日志级别
log_min_duration_statement = 1000           # 最小持续时间语句日志（毫秒，1000ms = 1s）

# 日志内容设置
log_checkpoints = on                        # 记录检查点
log_connections = on                        # 记录连接
log_disconnections = on                     # 记录断开连接
log_duration = off                          # 记录语句持续时间
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '  # 日志行前缀
log_lock_waits = on                         # 记录锁等待
log_statement = 'none'                     # 记录语句类型（none、ddl、mod、all）
log_temp_files = 10                        # 记录临时文件（10MB以上）

# 性能监控设置
shared_preload_libraries = 'pg_stat_statements'  # 预加载库（性能监控）
track_activities = on                       # 跟踪活动
track_counts = on                          # 跟踪计数
track_io_timing = on                       # 跟踪 I/O 时间
track_functions = all                      # 跟踪函数（none、pl、all）
stats_temp_directory = 'pg_stat_tmp'      # 统计临时目录

# 查询规划器设置
seq_page_cost = 1.0                        # 顺序页成本
random_page_cost = 4.0                     # 随机页成本
cpu_tuple_cost = 0.01                      # CPU 元组成本
cpu_index_tuple_cost = 0.005               # CPU 索引元组成本
cpu_operator_cost = 0.0025                 # CPU 操作符成本
parallel_tuple_cost = 0.1                  # 并行元组成本
parallel_setup_cost = 1000.0               # 并行设置成本
min_parallel_table_scan_size = 8MB        # 最小并行表扫描大小
min_parallel_index_scan_size = 512kB        # 最小并行索引扫描大小
effective_io_concurrency = 200              # 有效 I/O 并发数（SSD 可设置更高）

# 并行查询设置
max_parallel_workers = 8                   # 最大并行工作进程数
max_parallel_workers_per_gather = 2       # 每个 Gather 的最大并行工作进程数

# 自动清理设置
autovacuum = on                            # 启用自动清理
autovacuum_max_workers = 3                # 最大自动清理工作进程数
autovacuum_naptime = 1min                   # 自动清理间隔时间
autovacuum_vacuum_threshold = 50           # 清理阈值
autovacuum_analyze_threshold = 50          # 分析阈值
autovacuum_vacuum_scale_factor = 0.2       # 清理比例因子
autovacuum_analyze_scale_factor = 0.1      # 分析比例因子
autovacuum_freeze_max_age = 200000000      # 冻结最大年龄
autovacuum_multixact_freeze_max_age = 400000000  # 多事务冻结最大年龄
autovacuum_vacuum_cost_delay = 20ms        # 清理成本延迟
autovacuum_vacuum_cost_limit = -1          # 清理成本限制（-1 表示使用默认值）

# 锁设置
deadlock_timeout = 1s                      # 死锁超时时间
lock_timeout = 0                           # 锁超时时间（0 表示不超时）
idle_in_transaction_session_timeout = 0      # 空闲事务会话超时时间

# 其他设置
max_worker_processes = 8                   # 最大工作进程数
max_files_per_process = 1000               # 每个进程最大文件数
shared_preload_libraries = ''               # 预加载库（多个库用逗号分隔）
dynamic_shared_memory_type = posix         # 动态共享内存类型
EOF

    # 创建 pg_hba.conf 认证配置文件
    cat > "$postgres_config_dir/pg_hba.conf" << 'EOF'
# PostgreSQL 客户端认证配置文件
# 格式：TYPE  DATABASE        USER            ADDRESS                 METHOD

# 本地连接（Unix 域套接字）
local   all             all                                     trust

# IPv4 本地连接
host    all             all             127.0.0.1/32            trust

# IPv6 本地连接
host    all             all             ::1/128                 trust

# Docker 网络连接（允许 Docker 容器连接）
host    all             all             172.16.0.0/12           md5
host    all             all             192.168.0.0/16          md5
host    all             all             10.0.0.0/8              md5

# 拒绝其他所有连接
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
EOF

    print_success "PostgreSQL 配置文件生成完成"
    print_success "  - 主配置: $postgres_config_dir/postgresql.conf"
    print_success "  - 认证配置: $postgres_config_dir/pg_hba.conf"
}

# 生成 Elasticsearch 配置文件
generate_elasticsearch_config() {
    print_title "生成 Elasticsearch 配置文件"
    
    local elasticsearch_config_dir="$BASE_DIR/elasticsearch/config"
    
    cat > "$elasticsearch_config_dir/elasticsearch.yml" << 'EOF'
# Elasticsearch 企业级配置文件
# 适用于 Docker 容器环境
# 单节点配置，适用于开发环境

# 集群设置
cluster.name: docker-cluster              # 集群名称
node.name: node-1                          # 节点名称
node.roles: [master, data, ingest]         # 节点角色

# 网络设置
network.host: 0.0.0.0                      # 网络绑定地址（Docker 需要）
http.port: 9200                            # HTTP 端口
transport.port: 9300                       # 传输端口
http.cors.enabled: true                    # 启用 CORS（开发环境需要）
http.cors.allow-origin: "*"              # 允许所有来源（开发环境）

# 发现和集群设置
discovery.type: single-node                # 发现类型（单节点模式）
# discovery.seed_hosts: ["node1", "node2"]  # 种子主机列表（多节点模式）
# cluster.initial_master_nodes: ["node1"]  # 初始主节点（多节点模式）

# 索引设置
indices.query.bool.max_clause_count: 1024  # 布尔查询最大子句数
indices.memory.index_buffer_size: 10%      # 索引缓冲区大小（堆内存的百分比）
indices.memory.min_index_buffer_size: 48mb # 最小索引缓冲区大小
indices.memory.max_index_buffer_size: 512mb # 最大索引缓冲区大小

# 分片和副本设置
# index.number_of_shards: 1                 # 索引分片数（默认 1）
# index.number_of_replicas: 1               # 索引副本数（默认 1）
# index.routing.allocation.enable: all        # 分片分配启用
# index.routing.allocation.total_shards_per_node: -1 # 每个节点总分片数限制

# 字段数据设置
indices.fielddata.cache.size: 20%          # 字段数据缓存大小（堆内存百分比）
indices.fielddata.cache.expire: 6h         # 字段数据缓存过期时间

# 请求缓存设置
indices.requests.cache.size: 1%            # 请求缓存大小（堆内存百分比）
indices.requests.cache.expire: 1m          # 请求缓存过期时间

# 查询缓存设置
indices.queries.cache.size: 10%            # 查询缓存大小（堆内存百分比）
indices.queries.cache.count: 10000          # 查询缓存条目数

# 搜索设置
search.max_buckets: 10000                  # 聚合最大桶数
search.allow_expensive_queries: true       # 允许昂贵查询
search.default_keep_alive: 5m              # 默认保持活动时间
search.max_keep_alive: 24h                  # 最大保持活动时间

# 聚合设置
search.max_open_scroll_context: 500        # 最大打开滚动上下文数
search.max_async_search_response_size: 10mb # 最大异步搜索响应大小

# JVM 设置（通过环境变量设置）
# ES_JAVA_OPTS: "-Xms1g -Xmx1g"           # JVM 堆内存设置（通过 Docker 环境变量）

# 脚本设置
script.allowed_types: inline, stored       # 允许的脚本类型
script.max_compilations_rate: 150/5m       # 脚本编译速率限制
script.cache.max_size: 100                 # 脚本缓存最大大小
script.context.field.max_compilations_rate: 75/5m # 字段脚本编译速率
script.context.filter.max_compilations_rate: 75/5m # 过滤脚本编译速率

# 监控设置
monitoring.enabled: false                  # 启用监控（需要额外配置）
xpack.monitoring.collection.enabled: false # X-Pack 监控收集
xpack.monitoring.collection.interval: 10s  # 监控收集间隔

# 安全设置（生产环境需要）
# xpack.security.enabled: true             # 启用安全（需要 X-Pack）
# xpack.security.transport.ssl.enabled: true # 启用传输 SSL
# xpack.security.http.ssl.enabled: true   # 启用 HTTP SSL

# 日志设置
logger.level: INFO                          # 日志级别（ERROR、WARN、INFO、DEBUG、TRACE）
logger.org.elasticsearch.discovery: DEBUG   # 发现模块日志级别
logger.org.elasticsearch.cluster.service: DEBUG # 集群服务日志级别
logger.org.elasticsearch.indices.recovery: DEBUG # 索引恢复日志级别
logger.org.elasticsearch.index.search.slowlog: TRACE # 慢查询日志级别
logger.org.elasticsearch.index.indexing.slowlog: TRACE # 慢索引日志级别

# 慢日志设置
index.search.slowlog.threshold.query.warn: 10s    # 慢查询警告阈值
index.search.slowlog.threshold.query.info: 5s     # 慢查询信息阈值
index.search.slowlog.threshold.query.debug: 2s     # 慢查询调试阈值
index.search.slowlog.threshold.query.trace: 500ms # 慢查询跟踪阈值

index.search.slowlog.threshold.fetch.warn: 1s    # 慢获取警告阈值
index.search.slowlog.threshold.fetch.info: 800ms # 慢获取信息阈值
index.search.slowlog.threshold.fetch.debug: 500ms # 慢获取调试阈值
index.search.slowlog.threshold.fetch.trace: 200ms  # 慢获取跟踪阈值

index.indexing.slowlog.threshold.index.warn: 10s   # 慢索引警告阈值
index.indexing.slowlog.threshold.index.info: 5s    # 慢索引信息阈值
index.indexing.slowlog.threshold.index.debug: 2s    # 慢索引调试阈值
index.indexing.slowlog.threshold.index.trace: 500ms # 慢索引跟踪阈值

# 集群路由设置
cluster.routing.allocation.enable: all      # 分片分配启用
cluster.routing.allocation.node_concurrent_recoveries: 2 # 节点并发恢复数
cluster.routing.allocation.node_initial_primaries_recoveries: 4 # 节点初始主分片恢复数
cluster.routing.allocation.same_shard.host: true # 同一主机分片分配
cluster.routing.rebalance.enable: all       # 重新平衡启用
cluster.routing.allocation.cluster_concurrent_rebalance: 2 # 集群并发重新平衡数
cluster.routing.allocation.balance.shard: 0.45f # 分片平衡权重
cluster.routing.allocation.balance.index: 0.55f # 索引平衡权重
cluster.routing.allocation.balance.threshold: 1.0f # 平衡阈值

# 节点设置
node.max_local_storage_nodes: 1           # 最大本地存储节点数
node.attr.box_type: hot                    # 节点属性（冷热分层）

# 路径设置
path.data: /usr/share/elasticsearch/data  # 数据路径
path.logs: /usr/share/elasticsearch/logs  # 日志路径
path.repo: ["/usr/share/elasticsearch/backup"] # 快照仓库路径

# 其他设置
action.destructive_requires_name: true    # 破坏性操作需要名称
action.auto_create_index: true            # 自动创建索引
rest.action.multi.allow_explicit_index: true # 允许多索引操作
EOF

    print_success "Elasticsearch 配置文件生成完成: $elasticsearch_config_dir/elasticsearch.yml"
}

# 生成 Nginx 配置文件
generate_nginx_config() {
    print_title "生成 Nginx 配置文件"
    
    local nginx_config_dir="$BASE_DIR/nginx/config"
    
    # 创建主配置文件
    cat > "$nginx_config_dir/nginx.conf" << 'EOF'
# Nginx 企业级配置文件
# 适用于 Docker 容器环境
# 反向代理和负载均衡配置

user nginx;                                # 运行用户
worker_processes auto;                     # 工作进程数（自动检测 CPU 核心数）
error_log /var/log/nginx/error.log notice; # 错误日志路径和级别
pid /var/run/nginx/nginx.pid;              # PID 文件路径

# 事件模块设置
events {
    worker_connections 1024;               # 每个工作进程最大连接数
    use epoll;                             # 使用 epoll 事件模型（Linux 高性能）
    multi_accept on;                       # 启用多连接接收
    accept_mutex on;                       # 启用连接互斥锁
    accept_mutex_delay 500ms;              # 连接互斥锁延迟
}

# HTTP 模块设置
http {
    # 基本设置
    include /etc/nginx/mime.types;       # MIME 类型文件
    default_type application/octet-stream; # 默认 MIME 类型
    
    # 日志格式设置
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';
    
    log_format json '{"time":"$time_iso8601","remote_addr":"$remote_addr",'
                     '"request":"$request","status":"$status",'
                     '"body_bytes_sent":"$body_bytes_sent",'
                     '"request_time":"$request_time",'
                     '"http_referrer":"$http_referer",'
                     '"http_user_agent":"$http_user_agent",'
                     '"http_x_forwarded_for":"$http_x_forwarded_for",'
                     '"upstream_addr":"$upstream_addr",'
                     '"upstream_status":"$upstream_status",'
                     '"upstream_response_time":"$upstream_response_time"}';
    
    access_log /var/log/nginx/access.log main;  # 访问日志路径
    
    # 性能优化设置
    sendfile on;                             # 启用 sendfile 系统调用
    tcp_nopush on;                          # 启用 TCP NOPUSH
    tcp_nodelay on;                         # 启用 TCP NODELAY
    keepalive_timeout 65;                  # KeepAlive 超时时间（秒）
    keepalive_requests 1000;                 # KeepAlive 最大请求数
    reset_timedout_connection on;         # 重置超时连接
    client_body_timeout 12;                 # 客户端主体超时时间（秒）
    client_header_timeout 12;               # 客户端头部超时时间（秒）
    send_timeout 10;                        # 发送超时时间（秒）
    
    # 缓冲区设置
    client_body_buffer_size 128k;            # 客户端主体缓冲区大小
    client_header_buffer_size 1k;          # 客户端头部缓冲区大小
    client_max_body_size 10m;               # 客户端最大主体大小（文件上传限制）
    large_client_header_buffers 4 4k;       # 大客户端头部缓冲区
    output_buffers 1 32k;                   # 输出缓冲区
    postpone_output 1460;                   # 延迟输出大小
    
    # Gzip 压缩设置
    gzip on;                                # 启用 Gzip 压缩
    gzip_vary on;                           # 启用 Vary 头部
    gzip_min_length 1000;                   # 最小压缩长度（字节）
    gzip_proxied any;                       # 代理压缩设置
    gzip_comp_level 6;                    # 压缩级别（1-9，6 是平衡性能和压缩率）
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/svg+xml
        image/x-icon
        text/css
        text/plain
        text/x-component;
    
    # 安全设置
    server_tokens off;                      # 隐藏 Nginx 版本信息
    server_name_in_redirect off;            # 禁用服务器名称重定向
    port_in_redirect off;                   # 禁用端口重定向
    
    # SSL/TLS 设置（需要 SSL 证书）
    ssl_protocols TLSv1.2 TLSv1.3;         # 支持的 SSL 协议
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;          # 优先服务器密码套件
    ssl_session_cache shared:SSL:10m;       # SSL 会话缓存
    ssl_session_timeout 10m;                # SSL 会话超时时间
    
    # 代理设置
    proxy_connect_timeout 30;               # 代理连接超时时间（秒）
    proxy_send_timeout 30;                  # 代理发送超时时间（秒）
    proxy_read_timeout 30;                  # 代理读取超时时间（秒）
    proxy_buffer_size 4k;                   # 代理缓冲区大小
    proxy_buffers 8 4k;                     # 代理缓冲区数量和大小
    proxy_busy_buffers_size 8k;             # 代理忙缓冲区大小
    proxy_temp_file_write_size 64k;         # 代理临时文件写入大小
    
    # 上游服务器设置（负载均衡）
    upstream backend {
        least_conn;                         # 最少连接负载均衡算法
        server mysql:3306 max_fails=3 fail_timeout=30s;  # MySQL 服务
        server postgres:5432 max_fails=3 fail_timeout=30s backup;  # PostgreSQL 服务（备用）
        keepalive 32;                       # KeepAlive 连接数
    }
    
    # 上游 Redis 服务器设置
    upstream redis_backend {
        server redis:6379 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }
    
    # 上游 MongoDB 服务器设置
    upstream mongodb_backend {
        server mongodb:27017 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }
    
    # 包含其他配置文件
    include /etc/nginx/conf.d/*.conf;       # 包含 conf.d 目录下的配置文件
    include /etc/nginx/sites-enabled/*;     # 包含 sites-enabled 目录下的配置文件
}

# Stream 模块设置（TCP/UDP 负载均衡）
stream {
    upstream mysql_stream {
        server mysql:3306 max_fails=3 fail_timeout=30s;
    }
    
    upstream redis_stream {
        server redis:6379 max_fails=3 fail_timeout=30s;
    }
    
    upstream mongodb_stream {
        server mongodb:27017 max_fails=3 fail_timeout=30s;
    }
    
    upstream postgres_stream {
        server postgres:5432 max_fails=3 fail_timeout=30s;
    }
    
    # MySQL 代理
    server {
        listen 3307;                        # 代理端口（避免与 MySQL 冲突）
        proxy_pass mysql_stream;            # 上游服务器
        proxy_timeout 1s;                   # 代理超时时间
        proxy_responses 1;                  # 代理响应数
        error_log /var/log/nginx/mysql-proxy.log;  # 错误日志
    }
    
    # Redis 代理
    server {
        listen 6380;                        # 代理端口（避免与 Redis 冲突）
        proxy_pass redis_stream;            # 上游服务器
        proxy_timeout 1s;                   # 代理超时时间
        proxy_responses 1;                  # 代理响应数
        error_log /var/log/nginx/redis-proxy.log;  # 错误日志
    }
}
EOF

    # 创建默认站点配置
    mkdir -p "$nginx_config_dir/sites-enabled"
    mkdir -p "$nginx_config_dir/conf.d"
    
    cat > "$nginx_config_dir/sites-enabled/default" << 'EOF'
# 默认站点配置
# 提供基本的信息页面和代理配置示例

server {
    listen 80 default_server;               # 监听端口
    listen [::]:80 default_server;        # IPv6 监听
    server_name _;                          # 服务器名称（通配符）
    
    # 根目录
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    # 日志文件
    access_log /var/log/nginx/default.access.log json;
    error_log /var/log/nginx/default.error.log notice;
    
    # 首页
    location / {
        try_files $uri $uri/ =404;
    }
    
    # 健康检查页面
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # 状态页面（需要 stub_status 模块）
    location /nginx-status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;                    # 只允许本地访问
        allow 172.16.0.0/12;                  # 允许 Docker 网络访问
        deny all;                             # 拒绝其他所有访问
    }
    
    # 数据库代理配置示例
    
    # MySQL 代理（通过 HTTP 协议，需要额外工具）
    location /mysql-proxy {
        proxy_pass http://mysql:3306;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 30;
        proxy_send_timeout 30;
        proxy_read_timeout 30;
    }
    
    # Redis 代理（通过 HTTP 协议，需要额外工具）
    location /redis-proxy {
        proxy_pass http://redis:6379;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 30;
        proxy_send_timeout 30;
        proxy_read_timeout 30;
    }
    
    # API 代理示例
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 30;
        proxy_send_timeout 30;
        proxy_read_timeout 30;
        
        # 缓存设置（可选）
        # proxy_cache api_cache;
        # proxy_cache_valid 200 302 10m;
        # proxy_cache_valid 404 1m;
    }
    
    # 静态文件处理
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;                          # 过期时间（1年）
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        
        # 访问日志关闭（减少日志量）
        access_log off;
    }
    
    # 安全设置
    location ~ /\. {
        deny all;                            # 拒绝访问隐藏文件
    }
    
    location ~ /(config|logs|temp|vendor) {
        deny all;                            # 拒绝访问敏感目录
    }
}
EOF

    # 创建 HTML 目录和默认页面
    mkdir -p "$BASE_DIR/nginx/html"
    
    cat > "$BASE_DIR/nginx/html/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker 企业级数据库服务</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 40px;
            max-width: 800px;
            width: 90%;
            text-align: center;
        }
        h1 {
            color: #333;
            margin-bottom: 30px;
            font-size: 2.5em;
            font-weight: 300;
        }
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .service {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
            transition: transform 0.3s ease;
        }
        .service:hover {
            transform: translateY(-5px);
        }
        .service h3 {
            margin: 0 0 10px 0;
            color: #333;
        }
        .service p {
            margin: 0;
            color: #666;
            font-size: 0.9em;
        }
        .status {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 0.8em;
            font-weight: bold;
        }
        .status.running {
            background: #d4edda;
            color: #155724;
        }
        .status.stopped {
            background: #f8d7da;
            color: #721c24;
        }
        .info {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
            text-align: left;
        }
        .warning {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
            text-align: left;
        }
        .command {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 5px;
            padding: 10px;
            margin: 10px 0;
            font-family: 'Courier New', monospace;
            text-align: left;
            overflow-x: auto;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e9ecef;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Docker 企业级数据库服务</h1>
        
        <div class="info">
            <strong>✅ 系统状态：</strong>所有服务已配置完成，Nginx 代理正常运行
        </div>

        <h2>📊 数据库服务状态</h2>
        <div class="services">
            <div class="service">
                <h3>🗄️ MySQL</h3>
                <p>端口: 3306</p>
                <span class="status running">运行中</span>
            </div>
            <div class="service">
                <h3>🔴 Redis</h3>
                <p>端口: 6379</p>
                <span class="status running">运行中</span>
            </div>
            <div class="service">
                <h3>🍃 MongoDB</h3>
                <p>端口: 27017</p>
                <span class="status running">运行中</span>
            </div>
            <div class="service">
                <h3>🐘 PostgreSQL</h3>
                <p>端口: 5432</p>
                <span class="status running">运行中</span>
            </div>
        </div>

        <div class="warning">
            <strong>⚠️ 安全提醒：</strong>
            <ul>
                <li>请立即修改所有数据库的默认密码</li>
                <li>配置防火墙规则，限制数据库端口访问</li>
                <li>定期备份重要数据</li>
                <li>监控磁盘空间和系统性能</li>
            </ul>
        </div>

        <h2>🚀 快速开始</h2>
        
        <h3>🔧 常用命令</h3>
        <div class="command"># 查看所有容器状态
docker ps -a</div>
        
        <div class="command"># 查看数据库容器日志
docker logs mysql-production</div>
        
        <div class="command"># 连接到 MySQL
docker exec -it mysql-production mysql -u root -p</div>
        
        <div class="command"># 连接到 Redis
docker exec -it redis-production redis-cli</div>
        
        <div class="command"># 连接到 MongoDB
docker exec -it mongodb-production mongosh -u admin -p</div>
        
        <div class="command"># 连接到 PostgreSQL
docker exec -it postgres-production psql -U appuser -d appdb</div>

        <h3>📁 目录结构</h3>
        <div class="command"># 查看数据卷目录结构
tree /opt/docker-volumes -L 2</div>

        <h3>🔄 备份数据</h3>
        <div class="command"># 执行备份脚本
/opt/docker-volumes/shared/scripts/backup-example.sh</div>

        <div class="footer">
            <p>🛠️ 配置生成时间：2024年 | 📖 详细文档请查看 README 文件</p>
            <p>💡 提示：此页面由 Nginx 提供，位于 /opt/docker-volumes/nginx/html/</p>
        </div>
    </div>
</body>
</html>
EOF

    print_success "Nginx 配置文件生成完成"
    print_success "  - 主配置: $nginx_config_dir/nginx.conf"
    print_success "  - 站点配置: $nginx_config_dir/sites-enabled/default"
    print_success "  - 默认页面: $BASE_DIR/nginx/html/index.html"
}

# 生成 Docker 网络配置
generate_docker_network_config() {
    print_title "生成 Docker 网络配置"
    
    local network_config_dir="$BASE_DIR/shared/configs"
    
    cat > "$network_config_dir/docker-networks.yml" << 'EOF'
# Docker 网络配置
# 为企业级数据库服务创建隔离的网络环境

version: '3.8'

networks:
  # 数据库网络 - 用于数据库服务之间的通信
  database-network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: docker-db-br0  # 网桥名称
      com.docker.network.bridge.enable_icc: "true"    # 启用容器间通信
      com.docker.network.bridge.enable_ip_masquerade: "true"  # 启用 IP 伪装
      com.docker.network.bridge.host_binding_ipv4: "0.0.0.0"  # 主机绑定 IPv4
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16              # 子网范围（65534 个可用 IP）
          gateway: 172.20.0.1                # 网关地址
          ip_range: 172.20.1.0/24            # IP 分配范围
          aux_addresses:
            host: 172.20.0.2                 # 主机辅助地址
    labels:
      com.docker.network.description: "Database services network"  # 网络描述
      com.docker.network.environment: "production"               # 环境标签
    
  # Web 网络 - 用于 Web 服务和反向代理
  web-network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: docker-web-br0  # 网桥名称
      com.docker.network.bridge.enable_icc: "true"     # 启用容器间通信
      com.docker.network.bridge.enable_ip_masquerade: "true"   # 启用 IP 伪装
    ipam:
      driver: default
      config:
        - subnet: 172.21.0.0/16              # 子网范围
          gateway: 172.21.0.1                # 网关地址
          ip_range: 172.21.1.0/24            # IP 分配范围
    labels:
      com.docker.network.description: "Web services network"     # 网络描述
      com.docker.network.environment: "production"               # 环境标签
    
  # 应用网络 - 用于应用程序服务
  app-network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: docker-app-br0  # 网桥名称
      com.docker.network.bridge.enable_icc: "true"   # 启用容器间通信
    ipam:
      driver: default
      config:
        - subnet: 172.22.0.0/16              # 子网范围
          gateway: 172.22.0.1                # 网关地址
          ip_range: 172.22.1.0/24            # IP 分配范围
    labels:
      com.docker.network.description: "Application services network"  # 网络描述
      com.docker.network.environment: "production"                  # 环境标签
    
  # 监控网络 - 用于监控和日志服务
  monitoring-network:
    driver: bridge
    internal: true                           # 内部网络（无外部访问）
    driver_opts:
      com.docker.network.bridge.name: docker-mon-br0  # 网桥名称
      com.docker.network.bridge.enable_icc: "true"   # 启用容器间通信
    ipam:
      driver: default
      config:
        - subnet: 172.23.0.0/16              # 子网范围
          gateway: 172.23.0.1                # 网关地址
          ip_range: 172.23.1.0/24            # IP 分配范围
    labels:
      com.docker.network.description: "Monitoring services network"   # 网络描述
      com.docker.network.environment: "production"                  # 环境标签

# 网络使用说明：
# 1. database-network: 专用于数据库服务（MySQL、Redis、MongoDB、PostgreSQL）
# 2. web-network: 用于 Web 服务和反向代理（Nginx、Apache）
# 3. app-network: 用于应用程序服务（API、微服务）
# 4. monitoring-network: 用于监控和日志服务（Prometheus、Grafana、ELK）
# 
# 使用示例：
# docker network create -f docker-networks.yml database-network
# docker run --network database-network --name mysql mysql:8.0
EOF

    print_success "Docker 网络配置生成完成: $network_config_dir/docker-networks.yml"
}

# 生成备份脚本
generate_backup_scripts() {
    print_title "生成备份脚本"
    
    local scripts_dir="$BASE_DIR/shared/scripts"
    
    # 创建完整备份脚本
    cat > "$scripts_dir/backup-all-databases.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# Docker 数据库全量备份脚本
# =============================================================================
# 功能：备份所有 Docker 数据库容器的数据
# 支持：MySQL、Redis、MongoDB、PostgreSQL
# =============================================================================

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 基础配置
readonly BASE_DIR="/opt/docker-volumes"
readonly BACKUP_DIR="$BASE_DIR/shared/backups"
readonly LOG_FILE="/var/log/docker-volumes/backup.log"
readonly DATE=$(date +%Y%m%d_%H%M%S)

# 打印信息函数
print_info() {
    echo -e "${BLUE}[信息]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1" | tee -a "$LOG_FILE"
}

# 创建备份目录
create_backup_directory() {
    local backup_subdir="$BACKUP_DIR/$DATE"
    mkdir -p "$backup_subdir"
    echo "$backup_subdir"
}

# MySQL 备份
backup_mysql() {
    print_info "开始备份 MySQL..."
    
    local backup_path="$1/mysql"
    mkdir -p "$backup_path"
    
    # 使用 mysqldump 备份所有数据库
    docker exec mysql-production mysqldump \
        --all-databases \
        --add-drop-database \
        --add-drop-table \
        --add-drop-trigger \
        --create-options \
        --disable-keys \
        --extended-insert \
        --lock-all-tables \
        --quick \
        --set-charset \
        --routines \
        --triggers \
        --single-transaction \
        --user=root \
        --password=$MYSQL_ROOT_PASSWORD \
        > "$backup_path/all-databases.sql" 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        # 压缩备份文件
        gzip "$backup_path/all-databases.sql"
        print_success "MySQL 备份完成: $backup_path/all-databases.sql.gz"
    else
        print_error "MySQL 备份失败"
        return 1
    fi
}

# Redis 备份
backup_redis() {
    print_info "开始备份 Redis..."
    
    local backup_path="$1/redis"
    mkdir -p "$backup_path"
    
    # 创建 Redis 备份
    docker exec redis-production redis-cli BGSAVE 2>> "$LOG_FILE"
    
    # 等待备份完成
    sleep 5
    
    # 复制 dump.rdb 文件
    docker cp redis-production:/data/dump.rdb "$backup_path/dump.rdb" 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        # 压缩备份文件
        gzip "$backup_path/dump.rdb"
        print_success "Redis 备份完成: $backup_path/dump.rdb.gz"
    else
        print_error "Redis 备份失败"
        return 1
    fi
}

# MongoDB 备份
backup_mongodb() {
    print_info "开始备份 MongoDB..."
    
    local backup_path="$1/mongodb"
    mkdir -p "$backup_path"
    
    # 使用 mongodump 备份所有数据库
    docker exec mongodb-production mongodump \
        --username=$MONGO_ROOT_USERNAME \
        --password=$MONGO_ROOT_PASSWORD \
        --authenticationDatabase=admin \
        --out=/tmp/mongodb_backup \
        --gzip \
        2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        # 复制备份文件
        docker cp mongodb-production:/tmp/mongodb_backup "$backup_path/" 2>> "$LOG_FILE"
        
        # 压缩备份目录
        tar -czf "$backup_path/mongodb_backup.tar.gz" -C "$backup_path" mongodb_backup
        rm -rf "$backup_path/mongodb_backup"
        
        print_success "MongoDB 备份完成: $backup_path/mongodb_backup.tar.gz"
    else
        print_error "MongoDB 备份失败"
        return 1
    fi
}

# PostgreSQL 备份
backup_postgres() {
    print_info "开始备份 PostgreSQL..."
    
    local backup_path="$1/postgres"
    mkdir -p "$backup_path"
    
    # 使用 pg_dumpall 备份所有数据库
    docker exec postgres-production pg_dumpall \
        --username=$POSTGRES_USER \
        --clean \
        --if-exists \
        --verbose \
        > "$backup_path/all-databases.sql" 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        # 压缩备份文件
        gzip "$backup_path/all-databases.sql"
        print_success "PostgreSQL 备份完成: $backup_path/all-databases.sql.gz"
    else
        print_error "PostgreSQL 备份失败"
        return 1
    fi
}

# 配置文件备份
backup_configs() {
    print_info "开始备份配置文件..."
    
    local backup_path="$1/configs"
    mkdir -p "$backup_path"
    
    # 备份所有服务的配置文件
    tar -czf "$backup_path/docker-volumes-configs.tar.gz" \
        -C "$BASE_DIR" \
        --exclude='data' \
        --exclude='logs' \
        --exclude='backup' \
        . 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "配置文件备份完成: $backup_path/docker-volumes-configs.tar.gz"
    else
        print_error "配置文件备份失败"
        return 1
    fi
}

# 创建备份清单
create_backup_manifest() {
    local backup_path="$1"
    local manifest_file="$backup_path/backup_manifest.txt"
    
    cat > "$manifest_file" << EOF
Docker 数据库备份清单
========================
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份目录: $backup_path
主机名: $(hostname)
系统版本: $(uname -a)
Docker 版本: $(docker --version)

备份内容:
- MySQL: 完整数据库备份
- Redis: 数据快照备份
- MongoDB: 完整数据库备份
- PostgreSQL: 完整数据库备份
- 配置文件: 所有服务配置

恢复说明:
1. 解压相应的备份文件
2. 使用对应的数据库工具导入数据
3. 验证数据完整性

注意事项:
- 请定期测试备份恢复
- 备份文件包含敏感数据，请妥善保管
- 建议将备份文件存储在多个位置

EOF

    print_info "备份清单已创建: $manifest_file"
}

# 清理旧备份
cleanup_old_backups() {
    print_info "清理旧备份文件..."
    
    # 删除 7 天前的备份
    find "$BACKUP_DIR" -type d -name "20*" -mtime +7 -exec rm -rf {} \; 2>> "$LOG_FILE"
    
    # 保留最新的 10 个备份
    local backup_count=$(ls -1d "$BACKUP_DIR"/20* 2>/dev/null | wc -l)
    if [ "$backup_count" -gt 10 ]; then
        ls -1dt "$BACKUP_DIR"/20* | tail -n +11 | xargs rm -rf 2>> "$LOG_FILE"
    fi
    
    print_success "旧备份清理完成"
}

# 发送通知（可选）
send_notification() {
    local status="$1"
    local message="$2"
    
    # 这里可以添加邮件、短信或其他通知方式
    # 例如：mail -s "备份 $status" admin@example.com <<< "$message"
    
    print_info "通知: $message"
}

# 主函数
main() {
    print_info "开始 Docker 数据库全量备份..."
    print_info "备份时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 创建备份目录
    local backup_subdir=$(create_backup_directory)
    print_info "备份目录: $backup_subdir"
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行备份（错误不中断整体流程）
    local errors=0
    
    # MySQL 备份
    if docker ps --format "table {{.Names}}" | grep -q "mysql-production"; then
        backup_mysql "$backup_subdir" || ((errors++))
    else
        print_warning "MySQL 容器未运行，跳过备份"
    fi
    
    # Redis 备份
    if docker ps --format "table {{.Names}}" | grep -q "redis-production"; then
        backup_redis "$backup_subdir" || ((errors++))
    else
        print_warning "Redis 容器未运行，跳过备份"
    fi
    
    # MongoDB 备份
    if docker ps --format "table {{.Names}}" | grep -q "mongodb-production"; then
        backup_mongodb "$backup_subdir" || ((errors++))
    else
        print_warning "MongoDB 容器