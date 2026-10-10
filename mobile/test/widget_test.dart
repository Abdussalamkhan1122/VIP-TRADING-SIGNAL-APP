import 'package:flutter_test/flutter_test.dart';
import 'package:hurrair_vip_trading/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows app title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HurrairApp());
    await tester.pump();
    expect(find.text('Hurrair VIP Trading'), findsOneWidget);
  });
}
