import 'package:flutter_test/flutter_test.dart';
import 'package:enbridge/main.dart';

void main() {
  testWidgets('Enbridge smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EnbridgeApp());
    expect(find.text('ENBRIDGE'), findsWidgets);
  });
}
