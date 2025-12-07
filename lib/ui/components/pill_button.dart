import 'package:flutter/material.dart';

class PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const PillButton({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4D7CFE) : const Color(0xFFF1F4FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF49536E),
          ),
        ),
      ),
    );
  }
}
