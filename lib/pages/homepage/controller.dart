import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:xlist/models/index.dart';
import 'package:xlist/common/index.dart';
import 'package:xlist/models/object.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:xlist/constants/index.dart';
import 'package:xlist/services/core_service.dart';

class HomepageController extends GetxController {
  final objects = Rx<List<ObjectModel>>([]);
  final isFirstLoading = true.obs;
  final serverId = 0.obs;
  final layoutType = 'grid'.obs;
  final isShowPreview = true.obs;
  final userInfo = Rx<dynamic>(null);
  final errorMessage = "".obs;
  final currentPath = "".obs;

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

    // 获取文件列表
    getObjectList();
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
      errorMessage.value = 'Failed to initialize core service';
    }
  }

  Future<void> getObjectList({bool refresh = false, String path = '/'}) async {
    isFirstLoading.value = true;
    errorMessage.value = '';
    currentPath.value = path;

    try {
      print('Getting WebDAV files from path: $path');
      
      // 检查 CoreService 是否初始化
      if (coreService == null) {
        print('⚠ CoreService not initialized, trying to reinitialize...');
        _initCoreService();
        if (coreService == null) {
          throw Exception('CoreService not available');
        }
      }

      // 使用 CoreService 获取 WebDAV 文件列表
      final files = await coreService!.getWebDAVFiles(
        path,
        onError: (error) {
          print('⚠ WebDAV error: $error');
          errorMessage.value = error.message;
        },
      );
      
      objects.value = files;
      print('✓ Got ${files.length} files from WebDAV');
    } catch (e) {
      print('✗ Error getting object list: $e');
      objects.value = [];
      errorMessage.value = 'Failed to get files: ${e.toString()}';
    } finally {
      isFirstLoading.value = false;
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
}
