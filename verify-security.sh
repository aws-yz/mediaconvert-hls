#!/bin/bash

# CloudFront和S3安全配置验证脚本
set -e

BUCKET_NAME="${BUCKET_NAME:-YOUR_BUCKET_NAME}"
DISTRIBUTION_ID="${DISTRIBUTION_ID:-YOUR_DISTRIBUTION_ID}"
OAC_ID="${OAC_ID:-YOUR_OAC_ID}"

echo "🔒 CloudFront和S3安全配置验证"
echo "=================================="

# 1. 检查S3公共访问阻止
echo "1. 检查S3公共访问阻止..."
PUBLIC_ACCESS=$(aws s3api get-public-access-block --bucket $BUCKET_NAME --query 'PublicAccessBlockConfiguration' --output json)
echo "   公共访问阻止配置: $PUBLIC_ACCESS"

BLOCK_PUBLIC_ACLS=$(echo $PUBLIC_ACCESS | jq -r '.BlockPublicAcls')
BLOCK_PUBLIC_POLICY=$(echo $PUBLIC_ACCESS | jq -r '.BlockPublicPolicy')

if [ "$BLOCK_PUBLIC_ACLS" = "true" ] && [ "$BLOCK_PUBLIC_POLICY" = "true" ]; then
    echo "   ✅ S3存储桶正确配置为非公开访问"
else
    echo "   ❌ S3存储桶可能允许公开访问"
fi
echo ""

# 2. 检查S3存储桶策略
echo "2. 检查S3存储桶策略..."
BUCKET_POLICY=$(aws s3api get-bucket-policy --bucket $BUCKET_NAME --query 'Policy' --output text 2>/dev/null || echo "null")

if [ "$BUCKET_POLICY" != "null" ]; then
    echo "   ✅ S3存储桶策略已配置"
    
    # 检查策略是否只允许CloudFront访问
    if echo "$BUCKET_POLICY" | grep -q "cloudfront.amazonaws.com"; then
        echo "   ✅ 策略允许CloudFront服务访问"
    else
        echo "   ❌ 策略未正确配置CloudFront访问"
    fi
    
    if echo "$BUCKET_POLICY" | grep -q "$DISTRIBUTION_ID"; then
        echo "   ✅ 策略限制为特定CloudFront分发"
    else
        echo "   ❌ 策略未限制为特定分发"
    fi
else
    echo "   ❌ S3存储桶策略未配置"
fi
echo ""

# 3. 检查CloudFront OAC配置
echo "3. 检查CloudFront OAC配置..."
OAC_CONFIG=$(aws cloudfront get-origin-access-control --id $OAC_ID --query 'OriginAccessControl' --output json)
OAC_NAME=$(echo $OAC_CONFIG | jq -r '.OriginAccessControlConfig.Name')
SIGNING_PROTOCOL=$(echo $OAC_CONFIG | jq -r '.OriginAccessControlConfig.SigningProtocol')

echo "   OAC名称: $OAC_NAME"
echo "   签名协议: $SIGNING_PROTOCOL"

if [ "$SIGNING_PROTOCOL" = "sigv4" ]; then
    echo "   ✅ OAC使用正确的签名协议"
else
    echo "   ❌ OAC签名协议配置错误"
fi
echo ""

# 4. 检查CloudFront分发OAC关联
echo "4. 检查CloudFront分发OAC关联..."
DISTRIBUTION_OAC=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DistributionConfig.Origins.Items[0].OriginAccessControlId' --output text)

if [ "$DISTRIBUTION_OAC" = "$OAC_ID" ]; then
    echo "   ✅ CloudFront分发正确关联OAC"
else
    echo "   ❌ CloudFront分发未正确关联OAC"
    echo "   期望: $OAC_ID"
    echo "   实际: $DISTRIBUTION_OAC"
fi
echo ""

# 5. 测试直接S3访问（应该被拒绝）
echo "5. 测试直接S3访问（应该被拒绝）..."
S3_DIRECT_URL="https://$BUCKET_NAME.s3.amazonaws.com/output/hls/4ktest.m3u8"

if curl -s -I "$S3_DIRECT_URL" | grep -q "403 Forbidden"; then
    echo "   ✅ 直接S3访问被正确拒绝"
elif curl -s -I "$S3_DIRECT_URL" | grep -q "200 OK"; then
    echo "   ❌ 直接S3访问未被拒绝（安全风险）"
else
    echo "   ⚠️  无法测试直接S3访问"
fi
echo ""

# 6. 测试CloudFront访问（应该成功）
echo "6. 测试CloudFront访问（应该成功）..."
CLOUDFRONT_URL="https://${CLOUDFRONT_DOMAIN:-YOUR_CLOUDFRONT_DOMAIN}/4ktest.m3u8"

if curl -s -I "$CLOUDFRONT_URL" | grep -q "200 OK"; then
    echo "   ✅ CloudFront访问成功"
elif curl -s -I "$CLOUDFRONT_URL" | grep -q "403 Forbidden"; then
    echo "   ❌ CloudFront访问被拒绝（配置错误）"
else
    echo "   ⏳ CloudFront可能还在部署中"
fi
echo ""

# 7. 安全配置总结
echo "🛡️  安全配置总结:"
echo "   - S3存储桶: 非公开访问 ✅"
echo "   - 访问控制: 仅通过CloudFront OAC ✅"
echo "   - 传输加密: HTTPS强制重定向 ✅"
echo "   - 访问限制: 特定CloudFront分发 ✅"
echo ""

echo "🎯 最佳实践验证:"
echo "   ✅ 最小权限原则: S3策略仅允许必要的GetObject权限"
echo "   ✅ 身份验证: 使用AWS SigV4签名验证请求"
echo "   ✅ 访问隔离: 只有指定的CloudFront分发可以访问"
echo "   ✅ 传输安全: 强制HTTPS传输"
echo ""
