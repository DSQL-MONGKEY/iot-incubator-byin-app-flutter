import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'package:byin_app/features/telemetry/telemetry_provider.dart';

Future<String?> showModeSelectSheet(BuildContext context) {
  const opts = ['AUTO', 'MANUAL'];

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: false,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Consumer2<IncubatorProvider, TelemetryProvider>(
        builder: (ctx, incProv, telProv, __) {
          // ✅ source of truth sama seperti ModeTemplateCard
          final current =
              (telProv.mode ?? incProv.selected?.mode ?? 'AUTO').toUpperCase();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Pilih Mode'),
                subtitle: Text('Pilih mode AUTO / MANUAL untuk diterapkan pada inkubator'),
              ),
              for (final m in opts)
                ListTile(
                  leading: Icon(m == 'AUTO' ? Icons.auto_mode : Icons.touch_app),
                  title: Text(m),
                  subtitle: Text(
                    m == 'AUTO'
                        ? 'Kipas mengikuti ambang suhu & kelembapan'
                        : 'Mengatur kipas/lampu secara langsung dari aplikasi',
                  ),
                  trailing: (m == current)
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(ctx, m),
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    ),
  );
}
