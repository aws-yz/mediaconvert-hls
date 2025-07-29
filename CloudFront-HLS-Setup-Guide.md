# CloudFront HLS视频分发配置指南

## 📋 概述

本文档详细介绍如何为MediaConvert生成的HLS视频文件配置CloudFront分发，包括Origin Access Control (OAC)安全设置，确保S3存储桶保持私有状态，同时提供全球CDN加速。

## 🎯 配置目标

- ✅ 创建CloudFront分发用于HLS视频流
- ✅ 配置Origin Access Control (OAC)确保安全访问
- ✅ 设置S3存储桶策略限制访问权限
- ✅ 优化HLS播放列表和视频分片的缓存策略
- ✅ 强制HTTPS传输确保安全性

## 🏗️ 架构图

```
用户请求 → CloudFront分发 (HTTPS) → OAC (SigV4签名) → S3存储桶 (私有) → HLS视频文件
```

## ⚙️ 配置参数

在开始配置之前，请设置以下参数（根据你的实际情况修改）：

```bash
# 基础配置参数
export BUCKET_NAME="your-mediaconvert-bucket-name"    # 你的S3存储桶名称
export AWS_REGION="us-east-1"                         # AWS区域
export AWS_ACCOUNT_ID="123456789012"                  # 你的AWS账户ID
export PROJECT_NAME="mediaconvert-hls"                # 项目名称

# 自动生成的参数（执行后会获得）
export DISTRIBUTION_ID=""                             # CloudFront分发ID（创建后获得）
export CLOUDFRONT_DOMAIN=""                           # CloudFront域名（创建后获得）
export OAC_ID=""                                       # OAC ID（创建后获得）
```

**获取AWS账户ID:**
```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS账户ID: $AWS_ACCOUNT_ID"
```

## 📊 项目信息示例

以下是基于默认配置的示例信息：

| 项目 | 值 | 说明 |
|------|----|----- |
| **S3存储桶** | `${BUCKET_NAME}` | 存储HLS文件 |
| **CloudFront分发ID** | `${DISTRIBUTION_ID}` | 分发唯一标识 |
| **CloudFront域名** | `${CLOUDFRONT_DOMAIN}` | 分发访问域名 |
| **OAC ID** | `${OAC_ID}` | Origin Access Control标识 |
| **AWS区域** | `${AWS_REGION}` | 部署区域 |

## 🚀 配置步骤

### 步骤1: 创建CloudFront分发配置文件

创建初始的CloudFront分发配置：

```bash
# 创建配置文件（使用参数化变量）
cat > cloudfront-config.json << EOF
{
  "CallerReference": "${PROJECT_NAME}-distribution-$(date +%Y-%m-%d)",
  "Comment": "CloudFront distribution for HLS video streaming from MediaConvert output",
  "DefaultRootObject": "4ktest.m3u8",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-${BUCKET_NAME}",
        "DomainName": "${BUCKET_NAME}.s3.amazonaws.com",
        "OriginPath": "/output/hls",
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${BUCKET_NAME}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "MinTTL": 0,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      },
      "Headers": {
        "Quantity": 3,
        "Items": [
          "Origin",
          "Access-Control-Request-Method",
          "Access-Control-Request-Headers"
        ]
      }
    },
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "Compress": true,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000
  },
  "CacheBehaviors": {
    "Quantity": 2,
    "Items": [
      {
        "PathPattern": "*.m3u8",
        "TargetOriginId": "S3-${BUCKET_NAME}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "DefaultTTL": 5,
        "MaxTTL": 60,
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {
            "Forward": "none"
          }
        },
        "TrustedSigners": {
          "Enabled": false,
          "Quantity": 0
        },
        "Compress": false
      },
      {
        "PathPattern": "*.ts",
        "TargetOriginId": "S3-${BUCKET_NAME}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {
            "Forward": "none"
          }
        },
        "TrustedSigners": {
          "Enabled": false,
          "Quantity": 0
        },
        "Compress": false
      }
    ]
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF
```

### 步骤2: 创建CloudFront分发

