import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Page to configure business operating hours
class BusinessHoursPage extends ConsumerStatefulWidget {
  const BusinessHoursPage({super.key});

  @override
  ConsumerState<BusinessHoursPage> createState() => _BusinessHoursPageState();
}

class _BusinessHoursPageState extends ConsumerState<BusinessHoursPage> {
  final Map<String, _DayHours> _businessHours = {
    'Monday': _DayHours(isOpen: true, open: const TimeOfDay(hour: 8, minute: 0), close: const TimeOfDay(hour: 17, minute: 0)),
    'Tuesday': _DayHours(isOpen: true, open: const TimeOfDay(hour: 8, minute: 0), close: const TimeOfDay(hour: 17, minute: 0)),
    'Wednesday': _DayHours(isOpen: true, open: const TimeOfDay(hour: 8, minute: 0), close: const TimeOfDay(hour: 17, minute: 0)),
    'Thursday': _DayHours(isOpen: true, open: const TimeOfDay(hour: 8, minute: 0), close: const TimeOfDay(hour: 17, minute: 0)),
    'Friday': _DayHours(isOpen: true, open: const TimeOfDay(hour: 8, minute: 0), close: const TimeOfDay(hour: 17, minute: 0)),
    'Saturday': _DayHours(isOpen: true, open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 14, minute: 0)),
    'Sunday': _DayHours(isOpen: false, open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 14, minute: 0)),
  };

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Hours'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveHours,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set your store hours',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Customers will see when your store is open',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._businessHours.entries.map((entry) {
            return _DayHoursCard(
              day: entry.key,
              hours: entry.value,
              onToggle: (isOpen) {
                setState(() {
                  _businessHours[entry.key] = entry.value.copyWith(isOpen: isOpen);
                });
              },
              onOpenChanged: (time) {
                setState(() {
                  _businessHours[entry.key] = entry.value.copyWith(open: time);
                });
              },
              onCloseChanged: (time) {
                setState(() {
                  _businessHours[entry.key] = entry.value.copyWith(close: time);
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Future<void> _saveHours() async {
    setState(() => _isSaving = true);

    // TODO: Save to Firestore when vendor profile model is available
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business hours saved'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _DayHours {
  final bool isOpen;
  final TimeOfDay open;
  final TimeOfDay close;

  _DayHours({
    required this.isOpen,
    required this.open,
    required this.close,
  });

  _DayHours copyWith({
    bool? isOpen,
    TimeOfDay? open,
    TimeOfDay? close,
  }) {
    return _DayHours(
      isOpen: isOpen ?? this.isOpen,
      open: open ?? this.open,
      close: close ?? this.close,
    );
  }
}

class _DayHoursCard extends StatelessWidget {
  const _DayHoursCard({
    required this.day,
    required this.hours,
    required this.onToggle,
    required this.onOpenChanged,
    required this.onCloseChanged,
  });

  final String day;
  final _DayHours hours;
  final void Function(bool) onToggle;
  final void Function(TimeOfDay) onOpenChanged;
  final void Function(TimeOfDay) onCloseChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: hours.isOpen,
                  onChanged: onToggle,
                ),
              ],
            ),
            if (hours.isOpen) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Open',
                      time: hours.open,
                      onChanged: onOpenChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Close',
                      time: hours.close,
                      onChanged: onCloseChanged,
                    ),
                  ),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Closed',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay time;
  final void Function(TimeOfDay) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time.format(context),
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
