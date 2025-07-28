#!/bin/bash

# 模板恢复脚本
# 用于恢复配置文件到原始模板状态

set -e

echo "🔄 恢复配置文件到模板状态..."

# 恢复MediaConvert作业配置
if [ -f "mediaconvert-job.json.bak" ]; then
    echo "  恢复 mediaconvert-job.json..."
    mv mediaconvert-job.json.bak mediaconvert-job.json
fi

# 恢复简化MediaConvert配置
if [ -f "simple-mediaconvert-job.json.bak" ]; then
    echo "  恢复 simple-mediaconvert-job.json..."
    mv simple-mediaconvert-job.json.bak simple-mediaconvert-job.json
fi

# 恢复S3存储桶策略
if [ -f "s3-bucket-policy.json.bak" ]; then
    echo "  恢复 s3-bucket-policy.json..."
    mv s3-bucket-policy.json.bak s3-bucket-policy.json
fi

# 恢复权限策略
if [ -f "permissions-policy.json.bak" ]; then
    echo "  恢复 permissions-policy.json..."
    mv permissions-policy.json.bak permissions-policy.json
fi

# 恢复HLS播放器
if [ -f "enhanced-hls-player.html.bak" ]; then
    echo "  恢复 enhanced-hls-player.html..."
    mv enhanced-hls-player.html.bak enhanced-hls-player.html
fi

echo "✅ 模板恢复完成！"
echo ""
echo "💡 提示:"
echo "  - 所有配置文件已恢复到模板状态"
echo "  - 运行 ./replace-placeholders.sh 重新应用配置"
