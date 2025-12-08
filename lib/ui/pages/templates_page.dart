import 'package:byin_app/ui/components/template_card.dart';
import 'package:byin_app/ui/pages/template_create_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'package:byin_app/features/templates/template_provider.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      // muat saat pertama tampil
      Future.microtask(() => context.read<TemplateProvider>().load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncubatorProvider>().selected;
    final prov = context.watch<TemplateProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: prov.refresh,
          edgeOffset: 8,
          displacement: 32,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Template', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                        SizedBox(height: 6),
                        Text('Kelola template konfigurasi inkubator', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Tambah Template',
                    color: Colors.white,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                        const Color(0xFF4D7CFE)
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () async {
                      // pastikan daftar inkubator sudah ada
                      await context.read<IncubatorProvider>().refresh();
                      final created = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TemplateCreatePage()),
                      );
                      if (created == true && context.mounted) {
                        await context.read<TemplateProvider>().refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Template ditambahkan')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // STATE: loading / error / empty / list
              if (prov.loading) ...[
                _skeleton(),
                const SizedBox(height: 12),
                _skeleton(),
              ] else if (prov.error != null) ...[
                _errorView(prov.error!, onRetry: prov.load),
              ] else if (prov.items.isEmpty) ...[
                _emptyView(onAdd: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create template — coming soon')),
                )),
              ] else ...[
                for (final t in prov.items) ...[
                  TemplateCard(
                    data: t,
                    incubatorName: inc?.name,
                    onTap: () {}, // nanti: detail/edit
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeleton() => Container(
    height: 120,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE9EEF7)),
    ),
  );

  Widget _errorView(String msg, {required VoidCallback onRetry}) => Column(
    children: [
      const SizedBox(height: 40),
      const Icon(Icons.error_outline, color: Colors.redAccent),
      const SizedBox(height: 8),
      Text(msg, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Coba lagi'),
      ),
    ],
  );

  Widget _emptyView({required VoidCallback onAdd}) => Column(
    children: [
      const SizedBox(height: 40),
      const Icon(Icons.playlist_add_outlined, size: 36, color: Color(0xFF9CA3AF)),
      const SizedBox(height: 8),
      const Text('Belum ada template'),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Buat Template'),
      ),
    ],
  );
}
