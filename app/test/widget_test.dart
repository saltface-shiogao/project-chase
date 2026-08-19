import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('App launch test', (WidgetTester tester) async {
    // main.dart の実際のクラス名は CityChaseApp
    await tester.pumpWidget(const CityChaseApp());

    // 描画が正常に行われるか確認
    expect(find.byType(CityChaseApp), findsOneWidget);
  });
}
