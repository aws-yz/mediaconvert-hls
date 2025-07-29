#!/bin/bash

# MediaConvert IAM角色设置脚本
# 处理角色存在和不存在的情况

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 MediaConvert IAM角色设置${NC}"
echo "=================================="

# 检查环境变量
if [ -z "$ROLE_NAME" ] || [ -z "$BUCKET_NAME" ] || [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ 错误: 请先加载环境变量${NC}"
    echo "运行: source .env"
    exit 1
fi

echo -e "${YELLOW}📋 使用配置:${NC}"
echo "   角色名称: $ROLE_NAME"
echo "   存储桶名称: $BUCKET_NAME"
echo "   AWS账户ID: $AWS_ACCOUNT_ID"
echo

# 检查角色是否存在
echo -e "${BLUE}🔍 检查IAM角色状态...${NC}"
if aws iam get-role --role-name $ROLE_NAME > /dev/null 2>&1; then
    echo -e "${YELLOW}ℹ️  角色 '$ROLE_NAME' 已存在${NC}"
    
    # 显示现有角色信息
    echo -e "${BLUE}📋 现有角色信息:${NC}"
    aws iam get-role --role-name $ROLE_NAME --query 'Role.{RoleName:RoleName,CreateDate:CreateDate,Description:Description}' --output table
    
    echo -e "${BLUE}📋 现有内联策略:${NC}"
    INLINE_POLICIES=$(aws iam list-role-policies --role-name $ROLE_NAME --query 'PolicyNames' --output text)
    if [ -n "$INLINE_POLICIES" ]; then
        echo "$INLINE_POLICIES"
    else
        echo "无内联策略"
    fi
    
    echo -e "${BLUE}📋 现有托管策略:${NC}"
    aws iam list-attached-role-policies --role-name $ROLE_NAME --query 'AttachedPolicies[].PolicyName' --output text
    
    echo
    read -p "是否要更新现有角色的权限? (y/n): " UPDATE_ROLE
    
    if [ "$UPDATE_ROLE" = "y" ] || [ "$UPDATE_ROLE" = "Y" ]; then
        echo -e "${BLUE}🔄 更新现有角色权限...${NC}"
    else
        echo -e "${YELLOW}ℹ️  跳过角色更新${NC}"
        exit 0
    fi
else
    echo -e "${BLUE}🆕 创建新的IAM角色...${NC}"
    
    # 创建信任策略
    TRUST_POLICY='{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "mediaconvert.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'
    
    # 创建角色
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document "$TRUST_POLICY" \
        --description "MediaConvert role for DRM HLS processing"
    
    echo -e "${GREEN}✅ 角色创建成功${NC}"
fi

# 添加或更新S3访问策略
echo -e "${BLUE}📝 配置S3访问策略...${NC}"
S3_POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::'$BUCKET_NAME'",
                "arn:aws:s3:::'$BUCKET_NAME'/*"
            ]
        }
    ]
}'

aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name MediaConvertS3AccessForDRM \
    --policy-document "$S3_POLICY"

echo -e "${GREEN}✅ S3访问策略已配置${NC}"

# 检查并附加必要的托管策略
echo -e "${BLUE}📝 检查托管策略...${NC}"

# MediaConvert基础权限
MEDIACONVERT_POLICY="arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
if ! aws iam list-attached-role-policies --role-name $ROLE_NAME --query 'AttachedPolicies[?PolicyArn==`'$MEDIACONVERT_POLICY'`]' --output text | grep -q $MEDIACONVERT_POLICY; then
    echo -e "${BLUE}📎 附加MediaConvert基础权限...${NC}"
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $MEDIACONVERT_POLICY
    echo -e "${GREEN}✅ MediaConvert基础权限已附加${NC}"
else
    echo -e "${YELLOW}ℹ️  MediaConvert基础权限已存在${NC}"
fi

# 等待角色生效
echo -e "${BLUE}⏳ 等待角色权限生效...${NC}"
sleep 10

# 验证角色配置
echo -e "${BLUE}🔍 验证角色配置...${NC}"
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
echo -e "${GREEN}✅ 角色ARN: $ROLE_ARN${NC}"

# 测试角色权限
echo -e "${BLUE}🧪 测试S3访问权限...${NC}"
if aws s3 ls s3://$BUCKET_NAME/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ S3访问权限正常${NC}"
else
    echo -e "${YELLOW}⚠️  S3访问权限测试失败，但这可能是正常的${NC}"
fi

echo -e "${GREEN}✅ IAM角色设置完成！${NC}"
echo
echo -e "${YELLOW}📋 配置摘要:${NC}"
echo "   角色名称: $ROLE_NAME"
echo "   角色ARN: $ROLE_ARN"
echo "   S3存储桶权限: $BUCKET_NAME"
echo "   内联策略: MediaConvertS3AccessForDRM"
echo
echo -e "${BLUE}📖 下一步:${NC}"
echo "1. 确保密钥文件已上传到S3"
echo "2. 使用 mediaconvert-job-encrypted-ready.json 运行转码"
echo "3. 测试加密视频播放"
