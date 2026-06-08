import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/components/icons/sage_logo.dart';

const _iconSize = 1024.0;
const _background = Color(0xFFF7F5F0);
const _logoFraction = 0.68;

void main() {
  test('generate app icon assets', () async {
    final outDir = Directory('docs/assets/app_icon');
    outDir.createSync(recursive: true);

    await _writePng(
      '${outDir.path}/icon.png',
      background: _background,
    );
    await _writePng(
      '${outDir.path}/icon_foreground.png',
      background: null,
    );
  });
}

Future<void> _writePng(String path, {required Color? background}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (background != null) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _iconSize, _iconSize),
      Paint()..color = background,
    );
  }

  final logoSize = _iconSize * _logoFraction;
  final offset = (_iconSize - logoSize) / 2;
  canvas
    ..save()
    ..translate(offset, offset);
  const SageLogoPainter().paint(canvas, Size(logoSize, logoSize));
  canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(_iconSize.toInt(), _iconSize.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}