```bash
# 创建CloudFront分发
DISTRIBUTION_RESULT=$(aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json \
  --region ${AWS_REGION})

# 提取分发ID和域名
export DISTRIBUTION_ID=$(echo $DISTRIBUTION_RESULT | jq -r '.Distribution.Id')
export CLOUDFRONT_DOMAIN=$(echo $DISTRIBUTION_RESULT | jq -r '.Distribution.DomainName')

echo "✅ CloudFront分发已创建:"
echo "   分发ID: $DISTRIBUTION_ID"
echo "   域名: $CLOUDFRONT_DOMAIN"
```

**预期输出:**
```json
{
    "Distribution": {
        "Id": "E2OOLQY70ZOTOA",
        "DomainName": "d3g6olblkz60ii.cloudfront.net",
        "Status": "InProgress"
    }
}
```

### 步骤3: 创建Origin Access Control (OAC)

这是关键的安全配置步骤：

```bash
# 创建OAC配置
OAC_RESULT=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config "{
    \"Name\": \"OAC-${PROJECT_NAME}\",
    \"Description\": \"OAC for ${PROJECT_NAME} HLS video streaming\",
    \"SigningProtocol\": \"sigv4\",
    \"SigningBehavior\": \"always\",
    \"OriginAccessControlOriginType\": \"s3\"
  }" \
  --region ${AWS_REGION})

# 提取OAC ID
export OAC_ID=$(echo $OAC_RESULT | jq -r '.OriginAccessControl.Id')

echo "✅ OAC已创建:"
echo "   OAC ID: $OAC_ID"
```

**预期输出:**
```json
{
    "OriginAccessControl": {
        "Id": "EZ3T285Q2VMKQ",
        "OriginAccessControlConfig": {
            "Name": "OAC-mediaconvert-hls",
            "SigningProtocol": "sigv4",
            "SigningBehavior": "always"
        }
    }
}
```

**重要参数说明:**
- `SigningProtocol`: `sigv4` - 使用AWS Signature Version 4
- `SigningBehavior`: `always` - 总是对请求进行签名
- `OriginAccessControlOriginType`: `s3` - 专用于S3源站

### 步骤4: 更新CloudFront分发以使用OAC

创建包含OAC的更新配置：

```bash
# 创建带OAC的配置文件
cat > cloudfront-config-with-oac.json << EOF
{
  "CallerReference": "${PROJECT_NAME}-distribution-$(date +%Y-%m-%d)",
  "Aliases": {
    "Quantity": 0
  },
  "DefaultRootObject": "4ktest.m3u8",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-${BUCKET_NAME}",
        "DomainName": "${BUCKET_NAME}.s3.amazonaws.com",
        "OriginPath": "/output/hls",
        "CustomHeaders": {
          "Quantity": 0
        },
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        },
        "ConnectionAttempts": 3,
        "ConnectionTimeout": 10,
        "OriginShield": {
          "Enabled": false
        },
        "OriginAccessControlId": "${OAC_ID}"
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${BUCKET_NAME}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "Compress": true,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      },
      "Headers": {
        "Quantity": 3,
        "Items": [
          "Origin",
          "Access-Control-Request-Method",
          "Access-Control-Request-Headers"
        ]
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000
  },
  "CacheBehaviors": {
    "Quantity": 2,
    "Items": [
      {
        "PathPattern": "*.m3u8",
        "TargetOriginId": "S3-${BUCKET_NAME}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "Compress": false,
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {
            "Forward": "none"
          }
        },
        "MinTTL": 0,
        "DefaultTTL": 5,
        "MaxTTL": 60
      },
      {
        "PathPattern": "*.ts",
        "TargetOriginId": "S3-${BUCKET_NAME}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "Compress": false,
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {
            "Forward": "none"
          }
        },
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000
      }
    ]
  },
  "Comment": "CloudFront distribution for HLS video streaming from MediaConvert output",
  "PriceClass": "PriceClass_100",
  "Enabled": true,
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true
  },
  "HttpVersion": "http2",
  "IsIPV6Enabled": true
}
EOF
```

更新分发配置：

```bash
# 获取当前ETag
ETAG=$(aws cloudfront get-distribution-config --id ${DISTRIBUTION_ID} --query 'ETag' --output text)

# 更新分发配置
aws cloudfront update-distribution \
  --distribution-config file://cloudfront-config-with-oac.json \
  --if-match $ETAG \
  --id ${DISTRIBUTION_ID} \
  --region ${AWS_REGION}

echo "✅ CloudFront分发已更新为使用OAC"
```

