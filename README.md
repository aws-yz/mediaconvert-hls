# MediaConvert HLS视频转换与分发项目

[![GitHub](https://img.shields.io/github/license/aws-yz/mediaconvert-hls)](https://github.com/aws-yz/mediaconvert-hls/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/aws-yz/mediaconvert-hls)](https://github.com/aws-yz/mediaconvert-hls/issues)
[![GitHub stars](https://img.shields.io/github/stars/aws-yz/mediaconvert-hls)](https://github.com/aws-yz/mediaconvert-hls/stargazers)
[![Validate Project](https://github.com/aws-yz/mediaconvert-hls/actions/workflows/validate.yml/badge.svg)](https://github.com/aws-yz/mediaconvert-hls/actions/workflows/validate.yml)

一个完整的解决方案，将4K MP4视频转换为HLS格式的多分辨率自适应流媒体，并通过CloudFront进行全球分发。

## 🌟 GitHub仓库
- **仓库地址**: https://github.com/aws-yz/mediaconvert-hls
- **问题反馈**: [创建Issue](https://github.com/aws-yz/mediaconvert-hls/issues/new/choose)
- **贡献指南**: [CONTRIBUTING.md](CONTRIBUTING.md)

## 🎯 项目功能

- **视频转换**: 将4K MP4转换为HLS格式（360p、720p、1080p）
- **自适应流媒体**: 根据网络条件自动调整视频质量
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
- **jq** - JSON处理工具（可选，用于高级功能）

### AWS权限要求
你的AWS账户需要以下服务权限：
- **MediaConvert** - 视频转换服务
- **S3** - 存储桶创建和文件管理
- **CloudFront** - CDN分发创建和管理
- **IAM** - 角色创建和策略管理

### 验证环境
```bash
# 检查AWS CLI配置
aws sts get-caller-identity

# 检查必需工具
which curl bash
```

## 🚀 快速开始

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

### 第四步：加载配置并验证
```bash
# 加载配置环境变量
source .env

# 验证配置正确性
./verify-config.sh
```

## 📹 MediaConvert作业执行

### 标准视频转换
```bash
# 执行标准HLS转换（无加密）
./convert-to-hls.sh
```

### 🔐 DRM加密转换
```bash
# 1. 首先设置DRM密钥
./setup-drm-keys.sh

# 2. 上传密钥文件到S3
source .env
aws s3 cp keys/ s3://$BUCKET_NAME/keys/ --recursive

# 3. 使用加密配置进行转换
# 注意：需要手动修改convert-to-hls.sh使用加密配置文件
# 或者直接使用AWS CLI提交加密作业
```

**转换过程包括：**
1. 创建S3存储桶
2. 上传源视频文件
3. 创建IAM角色和权限
4. 提交MediaConvert作业（标准或加密）
5. 监控转换进度
6. 显示输出文件列表

**预期输出：**
```
📋 使用配置:
   存储桶名称: your-bucket-name
   输入文件: your-video.mp4
   AWS区域: us-east-1
   IAM角色: MediaConvertRole
   DRM加密: 启用/禁用

开始MediaConvert HLS转换流程...
✅ 转换完成！
主播放列表: s3://your-bucket/output/hls/video.m3u8
```

**转换时间：** 4K视频转换通常需要15-30分钟，具体取决于视频长度和复杂度。

## ☁️ CloudFront分发设置

### 方法一：使用管理脚本（推荐）
```bash
# 运行CloudFront管理脚本
./manage-cloudfront.sh

# 脚本会显示播放URL和本地播放器路径
```

### 方法二：手动配置（完整控制）

**详细步骤请参考：** `CloudFront-HLS-Setup-Guide.md`

**快速配置命令：**
```bash
# 1. 设置环境变量
export BUCKET_NAME="your-bucket-name"
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export PROJECT_NAME="mediaconvert-hls"

# 2. 创建CloudFront分发
# （参考CloudFront-HLS-Setup-Guide.md中的详细步骤）

# 3. 创建Origin Access Control (OAC)
# （参考指南中的OAC配置步骤）

# 4. 配置S3存储桶策略
# （参考指南中的安全配置步骤）

# 5. 验证配置
./verify-security.sh
```

**重要提示：** CloudFront分发部署通常需要10-15分钟才能全球生效。

## 🎬 视频播放测试

### 获取播放URL
转换和分发完成后，你将获得以下URL：

```bash
# 自适应播放列表（推荐）
https://your-cloudfront-domain.cloudfront.net/video.m3u8

# 固定质量播放列表
https://your-cloudfront-domain.cloudfront.net/video_1080p.m3u8
https://your-cloudfront-domain.cloudfront.net/video_720p.m3u8
https://your-cloudfront-domain.cloudfront.net/video_360p.m3u8
```

### 播放方式

**1. 使用项目内置播放器：**
```bash
# 打开本地HLS播放器
open enhanced-hls-player.html
# 或者通过管理脚本
./manage-cloudfront.sh player
```

**2. Safari直接播放：**
```bash
# Safari原生支持HLS
open 'https://your-cloudfront-domain.cloudfront.net/video.m3u8'
```

**3. 集成到网页：**
```html
<video controls width="800" height="450">
  <source src="https://your-cloudfront-domain.cloudfront.net/video.m3u8" type="application/x-mpegURL">
  您的浏览器不支持HLS播放
</video>
```

## 🔧 配置选项

### 环境变量配置
```bash
# 基础配置
export BUCKET_NAME="your-unique-bucket-name"
export INPUT_FILE="your-video.mp4"
export AWS_REGION="us-east-1"
export ROLE_NAME="MediaConvertRole"
export PROJECT_NAME="mediaconvert-hls"

# CloudFront配置（部署后获得）
export DISTRIBUTION_ID="E1234567890ABC"
export CLOUDFRONT_DOMAIN="d1234567890abc.cloudfront.net"
export OAC_ID="E1234567890XYZ"
```

### 命令行参数
```bash
# 直接传递参数
./convert-to-hls.sh bucket-name video.mp4 us-west-2 MyRole
```

### 配置文件
```bash
# 编辑 .env 文件
nano .env

# 加载配置
source .env
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

### 🔐 DRM加密设置
- **加密算法**: AES-128
- **加密方式**: Static Key DRM
- **密钥管理**: 支持固定密钥、时间相关密钥、用户相关密钥
- **密钥分发**: 通过HTTPS URL分发
- **兼容性**: 支持HLS标准的所有主流播放器

## 💰 成本估算

### MediaConvert费用
- **基础层**: $0.0075/分钟（前1000分钟/月）
- **专业层**: $0.0150/分钟（1000分钟后）

### CloudFront费用
- **请求费用**: $0.0075/10,000请求
- **数据传输**: $0.085/GB（前10TB/月）

### S3存储费用
- **标准存储**: $0.023/GB/月
- **请求费用**: $0.0004/1,000 PUT请求

**示例：** 10分钟4K视频转换 + 1000次播放 ≈ $0.15

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

**4. CloudFront访问403错误**
```bash
# 验证安全配置
./verify-security.sh

# 检查OAC配置
aws cloudfront get-origin-access-control --id $OAC_ID
```

**5. 视频无法播放**
```bash
# 测试CORS配置
curl -H "Origin: https://example.com" -I https://your-domain/video.m3u8

# 检查浏览器控制台错误
```

### 调试工具
```bash
# 配置验证
./verify-config.sh

# 安全验证
./verify-security.sh

# CloudFront状态检查
./manage-cloudfront.sh status

# 网络连接测试
./manage-cloudfront.sh test
```

## 📁 项目文件说明

```
mediaConvert/
├── 🚀 核心脚本
│   ├── setup-config.sh              # 配置向导脚本
│   ├── convert-to-hls.sh            # 主转换脚本
│   ├── manage-cloudfront.sh         # CloudFront管理脚本
│   └── setup-drm-keys.sh            # DRM密钥生成和管理脚本
│
├── 🔍 验证脚本
│   ├── verify-config.sh             # 配置验证脚本
│   └── verify-security.sh           # 安全验证脚本
│
├── 🎬 播放器
│   └── enhanced-hls-player.html     # HLS播放器
│
├── ⚙️ 配置文件（模板化）
│   ├── mediaconvert-job.json        # 标准MediaConvert作业配置
│   ├── mediaconvert-job-encrypted-fixed.json # DRM加密作业配置
│   ├── simple-mediaconvert-job.json # 简化版作业配置
│   ├── trust-policy.json            # IAM信任策略
│   ├── permissions-policy.json      # IAM权限策略
│   ├── s3-bucket-policy.json        # S3存储桶策略
│   └── s3-cors-config.json          # S3 CORS配置
│
├── 📝 文档
│   ├── README.md                    # 主要文档（本文件）
│   ├── SECURITY-GUIDE.md            # 安全配置指南
│   ├── CloudFront-HLS-Setup-Guide.md # CloudFront详细指南
│   └── 其他文档...
│
├── 🔧 环境配置
│   ├── .env                         # 环境配置文件（自动生成）
│   └── .env.example                 # 环境配置示例
│
└── 📄 项目信息
    └── LICENSE                      # 开源许可证
```

## 🔒 安全最佳实践

### S3安全
- 存储桶设置为私有
- 仅允许CloudFront OAC访问
- 启用公共访问阻止

### CloudFront安全
- 强制HTTPS重定向
- 使用Origin Access Control (OAC)
- 限制访问来源

### IAM安全
- 最小权限原则
- 定期轮换访问密钥
- 使用IAM角色而非用户密钥

## 📚 进阶配置

### 自定义视频参数
编辑 `mediaconvert-job.json` 文件：
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
# 处理多个视频文件
for video in *.mp4; do
    export INPUT_FILE="$video"
    ./convert-to-hls.sh
done
```

## 🆘 获取帮助

### 文档资源
- `CloudFront-HLS-Setup-Guide.md` - CloudFront详细配置
- `PARAMETERIZATION-SUMMARY.md` - 参数化配置说明
- `config-explanation.md` - 配置文件详解
- `parameter-guide.md` - 参数速查表

### 支持渠道
1. 检查项目文档和故障排除部分
2. 运行验证脚本诊断问题
3. 查看AWS CloudWatch日志
4. 参考AWS官方文档

### 有用的AWS文档链接
- [AWS MediaConvert用户指南](https://docs.aws.amazon.com/mediaconvert/)
- [Amazon CloudFront开发者指南](https://docs.aws.amazon.com/cloudfront/)
- [Amazon S3用户指南](https://docs.aws.amazon.com/s3/)
- [HLS规范文档](https://tools.ietf.org/html/rfc8216)

---

## 🎉 部署成功！

完成上述步骤后，你将拥有：
- ✅ 多分辨率HLS视频流
- ✅ 全球CDN分发
- ✅ 自适应码率播放
- ✅ 安全的访问控制
- ✅ 跨浏览器兼容性

**开始播放你的视频吧！** 🎬

---

**注意**: 首次部署建议在AWS免费套餐范围内测试，熟悉流程后再用于生产环境。
