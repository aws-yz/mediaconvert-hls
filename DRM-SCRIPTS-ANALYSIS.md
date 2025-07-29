# DRM密钥脚本分析与整理

## 📋 脚本整理结果

经过分析和整理，项目现在只保留**1个优化的DRM密钥脚本**：

```
mediaConvert/
├── 📄 当前使用的脚本
│   └── setup-drm-keys.sh                    # 修复版DRM密钥设置脚本
│
└── 📁 备份文件
    └── backup/
        └── setup-drm-keys.sh                # 原版脚本备份
```

## 🔍 两个版本的详细对比

### 📊 **功能对比表**

| 特性 | 原版脚本 | 修复版脚本 (保留) |
|------|----------|------------------|
| **CloudFront依赖检查** | ❌ 无检查 | ✅ 强制检查 |
| **密钥URL生成** | 🔴 可能生成错误URL | ✅ 使用正确域名 |
| **配置文件处理** | 🔴 使用jq动态添加 | ✅ 使用模板替换 |
| **不支持参数处理** | 🔴 生成错误参数 | ✅ 使用正确模板 |
| **JSON格式验证** | ❌ 无验证 | ✅ 完整验证 |
| **错误处理** | 🔴 基础处理 | ✅ 完善处理 |
| **与新架构兼容** | ❌ 不兼容 | ✅ 完全兼容 |

### 🔴 **原版脚本的关键问题**

#### 1. **CloudFront域名依赖问题**
```bash
# 原版脚本问题
KEY_URL="https://${CLOUDFRONT_DOMAIN}/keys/encryption.key"
# 如果CLOUDFRONT_DOMAIN未定义，会生成: https:///keys/encryption.key
```

#### 2. **配置文件生成问题**
```bash
# 原版使用jq动态添加，包含不支持的参数
"KeyRotationIntervalSeconds": 0  # ❌ MediaConvert不支持
```

#### 3. **缺少依赖检查**
```bash
# 原版只检查.env文件，不检查CloudFront是否已创建
if [ -f .env ]; then
    source .env
# 缺少对CLOUDFRONT_DOMAIN的检查
```

### ✅ **修复版脚本的优势**

#### 1. **强制依赖检查**
```bash
# 修复版强制检查CloudFront域名
if [ -z "$CLOUDFRONT_DOMAIN" ]; then
    echo "❌ 错误: CloudFront域名未设置"
    echo "请先运行: ./create-cloudfront.sh"
    exit 1
fi
```

#### 2. **使用正确的模板系统**
```bash
# 使用预定义的正确模板，避免参数错误
cp mediaconvert-job-encrypted-template.json mediaconvert-job-encrypted-ready.json
```

#### 3. **完善的JSON验证**
```bash
# 验证生成的JSON格式
if jq . mediaconvert-job-encrypted-ready.json > /dev/null 2>&1; then
    echo "✅ 已创建 mediaconvert-job-encrypted-ready.json"
else
    echo "❌ JSON格式错误，请检查配置文件"
    exit 1
fi
```

#### 4. **正确的占位符替换**
```bash
# 系统性替换所有占位符
sed -i '' "s/YOUR_16_BYTE_HEX_KEY/$STATIC_KEY/g" mediaconvert-job-encrypted-ready.json
sed -i '' "s|YOUR_CLOUDFRONT_DOMAIN|$CLOUDFRONT_DOMAIN|g" mediaconvert-job-encrypted-ready.json
sed -i '' "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" mediaconvert-job-encrypted-ready.json
```

## 🎯 **整理决策理由**

### ✅ **保留修复版的原因**
1. **解决了实际部署问题** - 修复了CloudFront域名依赖
2. **与新架构兼容** - 使用模板文件系统
3. **经过实战验证** - 在实际部署中成功使用
4. **更好的错误处理** - 完善的依赖检查和验证
5. **避免已知错误** - 不会生成不支持的参数

### 🗂️ **备份原版的原因**
1. **保留历史** - 记录项目演进过程
2. **参考价值** - 某些功能实现可能有参考价值
3. **回滚选项** - 如有需要可以参考原始实现

## 🔄 **使用流程对比**

### 原版脚本流程
```bash
1. 检查.env文件
2. 选择密钥类型
3. 生成密钥
4. 使用jq动态修改配置文件 (❌ 可能出错)
5. 输出mediaconvert-job-encrypted.json (❌ 可能有问题)
```

### 修复版脚本流程
```bash
1. 检查CloudFront域名依赖 (✅ 强制检查)
2. 检查所有必需环境变量
3. 选择密钥类型
4. 生成密钥
5. 从模板复制配置文件 (✅ 使用正确模板)
6. 系统性替换占位符 (✅ 完整替换)
7. 验证JSON格式 (✅ 格式验证)
8. 输出mediaconvert-job-encrypted-ready.json (✅ 可直接使用)
```

## 💡 **最佳实践建议**

### 使用修复版脚本的正确流程
```bash
# 1. 确保CloudFront已创建
./create-cloudfront.sh
source .env

# 2. 生成DRM密钥和配置
./setup-drm-keys.sh

# 3. 验证生成的配置
jq . mediaconvert-job-encrypted-ready.json

# 4. 使用配置进行转码
aws mediaconvert create-job --cli-input-json file://mediaconvert-job-encrypted-ready.json
```

### 故障排除
```bash
# 如果遇到CloudFront域名错误
echo $CLOUDFRONT_DOMAIN  # 检查是否已设置

# 如果遇到JSON格式错误
jq . mediaconvert-job-encrypted-ready.json  # 验证格式

# 如果遇到占位符未替换
grep "YOUR_" mediaconvert-job-encrypted-ready.json  # 检查占位符
```

## 🎉 **整理效果**

### ✅ **整理前的问题**
- 2个功能重复的脚本
- 原版脚本有已知问题
- 脚本命名不规范
- 用户容易选择错误版本

### ✅ **整理后的优势**
- 1个经过验证的脚本
- 解决了所有已知问题
- 标准化的脚本命名
- 清晰的使用指导
- 完整的备份保留

## 📚 **相关文档更新**

以下文档已更新脚本引用：
- `deploy-drm-complete.sh` - 完整部署脚本
- `README-FIXED.md` - 修复版README
- `MEDIACONVERT-CONFIG-GUIDE.md` - 配置文件指南

---

**总结**: 通过保留修复版脚本，项目现在有了一个可靠、经过验证的DRM密钥设置工具，避免了原版脚本的已知问题！🔐✨
