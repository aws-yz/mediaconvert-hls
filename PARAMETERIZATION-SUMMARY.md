# MediaConvert项目参数化配置总结

## 📋 概述

本文档总结了MediaConvert HLS转换项目的参数化配置改进，使项目更加灵活和可重用。

## 🎯 改进目标

- ✅ 消除硬编码配置，提高项目可重用性
- ✅ 支持多种配置方式（环境变量、命令行参数、配置文件）
- ✅ 提供配置向导简化设置过程
- ✅ 保持向后兼容性
- ✅ 改进用户体验和错误处理

## 🔧 主要改进

### 1. 新增配置管理脚本

**setup-config.sh** - 配置向导脚本
- 交互式配置设置
- 非交互式模式支持 (`--non-interactive`)
- 自动获取AWS账户ID
- 生成 `.env` 配置文件
- 提供使用指导

```bash
# 交互式配置
./setup-config.sh

# 非交互式配置（使用默认值）
./setup-config.sh --non-interactive
```

### 2. 参数化的转换脚本

**convert-to-hls.sh** - 主转换脚本改进
- 支持命令行参数
- 支持环境变量
- 配置验证和显示
- 向后兼容性

**使用方式：**
```bash
# 1. 命令行参数
./convert-to-hls.sh [BUCKET_NAME] [INPUT_FILE] [REGION] [ROLE_NAME]

# 2. 环境变量
export BUCKET_NAME="my-bucket"
./convert-to-hls.sh

# 3. 配置文件
source .env
./convert-to-hls.sh
```

### 3. 参数化的CloudFront指南

**CloudFront-HLS-Setup-Guide.md** - 完全参数化
- 使用环境变量替代硬编码值
- 动态生成配置文件
- 参数化的安全验证脚本
- 灵活的部署指导

**关键参数：**
```bash
export BUCKET_NAME="your-bucket-name"
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"
export PROJECT_NAME="mediaconvert-hls"
export DISTRIBUTION_ID="E2OOLQY70ZOTOA"
export CLOUDFRONT_DOMAIN="d3g6olblkz60ii.cloudfront.net"
export OAC_ID="EZ3T285Q2VMKQ"
```

## 📁 配置文件结构

### .env 配置文件
```bash
# 基础配置
export BUCKET_NAME="wyz-mediaconvert-bucket-virginia"
export INPUT_FILE="4ktest.mp4"
export AWS_REGION="us-east-1"
export ROLE_NAME="MediaConvertRole"
export PROJECT_NAME="mediaconvert-hls"
export AWS_ACCOUNT_ID="533267335205"

# CloudFront配置 (部署后更新)
export DISTRIBUTION_ID=""
export CLOUDFRONT_DOMAIN=""
export OAC_ID=""
```

## 🚀 使用流程

### 快速开始
```bash
# 1. 运行配置向导
./setup-config.sh

# 2. 加载配置
source .env

# 3. 验证配置
./verify-config.sh

# 4. 运行转换
./convert-to-hls.sh

# 5. 设置CloudFront（参考指南）
# 按照 CloudFront-HLS-Setup-Guide.md 操作

# 6. 管理CloudFront
./manage-cloudfront.sh
```

### 自定义配置示例
```bash
# 为不同环境设置不同配置
export BUCKET_NAME="my-dev-mediaconvert-bucket"
export INPUT_FILE="test-video.mp4"
export AWS_REGION="us-west-2"
export ROLE_NAME="DevMediaConvertRole"

./convert-to-hls.sh
```

## 🔄 配置优先级

配置参数的优先级顺序（从高到低）：

1. **命令行参数** - 直接传递给脚本
2. **环境变量** - 通过 `export` 设置
3. **配置文件** - `.env` 文件中的值
4. **默认值** - 脚本内置默认值

## 📊 参数对照表

| 参数 | 环境变量 | 默认值 | 说明 |
|------|----------|--------|------|
| 存储桶名称 | `BUCKET_NAME` | `wyz-mediaconvert-bucket-virginia` | S3存储桶 |
| 输入文件 | `INPUT_FILE` | `4ktest.mp4` | 源视频文件 |
| AWS区域 | `AWS_REGION` | `us-east-1` | 部署区域 |
| IAM角色 | `ROLE_NAME` | `MediaConvertRole` | MediaConvert角色 |
| 项目名称 | `PROJECT_NAME` | `mediaconvert-hls` | 项目标识 |
| AWS账户ID | `AWS_ACCOUNT_ID` | 自动获取 | 账户标识 |

## 🛡️ 向后兼容性

- 所有现有脚本继续正常工作
- 默认值保持不变
- 现有配置文件格式兼容
- 无需修改现有工作流程

## 🔧 故障排除

### 常见问题

1. **配置文件未找到**
   ```bash
   # 重新生成配置文件
   ./setup-config.sh --non-interactive
   ```

2. **环境变量未生效**
   ```bash
   # 确保正确加载配置
   source .env
   echo $BUCKET_NAME  # 验证变量
   ```

3. **参数验证失败**
   ```bash
   # 检查配置
   ./verify-config.sh
   ```

### 调试技巧

```bash
# 查看当前配置
env | grep -E "(BUCKET_NAME|INPUT_FILE|AWS_REGION|ROLE_NAME)"

# 测试脚本参数解析
./convert-to-hls.sh --help  # 查看使用说明

# 验证AWS凭证
aws sts get-caller-identity
```

## 📈 性能优化

### 配置缓存
- `.env` 文件避免重复配置
- 环境变量在shell会话中持久化
- AWS账户ID自动获取和缓存

### 脚本优化
- 参数验证提前进行
- 配置显示帮助调试
- 错误处理更加友好

## 🎯 最佳实践

### 配置管理
1. **使用配置文件** - 推荐使用 `.env` 文件管理配置
2. **环境隔离** - 不同环境使用不同配置文件
3. **版本控制** - 将 `.env.example` 加入版本控制，排除 `.env`
4. **安全考虑** - 避免在配置中包含敏感信息

### 部署流程
1. **开发环境** - 使用默认配置快速开始
2. **测试环境** - 使用专用存储桶和角色
3. **生产环境** - 严格的配置验证和监控

## 📚 相关文档

- `README.md` - 项目总体说明（已更新）
- `CloudFront-HLS-Setup-Guide.md` - CloudFront配置指南（已参数化）
- `verify-config.sh` - 配置验证脚本
- `parameter-guide.md` - 参数详细说明

## 🔮 未来改进

### 计划中的功能
- [ ] 配置模板系统
- [ ] 多环境配置管理
- [ ] 配置验证增强
- [ ] 自动化部署脚本
- [ ] 配置迁移工具

### 扩展可能性
- 支持配置文件格式（JSON、YAML）
- 集成AWS Systems Manager Parameter Store
- 添加配置加密支持
- 实现配置版本管理

---

## 📞 支持

如果在使用参数化配置时遇到问题：

1. 运行 `./setup-config.sh` 重新配置
2. 检查 `PARAMETERIZATION-SUMMARY.md` 了解详细说明
3. 查看 `README.md` 获取最新使用指导
4. 运行 `./verify-config.sh` 验证配置正确性

**注意**: 参数化配置完全向后兼容，现有用户可以继续使用原有方式，也可以逐步迁移到新的配置管理方式。
