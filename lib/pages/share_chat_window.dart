import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:get/utils.dart';
import 'package:global_repository/global_repository.dart';
import 'package:speed_share/app/controller/chat_controller.dart';
import 'package:speed_share/config/assets.dart';
import 'package:speed_share/config/config.dart';
import 'package:speed_share/global/global.dart';
import 'package:speed_share/global/widget/pop_button.dart';
import 'package:speed_share/themes/app_colors.dart';
import 'package:speed_share/utils/chat_server.dart';
import 'item/message_item_factory.dart';
import 'model/model.dart';

class ShareChat extends StatefulWidget {
  const ShareChat({
    Key key,
    this.needCreateChatServer = true,
    this.chatServerAddress,
  }) : super(key: key);

  /// 为`true`的时候，会创建一个聊天服务器，如果为`false`，则代表加入已有的聊天
  final bool needCreateChatServer;
  final String chatServerAddress;
  @override
  _ShareChatState createState() => _ShareChatState();
}

class _ShareChatState extends State<ShareChat>
    with SingleTickerProviderStateMixin {
  ChatController controller = Get.find();
  AnimationController menuAnim;
  final List<XFile> files = [];
  bool dropping = false;
  @override
  void initState() {
    super.initState();
    menuAnim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    controller.initChat(
      widget.needCreateChatServer,
      widget.chatServerAddress,
    );
  }

  @override
  void dispose() {
    menuAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        // files.addAll(detail.urls.map((e) => XFile(e.path)));
        // setState(() {});
        // final List<String> paths = [];
        // for (final XFile file in files) {
        //   paths.add(file.path);
        // }
        // Log.d('paths -> $paths');
        // files.clear();
        files.addAll(
          detail.urls.map(
            (e) => XFile(
              GetPlatform.isWeb ? 'blob:${e.path}' : e.toFilePath(),
            ),
          ),
        );
          detail.urls.forEach((element) { 
            Log.e(element);
          });
        Log.d('files -> $files');
        setState(() {});
        if (files.isNotEmpty) {
          controller.sendXFiles(files);
          files.clear();
        }
      },
      onDragUpdated: (details) {
        setState(() {
          // offset = details.localPosition;
        });
      },
      onDragEntered: (detail) {
        setState(() {
          dropping = true;
          // offset = detail.localPosition;
        });
      },
      onDragExited: (detail) {
        setState(() {
          dropping = false;
          // offset = null;
        });
      },
      child: Stack(
        children: [
          Scaffold(
            body: Stack(
              alignment: Alignment.center,
              // fit: StackFit.passthrough,
              children: [
                GestureDetector(
                  onTap: () {
                    controller.focusNode.unfocus();
                  },
                  child: GetBuilder<ChatController>(builder: (context) {
                    return ListView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        0.w,
                        kToolbarHeight,
                        0.w,
                        80.w,
                      ),
                      controller: controller.scrollController,
                      itemCount: controller.children.length,
                      cacheExtent: 99999,
                      itemBuilder: (c, i) {
                        return controller.children[i];
                      },
                    );
                  }),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 8.0,
                        sigmaY: 8.0,
                      ),
                      child: Container(
                        height: kToolbarHeight,
                        color: AppColors.background.withOpacity(0.4),
                        child: AppBar(
                          title: Text(
                            '文件共享',
                            style: TextStyle(
                              color: AppColors.fontColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.w,
                            ),
                          ),
                          leading: PopButton(),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 8.0,
                        sigmaY: 8.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 60.w,
                          maxHeight: 240.w,
                        ),
                        child: sendMsgContainer(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (dropping)
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 4.0,
                sigmaY: 4.0,
              ),
              child: Material(
                color: AppColors.surface.withOpacity(0.4),
                child: Center(
                  child: Text(
                    '释放以分享文件到共享窗口~',
                    style: TextStyle(
                      color: AppColors.fontColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.w,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget menu() {
    return AnimatedBuilder(
      animation: menuAnim,
      builder: (c, child) {
        return SizedBox(
          height: 100.w * menuAnim.value,
          child: child,
        );
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 16.w),
        physics: NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            SizedBox(
              width: 80.w,
              height: 80.w,
              child: InkWell(
                borderRadius: BorderRadius.circular(10.w),
                onTap: () {
                  menuAnim.reverse();
                  Future.delayed(Duration(milliseconds: 100), () {
                    if (GetPlatform.isDesktop || GetPlatform.isWeb) {
                      controller.sendFileForBroswerAndDesktop();
                    } else if (GetPlatform.isAndroid) {
                      controller.sendFileForAndroid(
                        useSystemPicker: true,
                      );
                    }
                  });
                },
                child: Tooltip(
                  message: '点击将会调用系统的文件选择器',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        color: AppColors.accentColor,
                        size: 36.w,
                      ),
                      SizedBox(height: 4.w),
                      Text(
                        '系统管理器',
                        style: TextStyle(
                          color: AppColors.fontColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.w,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            if (GetPlatform.isAndroid && !GetPlatform.isWeb)
              Theme(
                data: ThemeData(
                  primaryColor: AppColors.accentColor,
                ),
                child: Builder(builder: (context) {
                  return SizedBox(
                    width: 80.w,
                    height: 80.w,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.w),
                      onTap: () {
                        menuAnim.reverse();
                        Future.delayed(Duration(milliseconds: 100), () {
                          controller.sendFileForAndroid(
                            context: context,
                          );
                        });
                      },
                      child: Tooltip(
                        message: '点击将调用自实现的文件选择器',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.file_copy,
                              color: AppColors.accentColor,
                              size: 36.w,
                            ),
                            SizedBox(height: 4.w),
                            Text(
                              '内部管理器',
                              style: TextStyle(
                                color: AppColors.fontColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.w,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            if (!GetPlatform.isWeb)
              SizedBox(
                width: 80.w,
                height: 80.w,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10.w),
                  onTap: () async {
                    menuAnim.reverse();
                    Future.delayed(Duration(milliseconds: 100), () {
                      controller.sendDir();
                    });
                  },
                  child: Tooltip(
                    message: '点击将调用自实现的文件夹选择器',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          Assets.dir,
                          color: AppColors.accentColor,
                          width: 36.w,
                        ),
                        SizedBox(height: 4.w),
                        Text(
                          '文件夹',
                          style: TextStyle(
                            color: AppColors.fontColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.w,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget sendMsgContainer(BuildContext context) {
    return GetBuilder<ChatController>(builder: (context) {
      return Material(
        color: AppColors.nav.withOpacity(0.8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.w),
          topRight: Radius.circular(12.w),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: controller.focusNode,
                      controller: controller.controller,
                      autofocus: false,
                      maxLines: 8,
                      minLines: 1,
                      style: TextStyle(
                        textBaseline: TextBaseline.ideographic,
                      ),
                      onSubmitted: (_) {
                        controller.sendTextMsg();
                        Future.delayed(Duration(milliseconds: 100), () {
                          controller.focusNode.requestFocus();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 16.w,
                  ),
                  GestureWithScale(
                    onTap: () {
                      if (controller.hasInput) {
                        controller.sendTextMsg();
                      } else {
                        if (menuAnim.isCompleted) {
                          menuAnim.reverse();
                        } else {
                          menuAnim.forward();
                        }
                      }
                    },
                    child: Material(
                      color: AppColors.accentColor,
                      borderRadius: BorderRadius.circular(24.w),
                      borderOnForeground: true,
                      child: SizedBox(
                        width: 48.w,
                        height: 48.w,
                        child: AnimatedBuilder(
                          animation: menuAnim,
                          builder: (c, child) {
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..rotateZ(menuAnim.value * pi / 4),
                              child: child,
                            );
                          },
                          child: Icon(
                            controller.hasInput ? Icons.send : Icons.add,
                            color: AppColors.nav,
                            size: 24.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 16.w,
              ),
              menu(),
            ],
          ),
        ),
      );
    });
  }
}
