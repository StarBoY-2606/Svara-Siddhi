import 'package:flutter_test/flutter_test.dart';

import 'package:svara_siddhi/main.dart';

void main() {
  testWidgets('App launches and shows home title', (WidgetTester tester) async {
    await tester.pumpWidget(const SvaraSiddhiApp());

    expect(find.text('SVARA SIDDHI'), findsOneWidget);
    expect(find.text('Tap to Enter'), findsOneWidget);
  });
}
