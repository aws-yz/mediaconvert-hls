#!/bin/bash

# 配置文件占位符替换脚本
# 用于将模板文件中的占位符替换为实际配置值

set -e

# 检查必需的环境变量
if [ -z "$BUCKET_NAME" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$ROLE_NAME" ]; then
    echo "❌ 错误: 请先设置必需的环境变量"
    echo "需要设置: BUCKET_NAME, AWS_ACCOUNT_ID, ROLE_NAME"
    echo "运行: source .env"
    exit 1
fi

echo "🔧 替换配置文件中的占位符..."

# 替换MediaConvert作业配置
if [ -f "mediaconvert-job.json" ]; then
    echo "  替换 mediaconvert-job.json..."
    sed -i.bak "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" mediaconvert-job.json
    sed -i.bak "s/YOUR_INPUT_FILE/${INPUT_FILE:-4ktest.mp4}/g" mediaconvert-job.json
    sed -i.bak "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" mediaconvert-job.json
    sed -i.bak "s/YOUR_ROLE_NAME/$ROLE_NAME/g" mediaconvert-job.json
fi

# 替换简化MediaConvert配置
if [ -f "simple-mediaconvert-job.json" ]; then
    echo "  替换 simple-mediaconvert-job.json..."
    sed -i.bak "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" simple-mediaconvert-job.json
    sed -i.bak "s/YOUR_INPUT_FILE/${INPUT_FILE:-4ktest.mp4}/g" simple-mediaconvert-job.json
    sed -i.bak "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" simple-mediaconvert-job.json
    sed -i.bak "s/YOUR_ROLE_NAME/$ROLE_NAME/g" simple-mediaconvert-job.json
fi

# 替换S3存储桶策略
if [ -f "s3-bucket-policy.json" ]; then
    echo "  替换 s3-bucket-policy.json..."
    sed -i.bak "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" s3-bucket-policy.json
    sed -i.bak "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" s3-bucket-policy.json
    if [ -n "$DISTRIBUTION_ID" ]; then
        sed -i.bak "s/YOUR_DISTRIBUTION_ID/$DISTRIBUTION_ID/g" s3-bucket-policy.json
    fi
fi

# 替换权限策略
if [ -f "permissions-policy.json" ]; then
    echo "  替换 permissions-policy.json..."
    sed -i.bak "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" permissions-policy.json
fi

# 替换HLS播放器
if [ -f "enhanced-hls-player.html" ] && [ -n "$CLOUDFRONT_DOMAIN" ]; then
    echo "  替换 enhanced-hls-player.html..."
    sed -i.bak "s/YOUR_CLOUDFRONT_DOMAIN/$CLOUDFRONT_DOMAIN/g" enhanced-hls-player.html
    sed -i.bak "s/YOUR_VIDEO_NAME/${INPUT_FILE%.*}/g" enhanced-hls-player.html
fi

echo "✅ 占位符替换完成！"
echo ""
echo "💡 提示:"
echo "  - 备份文件已创建 (*.bak)"
echo "  - 如需恢复原始模板，请运行: ./restore-templates.sh"
