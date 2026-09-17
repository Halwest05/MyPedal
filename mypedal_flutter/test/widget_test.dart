
import 'package:flutter_test/flutter_test.dart';

import 'package:mypedal_flutter/main.dart';

void main() {
  testWidgets('Pedal screen renders in searching state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyPedalApp());

    // No server is broadcasting during tests, so the app should stay in the
    // searching state and show the corresponding UI hints.
    expect(find.text('SEARCHING FOR PC...'), findsOneWidget);
    expect(find.text('START THE PYTHON SERVER ON YOUR PC'), findsOneWidget);
  });
}
