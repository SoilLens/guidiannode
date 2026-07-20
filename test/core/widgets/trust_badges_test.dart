import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guidiannode/core/theme/theme.dart';
import 'package:guidiannode/core/widgets/trust_badges.dart';

void main() {
  testWidgets('VerificationBadge shows a distinct label for each trust state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              VerificationBadge(status: 'unverified'),
              VerificationBadge(status: 'officially_confirmed'),
              VerificationBadge(status: 'false_report'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Unverified'), findsOneWidget);
    expect(find.text('Officially confirmed'), findsOneWidget);
    expect(find.text('False report'), findsOneWidget);
  });

  testWidgets('UrgencyBadge shows a distinct label for each urgency level', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              UrgencyBadge(urgency: 'critical'),
              UrgencyBadge(urgency: 'low'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Critical'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
  });

  testWidgets(
    'AlertConfirmationActions disables the confirm chip once the viewer already confirmed',
    (tester) async {
      var confirmTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AlertConfirmationActions(
              communityConfirmations: 3,
              myConfirmationType: 'community_confirm',
              onConfirm: () => confirmTapped = true,
              onDispute: () {},
            ),
          ),
        ),
      );

      expect(find.text('3 people confirmed this'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(confirmTapped, isFalse);
    },
  );

  testWidgets(
    'AlertConfirmationActions hides itself entirely for the reporter\'s own alert',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AlertConfirmationActions(
              communityConfirmations: 0,
              isOwnAlert: true,
            ),
          ),
        ),
      );

      expect(find.byType(AlertConfirmationActions), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
    },
  );
}
