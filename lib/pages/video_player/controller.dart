import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:charset/charset.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:charset/charset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:audio_service/audio_service.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:subtitle_wrapper_package/subtitle_wrapper_package.dart';

import 'package:xlist/gen/index.dart';
import 'package:xlist/helper/index.dart';
import 'package:xlist/models/index.dart';
import 'package:xlist/common/utils.dart';
import 'package:xlist/services/index.dart';
import 'package:xlist/storages/index.dart';
import 'package:xlist/constants/index.dart';
import 'package:xlist/repositorys/index.dart';
import 'package:xlist/repositorys/user_repository.dart';
import 'package:xlist/database/entity/index.dart';

class VideoPlayerController extends SuperController {
  final object = ObjectModel().obs;
  final userInfo = UserModel().obs;
  final httpHeaders = Map<String, String>().obs;
  final serverId = Get.find<UserStorage>().serverId.value.obs;
  final isLoading = true.obs;
  final isAutoPaused = false.obs;
  final subtitles = <Subtitle>[].obs;
  final subtitleNameList = <String>[].obs;
  final subtitleName = ''.obs;
  final audioTracks = <Map<String, String>>[].obs;
  final timedTextTracks = <Map<String, String>>[].obs;
  final showTimedText = true.obs;
  final currentName = ''.obs;
  final currentIndex = 0.obs;
  final showPlaylist = false.obs;
  final fijkViewKey = GlobalKey();
  final thumbnail = ''.obs;

  final isAutoPlay = Get.find<PreferencesStorage>().isAutoPlay.val;

  final isBackgroundPlay = Get.find<PreferencesStorage>().isBackgroundPlay.val;

  final playMode = Get.find<PreferencesStorage>().playMode;

  final String path = Get.arguments['path'] ?? '';
  final String name = Get.arguments['name'] ?? '';
  List<ObjectModel> objects = Get.arguments['objects'] ?? [];

  final String file = Get.arguments['file'] ?? '';
  final int downloadId = Get.arguments['downloadId'] ?? 0;

  late vp.VideoPlayerController player;
  final audioHandler = PlayerNotificationService.to.audioHandler;

  Timer? _timer;
  int _progressId = 0;
  final currentPos = Duration.zero.obs;
  StreamSubscription? _currentPosSubs;
  MediaItem? _mediaItem;

  @override
  void onInit() async {
    super.onInit();

    objects = objects.where((o) => PreviewHelper.isVideo(o.name!)).toList();
    userInfo.value = await UserRepository.me();

    currentName.value = name;
    currentIndex.value = objects.indexWhere((o) => o.name == name);
    showPlaylist.value = objects.length > 1;

    audioHandler.initializeStreamController(player, showPlaylist.value, true);
    audioHandler.playbackState.addStream(audioHandler.streamController.stream);
    audioHandler.setVideoFunctions(player.play, player.pause, (position) => player.seekTo(Duration(milliseconds: position)), player.dispose);

    if (file.isEmpty) {
      try {
        object.value = await ObjectRepository.get(path: '${path}${name}');
        if (object.value.provider != null && object.value.rawUrl != null) {
          httpHeaders.value = await DriverHelper.getHeaders(
              object.value.provider, object.value.rawUrl);
        }
      } catch (e) {
        SmartDialog.showToast('toast_get_object_fail'.tr);
        return;
      }
    } else {
      final download = await DatabaseService.to.database.downloadDao
          .findDownloadById(downloadId);
      object.value = ObjectModel.fromJson({
        'name': download?.name,
        'type': download?.type,
        'size': download?.size,
        'raw_url': 'file://${file}',
      });

      ObjectRepository.get(path: '${path}${name}').then((value) {
        updateSubtitleNameList(value.related ?? []);
      });
    }

    updateSubtitleNameList(object.value.related ?? []);
    thumbnail.value = object.value.thumb ?? '';

    if (Get.arguments['serverId'] != null) {
      serverId.value = Get.arguments['serverId'] ?? 0;
    }

    await updateProgress();

    // 检查 rawUrl 是否为空
    if (object.value.rawUrl == null || object.value.rawUrl!.isEmpty) {
      SmartDialog.showToast('toast_get_object_fail'.tr);
      return;
    }

    player = vp.VideoPlayerController.networkUrl(
      Uri.parse(object.value.rawUrl!),
      httpHeaders: httpHeaders.cast<String, String>(),
    );
    await player.initialize();
    await player.seekTo(currentPos.value);
    if (isAutoPlay) {
      await player.play();
    }

    player.addListener(_videoPlayerListener);

    await CommonUtils.addRecent(object.value, path, name);

    DownloadService.to.bindBackgroundIsolate((id, status, progress) {});
    isLoading.value = false;
  }

  void _videoPlayerListener() async {
    final value = player.value;

    if (_mediaItem != null && _mediaItem!.duration != value.duration) {
      _playerNotificationHandler();
    }

    if (value.isPlaying) WakelockPlus.enable();
    if (!value.isPlaying && value.isInitialized) WakelockPlus.disable();

    if (value.isInitialized && !value.hasError) {
      if (value.duration != null && value.duration!.inMilliseconds > 0) _playerNotificationHandler();
      final _audioTracks = <Map<String, String>>[];
      final _timedTextTracks = <Map<String, String>>[];
      audioTracks.value = _audioTracks;
      timedTextTracks.value = _timedTextTracks;
    }

    if (value.position == value.duration && value.isInitialized) {
      currentPos.value = Duration.zero;

      await DatabaseService.to.database.progressDao.updateProgress(
        ProgressEntity(
          id: _progressId,
          serverId: serverId.value,
          path: path,
          name: currentName.value,
          currentPos: currentPos.value.inMilliseconds,
        ),
      );

      if (playMode.val == PlayMode.LIST_LOOP && showPlaylist.isTrue) {
        await player.seekTo(Duration.zero);
        currentIndex.value == objects.length - 1
            ? changePlaylist(0)
            : changePlaylist(currentIndex.value + 1);
        return;
      }

      if (playMode.val == PlayMode.SINGLE_LOOP && showPlaylist.isTrue) {
        await player.seekTo(Duration.zero);
        await player.play();
        return;
      }
    }

    currentPos.value = value.position;
  }

