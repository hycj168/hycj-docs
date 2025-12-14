#!/bin/bash

# MySQL Docker 备份和恢复管理脚本
# 支持全量备份、增量备份、定时备份和恢复

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
BACKUP_DIR="/opt/mysql-docker/backup"
MYSQL_HOST="mysql"
MYSQL_PORT="3306"
MYSQL_USER="root"
RETENTION_DAYS=7
COMPRESSION_LEVEL=6

# 获取环境变量
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"
if [ -z "$MYSQL_PASSWORD" ]; then
    echo -e "${RED}错误: MYSQL_ROOT_PASSWORD 环境变量未设置${NC}"
    exit 1
fi

# 日志函数
log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1" | tee -a "${BACKUP_DIR}/backup.log"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1" | tee -a "${BACKUP_DIR}/backup.log"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING]${NC} $1" | tee -a "${BACKUP_DIR}/backup.log"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1" | tee -a "${BACKUP_DIR}/backup.log"
}

# 显示帮助信息
show_help() {
    echo "MySQL Docker 备份恢复管理脚本"
    echo
    echo "用法: $0 [选项] [命令]"
    echo
    echo "命令:"
    echo "  full-backup          执行全量备份"
    echo "  incremental-backup   执行增量备份"
    echo "  restore <文件>       恢复指定备份文件"
    echo "  list-backups         列出所有备份文件"
    echo "  cleanup              清理过期备份"
    echo "  setup-cron           设置定时备份"
    echo "  status               显示备份状态"
    echo
    echo "选项:"
    echo "  -h, --help           显示帮助信息"
    echo "  -d, --dir <目录>     备份目录 (默认: ${BACKUP_DIR})"
    echo "  -r, --retention <天> 保留天数 (默认: ${RETENTION_DAYS})"
    echo "  -v, --verbose        详细输出"
    echo
    echo "示例:"
    echo "  $0 full-backup                    # 执行全量备份"
    echo "  $0 restore backup_20251206.sql.gz  # 恢复备份"
    echo "  $0 cleanup                        # 清理过期备份"
    echo "  $0 setup-cron                   # 设置定时备份"
}

