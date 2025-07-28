#!/bin/bash

# MediaConvert项目配置设置脚本
# 用法: ./setup-config.sh [--non-interactive]

set -e

CONFIG_FILE=".env"
NON_INTERACTIVE=false

# 检查命令行参数
if [ "$1" = "--non-interactive" ] || [ "$1" = "-n" ]; then
    NON_INTERACTIVE=true
fi

echo "🔧 MediaConvert项目配置设置"
echo "================================"

# 检查是否存在配置文件
if [ -f "$CONFIG_FILE" ]; then
    echo "发现现有配置文件: $CONFIG_FILE"
    if [ "$NON_INTERACTIVE" = "false" ]; then
        echo "是否要加载现有配置? (y/n)"
        read -r load_existing
        if [ "$load_existing" = "y" ] || [ "$load_existing" = "Y" ]; then
            source "$CONFIG_FILE"
            echo "✅ 已加载现有配置"
        fi
    else
        source "$CONFIG_FILE"
        echo "✅ 已加载现有配置 (非交互模式)"
    fi
fi

# 获取AWS账户ID
echo ""
echo "📋 获取AWS账户信息..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -n "$AWS_ACCOUNT_ID" ]; then
    echo "✅ AWS账户ID: $AWS_ACCOUNT_ID"
else
    echo "❌ 无法获取AWS账户ID，请检查AWS凭证配置"
    exit 1
fi

# 设置配置参数
echo ""
echo "🎯 配置项目参数"
echo "==============="

if [ "$NON_INTERACTIVE" = "false" ]; then
    # 交互式模式
    
    # S3存储桶名称
    echo ""
    echo "1. S3存储桶名称"
    echo "   当前值: ${BUCKET_NAME:-未设置}"
    echo "   请输入S3存储桶名称 (留空使用默认值 'wyz-mediaconvert-bucket-virginia'):"
    read -r new_bucket_name
    BUCKET_NAME="${new_bucket_name:-${BUCKET_NAME:-wyz-mediaconvert-bucket-virginia}}"

    # 输入文件名
    echo ""
    echo "2. 输入视频文件名"
    echo "   当前值: ${INPUT_FILE:-未设置}"
    echo "   请输入输入文件名 (留空使用默认值 '4ktest.mp4'):"
    read -r new_input_file
    INPUT_FILE="${new_input_file:-${INPUT_FILE:-4ktest.mp4}}"

    # AWS区域
    echo ""
    echo "3. AWS区域"
    echo "   当前值: ${AWS_REGION:-未设置}"
    echo "   请输入AWS区域 (留空使用默认值 'us-east-1'):"
    read -r new_region
    AWS_REGION="${new_region:-${AWS_REGION:-us-east-1}}"

    # IAM角色名称
    echo ""
    echo "4. IAM角色名称"
    echo "   当前值: ${ROLE_NAME:-未设置}"
    echo "   请输入IAM角色名称 (留空使用默认值 'MediaConvertRole'):"
    read -r new_role_name
    ROLE_NAME="${new_role_name:-${ROLE_NAME:-MediaConvertRole}}"

    # 项目名称
    echo ""
    echo "5. 项目名称"
    echo "   当前值: ${PROJECT_NAME:-未设置}"
    echo "   请输入项目名称 (留空使用默认值 'mediaconvert-hls'):"
    read -r new_project_name
    PROJECT_NAME="${new_project_name:-${PROJECT_NAME:-mediaconvert-hls}}"
    
else
    # 非交互式模式 - 使用默认值或现有值
    echo "使用非交互式模式，应用默认配置..."
    BUCKET_NAME="${BUCKET_NAME:-wyz-mediaconvert-bucket-virginia}"
    INPUT_FILE="${INPUT_FILE:-4ktest.mp4}"
    AWS_REGION="${AWS_REGION:-us-east-1}"
    ROLE_NAME="${ROLE_NAME:-MediaConvertRole}"
    PROJECT_NAME="${PROJECT_NAME:-mediaconvert-hls}"
fi

# CloudFront配置（如果已存在）
if [ -n "$DISTRIBUTION_ID" ]; then
    echo ""
    echo "6. CloudFront配置 (现有)"
    echo "   分发ID: $DISTRIBUTION_ID"
    echo "   域名: $CLOUDFRONT_DOMAIN"
    echo "   OAC ID: $OAC_ID"
fi

# 保存配置到文件
echo ""
echo "💾 保存配置到 $CONFIG_FILE..."

cat > "$CONFIG_FILE" << EOF
# MediaConvert项目配置文件
# 由 setup-config.sh 生成于 $(date)

# 基础配置
export BUCKET_NAME="$BUCKET_NAME"
export INPUT_FILE="$INPUT_FILE"
export AWS_REGION="$AWS_REGION"
export ROLE_NAME="$ROLE_NAME"
export PROJECT_NAME="$PROJECT_NAME"
export AWS_ACCOUNT_ID="$AWS_ACCOUNT_ID"

# CloudFront配置 (部署后更新)
export DISTRIBUTION_ID="${DISTRIBUTION_ID:-}"
export CLOUDFRONT_DOMAIN="${CLOUDFRONT_DOMAIN:-}"
export OAC_ID="${OAC_ID:-}"

# 使用说明:
# 1. 加载配置: source .env
# 2. 运行转换: ./convert-to-hls.sh
# 3. 管理CloudFront: ./manage-cloudfront.sh
EOF

echo "✅ 配置已保存到 $CONFIG_FILE"

# 显示配置摘要
echo ""
echo "📋 配置摘要"
echo "==========="
echo "存储桶名称: $BUCKET_NAME"
echo "输入文件: $INPUT_FILE"
echo "AWS区域: $AWS_REGION"
echo "IAM角色: $ROLE_NAME"
echo "项目名称: $PROJECT_NAME"
echo "AWS账户ID: $AWS_ACCOUNT_ID"

# 提供使用指导
echo ""
echo "🚀 下一步操作"
echo "============="
echo "1. 加载配置环境变量:"
echo "   source $CONFIG_FILE"
echo ""
echo "2. 验证配置:"
echo "   ./verify-config.sh"
echo ""
echo "3. 运行MediaConvert转换:"
echo "   ./convert-to-hls.sh"
echo ""
echo "4. 设置CloudFront分发:"
echo "   # 参考 CloudFront-HLS-Setup-Guide.md"
echo ""
echo "5. 管理CloudFront:"
echo "   ./manage-cloudfront.sh"

# 询问是否立即加载配置（仅交互模式）
if [ "$NON_INTERACTIVE" = "false" ]; then
    echo ""
    echo "是否要立即加载配置到当前shell? (y/n)"
    read -r load_now
    if [ "$load_now" = "y" ] || [ "$load_now" = "Y" ]; then
        source "$CONFIG_FILE"
        echo "✅ 配置已加载到当前shell"
        echo "现在可以直接运行脚本，例如: ./convert-to-hls.sh"
    fi
else
    echo ""
    echo "💡 提示: 运行 'source $CONFIG_FILE' 来加载配置到当前shell"
fi

echo ""
echo "🎉 配置设置完成！"
