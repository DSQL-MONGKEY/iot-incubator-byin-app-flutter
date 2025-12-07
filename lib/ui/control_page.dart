import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/control/control_provider.dart';
import '../features/telemetry/telemetry_provider.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tel = context.watch<TelemetryProvider>();
    final ctrl = context.read<ControlProvider>();
    final fan = tel.last?.fan ?? List.filled(6, 0);
    final lampOn = (tel.last?.lamp ?? [1,1])[0] == 1;
    final isAuto = tel.last?.mode == 'AUTO';

    return Scaffold(
      appBar: AppBar(title: const Text('Kontrol Manual')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isAuto)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Mode: AUTO'),
                subtitle: const Text('Ubah ke MANUAL untuk mengontrol kipas/lampu'),
                trailing: FilledButton(
                  onPressed: () => ctrl.setModeManual(),
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
                title: Text('Kipas ${i+1}'),
                value: fan[i] == 1,
                onChanged: isAuto ? null : (_) => ctrl.toggleFan(i),
              ),
            ),
          const SizedBox(height: 12),
          const Text('Kontrol Lampu', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Lampu (keduanya)'),
              value: lampOn,
              onChanged: isAuto ? null : (_) => ctrl.toggleLampGroup(),
            ),
          ),
        ],
      ),
    );
  }
}
