import 'dart:io';

import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:audio_wave/audio_wave.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:xlist/gen/index.dart';
import 'package:xlist/helper/index.dart';
import 'package:xlist/common/index.dart';
import 'package:xlist/pages/video_player/index.dart';
import 'package:xlist/routes/app_pages.dart';
import 'package:xlist/services/index.dart';

class VideoPlayerPage extends GetView<VideoPlayerController> {
  VideoPlayerPage({super.key});
  late final _thumbnailPath = Rx<String?>(null);

  void _loadThumbnail() async {
    if (controller.thumbnail.isNotEmpty) {
      try {
        final path = await ThumbnailCache().getThumbnail(
          url: controller.thumbnail.value,
          headers: controller.httpHeaders,
          isVideo: true,
        );
        if (path != null) {
          _thumbnailPath.value = path;
        }
      } catch (e) {
        print('Error loading video thumbnail: $e');
      }
    }
  }

  /// 构建下拉按钮
  Widget _buildPullDownButton() {
    List<PullDownMenuEntry> items = [];

    // 收藏
    items.add(PullDownMenuItem(
      title: 'favorite'.tr,
      onTap: () => controller.favorite(),
    ));

    // 切换字幕
    if (controller.subtitleNameList.isNotEmpty ||
        controller.timedTextTracks.isNotEmpty) {
      items.add(PullDownMenuItem(
        title: 'video_switch_subtitle'.tr,
        onTap: () => controller.changeSubtitle(),
      ));
    }

    // 切换音轨
    if (controller.audioTracks.isNotEmpty &&
        controller.audioTracks.length > 1) {
      items.add(PullDownMenuItem(
        title: 'video_switch_audio'.tr,
        onTap: () => controller.changeAudioTrack(),
      ));
    }

    items.addAll([
      PullDownMenuItem(
        title: 'pull_down_copy_link'.tr,
        onTap: () => controller.copyLink(),
      ),
      PullDownMenuItem(
        title: 'pull_down_download_file'.tr,
        onTap: () => controller.download(),
      ),
    ]);

    return PullDownButton(
      itemBuilder: (context) => items,
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        child: Icon(
          CupertinoIcons.ellipsis_circle,
          size: CommonUtils.navIconSize,
        ),
      ),
    );
  }

  // NavigationBar
  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CommonUtils.backButton,
      middle: Obx(
        () => Text(
          CommonUtils.formatFileNme(controller.currentName.value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.download_circle),
            onPressed: () => Get.toNamed(Routes.SETTING_DOWNLOAD),
          ),
          Obx(() => _buildPullDownButton()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadThumbnail();
    return Obx(
      () => controller.isFullScreen.value
          ? Container(
              color: Colors.black,
              child: Stack(
                children: [
                  _buildVideoPlayer(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: _buildControlBar(),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: CupertinoButton(
                      onPressed: () {
                        controller.toggleFullScreen();
                      },
                      child: Icon(
                        CupertinoIcons.back, 
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : CupertinoPageScaffold(
              backgroundColor: Get.theme.scaffoldBackgroundColor,
              navigationBar: _buildNavigationBar(),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildVideoPlayer(),
                    _buildControlBar(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVideoPlayer() {
    return Obx(
      () => controller.playerInitialized.value
          ? Obx(
              () => controller.isFullScreen.value
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: vp.VideoPlayer(controller.videoPlayerController),
                    )
                  : Center(
                      child: AspectRatio(
                        aspectRatio: controller.videoPlayerController.value.aspectRatio,
                        child: vp.VideoPlayer(controller.videoPlayerController),
                      ),
                    ),
            )
          : const Center(
              child: CupertinoActivityIndicator(
                radius: 20,
              ),
            ),
    );
  }

  Widget _buildControlBar() {
    return Expanded(
      child: Column(
        children: [
          _buildProgressBar(),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(controller.currentPosition.value),
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  _formatDuration(controller.totalDuration.value),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Slider(
              value: controller.currentPosition.value.inMilliseconds.toDouble(),
              max: controller.totalDuration.value.inMilliseconds.toDouble(),
              onChanged: (value) {
                controller.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            onPressed: controller.seekBackward,
            child: const Icon(CupertinoIcons.gobackward_10),
          ),
          SizedBox(width: 20),
          CupertinoButton(
            onPressed: controller.togglePlayPause,
            child: Obx(
              () => Icon(
                controller.isPlaying.value
                    ? CupertinoIcons.pause_circle_fill
                    : CupertinoIcons.play_circle_fill,
                size: 60,
              ),
            ),
          ),
          SizedBox(width: 20),
          CupertinoButton(
            onPressed: controller.seekForward,
            child: const Icon(CupertinoIcons.goforward_10),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
