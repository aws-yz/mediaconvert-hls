#!/bin/bash

# MediaConvert DRM HLS完整部署脚本
# 按正确顺序执行所有部署步骤

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 MediaConvert DRM HLS完整部署${NC}"
echo "========================================"
echo

# 检查必需文件
REQUIRED_FILES=("4ktest.mp4" ".env" "mediaconvert-job-encrypted-fixed.json")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ 错误: 缺少必需文件 $file${NC}"
        exit 1
    fi
done

# 加载环境变量
echo -e "${BLUE}📋 步骤1: 加载配置${NC}"
source .env

# 验证环境变量
if [ -z "$BUCKET_NAME" ] || [ -z "$INPUT_FILE" ] || [ -z "$AWS_REGION" ]; then
    echo -e "${RED}❌ 错误: 环境变量不完整${NC}"
    echo "请运行: ./setup-config.sh"
    exit 1
fi

echo -e "${GREEN}✅ 配置加载完成${NC}"
echo "   存储桶: $BUCKET_NAME"
echo "   输入文件: $INPUT_FILE"
echo "   AWS区域: $AWS_REGION"
echo

# 步骤2: 创建S3存储桶
echo -e "${BLUE}📦 步骤2: 创建S3存储桶${NC}"
if aws s3 ls s3://$BUCKET_NAME 2>/dev/null; then
    echo -e "${YELLOW}ℹ️  存储桶已存在: $BUCKET_NAME${NC}"
else
    aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
    echo -e "${GREEN}✅ 存储桶创建成功${NC}"
fi

# 上传视频文件
echo -e "${BLUE}📤 上传视频文件...${NC}"
aws s3 cp $INPUT_FILE s3://$BUCKET_NAME/
echo -e "${GREEN}✅ 视频文件上传完成${NC}"
echo

# 步骤3: 创建CloudFront分发
echo -e "${BLUE}🌐 步骤3: 创建CloudFront分发${NC}"
if [ -z "$DISTRIBUTION_ID" ] || [ "$DISTRIBUTION_ID" = "" ]; then
    ./create-cloudfront.sh
    # 重新加载更新后的环境变量
    source .env
    echo -e "${GREEN}✅ CloudFront分发创建完成${NC}"
else
    echo -e "${YELLOW}ℹ️  CloudFront分发已存在: $DISTRIBUTION_ID${NC}"
fi
echo

# 等待CloudFront部署
echo -e "${BLUE}⏳ 等待CloudFront分发部署...${NC}"
while true; do
    STATUS=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text)
    echo "   当前状态: $STATUS"
    if [ "$STATUS" = "Deployed" ]; then
        echo -e "${GREEN}✅ CloudFront分发已部署完成${NC}"
        break
    fi
    echo "   等待30秒后重新检查..."
    sleep 30
done
echo

# 步骤4: 生成DRM密钥
echo -e "${BLUE}🔐 步骤4: 生成DRM密钥${NC}"
if [ ! -f "keys/encryption.key" ]; then
    echo "1" | ./setup-drm-keys.sh
    echo -e "${GREEN}✅ DRM密钥生成完成${NC}"
else
    echo -e "${YELLOW}ℹ️  DRM密钥已存在${NC}"
fi

# 上传密钥文件
echo -e "${BLUE}📤 上传密钥文件...${NC}"
aws s3 cp keys/ s3://$BUCKET_NAME/keys/ --recursive
echo -e "${GREEN}✅ 密钥文件上传完成${NC}"
echo

# 步骤5: 配置IAM角色
echo -e "${BLUE}🔐 步骤5: 配置IAM角色${NC}"
echo "y" | ./setup-iam-role.sh
echo -e "${GREEN}✅ IAM角色配置完成${NC}"
echo

# 步骤6: 执行MediaConvert转码
echo -e "${BLUE}🎬 步骤6: 执行MediaConvert转码${NC}"
ENDPOINT=$(aws mediaconvert describe-endpoints --query 'Endpoints[0].Url' --output text --region $AWS_REGION)
echo "MediaConvert端点: $ENDPOINT"

