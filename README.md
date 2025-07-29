# MediaConvert HLS视频转换与分发项目

[![GitHub](https://img.shields.io/github/license/aws-yz/mediaconvert-hls)](https://github.com/aws-yz/mediaconvert-hls/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/aws-yz/mediaconvert-hls)](https://github.com/aws-yz/mediaconvert-hls/issues)
[![GitHub stars](https://img.shields.io/github/stars/aws-yz/mediaconvert-hls)](https://github.com/aws-yz/mediaconvert-hls/stargazers)
[![Validate Project](https://github.com/aws-yz/mediaconvert-hls/actions/workflows/validate.yml/badge.svg)](https://github.com/aws-yz/mediaconvert-hls/actions/workflows/validate.yml)

一个完整的解决方案，将4K MP4视频转换为HLS格式的多分辨率自适应流媒体，支持标准转码和DRM加密两种模式，并可通过CloudFront进行全球分发。

## 🌟 GitHub仓库
- **仓库地址**: https://github.com/aws-yz/mediaconvert-hls
- **问题反馈**: [创建Issue](https://github.com/aws-yz/mediaconvert-hls/issues/new/choose)
- **贡献指南**: [CONTRIBUTING.md](CONTRIBUTING.md)

## 🎯 项目功能

- **视频转换**: 将4K MP4转换为HLS格式（360p、720p、1080p）
- **自适应流媒体**: 根据网络条件自动调整视频质量
- **双模式支持**: 标准HLS转码 + DRM加密转码
- **全球分发**: 通过CloudFront CDN实现低延迟播放
- **安全访问**: 使用Origin Access Control (OAC)保护S3资源
- **DRM内容保护**: 支持Static Key DRM加密，防止未授权访问
- **跨浏览器兼容**: 支持Safari、Chrome、Firefox等主流浏览器

## 🔒 重要安全提醒

**在开始之前，请注意：**
- 本项目使用配置模板，包含需要替换的占位符
- 请勿在配置文件中硬编码AWS账户ID、密钥等敏感信息
- 详细安全配置请参考：[SECURITY-GUIDE.md](SECURITY-GUIDE.md)

## 📋 前置要求

### 必需工具
- **AWS CLI** - 已配置有效凭证
- **bash** - 脚本执行环境
- **curl** - 网络测试工具
- **jq** - JSON处理工具
- **openssl** - 密钥生成工具（DRM模式需要）

### AWS权限要求
你的AWS账户需要以下服务权限：
- **MediaConvert** - 视频转换服务
- **S3** - 存储桶创建和文件管理
- **CloudFront** - CDN分发创建和管理（可选）
- **IAM** - 角色创建和策略管理

### 验证环境
```bash
# 检查AWS CLI配置
aws sts get-caller-identity

# 检查必需工具
which curl bash jq openssl
```

## 🚀 快速开始

### 选择部署模式

本项目支持两种转码模式，请根据需求选择：

| 模式 | 适用场景 | 安全级别 | 复杂度 | 一键部署 |
|------|----------|----------|--------|----------|
| **标准HLS** | 公开内容、教育视频、营销内容 | 基础 | 简单 | `./deploy-standard-complete.sh` |
| **DRM加密** | 付费内容、版权保护、企业内容 | 高级 | 中等 | `./deploy-drm-complete.sh` |

### 方法一：一键自动化部署（推荐）

#### 🎬 标准HLS转码（无加密）

**适合公开内容，部署简单快速：**

```bash
# 1. 确保所有脚本有执行权限
chmod +x *.sh

# 2. 配置项目参数
./setup-config.sh

# 3. 一键标准HLS部署
./deploy-standard-complete.sh
```

**标准模式会自动完成：**
- S3存储桶创建
- IAM角色配置
- MediaConvert标准转码
- 输出文件验证

#### 🔐 DRM加密转码（内容保护）

**适合需要版权保护的付费内容：**

```bash
# 1. 确保所有脚本有执行权限
chmod +x *.sh

# 2. 配置项目参数
./setup-config.sh

# 3. 一键DRM加密部署
./deploy-drm-complete.sh
```

**DRM模式会自动完成：**
- S3存储桶创建
- CloudFront分发创建
- DRM密钥生成
- IAM角色配置
- MediaConvert加密转码
- 部署验证

### 方法二：分步部署（完全控制）

#### 标准HLS转码分步流程

```bash
# 1. 项目配置
./setup-config.sh
source .env

# 2. 创建S3存储桶并上传视频
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
aws s3 cp your-video.mp4 s3://$BUCKET_NAME/

# 3. 配置IAM角色
./setup-iam-role.sh

# 4. 执行标准转码
./convert-to-hls.sh

# 5. (可选) 创建CloudFront分发
./create-cloudfront.sh
```

#### DRM加密转码分步流程

```bash
# 1. 项目配置
./setup-config.sh
source .env

# 2. 创建S3存储桶并上传视频
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
aws s3 cp your-video.mp4 s3://$BUCKET_NAME/

# 3. 创建CloudFront分发（DRM必需）
./create-cloudfront.sh
source .env  # 重新加载更新的环境变量

# 4. 生成DRM密钥
./setup-drm-keys.sh

# 5. 上传密钥文件
aws s3 cp keys/ s3://$BUCKET_NAME/keys/ --recursive

# 6. 配置IAM角色
./setup-iam-role.sh

# 7. 执行加密转码
ENDPOINT=$(aws mediaconvert describe-endpoints --query 'Endpoints[0].Url' --output text --region $AWS_REGION)
aws mediaconvert create-job \
    --endpoint-url $ENDPOINT \
    --region $AWS_REGION \
    --cli-input-json file://mediaconvert-job-encrypted-ready.json
```

### 第一步：获取项目
```bash
# 下载或克隆项目到本地
cd /path/to/your/workspace
# 确保所有脚本有执行权限
chmod +x *.sh
```

### 第二步：配置项目参数
```bash
# 运行配置向导（推荐）
./setup-config.sh

# 或者使用非交互模式（使用默认值）
./setup-config.sh --non-interactive
```

配置向导会要求你设置：
- **S3存储桶名称** - 存储视频文件的桶（必须全局唯一）
- **输入文件名** - 你的源视频文件名
- **AWS区域** - 部署区域（推荐 us-east-1）
- **IAM角色名称** - MediaConvert使用的角色
- **项目名称** - 用于标识资源

### 第三步：准备视频文件
```bash
# 将你的视频文件放在项目目录中
# 文件名应与配置中的 INPUT_FILE 匹配
ls -la your-video-file.mp4
```

### 第四步：选择部署模式
```bash
# 标准HLS转码（推荐新手）
./deploy-standard-complete.sh

# 或者 DRM加密转码（推荐付费内容）
./deploy-drm-complete.sh
```

## 📹 MediaConvert作业执行

### 🎬 标准HLS转码

**适用场景：** 公开内容、教育视频、营销材料

```bash
# 方法1: 使用一键部署脚本
./deploy-standard-complete.sh

# 方法2: 使用传统转换脚本
./convert-to-hls.sh

# 方法3: 手动执行
ENDPOINT=$(aws mediaconvert describe-endpoints --query 'Endpoints[0].Url' --output text --region $AWS_REGION)
aws mediaconvert create-job \
    --endpoint-url $ENDPOINT \
    --region $AWS_REGION \
    --cli-input-json file://mediaconvert-job-standard-ready.json
```

**输出文件：**
- `video.m3u8` - 主播放列表（自适应）
- `video_1080p.m3u8` - 1080p播放列表
- `video_720p.m3u8` - 720p播放列表
- `video_360p.m3u8` - 360p播放列表
- `*.ts` - 视频分片文件

### 🔐 DRM加密转码

**适用场景：** 付费内容、版权保护、企业内容

```bash
# 方法1: 使用一键部署脚本（推荐）
./deploy-drm-complete.sh

# 方法2: 分步执行
# 1. 创建CloudFront分发
./create-cloudfront.sh

# 2. 生成DRM密钥
./setup-drm-keys.sh

# 3. 上传密钥文件
aws s3 cp keys/ s3://$BUCKET_NAME/keys/ --recursive

# 4. 执行加密转码
ENDPOINT=$(aws mediaconvert describe-endpoints --query 'Endpoints[0].Url' --output text --region $AWS_REGION)
aws mediaconvert create-job \
    --endpoint-url $ENDPOINT \
    --region $AWS_REGION \
    --cli-input-json file://mediaconvert-job-encrypted-ready.json
```

**输出文件：**
- `video.m3u8` - 加密的主播放列表
- `video_1080p.m3u8` - 加密的1080p播放列表
- `video_720p.m3u8` - 加密的720p播放列表
- `video_360p.m3u8` - 加密的360p播放列表
- `*.ts` - 加密的视频分片文件
- `keys/encryption.key` - DRM密钥文件

**转换时间：** 4K视频转换通常需要15-30分钟，具体取决于视频长度和复杂度。

## ☁️ CloudFront分发设置

### 何时需要CloudFront

| 场景 | 标准HLS | DRM加密 |
|------|---------|---------|
| **本地测试** | 可选 | 必需 |
| **生产环境** | 推荐 | 必需 |
| **全球分发** | 推荐 | 必需 |
| **DRM密钥分发** | 不适用 | 必需 |

### 创建CloudFront分发

```bash
# 自动创建（推荐）
./create-cloudfront.sh

# 管理现有分发
./manage-cloudfront.sh
```

**重要提示：** 
- DRM加密模式必须使用CloudFront来分发密钥文件
- 标准HLS模式可以选择性使用CloudFront来提升性能
- CloudFront分发部署通常需要10-15分钟才能全球生效

## 🎬 视频播放测试

### 播放URL格式

#### 标准HLS（S3直接访问）
```bash
# 仅限同区域访问，适合测试
s3://your-bucket-name/output/hls/video.m3u8
```

#### 通过CloudFront分发
```bash
# 全球CDN加速，适合生产环境
https://your-cloudfront-domain.cloudfront.net/output/hls/video.m3u8

# 固定质量播放列表
https://your-cloudfront-domain.cloudfront.net/output/hls/video_1080p.m3u8
https://your-cloudfront-domain.cloudfront.net/output/hls/video_720p.m3u8
https://your-cloudfront-domain.cloudfront.net/output/hls/video_360p.m3u8
```

### 播放方式

**1. 使用项目内置播放器：**
```bash
# 打开本地HLS播放器
open enhanced-hls-player.html
```

**2. Safari直接播放：**
```bash
# Safari原生支持HLS
open 'https://your-cloudfront-domain.cloudfront.net/output/hls/video.m3u8'
```

**3. 集成到网页：**
```html
<video controls width="800" height="450">
  <source src="https://your-cloudfront-domain.cloudfront.net/output/hls/video.m3u8" type="application/x-mpegURL">
  您的浏览器不支持HLS播放
</video>
```

### 验证DRM加密是否生效

**仅适用于DRM加密模式：**

```bash
# 检查播放列表中的加密标记
curl -s https://your-cloudfront-domain.cloudfront.net/output/hls/video.m3u8 | grep "EXT-X-KEY"

# 测试密钥文件访问
curl -I https://your-cloudfront-domain.cloudfront.net/keys/encryption.key

# 下载视频分片检查加密状态
curl -s https://your-cloudfront-domain.cloudfront.net/output/hls/segment.ts | head -c 100 | hexdump -C
```

如果看到 `#EXT-X-KEY` 标记和加密的视频分片数据，说明DRM加密成功！

## 🔧 配置选项

### 环境变量配置
```bash
# 基础配置
export BUCKET_NAME="your-unique-bucket-name"
export INPUT_FILE="your-video.mp4"
export AWS_REGION="us-east-1"
export ROLE_NAME="MediaConvertRole"
export PROJECT_NAME="mediaconvert-hls"

# CloudFront配置（DRM模式或需要CDN时）
export DISTRIBUTION_ID="E1234567890ABC"
export CLOUDFRONT_DOMAIN="d1234567890abc.cloudfront.net"
export OAC_ID="E1234567890XYZ"
```

### 命令行参数
```bash
# 直接传递参数给转换脚本
./convert-to-hls.sh bucket-name video.mp4 us-west-2 MyRole
```

## 📊 技术规格

### 输出格式
| 分辨率 | 尺寸 | 视频码率 | 音频码率 | 适用场景 |
|--------|------|----------|----------|----------|
| 360p | 640×360 | ~1.0Mbps | 96kbps | 移动网络 |
| 720p | 1280×720 | ~2.9Mbps | 96kbps | 标准宽带 |
| 1080p | 1920×1080 | ~5.7Mbps | 96kbps | 高速网络 |

### 编码设置
- **视频编码**: H.264 (AVC)
- **音频编码**: AAC-LC
- **分片长度**: 10秒
- **帧率**: 保持原始帧率
- **GOP大小**: 90帧

### 🔐 DRM加密设置（仅DRM模式）
- **加密算法**: AES-128
- **加密方式**: Static Key DRM
- **密钥管理**: 支持固定密钥、时间相关密钥、用户相关密钥
- **密钥分发**: 通过HTTPS URL分发
- **兼容性**: 支持HLS标准的所有主流播放器

## 💰 成本估算

### MediaConvert费用
- **基础层**: $0.0075/分钟（前1000分钟/月）
- **专业层**: $0.0150/分钟（1000分钟后）

### CloudFront费用（可选）
- **请求费用**: $0.0075/10,000请求
- **数据传输**: $0.085/GB（前10TB/月）

### S3存储费用
- **标准存储**: $0.023/GB/月
- **请求费用**: $0.0004/1,000 PUT请求

**成本对比：**
- **标准HLS**: 10分钟4K视频转换 ≈ $0.08
- **DRM加密**: 10分钟4K视频转换 + CloudFront ≈ $0.15

## 🛠️ 故障排除

### 常见问题

**1. AWS权限错误**
```bash
# 检查AWS凭证
aws sts get-caller-identity

# 检查权限
aws iam get-user
```

**2. 存储桶名称冲突**
```bash
# S3存储桶名称必须全局唯一
# 修改配置中的BUCKET_NAME为唯一名称
```

**3. MediaConvert作业失败**
```bash
# 查看作业详情
aws mediaconvert get-job --endpoint-url $ENDPOINT --id $JOB_ID

# 检查CloudWatch日志
```

**4. CloudFront访问403错误（DRM模式）**
```bash
# 验证安全配置
./verify-security.sh

# 检查OAC配置
aws cloudfront get-origin-access-control --id $OAC_ID
```

**5. 视频无法播放**
```bash
# 标准HLS: 检查S3访问权限
aws s3 ls s3://$BUCKET_NAME/output/hls/

# DRM模式: 测试CORS配置
curl -H "Origin: https://example.com" -I https://your-domain/video.m3u8
```

### 调试工具
```bash
# 配置验证
./verify-config.sh

# 安全验证（DRM模式）
./verify-security.sh

# CloudFront状态检查
./manage-cloudfront.sh status
```

## 📁 项目文件说明

```
mediaConvert/
├── 🚀 核心脚本
│   ├── setup-config.sh              # 配置向导脚本
│   ├── deploy-standard-complete.sh  # 一键标准HLS部署
│   ├── deploy-drm-complete.sh       # 一键DRM加密部署
│   ├── create-cloudfront.sh         # CloudFront分发创建脚本
│   ├── setup-drm-keys.sh            # DRM密钥生成脚本
│   ├── setup-iam-role.sh            # IAM角色管理脚本
│   └── convert-to-hls.sh            # 传统转换脚本
│
├── 🔍 验证脚本
│   ├── verify-config.sh             # 配置验证脚本
│   └── verify-security.sh           # 安全验证脚本
│
├── 🎬 播放器
│   └── enhanced-hls-player.html     # HLS播放器
│
├── ⚙️ 配置文件
│   ├── mediaconvert-job-template.json           # 标准HLS转码模板
│   ├── mediaconvert-job-encrypted-template.json # DRM加密转码模板
│   ├── mediaconvert-job-standard-ready.json     # 标准转码配置（脚本生成）
│   ├── mediaconvert-job-encrypted-ready.json    # 加密转码配置（脚本生成）
│   ├── trust-policy.json            # IAM信任策略
│   ├── permissions-policy.json      # IAM权限策略
│   ├── s3-bucket-policy.json        # S3存储桶策略
│   └── s3-cors-config.json          # S3 CORS配置
│
├── 📝 文档
│   ├── README.md                    # 主要文档（本文件）
│   ├── SECURITY-GUIDE.md            # 安全配置指南
│   ├── CloudFront-HLS-Setup-Guide.md # CloudFront详细指南
│   ├── MEDIACONVERT-CONFIG-GUIDE.md # 配置文件指南
│   └── DRM-SCRIPTS-ANALYSIS.md     # DRM脚本分析
│
├── 🔧 环境配置
│   ├── .env                         # 环境配置文件（自动生成）
│   └── .env.example                 # 环境配置示例
│
└── 📁 备份文件
    └── backup/                      # 原始文件备份
```

## 🔒 安全最佳实践

### 标准HLS安全
- 使用IAM角色而非用户密钥
- 定期轮换访问密钥
- 监控S3访问日志

### DRM加密安全
- 存储桶设置为私有
- 仅允许CloudFront OAC访问
- 启用公共访问阻止
- 强制HTTPS重定向
- 定期轮换加密密钥
- 使用HTTPS保护密钥URL
- 监控密钥访问日志
- 实施用户认证机制

## 📚 进阶配置

### 自定义视频参数
编辑模板文件：
- 调整码率设置
- 修改分辨率配置
- 更改编码参数

### 多环境部署
```bash
# 开发环境
export BUCKET_NAME="dev-mediaconvert-bucket"
export PROJECT_NAME="mediaconvert-dev"

# 生产环境
export BUCKET_NAME="prod-mediaconvert-bucket"
export PROJECT_NAME="mediaconvert-prod"
```

### 批量处理
```bash
# 标准HLS批量处理
for video in *.mp4; do
    export INPUT_FILE="$video"
    ./deploy-standard-complete.sh
done

# DRM加密批量处理
for video in *.mp4; do
    export INPUT_FILE="$video"
    ./deploy-drm-complete.sh
done
```

## 🆘 获取帮助

### 文档资源
- `CloudFront-HLS-Setup-Guide.md` - CloudFront详细配置
- `MEDIACONVERT-CONFIG-GUIDE.md` - 配置文件详解
- `DRM-SCRIPTS-ANALYSIS.md` - DRM脚本分析
- `SECURITY-GUIDE.md` - 安全配置指南

### 支持渠道
1. 检查项目文档和故障排除部分
2. 标准HLS: 运行 `./deploy-standard-complete.sh`
3. DRM加密: 运行 `./deploy-drm-complete.sh`
4. 查看脚本输出的详细错误信息
5. 参考AWS官方文档

### 有用的AWS文档链接
- [AWS MediaConvert用户指南](https://docs.aws.amazon.com/mediaconvert/)
- [Amazon CloudFront开发者指南](https://docs.aws.amazon.com/cloudfront/)
- [Amazon S3用户指南](https://docs.aws.amazon.com/s3/)
- [HLS规范文档](https://tools.ietf.org/html/rfc8216)

### 验证命令
```bash
# 检查转码作业
aws mediaconvert get-job --endpoint-url $ENDPOINT --id $JOB_ID

# 验证配置
./verify-config.sh

# 验证安全配置（DRM模式）
./verify-security.sh
```

---

## 🎉 部署成功！

### 标准HLS模式
完成标准部署后，你将拥有：
- ✅ 多分辨率HLS视频流
- ✅ 自适应码率播放
- ✅ 跨浏览器兼容性
- ✅ 可选的CDN分发

### DRM加密模式
完成DRM部署后，你将拥有：
- ✅ 加密的多分辨率HLS视频流
- ✅ 全球CDN分发
- ✅ 安全的访问控制
- ✅ DRM内容保护
- ✅ 密钥管理系统

**开始播放你的HLS视频吧！** 🎬

---

**注意**: 首次部署建议在AWS免费套餐范围内测试，熟悉流程后再用于生产环境。
