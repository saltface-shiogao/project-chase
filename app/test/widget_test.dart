import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('App launch test', (WidgetTester tester) async {
    // MyApp を ProjectChaseApp に変更
    await tester.pumpWidget(const ProjectChaseApp());

    // 描画が正常に行われるか確認
    expect(find.byType(ProjectChaseApp), findsOneWidget);
  });
}
