


import 'package:byin_app/features/incubators/incubator_model.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'package:byin_app/mqtt/mqtt_service.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:byin_app/ui/components/mode_select_sheet.dart';
import 'package:byin_app/ui/components/pill_button.dart';
import 'package:byin_app/ui/components/template_select_sheet.dart';
import 'package:byin_app/ui/control_page.dart';
import 'package:byin_app/ui/utils/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModeTemplateCard extends StatefulWidget {
  const ModeTemplateCard({ super.key });

  @override
  State<ModeTemplateCard> createState() => _ModeTemplateCardState();
}

class _ModeTemplateCardState extends State<ModeTemplateCard> {
  bool _busy = false;

  ApiClient get _api => context.read<ApiClient>();
  MqttService get _mqtt => context.read<MqttService>();
  Incubator? get _inc => context.read<IncubatorProvider>().selected;

  Future<void> _onChangeMode() async {
    final inc = _inc;
    if (inc == null) return;

    final current = (inc.mode ?? 'AUTO').toUpperCase();
    final chosen = await showModeSelectSheet(context, current);

    if (chosen == null || chosen == current) return;

    final ok = await confirmDialog(
      context, 
      title: 'Ubah mode ke $chosen', 
      message: chosen == 'MANUAL'
        ? 'Mode MANUAL memberi kontrol langsung ke kipas/lampu dari aplikasi.'
        : 'Mode AUTO membuat kipas berjalan otomatis mengikuti ambang.',
    );

    if (!ok) return;

    setState(() => _busy = true);

    try {
      await _api.setIncubatorMode(inc.id, chosen);

      final gotAck = await _waitAckSafe(inc.code, type: 'control-mode');

      if (!mounted) return;

      showToast(context, gotAck ? 'Mode diubah ke $chosen' : 'Mode diubah (tanpa ACK)');

      context.read<IncubatorProvider>().refresh();
    } catch (e) {
      if (mounted) showToast(context, 'Gagal mengubah mdoe: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onOpenTemplates() async {
    final inc = _inc;
    if (inc == null) return;

    await showTemplateSelectSheet(
      context: context, 
      incubatorId: inc.id, 
      incubatorCode: inc.code, 
      api: _api, 
      mqtt: _mqtt, 
      onApplied: () => context.read<IncubatorProvider>().refresh(), 
      onDeleted: () {}, 
      onNavigateCreate: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ControlPage()))
    );
  }

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncubatorProvider>().selected;
    final mode = (inc?.mode ?? 'AUTO').toUpperCase();

    return AbsorbPointer(
      absorbing: _busy || inc == null,
      child: Opacity(
        opacity: inc == null ? 0.5 : 1,
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE9EEF7)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'MODE: $mode', 
                        selected: true, onTap: _onChangeMode
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PillButton(
                        label: 'TEMPLATE',
                        selected: false,
                        onTap: _onOpenTemplates,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: inc == null
                      ? null
                      : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ControlPage())
                      ),
                    icon: const Icon(Icons.tune),
                    label: const Text('Kontrol Kipas & Lampu'),
                  ),
                ),
                if (_busy) const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _waitAckSafe(String code, { required String type}) async {
    try {
      await _mqtt.ensureSubscribeAck(code);
      return _mqtt.waitAck(type: type, timeout: const Duration(seconds: 5));
    } catch (_) {
      return false;
    }
  }
}