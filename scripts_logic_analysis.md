# XList 项目脚本逻辑分析文档

## 项目概述
XList 是一个基于 Flutter 的文件管理应用，支持多种云存储服务，提供文件浏览、搜索、预览、下载等功能。

---

## 路由配置

### 主路由 (app_pages.dart)
- **INITIAL**: `/homepage` - 应用启动页
- **HOMEPAGE**: `/homepage` - 首页
- **DETAIL**: `/detail` - 文件详情页
- **SEARCH**: `/search` - 搜索页
- **DIRECTORY**: `/directory` - 目录页
- **DOCUMENT**: `/document` - 文档预览页
- **FILE**: `/file` - 文件页
- **IMAGE_PREVIEW**: `/image/preview` - 图片预览页
- **VIDEO_PLAYER**: `/video/player` - 视频播放页
- **AUDIO_PLAYER**: `/audio/player` - 音频播放页
- **IMAGE_GALLERY**: `/image_gallery` - 图片画廊页
- **SETTING**: `/setting` - 设置页（包含多个子路由）

### 设置子路由
- `/setting/server` - 服务器管理
- `/setting/download` - 下载管理
- `/setting/about` - 关于页面
- `/setting/recent` - 最近浏览
- `/setting/favorite` - 收藏
- `/setting/preview/image` - 图片预览设置
- `/setting/preview/audio` - 音频预览设置
- `/setting/preview/video` - 视频预览设置
- `/setting/preview/document` - 文档预览设置

### 特殊路由
- `/image_gallery` - 图片画廊（未在 Routes 中定义，但存在于 app_pages.dart）

---

## 页面控制器逻辑分析

### 1. HomepageController (首页控制器)
**文件路径**: `lib/pages/homepage/controller.dart`

**功能**: 显示服务器根目录的文件列表

**主要状态**:
- `objects`: 文件对象列表
- `isFirstLoading`: 是否首次加载
- `serverId`: 服务器ID
- `layoutType`: 布局类型（网格/列表）
- `isShowPreview`: 是否显示预览图
- `userInfo`: 用户信息

**主要方法**:
- `getObjectList({bool refresh = false})`: 获取根目录文件列表
  - 检查 serverId 和 serverUrl 是否有效
  - 调用 ObjectRepository.getList(path: '/') 获取数据
  - 使用 CommonUtils.sortObjectList 排序
- `resetUserToken(dynamic server, {bool force = false})`: 重置用户令牌

**参数**: 无（从 UserStorage 获取 serverId）

---

### 2. DirectoryController (目录控制器)
**文件路径**: `lib/pages/directory/controller.dart`

**功能**: 显示特定目录的子目录列表（仅显示文件夹）

**主要状态**:
- `objects`: 目录对象列表
- `isFirstLoading`: 是否首次加载
- `serverId`: 服务器ID
- `isShowPreview`: 是否显示预览图
- `password`: 目录密码

**路由参数**:
- `path`: 目录路径
- `object`: 当前目录对象
- `tag`: 页面标签
- `isCopy`: 是否为复制操作
- `root`: 是否为根目录
- `source`: 来源
- `srcDir`: 源目录
- `srcObject`: 源对象

**主要方法**:
- `getDirectoryList()`: 获取目录列表
  - 调用 ObjectRepository.getDirs() 获取子目录
  - 处理 403 权限错误，提示输入密码
  - 使用 formatData 格式化数据
- `formatData(dynamic response)`: 格式化数据，将 FsDirsModel 转换为 ObjectModel
- `moveOrCopy()`: 移动或复制文件

---

### 3. DetailController (详情控制器)
**文件路径**: `lib/pages/detail/controller.dart`

**功能**: 显示特定目录的文件和文件夹列表

**主要状态**:
- `objects`: 文件对象列表
- `isFirstLoading`: 是否首次加载
- `serverId`: 服务器ID
- `sortType`: 排序方式
- `layoutType`: 布局方式
- `isShowPreview`: 是否显示预览图
- `password`: 目录密码

**路由参数**:
- `path`: 目录路径
- `name`: 目录名称

