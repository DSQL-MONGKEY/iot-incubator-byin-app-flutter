import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/control/control_provider.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ControlProvider>();

    final fan = ctrl.fan;
    final lampOn = (ctrl.lamp.isNotEmpty && ctrl.lamp[0] == 1);
    final isAuto = ctrl.isAuto;

    return Scaffold(
      appBar: AppBar(title: const Text('Kontrol Manual')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ctrl.error != null)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Gagal sinkron'),
                subtitle: Text(ctrl.error!),
              ),
            ),

          if (isAuto)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Mode: AUTO'),
                subtitle: const Text('Ubah ke MANUAL untuk mengontrol kipas/lampu'),
                trailing: FilledButton(
                  onPressed: () async {
                    try {
                      await ctrl.setModeManual();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mode diubah ke MANUAL')),
                        );
                      }
                    } catch (_) {
                      // error sudah ditampilkan via ctrl.error
                    }
                  },
                  child: const Text('Set MANUAL'),
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Text('Kontrol Kipas', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          for (int i = 0; i < fan.length; i++)
            Card(
              child: SwitchListTile(
                title: Text('Kipas ${i + 1}'),
                value: fan[i] == 1,
                onChanged: (isAuto || ctrl.savingFan) ? null : (_) => ctrl.toggleFan(i),
              ),
            ),

          if (ctrl.savingFan)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(minHeight: 2),
            ),

          const SizedBox(height: 12),
          const Text('Kontrol Lampu', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          Card(
            child: SwitchListTile(
              title: const Text('Lampu (keduanya)'),
              value: lampOn,
              onChanged: (isAuto || ctrl.savingLamp) ? null : (_) => ctrl.toggleLampGroup(),
            ),
          ),

          if (ctrl.savingLamp)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