JOB_RESULT=$(aws mediaconvert create-job \
    --endpoint-url $ENDPOINT \
    --region $AWS_REGION \
    --cli-input-json file://mediaconvert-job-encrypted-ready.json)

JOB_ID=$(echo "$JOB_RESULT" | jq -r '.Job.Id')
echo -e "${GREEN}✅ 转码作业已提交${NC}"
echo "   作业ID: $JOB_ID"
echo

# 监控转码进度
echo -e "${BLUE}⏳ 监控转码进度...${NC}"
while true; do
    STATUS=$(aws mediaconvert get-job --endpoint-url $ENDPOINT --id $JOB_ID --query 'Job.Status' --output text)
    PROGRESS=$(aws mediaconvert get-job --endpoint-url $ENDPOINT --id $JOB_ID --query 'Job.JobPercentComplete' --output text)
    echo "   $(date): 状态=$STATUS, 进度=$PROGRESS%"
    
    if [ "$STATUS" = "COMPLETE" ]; then
        echo -e "${GREEN}✅ 转码完成！${NC}"
        break
    elif [ "$STATUS" = "ERROR" ] || [ "$STATUS" = "CANCELED" ]; then
        echo -e "${RED}❌ 转码失败: $STATUS${NC}"
        exit 1
    fi
    
    sleep 30
done
echo

# 步骤7: 验证部署
echo -e "${BLUE}🧪 步骤7: 验证部署${NC}"

# 检查输出文件
echo -e "${BLUE}📁 检查输出文件...${NC}"
aws s3 ls s3://$BUCKET_NAME/output/hls/ --recursive --human-readable

# 测试播放列表访问
echo -e "${BLUE}🎵 测试播放列表访问...${NC}"
PLAYLIST_URL="https://$CLOUDFRONT_DOMAIN/output/hls/$INPUT_FILE.m3u8"
if curl -s -I "$PLAYLIST_URL" | grep -q "200 OK"; then
    echo -e "${GREEN}✅ 播放列表可访问${NC}"
else
    echo -e "${YELLOW}⚠️  播放列表访问测试失败，可能需要等待缓存生效${NC}"
fi

# 测试密钥文件访问
echo -e "${BLUE}🔑 测试密钥文件访问...${NC}"
KEY_URL="https://$CLOUDFRONT_DOMAIN/keys/encryption.key"
if curl -s -I "$KEY_URL" | grep -q "200 OK"; then
    echo -e "${GREEN}✅ 密钥文件可访问${NC}"
else
    echo -e "${YELLOW}⚠️  密钥文件访问测试失败${NC}"
fi

# 验证加密
echo -e "${BLUE}🔒 验证加密配置...${NC}"
if curl -s "$PLAYLIST_URL" | grep -q "EXT-X-KEY"; then
    echo -e "${GREEN}✅ 检测到加密标记${NC}"
else
    echo -e "${YELLOW}⚠️  未检测到加密标记${NC}"
fi

echo
echo -e "${PURPLE}🎉 部署完成！${NC}"
echo "========================================"
echo
echo -e "${YELLOW}📋 部署摘要:${NC}"
echo "   存储桶: $BUCKET_NAME"
echo "   CloudFront域名: $CLOUDFRONT_DOMAIN"
echo "   分发ID: $DISTRIBUTION_ID"
echo "   作业ID: $JOB_ID"
echo
echo -e "${BLUE}🎬 播放URL:${NC}"
echo "   主播放列表: $PLAYLIST_URL"
echo "   本地播放器: file://$(pwd)/enhanced-hls-player.html"
echo
echo -e "${GREEN}✅ DRM加密HLS视频部署成功！${NC}"
echo
echo -e "${YELLOW}💡 提示:${NC}"
echo "1. CloudFront缓存可能需要几分钟才能完全生效"
echo "2. 使用支持HLS的播放器测试视频播放"
echo "3. 检查浏览器开发者工具确认加密密钥请求"
echo "4. 生产环境建议实施额外的密钥保护措施"
