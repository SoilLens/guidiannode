import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guidiannode/core/theme/theme.dart';
import 'package:guidiannode/core/widgets/buttons.dart';

void main() {
  testWidgets('SosButton triggers callback on tap', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SosButton(
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SOS'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('PrimaryButton shows loading spinner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: PrimaryButton(text: 'Continue', isLoading: true),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });
}
