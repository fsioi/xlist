import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:xlist/common/index.dart';
import 'package:xlist/storages/index.dart';
import 'package:xlist/routes/app_pages.dart';
import 'package:xlist/pages/homepage/index.dart';

class Homepage extends GetView<HomepageController> {
  const Homepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Get.isDarkMode ? Color.fromARGB(255, 18, 18, 18) : Colors.white,
        border: Border.all(width: 0, color: Colors.transparent),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Icon(CupertinoIcons.umbrella_fill, size: CommonUtils.navIconSize),
              onPressed: () => Get.toNamed(Routes.SETTING)
                  ?.then((value) => controller.getObjectList()),
            ),
            CupertinoButton(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Icon(CupertinoIcons.download_circle, size: CommonUtils.navIconSize),
              onPressed: () => Get.toNamed(Routes.SETTING_DOWNLOAD),
            ),
          ],
        ),
        middle: Text(
          'homepage_title'.tr,
          style: TextStyle(color: Get.theme.textTheme.bodyLarge?.color),
        ),
      ),
      child: SafeArea(
        child: Obx(() {
          final userStorage = Get.find<UserStorage>();
          final hasServer = controller.serverId.value != 0 && userStorage.serverUrl.value.isNotEmpty;
          
          if (controller.isFirstLoading.isTrue) {
            return Center(
              child: CupertinoActivityIndicator(),
            );
          }
          
          if (!hasServer) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'homepage_empty_server_title'.tr,
                    style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20.h),
                  CupertinoButton(
                    child: Text('添加服务器'),
                    onPressed: () async {
                      // 直接导航到服务器设置页面
                      await Get.toNamed(Routes.SETTING_SERVER);
                      // 刷新主页数据
                      controller.getObjectList();
                    },
                  ),
                ],
              ),
            );
          }
          
          return Center(
            child: Text('文件列表页面'),
          );
        }),
      ),
    );
  }
}
