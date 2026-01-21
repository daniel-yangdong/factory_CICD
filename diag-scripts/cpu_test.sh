#!/bin/bash
#
# CPU 测试脚本
# 用于测试 CPU 性能和稳定性

# 设置测试参数
TEST_DURATION=${1:-30}  # 默认测试30秒
THREADS=${2:-$(nproc)}  # 默认使用CPU核心数

echo "开始CPU压力测试..."
echo "测试时长: ${TEST_DURATION} 秒"
echo "线程数: ${THREADS}"

# 使用stress工具进行CPU压力测试
if command -v stress &> /dev/null; then
    echo "使用stress工具进行测试..."
    stress --cpu $THREADS --timeout ${TEST_DURATION}s
elif command -v sysbench &> /dev/null; then
    echo "使用sysbench进行测试..."
    sysbench cpu --threads=$THREADS --time=${TEST_DURATION} run
else
    echo "错误: 未找到stress或sysbench工具"
    echo "安装命令 (Ubuntu/Debian): sudo apt-get install stress"
    echo "安装命令 (CentOS/RHEL): sudo yum install stress 或 sudo dnf install sysbench"
    exit 1
fi

# 显示测试结果摘要
echo "CPU测试完成"
