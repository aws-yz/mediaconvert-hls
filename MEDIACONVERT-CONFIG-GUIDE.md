# MediaConvert配置文件指南

## 📋 配置文件结构（整理后）

经过整理，项目现在只保留了**2个核心模板文件**，结构清晰明了：

```
mediaConvert/
├── 📄 模板文件（需要替换占位符）
│   ├── mediaconvert-job-template.json           # 标准HLS转码模板
│   └── mediaconvert-job-encrypted-template.json # DRM加密转码模板
│
├── 📄 工作文件（脚本自动生成）
│   ├── mediaconvert-job-encrypted-ready.json    # 可用的DRM配置（脚本生成）
│   └── mediaconvert-job-standard-ready.json     # 可用的标准配置（脚本生成）
│
└── 📁 备份文件
    └── backup/                                   # 原始文件备份
        ├── mediaconvert-job.json
        ├── mediaconvert-job-original.json
        ├── mediaconvert-job-encrypted.json
        └── mediaconvert-job-encrypted-fixed.json
```

## 🎯 文件用途说明

### 📄 **模板文件（Template Files）**

#### `mediaconvert-job-template.json`
- **用途**: 标准HLS转码模板
- **特点**: 无DRM加密，生成多分辨率HLS流
- **占位符**: 包含 `YOUR_*` 占位符，需要脚本替换
- **输出**: 360p、720p、1080p三种分辨率
- **适用场景**: 不需要内容保护的视频转码

#### `mediaconvert-job-encrypted-template.json`
- **用途**: DRM加密HLS转码模板
- **特点**: 包含Static Key DRM加密配置
- **占位符**: 包含 `YOUR_*` 占位符，需要脚本替换
- **输出**: 加密的多分辨率HLS流
- **适用场景**: 需要内容保护的视频转码

### 📄 **工作文件（Working Files）**

#### `mediaconvert-job-encrypted-ready.json`
- **生成方式**: 由 `setup-drm-keys.sh` 脚本自动生成
- **状态**: 所有占位符已替换，可直接使用
- **用途**: 实际的DRM加密转码作业配置
- **包含**: 实际的密钥、URL、存储桶信息等

#### `mediaconvert-job-standard-ready.json`（可选）
- **生成方式**: 可由脚本从标准模板生成
- **状态**: 所有占位符已替换，可直接使用
- **用途**: 实际的标准转码作业配置

## 🔄 使用流程

### 标准HLS转码流程
```bash
1. 配置项目参数
   ./setup-config.sh

2. 从模板生成工作配置
   # 手动替换占位符或使用脚本
   
3. 提交转码作业
   aws mediaconvert create-job --cli-input-json file://mediaconvert-job-standard-ready.json
```

### DRM加密转码流程
```bash
1. 配置项目参数
   ./setup-config.sh

2. 创建CloudFront分发
   ./create-cloudfront.sh

3. 生成DRM密钥和配置
   ./setup-drm-keys.sh
   # 自动生成 mediaconvert-job-encrypted-ready.json

4. 提交加密转码作业
   aws mediaconvert create-job --cli-input-json file://mediaconvert-job-encrypted-ready.json
```

## 📊 配置差异对比

| 特性 | 标准模板 | 加密模板 |
|------|----------|----------|
| **加密配置** | ❌ 无 | ✅ Static Key DRM |
| **密钥管理** | N/A | ✅ 密钥URL配置 |
| **播放要求** | 标准HLS播放器 | 支持DRM的播放器 |
| **安全级别** | 基础 | 高级 |
| **复杂度** | 简单 | 中等 |
| **依赖** | S3 + CloudFront | S3 + CloudFront + 密钥服务 |

## 🔧 占位符说明

### 通用占位符
- `YOUR_AWS_ACCOUNT_ID`: AWS账户ID
- `YOUR_ROLE_NAME`: MediaConvert IAM角色名称
- `YOUR_BUCKET_NAME`: S3存储桶名称
- `YOUR_INPUT_FILE`: 输入视频文件名

### DRM专用占位符
- `YOUR_16_BYTE_HEX_KEY`: 16字节十六进制加密密钥
- `YOUR_CLOUDFRONT_DOMAIN`: CloudFront分发域名

## 🛠️ 脚本自动化

### 自动替换占位符的脚本
- `setup-drm-keys.sh`: 自动处理DRM配置
- `create-cloudfront.sh`: 自动创建CloudFront分发
- `deploy-drm-complete.sh`: 一键完整部署

### 手动替换（如需要）
```bash
# 替换通用占位符
sed -i 's/YOUR_AWS_ACCOUNT_ID/123456789012/g' config.json
sed -i 's/YOUR_BUCKET_NAME/my-bucket/g' config.json
sed -i 's/YOUR_INPUT_FILE/video.mp4/g' config.json
```

## 🎉 整理效果

### ✅ **整理前的问题**
- 5个配置文件，关系混乱
- 重复的模板文件
- 有问题的配置文件
- 文件命名不规范

### ✅ **整理后的优势**
- 2个清晰的模板文件
- 明确的文件用途
- 自动化的配置生成
- 规范的命名约定
- 完整的备份保留

## 💡 最佳实践

1. **不要直接修改模板文件** - 它们是项目的基础模板
2. **使用脚本生成工作文件** - 避免手动错误
3. **定期备份配置** - 重要配置文件要备份
4. **验证JSON格式** - 使用 `jq` 验证配置文件格式
5. **版本控制** - 将模板文件纳入版本控制

## 🔍 故障排除

### 常见问题
1. **占位符未替换**: 检查脚本是否正确执行
2. **JSON格式错误**: 使用 `jq . config.json` 验证
3. **文件不存在**: 确认脚本已生成工作文件
4. **权限错误**: 检查文件执行权限

### 验证命令
```bash
# 验证JSON格式
jq . mediaconvert-job-template.json
jq . mediaconvert-job-encrypted-template.json

# 检查占位符
grep -n "YOUR_" *.json

# 查看文件状态
ls -la mediaconvert-job*.json
```

---

**总结**: 通过这次整理，项目配置文件结构更加清晰，使用更加简单，维护更加容易！🎬✨
