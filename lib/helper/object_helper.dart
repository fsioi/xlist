import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart' hide FileType;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:xlist/models/index.dart';
import 'package:xlist/models/user.dart'; // 导入 UserModel
import 'package:xlist/common/index.dart';
import 'package:xlist/storages/index.dart';
import 'package:xlist/storages/user_storage.dart'; // 导入 UserStorage
import 'package:xlist/constants/index.dart';
import 'package:xlist/routes/app_pages.dart';
import 'package:xlist/repositorys/index.dart';
import 'package:xlist/pages/detail/index.dart';
import 'package:xlist/pages/homepage/index.dart';
import 'package:xlist/pages/directory/index.dart';
import 'package:xlist/helper/preview_helper.dart';

class ObjectHelper {
  /// 文件点击事件
  /// [path] 文件路径
  /// [type] 文件类型
  /// [name] 文件名称
  static void click({
    required String path,
    required int type,
    required String name,
    List<ObjectModel>? objects,
  }) {
    // 文件夹
    if (type == FileType.FOLDER) {
      // 使用 homepage controller 进行导航
      final homepageController = Get.find<HomepageController>();
      final newPath = path == '/' ? '/${name}' : '${path}/${name}';
      homepageController.navigateToPath(newPath);
      return;
    }

    // 预览图片
    if (PreviewHelper.isImage(name)) {
      Get.toNamed(Routes.IMAGE_PREVIEW,
          arguments: {'path': path, 'name': name, 'objects': objects});
      return;
    }

    // 预览视频
    if (PreviewHelper.isVideo(name)) {
      Get.toNamed(Routes.VIDEO_PLAYER,
          arguments: {'path': path, 'name': name, 'objects': objects});
      return;
    }

    // 预览音频
    if (PreviewHelper.isAudio(name)) {
      Get.toNamed(Routes.AUDIO_PLAYER,
          arguments: {'path': path, 'name': name, 'objects': objects});
      return;
    }

    // 预览文档
    if (PreviewHelper.isDocument(name)) {
      Get.toNamed(Routes.DOCUMENT, arguments: {'path': path, 'name': name});
      return;
    }

    // 其他文件
    Get.toNamed(Routes.FILE, arguments: {'path': path, 'name': name});
  }

  /// 刷新列表
  /// [source] 来源
  /// [pageTag] 页面标签
  static void refreshObjectList({
    required String source,
    required String pageTag,
    bool refresh = false,
  }) async {
    switch (source) {
      case PageSource.DETAIL:
        await Get.find<DetailController>(tag: pageTag)
            .getObjectList(refresh: refresh);
        Get.until((route) => Get.currentRoute.startsWith(Routes.DETAIL));
        break;
      case PageSource.HOMEPAGE:
        await Get.find<HomepageController>().getObjectList();
        Get.until((route) => Get.currentRoute.startsWith(Routes.HOMEPAGE));
        break;
      case PageSource.DIRECTORY:
        await Get.find<DirectoryController>(tag: pageTag).getDirectoryList();
        Get.until((route) => Get.currentRoute.startsWith(Routes.DIRECTORY));
        break;
      default:
        break;
    }
  }

  /// 重命名
  /// [path] 文件路径
  /// [object] 文件对象
  static Future<void> rename({
    required String path,
    required ObjectModel object,
    required String source,
    required String pageTag,
  }) async {
    final data = await showTextInputDialog(
      context: Get.context!,
      title: 'dialog_rename_title'.tr,
      message: 'dialog_rename_message'.tr,
      okLabel: 'confirm'.tr,
      cancelLabel: 'cancel'.tr,
      textFields: [
        DialogTextField(
          hintText: 'dialog_rename_hint'.tr,
          initialText: object.name,
        ),
      ],
    );
    if (data == null) return;
    if (data.isEmpty) return;

    // 重命名
    try {
      SmartDialog.showLoading();
      final response = await ObjectRepository.rename(
          path: '${path}${object.name}', name: data.first);
      if (response['code'] != HttpStatus.ok) {
        throw response['message'];
      }

      SmartDialog.dismiss();
      SmartDialog.showToast('toast_rename_success'.tr);

      // 刷新列表
      refreshObjectList(source: source, pageTag: pageTag);
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast(e.toString());
    }
  }