**主要方法**:
- `getObjectList({bool refresh = false})`: 获取对象列表
  - 调用 ObjectRepository.getList() 获取数据
  - 处理 401 未登录错误，强制刷新 token
  - 处理 403 权限错误，提示输入密码
  - 使用 CommonUtils.sortObjectList 排序

---

### 4. FileController (文件控制器)
**文件路径**: `lib/pages/file/controller.dart`

**功能**: 显示单个文件的详细信息

**主要状态**:
- `object`: 文件对象
- `userInfo`: 用户信息
- `serverId`: 服务器ID
- `isLoading`: 是否正在加载

**路由参数**:
- `path`: 文件路径
- `name`: 文件名称

**主要方法**:
- `copyLink()`: 复制下载链接
- `download()`: 下载文件
- 绑定下载进度监听

**生命周期**:
- `onInit`: 获取文件信息、用户信息，加入最近浏览
- `onClose`: 取消进度监听

---

### 5. SearchController (搜索控制器)
**文件路径**: `lib/pages/search/controller.dart`

**功能**: 搜索文件

**主要状态**:
- `searchList`: 搜索结果列表
- `serverId`: 服务器ID
- `isShowPreview`: 是否显示预览图
- `password`: 目录密码

**路由参数**:
- `path`: 搜索路径

**主要方法**:
- `onChanged(String value)`: 搜索输入变化时触发
- `getSearchObjectList(String keywords)`: 获取搜索结果
  - 调用 ObjectRepository.search() 搜索文件
  - 每页 100 条记录

---

### 6. DocumentController (文档控制器)
**文件路径**: `lib/pages/document/controller.dart`

**功能**: 预览文档文件（支持代码、HTML等）

**主要状态**:
- `object`: 文档对象
- `userInfo`: 用户信息
- `httpHeaders`: HTTP 请求头
- `serverId`: 服务器ID
- `isLoading`: 是否正在加载
- `progress`: 加载进度
- `layoutMode`: 布局模式（defaultView/fullscreen/readerMode）

**路由参数**:
- `path`: 文件路径
- `name`: 文件名称

**主要方法**:
- `favorite()`: 收藏文件
- `copyLink()`: 复制链接
- `download()`: 下载文件
- `onProgressChanged(controller, p)`: WebView 加载进度回调
- `toggleLayoutMode()`: 切换布局模式

**特殊处理**:
- 代码文件：使用 CodeController 显示代码高亮
- HTML 文件：使用 InAppWebView 显示
- 加入最近浏览

---

### 7. ImagePreviewController (图片预览控制器)
**文件路径**: `lib/pages/image_preview/controller.dart`

**功能**: 预览图片，支持轮播和网格布局

**主要状态**:
- `imageUrls`: 图片URL列表
- `imageHeaders`: 图片请求头
- `userInfo`: 用户信息
- `serverUrl`: 服务器URL
- `layoutMode`: 布局模式（carousel/grid/list）
- `gridCrossAxisCount`: 网格列数
- `currentIndex`: 当前图片索引

**路由参数**:
- `path`: 文件路径
- `name`: 文件名称
- `objects`: 文件对象列表

**主要方法**:
- `onPageChanged(int index)`: 页面切换回调
- `moreActionSheet()`: 显示更多操作菜单
  - 复制链接
  - 保存图片
  - 切换布局模式
- `copyLink()`: 复制链接
- `saveImage()`: 保存图片到相册

**特殊处理**:
- 115云盘：使用 rawUrl
- 其他云盘：使用 getDownloadLink
- 过滤非图片文件
- 加入最近浏览

---

### 8. VideoPlayerController (视频播放控制器)
**文件路径**: `lib/pages/video_player/controller.dart`

**功能**: 播放视频文件，支持播放列表、字幕、音频轨道

