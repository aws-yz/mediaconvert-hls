# MediaConvert HLS 快速开始指南

## 🚀 5分钟快速部署

这是一个简化的快速开始指南，帮助你在5分钟内完成MediaConvert HLS视频转换和CloudFront分发的部署。

## ✅ 前置检查

```bash
# 1. 检查AWS CLI配置
aws sts get-caller-identity

# 2. 检查必需工具
which curl bash jq
```

如果上述命令有任何失败，请先完成AWS CLI配置和工具安装。

## 📋 快速部署步骤

### 步骤1: 项目配置（1分钟）
```bash
# 运行配置向导
./setup-config.sh --non-interactive

# 加载配置
source .env

# 验证配置
./verify-config.sh
```

### 步骤2: 准备视频文件（1分钟）
```bash
# 将你的视频文件放在项目目录中
# 默认文件名: 4ktest.mp4
# 或者修改配置中的INPUT_FILE

# 检查文件存在
ls -la 4ktest.mp4
```

### 步骤3: 执行MediaConvert转换（15-30分钟）
```bash
# 开始转换
./convert-to-hls.sh

# 等待转换完成，会显示：
# ✅ 转换完成！
# 主播放列表: s3://your-bucket/output/hls/4ktest.m3u8
```

### 步骤4: 设置CloudFront分发（2分钟）
```bash
# 运行CloudFront管理脚本
./manage-cloudfront.sh

# 等待分发部署（10-15分钟）
# 脚本会显示播放URL
```

### 步骤5: 测试播放（1分钟）
```bash
# 打开本地播放器
open enhanced-hls-player.html

# 或者在Safari中直接播放
open 'https://your-cloudfront-domain.cloudfront.net/4ktest.m3u8'
```

## 🎯 预期结果

完成后你将获得：

**播放URL:**
- 主播放列表: `https://d3g6olblkz60ii.cloudfront.net/4ktest.m3u8`
- 1080p: `https://d3g6olblkz60ii.cloudfront.net/4ktest_1080p.m3u8`
- 720p: `https://d3g6olblkz60ii.cloudfront.net/4ktest_720p.m3u8`
- 360p: `https://d3g6olblkz60ii.cloudfront.net/4ktest_360p.m3u8`

**本地播放器:**
- `file:///path/to/project/enhanced-hls-player.html`

## 🛠️ 常见问题快速解决

### 问题1: AWS权限错误
```bash
# 解决方案: 检查AWS凭证
aws configure list
aws sts get-caller-identity
```

### 问题2: 存储桶名称冲突
```bash
# 解决方案: 修改存储桶名称
export BUCKET_NAME="your-unique-bucket-name-$(date +%s)"
./convert-to-hls.sh
```

### 问题3: 视频文件不存在
```bash
# 解决方案: 检查文件路径
ls -la *.mp4
export INPUT_FILE="your-actual-video-file.mp4"
./convert-to-hls.sh
```

### 问题4: CloudFront访问403
```bash
# 解决方案: 验证安全配置
./verify-security.sh
```

### 问题5: 视频无法播放
```bash
# 解决方案: 检查CORS配置
curl -H "Origin: https://example.com" -I https://your-domain/4ktest.m3u8
```

## 📞 需要帮助？

如果快速部署遇到问题：

1. **查看详细文档**: `README.md`
2. **CloudFront配置**: `CloudFront-HLS-Setup-Guide.md`
3. **参数化配置**: `PARAMETERIZATION-SUMMARY.md`
4. **运行诊断脚本**: `./verify-config.sh` 和 `./verify-security.sh`

## 🎉 成功！

如果所有步骤都成功完成，你现在拥有了一个完整的HLS视频流媒体解决方案，支持：
- ✅ 多分辨率自适应播放
- ✅ 全球CDN加速
- ✅ 安全访问控制
- ✅ 跨浏览器兼容

**开始享受你的HLS视频流媒体服务吧！** 🎬
