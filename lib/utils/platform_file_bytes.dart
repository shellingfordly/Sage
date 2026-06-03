import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'platform_file_io.dart';

Future<Uint8List> readPlatformFileBytes(PlatformFile file) async {
  if (file.bytes != null) {
    return file.bytes!;
  }
  final path = file.path;
  if (path == null) {
    throw StateError('无法读取文件');
  }
  return Uint8List.fromList(await readBytesFromPath(path));
}