  /// 复制链接
  /// [path] 文件路径
  /// [object] 文件对象
  static void copyLink(
    String path, {
    required ObjectModel object,
    required UserModel userInfo,
  }) {
    if (object.isDir == true) {
      final serverUrl = Get.find<UserStorage>().serverUrl.value;
      Clipboard.setData(
          ClipboardData(text: '${serverUrl}${path}${object.name}'));
    } else {
      Clipboard.setData(ClipboardData(
        text: CommonUtils.getDownloadLink(
          path,
          object: object,
          userInfo: userInfo,
        ),
      ));
    }

    SmartDialog.showToast('toast_copy_success'.tr);
  }

  /// 移动
  /// [srcDir] 文件路径
  /// [name] 文件对象
  /// [dstDir] 目标路径
  static Future<void> move({
    required String srcDir,
    required String dstDir,
    required String name,
    required String source,
    required String pageTag,
  }) async {
    try {
      SmartDialog.showLoading();
      final response = await ObjectRepository.move(
          srcDir: srcDir, dstDir: dstDir, name: name);
      if (response['code'] != HttpStatus.ok) {
        throw response['message'];
      }

      SmartDialog.dismiss();
      SmartDialog.showToast('toast_move_success'.tr);

      // 刷新列表
      refreshObjectList(source: source, pageTag: pageTag);
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast(e.toString());
    }
  }

  /// 复制
  /// [srcDir] 文件路径
  /// [dstDir] 目标路径
  /// [name] 文件对象
  /// [source] 来源
  /// [pageTag] 页面标签
  static Future<void> copy({
    required String srcDir,
    required String dstDir,
    required String name,
    required String source,
    required String pageTag,
  }) async {
    try {
      SmartDialog.showLoading();
      final response = await ObjectRepository.copy(
          srcDir: srcDir, dstDir: dstDir, name: name);
      if (response['code'] != HttpStatus.ok) {
        throw response['message'];
      }

      SmartDialog.dismiss();
      SmartDialog.showToast('toast_copy_success'.tr);

      // 刷新列表
      refreshObjectList(source: source, pageTag: pageTag);
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast(e.toString());
    }
  }

  /// 删除
  /// [path] 文件路径
  /// [name] 文件名称
  /// [source] 来源
  /// [pageTag] 页面标签
  static Future<void> remove({
    required String path,
    required String name,
    required String source,
    required String pageTag,
  }) async {
    final ok = await showOkCancelAlertDialog(
      context: Get.context!,
      title: 'dialog_prompt_title'.tr,
      message: 'dialog_remove_message'.tr,
      okLabel: 'confirm'.tr,
      cancelLabel: 'cancel'.tr,
    );
    if (ok != OkCancelResult.ok) return;

    try {
      SmartDialog.showLoading();
      final response = await ObjectRepository.remove(path: path, name: name);
      if (response['code'] != HttpStatus.ok) {
        throw response['message'];
      }

      SmartDialog.dismiss();
      SmartDialog.showToast('toast_remove_success'.tr);

      // 刷新列表
      refreshObjectList(source: source, pageTag: pageTag);
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast(e.toString());
    }
  }

  /// 新建文件夹
  /// [path] 文件路径
  static Future<void> mkdir({
    required String path,
    required String source,
    required String pageTag,
  }) async {
    final data = await showTextInputDialog(
      context: Get.context!,
      title: 'dialog_mkdir_title'.tr,
      message: 'dialog_mkdir_message'.tr,
      okLabel: 'confirm'.tr,
      cancelLabel: 'cancel'.tr,
      textFields: [DialogTextField(hintText: 'dialog_mkdir_hint'.tr)],
    );
    if (data == null) return;
    if (data.isEmpty) return;

    // 新建文件夹
    try {
      SmartDialog.showLoading();
      final response =
          await ObjectRepository.mkdir(path: '${path}/${data.first}');
      if (response['code'] != HttpStatus.ok) {
        throw response['message'];
      }

      SmartDialog.dismiss();
      SmartDialog.showToast('toast_mkdir_success'.tr);

      // 刷新列表
      refreshObjectList(source: source, pageTag: pageTag);
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast(e.toString());
    }
  }