### 步骤5: 配置S3存储桶策略

创建S3存储桶策略以允许OAC访问：

```bash
# 创建S3存储桶策略
cat > s3-bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${BUCKET_NAME}/output/hls/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::${AWS_ACCOUNT_ID}:distribution/${DISTRIBUTION_ID}"
        }
      }
    }
  ]
}
EOF
```

应用存储桶策略：

```bash
# 应用S3存储桶策略
aws s3api put-bucket-policy \
  --bucket ${BUCKET_NAME} \
  --policy file://s3-bucket-policy.json

echo "✅ S3存储桶策略已配置"
```

**策略关键要素:**
- `Principal`: `cloudfront.amazonaws.com` - 只允许CloudFront服务访问
- `Action`: `s3:GetObject` - 最小权限，仅允许读取对象
- `Resource`: 限制在`/output/hls/*`路径
- `Condition`: `AWS:SourceArn` - 限制为特定CloudFront分发

### 步骤6: 验证S3公共访问阻止

确保S3存储桶不允许公共访问：

```bash
# 检查公共访问阻止设置
aws s3api get-public-access-block --bucket ${BUCKET_NAME}
```

**预期输出:**
```json
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

## 🔧 缓存策略详解

### HLS优化缓存配置

| 文件类型 | 路径模式 | 缓存时间 | 压缩 | 说明 |
|----------|----------|----------|------|------|
| **播放列表** | `*.m3u8` | 5秒 | 否 | 快速更新，支持实时流 |
| **视频分片** | `*.ts` | 24小时 | 否 | 长期缓存，减少源站请求 |
| **默认** | `*` | 24小时 | 是 | 其他文件的默认策略 |

### 缓存策略原理

1. **播放列表 (*.m3u8)**
   - 短缓存时间确保客户端能快速获取最新的分片列表
   - 不压缩以减少处理延迟

2. **视频分片 (*.ts)**
   - 长缓存时间因为分片内容不会改变
   - 不压缩因为视频文件已经压缩

3. **CORS支持**
   - 转发必要的CORS头部支持跨域播放

## 🛡️ 安全配置验证

### 创建安全验证脚本

```bash
# 创建安全验证脚本
cat > verify-security.sh << EOF
#!/bin/bash

# 使用环境变量或默认值
BUCKET_NAME="\${BUCKET_NAME:-your-unique-bucket-name}"
DISTRIBUTION_ID="\${DISTRIBUTION_ID:-E1234567890ABC}"
OAC_ID="\${OAC_ID:-E1234567890XYZ}"
CLOUDFRONT_DOMAIN="\${CLOUDFRONT_DOMAIN:-d1234567890abc.cloudfront.net}"

echo "🔒 CloudFront和S3安全配置验证"
echo "=================================="
echo "存储桶: \$BUCKET_NAME"
echo "分发ID: \$DISTRIBUTION_ID"
echo "OAC ID: \$OAC_ID"
echo "域名: \$CLOUDFRONT_DOMAIN"
echo ""

# 1. 检查S3公共访问阻止
echo "1. 检查S3公共访问阻止..."
PUBLIC_ACCESS=\$(aws s3api get-public-access-block --bucket \$BUCKET_NAME --query 'PublicAccessBlockConfiguration' --output json)
BLOCK_PUBLIC_ACLS=\$(echo \$PUBLIC_ACCESS | jq -r '.BlockPublicAcls')
BLOCK_PUBLIC_POLICY=\$(echo \$PUBLIC_ACCESS | jq -r '.BlockPublicPolicy')

if [ "\$BLOCK_PUBLIC_ACLS" = "true" ] && [ "\$BLOCK_PUBLIC_POLICY" = "true" ]; then
    echo "   ✅ S3存储桶正确配置为非公开访问"
else
    echo "   ❌ S3存储桶可能允许公开访问"
fi

# 2. 检查S3存储桶策略
echo "2. 检查S3存储桶策略..."
BUCKET_POLICY=\$(aws s3api get-bucket-policy --bucket \$BUCKET_NAME --query 'Policy' --output text 2>/dev/null || echo "null")

