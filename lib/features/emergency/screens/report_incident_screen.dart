import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/guardian_components.dart';
import '../../../core/widgets/incident_taxonomy_ui.dart';
import '../../../core/widgets/status_widgets.dart';
import '../models/emergency_models.dart';
import '../services/emergency_api_service.dart';
import '../services/emergency_coordinator.dart';
import 'active_sos_map_screen.dart';

const List<String> _reportCategories = [
  'security_threat',
  'medical_emergency',
  'fire',
  'road_accident',
  'missing_person',
  'gender_based_violence',
  'natural_disaster',
  'flooding_landslide',
  'food_water_request',
  'shelter_request',
  'infrastructure_hazard',
  'public_health_concern',
  'other',
];

const List<String> _urgencyLevels = ['critical', 'high', 'medium', 'low'];

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

class _ExamplePhrase {
  const _ExamplePhrase(this.language, this.text);
  final String language;
  final String text;
}

const List<_ExamplePhrase> _examplePhrases = [
  _ExamplePhrase('EN', 'Fire is burning near the market.'),
  _ExamplePhrase('EN', 'A child is missing.'),
  _ExamplePhrase('EN', 'Road accident with injured passengers.'),
  _ExamplePhrase('EN', 'We need food and drinking water.'),
  _ExamplePhrase('Pidgin', 'Gunshots di happen for Mile 3.'),
  _ExamplePhrase('Pidgin', 'Person don wound and we need ambulance.'),
  _ExamplePhrase('Français', "Il y a un incendie pres du marche."),
  _ExamplePhrase('Français', 'Accident de la route avec des blesses.'),
];