  /// 新建文件
  /// [path] 文件路径
  static Future<void> createFile({
    required String path,
    required String source,
    required String pageTag,
    String password = '',
  }) async {
    final data = await showTextInputDialog(
      context: Get.context!,
      title: 'dialog_newfile_title'.tr,
      message: 'dialog_newfile_message'.tr,
      okLabel: 'confirm'.tr,
      cancelLabel: 'cancel'.tr,
      textFields: [DialogTextField(hintText: 'dialog_newfile_hint'.tr)],
    );
    if (data == null) return;
    if (data.isEmpty) return;

    // 新建文件夹
    try {
      SmartDialog.showLoading();
      final response = await ObjectRepository.put(
        fileData: [],
        fileName: data.first,
        remotePath: path,
        password: password,
      );
      if (response['code'] != HttpStatus.ok) {
        throw response['message'];
      }

      SmartDialog.dismiss();
      SmartDialog.showToast('toast_newfile_success'.tr);

      // 刷新列表
      refreshObjectList(source: source, pageTag: pageTag, refresh: true);
    } catch (e) {
      SmartDialog.dismiss();
      print(e);
      SmartDialog.showToast(e.toString());
    }
  }

  /// 上传图片 & 视频
  /// [path] 文件路径
  static Future<void> upload({
    required String path,
    required int type,
    required String source,
    required String pageTag,
    String password = '',
  }) async {
    List<XFile>? pickedFiles;
    final ImagePicker picker = ImagePicker(); // 图片选择器

    if (type == FileType.IMAGE) pickedFiles = await picker.pickMultiImage();
    if (type == FileType.VIDEO) {
      // 视频选择器暂时不支持多选，保持单选
      XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) pickedFiles = [pickedFile];
    }

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      try {
        SmartDialog.showLoading(msg: 'toast_upload_loading'.tr);

        int successCount = 0;
        int failCount = 0;
        List<String> failFiles = [];

        for (var pickedFile in pickedFiles) {
          try {
            // 文件名称
            final fileName = DateTime.now().millisecondsSinceEpoch.toString() +
                p.extension(pickedFile.name);

            // 上传文件
            final response = await ObjectRepository.put(
              fileData: File(pickedFile.path).readAsBytesSync(),
              fileName: fileName,
              remotePath: path,
              password: password,
            );

            // 错误处理
            if (response['code'] != HttpStatus.ok) {
              throw response['message'];
            }
            successCount++;
          } catch (e) {
            failCount++;
            failFiles.add(pickedFile.name);
            print('上传文件 ${pickedFile.name} 失败: $e');
          }
        }

        SmartDialog.dismiss();
        if (failCount > 0) {
          String failMessage = 'toast_upload_partial_failure'.trParams({
            'success': successCount.toString(),
            'total': pickedFiles.length.toString(),
            'files': failFiles.join(', ')
          });
          SmartDialog.showToast(failMessage);
        } else {
          SmartDialog.showToast('toast_upload_success'.tr);
        }

        // 刷新列表
        refreshObjectList(source: source, pageTag: pageTag, refresh: true);
      } catch (e) {
        SmartDialog.dismiss();
        print(e);
        SmartDialog.showToast(e.toString());
      }
    } else {
      // User canceled the picker
    }
  }

  /// 上传文件
  /// [path] 文件路径
  static Future<void> uploadFile({
    required String path,
    required String source,
    required String pageTag,
    String password = '',
  }) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      try {
        SmartDialog.showLoading(msg: 'toast_upload_loading'.tr);
        int successCount = 0;
        int failCount = 0;
        List<String> failFiles = [];

        // 上传多个文件
        for (var file in result.files) {
          try {
            final response = await ObjectRepository.put(
              fileData: File(file.path!).readAsBytesSync(),
              fileName: file.name,
              remotePath: path,
              password: password,
            );

            // 错误处理
            if (response['code'] != HttpStatus.ok) {
              throw response['message'];
            }
            successCount++;
          } catch (e) {
            failCount++;
            failFiles.add(file.name);
            print('上传文件 ${file.name} 失败: $e');
          }
        }

        SmartDialog.dismiss();
        if (failCount > 0) {
          String failMessage = 'toast_upload_partial_failure'.trParams({
            'success': successCount.toString(),
            'total': result.files.length.toString(),
            'files': failFiles.join(', ')
          });
          SmartDialog.showToast(failMessage);
        } else {
          SmartDialog.showToast('toast_upload_success'.tr);
        }

        // 刷新列表
        refreshObjectList(source: source, pageTag: pageTag, refresh: true);
      } catch (e) {
        SmartDialog.dismiss();
        print(e);
        SmartDialog.showToast(e.toString());
      }
    } else {
      // User canceled the picker
    }
  }
}
