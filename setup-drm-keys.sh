#!/bin/bash

# MediaConvert DRM密钥设置脚本（修复版）
# 修复了CloudFront域名依赖问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 MediaConvert DRM密钥设置${NC}"
echo "=================================="

# 检查环境变量
if [ -z "$CLOUDFRONT_DOMAIN" ]; then
    echo -e "${RED}❌ 错误: CloudFront域名未设置${NC}"
    echo "请先运行: ./create-cloudfront.sh"
    echo "然后重新加载环境变量: source .env"
    exit 1
fi

if [ -z "$BUCKET_NAME" ] || [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ 错误: 请先加载环境变量${NC}"
    echo "运行: source .env"
    exit 1
fi

echo -e "${YELLOW}📋 使用配置:${NC}"
echo "   CloudFront域名: $CLOUDFRONT_DOMAIN"
echo "   存储桶名称: $BUCKET_NAME"
echo "   AWS区域: $AWS_REGION"
echo

# 密钥配置选项
echo -e "${BLUE}📋 密钥配置选项:${NC}"
echo "1. 生成固定密钥（简单，适合测试）"
echo "2. 生成时间相关密钥（中等安全）"
echo "3. 生成用户相关密钥（高安全，需要认证系统）"
echo

read -p "请选择密钥类型 (1-3): " KEY_TYPE

# 创建keys目录
mkdir -p keys

case $KEY_TYPE in
    1)
        echo -e "${BLUE}🔑 生成固定密钥...${NC}"
        # 生成16字节随机密钥
        openssl rand -hex 16 > keys/static.key
        openssl rand 16 > keys/encryption.key
        
        STATIC_KEY=$(cat keys/static.key)
        KEY_URL="https://$CLOUDFRONT_DOMAIN/keys/encryption.key"
        
        echo -e "${GREEN}✅ 固定密钥生成完成${NC}"
        ;;
    2)
        echo -e "${BLUE}🔑 生成时间相关密钥...${NC}"
        # 基于时间戳生成密钥
        TIMESTAMP=$(date +%s)
        echo -n "${TIMESTAMP}$(openssl rand -hex 8)" | openssl dgst -sha256 -binary | head -c 16 | xxd -p > keys/static.key
        openssl rand 16 > keys/encryption.key
        
        STATIC_KEY=$(cat keys/static.key)
        KEY_URL="https://$CLOUDFRONT_DOMAIN/keys/encryption.key?t=$TIMESTAMP"
        
        echo -e "${GREEN}✅ 时间相关密钥生成完成${NC}"
        ;;
    3)
        echo -e "${BLUE}🔑 生成用户相关密钥...${NC}"
        # 生成用户相关密钥（需要额外的认证逻辑）
        USER_ID="default_user"
        echo -n "${USER_ID}$(openssl rand -hex 12)" | openssl dgst -sha256 -binary | head -c 16 | xxd -p > keys/static.key
        openssl rand 16 > keys/encryption.key
        
        STATIC_KEY=$(cat keys/static.key)
        KEY_URL="https://$CLOUDFRONT_DOMAIN/keys/encryption.key?user=$USER_ID"
        
        echo -e "${GREEN}✅ 用户相关密钥生成完成${NC}"
        echo -e "${YELLOW}⚠️  注意: 生产环境需要实现用户认证逻辑${NC}"
        ;;
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

# 更新环境变量文件
echo -e "${BLUE}📝 更新环境变量...${NC}"
cat >> .env << EOF

# DRM加密配置
ENCRYPTION_KEY=$STATIC_KEY
KEY_URL=$KEY_URL
DRM_ENABLED=true
EOF

# 创建加密版本的MediaConvert配置
echo -e "${BLUE}📝 创建加密版本的MediaConvert配置...${NC}"

# 首先复制加密模板文件
cp mediaconvert-job-encrypted-template.json mediaconvert-job-encrypted-ready.json

# 替换所有占位符
sed -i '' "s/YOUR_16_BYTE_HEX_KEY/$STATIC_KEY/g" mediaconvert-job-encrypted-ready.json
sed -i '' "s|YOUR_CLOUDFRONT_DOMAIN|$CLOUDFRONT_DOMAIN|g" mediaconvert-job-encrypted-ready.json
sed -i '' "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" mediaconvert-job-encrypted-ready.json
sed -i '' "s/YOUR_INPUT_FILE/$INPUT_FILE/g" mediaconvert-job-encrypted-ready.json
sed -i '' "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" mediaconvert-job-encrypted-ready.json
sed -i '' "s/YOUR_ROLE_NAME/$ROLE_NAME/g" mediaconvert-job-encrypted-ready.json

# 移除不支持的参数
sed -i '' '/KeyRotationIntervalSeconds/d' mediaconvert-job-encrypted-ready.json

# 修复JSON语法错误
sed -i '' 's/"EncryptionMethod": "AES128",/"EncryptionMethod": "AES128"/' mediaconvert-job-encrypted-ready.json

# 验证JSON格式
if jq . mediaconvert-job-encrypted-ready.json > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 已创建 mediaconvert-job-encrypted-ready.json${NC}"
else
    echo -e "${RED}❌ JSON格式错误，请检查配置文件${NC}"
    exit 1
fi

echo -e "${GREEN}✅ DRM密钥设置完成！${NC}"
echo
echo -e "${YELLOW}📋 配置摘要:${NC}"
echo "密钥类型: $KEY_TYPE"
echo "密钥URL: $KEY_URL"
echo "密钥文件: keys/"
echo "配置文件: mediaconvert-job-encrypted-ready.json"
echo
echo -e "${BLUE}🔒 安全提醒:${NC}"
echo "1. 密钥文件包含敏感信息，请妥善保管"
echo "2. 生产环境建议使用HTTPS和认证保护密钥URL"
echo "3. 定期轮换密钥以提高安全性"
echo "4. 监控密钥访问日志，检测异常访问"
echo
echo -e "${BLUE}📖 下一步:${NC}"
echo "1. 上传密钥文件到S3: aws s3 cp keys/ s3://$BUCKET_NAME/keys/ --recursive"
echo "2. 配置IAM角色权限: ./setup-iam-role.sh"
echo "3. 使用 mediaconvert-job-encrypted-ready.json 运行加密转换"
echo "4. 测试加密视频播放"