/// The structured, multilingual free-text incident report flow. This
/// complements (does not replace) the quick 2x2 SOS category sheet -- use
/// this when the situation isn't an instant life-threatening SOS but still
/// needs to reach nearby helpers with real detail.
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final EmergencyCoordinator _coordinator = EmergencyCoordinator.instance;
  final TextEditingController _descriptionController = TextEditingController();
  final PageController _pageController = PageController();

  int _step = 0;
  int _peopleAffected = 1;
  bool _immediateDanger = false;
  final Set<String> _selectedAssistance = <String>{};

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  IncidentClassification? _classification;
  bool _isClassifying = false;
  String? _classificationError;
  String? _confirmedCategory;
  String? _confirmedUrgency;
  bool _isSubmitting = false;

  static const int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_handleDescriptionChanged);
  }

  void _handleDescriptionChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_handleDescriptionChanged);
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );

    if (step == 3 && _classification == null) {
      unawaited(_runClassification());
    }
  }

  Future<void> _runClassification() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      return;
    }

    setState(() {
      _isClassifying = true;
      _classificationError = null;
    });

    try {
      final result = await EmergencyApiService.classifyReport(description: description);

      if (!mounted) {
        return;
      }

      setState(() {
        _classification = result;
        _confirmedCategory = result.category;
        _confirmedUrgency = _immediateDanger ? 'critical' : result.urgency;
        _isClassifying = false;
        if (_selectedAssistance.isEmpty) {
          _selectedAssistance.addAll(result.assistanceNeeded);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isClassifying = false;
        _classificationError =
            'Automatic suggestion is unavailable right now. Pick a category manually below -- your report will still be sent.';
        _confirmedCategory ??= 'other';
        _confirmedUrgency ??= _immediateDanger ? 'critical' : 'medium';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _pickedImage = file;
        _pickedImageBytes = bytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      StatusSnackbar.show(
        context,
        message: 'Could not open the photo library. You can still submit without a photo.',
        tone: StatusTone.warning,
      );
    }
  }

  String _mimeTypeForImage(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    final category = _confirmedCategory ?? 'other';
    final urgency = _immediateDanger ? 'critical' : (_confirmedUrgency ?? 'medium');
    final suggestion = _classification;
    final unedited = suggestion != null &&
        suggestion.category == category &&
        suggestion.urgency == urgency;

    setState(() => _isSubmitting = true);

    try {
      final alert = await _coordinator.triggerSos(
        emergencyType: category,
        description: description,
        suggestedCategory: suggestion?.category,
        confirmedCategory: category,
        urgencyLevel: urgency,
        classificationSource: unedited ? suggestion.classificationSource : 'user',
        classificationConfidence: unedited ? suggestion.confidence : null,
        detectedLanguage: suggestion?.detectedLanguage,
        aiExplanation: suggestion?.explanation,
        recommendedAction: suggestion?.recommendedAction,
        peopleAffected: _peopleAffected,
        assistanceNeeded: _selectedAssistance.toList(),
        immediateDanger: _immediateDanger,
      );

      if (_pickedImage != null && _pickedImageBytes != null) {
        try {
          await EmergencyApiService.uploadAlertMedia(
            alertId: alert.id,
            bytes: _pickedImageBytes!,
            filename: _pickedImage!.name,
            mimeType: _mimeTypeForImage(_pickedImage!),
          );
        } catch (_) {
          // Evidence upload is best-effort; the report itself already went
          // through, so a failed photo upload must never look like a
          // failed submission.
        }
      }

      if (!mounted) {
        return;
      }

      StatusSnackbar.show(
        context,
        message: 'Report sent. Nearby helpers are being notified now.',
        tone: StatusTone.error,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ActiveSosMapScreen()),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      StatusSnackbar.show(
        context,
        message: ApiClient.friendlyMessage(
          error,
          fallback: 'The report could not be sent. Please try again.',
        ),
        tone: StatusTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            GuardianAppBar(
              title: 'Describe the emergency',
              subtitle: 'Step ${_step + 1} of $_totalSteps',
            ),
            _StepProgress(step: _step, totalSteps: _totalSteps),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _DescribeStep(
                    controller: _descriptionController,
                    onExampleTap: (text) {
                      setState(() {
                        _descriptionController.text = text;
                        _classification = null;
                      });
                    },
                  ),
                  _DetailsStep(
                    peopleAffected: _peopleAffected,
                    immediateDanger: _immediateDanger,
                    selectedAssistance: _selectedAssistance,
                    onPeopleChanged: (value) => setState(() => _peopleAffected = value),
                    onDangerChanged: (value) => setState(() => _immediateDanger = value),
                    onAssistanceToggled: (key) => setState(() {
                      if (_selectedAssistance.contains(key)) {
                        _selectedAssistance.remove(key);
                      } else {
                        _selectedAssistance.add(key);
                      }
                    }),
                  ),
                  _PhotoStep(
                    imageBytes: _pickedImageBytes,
                    onPickImage: _pickImage,
                    onRemoveImage: () => setState(() {
                      _pickedImage = null;
                      _pickedImageBytes = null;
                    }),
                  ),
                  _ReviewStep(
                    description: _descriptionController.text.trim(),
                    isClassifying: _isClassifying,
                    classification: _classification,
                    classificationError: _classificationError,
                    confirmedCategory: _confirmedCategory,
                    confirmedUrgency: _immediateDanger ? 'critical' : _confirmedUrgency,
                    immediateDanger: _immediateDanger,
                    onCategoryChanged: (value) => setState(() => _confirmedCategory = value),
                    onUrgencyChanged: (value) => setState(() => _confirmedUrgency = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlineActionButton(
                        text: 'Back',
                        onPressed: _isSubmitting ? null : () => _goToStep(_step - 1),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: _step == _totalSteps - 1
                        ? PrimaryButton(
                            text: context.tr('send_report'),
                            isLoading: _isSubmitting,
                            onPressed:
                                _descriptionController.text.trim().isEmpty || _isSubmitting
                                ? null
                                : _submit,
                          )
                        : PrimaryButton(
                            text: _step == 0 ? 'Next' : 'Continue',
                            onPressed: _step == 0 && _descriptionController.text.trim().isEmpty
                                ? null
                                : () => _goToStep(_step + 1),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.totalSteps});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final active = index <= step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: active ? AppColors.trustBlue : AppColors.backgroundAltFor(context),
                borderRadius: AppRadii.pill,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DescribeStep extends StatelessWidget {
  const _DescribeStep({required this.controller, required this.onExampleTap});

  final TextEditingController controller;
  final ValueChanged<String> onExampleTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('describe_emergency'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('describe_emergency_hint'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            maxLines: 5,
            minLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'e.g. "Fire is burning near the market" or "Gunshots di happen for Mile 3."',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Need an example?',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final phrase in _examplePhrases)
                ActionChip(
                  label: Text('${phrase.language}: "${phrase.text}"'),
                  onPressed: () => onExampleTap(phrase.text),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.peopleAffected,
    required this.immediateDanger,
    required this.selectedAssistance,
    required this.onPeopleChanged,
    required this.onDangerChanged,
    required this.onAssistanceToggled,
  });

  final int peopleAffected;
  final bool immediateDanger;
  final Set<String> selectedAssistance;
  final ValueChanged<int> onPeopleChanged;
  final ValueChanged<bool> onDangerChanged;
  final ValueChanged<String> onAssistanceToggled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who needs help?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'People affected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: peopleAffected > 1 ? () => onPeopleChanged(peopleAffected - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$peopleAffected', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                onPressed: () => onPeopleChanged(peopleAffected + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: immediateDanger,
            onChanged: onDangerChanged,
            title: Text(context.tr('immediate_danger_question')),
            subtitle: Text(
              'This raises the urgency to critical.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'What kind of help is needed?',
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
                  selected: selectedAssistance.contains(entry.key),
                  onSelected: (_) => onAssistanceToggled(entry.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.imageBytes,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a photo (optional)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A photo helps responders understand the situation. You can skip this step.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          if (imageBytes != null)
            ClipRRect(
              borderRadius: AppRadii.card,
              child: Stack(
                children: [
                  Image.memory(imageBytes!, height: 220, width: double.infinity, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      style: IconButton.styleFrom(backgroundColor: Colors.black45),
                      onPressed: onRemoveImage,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Choose a photo'),
            ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.description,
    required this.isClassifying,
    required this.classification,
    required this.classificationError,
    required this.confirmedCategory,
    required this.confirmedUrgency,
    required this.immediateDanger,
    required this.onCategoryChanged,
    required this.onUrgencyChanged,
  });

  final String description;
  final bool isClassifying;
  final IncidentClassification? classification;
  final String? classificationError;
  final String? confirmedCategory;
  final String? confirmedUrgency;
  final bool immediateDanger;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onUrgencyChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review and confirm',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '"$description"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isClassifying)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: AppSpacing.sm),
                  Text('Suggesting a category...'),
                ],
              ),
            )
          else if (classification != null) ...[
            StatusBanner.info(
              title: classification!.isRuleBased
                  ? 'Rule-based suggestion (AI unavailable)'
                  : 'AI-assisted suggestion',
              message: classification!.explanation.isEmpty
                  ? 'This is advisory only -- please confirm or correct it below.'
                  : classification!.explanation,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confidence: ${(classification!.confidence * 100).round()}% • ${classification!.recommendedAction}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ] else if (classificationError != null)
            StatusBanner.warning(message: classificationError!),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Category (you can correct this)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final category in _reportCategories)
                ChoiceChip(
                  label: Text(IncidentCategoryUi.label(category)),
                  selected: confirmedCategory == category,
                  onSelected: (_) => onCategoryChanged(category),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Urgency',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (immediateDanger)
            StatusBanner.error(
              message: 'Set to Critical because you indicated immediate danger.',
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final urgency in _urgencyLevels)
                  ChoiceChip(
                    label: Text(UrgencyUi.label(urgency)),
                    selected: confirmedUrgency == urgency,
                    onSelected: (_) => onUrgencyChanged(urgency),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'This helps nearby responders and is never treated as confirmation that the emergency is real -- a human always reviews high-impact reports.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
