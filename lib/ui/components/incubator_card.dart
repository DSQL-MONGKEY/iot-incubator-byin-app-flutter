// lib/ui/components/incubator_card.dart
import 'package:flutter/material.dart';
import 'package:byin_app/features/incubators/incubator_model.dart';

class IncubatorCard extends StatelessWidget {
  final Incubator data;
  final VoidCallback? onTap;
  const IncubatorCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9EEF7)),
          boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0,4), color: Color(0x0F000000))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFFFE9E1),
              child: Icon(Icons.child_care_rounded, color: Colors.orange.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Kode: INC-${data.code}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Row(children: [
                  _dot(color: data.isOnline ? const Color(0xFF2CC84D) : const Color(0xFF95A0B6)),
                  const SizedBox(width: 6),
                  Text(data.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: data.isOnline ? const Color(0xFF2CC84D) : const Color(0xFF95A0B6),
                      )),
                  const Spacer(),
                  _chip(icon: Icons.settings_suggest_rounded, label: data.mode!),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5FF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: const Color(0xFF4D7CFE)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF4D7CFE), fontWeight: FontWeight.w600)),
        ]),
      );

  static Widget _dot({required Color color}) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
