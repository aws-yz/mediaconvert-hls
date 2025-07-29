#!/bin/bash

# MediaConvert配置验证脚本
set -e

BUCKET_NAME="your-unique-bucket-name"
REGION="us-east-1"
ROLE_NAME="MediaConvertRole"

echo "🔍 验证MediaConvert配置..."

# 1. 检查AWS CLI配置
echo "1. 检查AWS CLI配置..."
aws sts get-caller-identity

# 2. 检查/创建S3存储桶
echo "2. 检查S3存储桶..."
if aws s3 ls s3://$BUCKET_NAME >/dev/null 2>&1; then
    echo "✅ 存储桶 $BUCKET_NAME 已存在"
else
    echo "📦 创建存储桶 $BUCKET_NAME..."
    aws s3 mb s3://$BUCKET_NAME --region $REGION
    echo "✅ 存储桶创建成功"
fi

# 3. 检查源文件
echo "3. 检查源文件..."
if [ -f "4ktest.mp4" ]; then
    echo "✅ 源文件 4ktest.mp4 存在"
    FILE_SIZE=$(ls -lh 4ktest.mp4 | awk '{print $5}')
    echo "   文件大小: $FILE_SIZE"
else
    echo "❌ 源文件 4ktest.mp4 不存在"
    exit 1
fi

# 4. 检查IAM角色
echo "4. 检查IAM角色..."
if aws iam get-role --role-name $ROLE_NAME >/dev/null 2>&1; then
    echo "✅ IAM角色 $ROLE_NAME 已存在"
else
    echo "⚠️  IAM角色 $ROLE_NAME 不存在，将在执行时创建"
fi

# 5. 检查MediaConvert端点
echo "5. 检查MediaConvert端点..."
ENDPOINT=$(aws mediaconvert describe-endpoints --region $REGION --query 'Endpoints[0].Url' --output text)
echo "✅ MediaConvert端点: $ENDPOINT"

# 6. 验证配置文件
echo "6. 验证配置文件..."
if [ -f "mediaconvert-job.json" ]; then
    echo "✅ 配置文件存在"
    # 检查配置文件中的存储桶名称
    if grep -q "your-unique-bucket-name" mediaconvert-job.json; then
        echo "✅ 配置文件中的存储桶名称正确"
    else
        echo "❌ 配置文件中的存储桶名称需要更新"
    fi
else
    echo "❌ 配置文件 mediaconvert-job.json 不存在"
    exit 1
fi

echo ""
echo "🎉 配置验证完成！"
echo "📋 配置摘要:"
echo "   存储桶: $BUCKET_NAME"
echo "   区域: $REGION"
echo "   IAM角色: $ROLE_NAME"
echo "   MediaConvert端点: $ENDPOINT"
echo ""
echo "🚀 现在可以运行 ./convert-to-hls.sh 开始转换"
