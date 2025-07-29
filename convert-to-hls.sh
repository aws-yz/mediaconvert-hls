#!/bin/bash

# MediaConvert HLS转换脚本
# 将4K MP4转换为HLS格式的360p, 720p, 1080p三种分辨率

# 使用方法:
# 1. 命令行参数: ./convert-to-hls.sh [BUCKET_NAME] [INPUT_FILE] [REGION] [ROLE_NAME]
# 2. 环境变量: BUCKET_NAME=my-bucket ./convert-to-hls.sh
# 3. 默认配置: ./convert-to-hls.sh
#
# 示例:
# ./convert-to-hls.sh my-custom-bucket video.mp4 us-west-2 MyRole
# BUCKET_NAME=my-bucket INPUT_FILE=test.mp4 ./convert-to-hls.sh

set -e

# 配置变量 - 可通过环境变量或命令行参数覆盖
BUCKET_NAME="${1:-${BUCKET_NAME:-your-unique-bucket-name}}"
INPUT_FILE="${2:-${INPUT_FILE:-4ktest.mp4}}"
REGION="${3:-${REGION:-us-east-1}}"
ROLE_NAME="${4:-${ROLE_NAME:-MediaConvertRole}}"

# 显示使用的配置
echo "📋 使用配置:"
echo "   存储桶名称: $BUCKET_NAME"
echo "   输入文件: $INPUT_FILE"
echo "   AWS区域: $REGION"
echo "   IAM角色: $ROLE_NAME"
echo ""

# 参数验证
if [ -z "$BUCKET_NAME" ]; then
    echo "❌ 错误: 存储桶名称不能为空"
    echo "用法: $0 [BUCKET_NAME] [INPUT_FILE] [REGION] [ROLE_NAME]"
    echo "或设置环境变量: BUCKET_NAME, INPUT_FILE, REGION, ROLE_NAME"
    exit 1
fi

echo "开始MediaConvert HLS转换流程..."

# 1. 创建S3存储桶
echo "1. 创建S3存储桶..."
aws s3 mb s3://$BUCKET_NAME --region $REGION 2>/dev/null || echo "存储桶已存在"

# 2. 上传源文件
echo "2. 上传源文件到S3..."
aws s3 cp $INPUT_FILE s3://$BUCKET_NAME/input/$INPUT_FILE

# 3. 创建IAM角色（如果不存在）
echo "3. 检查并创建IAM角色..."
if ! aws iam get-role --role-name $ROLE_NAME >/dev/null 2>&1; then
    echo "创建IAM角色..."
    aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json
    
    echo "附加权限策略..."
    aws iam put-role-policy --role-name $ROLE_NAME --policy-name MediaConvertS3Access --policy-document file://permissions-policy.json
    
    echo "等待角色生效..."
    sleep 10
else
    echo "IAM角色已存在"
fi

# 4. 获取MediaConvert端点
echo "4. 获取MediaConvert端点..."
ENDPOINT=$(aws mediaconvert describe-endpoints --region $REGION --query 'Endpoints[0].Url' --output text)
echo "MediaConvert端点: $ENDPOINT"

# 5. 更新作业配置中的存储桶名称和角色ARN
echo "5. 更新作业配置..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"

# 替换配置文件中的占位符
sed -i.bak "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" mediaconvert-job.json
sed -i.bak "s/YOUR_INPUT_FILE/$INPUT_FILE/g" mediaconvert-job.json
sed -i.bak "s|YOUR_AWS_ACCOUNT_ID|$ACCOUNT_ID|g" mediaconvert-job.json
sed -i.bak "s|YOUR_ROLE_NAME|$ROLE_NAME|g" mediaconvert-job.json

# 6. 提交MediaConvert作业
echo "6. 提交MediaConvert作业..."
JOB_ID=$(aws mediaconvert create-job \
    --endpoint-url $ENDPOINT \
    --region $REGION \
    --cli-input-json file://mediaconvert-job.json \
    --query 'Job.Id' \
    --output text)

echo "作业已提交，作业ID: $JOB_ID"

# 7. 监控作业状态
echo "7. 监控作业状态..."
while true; do
    STATUS=$(aws mediaconvert get-job \
        --endpoint-url $ENDPOINT \
        --region $REGION \
        --id $JOB_ID \
        --query 'Job.Status' \
        --output text)
    
    echo "当前状态: $STATUS"
    
    if [ "$STATUS" = "COMPLETE" ]; then
        echo "✅ 转换完成！"
        break
    elif [ "$STATUS" = "ERROR" ]; then
        echo "❌ 转换失败！"
        aws mediaconvert get-job \
            --endpoint-url $ENDPOINT \
            --region $REGION \
            --id $JOB_ID \
            --query 'Job.ErrorMessage'
        exit 1
    fi
    
    sleep 30
done

# 8. 列出输出文件
echo "8. 输出文件列表:"
aws s3 ls s3://$BUCKET_NAME/output/hls/ --recursive

echo "🎉 HLS转换完成！"
echo "主播放列表: s3://$BUCKET_NAME/output/hls/4ktest.m3u8"
echo "各分辨率文件:"
echo "  - 360p: s3://$BUCKET_NAME/output/hls/4ktest_360p.m3u8"
echo "  - 720p: s3://$BUCKET_NAME/output/hls/4ktest_720p.m3u8"
echo "  - 1080p: s3://$BUCKET_NAME/output/hls/4ktest_1080p.m3u8"