# 检查 MySQL 连接
check_mysql_connection() {
    if mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 创建备份目录
create_backup_dir() {
    if [ ! -d "${BACKUP_DIR}" ]; then
        mkdir -p "${BACKUP_DIR}"
        log_info "创建备份目录: ${BACKUP_DIR}"
    fi
}

# 全量备份
full_backup() {
    log_info "开始执行全量备份..."
    
    if ! check_mysql_connection; then
        log_error "无法连接到 MySQL 服务器"
        exit 1
    fi
    
    create_backup_dir
    
    local backup_file="full_backup_$(date +%Y%m%d_%H%M%S).sql"
    local backup_path="${BACKUP_DIR}/${backup_file}"
    
    log_info "备份文件: ${backup_file}"
    
    # 执行备份
    if mysqldump -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
        --all-databases \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --master-data=2 \
        --lock-tables=false \
        > "${backup_path}"; then
        
        # 压缩备份文件
        log_info "压缩备份文件..."
        gzip -${COMPRESSION_LEVEL} "${backup_path}"
        
        local compressed_size=$(du -h "${backup_path}.gz" | cut -f1)
        log_success "全量备份完成: ${backup_file}.gz (${compressed_size})"
        
        # 记录备份信息
        echo "$(date '+%Y-%m-%d %H:%M:%S') full ${backup_file}.gz ${compressed_size}" >> "${BACKUP_DIR}/backup_history.log"
        
    else
        log_error "全量备份失败"
        rm -f "${backup_path}"
        exit 1
    fi
}

# 增量备份
incremental_backup() {
    log_info "开始执行增量备份..."
    
    if ! check_mysql_connection; then
        log_error "无法连接到 MySQL 服务器"
        exit 1
    fi
    
    create_backup_dir
    
    # 检查是否启用了二进制日志
    local binlog_enabled=$(mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW VARIABLES LIKE 'log_bin';" | tail -1 | awk '{print $2}')
    if [ "$binlog_enabled" != "ON" ]; then
        log_error "未启用二进制日志，无法执行增量备份"
        exit 1
    fi
    
    local backup_file="incremental_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_file}"
    
    log_info "备份文件: ${backup_file}"
    
    # 获取当前二进制日志位置
    local master_status=$(mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SHOW MASTER STATUS;" | tail -1)
    local binlog_file=$(echo "$master_status" | awk '{print $1}')
    local binlog_pos=$(echo "$master_status" | awk '{print $2}')
    
    log_info "当前二进制日志: ${binlog_file}:${binlog_pos}"
    
    # 备份二进制日志
    if mysqlbinlog -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
        --read-from-remote-server \
        --raw \
        --to-last-log \
        --result-file="${backup_path}_" \
        "${binlog_file}" > /dev/null 2>&1; then
        
        # 压缩备份文件
        log_info "压缩备份文件..."
        tar -czf "${backup_path}.tar.gz" "${backup_path}_"*
        rm -f "${backup_path}_"*
        
        local compressed_size=$(du -h "${backup_path}.tar.gz" | cut -f1)
        log_success "增量备份完成: ${backup_file}.tar.gz (${compressed_size})"
        
        # 记录备份信息
        echo "$(date '+%Y-%m-%d %H:%M:%S') incremental ${backup_file}.tar.gz ${compressed_size} ${binlog_file}:${binlog_pos}" >> "${BACKUP_DIR}/backup_history.log"
        
    else
        log_error "增量备份失败"
        exit 1
    fi
}

# 恢复备份
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log_error "请指定备份文件"
        show_help
        exit 1
    fi
    
    local backup_path="${BACKUP_DIR}/${backup_file}"
    
    if [ ! -f "${backup_path}" ]; then
        log_error "备份文件不存在: ${backup_path}"
        exit 1
    fi
    
    log_info "开始恢复备份: ${backup_file}"
    
    if ! check_mysql_connection; then
        log_error "无法连接到 MySQL 服务器"
        exit 1
    fi
    
    # 确认恢复操作
    echo -e "${YELLOW}警告: 恢复操作将覆盖当前数据库！${NC}"
    read -p "确定要继续吗? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "恢复操作已取消"
        exit 0
    fi
    
    local temp_file="/tmp/restore_$(date +%s).sql"
    
    # 解压备份文件
    if [[ "${backup_file}" == *.gz ]]; then
        log_info "解压备份文件..."
        gunzip -c "${backup_path}" > "${temp_file}"
    elif [[ "${backup_file}" == *.tar.gz ]]; then
        log_error "增量备份需要使用专门的恢复程序"
        exit 1
    else
        cp "${backup_path}" "${temp_file}"
    fi
    
    # 执行恢复
    log_info "执行数据库恢复..."
    if mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" < "${temp_file}"; then
        log_success "数据库恢复完成"
        
        # 清理临时文件
        rm -f "${temp_file}"
        
        # 记录恢复信息
        echo "$(date '+%Y-%m-%d %H:%M:%S') restore ${backup_file}" >> "${BACKUP_DIR}/backup_history.log"
        
    else
        log_error "数据库恢复失败"
        rm -f "${temp_file}"
        exit 1
    fi
}

# 列出备份文件
list_backups() {
    create_backup_dir
    
    echo "备份文件列表:"
    echo "================================================================================"
    printf "%-30s %-15s %-10s %-20s\n" "文件名" "类型" "大小" "创建时间"
    echo "================================================================================"
    
    if [ -f "${BACKUP_DIR}/backup_history.log" ]; then
        while IFS=' ' read -r datetime type filename size position; do
            if [ "$type" == "full" ] || [ "$type" == "incremental" ]; then
                local file_date=$(echo "$datetime" | cut -d' ' -f1)
                local file_time=$(echo "$datetime" | cut -d' ' -f2)
                printf "%-30s %-15s %-10s %-20s\n" "$filename" "$type" "$size" "$file_date $file_time"
            fi
        done < "${BACKUP_DIR}/backup_history.log"
    else
        # 如果没有历史记录，直接扫描备份目录
        for file in "${BACKUP_DIR}"/*.sql*; do
            if [ -f "$file" ]; then
                local filename=$(basename "$file")
                local filesize=$(du -h "$file" | cut -f1)
                local filedate=$(stat -c %y "$file" | cut -d' ' -f1)
                local filetime=$(stat -c %y "$file" | cut -d' ' -f2 | cut -d'.' -f1)
                
                local backup_type="unknown"
                if [[ "$filename" == *"full_backup"* ]]; then
                    backup_type="full"
                elif [[ "$filename" == *"incremental_backup"* ]]; then
                    backup_type="incremental"
                fi
                
                printf "%-30s %-15s %-10s %-20s\n" "$filename" "$backup_type" "$filesize" "$filedate $filetime"
            fi
        done
    fi
    
    echo "================================================================================"
}

# 清理过期备份
cleanup_backups() {
    log_info "开始清理过期备份文件..."
    
    create_backup_dir
    
    local deleted_count=0
    
    # 清理备份文件
    while IFS= read -r -d '' file; do
        log_info "删除过期备份文件: $(basename "$file")"
        rm -f "$file"
        ((deleted_count++))
    done < <(find "${BACKUP_DIR}" -name "*.sql*" -type f -mtime +${RETENTION_DAYS} -print0)
    
    # 清理历史记录
    if [ -f "${BACKUP_DIR}/backup_history.log" ]; then
        local cutoff_date=$(date -d "${RETENTION_DAYS} days ago" '+%Y-%m-%d')
        sed -i "/^${cutoff_date}/d" "${BACKUP_DIR}/backup_history.log"
    fi
    
    log_success "清理完成，删除了 ${deleted_count} 个过期备份文件"
}

# 设置定时备份
setup_cron() {
    log_info "设置定时备份任务..."
    
    # 备份脚本路径
    local script_path=$(realpath "$0")
    
    # 添加定时任务
    (crontab -l 2>/dev/null; echo "0 2 * * * ${script_path} full-backup") | crontab -
    (crontab -l 2>/dev/null; echo "0 3 * * * ${script_path} cleanup") | crontab -
    
    log_success "定时备份任务设置完成"
    log_info "备份时间: 每天凌晨 2:00"
    log_info "清理时间: 每天凌晨 3:00"
    log_info "保留天数: ${RETENTION_DAYS} 天"
}

# 显示备份状态
show_status() {
    echo "MySQL 备份状态:"
    echo "================================================================================"
    
    # 检查 MySQL 连接
    if check_mysql_connection; then
        echo -e "MySQL 连接状态: ${GREEN}正常${NC}"
    else
        echo -e "MySQL 连接状态: ${RED}异常${NC}"
    fi
    
    # 备份目录状态
    if [ -d "${BACKUP_DIR}" ]; then
        local backup_count=$(find "${BACKUP_DIR}" -name "*.sql*" -type f | wc -l)
        local backup_size=$(du -sh "${BACKUP_DIR}" 2>/dev/null | cut -f1)
        echo -e "备份目录: ${BLUE}${BACKUP_DIR}${NC}"
        echo -e "备份文件数量: ${BLUE}${backup_count}${NC}"
        echo -e "备份总大小: ${BLUE}${backup_size}${NC}"
    else
        echo -e "备份目录: ${RED}不存在${NC}"
    fi
    
    # 最近备份
    if [ -f "${BACKUP_DIR}/backup_history.log" ]; then
        local recent_backup=$(tail -1 "${BACKUP_DIR}/backup_history.log" 2>/dev/null)
        if [ -n "$recent_backup" ]; then
            echo -e "最近备份: ${BLUE}${recent_backup}${NC}"
        fi
    fi
    
    # 定时任务状态
    if crontab -l 2>/dev/null | grep -q "$0"; then
        echo -e "定时备份: ${GREEN}已启用${NC}"
    else
        echo -e "定时备份: ${YELLOW}未启用${NC}"
    fi
    
    echo "================================================================================"
}

# 主函数
main() {
    local command=""
    local backup_file=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            full-backup|incremental-backup|restore|list-backups|cleanup|setup-cron|status)
                command="$1"
                shift
                if [ "$command" == "restore" ] && [ $# -gt 0 ]; then
                    backup_file="$1"
                    shift
                fi
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -r|--retention)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 执行命令
    case "$command" in
        full-backup)
            full_backup
            ;;
        incremental-backup)
            incremental_backup
            ;;
        restore)
            restore_backup "$backup_file"
            ;;
        list-backups)
            list_backups
            ;;
        cleanup)
            cleanup_backups
            ;;
        setup-cron)
            setup_cron
            ;;
        status)
            show_status
            ;;
        "")
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi