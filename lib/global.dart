import 'dart:io';
import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'package:xlist/services/browser_service.dart';
import 'package:xlist/services/database_service.dart';
import 'package:xlist/services/device_info_service.dart';
import 'package:xlist/services/dio_service.dart';
import 'package:xlist/services/download_service.dart';
// 暂时移除 PlayerNotificationService 的导入，避免音频服务错误
// import 'package:xlist/services/player_notification_service.dart';
import 'package:xlist/storages/common_storage.dart';
import 'package:xlist/storages/preferences_storage.dart';
import 'package:xlist/storages/user_storage.dart'; // 添加 UserStorage 导入
import 'package:xlist/constants/common.dart';
import 'package:xlist/models/user.dart'; // 添加 UserModel 和 UserRole 导入
import 'package:xlist/repositorys/user_repository.dart'; // 添加 UserRepository 导入

// 全局配置
class Global {
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;
  static bool get isDebug => kDebugMode;

  // 运行初始化
  static Future<void> init() async {
    // Init FlutterBinding
    WidgetsFlutterBinding.ensureInitialized();


    // GetStorage
    await GetStorage.init();

    // Storage
    await Get.put(CommonStorage());
    await Get.putAsync(() => PreferencesStorage().init());
    await Get.put(UserStorage()); // 初始化 UserStorage

    // Init Getx Service
    await Get.put(BrowserService());
    await Get.putAsync(() => DioService().init());
    await Get.putAsync(() => DatabaseService().init());
    await Get.putAsync(() => DownloadService().init());
    await Get.putAsync(() => DeviceInfoService().init());
    // 暂时注释掉 PlayerNotificationService 的初始化，避免音频服务错误
    // await Get.putAsync(() => PlayerNotificationService().init());


    // Theme
    Get.changeThemeMode(ThemeModeMap[Get.find<CommonStorage>().themeMode.val]!);

    // android 状态栏为透明的沉浸
    if (GetPlatform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle =
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }
}
