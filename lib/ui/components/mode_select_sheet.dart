

import 'package:flutter/material.dart';

Future<String?> showModeSelectSheet(BuildContext context, String current) {
  const opts = ['AUTO', 'MANUAL'];

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: false,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Column(
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
              trailing: (m == current) ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () => Navigator.pop(context, m),
            ),
          const SizedBox(height: 8),
        ],
      ),
    )
  );
}