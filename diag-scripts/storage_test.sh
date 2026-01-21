#!/bin/bash
#
# 存储/磁盘测试脚本
# 用于测试磁盘性能和健康状况

# 设置默认参数
TEST_DIR=${1:-"/tmp"}  # 默认测试目录
TEST_SIZE=${2:-"1G"}   # 默认测试文件大小1GB
BLOCK_SIZE=${3:-"1M"}  # 默认块大小1MB

echo "开始存储测试..."
echo "测试目录: ${TEST_DIR}"
echo "测试大小: ${TEST_SIZE}"
echo "块大小: ${BLOCK_SIZE}"

# 检查测试目录是否存在
if [ ! -d "$TEST_DIR" ]; then
    echo "错误: 目录 $TEST_DIR 不存在"
    exit 1
fi

# 检查磁盘空间
DF_OUTPUT=$(df -h "$TEST_DIR")
AVAIL_SPACE=$(df "$TEST_DIR" | awk 'NR==2 {print $4}')
NEEDED_SPACE=$(echo $TEST_SIZE | sed 's/[^0-9]*//g')

if [[ $TEST_SIZE == *"G"* ]] || [[ $TEST_SIZE == *"g"* ]]; then
    NEEDED_SPACE=$((NEEDED_SPACE * 1024 * 1024))  # GB to KB
elif [[ $TEST_SIZE == *"M"* ]] || [[ $TEST_SIZE == *"m"* ]]; then
    NEEDED_SPACE=$((NEEDED_SPACE * 1024))  # MB to KB
fi

if [ $NEEDED_SPACE -gt $AVAIL_SPACE ]; then
    echo "错误: 可用空间不足。需要: $((NEEDED_SPACE/1024/1024))GB, 可用: $((AVAIL_SPACE/1024/1024))GB"
    exit 1
fi

echo "=== 磁盘空间信息 ==="
df -h "$TEST_DIR"

echo "=== 磁盘性能测试 ==="

# 测试写入性能
TEST_FILE="$TEST_DIR/storage_test_$$.dat"
echo "测试写入性能..."

START_TIME=$(date +%s.%N)
dd if=/dev/zero of="$TEST_FILE" bs=$BLOCK_SIZE count=$(echo $TEST_SIZE | sed 's/[^0-9]*//g') 2>/dev/null
END_TIME=$(date +%s.%N)

WRITE_DURATION=$(echo "$END_TIME - $START_TIME" | bc)
WRITE_SIZE=$(echo $TEST_SIZE | sed 's/[^0-9]*//g')
if [[ $TEST_SIZE == *"G"* ]] || [[ $TEST_SIZE == *"g"* ]]; then
    WRITE_SIZE=$(echo "$WRITE_SIZE * 1024" | bc)
fi

WRITE_SPEED=$(echo "scale=2; $WRITE_SIZE / $WRITE_DURATION" | bc)
echo "写入速度: ${WRITE_SPEED} MB/s (${TEST_SIZE} in ${WRITE_DURATION}s)"

# 测试读取性能
echo "测试读取性能..."

# 同步缓存
sync

START_TIME=$(date +%s.%N)
dd if="$TEST_FILE" of=/dev/null bs=$BLOCK_SIZE 2>/dev/null
END_TIME=$(date +%s.%N)

READ_DURATION=$(echo "$END_TIME - $START_TIME" | bc)
READ_SPEED=$(echo "scale=2; $WRITE_SIZE / $READ_DURATION" | bc)
echo "读取速度: ${READ_SPEED} MB/s (${TEST_SIZE} in ${READ_DURATION}s)"

# 清理测试文件
rm -f "$TEST_FILE"

# 检查磁盘错误（如果可用）
echo "=== 磁盘健康检查 ==="

# 获取测试目录所在设备
DEVICE=$(df "$TEST_DIR" | tail -1 | awk '{print $1}')

# 如果有smartctl，检查SMART状态
if command -v smartctl &> /dev/null; then
    echo "检查磁盘SMART状态..."
    smartctl -H "$DEVICE" 2>/dev/null || echo "无法获取SMART信息"
else
    echo "未安装smartctl，跳过SMART检查。安装命令: sudo apt-get install smartmontools"
fi

# 显示I/O统计
echo "=== I/O 统计 ==="
if command -v iostat &> /dev/null; then
    iostat -x 1 2 | tail -10
else
    echo "未安装iostat，显示基本磁盘使用情况..."
    cat /proc/diskstats | grep -E "(sd|hd|xvd|nvme)" | head -5
fi

echo "存储测试完成"
