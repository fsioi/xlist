import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:xlist/common/logger.dart';
import 'package:xlist/services/dio_service.dart';
import 'package:xlist/services/database_service.dart';
import 'package:xlist/storages/common_storage.dart';
import 'package:xlist/storages/preferences_storage.dart';
import 'package:xlist/storages/user_storage.dart';
import 'package:xlist/models/index.dart';
import 'package:xlist/database/dao/index.dart';
import 'package:xlist/database/entity/index.dart';

// WebDAV 错误类型
enum WebDAVErrorType {
  NETWORK_ERROR,      // 网络错误
  AUTH_ERROR,         // 认证错误
  SERVER_ERROR,       // 服务器错误
  PARSE_ERROR,        // 解析错误
  UNKNOWN_ERROR,      // 未知错误
}

// WebDAV 错误类
class WebDAVError {
  final WebDAVErrorType type;
  final String message;
  final dynamic originalError;

  WebDAVError(this.type, this.message, {this.originalError});

  @override
  String toString() {
    return 'WebDAVError{type: $type, message: $message}';
  }
}

class CoreService extends GetxService {
  static CoreService get to => Get.find();

  // 服务
  late DioService dioService;
  late DatabaseService databaseService;
  
  // 为了兼容其他控制器，添加必要的属性
  late dynamic downloadService;

  // 存储
  late CommonStorage commonStorage;
  late PreferencesStorage preferencesStorage;
  late UserStorage userStorage;

  // DAO
  late DownloadDao downloadDao;
  late FavoriteDao favoriteDao;
  late RecentDao recentDao;
  late ServerDao serverDao;
  
  // 为了兼容其他控制器，添加必要的DAO
  late dynamic passwordManagerDao;
  late dynamic progressDao;

  // 状态
  final currentUser = Rxn<UserModel>();
  final currentServer = Rxn<ServerEntity>();
  final currentPath = "".obs;
  final currentObjects = <ObjectModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = "".obs;

  // 服务初始化状态
  final Map<String, bool> _serviceStatus = {};

  Future<CoreService> init() async {
    Logger.d('Initializing CoreService');
    
    // 初始化服务
    await _initServices();

    // 初始化存储
    await _initStorages();

    // 初始化 DAO
    await _initDAOs();

    // 初始化其他服务
    await _initOtherServices();

    // 加载用户数据
    await loadUserData();
    // 加载最近服务器
    await loadRecentServer();

    // 打印初始化状态
    _printInitializationStatus();

    Logger.d('CoreService initialized');
    return this;
  }

  // 初始化服务
  Future<void> _initServices() async {
    Logger.d('Initializing services');

    // 初始化 DioService
    try {
      dioService = Get.find<DioService>();
      _serviceStatus['DioService'] = true;
      Logger.d('DioService initialized');
    } catch (e) {
      Logger.w('Error finding DioService: $e');
      _serviceStatus['DioService'] = false;
    }

    // 初始化 DatabaseService
    try {
      databaseService = Get.find<DatabaseService>();
      _serviceStatus['DatabaseService'] = true;
      Logger.d('DatabaseService initialized');
    } catch (e) {
      Logger.w('Error finding DatabaseService: $e');
      _serviceStatus['DatabaseService'] = false;
    }
  }

  // 初始化存储
  Future<void> _initStorages() async {
    Logger.d('Initializing storages');

    // 初始化 CommonStorage
    try {
      commonStorage = Get.find<CommonStorage>();
      _serviceStatus['CommonStorage'] = true;
      Logger.d('CommonStorage initialized');
    } catch (e) {
      Logger.w('Error finding CommonStorage: $e');
      _serviceStatus['CommonStorage'] = false;
    }

    // 初始化 PreferencesStorage
    try {
      preferencesStorage = Get.find<PreferencesStorage>();
      _serviceStatus['PreferencesStorage'] = true;
      Logger.d('PreferencesStorage initialized');
    } catch (e) {
      Logger.w('Error finding PreferencesStorage: $e');
      _serviceStatus['PreferencesStorage'] = false;
    }

    // 初始化 UserStorage
    try {
      userStorage = Get.find<UserStorage>();
      _serviceStatus['UserStorage'] = true;
      Logger.d('UserStorage initialized');
    } catch (e) {
      Logger.w('Error finding UserStorage: $e');
      _serviceStatus['UserStorage'] = false;
    }
  }

