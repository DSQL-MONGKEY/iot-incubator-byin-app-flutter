import 'package:flutter/material.dart';

/// Field read-only yang membuka bottom sheet saat di-tap.
class SheetSelectField extends StatelessWidget {
  final String label;
  final String? value;
  final String? placeholder;
  final VoidCallback onTap;

  const SheetSelectField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.isEmpty)
        ? (placeholder ?? 'Pilih…')
        : value!;
    final isPlaceholder = value == null || value!.isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.expand_more),
          isDense: true,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isPlaceholder ? const Color(0xFF9CA3AF) : null,
            fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
