import 'package:flutter/material.dart';

import 'video_file.dart';

Future<VideoFile?> pickVideo() async =>
    throw UnsupportedError('Usa la versión web para subir videos.');
Widget videoPlayer(String url) =>
    const Text('Abre la versión web para reproducir el video.');
