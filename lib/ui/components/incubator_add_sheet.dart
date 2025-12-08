// lib/ui/components/incubator_add_sheet.dart
import 'package:byin_app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';

Future<void> showAddIncubatorSheet(BuildContext context) async {
  final form = GlobalKey<FormState>();
  final codeC = TextEditingController();
  final nameC = TextEditingController();
  final locC  = TextEditingController();
  final fwC   = TextEditingController(); // opsional
  String status = 'ONLINE';
  String mode   = 'AUTO';
  bool submitting = false;

  InputDecoration deco(String hint) => InputDecoration(
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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        Future<void> onSubmit() async {
          if (!form.currentState!.validate()) return;
          setState(() => submitting = true);
          try {
            await ctx.read<ApiClient>().createIncubator(
                  incubatorCode: codeC.text.trim(),
                  name: nameC.text.trim(),
                  status: status,
                  mode: mode,
                  locationLabel: locC.text.trim().isEmpty ? null : locC.text.trim(),
                  fwVersion: fwC.text.trim().isEmpty ? null : fwC.text.trim(),
                );
            if (Navigator.canPop(ctx)) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inkubator berhasil ditambahkan')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menyimpan: $e')),
              );
            }
          } finally {
            if (context.mounted) setState(() => submitting = false);
          }
        }

        final viewPadding = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: viewPadding),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Form(
                key: form,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(
                      child: Text('Tambah Inkubator',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  ]),
                  const SizedBox(height: 12),
                  // Kode
                  const Text('Kode Inkubator'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: codeC,
                    decoration: deco('Contoh: INC-001  (isi hanya angka: 001)'),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Kode wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  // Nama
                  const Text('Nama Inkubator'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameC,
                    decoration: deco('Contoh: Inkubator Ruang A1'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  // Lokasi (opsional)
                  const Text('Lokasi (opsional)'),
                  const SizedBox(height: 6),
                  TextFormField(controller: locC, decoration: deco('Mis. NICU Room 2')),
                  const SizedBox(height: 12),

                  // Status
                  const Text('Status'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: deco(''),
                    items: const [
                      DropdownMenuItem(value: 'ONLINE', child: _StatusLabel('ONLINE')),
                      DropdownMenuItem(value: 'OFFLINE', child: _StatusLabel('OFFLINE')),
                    ],
                    onChanged: (v) => setState(() => status = v ?? 'ONLINE'),
                  ),
                  const SizedBox(height: 12),

                  // Mode
                  const Text('Mode'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: mode,
                    decoration: deco(''),
                    items: const [
                      DropdownMenuItem(value: 'AUTO', child: Text('AUTO')),
                      DropdownMenuItem(value: 'MANUAL', child: Text('MANUAL')),
                    ],
                    onChanged: (v) => setState(() => mode = v ?? 'AUTO'),
                  ),
                  const SizedBox(height: 12),

                  // Firmware (opsional)
                  const Text('Firmware Version (opsional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: fwC,
                    decoration: deco('Biarkan kosong untuk default backend (iot-byin@1.0.0)'),
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: submitting ? null : onSubmit,
                      child: const Text('Simpan Inkubator'),
                    ),
                  ),
                  if (submitting) const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ]),
              ),
            ),
          ),
        );
      });
    },
  );
}

class _StatusLabel extends StatelessWidget {
  final String text;
  const _StatusLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final on = text == 'ONLINE';
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: on ? const Color(0xFF2CC84D) : const Color(0xFF95A0B6),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),
      Text(text),
    ]);
  }
}
