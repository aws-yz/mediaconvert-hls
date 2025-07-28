# HLS视频播放指南

## 🎯 重要说明

**浏览器直接访问m3u8文件会下载而不是播放，这是正常现象！**

HLS (HTTP Live Streaming) 需要专门的播放器来处理，不能像普通视频文件一样直接在浏览器中播放。

## 🎬 正确的播放方法

### 1. 使用我们提供的播放器页面

#### 增强版播放器 (推荐)
```bash
./manage-cloudfront.sh enhanced
```
- 功能最完整，包含调试信息
- 自动连接测试
- 详细的错误提示
- 支持所有现代浏览器

#### 完整播放器
```bash
./manage-cloudfront.sh open
```
- 基于Video.js的专业播放器
- 支持多种视频格式
- 完整的播放控制

#### 简单测试页面
```bash
./manage-cloudfront.sh simple
```
- 轻量级测试页面
- 快速验证播放功能

### 2. 在Safari中直接播放

Safari原生支持HLS，可以直接播放：

```bash
# 打开Safari并播放
open 'https://d3g6olblkz60ii.cloudfront.net/4ktest.m3u8'
```

### 3. 使用专业媒体播放器

#### VLC播放器
```bash
vlc 'https://d3g6olblkz60ii.cloudfront.net/4ktest.m3u8'
```

#### FFplay (如果安装了FFmpeg)
```bash
ffplay 'https://d3g6olblkz60ii.cloudfront.net/4ktest.m3u8'
```

## 🌐 浏览器兼容性

| 浏览器 | HLS支持 | 需要的库 |
|--------|---------|----------|
| Safari | ✅ 原生支持 | 无 |
| Chrome | ❌ 需要库 | HLS.js |
| Firefox | ❌ 需要库 | HLS.js |
| Edge | ❌ 需要库 | HLS.js |
| 移动浏览器 | ✅ 大多原生支持 | 无 |

## 🔧 故障排除

### 问题1: "视频加载失败"
**可能原因:**
- 网络连接问题
- CloudFront分发未完全部署
- 浏览器不支持HLS

**解决方案:**
1. 运行连接测试: `./manage-cloudfront.sh test`
2. 检查分发状态: `./manage-cloudfront.sh status`
3. 尝试不同的播放器
4. 使用诊断工具: `./diagnose-hls.sh`

### 问题2: "浏览器下载m3u8文件"
**这是正常现象！** m3u8是播放列表文件，不是视频文件。

**解决方案:**
使用我们提供的播放器页面或Safari浏览器。

### 问题3: "播放卡顿或缓冲"
**可能原因:**
- 网络带宽不足
- 选择的分辨率过高

**解决方案:**
1. 尝试较低分辨率: 360p → 720p → 1080p
2. 检查网络连接
3. 使用自适应播放列表（会自动调整）

### 问题4: "跨域错误"
**可能原因:**
- CORS配置问题
- 本地文件访问限制

**解决方案:**
1. 使用我们提供的播放器页面
2. 通过HTTP服务器访问，不要直接打开HTML文件

## 📊 可用的播放URL

### 自适应播放列表 (推荐)
```
https://d3g6olblkz60ii.cloudfront.net/4ktest.m3u8
```
会根据网络条件自动选择最佳分辨率

### 固定分辨率播放列表
```
1080p: https://d3g6olblkz60ii.cloudfront.net/4ktest_1080p.m3u8
720p:  https://d3g6olblkz60ii.cloudfront.net/4ktest_720p.m3u8
360p:  https://d3g6olblkz60ii.cloudfront.net/4ktest_360p.m3u8
```

## 🛠️ 开发者信息

### HLS.js集成示例
```html
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
<video id="video" controls></video>
<script>
  const video = document.getElementById('video');
  const videoSrc = 'https://d3g6olblkz60ii.cloudfront.net/4ktest.m3u8';
  
  if (Hls.isSupported()) {
    const hls = new Hls();
    hls.loadSource(videoSrc);
    hls.attachMedia(video);
  } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
    video.src = videoSrc;
  }
</script>
```

### 技术规格
- **编码格式**: H.264 + AAC
- **分片长度**: 10秒
- **支持分辨率**: 360p, 720p, 1080p
- **自适应码率**: 支持
- **HTTPS**: 必需

## 📱 移动设备播放

大多数移动设备原生支持HLS：

- **iOS Safari**: 完全支持
- **Android Chrome**: 部分支持，建议使用HLS.js
- **移动应用**: 可直接使用原生播放器

## 🎯 快速开始

1. **最简单的方法**: 运行 `./manage-cloudfront.sh enhanced`
2. **Safari用户**: 直接打开 `https://d3g6olblkz60ii.cloudfront.net/4ktest.m3u8`
3. **其他浏览器**: 使用我们提供的播放器页面
4. **遇到问题**: 运行 `./diagnose-hls.sh` 进行诊断

---

**记住**: HLS不是普通的视频文件，需要专门的播放器支持！
