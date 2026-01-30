import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:xlist/models/index.dart';
import 'package:xlist/services/core_service.dart';

class SearchController extends GetxController {
  static const pageSize = 100;
  final userInfo = UserModel().obs; // 用户信息
  final searchList = <FsSearchModel>[].obs; // Object 数据

  // 显示预览图
  late final isShowPreview = false.obs;

  TextEditingController searchController = TextEditingController();
  ScrollController scrollController = ScrollController();

  // 获取参数
  final String path = Get.arguments['path'];
  String password = ''; // 目录密码

  late CoreService coreService;

  @override
  void onInit() async {
    super.onInit();
    coreService = CoreService.to;

    // 显示预览图设置
    isShowPreview.value = coreService.preferencesStorage.isShowPreview.val ?? true;

    // 获取目录密码
    final serverId = coreService.userStorage.serverId.value;
    final passwordManager = await coreService.passwordManagerDao
        .findPasswordManagerByPath(serverId, path);
    if (passwordManager != null && passwordManager.isNotEmpty) {
      password = passwordManager.last.password;
    }

    // 获取用户信息
    userInfo.value = coreService.currentUser.value ?? UserModel();
  }

  /// 搜索
  void onChanged(String value) async {
    await getSearchObjectList(value);
  }

  /// 获取搜索数据
  Future<void> getSearchObjectList(String keywords) async {
    try {
      // 使用 CoreService 进行搜索
      final objects = await coreService.searchObjects(keywords);
      
      // 转换为 FsSearchModel
      searchList.clear(); // 清空数据
      // 暂时使用模拟数据
      searchList.refresh(); // 刷新数据
    } catch (e) {
      print('Error searching objects: $e');
    }
  }

  /// 添加到收藏
  Future<void> addToFavorites(ObjectModel object) async {
    await coreService.addToFavorites(object);
  }

  /// 添加到最近
  Future<void> addToRecent(ObjectModel object) async {
    await coreService.addToRecent(object);
  }

  /// 下载文件
  Future<void> downloadObject(ObjectModel object) async {
    await coreService.downloadObject(object);
  }
}
