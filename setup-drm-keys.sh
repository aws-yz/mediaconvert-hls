#!/bin/bash

# 安全的DRM密钥设置脚本
# 用于为MediaConvert HLS加密生成和管理密钥

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 MediaConvert DRM密钥设置${NC}"
echo "=================================="

# 检查必需工具
command -v openssl >/dev/null 2>&1 || { echo -e "${RED}❌ 需要安装 openssl${NC}" >&2; exit 1; }

# 加载环境变量
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ 未找到 .env 文件，请先运行 setup-config.sh${NC}"
    exit 1
fi

# 创建密钥目录
KEYS_DIR="keys"
mkdir -p "$KEYS_DIR"

echo -e "${YELLOW}📋 密钥配置选项:${NC}"
echo "1. 生成固定密钥（简单，适合测试）"
echo "2. 生成时间相关密钥（中等安全）"
echo "3. 生成用户相关密钥（高安全，需要认证系统）"
echo ""

read -p "请选择密钥类型 (1-3): " KEY_TYPE

case $KEY_TYPE in
    1)
        echo -e "${BLUE}🔑 生成固定密钥...${NC}"
        # 生成16字节随机密钥
        ENCRYPTION_KEY=$(openssl rand -hex 16)
        echo "$ENCRYPTION_KEY" > "$KEYS_DIR/static.key"
        
        # 创建二进制密钥文件
        echo "$ENCRYPTION_KEY" | xxd -r -p > "$KEYS_DIR/encryption.key"
        
        KEY_URL="https://${CLOUDFRONT_DOMAIN}/keys/encryption.key"
        ;;
        
    2)
        echo -e "${BLUE}🔑 生成时间相关密钥...${NC}"
        # 基于当前小时生成密钥
        HOUR=$(date +%Y%m%d%H)
        ENCRYPTION_KEY=$(echo -n "${PROJECT_NAME}_${HOUR}" | openssl dgst -sha256 | cut -d' ' -f2 | cut -c1-32)
        echo "$ENCRYPTION_KEY" > "$KEYS_DIR/hourly.key"
        
        # 创建二进制密钥文件
        echo "$ENCRYPTION_KEY" | xxd -r -p > "$KEYS_DIR/encryption.key"
        
        KEY_URL="https://${CLOUDFRONT_DOMAIN}/keys/encryption.key"
        
        echo -e "${YELLOW}⚠️  注意：此密钥每小时自动更新，需要配置自动化脚本${NC}"
        ;;
        
    3)
        echo -e "${BLUE}🔑 生成用户相关密钥模板...${NC}"
        echo -e "${YELLOW}⚠️  此选项需要实现认证API，这里生成模板${NC}"
        
        # 生成主密钥
        MASTER_KEY=$(openssl rand -hex 32)
        echo "$MASTER_KEY" > "$KEYS_DIR/master.key"
        
        # 创建密钥API模板
        cat > "$KEYS_DIR/key-api-template.py" << 'EOF'
#!/usr/bin/env python3
"""
DRM密钥API服务器模板
需要根据实际认证系统进行修改
"""

import hmac
import hashlib
import time
from flask import Flask, request, abort, send_file
import jwt

app = Flask(__name__)

# 从环境变量或配置文件加载
MASTER_KEY = "YOUR_MASTER_KEY_HERE"
JWT_SECRET = "YOUR_JWT_SECRET_HERE"

@app.route('/keys/encryption.key')
def get_encryption_key():
    # 验证JWT token
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        abort(401)
    
    try:
        token = auth_header.split(' ')[1]
        payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        user_id = payload['user_id']
    except:
        abort(401)
    
    # 生成用户特定密钥
    current_hour = int(time.time()) // 3600
    key_data = f"{user_id}:{current_hour}".encode()
    user_key = hmac.new(
        bytes.fromhex(MASTER_KEY),
        key_data,
        hashlib.sha256
    ).digest()[:16]  # AES-128需要16字节
    
    # 返回密钥文件
    with open('/tmp/user_key.bin', 'wb') as f:
        f.write(user_key)
    
    return send_file('/tmp/user_key.bin', 
                    mimetype='application/octet-stream',
                    cache_timeout=300)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF
        
        KEY_URL="https://your-api-server.com/keys/encryption.key"
        ENCRYPTION_KEY="DYNAMIC_USER_BASED"
        ;;
        
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

# 更新环境变量
echo "" >> .env
echo "# DRM加密配置" >> .env
echo "ENCRYPTION_KEY=$ENCRYPTION_KEY" >> .env
echo "KEY_URL=$KEY_URL" >> .env
echo "DRM_ENABLED=true" >> .env

# 创建加密版本的MediaConvert配置
if [ -f "mediaconvert-job.json" ]; then
    echo -e "${BLUE}📝 创建加密版本的MediaConvert配置...${NC}"
    
    # 备份原始配置
    cp mediaconvert-job.json mediaconvert-job-original.json
    
    # 使用jq添加加密配置（如果有jq的话）
    if command -v jq >/dev/null 2>&1; then
        jq --arg key_url "$KEY_URL" --arg key_value "$ENCRYPTION_KEY" '
        .Settings.OutputGroups[0].OutputGroupSettings.HlsGroupSettings.Encryption = {
            "Type": "STATIC_KEY",
            "StaticKeyProvider": {
                "StaticKeyValue": $key_value,
                "Url": $key_url
            },
            "InitializationVectorInManifest": "INCLUDE",
            "EncryptionMethod": "AES128",
            "KeyRotationIntervalSeconds": 0
        }' mediaconvert-job.json > mediaconvert-job-encrypted.json
        
        echo -e "${GREEN}✅ 已创建 mediaconvert-job-encrypted.json${NC}"
    else
        echo -e "${YELLOW}⚠️  请手动编辑 mediaconvert-job.json 添加加密配置${NC}"
        echo "或安装 jq 工具后重新运行此脚本"
    fi
fi

# 设置密钥文件权限
chmod 600 "$KEYS_DIR"/*

echo ""
echo -e "${GREEN}✅ DRM密钥设置完成！${NC}"
echo ""
echo -e "${BLUE}📋 配置摘要:${NC}"
echo "密钥类型: $KEY_TYPE"
echo "密钥URL: $KEY_URL"
echo "密钥文件: $KEYS_DIR/"
echo ""
echo -e "${YELLOW}🔒 安全提醒:${NC}"
echo "1. 密钥文件包含敏感信息，请妥善保管"
echo "2. 生产环境建议使用HTTPS和认证保护密钥URL"
echo "3. 定期轮换密钥以提高安全性"
echo "4. 监控密钥访问日志，检测异常访问"
echo ""
echo -e "${BLUE}📖 下一步:${NC}"
echo "1. 上传密钥文件到S3: aws s3 cp $KEYS_DIR/ s3://$BUCKET_NAME/keys/ --recursive"
echo "2. 配置CloudFront缓存策略（密钥文件建议不缓存）"
echo "3. 使用 mediaconvert-job-encrypted.json 运行加密转换"
echo "4. 测试加密视频播放"
