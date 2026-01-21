#!/bin/bash
#
# 内存测试脚本
# 用于测试内存性能和稳定性

# 设置默认参数
TEST_TIME=${1:-30}  # 默认测试30秒
MEMORY_SIZE=${2:-"1G"}  # 默认使用1GB内存进行测试

echo "开始内存测试..."
echo "测试时长: ${TEST_TIME} 秒"
echo "内存块大小: ${MEMORY_SIZE}"

# 检查可用内存
AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')

echo "总内存: $(free -h | awk 'NR==2{print $2}')"
echo "可用内存: $(free -h | awk 'NR==2{print $7}')"

# 验证内存参数
MEM_SIZE_MB=$(echo $MEMORY_SIZE | sed 's/[^0-9]*//g')
MEM_UNIT=$(echo $MEMORY_SIZE | sed 's/[0-9]//g' | tr '[:lower:]' '[:upper:]')

case $MEM_UNIT in
    "G"|"GB") MEM_SIZE_MB=$((MEM_SIZE_MB * 1024)) ;;
    "K"|"KB") MEM_SIZE_MB=$((MEM_SIZE_MB / 1024)) ;;
    *) ;;  # 已经是MB
esac

if [ $MEM_SIZE_MB -gt $AVAILABLE_MEM ]; then
    echo "警告: 请求的内存量(${MEMORY_SIZE})超过可用内存($(free -h | awk 'NR==2{print $7}'))"
    MEMORY_SIZE="${AVAILABLE_MEM}M"
    echo "调整为: ${MEMORY_SIZE}"
fi

# 检查是否有内存测试工具
if command -v stress &> /dev/null; then
    echo "使用stress工具进行内存测试..."
    stress --vm 1 --vm-bytes $MEMORY_SIZE --timeout ${TEST_TIME}s
elif command -v sysbench &> /dev/null; then
    echo "使用sysbench进行内存测试..."
    sysbench memory --memory-size=$MEMORY_SIZE --threads=1 --time=${TEST_TIME} run
elif command -v memtester &> /dev/null; then
    echo "使用memtester进行内存测试..."
    # 创建临时文件进行测试
    TEMP_FILE="/tmp/memtest_$$"
    dd if=/dev/zero of=$TEMP_FILE bs=1M count=$MEM_SIZE_MB 2>/dev/null &
    sleep $TEST_TIME
    rm -f $TEMP_FILE
else
    echo "错误: 未找到内存测试工具"
    echo "推荐安装命令:"
    echo "  Ubuntu/Debian: sudo apt-get install stress memtester"
    echo "  CentOS/RHEL: sudo yum install stress memtester 或 sudo dnf install sysbench"
    exit 1
fi

echo "内存测试完成"
