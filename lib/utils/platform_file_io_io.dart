import 'dart:io';

Future<void> writeBytesToPath(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

Future<List<int>> readBytesFromPath(String path) async {
  return File(path).readAsBytes();
}