**主要状态**:
- `object`: 视频对象
- `userInfo`: 用户信息
- `httpHeaders`: HTTP 请求头
- `serverId`: 服务器ID
- `isLoading`: 是否正在加载
- `isAutoPaused`: 是否自动暂停
- `subtitles`: 字幕列表
- `subtitleNameList`: 字幕名称列表
- `subtitleName`: 当前字幕名称
- `audioTracks`: 音频轨道列表
- `timedTextTracks`: 文本轨道列表
- `showTimedText`: 是否显示文本
- `currentName`: 当前播放文件名
- `currentIndex`: 当前播放索引
- `showPlaylist`: 是否显示播放列表
- `thumbnail`: 缩略图
- `isAutoPlay`: 是否自动播放
- `isBackgroundPlay`: 是否后台播放
- `playMode`: 播放模式
- `currentPos`: 当前播放位置

**路由参数**:
- `path`: 文件路径
- `name`: 文件名称
- `objects`: 文件对象列表
- `file`: 本地文件路径（下载页面点击）
- `downloadId`: 下载ID
- `serverId`: 服务器ID

**主要方法**:
- `changePlaylist(int index)`: 切换播放列表中的视频
- `changeAudioTrack({String? value})`: 切换音频轨道
- `updateSubtitleNameList(List<ObjectModel> related)`: 更新字幕名称列表
- `changeSubtitle({String? value})`: 切换字幕
- `updateProgress()`: 更新播放进度（每5秒保存一次）
- `favorite()`: 收藏视频
- `copyLink()`: 复制链接
- `download()`: 下载视频

**生命周期**:
- `onInit`: 初始化播放器，加载视频，设置通知栏控制
- `onPaused`: 应用暂停时暂停播放
- `onResumed`: 应用恢复时恢复播放
- `onClose`: 清理资源

**特殊处理**:
- 大文件（>30GB）：自动暂停处理
- 播放完成：根据播放模式自动切换下一首
- 通知栏控制：使用 PlayerNotificationService
- WakeLock：播放时保持屏幕常亮

---

### 9. AudioPlayerController (音频播放控制器)
**文件路径**: `lib/pages/audio_player/controller.dart`

**功能**: 播放音频文件，支持播放列表、定时关闭、变速播放

**主要状态**:
- `isPlaylist`: 是否显示播放列表
- `object`: 音频对象
- `isLoading`: 是否正在加载
- `playMode`: 播放模式
- `httpHeaders`: HTTP 请求头
- `serverId`: 服务器ID
- `userInfo`: 用户信息
- `currentName`: 当前播放文件名
- `currentIndex`: 当前播放索引
- `player`: VideoPlayerController（用于音频播放）
- `seekPos`: 跳转位置
- `isPlaying`: 是否正在播放
- `duration`: 总时长
- `currentPos`: 当前位置
- `bufferPos`: 缓冲位置
- `timerDuration`: 定时关闭剩余时间

**路由参数**:
- `path`: 文件路径
- `name`: 文件名称
- `objects`: 文件对象列表
- `file`: 本地文件路径（下载页面点击）
- `downloadId`: 下载ID

**主要方法**:
- `changePlaylist(int index)`: 切换播放列表中的音频
- `timedShutdown()`: 定时关闭
- `changeSpeed()`: 切换播放速度（0.5x-2.0x）
- `updateProgress()`: 更新播放进度（每5秒保存一次）
- `favorite()`: 收藏音频
- `copyLink()`: 复制链接
- `download()`: 下载音频

**生命周期**:
- `onInit`: 初始化播放器，加载音频，设置通知栏控制
- `onClose`: 清理资源

**特殊处理**:
- 播放完成：根据播放模式自动切换下一首
- 通知栏控制：使用 PlayerNotificationService
- TabController：控制播放列表显示

---

### 10. SettingController (设置控制器)
**文件路径**: `lib/pages/setting/controller.dart`

**功能**: 设置页面主控制器

**主要状态**:
- `version`: 版本号
- `serverId`: 服务器ID
- `serverInfo`: 服务器信息
- `isAutoPlay`: 是否自动播放
- `isBackgroundPlay`: 是否后台播放
- `isHardwareDecode`: 是否硬件解码
- `isShowPreview`: 是否显示预览图
- `themeModeText`: 主题模式文本

**主要方法**:
- `changeTheme()`: 更换主题（跟随系统/明亮/深邃）

