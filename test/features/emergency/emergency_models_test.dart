import 'package:flutter_test/flutter_test.dart';

import 'package:guidiannode/features/emergency/models/emergency_models.dart';

void main() {
  group('EmergencyAlert.fromJson', () {
    test('parses AI/verification/confirmation fields when present', () {
      final alert = EmergencyAlert.fromJson({
        'id': 'alert-1',
        'user_id': 'user-1',
        'emergency_type': 'fire',
        'latitude': 5.96,
        'longitude': 10.15,
        'status': 'active',
        'confirmed_category': 'fire',
        'urgency_level': 'critical',
        'detected_language': 'pcm',
        'classification_source': 'rules',
        'verification_status': 'community_confirmed',
        'visibility_level': 'standard',
        'moderation_status': 'reviewed',
        'people_affected': 4,
        'assistance_needed': ['fire_rescue', 'medical'],
        'confirmation_counts': {
          'community_confirm': 3,
          'dispute': 1,
          'false_report': 0,
        },
        'my_confirmation_type': 'community_confirm',
      });

      expect(alert.confirmedCategory, 'fire');
      expect(alert.urgencyLevel, 'critical');
      expect(alert.detectedLanguage, 'pcm');
      expect(alert.verificationStatus, 'community_confirmed');
      expect(alert.peopleAffected, 4);
      expect(alert.assistanceNeeded, ['fire_rescue', 'medical']);
      expect(alert.communityConfirmations, 3);
      expect(alert.disputeCount, 1);
      expect(alert.myConfirmationType, 'community_confirm');
      expect(alert.isVerifiedByAuthority, isFalse);
      expect(alert.isSensitive, isFalse);
    });

    test('defaults trust fields safely when the backend omits them', () {
      final alert = EmergencyAlert.fromJson({
        'id': 'alert-2',
        'user_id': 'user-2',
        'emergency_type': 'medical',
        'latitude': 5.96,
        'longitude': 10.15,
        'status': 'active',
      });

      expect(alert.verificationStatus, 'unverified');
      expect(alert.visibilityLevel, 'standard');
      expect(alert.communityConfirmations, 0);
      expect(alert.myConfirmationType, isNull);
    });

    test('displayCategory maps legacy quick-SOS types for old alerts', () {
      final alert = EmergencyAlert.fromJson({
        'id': 'alert-3',
        'user_id': 'user-3',
        'emergency_type': 'accident',
        'latitude': 5.96,
        'longitude': 10.15,
        'status': 'active',
      });

      expect(alert.displayCategory, 'road_accident');
    });

    test('displayCategory passes through new taxonomy values sent directly as emergency_type', () {
      final alert = EmergencyAlert.fromJson({
        'id': 'alert-4',
        'user_id': 'user-4',
        'emergency_type': 'flooding_landslide',
        'latitude': 5.96,
        'longitude': 10.15,
        'status': 'active',
      });

      expect(alert.displayCategory, 'flooding_landslide');
    });

    test('officially_confirmed and responder_confirmed both read as authority-verified', () {
      for (final status in ['officially_confirmed', 'responder_confirmed']) {
        final alert = EmergencyAlert.fromJson({
          'id': 'alert-5',
          'user_id': 'user-5',
          'emergency_type': 'medical',
          'latitude': 5.96,
          'longitude': 10.15,
          'status': 'active',
          'verification_status': status,
        });

        expect(alert.isVerifiedByAuthority, isTrue, reason: status);
      }
    });
  });

  group('IncidentClassification.fromJson', () {
    test('parses an advisory classification result', () {
      final classification = IncidentClassification.fromJson({
        'category': 'fire',
        'urgency': 'critical',
        'detected_language': 'en',
        'explanation': 'Fire keywords matched near a populated place.',
        'confidence': 0.8,
        'recommended_action': 'Alert nearby responders immediately.',
        'requires_moderator_attention': true,
        'possible_spam': false,
        'assistance_needed': ['fire_rescue'],
        'classification_source': 'rules',
      });

      expect(classification.category, 'fire');
      expect(classification.urgency, 'critical');
      expect(classification.confidence, 0.8);
      expect(classification.isRuleBased, isTrue);
      expect(classification.isAiGenerated, isFalse);
      expect(classification.assistanceNeeded, ['fire_rescue']);
    });
  });
}
