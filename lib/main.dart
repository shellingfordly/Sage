import 'package:flutter/material.dart';

import 'app.dart';
import 'data/ledger_store.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ledgerStore.load(),
    themeController.load(),
  ]);
  runApp(const LedgerApp());
}
