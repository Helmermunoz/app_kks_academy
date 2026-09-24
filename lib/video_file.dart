import 'dart:typed_data';

class VideoFile {
  final String name, type;
  final Uint8List bytes;
  VideoFile(this.name, this.type, this.bytes);
}
