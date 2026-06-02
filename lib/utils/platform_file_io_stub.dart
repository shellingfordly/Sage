Future<void> writeBytesToPath(String path, List<int> bytes) async {
  throw UnsupportedError('当前平台不支持直接写入文件');
}

Future<List<int>> readBytesFromPath(String path) async {
  throw UnsupportedError('当前平台不支持直接读取文件');
}
