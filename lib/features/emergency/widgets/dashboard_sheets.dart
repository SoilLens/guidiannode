import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bottom_sheets.dart';

class DashboardSheets {
  const DashboardSheets._();

  static void showEmergencyCategories(
    BuildContext context,
    Future<void> Function(String emergencyType, {String? description})
    onTrigger,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (context) => AppBottomSheet(
        title: 'Choose emergency type',
        subtitle:
            'Select the closest emergency category. GuardianNode keeps the same SOS backend flow underneath.',
        child: Column(
          children: [
            _CategoryOption(
              icon: Icons.sos_rounded,
              title: 'General distress',
              subtitle: 'Immediate help needed',
              onTap: () {
                Navigator.of(context).pop();
                onTrigger('general_distress');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _CategoryOption(
              icon: Icons.local_hospital_outlined,
              title: 'Medical emergency',
              subtitle: 'Illness, injury, urgent care',
              onTap: () {
                Navigator.of(context).pop();
                onTrigger('medical');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _CategoryOption(
              icon: Icons.local_fire_department_outlined,
              title: 'Fire emergency',
              subtitle: 'Smoke, flames, or evacuation risk',
              onTap: () {
                Navigator.of(context).pop();
                onTrigger('fire');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _CategoryOption(
              icon: Icons.security_outlined,
              title: 'Security emergency',
              subtitle: 'Violence, threat, or unsafe situation',
              onTap: () {
                Navigator.of(context).pop();
                onTrigger('security');
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showMapLegend(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const AppBottomSheet(
        title: 'Map legend',
        subtitle:
            'Use the map to see your position, active alerts, and response access points.',
        child: Column(
          children: [
            _LegendRow(
              color: AppColors.safetyGreen,
              label: 'Your current location',
            ),
            SizedBox(height: AppSpacing.sm),
            _LegendRow(color: AppColors.error, label: 'Active SOS alert'),
            SizedBox(height: AppSpacing.sm),
            _LegendRow(
              color: AppColors.communityYellow,
              label: 'Support and awareness overlay',
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.trustBlueSurface,
          borderRadius: AppRadii.card,
        ),
        child: Icon(icon, color: AppColors.trustBlueDark),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label)),
      ],
    );
  }
}
