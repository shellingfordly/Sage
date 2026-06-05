import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/ai_insight_scope.dart';
import 'pages/ai/ai_insight_route.dart';
import 'pages/analysis/analysis_page.dart';
import 'pages/home_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/charts/charts_page.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'utils/ledger_formatters.dart';
import 'pages/add_record_page.dart';

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
          fontScale: themeController.fontScale,
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
  DateTime _selectedMonth = monthStart(DateTime.now());

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
        onOpenAiPage: _openAiInsightPage,
      ),
      const AnalysisPage(key: ValueKey('analysis-page')),
      const ChartsPage(key: ValueKey('charts-page')),
      const ProfilePage(key: ValueKey('profile-page')),
    ];
  }

  void _openAiInsightPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AiInsightRoute(initialMonth: _selectedMonth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages();

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: _MainBottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        onAddRecord: () => openAddRecordPage(context),
      ),
    );
  }
}

class _MainBottomNavBar extends StatelessWidget {
  const _MainBottomNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddRecord,
  });

  final int selectedIndex;
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
                label: '分析',
                icon: Icons.manage_search_outlined,
                selectedIcon: Icons.manage_search,
                selected: selectedIndex == 1,
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
                label: '图表',
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
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

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
            Icon(selected ? selectedIcon : icon, color: color, size: 24),
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
