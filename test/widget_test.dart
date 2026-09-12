import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wavely/main.dart';

void main() {
  testWidgets('Wavely app launches and renders bottom navigation and tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WavelyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsWidgets);
    expect(find.text('Devices'), findsWidgets);
    expect(find.text('AR View'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Wavely'), findsOneWidget);
  });
}
