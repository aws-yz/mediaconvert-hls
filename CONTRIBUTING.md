# 贡献指南

感谢你对MediaConvert HLS项目的关注！我们欢迎各种形式的贡献。

## 🤝 如何贡献

### 报告问题
- 使用GitHub Issues报告bug
- 提供详细的错误信息和重现步骤
- 包含你的环境信息（AWS区域、CLI版本等）

### 提交功能请求
- 在Issues中描述你希望的功能
- 解释为什么这个功能有用
- 提供使用场景示例

### 代码贡献
1. Fork这个仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 📋 开发指南

### 环境设置
```bash
# 克隆仓库
git clone https://github.com/your-username/mediaconvert-hls.git
cd mediaconvert-hls

# 设置配置
cp .env.example .env
# 编辑 .env 文件

# 测试配置
./setup-config.sh --non-interactive
source .env
./verify-config.sh
```

### 代码规范
- 使用bash脚本最佳实践
- 添加适当的错误处理
- 包含详细的注释
- 遵循现有的代码风格

### 测试
- 在提交前测试所有脚本
- 验证配置脚本正常工作
- 确保文档与代码同步

## 🐛 问题报告模板

```
**描述问题**
简要描述遇到的问题

**重现步骤**
1. 运行 '...'
2. 点击 '....'
3. 看到错误

**预期行为**
描述你期望发生什么

**环境信息**
- OS: [e.g. macOS 12.0]
- AWS CLI版本: [e.g. 2.0.0]
- AWS区域: [e.g. us-east-1]

**额外信息**
添加任何其他相关信息
```

## 📝 文档贡献

- 改进现有文档
- 添加使用示例
- 翻译文档到其他语言
- 修复拼写和语法错误

## 🎯 优先级

我们特别欢迎以下类型的贡献：
- 性能优化
- 错误修复
- 文档改进
- 新的视频格式支持
- 监控和日志功能

## 📞 联系方式

如果你有任何问题，可以：
- 创建GitHub Issue
- 查看现有的Issues和Discussions

感谢你的贡献！ 🎉
