import 'package:flutter/material.dart';
import 'package:byin_app/features/templates/template_model.dart';

class TemplateCard extends StatelessWidget {
  final IncTemplate data;
  final String? incubatorName;
  final VoidCallback? onTap;

  const TemplateCard({
    super.key,
    required this.data,
    this.incubatorName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fans = data.enabledFanIdx();
    final lamps = data.enabledLampIdx();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE9EEF7)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul
              Text(
                data.name.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              if ((data.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  data.description!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
              if ((incubatorName ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Inkubator: $incubatorName',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
              const SizedBox(height: 10),
              // Badge kipas & lampu
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in fans) _badge(
                    context,
                    icon: Icons.air,
                    label: 'Kipas ${i + 1}',
                    bg: const Color(0xFFEAF2FF),
                    fg: const Color(0xFF3B82F6),
                  ),
                  for (final i in lamps) _badge(
                    context,
                    icon: Icons.lightbulb_outline,
                    label: 'Lampu ${i + 1}',
                    bg: const Color(0xFFFFEEEE),
                    fg: const Color(0xFFEF4444),
                  ),
                  if (fans.isEmpty && lamps.isEmpty)
                    const Text('Semua OFF', style: TextStyle(color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context,
      {required IconData icon, required String label, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
