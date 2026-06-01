import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ai/models/ai_insight_models.dart';
import 'ai/services/ai_home_alert_service.dart';
import 'ai/services/ai_insight_cache.dart';
import 'ai/services/ai_insight_engine.dart';
import 'data/ledger_store.dart';
import 'pages/ai_insight_page.dart';
import 'pages/home_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/statistics_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

const _aiInsightEngine = AiInsightEngine();
const _aiHomeAlertService = AiHomeAlertService();
final _aiInsightCache = AiInsightCache();

class LedgerApp extends StatelessWidget {
  const LedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeOption>(
      valueListenable: themeController,
      builder: (context, selectedTheme, child) {
        final themeData = AppTheme.fromPalette(
          brightness: selectedTheme.brightness,
          colors: selectedTheme.palette,
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ledger App',
          theme: themeData,
          darkTheme: themeData,
          themeMode: ThemeMode.light,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        );
      },
      child: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _aiEntrySequence = 0;
  bool _expandRiskAndAnomalyOnAiEntry = false;

  static const _aiIndex = 1;

  List<Widget> _pages() {
    return [
      HomePage(
        onOpenAiPage: () {
          setState(() {
            _aiEntrySequence++;
            _expandRiskAndAnomalyOnAiEntry = true;
            _selectedIndex = _aiIndex;
          });
        },
      ),
      AiInsightPage(
        entrySequence: _aiEntrySequence,
        expandRiskAndAnomalyOnEntry: _expandRiskAndAnomalyOnAiEntry,
      ),
      const StatisticsPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledgerStore,
      builder: (context, child) {
        final pages = _pages();
        final now = DateTime.now();
        final snapshot = _aiInsightCache.getOrBuild(
          ledgerId: ledgerStore.currentLedger.id,
          records: ledgerStore.records,
          monthlyBudget: ledgerStore.monthlyBudgetFor(now),
          mode: AiSuggestionMode.balanced,
          now: now,
          builder: () => _aiInsightEngine.buildSnapshot(
            records: ledgerStore.records,
            monthlyBudget: ledgerStore.monthlyBudgetFor(now),
            mode: AiSuggestionMode.balanced,
            now: now,
          ),
        );
        final alert = _aiHomeAlertService.evaluate(snapshot);

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                if (index == _aiIndex && _selectedIndex != _aiIndex) {
                  _aiEntrySequence++;
                  _expandRiskAndAnomalyOnAiEntry = false;
                }
                _selectedIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '首页',
              ),
              NavigationDestination(
                icon: _AiNavIcon(
                  icon: Icons.auto_awesome_outlined,
                  badgeCount: alert.badgeCount,
                ),
                selectedIcon: _AiNavIcon(
                  icon: Icons.auto_awesome,
                  badgeCount: alert.badgeCount,
                ),
                label: 'AI分析',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: '统计',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AiNavIcon extends StatelessWidget {
  const _AiNavIcon({required this.icon, required this.badgeCount});

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    if (badgeCount <= 0) {
      return Icon(icon);
    }
    final label = badgeCount > 99 ? '99+' : '$badgeCount';
    return Badge(label: Text(label), child: Icon(icon));
  }
}
