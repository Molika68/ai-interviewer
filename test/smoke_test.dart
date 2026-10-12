import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_interviewer/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('首页可以正常渲染', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AiInterviewerApp()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AI 面试官'), findsWidgets);
    expect(find.text('开始面试'), findsOneWidget);
    expect(find.text('目标岗位'), findsOneWidget);
    expect(find.text('查看历史成绩'), findsOneWidget);
  });
}
