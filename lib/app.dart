import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ai/models/ai_insight_models.dart';
import 'ai/services/ai_alert_ack_store.dart';
import 'ai/services/ai_home_alert_service.dart';
import 'ai/services/ai_insight_cache.dart';
import 'ai/services/ai_insight_engine.dart';
import 'data/ledger_store.dart';
import 'pages/ai_insight_page.dart';
import 'pages/home_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/statistics_page.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'utils/ledger_formatters.dart';
import 'pages/add_record_page.dart';

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
  DateTime _selectedMonth = monthStart(DateTime.now());

  static const _aiIndex = 1;

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

  bool get _canGoNextMonth =>
      _selectedMonth.isBefore(monthStart(DateTime.now()));

  List<Widget> _pages() {
    return [
      HomePage(
        key: const ValueKey('home-page'),
        selectedMonth: _selectedMonth,
        canGoNextMonth: _canGoNextMonth,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        onOpenAiPage: () {
          setState(() {
            _aiEntrySequence++;
            _expandRiskAndAnomalyOnAiEntry = true;
            _selectedIndex = _aiIndex;
          });
        },
      ),
      AiInsightPage(
        key: const ValueKey('ai-insight-page'),
        selectedMonth: _selectedMonth,
        canGoNextMonth: _canGoNextMonth,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        entrySequence: _aiEntrySequence,
        expandRiskAndAnomalyOnEntry: _expandRiskAndAnomalyOnAiEntry,
      ),
      const StatisticsPage(key: ValueKey('statistics-page')),
      const ProfilePage(key: ValueKey('profile-page')),
    ];
  }

  int _badgeCount() {
    final now = DateTime.now();
    final monthReference = monthReferenceDate(_selectedMonth, now: now);
    final budget = ledgerStore.monthlyBudgetFor(_selectedMonth);
    final snapshot = _aiInsightCache.getOrBuild(
      ledgerId: ledgerStore.currentLedger.id,
      records: ledgerStore.records,
      monthlyBudget: budget,
      mode: AiSuggestionMode.balanced,
      now: monthReference,
      builder: () => _aiInsightEngine.buildSnapshot(
        records: ledgerStore.records,
        monthlyBudget: budget,
        mode: AiSuggestionMode.balanced,
        now: monthReference,
      ),
    );
    final alert = _aiHomeAlertService.evaluate(snapshot);
    final ledgerId = ledgerStore.currentLedger.id;
    return _aiHomeAlertService.visibleBadgeCount(
      alert: alert,
      budgetAcknowledged: aiAlertAckStore.isBudgetAcknowledged(
        ledgerId: ledgerId,
        snapshot: snapshot,
      ),
      anomalyAcknowledged: aiAlertAckStore.isAnomalyAcknowledged(
        ledgerId: ledgerId,
        snapshot: snapshot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages();

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: AnimatedBuilder(
        animation: Listenable.merge([ledgerStore, aiAlertAckStore]),
        builder: (context, child) {
          final badgeCount = _badgeCount();

          return _MainBottomNavBar(
            selectedIndex: _selectedIndex,
            badgeCount: badgeCount,
            onDestinationSelected: (index) {
              setState(() {
                if (index == _aiIndex && _selectedIndex != _aiIndex) {
                  _aiEntrySequence++;
                  _expandRiskAndAnomalyOnAiEntry = false;
                }
                _selectedIndex = index;
              });
            },
            onAddRecord: () => openAddRecordPage(context),
          );
        },
      ),
    );
  }
}

class _MainBottomNavBar extends StatelessWidget {
  const _MainBottomNavBar({
    required this.selectedIndex,
    required this.badgeCount,
    required this.onDestinationSelected,
    required this.onAddRecord,
  });

  final int selectedIndex;
  final int badgeCount;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.surfaceBorder)),
          ),
          child: Row(
            children: [
              _NavItem(
                label: '首页',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                selected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                label: 'AI分析',
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome,
                selected: selectedIndex == 1,
                badgeCount: badgeCount,
                onTap: () => onDestinationSelected(1),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Center(
                    child: Material(
                      color: colors.primary,
                      elevation: 4,
                      shadowColor: colors.primary.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onAddRecord,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(
                            Icons.add,
                            color: colors.onStrong,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                label: '统计',
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                selected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _NavItem(
                label: '我的',
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                selected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badgeCount > 0
                ? Badge(
                    label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                    child: Icon(
                      selected ? selectedIcon : icon,
                      color: color,
                      size: 24,
                    ),
                  )
                : Icon(selected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
