import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../emergency/models/emergency_models.dart';
import '../../emergency/services/emergency_coordinator.dart';
import '../utils/post_auth_flow.dart';
import '../widgets/auth_scaffold.dart';
import 'legal_document_screen.dart';
import 'otp_verification_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.prefillLocationEnabled = false});

  final bool prefillLocationEnabled;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _quarterController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final EmergencyCoordinator _emergencyCoordinator =
      EmergencyCoordinator.instance;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  String? _relationship;
  bool _enableLocationSharing = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  PositionSnapshot? _locationSnapshot;

  @override
  void initState() {
    super.initState();
    _enableLocationSharing = widget.prefillLocationEnabled;
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LegalDocumentScreen(
            title: 'Terms & Conditions',
            content:
                '1. Introduction\nWelcome to GuardianNode. By using our emergency alert system, you agree to these terms.\n\n2. Acceptable Use\nUse this application only for genuine emergency situations. False alarms or misuse may result in account restriction.\n\n3. Liability\nGuardianNode does not guarantee immediate responder arrival and is not liable for network failures.',
          ),
        ),
      );
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LegalDocumentScreen(
            title: 'Privacy Policy',
            content:
                '1. Data Collection\nGuardianNode stores your name, phone number, and emergency contact details for account and emergency coordination.\n\n2. Location Sharing\nYour live location is used for emergency routing and nearby alert discovery. It matters most when you trigger SOS.\n\n3. Data Security\nAuthentication and data transport rely on secure backend contracts and Supabase-backed realtime services.',
          ),
        ),
      );
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _quarterController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _toggleLocationSharing(bool value) async {
    if (!value) {
      setState(() {
        _enableLocationSharing = false;
        _locationSnapshot = null;
      });
      return;
    }

    final permissionResult = await _emergencyCoordinator
        .previewLocationPermission(true);

    if (!mounted) {
      return;
    }

    setState(() {
      _enableLocationSharing = permissionResult.granted;
      _locationSnapshot = permissionResult.snapshot;
    });

    if (!permissionResult.granted && permissionResult.message != null) {
      StatusSnackbar.show(
        context,
        message: permissionResult.message!,
        tone: StatusTone.error,
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      StatusSnackbar.show(
        context,
        message: 'Please agree to the terms before continuing.',
        tone: StatusTone.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phoneNumber = _phoneController.text.trim();

      final registrationData = {
        'full_name': _nameController.text.trim(),
        'phone_number': phoneNumber,
        'quarter': _quarterController.text.trim(),
        'location_permission': _enableLocationSharing,
        'latitude': _locationSnapshot?.latitude,
        'longitude': _locationSnapshot?.longitude,
        'emergency_contact': {
          'contact_name': _contactNameController.text.trim(),
          'phone_number': _contactPhoneController.text.trim(),
          'relationship': _relationship,
        },
      };

      final response = await ApiService.register(
        registrationData: registrationData,
      );
      final debugPayload = response['debug'];
      final debugHelperMessage = debugPayload is Map
          ? debugPayload['helper_message']?.toString()
          : null;
      final otpLength = response['otp_length'] is num
          ? (response['otp_length'] as num).toInt()
          : int.tryParse(response['otp_length']?.toString() ?? '') ?? 6;

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      if (response['success'] != true) {
        StatusSnackbar.show(
          context,
          message:
              response['message']?.toString() ??
              'Registration could not be completed.',
          tone: StatusTone.error,
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: phoneNumber,
            otpSessionId: response['otp_session_id']?.toString(),
            debugHelperMessage: debugHelperMessage,
            otpLength: otpLength > 0 ? otpLength : 6,
            onVerified: (session) {
              SessionService.setSession(session);
              PostAuthFlow.routeAfterVerification(
                context,
                bootstrapLocationSharing: _enableLocationSharing,
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      StatusSnackbar.show(
        context,
        message: 'An error occurred: $error',
        tone: StatusTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      heroIcon: Icons.person_add_alt_1_rounded,
      eyebrow: 'Create your emergency profile',
      title: 'Join GuardianNode',
      subtitle:
          'Set up your identity, your quarter, and one trusted emergency contact so the platform can act quickly when you need it.',
      badge: AuthHeroBadge(
        label: _enableLocationSharing ? 'Location primed' : 'Resident signup',
        tone: _enableLocationSharing ? StatusTone.success : StatusTone.info,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CommunityUpdateCard(
              updateText:
                  'Your registration still uses the existing backend, OTP session, and Supabase-integrated emergency flow.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Your details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+237 ...',
              ),
              validator: (value) {
                if (value == null || value.trim().length < 8) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _quarterController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Quarter / neighborhood',
                prefixIcon: Icon(Icons.location_city_outlined),
                hintText: 'For example Mile 4 or Up Station',
              ),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Enter your quarter or neighborhood';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile.adaptive(
                value: _enableLocationSharing,
                onChanged: _isLoading ? null : _toggleLocationSharing,
                activeThumbColor: AppColors.safetyGreen,
                activeTrackColor: AppColors.safetyGreen.withValues(alpha: 0.3),
                title: const Text('Allow location for emergency routing'),
                subtitle: Text(
                  _enableLocationSharing
                      ? 'Your location will be ready after account verification.'
                      : 'You can enable this later from the dashboard as well.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                secondary: const Icon(Icons.my_location_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Primary emergency contact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _contactNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Contact name',
                prefixIcon: Icon(Icons.contact_page_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Enter a contact name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Contact phone number',
                prefixIcon: Icon(Icons.contact_phone_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 8) {
                  return 'Enter a valid contact phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _relationship,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                prefixIcon: Icon(Icons.people_outline_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                DropdownMenuItem(value: 'Neighbor', child: Text('Neighbor')),
              ],
              onChanged: (value) => setState(() => _relationship = value),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Choose a relationship';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox.adaptive(
                    value: _agreedToTerms,
                    onChanged: (value) =>
                        setState(() => _agreedToTerms = value ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: Theme.of(context).textTheme.bodySmall,
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              recognizer: _termsRecognizer,
                              style: const TextStyle(
                                color: AppColors.trustBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              recognizer: _privacyRecognizer,
                              style: const TextStyle(
                                color: AppColors.trustBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ' for emergency communication, OTP verification, and profile storage.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Create account',
              icon: Icons.arrow_forward_rounded,
              isLoading: _isLoading,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
