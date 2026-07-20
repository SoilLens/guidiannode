import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bottom_sheets.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/status_widgets.dart';
import '../services/role_api_service.dart';

const Map<String, String> _sensitiveRoleLabels = {
  'verified_responder': 'Verified Responder',
  'medical_responder': 'Medical Responder',
  'security_responder': 'Security Responder',
  'humanitarian_responder': 'Humanitarian Responder',
};

const Map<String, String> _assistanceLabels = {
  'medical': 'Medical care',
  'security': 'Security / police',
  'fire_rescue': 'Fire & rescue',
  'transport': 'Transport',
  'shelter': 'Shelter',
  'food_water': 'Food or water',
  'search': 'Search / find someone',
  'counselling': 'Counselling support',
  'translation': 'Translation help',
  'general': 'General help',
};

/// A request submitted here never grants elevated access by itself -- an
/// administrator must approve it before the role becomes active.
class RoleRequestSheet extends StatefulWidget {
  const RoleRequestSheet({super.key, required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  State<RoleRequestSheet> createState() => _RoleRequestSheetState();
}

class _RoleRequestSheetState extends State<RoleRequestSheet> {
  String _selectedRole = _sensitiveRoleLabels.keys.first;
  final Set<String> _capabilities = <String>{};
  double _serviceRadiusKm = 3;
  final _organisationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _organisationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      await RoleApiService.requestRole(
        requestedRole: _selectedRole,
        assistanceCapabilities: _capabilities.toList(),
        serviceRadiusMeters: (_serviceRadiusKm * 1000).round(),
        organisation: _organisationController.text.trim().isEmpty
            ? null
            : _organisationController.text.trim(),
        verificationNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onSubmitted();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      StatusSnackbar.show(
        context,
        message: ApiClient.friendlyMessage(
          error,
          fallback: 'Could not submit your request. Please try again.',
        ),
        tone: StatusTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Request a responder role',
      subtitle:
          'An administrator reviews every request before it takes effect. You stay a citizen/helper in the meantime.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final entry in _sensitiveRoleLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _selectedRole == entry.key,
                    onSelected: (_) => setState(() => _selectedRole = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'What can you help with?',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final entry in _assistanceLabels.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: _capabilities.contains(entry.key),
                    onSelected: (_) => setState(() {
                      if (_capabilities.contains(entry.key)) {
                        _capabilities.remove(entry.key);
                      } else {
                        _capabilities.add(entry.key);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Service radius: ${_serviceRadiusKm.round()} km',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Slider(
              value: _serviceRadiusKm,
              min: 1,
              max: 20,
              divisions: 19,
              label: '${_serviceRadiusKm.round()} km',
              onChanged: (value) => setState(() => _serviceRadiusKm = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _organisationController,
              decoration: const InputDecoration(
                labelText: 'Organisation (optional)',
                hintText: 'e.g. Red Cross, a clinic, a church group',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Supporting information (optional)',
                hintText: 'Training, certifications, or relevant experience',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Submit request',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
