import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'video_file.dart';

Future<VideoFile?> pickVideo() async {
  final result = Completer<VideoFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'video/mp4,video/webm,video/quicktime';
  input.oncancel = ((web.Event _) {
    if (!result.isCompleted) result.complete(null);
  }).toJS;
  input.onchange = ((web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      result.complete(null);
      return;
    }
    if (file.size == 0 ||
        file.size > 50 * 1024 * 1024 ||
        !['video/mp4', 'video/webm', 'video/quicktime'].contains(file.type)) {
      result.completeError(
        Exception('Selecciona MP4, WebM o MOV de hasta 50 MB.'),
      );
      return;
    }
    () async {
      try {
        final data = await file.arrayBuffer().toDart;
        result.complete(
          VideoFile(file.name, file.type, data.toDart.asUint8List()),
        );
      } catch (e) {
        result.completeError(e);
      }
    }();
  }).toJS;
  input.click();
  try {
    return await result.future;
  } finally {
    input.onchange = null;
    input.oncancel = null;
  }
}

Widget videoPlayer(String url) => SizedBox(
  height: 300,
  child: HtmlElementView.fromTagName(
    key: ValueKey(url),
    tagName: 'video',
    onElementCreated: (element) {
      final player = element as web.HTMLVideoElement;
      player.src = url;
      player.controls = true;
      player.preload = 'metadata';
      player.setAttribute('playsinline', '');
      player.style.width = '100%';
      player.style.height = '100%';
    },
  ),
);
