#!/bin/bash

# 预提交检查脚本
# 确保代码库准备好提交到远程仓库

set -e

echo "🔍 执行预提交检查..."

# 检查是否有敏感信息
echo "📋 检查敏感信息..."
SENSITIVE_PATTERNS=(
    "533267335205"  # AWS账户ID
    "wyz-mediaconvert"  # 个人存储桶名称
    "d3pi2t3o7hfx4l"  # CloudFront域名
    "E20OAT6Y1OHR01"  # Distribution ID
    "E1O5EXLRP0AQOM"  # OAC ID
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -r "$pattern" --exclude-dir=.git --exclude-dir=backup --exclude="*.mp4" --exclude="pre-commit-check.sh" . >/dev/null 2>&1; then
        echo "❌ 发现敏感信息: $pattern"
        echo "请移除所有硬编码的敏感信息"
        exit 1
    fi
done

# 检查.env文件是否被忽略
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
    echo "❌ .env文件不应该被提交到仓库"
    exit 1
fi

# 检查keys目录是否被忽略
if git ls-files --error-unmatch keys/ >/dev/null 2>&1; then
    echo "❌ keys/目录不应该被提交到仓库"
    exit 1
fi

# 检查脚本权限
echo "📋 检查脚本权限..."
find . -name "*.sh" -not -path "./.git/*" -not -path "./backup/*" | while read script; do
    if [ ! -x "$script" ]; then
        echo "❌ 脚本缺少执行权限: $script"
        exit 1
    fi
done

# 检查JSON文件格式
echo "📋 检查JSON文件格式..."
find . -name "*.json" -not -path "./.git/*" -not -path "./backup/*" | while read json_file; do
    if ! jq . "$json_file" >/dev/null 2>&1; then
        echo "❌ JSON格式错误: $json_file"
        exit 1
    fi
done

echo "✅ 预提交检查通过！"
echo "🚀 代码库已准备好提交到远程仓库"