  void _playerNotificationHandler() {
    _mediaItem = MediaItem(
      id: '${path}${currentName.value}',
      title: CommonUtils.formatFileNme(currentName.value),
      duration: player.value.duration,
      artUri: object.value.thumb != null && object.value.thumb!.isNotEmpty
          ? Uri.parse(object.value.thumb!)
          : Uri.parse('https://s2.loli.net/2023/07/05/viCwFoLceMtAB3m.jpg'),
      artHeaders: httpHeaders.cast<String, String>(),
    );

    audioHandler.mediaItem.add(_mediaItem);
  }

  void changePlaylist(int index) async {
    final _object = objects[index];
    if (_object.name == currentName.value) {
      SmartDialog.showToast('toast_current_play_file'.tr);
      return;
    }

    SmartDialog.showLoading();
    try {
      object.value = await ObjectRepository.get(path: '${path}${_object.name}');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast(e.toString());
      return;
    }

    currentIndex.value = index;
    currentName.value = _object.name!;
    isAutoPaused.value = false;
    subtitles.clear();
    audioTracks.clear();
    timedTextTracks.clear();

    updateSubtitleNameList(object.value.related ?? []);

    SmartDialog.dismiss();
    await player.dispose();
    player = vp.VideoPlayerController.networkUrl(
      Uri.parse(object.value.rawUrl!),
      httpHeaders: httpHeaders.cast<String, String>(),
    );
    await player.initialize();
    currentPos.value = Duration.zero;
    await updateProgress();

    await player.seekTo(currentPos.value);
    await player.play();

    await CommonUtils.addRecent(object.value, path, _object.name!);
    SmartDialog.showToast('toast_switch_success'.tr);
  }

  void changeAudioTrack({String? value}) async {
    SmartDialog.showToast('video_switch_audio_not_supported'.tr);
    return;
  }

  void updateSubtitleNameList(List<ObjectModel> related) {
    subtitleNameList.clear();
    related.forEach((v) {
      final ext = p.extension(v.name!).toLowerCase();
      if (ext == '.vtt' || ext == '.srt' || ext == '.ass') {
        subtitleNameList.add(v.name!);
      }
    });
  }

  void changeSubtitle({String? value}) async {
    SmartDialog.showToast('video_switch_subtitle_not_supported'.tr);
    return;
  }

  Future<void> updateProgress() async {
    final progress = await DatabaseService.to.database.progressDao
        .findProgressByServerIdAndPath(serverId.value, path, currentName.value);

    if (progress != null) {
      _progressId = progress.id!;
      currentPos.value = Duration(milliseconds: progress.currentPos);
    } else {
      _progressId =
          await DatabaseService.to.database.progressDao.insertProgress(
        ProgressEntity(
          serverId: serverId.value,
          path: path,
          name: currentName.value,
          currentPos: 0,
        ),
      );
    }

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await DatabaseService.to.database.progressDao.updateProgress(
        ProgressEntity(
          id: _progressId,
          serverId: serverId.value,
          path: path,
          name: currentName.value,
          currentPos: currentPos.value.inMilliseconds,
        ),
      );
    });
  }

  void favorite() async {
    await CommonUtils.addFavorite(object.value, path, currentName.value);
  }

  void copyLink() {
    Clipboard.setData(ClipboardData(
      text: CommonUtils.getDownloadLink(
        path,
        object: object.value,
        userInfo: userInfo.value,
      ),
    ));
    SmartDialog.showToast('toast_copy_success'.tr);
  }

  void download() async {
    DownloadHelper.file(
        path, currentName.value, object.value.type!, object.value.size!);
  }

  @override
  void onPaused() {
    if (player.value.isPlaying && !isBackgroundPlay) {
      isAutoPaused.value = true;
      player.pause();
    }
  }

  @override
  void onResumed() {
    // 判断大小超过 30g 的大文件
    final isLargeFile = object.value.size! > 30 * 1024 * 1024 * 1024;

    // if player is started and auto paused
    if (player.value.isPlaying && isLargeFile) {
      isAutoPaused.value = true;
      player.pause();
    }

    // fix player seekTo bug
    Future.delayed(Duration(milliseconds: 500), () async {
      if (isLargeFile) await player.seekTo(currentPos.value);

      if (!player.value.isPlaying && isAutoPaused.isTrue) {
        isAutoPaused.value = false;
        player.play();
      }
    });
  }

  @override
  void onInactive() {}

  @override
  void onDetached() {}

  @override
  void onHidden() {}

  @override
  void onClose() {
    super.onClose();

    _timer?.cancel();
    _currentPosSubs?.cancel();
    audioHandler.streamController.add(PlaybackState());
    audioHandler.streamController.close();
    player.removeListener(_videoPlayerListener);
    player.dispose();

    DownloadService.to.unbindBackgroundIsolate();
    WakelockPlus.disable();
  }
}