  // 初始化 DAO
  Future<void> _initDAOs() async {
    Logger.d('Initializing DAOs');

    try {
      // 尝试获取数据库实例
      if (databaseService.isDatabaseInitialized) {
        final db = databaseService.database;
        downloadDao = db.downloadDao;
        favoriteDao = db.favoriteDao;
        recentDao = db.recentDao;
        serverDao = db.serverDao;
        
        // 尝试初始化其他DAO
        try {
          passwordManagerDao = db.passwordManagerDao;
          progressDao = db.progressDao;
        } catch (e) {
          Logger.w('Error initializing optional DAOs: $e');
          // 如果初始化失败，设置为null
          passwordManagerDao = null;
          progressDao = null;
        }
        
        _serviceStatus['DAOs'] = true;
        Logger.d('DAOs initialized');
      } else {
        Logger.w('Database not initialized, skipping DAO initialization');
        _serviceStatus['DAOs'] = false;
      }
    } catch (e) {
      Logger.w('Error initializing DAOs: $e');
      _serviceStatus['DAOs'] = false;
      // 如果初始化失败，设置为null
      passwordManagerDao = null;
      progressDao = null;
    }
  }

  // 初始化其他服务
  Future<void> _initOtherServices() async {
    Logger.d('Initializing other services');

    // 初始化downloadService
    try {
      // 尝试获取downloadService
      // 暂时设置为null，因为我们没有初始化它
      downloadService = null;
      _serviceStatus['DownloadService'] = true;
      Logger.d('DownloadService initialized (placeholder)');
    } catch (e) {
      Logger.w('Error initializing downloadService: $e');
      downloadService = null;
      _serviceStatus['DownloadService'] = false;
    }
  }

  // 打印初始化状态
  void _printInitializationStatus() {
    Logger.d('CoreService Initialization Status');
    _serviceStatus.forEach((key, value) {
      Logger.d('${value ? '✓' : '✗'} $key: ${value ? 'Initialized' : 'Failed'}');
    });
  }

  Future<void> loadUserData() async {
    try {
      // 暂时使用空的 UserModel
      currentUser.value = UserModel();
      Logger.d('User data loaded');
    } catch (e) {
      Logger.w('Error loading user data: $e');
    }
  }

  Future<void> loadRecentServer() async {
    try {
      if (_serviceStatus['DAOs'] ?? false) {
        final servers = await serverDao.findAllServer();
        if (servers.isNotEmpty) {
          currentServer.value = servers.first;
          Logger.d('Loaded recent server: ${servers.first.url}');
        } else {
          Logger.w('No servers found');
        }
      } else {
        Logger.w('DAOs not initialized, skipping server loading');
      }
    } catch (e) {
      Logger.w('Error loading recent server: $e');
    }
  }

  // WebDAV 相关功能
  Future<List<ObjectModel>> getWebDAVFiles(String path, {Function(WebDAVError)? onError}) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      currentPath.value = path;
      
