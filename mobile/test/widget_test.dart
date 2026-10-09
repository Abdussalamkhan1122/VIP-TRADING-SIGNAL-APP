import 'package:flutter_test/flutter_test.dart';
import 'package:hurrair_vip_trading/main.dart';

void main() {
  testWidgets('shows app title', (tester) async {
    await tester.pumpWidget(const HurrairApp());
    expect(find.text('Hurrair VIP Trading'), findsOneWidget);
  });
}

