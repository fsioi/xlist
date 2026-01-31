import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:xlist/models/index.dart';
import 'package:xlist/common/index.dart';
import 'package:xlist/models/object.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:xlist/constants/index.dart';
import 'package:xlist/services/core_service.dart';
import 'package:xlist/database/entity/index.dart';

class HomepageController extends GetxController {
  final objects = Rx<List<ObjectModel>>([]);
  final isFirstLoading = true.obs;
  final serverId = 0.obs;
  final layoutType = 'grid'.obs;
  final isShowPreview = true.obs;
  final userInfo = Rx<dynamic>(null);
  final errorMessage = "".obs;
  final currentPath = "".obs;
  final searchQuery = "".obs;
  final isSearching = false.obs;

  final EasyRefreshController easyRefreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );
  final ScrollController scrollController = ScrollController();

  CoreService? coreService;

  @override
  void onInit() {
    super.onInit();
    print('=== Initializing HomepageController ===');

    // 初始化 CoreService
    _initCoreService();

    // 延迟获取文件列表，确保CoreService已完全初始化
    Future.delayed(Duration(milliseconds: 500), () {
      print('=== Delayed getObjectList call ===');
      getObjectList();
    });
    print('=== HomepageController initialization completed ===');
  }

  // 初始化 CoreService
  void _initCoreService() {
    try {
      coreService = CoreService.to;
      serverId.value = coreService?.userStorage.serverId.value ?? 0;
      print('✓ CoreService initialized');
    } catch (e) {
      print('⚠ Error initializing CoreService: $e');
      coreService = null;
      errorMessage.value = '核心服务初始化失败';
    }
  }

  // 检查服务器是否配置
  bool get isServerConfigured {
    bool configured = coreService != null && coreService!.currentServer.value != null;
    print('=== Server configuration check: $configured ===');
    if (coreService != null) {
      print('CoreService available: ${coreService != null}');
      print('Current server: ${coreService!.currentServer.value?.url ?? 'null'}');
      print('Current user: ${coreService!.currentUser.value != null}');
    }
    return configured;
  }

  // 获取当前服务器
  ServerEntity? get currentServer {
    return coreService?.currentServer.value;
  }

  Future<void> getObjectList({bool refresh = false, String path = '/'}) async {
    print('=== Starting getObjectList() for path: $path ===');
    isFirstLoading.value = true;
    errorMessage.value = '';
    currentPath.value = path;

    try {
      print('=== Getting WebDAV files from path: $path ===');
      
      // 检查 CoreService 是否初始化
      if (coreService == null) {
        print('⚠ CoreService not initialized, trying to reinitialize...');
        _initCoreService();
        if (coreService == null) {
          throw Exception('核心服务不可用');
        }
        print('✓ CoreService reinitialized');
      } else {
        print('✓ CoreService already initialized');
      }

      // 确保服务器配置已经加载
      print('Checking server configuration...');
      if (coreService!.currentServer.value == null) {
        print('⚠ Server not loaded, trying to load recent server...');
        await coreService!.loadRecentServer();
        if (coreService!.currentServer.value == null) {
          print('⚠ No server configured after loading');
          objects.value = [];
          return;
        }
        print('✓ Server loaded after loadRecentServer');
      } else {
        print('✓ Server already loaded: ${coreService!.currentServer.value!.url}');
        // 即使服务器已经加载，也再次确认，确保配置正确
        await coreService!.loadRecentServer();
        if (coreService!.currentServer.value == null) {
          print('⚠ Server lost after reload');
          objects.value = [];
          return;
        }
        print('✓ Server still loaded after reload: ${coreService!.currentServer.value!.url}');
      }

      // 使用 CoreService 获取 WebDAV 文件列表
      print('✓ Server configured: ${coreService!.currentServer.value!.url}');
      print('Sending WebDAV request...');
      
      // 测试WebDAV连接
      final server = coreService!.currentServer.value!;
      print('Testing WebDAV connection for: ${server.url}');
      
      // 生产阶段使用真实数据
      final files = await coreService!.getWebDAVFiles(
        path,
        onError: (error) {
          print('⚠ WebDAV error: $error');
          errorMessage.value = error.message;
        },
      );
      
      // 开发阶段使用模拟数据，验证UI是否正常
      // final files = await coreService!.getMockWebDAVFiles(path);
      
      objects.value = files;
      print('✓ Got ${files.length} files from WebDAV');
      print('Files: ${files.map((f) => f.name).toList()}');
    } catch (e) {
      print('✗ Error getting object list: $e');
      objects.value = [];
      errorMessage.value = '获取文件列表失败: ${e.toString()}';
    } finally {
      isFirstLoading.value = false;
      print('=== File list retrieval completed ===');
    }
  }

  Future<dynamic> resetUserToken(dynamic server, {bool force = false}) async {
    try {
      print('Resetting user token for server: ${server?.url ?? 'unknown'}');
      
      if (coreService == null) {
        _initCoreService();
        if (coreService == null) {
          throw Exception('CoreService not available');
        }
      }

      await coreService!.refreshAllData();
      serverId.value = coreService!.userStorage.serverId.value;
      print('✓ User token reset');
      return coreService!.currentUser.value;
    } catch (e) {
      print('✗ Error resetting user token: $e');
      return null;
    }
  }

  Future<void> addToFavorites(ObjectModel object) async {
    try {
      if (coreService == null) {
        _initCoreService();
        if (coreService == null) {
          throw Exception('CoreService not available');
        }
      }

      await coreService!.addToFavorites(object);
      print('✓ Added ${object.name} to favorites');
    } catch (e) {
      print('✗ Error adding to favorites: $e');
    }
  }

  Future<void> addToRecent(ObjectModel object) async {
    try {
      if (coreService == null) {
        _initCoreService();
        if (coreService == null) {
          throw Exception('CoreService not available');
        }
      }

      await coreService!.addToRecent(object);
      print('✓ Added ${object.name} to recent');
    } catch (e) {
      print('✗ Error adding to recent: $e');
    }
  }

  Future<void> downloadObject(ObjectModel object) async {
    try {
      if (coreService == null) {
        _initCoreService();
        if (coreService == null) {
          throw Exception('CoreService not available');
        }
      }

      await coreService!.downloadFile(object);
      print('✓ Started download for ${object.name}');
    } catch (e) {
      print('✗ Error downloading object: $e');
    }
  }

  // 切换布局类型
  void toggleLayoutType() {
    layoutType.value = layoutType.value == 'grid' ? 'list' : 'grid';
    print('✓ Layout type changed to ${layoutType.value}');
  }

  // 切换预览显示
  void togglePreview() {
    isShowPreview.value = !isShowPreview.value;
    print('✓ Preview toggled to ${isShowPreview.value}');
  }

  // 导航到上级目录
  void navigateUp() {
    if (currentPath.value != '/') {
      final path = currentPath.value.substring(0, currentPath.value.lastIndexOf('/'));
      getObjectList(path: path.isEmpty ? '/' : path);
    }
  }

  // 导航到路径
  void navigateToPath(String path) {
    getObjectList(path: path);
  }

  // 处理搜索
  Future<void> handleSearch(String query) async {
    if (query.isEmpty) {
      // 如果查询为空，显示当前路径的文件
      getObjectList(path: currentPath.value);
      return;
    }

    isSearching.value = true;
    try {
      // 全局搜索实现，递归搜索所有子目录
      final allFiles = await _searchRecursive('/');
      final filteredFiles = allFiles.where((file) {
        return file.name?.toLowerCase().contains(query.toLowerCase()) ?? false;
      }).toList();
      objects.value = filteredFiles;
    } catch (e) {
      print('Error searching files: $e');
      objects.value = [];
    } finally {
      isSearching.value = false;
    }
  }

  // 递归搜索所有子目录
  Future<List<ObjectModel>> _searchRecursive(String path) async {
    final results = <ObjectModel>[];
    
    try {
      final files = await coreService!.getWebDAVFiles(path);
      
      for (final file in files) {
        results.add(file);
        
        // 如果是目录，递归搜索
        if (file.isDir == true) {
          final subPath = path == '/' ? '/${file.name}' : '$path/${file.name}';
          final subResults = await _searchRecursive(subPath);
          results.addAll(subResults);
        }
      }
    } catch (e) {
      print('Error in recursive search for path $path: $e');
    }
    
    return results;
  }

  // 处理地址栏输入
  void handleAddressInput(String input) {
    if (input.isEmpty) return;

    // 检查是否是路径
    if (input.startsWith('/')) {
      // 是路径，导航到该路径
      navigateToPath(input);
    } else {
      // 不是路径，执行搜索
      handleSearch(input);
    }
  }
} 
