# MediaConvert配置文件详解

## 整体结构

```
MediaConvert Job
├── Role (IAM角色)
└── Settings
    ├── TimecodeConfig (时间码配置)
    ├── OutputGroups (输出组)
    │   └── HLS Group
    │       ├── Outputs (多个分辨率输出)
    │       │   ├── 1080p Output
    │       │   ├── 720p Output
    │       │   └── 360p Output
    │       └── HlsGroupSettings (HLS组设置)
    └── Inputs (输入文件配置)
```

## 关键配置项说明

### 1. 角色配置 (Role)
- **作用**: 允许MediaConvert访问S3等AWS服务
- **格式**: `arn:aws:iam::账户ID:role/角色名`

### 2. 输出组 (OutputGroups)
每个输出组代表一种输出格式，我们使用HLS组：

#### HLS组设置 (HlsGroupSettings)
- **SegmentLength**: 分片长度（秒）
  - 推荐值: 6-10秒
  - 影响: 更短=更快启动，更长=更高效率
- **Destination**: 输出S3路径
- **DirectoryStructure**: 目录结构
  - SINGLE_DIRECTORY: 所有文件在一个目录
  - SUBDIRECTORY_PER_STREAM: 每个流一个子目录

### 3. 输出配置 (Outputs)
每个输出代表一种分辨率/质量：

#### 视频配置 (VideoDescription)
- **Width/Height**: 输出分辨率
  - 360p: 640x360
  - 720p: 1280x720  
  - 1080p: 1920x1080
- **Bitrate**: 视频码率（bps）
  - 360p: 800,000 (800kbps)
  - 720p: 2,500,000 (2.5Mbps)
  - 1080p: 5,000,000 (5Mbps)

#### H.264编码设置
- **GopSize**: GOP大小（关键帧间隔）
  - 推荐: 60-120帧
  - 影响: 更小=更好质量，更大=更高压缩
- **RateControlMode**: 码率控制
  - CBR: 恒定码率（推荐流媒体）
  - VBR: 可变码率（推荐存储）
- **CodecProfile**: 编码配置
  - BASELINE: 兼容性最好
  - MAIN: 平衡性能和兼容性
  - HIGH: 最佳压缩效率

#### 音频配置 (AudioDescriptions)
- **Codec**: AAC（推荐流媒体）
- **Bitrate**: 音频码率
  - 推荐: 96-128kbps
- **SampleRate**: 采样率
  - 推荐: 48000Hz

### 4. 输入配置 (Inputs)
- **FileInput**: S3中的源文件路径
- **VideoSelector**: 视频选择器设置
- **AudioSelectors**: 音频选择器设置

## 常用码率推荐

| 分辨率 | 视频码率 | 音频码率 | 总码率 |
|--------|----------|----------|--------|
| 360p   | 800kbps  | 96kbps   | ~900kbps |
| 480p   | 1.2Mbps  | 96kbps   | ~1.3Mbps |
| 720p   | 2.5Mbps  | 96kbps   | ~2.6Mbps |
| 1080p  | 5Mbps    | 96kbps   | ~5.1Mbps |
| 4K     | 15-25Mbps| 128kbps  | ~15-25Mbps |

## 优化建议

### 质量优化
- 提高码率可以改善质量，但会增加文件大小
- 使用VBR可以在保持质量的同时减少文件大小
- 调整GOP大小平衡质量和压缩效率

### 性能优化
- 使用SINGLE_PASS可以加快编码速度
- 减少输出数量可以降低处理时间
- 选择合适的编码配置文件

### 成本优化
- 较低的码率可以减少存储和传输成本
- 使用CBR可以更好地预测文件大小
- 考虑是否需要所有分辨率

## 故障排除

### 常见错误
1. **权限错误**: 检查IAM角色权限
2. **输入文件错误**: 确认S3路径正确
3. **编码失败**: 检查源文件格式和参数设置

### 调试技巧
- 先用单一输出测试
- 检查CloudWatch日志
- 验证S3存储桶权限
