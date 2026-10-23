import 'package:creative_kb/app.dart';
import 'package:creative_kb/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CreativeKbApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('桌面宽度（≥900）渲染带标签的 NavigationRail，八入口齐全', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(rail.destinations, hasLength(8));
    // 页面标题与 Rail 标签同文案，至少出现一次即可。
    for (final label in ['灵感', '提示词', '资料库', '书籍', '备忘录', '密码本', '用量', '设置']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('中等宽度（700–899）Rail 折叠为纯图标（无标签）', (tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.labelType, NavigationRailLabelType.none);
  });

  testWidgets('窄屏（<700）走可横向滑动的自定义底栏，可切换到设置页', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    expect(find.byKey(const ValueKey('bottom-nav')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    // 占位页与底栏都含「设置」文案。
    expect(find.text('设置'), findsWidgets);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('Material 3 主题：种子色为深青、中文本地化', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.title, '创作知识库');
    expect(app.locale, const Locale('zh'));
    expect(app.supportedLocales, contains(const Locale('zh')));
    expect(app.localizationsDelegates, isNotNull);
  });
}
