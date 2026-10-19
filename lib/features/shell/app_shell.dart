import 'package:flutter/material.dart';

import '../../features/fragments/pages/fragments_page.dart';
import '../../features/kb/pages/kb_page.dart';
import '../../features/prompts/pages/prompts_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/usage/pages/usage_page.dart';

/// 一级入口定义（docs/01 第四节：灵感/提示词/资料库/用量/设置）。
class ShellTab {
  const ShellTab({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

const _tabs = <ShellTab>[
  ShellTab(
    title: '灵感',
    icon: Icons.lightbulb_outline,
    selectedIcon: Icons.lightbulb,
    page: FragmentsPage(),
  ),
  ShellTab(
    title: '提示词',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
    page: PromptsPage(),
  ),
  ShellTab(
    title: '资料库',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    page: KbPage(),
  ),
  ShellTab(
    title: '用量',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    page: UsagePage(),
  ),
  ShellTab(
    title: '设置',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    page: SettingsPage(),
  ),
];

/// 响应式导航壳（docs/01 第四节）：
/// 宽度 ≥900 → NavigationRail 带标签；700–899 → Rail 折叠纯图标；
/// <700 → 底部 NavigationBar。页面用 IndexedStack 保状态。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pages = <Widget>[for (final tab in _tabs) tab.page];

        if (width < 700) {
          return Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final tab in _tabs)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.title,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: _select,
                // ≥900 图标+标签；700–899 折叠为纯图标。
                labelType: width >= 900
                    ? NavigationRailLabelType.all
                    : NavigationRailLabelType.none,
                minWidth: 72,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Icon(Icons.auto_stories, size: 28),
                ),
                destinations: [
                  for (final tab in _tabs)
                    NavigationRailDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.selectedIcon),
                      label: Text(tab.title),
                    ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: IndexedStack(index: _index, children: pages),
              ),
            ],
          ),
        );
      },
    );
  }
}