---

### 11. ServerController (服务器控制器)
**文件路径**: `lib/pages/setting/server/controller.dart`

**功能**: 管理服务器列表

**主要状态**:
- `serverList`: 服务器列表
- `isFirstLoading`: 是否首次加载
- `serverId`: 服务器ID

**主要方法**:
- `getServerList()`: 获取服务器列表
- `switchServer(ServerEntity server)`: 切换服务器
  - 更新 UserStorage
  - 重置首页信息
  - 重置设置页面信息
- `deleteServer(int id)`: 删除服务器
  - 删除服务器数据
  - 删除相关的最近浏览、播放进度、密码管理
  - 如果删除的是当前服务器，重置相关状态

---

### 12. DownloadController (下载控制器)
**文件路径**: `lib/pages/setting/download/controller.dart`

**功能**: 管理下载任务

**主要状态**:
- `entities`: 下载实体列表
- `isFirstLoading`: 是否首次加载
- `totalSize`: 总大小
- `serverId`: 服务器ID

**主要方法**:
- `resetTotalSize()`: 重新计算总大小
- `open(dynamic task, DownloadEntity entity)`: 打开文件
  - 视频：跳转到视频播放页
  - 音频：跳转到音频播放页
- `resume(int id, String taskId)`: 恢复下载
- `delete(int id, String taskId)`: 删除下载

**特殊处理**:
- 支持播放已下载的视频和音频
- 删除下载时同时删除本地文件

---

### 13. AboutController (关于控制器)
**文件路径**: `lib/pages/setting/about/controller.dart`

**功能**: 显示应用信息

**主要状态**:
- `version`: 版本号
- `showVersion`: 是否显示版本号
- `isStoreChannel`: 是否应用商店渠道

**主要方法**: 无

---

### 14. RecentController (最近浏览控制器)
**文件路径**: `lib/pages/setting/recent/controller.dart`

**功能**: 管理最近浏览记录

**主要状态**:
- `isEmpty`: 是否为空
- `serverId`: 服务器ID
- `pagingController`: 分页控制器

**主要方法**:
- `_fetchPage(int pageKey)`: 获取分页数据（每页20条）
- `deleteRecent(RecentEntity entity)`: 删除最近浏览
- `clearRecent()`: 清空最近浏览
- `getObjectList(RecentEntity entity)`: 获取对象列表

**特殊处理**:
- 使用 PagingController 实现分页加载
- 清空时同时删除播放进度

---

### 15. FavoriteController (收藏控制器)
**文件路径**: `lib/pages/setting/favorite/controller.dart`

**功能**: 管理收藏文件

**主要状态**:
- `isEmpty`: 是否为空
- `serverId`: 服务器ID
- `pagingController`: 分页控制器

**主要方法**:
- `_fetchPage(int pageKey)`: 获取分页数据（每页20条）
- `deleteFavorite(FavoriteEntity entity)`: 删除收藏
- `clearFavorite()`: 清空收藏
- `getObjectList(FavoriteEntity entity)`: 获取对象列表
  - 文件夹：列出文件夹内容
  - 文件：列出父目录内容

**特殊处理**:
- 使用 PagingController 实现分页加载
- 文件夹和文件的处理逻辑不同

---

### 16. SettingVideoController (视频预览设置控制器)
**文件路径**: `lib/pages/setting/preview/video/controller.dart`

**功能**: 设置视频支持类型

**主要状态**:
- `videoSupportTypes`: 用户自定义的视频支持类型

**主要方法**:
- `toggleVideoSupportType(String type)`: 切换视频支持类型

---

### 17. SettingImageController (图片预览设置控制器)
**文件路径**: `lib/pages/setting/preview/image/controller.dart`

**功能**: 设置图片支持类型

**主要状态**:
- `imageSupportTypes`: 用户自定义的图片支持类型

**主要方法**:
- `toggleImageSupportType(String type)`: 切换图片支持类型

---

### 18. SettingAudioController (音频预览设置控制器)
**文件路径**: `lib/pages/setting/preview/audio/controller.dart`

