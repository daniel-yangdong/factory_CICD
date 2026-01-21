#!/bin/bash
#
# 网络测试脚本
# 用于测试网络连接性和性能

# 设置默认参数
TEST_HOST=${1:-"8.8.8.8"}  # 默认测试Google DNS
TEST_PORT=${2:-"53"}       # 默认测试DNS端口
TIMEOUT=${3:-10}           # 默认超时时间10秒

echo "开始网络测试..."
echo "目标主机: ${TEST_HOST}:${TEST_PORT}"
echo "超时时间: ${TIMEOUT} 秒"

# 获取网络接口信息
echo "=== 网络接口信息 ==="
ip addr show 2>/dev/null || ifconfig

# 检查网络连通性
echo "=== 连通性测试 ==="
if ping -c 3 -W $TIMEOUT $TEST_HOST &> /dev/null; then
    echo "✓ ping $TEST_HOST 成功"
else
    echo "✗ ping $TEST_HOST 失败"
fi

# 测试端口连通性
echo "=== 端口连通性测试 ==="
if command -v nc &> /dev/null; then
    if nc -z -w$TIMEOUT $TEST_HOST $TEST_PORT 2>/dev/null; then
        echo "✓ $TEST_HOST:$TEST_PORT 端口可达"
    else
        echo "✗ $TEST_HOST:$TEST_PORT 端口不可达"
    fi
elif command -v telnet &> /dev/null; then
    if timeout $TIMEOUT bash -c "</dev/tcp/$TEST_HOST/$TEST_PORT" &> /dev/null; then
        echo "✓ $TEST_HOST:$TEST_PORT 端口可达"
    else
        echo "✗ $TEST_HOST:$TEST_PORT 端口不可达"
    fi
else
    echo "! 未找到nc或telnet命令，跳过端口测试"
fi

# 测试带宽（如果有speedtest-cli）
echo "=== 带宽测试 ==="
if command -v speedtest-cli &> /dev/null; then
    echo "运行带宽测试 (可能需要几分钟)..."
    speedtest-cli --simple
elif command -v wget &> /dev/null; then
    echo "测试下载速度..."
    TEST_URL="http://cachefly.cachefly.net/10mb.test"
    START_TIME=$(date +%s)
    if timeout 30s wget -O /tmp/network_test.tmp --quiet $TEST_URL 2>/dev/null; then
        END_TIME=$(date +%s)
        ELAPSED=$((END_TIME - START_TIME))
        FILE_SIZE=$(stat -c%s /tmp/network_test.tmp 2>/dev/null || ls -l /tmp/network_test.tmp | awk '{print $5}')
        SPEED=$(($FILE_SIZE / $ELAPSED / 1024 / 1024))
        echo "下载速度: ${SPEED} MB/s (用时${ELAPSED}秒)"
        rm -f /tmp/network_test.tmp
    else
        echo "下载测试失败或超时"
    fi
else
    echo "! 未找到带宽测试工具"
fi

# 路由追踪
echo "=== 路由追踪 ==="
if command -v traceroute &> /dev/null; then
    echo "追踪到 $TEST_HOST 的路由..."
    timeout 30s traceroute -q 1 -w 3 $TEST_HOST 2>/dev/null | head -10
elif command -v tracepath &> /dev/null; then
    echo "追踪到 $TEST_HOST 的路径..."
    timeout 30s tracepath $TEST_HOST 2>/dev/null | head -10
else
    echo "! 未找到traceroute或tracepath命令"
fi

# DNS解析测试
echo "=== DNS解析测试 ==="
if command -v nslookup &> /dev/null; then
    echo "DNS解析测试: google.com"
    nslookup google.com 2>/dev/null | grep "Address" | head -5
elif command -v dig &> /dev/null; then
    echo "DNS解析测试: google.com"
    dig +short google.com 2>/dev/null | head -5
else
    echo "! 未找到nslookup或dig命令"
fi

# 显示当前网络统计
echo "=== 网络统计 ==="
netstat -i 2>/dev/null || ss -i 2>/dev/null

echo "网络测试完成"
