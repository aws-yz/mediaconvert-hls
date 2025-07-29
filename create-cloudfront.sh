#!/bin/bash

# CloudFront分发创建脚本
# 用于MediaConvert HLS DRM项目

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 创建CloudFront分发${NC}"
echo "================================"

# 检查环境变量
if [ -z "$BUCKET_NAME" ] || [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ 错误: 请先加载环境变量${NC}"
    echo "运行: source .env"
    exit 1
fi

echo -e "${YELLOW}📋 使用配置:${NC}"
echo "   存储桶名称: $BUCKET_NAME"
echo "   AWS区域: $AWS_REGION"
echo "   AWS账户ID: $AWS_ACCOUNT_ID"
echo "   项目名称: $PROJECT_NAME"
echo

# 步骤1: 创建Origin Access Control (OAC)
echo -e "${BLUE}🔐 步骤1: 创建Origin Access Control (OAC)${NC}"
OAC_RESULT=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config '{
        "Name": "'$PROJECT_NAME'-oac",
        "Description": "OAC for '$PROJECT_NAME' HLS distribution",
        "OriginAccessControlOriginType": "s3",
        "SigningBehavior": "always",
        "SigningProtocol": "sigv4"
    }' 2>/dev/null || echo "")

if [ -z "$OAC_RESULT" ]; then
    echo -e "${RED}❌ OAC创建失败，可能已存在${NC}"
    # 尝试查找现有OAC
    OAC_ID=$(aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[?Name=='$PROJECT_NAME-oac'].Id" --output text)
    if [ -z "$OAC_ID" ]; then
        echo -e "${RED}❌ 无法找到或创建OAC${NC}"
        exit 1
    fi
    echo -e "${YELLOW}ℹ️  使用现有OAC: $OAC_ID${NC}"
else
    OAC_ID=$(echo "$OAC_RESULT" | jq -r '.OriginAccessControl.Id')
    echo -e "${GREEN}✅ OAC创建成功: $OAC_ID${NC}"
fi

# 步骤2: 创建CloudFront分发
echo -e "${BLUE}🚀 步骤2: 创建CloudFront分发${NC}"
DISTRIBUTION_RESULT=$(aws cloudfront create-distribution \
    --distribution-config '{
        "CallerReference": "'$PROJECT_NAME'-'$(date +%s)'",
        "Comment": "'$PROJECT_NAME' HLS Distribution with DRM",
        "DefaultRootObject": "",
        "Origins": {
            "Quantity": 1,
            "Items": [
                {
                    "Id": "'$BUCKET_NAME'-origin",
                    "DomainName": "'$BUCKET_NAME'.s3.'$AWS_REGION'.amazonaws.com",
                    "OriginAccessControlId": "'$OAC_ID'",
                    "S3OriginConfig": {
                        "OriginAccessIdentity": ""
                    }
                }
            ]
        },
        "DefaultCacheBehavior": {
            "TargetOriginId": "'$BUCKET_NAME'-origin",
            "ViewerProtocolPolicy": "redirect-to-https",
            "TrustedSigners": {
                "Enabled": false,
                "Quantity": 0
            },
            "ForwardedValues": {
                "QueryString": false,
                "Cookies": {
                    "Forward": "none"
                }
            },
            "MinTTL": 0,
            "DefaultTTL": 86400,
            "MaxTTL": 31536000
        },
        "Enabled": true,
        "PriceClass": "PriceClass_All"
    }')

DISTRIBUTION_ID=$(echo "$DISTRIBUTION_RESULT" | jq -r '.Distribution.Id')
CLOUDFRONT_DOMAIN=$(echo "$DISTRIBUTION_RESULT" | jq -r '.Distribution.DomainName')

echo -e "${GREEN}✅ CloudFront分发创建成功${NC}"
echo "   分发ID: $DISTRIBUTION_ID"
echo "   域名: $CLOUDFRONT_DOMAIN"

# 步骤3: 更新环境变量文件
echo -e "${BLUE}📝 步骤3: 更新配置文件${NC}"
sed -i '' "s/export DISTRIBUTION_ID=\"\"/export DISTRIBUTION_ID=\"$DISTRIBUTION_ID\"/" .env
sed -i '' "s/export CLOUDFRONT_DOMAIN=\"\"/export CLOUDFRONT_DOMAIN=\"$CLOUDFRONT_DOMAIN\"/" .env
sed -i '' "s/export OAC_ID=\"\"/export OAC_ID=\"$OAC_ID\"/" .env

# 步骤4: 配置S3存储桶策略
echo -e "${BLUE}🔒 步骤4: 配置S3存储桶策略${NC}"
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::'$BUCKET_NAME'/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::'$AWS_ACCOUNT_ID':distribution/'$DISTRIBUTION_ID'"
                }
            }
        }
    ]
}'

# 步骤5: 配置S3 CORS
echo -e "${BLUE}🌐 步骤5: 配置S3 CORS${NC}"
aws s3api put-bucket-cors --bucket $BUCKET_NAME --cors-configuration '{
    "CORSRules": [
        {
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET", "HEAD"],
            "AllowedOrigins": ["*"],
            "ExposeHeaders": ["ETag"],
            "MaxAgeSeconds": 3000
        }
    ]
}'

echo -e "${GREEN}✅ CloudFront配置完成！${NC}"
echo
echo -e "${YELLOW}📋 配置摘要:${NC}"
echo "   分发ID: $DISTRIBUTION_ID"
echo "   域名: $CLOUDFRONT_DOMAIN"
echo "   OAC ID: $OAC_ID"
echo "   状态: 部署中（需要10-15分钟生效）"
echo
echo -e "${BLUE}🔄 下一步操作:${NC}"
echo "1. 等待CloudFront分发部署完成"
echo "2. 运行DRM密钥生成: ./setup-drm-keys.sh"
echo "3. 执行视频转码: ./convert-to-hls.sh"
echo
echo -e "${YELLOW}💡 提示: 可以运行以下命令检查部署状态:${NC}"
echo "aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text"
