import 'package:get/get.dart';
import 'package:keframe/keframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

import 'package:xlist/common/index.dart';
import 'package:xlist/storages/index.dart';
import 'package:xlist/routes/app_pages.dart';
import 'package:xlist/pages/homepage/index.dart';
import 'package:xlist/pages/setting/index.dart';
import 'package:xlist/components/index.dart';
import 'package:xlist/helper/index.dart';
import 'package:xlist/gen/assets.gen.dart';

class Homepage extends GetView<HomepageController> {
  const Homepage({Key? key}) : super(key: key);

  Widget _buildGridView() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        // 长按空白处显示上下文菜单，仅包含粘贴选项
        if (ObjectHelper.clipboardData != null && ObjectHelper.clipboardOperation != ClipboardOperation.none) {
          showModalActionSheet(
            context: Get.context!,
            actions: [
              SheetAction(
                label: '粘贴',
                key: 'paste',
              ),
            ],
            cancelLabel: '取消',
          ).then((value) {
            if (value == 'paste') {
              ObjectHelper.paste(
                path: controller.currentPath.value,
                source: 'HOMEPAGE',
                pageTag: '',
              );
            }
          });
        }
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: CommonUtils.isPad ? 120 : 280.w,
                mainAxisExtent: 100,
                mainAxisSpacing: 0,
                crossAxisSpacing: 8,
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
                      onLongPress: () {
                        ObjectHelper.showContextMenu(
                          path: controller.currentPath.value,
                          object: object,
                          objects: controller.objects.value,
                          source: 'HOMEPAGE',
                          pageTag: '',
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
      ),
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
                  onLongPress: () {
                    ObjectHelper.showContextMenu(
                      path: controller.currentPath.value,
                      object: object,
                      objects: controller.objects.value,
                      source: 'HOMEPAGE',
                      pageTag: '',
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
    return WillPopScope(
      onWillPop: () async {
        // 拦截返回键事件
        if (controller.currentPath.value != '/') {
          // 如果当前不在根目录，返回上级目录
          controller.navigateUp();
          return false; // 阻止默认的返回行为
        }
        return true; // 允许默认的返回行为（退出应用）
      },
      child: CupertinoPageScaffold(
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
          middle: Container(
            width: Get.width * 0.6,
            height: 36,
            child: Obx(() {
              // 提取当前目录名称
              String currentDirName = controller.currentPath.value;
              if (currentDirName != '/') {
                final parts = currentDirName.split('/').where((part) => part.isNotEmpty).toList();
                if (parts.isNotEmpty) {
                  currentDirName = parts.last;
                }
              }
              
              return CupertinoTextField(
                controller: TextEditingController(text: currentDirName),
                placeholder: currentDirName,
                placeholderStyle: TextStyle(color: Colors.grey),
                style: TextStyle(color: Get.theme.textTheme.bodyLarge?.color),
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? Color.fromARGB(255, 40, 40, 40) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16),
                onSubmitted: (value) {
                  controller.handleAddressInput(value);
                },
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
                onTap: () {
                  // 点击时显示完整路径
                  final field = Get.context!.findRenderObject() as RenderBox?;
                  if (field != null) {
                    // 重新创建控制器，设置为完整路径
                    final controller = CupertinoTextField();
                    // 这里需要使用StatefulWidget来管理这个状态
                    // 为了简单起见，我们暂时保持点击后显示完整路径的逻辑
                    // 实际实现可能需要更复杂的状态管理
                  }
                },
                suffix: IconButton(
                  icon: Icon(CupertinoIcons.search, size: 20, color: Get.theme.textTheme.bodyLarge?.color),
                  onPressed: () {
                    controller.handleSearch(controller.searchQuery.value);
                  },
                ),
              );
            }),
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
              print('=== Homepage: Loading state ===');
              return Center(
                child: CupertinoActivityIndicator(),
              );
            }
            
            final fileCount = controller.objects.value.length;
            final isServerConfigured = controller.isServerConfigured;
            final currentServer = controller.currentServer;
            
            print('=== Homepage: State Check ===');
            print('Server configured: $isServerConfigured');
            print('Current server: ${currentServer?.url ?? 'null'}');
            print('File count: $fileCount');
            print('Error message: ${controller.errorMessage.value}');
            print('Current path: ${controller.currentPath.value}');
            
            if (!isServerConfigured) {
              print('=== Homepage: No server configured ===');
              // 未配置服务器，显示配置提示和背景图片
              return Container(
                padding: EdgeInsets.all(16),
                color: Get.isDarkMode ? Color.fromARGB(255, 18, 18, 18) : Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 显示背景图片
                    Container(
                      margin: EdgeInsets.only(bottom: 32),
                      child: Assets.images.empty.image(width: 600.r),
                    ),
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
                              '未配置服务器',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      child: Text('添加服务器'),
                      onPressed: () async {
                        print('=== Homepage: Navigating to server settings ===');
                        // 直接导航到服务器设置页面
                        await Get.toNamed(Routes.SETTING_SERVER);
                        // 刷新主页数据
                        print('=== Homepage: Refreshing data after server settings ===');
                        controller.getObjectList();
                      },
                    ),
                  ],
                ),
              );
            } else if (fileCount == 0) {
              print('=== Homepage: Server configured but directory empty ===');
              print('Server URL: ${currentServer?.url}');
              // 已配置服务器但目录为空，显示空目录提示
              return Container(
                padding: EdgeInsets.all(16),
                color: Get.isDarkMode ? Color.fromARGB(255, 18, 18, 18) : Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 32),
                      child: Assets.images.empty.image(width: 600.r),
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.folder_open, color: Colors.grey[600]),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value.isNotEmpty 
                                ? controller.errorMessage.value 
                                : '目录为空',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      child: Text('刷新'),
                      onPressed: () {
                        print('=== Homepage: Refreshing file list ===');
                        controller.getObjectList();
                      },
                    ),
                  ],
                ),
              );
            } else {
              print('=== Homepage: Displaying file list with $fileCount items ===');
              // 显示文件列表
              return controller.layoutType.value == 'grid' ? _buildGridView() : _buildListView();
            }
          }),
        ),
      ),
    );
  }
}