**功能**: 设置音频支持类型

**主要状态**:
- `audioSupportTypes`: 用户自定义的音频支持类型

**主要方法**:
- `toggleAudioSupportType(String type)`: 切换音频支持类型

---

### 19. SettingDocumentController (文档预览设置控制器)
**文件路径**: `lib/pages/setting/preview/document/controller.dart`

**功能**: 设置文档支持类型

**主要状态**:
- `documentSupportTypes`: 用户自定义的文档支持类型

**主要方法**:
- `toggleDocumentSupportType(String type)`: 切换文档支持类型

---

## 路由与页面映射关系

| 路由 | 控制器 | 主要功能 | 必需参数 |
|------|--------|----------|----------|
| /homepage | HomepageController | 显示根目录文件列表 | 无 |
| /detail | DetailController | 显示目录内容 | path, name |
| /search | SearchController | 搜索文件 | path |
| /directory | DirectoryController | 显示子目录列表 | path, object |
| /document | DocumentController | 预览文档 | path, name |
| /file | FileController | 显示文件详情 | path, name |
| /image/preview | ImagePreviewController | 预览图片 | path, name, objects |
| /video/player | VideoPlayerController | 播放视频 | path, name, objects |
| /audio/player | AudioPlayerController | 播放音频 | path, name, objects |
| /image_gallery | - | 图片画廊 | 无 |
| /setting | SettingController | 设置页面 | 无 |
| /setting/server | ServerController | 服务器管理 | 无 |
| /setting/download | DownloadController | 下载管理 | 无 |
| /setting/about | AboutController | 关于页面 | 无 |
| /setting/recent | RecentController | 最近浏览 | 无 |
| /setting/favorite | FavoriteController | 收藏 | 无 |
| /setting/preview/image | SettingImageController | 图片预览设置 | 无 |
| /setting/preview/audio | SettingAudioController | 音频预览设置 | 无 |
| /setting/preview/video | SettingVideoController | 视频预览设置 | 无 |
| /setting/preview/document | SettingDocumentController | 文档预览设置 | 无 |

---

## 页面跳转关系

### 从首页跳转
- 点击文件夹 → DetailPage（path, name）
- 点击文件 → 根据文件类型跳转：
  - 图片 → ImagePreviewPage
  - 视频 → VideoPlayerPage
  - 音频 → AudioPlayerPage
  - 文档 → DocumentPage
  - 其他 → FilePage

### 从详情页跳转
- 点击文件夹 → DetailPage（子目录）
- 点击文件 → 根据文件类型跳转（同首页）

### 从搜索页跳转
- 点击搜索结果 → 根据文件类型跳转

### 从最近浏览跳转
- 点击记录 → 根据文件类型跳转

### 从收藏跳转
- 点击记录 → 根据文件类型跳转

### 从设置页跳转
- 点击服务器 → ServerPage
- 点击下载 → DownloadPage
- 点击关于 → AboutPage
- 点击最近浏览 → RecentPage
- 点击收藏 → FavoritePage
- 点击预览设置 → 对应的预览设置页面

### 从下载页跳转
- 点击已下载的视频 → VideoPlayerPage（file, downloadId）
- 点击已下载的音频 → AudioPlayerPage（file, downloadId）

---

## 数据流

### 用户信息流
UserStorage → 各控制器通过 Get.find<UserStorage>() 获取

### 服务器信息流
DatabaseService → ServerController → UserStorage → 各控制器

### 文件列表流
ObjectRepository → Controller → View

### 播放进度流
Controller → DatabaseService（每5秒保存）

### 最近浏览流
Controller → CommonUtils.addRecent → DatabaseService

### 收藏流
Controller → CommonUtils.addFavorite → DatabaseService

---

## 共享服务

### DatabaseService
- 数据库服务，管理所有本地数据

### DownloadService
- 下载服务，管理下载任务和进度

### PlayerNotificationService
- 播放通知服务，管理通知栏控制

### DioService
- HTTP 请求服务

---

## 常用工具类

