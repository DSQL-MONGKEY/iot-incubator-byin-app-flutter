import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:byin_app/ui/widgets/incubator_dropdown.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'package:byin_app/features/incubators/incubator_model.dart';
import 'package:byin_app/features/templates/template_provider.dart';

class TemplateCreatePage extends StatefulWidget {
  const TemplateCreatePage({super.key});

  @override
  State<TemplateCreatePage> createState() => _TemplateCreatePageState();
}

class _TemplateCreatePageState extends State<TemplateCreatePage> {
  final _form = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _descC = TextEditingController();

  // PILIHAN INKUBATOR (LOCAL STATE)
  Incubator? _pickedInc;

  // Toggle ON/OFF
  final List<bool> _fan = List<bool>.filled(6, false);
  final List<bool> _lamp = List<bool>.filled(2, false);

  bool _submitting = false;

  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    // Seed awal dari provider (jika ada pilihan global aktif)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickedInc = context.read<IncubatorProvider>().selected;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    // Gunakan pilihan lokal; fallback ke provider bila masih null
    final inc = _pickedInc ?? context.read<IncubatorProvider>().selected;
    if (inc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih inkubator terlebih dahulu')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _api.createTemplate(
        inc.id,
        name: _nameC.text.trim(),
        description: _descC.text.trim().isEmpty ? null : _descC.text.trim(),
        fan: _fan.map((b) => b ? 1 : 0).toList(growable: false),
        lamp: _lamp.map((b) => b ? 1 : 0).toList(growable: false),
        createdBy: 'dimas@contoh.com', // ganti ketika sudah ada auth
      );

      // refresh list template (jika halaman sebelumnya memakai TemplateProvider)
      await context.read<TemplateProvider>().load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template berhasil dibuat')),
      );
      Navigator.pop(context, true); // kembalikan true agar caller bisa refresh juga
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat template: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Template')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Reuse komponen dropdown yang sama, mode LOCAL:
              IncubatorDropdownCard(
                useGlobal: false,
                valueOverride: _pickedInc,
                onChanged: (inc) => setState(() => _pickedInc = inc),
                compact: true,
                heading: 'Inkubator',
              ),

              const SizedBox(height: 16),

              // Nama
              Text('Nama Template', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameC,
                decoration: _fieldDeco(hint: 'Mis. WARM-IN'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Deskripsi
              Text('Deskripsi', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descC,
                maxLines: 3,
                decoration: _fieldDeco(hint: 'Deskripsi template...'),
              ),
              const SizedBox(height: 20),

              // Kipas
              Text('Konfigurasi Kipas', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              for (int i = 0; i < 6; i++) ...[
                _SwitchRow(
                  icon: Icons.air_rounded,
                  label: 'Kipas ${i + 1}',
                  value: _fan[i],
                  onChanged: (v) => setState(() => _fan[i] = v),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),

              // Lampu
              Text('Konfigurasi Lampu', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              for (int i = 0; i < 2; i++) ...[
                _SwitchRow(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Lampu ${i + 1}',
                  value: _lamp[i],
                  onChanged: (v) => setState(() => _lamp[i] = v),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Simpan Template'),
                ),
              ),
              if (_submitting)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco({String? hint}) {
    return InputDecoration(
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
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EEF7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE9F0FF),
            child: Icon(icon, size: 18, color: const Color(0xFF4D7CFE)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
