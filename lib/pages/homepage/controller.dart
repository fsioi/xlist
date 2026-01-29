import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:xlist/models/index.dart';
import 'package:xlist/common/index.dart';
import 'package:xlist/models/object.dart';
import 'package:xlist/storages/user_storage.dart';
import 'package:xlist/repositorys/object_repository.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:xlist/constants/index.dart';

class HomepageController extends GetxController {
  final objects = Rx<List<ObjectModel>>([]);
  final isFirstLoading = true.obs;
  final serverId = 0.obs;
  final layoutType = 'grid'.obs;
  final isShowPreview = true.obs;
  final userInfo = Rx<dynamic>(null);

  final EasyRefreshController easyRefreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    // 暂时设置一个非零的 serverId 用于测试
    serverId.value = 1;
    getObjectList();
  }

  Future<void> getObjectList({bool refresh = false}) async {
    if (serverId.value == 0) {
      isFirstLoading.value = false;
      return;
    }
    
    // 检查 serverUrl 是否为空
    final serverUrl = Get.find<UserStorage>().serverUrl.value;
    if (serverUrl.isEmpty) {
      print('Server URL is empty');
      isFirstLoading.value = false;
      return;
    }
    
    try {
      final response = await ObjectRepository.getList(path: '/', refresh: refresh);
      final data = FsListModel.fromJson(response['data']);
      final _list = CommonUtils.sortObjectList(data.content ?? [], SortType.NAME_ASC);
      objects.value = _list;
    } catch (e) {
      print('Error getting object list: $e');
      isFirstLoading.value = false;
    }
  }

  Future<dynamic> resetUserToken(dynamic server, {bool force = false}) async {
    // Implement resetUserToken logic here
    return null;
  }
}