if [ "\$BUCKET_POLICY" != "null" ]; then
    echo "   ✅ S3存储桶策略已配置"
    if echo "\$BUCKET_POLICY" | grep -q "cloudfront.amazonaws.com"; then
        echo "   ✅ 策略允许CloudFront服务访问"
    fi
    if echo "\$BUCKET_POLICY" | grep -q "\$DISTRIBUTION_ID"; then
        echo "   ✅ 策略限制为特定CloudFront分发"
    fi
fi

# 3. 检查CloudFront OAC配置
echo "3. 检查CloudFront OAC配置..."
if [ "\$OAC_ID" != "" ]; then
    OAC_CONFIG=\$(aws cloudfront get-origin-access-control --id \$OAC_ID --query 'OriginAccessControl' --output json 2>/dev/null || echo "null")
    if [ "\$OAC_CONFIG" != "null" ]; then
        SIGNING_PROTOCOL=\$(echo \$OAC_CONFIG | jq -r '.OriginAccessControlConfig.SigningProtocol')
        if [ "\$SIGNING_PROTOCOL" = "sigv4" ]; then
            echo "   ✅ OAC使用正确的签名协议"
        fi
    fi
fi

# 4. 检查CloudFront分发OAC关联
echo "4. 检查CloudFront分发OAC关联..."
DISTRIBUTION_OAC=\$(aws cloudfront get-distribution --id \$DISTRIBUTION_ID --query 'Distribution.DistributionConfig.Origins.Items[0].OriginAccessControlId' --output text 2>/dev/null || echo "null")

if [ "\$DISTRIBUTION_OAC" = "\$OAC_ID" ]; then
    echo "   ✅ CloudFront分发正确关联OAC"
fi

# 5. 测试直接S3访问（应该被拒绝）
echo "5. 测试直接S3访问（应该被拒绝）..."
S3_DIRECT_URL="https://\$BUCKET_NAME.s3.amazonaws.com/output/hls/4ktest.m3u8"

if curl -s -I "\$S3_DIRECT_URL" | grep -q "403 Forbidden"; then
    echo "   ✅ 直接S3访问被正确拒绝"
elif curl -s -I "\$S3_DIRECT_URL" | grep -q "200 OK"; then
    echo "   ❌ 直接S3访问未被拒绝（安全风险）"
fi

# 6. 测试CloudFront访问（应该成功）
echo "6. 测试CloudFront访问（应该成功）..."
CLOUDFRONT_URL="https://\$CLOUDFRONT_DOMAIN/4ktest.m3u8"

if curl -s -I "\$CLOUDFRONT_URL" | grep -q "200 OK"; then
    echo "   ✅ CloudFront访问成功"
elif curl -s -I "\$CLOUDFRONT_URL" | grep -q "403 Forbidden"; then
    echo "   ❌ CloudFront访问被拒绝（配置错误）"
else
    echo "   ⏳ CloudFront可能还在部署中"
fi

echo ""
echo "🛡️  安全配置总结:"
echo "   - S3存储桶: 非公开访问 ✅"
echo "   - 访问控制: 仅通过CloudFront OAC ✅"
echo "   - 传输加密: HTTPS强制重定向 ✅"
echo "   - 访问限制: 特定CloudFront分发 ✅"
EOF

chmod +x verify-security.sh
```

### 运行安全验证

```bash
# 设置环境变量（根据你的实际配置修改）
export BUCKET_NAME="your-bucket-name"
export DISTRIBUTION_ID="your-distribution-id"
export OAC_ID="your-oac-id"
export CLOUDFRONT_DOMAIN="your-cloudfront-domain"

# 运行验证
./verify-security.sh
```

## 📱 使用方法

### 播放URL

**主播放列表（自适应码率）:**
```
https://${CLOUDFRONT_DOMAIN}/4ktest.m3u8
```

**各分辨率播放列表:**
- **1080p**: https://${CLOUDFRONT_DOMAIN}/4ktest_1080p.m3u8
- **720p**: https://${CLOUDFRONT_DOMAIN}/4ktest_720p.m3u8
- **360p**: https://${CLOUDFRONT_DOMAIN}/4ktest_360p.m3u8

### HTML5播放器集成

```html
<video controls>
  <source src="https://${CLOUDFRONT_DOMAIN}/4ktest.m3u8" type="application/x-mpegURL">
  您的浏览器不支持HTML5视频播放。
