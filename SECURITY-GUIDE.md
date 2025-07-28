# 安全配置指南

## 🔒 重要安全提醒

本项目包含配置模板文件，使用占位符来避免硬编码敏感信息。在使用前，请务必正确配置这些占位符。

## 🚨 敏感信息占位符

以下文件包含需要替换的占位符：

### 配置文件占位符

| 占位符 | 说明 | 示例值 |
|--------|------|--------|
| `YOUR_AWS_ACCOUNT_ID` | 你的AWS账户ID | `123456789012` |
| `YOUR_BUCKET_NAME` | S3存储桶名称 | `my-mediaconvert-bucket` |
| `YOUR_ROLE_NAME` | IAM角色名称 | `MediaConvertRole` |
| `YOUR_INPUT_FILE` | 输入视频文件名 | `video.mp4` |
| `YOUR_DISTRIBUTION_ID` | CloudFront分发ID | `E1234567890ABC` |
| `YOUR_CLOUDFRONT_DOMAIN` | CloudFront域名 | `d1234567890abc.cloudfront.net` |
| `YOUR_OAC_ID` | Origin Access Control ID | `E1234567890XYZ` |

### 包含占位符的文件

- `mediaconvert-job.json` - MediaConvert作业配置
- `simple-mediaconvert-job.json` - 简化作业配置
- `s3-bucket-policy.json` - S3存储桶策略
- `permissions-policy.json` - IAM权限策略
- `enhanced-hls-player.html` - HLS播放器

## 🔧 配置方法

### 方法1: 使用配置脚本（推荐）

```bash
# 1. 设置环境变量
source .env

# 2. 自动替换占位符
./replace-placeholders.sh
```

### 方法2: 手动替换

```bash
# 1. 复制模板文件
cp mediaconvert-job.json mediaconvert-job.json.backup

# 2. 手动编辑文件，替换占位符
nano mediaconvert-job.json
```

## 🛡️ 安全最佳实践

### 1. 环境变量管理
```bash
# ✅ 正确：使用环境变量
export BUCKET_NAME="my-secure-bucket"

# ❌ 错误：硬编码在脚本中
BUCKET_NAME="my-secure-bucket"
```

### 2. 配置文件保护
```bash
# ✅ 正确：使用.env文件并加入.gitignore
echo "BUCKET_NAME=my-bucket" > .env
echo ".env" >> .gitignore

# ❌ 错误：直接提交敏感配置到Git
git add config-with-secrets.json
```

### 3. 权限最小化
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject"
  ],
  "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/output/hls/*"
}
```

### 4. 定期轮换凭证
- 定期更新AWS访问密钥
- 使用IAM角色而非长期凭证
- 启用MFA保护

## 🔍 安全检查清单

在部署前，请确认：

- [ ] 所有占位符已被替换为实际值
- [ ] .env文件已加入.gitignore
- [ ] 没有硬编码的AWS账户ID或密钥
- [ ] S3存储桶策略限制了访问权限
- [ ] IAM角色遵循最小权限原则
- [ ] CloudFront使用HTTPS强制重定向

## 🚨 泄露应急处理

如果意外泄露了敏感信息：

### 1. 立即行动
```bash
# 撤销Git提交
git reset --hard HEAD~1

# 强制推送（谨慎使用）
git push --force-with-lease
```

### 2. 更换凭证
- 立即轮换AWS访问密钥
- 更新相关配置
- 检查CloudTrail日志

### 3. 通知相关人员
- 通知团队成员
- 更新文档
- 审查访问日志

## 📞 安全问题报告

如果发现安全问题，请：

1. **不要**在公开Issue中报告安全漏洞
2. 发送邮件到项目维护者
3. 提供详细的漏洞描述
4. 等待确认后再公开讨论

## 🔗 相关资源

- [AWS安全最佳实践](https://docs.aws.amazon.com/security/)
- [IAM最佳实践](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [S3安全配置](https://docs.aws.amazon.com/s3/latest/userguide/security.html)
- [CloudFront安全](https://docs.aws.amazon.com/cloudfront/latest/developerguide/security.html)

---

**记住：安全是一个持续的过程，不是一次性的任务！** 🔐