### CommonUtils
- sortObjectList: 排序文件列表
- getDownloadLink: 获取下载链接
- formatFileNme: 格式化文件名
- addRecent: 添加最近浏览
- addFavorite: 添加收藏

### PreviewHelper
- isImage: 判断是否为图片
- isVideo: 判断是否为视频
- isAudio: 判断是否为音频
- isCode: 判断是否为代码文件
- isHtml: 判断是否为HTML文件

### DownloadHelper
- file: 下载文件

### ObjectHelper
- copy: 复制文件
- move: 移动文件

### DriverHelper
- getHeaders: 获取请求头

---

## 存储类

### UserStorage
- id: 用户ID
- token: 用户令牌
- serverId: 服务器ID
- serverUrl: 服务器URL

### PreferencesStorage
- sortType: 排序方式
- layoutType: 布局方式
- isShowPreview: 是否显示预览图
- isAutoPlay: 是否自动播放
- isBackgroundPlay: 是否后台播放
- isHardwareDecode: 是否硬件解码
- videoSupportTypes: 视频支持类型
- imageSupportTypes: 图片支持类型
- audioSupportTypes: 音频支持类型
- documentSupportTypes: 文档支持类型

### CommonStorage
- themeMode: 主题模式

---

## 数据库实体

### ServerEntity
- 服务器信息

### DownloadEntity
- 下载信息

### FavoriteEntity
- 收藏信息

### RecentEntity
- 最近浏览信息

### ProgressEntity
- 播放进度信息

### PasswordManagerEntity
- 密码管理信息

---

## 常量

### SortType
- NAME_ASC: 名称升序
- NAME_DESC: 名称降序
- SIZE_ASC: 大小升序
- SIZE_DESC: 大小降序
- TIME_ASC: 时间升序
- TIME_DESC: 时间降序

### FileType
- FOLDER: 文件夹
- IMAGE: 图片
- VIDEO: 视频
- AUDIO: 音频
- DOCUMENT: 文档
- OTHER: 其他

### LayoutType
- GRID: 网格布局
- LIST: 列表布局

### PlayMode
- SINGLE_LOOP: 单曲循环
- LIST_LOOP: 列表循环
- SHUFFLE: 随机播放

### ThemeMode
- system: 跟随系统
- light: 明亮
- dark: 深邃

---

## 注意事项

1. **路由参数传递**: 使用 Get.arguments 传递参数，确保参数名称与控制器中定义的一致

2. **权限处理**: 目录可能需要密码，403 错误时弹出密码输入框

3. **未登录处理**: 401 错误时强制刷新 token

4. **大文件处理**: 视频 >30GB 时自动暂停，避免内存问题

5. **播放进度**: 每5秒自动保存播放进度到数据库

6. **最近浏览**: 打开文件时自动添加到最近浏览

7. **通知栏控制**: 音频和视频播放时显示通知栏控制

8. **WakeLock**: 视频播放时保持屏幕常亮

9. **分页加载**: 最近浏览和收藏使用分页加载，每页20条

10. **115云盘特殊处理**: 图片预览使用 rawUrl，其他云盘使用 getDownloadLink

---

## 潜在问题

### 已修复
1. ~~**路由不一致**: `/image_gallery` 路由在 app_pages.dart 中定义，但未在 Routes 中声明~~ ✅ 已修复

### 待修复
2. **参数验证**: 部分页面缺少参数验证，可能导致空指针异常

3. **错误处理**: 部分异常被捕获但未显示给用户

4. **内存泄漏**: 部分控制器未正确释放资源（如 Timer、StreamSubscription）

5. **并发问题**: 多个页面同时访问同一资源时可能存在并发问题

---

## 改进建议

1. **统一参数传递**: 使用统一的参数模型类，避免直接使用 Map

2. **增强错误处理**: 统一错误处理机制，提供友好的错误提示

3. **资源管理**: 确保所有控制器正确释放资源

4. **路由验证**: 添加路由参数验证，确保必需参数存在

5. **日志系统**: 添加统一的日志系统，便于调试

6. **单元测试**: 为关键逻辑添加单元测试

---

*文档生成时间: 2026-01-30*
