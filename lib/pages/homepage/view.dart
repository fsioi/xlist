import 'package:get/get.dart';
import 'package:keframe/keframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:xlist/common/index.dart';
import 'package:xlist/storages/index.dart';
import 'package:xlist/routes/app_pages.dart';
import 'package:xlist/pages/homepage/index.dart';
import 'package:xlist/pages/setting/index.dart';
import 'package:xlist/components/index.dart';
import 'package:xlist/helper/index.dart';

class Homepage extends GetView<HomepageController> {
  const Homepage({Key? key}) : super(key: key);

  Widget _buildGridView() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: CommonUtils.isPad ? 130 : 300.w,
              mainAxisExtent: 160,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final object = controller.objects.value[index];
                
                return FrameSeparateWidget(
                  index: index,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ObjectHelper.click(
                        path: controller.currentPath.value,
                        type: object.type ?? 0,
                        name: object.name ?? '',
                        objects: controller.objects.value,
                      );
                    },
                    child: ObjectGridItem(
                      object: object,
                      isShowPreview: controller.isShowPreview.value,
                    ),
                  ),
                );
              },
              childCount: controller.objects.value.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final object = controller.objects.value[index];
              
              return FrameSeparateWidget(
                index: index,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ObjectHelper.click(
                      path: controller.currentPath.value,
                      type: object.type ?? 0,
                      name: object.name ?? '',
                      objects: controller.objects.value,
                    );
                  },
                  child: Column(
                    children: [
                      ObjectListItem(
                        object: object,
                        isShowPreview: controller.isShowPreview.value,
                      ),
                      Container(
                        padding: EdgeInsets.only(top: CommonUtils.isPad ? 0 : 20.r),
                        child: CommonUtils.isPad
                            ? Divider(height: 1.r, indent: 90, endIndent: 10)
                            : Divider(height: 1.r, indent: 190.r, endIndent: 15.r),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: controller.objects.value.length,
          ),
        ),
      ],
    );
  }

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
        trailing: CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Icon(
            controller.layoutType.value == 'grid' 
              ? CupertinoIcons.square_list 
              : CupertinoIcons.square_grid_2x2,
            size: CommonUtils.navIconSize,
          ),
          onPressed: () {
            controller.layoutType.value = controller.layoutType.value == 'grid' ? 'list' : 'grid';
          },
        ),
      ),
      child: SafeArea(
        child: Obx(() {
          if (controller.isFirstLoading.isTrue) {
            return Center(
              child: CupertinoActivityIndicator(),
            );
          }
          
          final fileCount = controller.objects.value.length;
          
          if (fileCount == 0) {
            // 显示空状态或服务器配置提示
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.info_circle, color: Colors.blue[700]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '未配置服务器或目录为空',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
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
          
          // 显示文件列表
          return controller.layoutType.value == 'grid' ? _buildGridView() : _buildListView();
        }),
      ),
    );
  }
}
