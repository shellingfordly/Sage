import 'package:flutter/material.dart';

import '../../components/icons/sage_logo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';

const _appVersion = '1.1.0';
const _appAuthor = 'shellingfordly';
const _appContact = 'shellingfordly@qq.com';
const _appRepository = 'github.com/shellingfordly/Sage';
const _copyrightYear = '2026';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于应用')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              _AppHeader(),
              SizedBox(height: 28),
              _DescriptionPanel(),
              SizedBox(height: 16),
              _AuthorPanel(),
              SizedBox(height: 28),
              _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SageLogo(),
        const SizedBox(height: 16),
        Text('智账', style: AppTextStyles.pageTitle(context)),
        const SizedBox(height: 4),
        Text('Sage · 本地个人记账', style: AppTextStyles.pageSubtitle(context)),
        const SizedBox(height: 8),
        Text('版本 $_appVersion', style: AppTextStyles.bodyMuted(context)),
      ],
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(context),
      child: Text(
        '智账（Sage）是一款本地优先的个人记账应用，支持多账本、预算管理、统计图表与消费分析。所有数据仅保存在你的设备上，无需注册账号、无需联网即可使用。',
        style: AppTextStyles.bodyMuted(context).copyWith(height: 1.6),
      ),
    );
  }
}

class _AuthorPanel extends StatelessWidget {
  const _AuthorPanel();

  static const _entries = [
    (Icons.person_outline, '作者', _appAuthor),
    (Icons.mail_outline, '联系', _appContact),
    (Icons.code_outlined, '开源仓库', _appRepository),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: AppDecorations.surface(context),
          child: Column(
            children: [
              for (var i = 0; i < _entries.length; i++) ...[
                if (i > 0) const _PanelDivider(),
                _InfoTile(
                  icon: _entries[i].$1,
                  label: _entries[i].$2,
                  value: _entries[i].$3,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppDecorations.softFill(context),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMuted(context),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      color: context.colors.divider,
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '© $_copyrightYear $_appAuthor',
          style: AppTextStyles.caption(context),
        ),
        const SizedBox(height: 4),
        Text(
          '基于 Flutter 构建',
          style: AppTextStyles.caption(context),
        ),
      ],
    );
  }
}
