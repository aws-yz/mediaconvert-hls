#!/bin/bash

# MediaConvert标准HLS完整部署脚本
# 执行标准HLS转码（无DRM加密）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 MediaConvert标准HLS完整部署${NC}"
echo "========================================"
echo

# 检查必需文件
REQUIRED_FILES=(".env" "mediaconvert-job-template.json")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ 错误: 缺少必需文件 $file${NC}"
        if [ "$file" = ".env" ]; then
            echo "请先运行: ./setup-config.sh"
        fi
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

# 步骤3: 配置IAM角色
echo -e "${BLUE}🔐 步骤3: 配置IAM角色${NC}"
echo "y" | ./setup-iam-role.sh
echo -e "${GREEN}✅ IAM角色配置完成${NC}"
echo

# 步骤4: 生成标准转码配置
echo -e "${BLUE}📝 步骤4: 生成标准转码配置${NC}"

# 复制模板文件
cp mediaconvert-job-template.json mediaconvert-job-standard-ready.json

# 替换占位符
sed -i '' "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" mediaconvert-job-standard-ready.json
sed -i '' "s/YOUR_INPUT_FILE/$INPUT_FILE/g" mediaconvert-job-standard-ready.json
sed -i '' "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" mediaconvert-job-standard-ready.json
sed -i '' "s/YOUR_ROLE_NAME/$ROLE_NAME/g" mediaconvert-job-standard-ready.json

# 验证JSON格式
if jq . mediaconvert-job-standard-ready.json > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 标准转码配置生成完成${NC}"
else
    echo -e "${RED}❌ JSON格式错误，请检查配置文件${NC}"
    exit 1
fi
echo

# 步骤5: 执行MediaConvert转码
echo -e "${BLUE}🎬 步骤5: 执行MediaConvert转码${NC}"
ENDPOINT=$(aws mediaconvert describe-endpoints --query 'Endpoints[0].Url' --output text --region $AWS_REGION)
echo "MediaConvert端点: $ENDPOINT"

JOB_RESULT=$(aws mediaconvert create-job \
    --endpoint-url $ENDPOINT \
    --region $AWS_REGION \
    --cli-input-json file://mediaconvert-job-standard-ready.json)

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

# 步骤6: 验证输出
echo -e "${BLUE}🧪 步骤6: 验证输出${NC}"

# 检查输出文件
echo -e "${BLUE}📁 检查输出文件...${NC}"
aws s3 ls s3://$BUCKET_NAME/output/hls/ --recursive --human-readable

# 获取播放列表URL
PLAYLIST_URL="s3://$BUCKET_NAME/output/hls/$INPUT_FILE.m3u8"
echo -e "${BLUE}🎵 播放列表位置...${NC}"
echo "   S3位置: $PLAYLIST_URL"

echo
echo -e "${PURPLE}🎉 标准HLS部署完成！${NC}"
echo "========================================"
echo
echo -e "${YELLOW}📋 部署摘要:${NC}"
echo "   存储桶: $BUCKET_NAME"
echo "   作业ID: $JOB_ID"
echo "   转码类型: 标准HLS（无加密）"
echo
echo -e "${BLUE}🎬 播放文件:${NC}"
echo "   主播放列表: s3://$BUCKET_NAME/output/hls/$INPUT_FILE.m3u8"
echo "   1080p: s3://$BUCKET_NAME/output/hls/${INPUT_FILE%.*}_1080p.m3u8"
echo "   720p: s3://$BUCKET_NAME/output/hls/${INPUT_FILE%.*}_720p.m3u8"
echo "   360p: s3://$BUCKET_NAME/output/hls/${INPUT_FILE%.*}_360p.m3u8"
echo
echo -e "${GREEN}✅ 标准HLS视频转码部署成功！${NC}"
echo
echo -e "${YELLOW}💡 下一步选项:${NC}"
echo "1. 如需CDN分发，可运行: ./create-cloudfront.sh"
echo "2. 如需DRM加密，可运行: ./deploy-drm-complete.sh"
echo "3. 使用支持HLS的播放器测试视频播放"
echo "4. 生产环境建议配置CloudFront进行全球分发"
