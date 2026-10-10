import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mon–Fri segmented picker.
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> days;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat.E(Localizations.localeOf(context).toString());
    final selected = this.selected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<DateTime>(
          showSelectedIcon: false,
          segments: [
            for (final day in days)
              ButtonSegment(value: day, label: Text(format.format(day))),
          ],
          selected: {?selected},
          emptySelectionAllowed: selected == null,
          onSelectionChanged: (selection) => onSelected(selection.single),
        ),
      ),
    );
  }
}