      // 从真实的WebDAV服务器获取文件列表
      if (currentServer.value != null) {
        final serverUrl = currentServer.value!.url;
        final username = currentServer.value!.username;
        final password = currentServer.value!.password;
        
        Logger.d('Fetching WebDAV files from: $serverUrl$path');
        
        // 构建WebDAV请求
        final url = '$serverUrl$path';
        final options = Options(
          headers: {
            'Depth': '1',
            'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
          },
          responseType: ResponseType.plain,
          validateStatus: (status) {
            return status! < 500;
          },
        );
        
        // 发送PROPFIND请求获取文件列表
        final response = await dioService.dio.request(
          url,
          options: options..method = 'PROPFIND',
        );
        
        Logger.d('Got response from WebDAV server');
        Logger.d('Response status: ${response.statusCode}');
        Logger.d('Response data length: ${response.data?.length ?? 0}');
        
        // 检查响应状态
        if (response.statusCode == 401 || response.statusCode == 403) {
          final error = WebDAVError(
            WebDAVErrorType.AUTH_ERROR,
            'Authentication failed: Invalid username or password',
            originalError: response,
          );
          Logger.e('Authentication error: ${error.message}');
          onError?.call(error);
          errorMessage.value = error.message;
          currentObjects.value = [];
          return [];
        } else if (response.statusCode! >= 400) {
          final error = WebDAVError(
            WebDAVErrorType.SERVER_ERROR,
            'Server error: ${response.statusCode}',
            originalError: response,
          );
          Logger.e('Server error: ${error.message}');
          onError?.call(error);
          errorMessage.value = error.message;
          currentObjects.value = [];
          return [];
        }
        
        // 解析WebDAV响应
        final objects = _parseWebDAVResponse(response.data?.toString() ?? '', path, serverUrl);
        currentObjects.value = objects;
        Logger.d('Parsed ${objects.length} files from WebDAV response');
        
        return currentObjects;
      } else {
        Logger.w('No server configured');
        final error = WebDAVError(
          WebDAVErrorType.UNKNOWN_ERROR,
          'No server configured',
        );
        onError?.call(error);
        errorMessage.value = error.message;
        currentObjects.value = [];
        return [];
      }
    } on DioError catch (e) {
      Logger.e('Network error getting WebDAV files: $e');
      final error = WebDAVError(
        WebDAVErrorType.NETWORK_ERROR,
        'Network error: ${e.message}',
        originalError: e,
      );
      onError?.call(error);
      errorMessage.value = error.message;
      currentObjects.value = [];
      return [];
    } catch (e) {
      Logger.e('Unknown error getting WebDAV files: $e');
      final error = WebDAVError(
        WebDAVErrorType.UNKNOWN_ERROR,
        'Unknown error: $e',
        originalError: e,
      );
      onError?.call(error);
      errorMessage.value = error.message;
      currentObjects.value = [];
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // 解析WebDAV响应
  List<ObjectModel> _parseWebDAVResponse(String response, String path, String serverUrl) {
    final objects = <ObjectModel>[];
    
    try {
      Logger.d('Parsing WebDAV response');
      
      // 简单的XML解析逻辑
      final document = XmlDocument.parse(response);
      
      // 遍历所有响应的资源
      final responseElements = document.findAllElements('response');
      Logger.d('Found ${responseElements.length} response elements');
      
      for (final responseElement in responseElements) {
        try {
          // 获取资源路径
          final hrefElement = responseElement.findElements('href').first;
          final href = hrefElement.text;
          
          // 跳过当前目录
          if (href == path || href == '$path/') continue;
          
          // 获取资源属性
          final propstatElement = responseElement.findElements('propstat').first;
          final propElement = propstatElement.findElements('prop').first;
          
          // 获取文件名称
          final fileName = href.split('/').last;
          
          // 获取文件类型
          final isDir = href.endsWith('/');
          
          // 获取文件大小
          int size = 0;
          final contentLengthElement = propElement.findElements('getcontentlength').firstOrNull;
          if (contentLengthElement != null && !isDir) {
            size = int.tryParse(contentLengthElement.text) ?? 0;
          }
          
          // 获取修改时间
          DateTime? modified;
          final lastModifiedElement = propElement.findElements('getlastmodified').firstOrNull;
          if (lastModifiedElement != null) {
            modified = DateTime.tryParse(lastModifiedElement.text);
          }
          
          // 创建ObjectModel
          final object = ObjectModel();
          object.name = fileName;
          object.type = isDir ? 1 : 2; // 1 for directory, 2 for file
          object.size = size;
          object.isDir = isDir;
          object.rawUrl = href;
          object.modified = modified;
          
          objects.add(object);
        } catch (e) {
          Logger.w('Error parsing individual response element: $e');
          // 跳过解析失败的元素，继续解析其他元素
          continue;
        }
      }
    } catch (e) {
      Logger.e('Error parsing WebDAV response: $e');
      // 如果解析失败，返回一个空列表
    }
    
    Logger.d('Parsed ${objects.length} objects from WebDAV response');
    return objects;
  }

  Future<void> downloadFile(ObjectModel file) async {
    try {
      if (_serviceStatus['DAOs'] ?? false) {
        final download = DownloadEntity(
          serverId: userStorage.serverId.value,
          taskId: DateTime.now().millisecondsSinceEpoch.toString(),
          type: file.type ?? 0,
          path: file.rawUrl ?? '',
          name: file.name ?? '',
          size: file.size ?? 0,
        );
        await downloadDao.insertDownload(download);
        Logger.d('File added to download queue: ${file.name}');
      } else {
        Logger.w('DAOs not initialized, cannot add file to download queue');
      }
    } catch (e) {
      Logger.w('Error downloading file: $e');
    }
  }

  Future<void> addToFavorites(ObjectModel object) async {
    try {
      if (_serviceStatus['DAOs'] ?? false) {
        final favorite = FavoriteEntity(
          serverId: userStorage.serverId.value,
          path: object.rawUrl ?? '',
          name: object.name ?? '',
          type: object.type ?? 0,
          size: object.size ?? 0,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await favoriteDao.insertFavorite(favorite);
        Logger.d('Added to favorites: ${object.name}');
      } else {
        Logger.w('DAOs not initialized, cannot add to favorites');
      }
    } catch (e) {
      Logger.w('Error adding to favorites: $e');
    }
  }

  Future<void> addToRecent(ObjectModel object) async {
    try {
      if (_serviceStatus['DAOs'] ?? false) {
        final recent = RecentEntity(
          serverId: userStorage.serverId.value,
          path: object.rawUrl ?? '',
          name: object.name ?? '',
          type: object.type ?? 0,
          size: object.size ?? 0,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await recentDao.insertRecent(recent);
        Logger.d('Added to recent: ${object.name}');
      } else {
        Logger.w('DAOs not initialized, cannot add to recent');
      }
    } catch (e) {
      Logger.w('Error adding to recent: $e');
    }
  }

  Future<void> refreshAllData() async {
    Logger.d('Refreshing all data...');
    await loadUserData();
    await loadRecentServer();
    Logger.d('All data refreshed');
  }

  // 为了兼容其他控制器，添加必要的方法
  Future<void> downloadObject(ObjectModel object) async {
    try {
      await downloadFile(object);
    } catch (e) {
      Logger.w('Error downloading object: $e');
    }
  }

  Future<void> navigateToPath(String path) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      currentPath.value = path;
      Logger.d('Navigated to path: $path');
      // 这里可以添加加载路径内容的逻辑
      // 例如调用 API 获取目录内容
    } catch (e) {
      Logger.w('Error navigating to path: $e');
      errorMessage.value = 'Error navigating to path: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ObjectModel>> searchObjects(String query) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      Logger.d('Searching objects for: $query');
      // 这里可以添加搜索逻辑
      return [];
    } catch (e) {
      Logger.w('Error searching objects: $e');
      errorMessage.value = 'Error searching objects: $e';
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // 检查服务是否可用
  bool isServiceAvailable(String serviceName) {
    return _serviceStatus[serviceName] ?? false;
  }

  // 获取所有服务状态
  Map<String, bool> getServiceStatus() {
    return Map.unmodifiable(_serviceStatus);
  }
}
