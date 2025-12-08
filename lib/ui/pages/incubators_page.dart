// lib/ui/incubators_page.dart
import 'package:byin_app/ui/components/incubator_add_sheet.dart';
import 'package:byin_app/ui/components/incubator_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';

class IncubatorsPage extends StatefulWidget {
  const IncubatorsPage({super.key});

  @override
  State<IncubatorsPage> createState() => _IncubatorsPageState();
}

class _IncubatorsPageState extends State<IncubatorsPage> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      Future.microtask(() => context.read<IncubatorProvider>().bootstrap());
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<IncubatorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inkubator', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: () => showAddIncubatorSheet(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Tambah Inkubator',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: st.refresh,
          edgeOffset: 0,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Text('Kelola daftar inkubator bayi',
                  style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 12),

              if (st.loading) ...[
                _skeleton(), const SizedBox(height: 12), _skeleton(),
              ] else if (st.error != null) ...[
                _error(st.error!, onRetry: st.refresh),
              ] else if (st.items.isEmpty) ...[
                _empty(onAdd: () => showAddIncubatorSheet(context)),
              ] else ...[
                for (final it in st.items) ...[
                  IncubatorCard(data: it),
                  const SizedBox(height: 12),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeleton() => Container(
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9EEF7)),
        ),
      );

  Widget _error(String msg, {required VoidCallback onRetry}) => Column(
        children: [
          const SizedBox(height: 36),
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

  Widget _empty({required VoidCallback onAdd}) => Column(
        children: [
          const SizedBox(height: 36),
          const Icon(Icons.child_care_outlined, size: 36, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 8),
          const Text('Belum ada inkubator'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Inkubator'),
          ),
        ],
      );
}
