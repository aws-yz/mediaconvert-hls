#!/bin/bash

# CloudFront分发管理脚本
set -e

DISTRIBUTION_ID="E2OOLQY70ZOTOA"
DOMAIN_NAME="d3g6olblkz60ii.cloudfront.net"

echo "🌐 CloudFront HLS分发管理工具"
echo "================================"

# 显示分发信息
show_info() {
    echo "📊 分发信息:"
    echo "  分发ID: $DISTRIBUTION_ID"
    echo "  域名: $DOMAIN_NAME"
    echo "  主播放列表: https://$DOMAIN_NAME/4ktest.m3u8"
    echo ""
}

# 检查分发状态
check_status() {
    echo "🔍 检查分发状态..."
    STATUS=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text)
    LAST_MODIFIED=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.LastModifiedTime' --output text)
    
    echo "  状态: $STATUS"
    echo "  最后修改: $LAST_MODIFIED"
    
    if [ "$STATUS" = "Deployed" ]; then
        echo "  ✅ 分发已部署完成，可以播放视频"
    else
        echo "  ⏳ 分发正在部署中，请等待..."
    fi
    echo ""
}

# 测试连接
test_connection() {
    echo "🔗 测试CloudFront连接..."
    
    # 测试主播放列表
    if curl -s -I "https://$DOMAIN_NAME/4ktest.m3u8" | grep -q "HTTP/[12] 200"; then
        echo "  ✅ 主播放列表可访问"
    else
        echo "  ❌ 主播放列表无法访问"
        return 1
    fi
    
    # 测试各分辨率播放列表
    for resolution in "360p" "720p" "1080p"; do
        if curl -s -I "https://$DOMAIN_NAME/4ktest_${resolution}.m3u8" | grep -q "HTTP/[12] 200"; then
            echo "  ✅ ${resolution}播放列表可访问"
        else
            echo "  ❌ ${resolution}播放列表无法访问"
        fi
    done
    echo ""
}

# 获取缓存统计
get_cache_stats() {
    echo "📈 获取缓存统计..."
    
    # 获取最近24小时的统计数据
    END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S")
    START_TIME=$(date -u -d "24 hours ago" +"%Y-%m-%dT%H:%M:%S")
    
    echo "  时间范围: $START_TIME 到 $END_TIME"
    
    # 获取请求数量
    REQUESTS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/CloudFront \
        --metric-name Requests \
        --dimensions Name=DistributionId,Value=$DISTRIBUTION_ID \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --period 3600 \
        --statistics Sum \
        --query 'Datapoints[0].Sum' \
        --output text 2>/dev/null || echo "0")
    
    echo "  总请求数: ${REQUESTS:-0}"
    echo ""
}

# 创建缓存失效
invalidate_cache() {
    echo "🔄 创建缓存失效..."
    
    CALLER_REFERENCE="invalidation-$(date +%s)"
    
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --invalidation-batch "Paths={Quantity=1,Items=['/*']},CallerReference=$CALLER_REFERENCE" \
        --query 'Invalidation.Id' \
        --output text)
    
    echo "  失效ID: $INVALIDATION_ID"
    echo "  ✅ 缓存失效已创建，通常需要10-15分钟完成"
    echo ""
}

# 显示播放URL
show_urls() {
    echo "🎬 播放URL:"
    echo "  主播放列表: https://$DOMAIN_NAME/4ktest.m3u8"
    echo "  1080p: https://$DOMAIN_NAME/4ktest_1080p.m3u8"
    echo "  720p: https://$DOMAIN_NAME/4ktest_720p.m3u8"
    echo "  360p: https://$DOMAIN_NAME/4ktest_360p.m3u8"
    echo ""
    echo "📱 HLS播放器: file://$(pwd)/enhanced-hls-player.html"
    echo ""
}

# 打开HLS播放器
open_player() {
    echo "🌐 打开HLS播放器..."
    if command -v open >/dev/null 2>&1; then
        open "file://$(pwd)/enhanced-hls-player.html"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "file://$(pwd)/enhanced-hls-player.html"
    else
        echo "请手动打开: file://$(pwd)/enhanced-hls-player.html"
    fi
}

# 主菜单
show_menu() {
    echo "请选择操作:"
    echo "1) 显示分发信息"
    echo "2) 检查分发状态"
    echo "3) 测试连接"
    echo "4) 获取缓存统计"
    echo "5) 创建缓存失效"
    echo "6) 显示播放URL"
    echo "7) 打开HLS播放器"
    echo "0) 退出"
    echo ""
}

# 如果有参数，直接执行对应功能
if [ $# -gt 0 ]; then
    case $1 in
        "info") show_info ;;
        "status") check_status ;;
        "test") test_connection ;;
        "stats") get_cache_stats ;;
        "invalidate") invalidate_cache ;;
        "urls") show_urls ;;
        "player"|"open") open_player ;;
        *) echo "未知参数: $1" ;;
    esac
    exit 0
fi

# 交互式菜单
while true; do
    show_menu
    read -p "请输入选择 (0-7): " choice
    
    case $choice in
        1) show_info ;;
        2) check_status ;;
        3) test_connection ;;
        4) get_cache_stats ;;
        5) invalidate_cache ;;
        6) show_urls ;;
        7) open_player ;;
        0) echo "再见！"; exit 0 ;;
        *) echo "无效选择，请重试" ;;
    esac
    
    echo ""
    read -p "按回车键继续..."
    echo ""
done
