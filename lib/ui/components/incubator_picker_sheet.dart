import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:byin_app/features/incubators/incubator_model.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';

/// BottomSheet untuk memilih inkubator. Mengembalikan Incubator terpilih.
Future<Incubator?> showIncubatorPickerSheet(
  BuildContext context, {
  String? initialId,
}) async {
  final prov = context.read<IncubatorProvider>();
  await prov.refresh(); // pastikan data ada

  return showModalBottomSheet<Incubator>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      String query = '';
      String? selectedId = initialId;

      List<Incubator> filter(List<Incubator> all) {
        if (query.isEmpty) return all;
        final q = query.toLowerCase();
        return all.where((e) =>
          e.name.toLowerCase().contains(q) ||
          e.code.toLowerCase().contains(q)
        ).toList();
      }

      return StatefulBuilder(builder: (ctx, setState) {
        final items = filter(context.read<IncubatorProvider>().items);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // cari
              TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Cari inkubator…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 12),

              Flexible(
                child: items.isEmpty
                    ? const Center(child: Text('Tidak ada inkubator'))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final inc = items[i];
                          final selected = selectedId == inc.id;

                          return ListTile(
                            leading: _StatusDot(status: inc.status),
                            title: Text(inc.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text('Kode: ${inc.code} • ${inc.status}'),
                            trailing: selected
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF4D7CFE))
                                : const Icon(Icons.chevron_right),
                            onTap: () {
                              selectedId = inc.id;
                              Navigator.pop(ctx, inc);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      });
    },
  );
}

class _StatusDot extends StatelessWidget {
  final String? status; // ONLINE / OFFLINE / null
  const _StatusDot({this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch ((status ?? '').toUpperCase()) {
      case 'ONLINE':
        c = const Color(0xFF22C55E);
        break;
      case 'OFFLINE':
        c = const Color(0xFFEF4444);
        break;
      default:
        c = const Color(0xFFA3A3A3);
    }
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}
