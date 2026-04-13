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
import '../../emergency/services/emergency_coordinator.dart';
import '../utils/post_auth_flow.dart';
import '../widgets/auth_scaffold.dart';
import 'otp_verification_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.prefillLocationEnabled = false});

  final bool prefillLocationEnabled;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final EmergencyCoordinator _emergencyCoordinator =
      EmergencyCoordinator.instance;

  bool _isLocationEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLocationEnabled = widget.prefillLocationEnabled;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _toggleLocationSharing(bool value) async {
    if (!value) {
      setState(() => _isLocationEnabled = false);
      return;
    }

    final permissionResult = await _emergencyCoordinator
        .previewLocationPermission(true);

    if (!mounted) {
      return;
    }

    setState(() => _isLocationEnabled = permissionResult.granted);

    if (!permissionResult.granted && permissionResult.message != null) {
      StatusSnackbar.show(
        context,
        message: permissionResult.message!,
        tone: StatusTone.error,
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phoneNumber = _phoneController.text.trim();
      final response = await ApiService.requestOtp(phoneNumber);
      final debugPayload = response['debug'];
      final debugHelperMessage = debugPayload is Map
          ? debugPayload['helper_message']?.toString()
          : null;
      final rawOtpLength = response['otp_length'];
      final otpLength = rawOtpLength is num
          ? rawOtpLength.toInt()
          : int.tryParse(rawOtpLength?.toString() ?? '') ?? 6;

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      if (response['success'] != true) {
        StatusSnackbar.show(
          context,
          message: response['message']?.toString() ?? 'Failed to send OTP.',
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
                bootstrapLocationSharing: _isLocationEnabled,
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
      showBackButton: false,
      heroIcon: Icons.shield_moon_outlined,
      eyebrow: 'Trusted emergency access',
      title: 'Welcome back',
      subtitle:
          'Sign in with your verified phone number so GuardianNode can connect you to nearby help quickly.',
      badge: AuthHeroBadge(
        label: _isLocationEnabled ? 'Location ready' : 'OTP sign-in',
        tone: _isLocationEnabled ? StatusTone.success : StatusTone.info,
      ),
      footer: Center(
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RegistrationScreen(
                  prefillLocationEnabled: _isLocationEnabled,
                ),
              ),
            );
          },
          child: const Text('Create a GuardianNode account'),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoBanner(
              title: 'Fastest route into the app',
              message:
                  'We use OTP to keep access simple under pressure while still protecting emergency reports and live location streams.',
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+237 ...',
                helperText:
                    'Use the same number tied to your GuardianNode profile.',
                prefixIcon: Icon(Icons.phone_iphone_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your phone number';
                }
                if (value.replaceAll(' ', '').length < 8) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
              onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile.adaptive(
                value: _isLocationEnabled,
                onChanged: _isLoading ? null : _toggleLocationSharing,
                activeThumbColor: AppColors.safetyGreen,
                activeTrackColor: AppColors.safetyGreen.withValues(alpha: 0.3),
                title: const Text('Keep location ready for emergencies'),
                subtitle: Text(
                  _isLocationEnabled
                      ? 'GuardianNode will try to route help faster once you are signed in.'
                      : 'You can sign in first and enable this later on the dashboard.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                secondary: const Icon(Icons.location_searching_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(
                  child: StatTile(
                    label: 'Access method',
                    value: 'OTP',
                    helper: 'Phone based',
                    tone: StatusTone.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatTile(
                    label: 'Location',
                    value: _isLocationEnabled ? 'Ready' : 'Optional',
                    helper: _isLocationEnabled ? 'Primed' : 'Later',
                    tone: _isLocationEnabled
                        ? StatusTone.success
                        : StatusTone.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Continue with OTP',
              icon: Icons.arrow_forward_rounded,
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: AppSpacing.md),
            const CommunityUpdateCard(
              updateText:
                  'GuardianNode uses the same backend contracts for login, registration, live alerts, and realtime subscriptions.',
            ),
          ],
        ),
      ),
    );
  }
}
