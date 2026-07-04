import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const JizhangApp());
    expect(find.text('记账本'), findsOneWidget);
  });
}
