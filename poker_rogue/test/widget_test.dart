import 'package:flutter_test/flutter_test.dart';
import 'package:poker_rogue/main.dart';

void main() {
  testWidgets('shows the poker home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PokerRogueApp());

    expect(find.text('POKER\nROGUELIKE'), findsOneWidget);
    expect(find.text('Nova partida'), findsOneWidget);
    expect(find.text('Como funciona'), findsOneWidget);
  });
}
