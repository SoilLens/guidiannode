import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guidiannode/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GuardianNodeApp boots into splash experience', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const GuardianNodeApp());

    expect(find.text('GuardianNode'), findsOneWidget);
    expect(find.text('Preparing your safety network'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
  });
}
