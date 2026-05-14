import 'package:flutter/material.dart';

import 'app.dart';
import 'data/ledger_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ledgerStore.load();
  runApp(const LedgerApp());
}