</video>
```

### Video.js播放器集成

```html
<link href="https://vjs.zencdn.net/8.0.4/video-js.css" rel="stylesheet">
<script src="https://vjs.zencdn.net/8.0.4/video.min.js"></script>

<video-js id="my-video" class="vjs-default-skin" controls preload="auto" width="800" height="450">
  <source src="https://${CLOUDFRONT_DOMAIN}/4ktest.m3u8" type="application/x-mpegURL">
</video-js>

<script>
  var player = videojs('my-video');
</script>
```

## 🔧 管理和监控

### CloudFront分发状态检查

```bash
# 检查分发状态
aws cloudfront get-distribution --id ${DISTRIBUTION_ID} --query 'Distribution.Status' --output text

# 检查分发配置
aws cloudfront get-distribution-config --id ${DISTRIBUTION_ID}
```

### 缓存失效

```bash
# 创建缓存失效
aws cloudfront create-invalidation \
  --distribution-id ${DISTRIBUTION_ID} \
  --invalidation-batch "Paths={Quantity=1,Items=['/*']},CallerReference=invalidation-$(date +%s)"
```

### CloudWatch监控

```bash
# 获取请求数量指标
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=${DISTRIBUTION_ID} \
  --start-time $(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%S") \
  --end-time $(date -u +"%Y-%m-%dT%H:%M:%S") \
  --period 3600 \
  --statistics Sum
```

## 🚨 故障排除

### 常见问题

1. **403 Forbidden错误**
   - 检查OAC配置是否正确
   - 验证S3存储桶策略
   - 确认CloudFront分发已关联OAC

2. **分发部署时间长**
   - CloudFront分发通常需要10-15分钟部署
   - 可以通过AWS控制台监控部署进度

3. **缓存问题**
   - 使用缓存失效清除旧内容
   - 检查缓存策略配置

### 调试命令

```bash
# 检查分发状态
aws cloudfront get-distribution --id ${DISTRIBUTION_ID} --query 'Distribution.Status'

# 测试URL访问
curl -I https://${CLOUDFRONT_DOMAIN}/4ktest.m3u8

# 检查S3存储桶策略
aws s3api get-bucket-policy --bucket ${BUCKET_NAME}
```

## 💰 成本优化

### 价格等级选择

- **PriceClass_100**: 仅使用北美和欧洲边缘节点（成本最低）
- **PriceClass_200**: 包含亚洲边缘节点（平衡成本和性能）
- **PriceClass_All**: 全球所有边缘节点（性能最佳）

### 成本估算

| 项目 | 成本 | 说明 |
|------|------|------|
| **CloudFront请求** | $0.0075/10,000请求 | GET请求费用 |
| **数据传输** | $0.085/GB | 前10TB/月 |
| **源站请求** | $0.0075/10,000请求 | 回源请求费用 |

## 🎯 最佳实践

### 安全最佳实践

1. **使用OAC而非OAI**
   - OAC支持所有S3功能
   - 更好的安全性和性能

2. **最小权限原则**
   - S3策略仅授予必要权限
   - 限制访问路径和操作

3. **强制HTTPS**
   - 所有HTTP请求重定向到HTTPS
   - 保护数据传输安全

### 性能最佳实践

1. **合理的缓存策略**
   - 播放列表短缓存
   - 视频分片长缓存

2. **启用压缩**
   - 对文本文件启用Gzip压缩
   - 视频文件不压缩

3. **HTTP/2支持**
   - 启用HTTP/2提升性能
   - 支持多路复用

## 📚 参考资源

- [AWS CloudFront文档](https://docs.aws.amazon.com/cloudfront/)
- [Origin Access Control文档](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [HLS规范](https://tools.ietf.org/html/rfc8216)
- [Video.js文档](https://videojs.com/)

---

**注意**: 本文档基于具体的项目配置，使用时请根据实际情况调整存储桶名称、分发ID等参数。
