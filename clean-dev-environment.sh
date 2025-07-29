#!/bin/bash

# 开发环境清理脚本
# 清理所有生成的文件和敏感信息，准备提交到远程仓库

set -e

echo "🧹 清理开发环境..."

# 移除环境配置文件
echo "📋 移除环境配置文件..."
rm -f .env
rm -f .env.local
rm -f .env.production

# 移除生成的配置文件
echo "📋 移除生成的配置文件..."
rm -f *-ready.json
rm -f mediaconvert-job-*-ready.json

# 移除DRM密钥文件
echo "📋 移除DRM密钥文件..."
rm -rf keys/
rm -f *.key

# 移除大型视频文件
echo "📋 移除大型视频文件..."
rm -f *.mp4
rm -f *.mov
rm -f *.avi
rm -f *.mkv

# 移除HLS输出文件
echo "📋 移除HLS输出文件..."
rm -f *.m3u8
rm -f *.ts

# 移除临时文件
echo "📋 移除临时文件..."
rm -f *.tmp
rm -f *.temp
rm -f *.log
rm -f *~

# 移除备份文件
echo "📋 移除备份文件..."
rm -rf backup/
rm -f *.bak

# 移除过时的文件
echo "📋 移除过时的文件..."
rm -f *-fixed.json
rm -f simple-*.json

echo "✅ 开发环境清理完成！"
echo "🚀 环境已准备好提交到远程仓库"
echo ""
echo "💡 下次开发时，请运行 ./setup-config.sh 重新配置环境"
