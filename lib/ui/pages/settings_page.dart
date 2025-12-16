import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:byin_app/ui/widgets/incubator_dropdown.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'package:byin_app/features/settings/sensor_params_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _inited = false;
  String? _lastIncId;

  // Controllers (biar gampang sinkron teks <-> provider)
  final _tempMinC = TextEditingController();
  final _tempMaxC = TextEditingController();
  final _rhMin = TextEditingController();
  final _rhMax = TextEditingController();
  final _minOnMs = TextEditingController();
  final _minOffMs = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      _bootstrap();
    } else {
      // kalau user ganti inkubator dari dropdown → reload
      final sel = context.read<IncubatorProvider>().selected;
      if (sel?.id != null && sel!.id != _lastIncId) {
        _lastIncId = sel.id;
        context.read<SensorParamsProvider>().load(sel.id);
      }
    }
  }

  Future<void> _bootstrap() async {
    final sel = context.read<IncubatorProvider>().selected;
    if (sel != null) {
      _lastIncId = sel.id;
      await context.read<SensorParamsProvider>().load(sel.id);
    }
  }

  @override
  void dispose() {
    _tempMinC.dispose();
    _tempMaxC.dispose();
    _rhMin.dispose();
    _rhMax.dispose();
    _minOnMs.dispose();
    _minOffMs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incSel = context.watch<IncubatorProvider>().selected;
    final sp = context.watch<SensorParamsProvider>();
    final theme = Theme.of(context);

    // sinkron controller saat data berubah
    if (sp.params != null) {
      _tempMinC.text = _numToStr(sp.params!.tempOffC);
      _tempMaxC.text = _numToStr(sp.params!.tempOnC);
      _rhMin.text = _numToStr(sp.params!.rhOffPercent);
      _rhMax.text = _numToStr(sp.params!.rhOnPercent);
      _minOnMs.text = (sp.params!.minOnMs ?? 0).toString();
      _minOffMs.text = (sp.params!.minOffMs ?? 0).toString();
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final s = context.read<IncubatorProvider>().selected;
            if (s != null) await context.read<SensorParamsProvider>().load(s.id);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Text('Pengaturan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Atur threshold sensor inkubator', style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 16),

              // Inkubator chooser (reusable card)
              IncubatorDropdownCard(
                compact: true,
                heading: 'Inkubator',
                onChanged: (_) {
                  final s = context.read<IncubatorProvider>().selected;
                  if (s != null) context.read<SensorParamsProvider>().load(s.id);
                },
              ),
              const SizedBox(height: 16),

              if (sp.loading && sp.params == null) ...[
                _skeleton(),
                const SizedBox(height: 12),
                _skeleton(),
                const SizedBox(height: 12),
                _skeleton(),
              ] else if (incSel == null) ...[
                _empty('Pilih inkubator terlebih dahulu'),
              ] else if (sp.error != null) ...[
                _error(sp.error!, onRetry: () => sp.load(incSel.id)),
              ] else if (sp.params != null) ...[
                // --- Threshold Suhu ---
                _SectionCard(
                  title: 'Threshold Suhu',
                  icon: Icons.thermostat, iconBg: const Color(0xFFFFEEF0), iconFg: const Color(0xFFEF476F),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suhu Minimum (°C)'),
                      const SizedBox(height: 6),
                      _NumberField(
                        controller: _tempMinC,
                        hint: 'mis. 36.30',
                        onChanged: (v) => sp.setTempOff(double.tryParse(v) ?? sp.params!.tempOffC),
                      ),
                      const SizedBox(height: 12),
                      const Text('Suhu Maksimum (°C)'),
                      const SizedBox(height: 6),
                      _NumberField(
                        controller: _tempMaxC,
                        hint: 'mis. 36.70',
                        onChanged: (v) => sp.setTempOn(double.tryParse(v) ?? sp.params!.tempOnC),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // --- Threshold Kelembapan ---
                _SectionCard(
                  title: 'Threshold Kelembapan',
                  icon: Icons.water_drop, iconBg: const Color(0xFFEFF6FF), iconFg: const Color(0xFF4D7CFE),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kelembapan Minimum (%)'),
                      const SizedBox(height: 6),
                      _NumberField(
                        controller: _rhMin,
                        hint: 'mis. 50.0',
                        onChanged: (v) => sp.setRhOff(double.tryParse(v) ?? sp.params!.rhOffPercent),
                      ),
                      const SizedBox(height: 12),
                      const Text('Kelembapan Maksimum (%)'),
                      const SizedBox(height: 6),
                      _NumberField(
                        controller: _rhMax,
                        hint: 'mis. 60.0',
                        onChanged: (v) => sp.setRhOn(double.tryParse(v) ?? sp.params!.rhOnPercent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // --- Anti Chatter ---
                _SectionCard(
                  title: 'Anti Chatter',
                  icon: Icons.autorenew, iconBg: const Color(0xFFF1F5F9), iconFg: const Color(0xFF0EA5E9),
                  trailing: Switch(
                    value: sp.params!.antiChatter,
                    onChanged: (v) => sp.setAntiChatter(v),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Durasi Minimum ON (ms)'),
                      const SizedBox(height: 6),
                      _IntField(
                        controller: _minOnMs,
                        hint: 'mis. 5000',
                        onChanged: (v) => sp.setMinOn(int.tryParse(v)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Durasi Minimum OFF (ms)'),
                      const SizedBox(height: 6),
                      _IntField(
                        controller: _minOffMs,
                        hint: 'mis. 3000',
                        onChanged: (v) => sp.setMinOff(int.tryParse(v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- Simpan ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: sp.loading ? null : () async {
                      final inc = context.read<IncubatorProvider>().selected;
                      if (inc == null) return;

                      try {
                        final ack = await context.read<SensorParamsProvider>().save(
                          incubatorId: inc.id,
                          incubatorCode: inc.code,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ack ? 'Pengaturan tersimpan & ACK diterima' : 'Pengaturan tersimpan (ACK tidak diterima)')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyimpan: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan Pengaturan'),
                  ),
                ),
                if (sp.loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _numToStr(num v) => (v is int) ? v.toString() : v.toStringAsFixed(2);

  Widget _skeleton() => Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9EEF7)),
        ),
      );

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(child: Text(msg)),
      );

  Widget _error(String msg, {required VoidCallback onRetry}) => Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Coba lagi'),
          ),
        ],
      );
}

/// --- UI atoms ---

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9EEF7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(radius: 16, backgroundColor: iconBg, child: Icon(icon, color: iconFg)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const _NumberField({required this.controller, this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: _decoration(hint),
      onChanged: onChanged,
    );
  }
}

class _IntField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const _IntField({required this.controller, this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _decoration(hint),
      onChanged: onChanged,
    );
  }
}

InputDecoration _decoration(String? hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F7FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9EEF7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9EEF7)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
