import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthPickerRow extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  const MonthPickerRow({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy').format(month);
    return Row(
      children: [
        IconButton(
          tooltip: 'Bulan sebelumnya',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Expanded(
          child: TextButton(
            onPressed: onPick,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Bulan berikutnya',
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}
