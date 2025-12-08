import 'package:byin_app/features/incubators/incubator_model.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IncubatorDropdownCard extends StatelessWidget {
  /// Default true = perilaku seperti di Dashboard (ubah selection global).
  /// Set false untuk dipakai sebagai field form (local selection via [onChanged]).
  final bool useGlobal;

  /// Nilai pilihan saat ini ketika [useGlobal] = false.
  final Incubator? valueOverride;

  /// Dipanggil ketika user memilih inkubator saat [useGlobal] = false.
  final ValueChanged<Incubator>? onChanged;

  /// Tampilan lebih ringkas untuk di form.
  final bool compact;

  /// Ubah teks heading (mis. "Inkubator" saat dipakai di form).
  final String? heading;

  const IncubatorDropdownCard({
    super.key,
    this.useGlobal = true,
    this.valueOverride,
    this.onChanged,
    this.compact = false,
    this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<IncubatorProvider>(
      builder: (context, st, _) {
        // trigger load pertama kali
        if (!st.loading && st.items.isEmpty && st.error == null) {
          st.bootstrap();
        }

        final Incubator? sel = useGlobal ? st.selected : (valueOverride ?? st.selected);

        return InkWell(
          onTap: () => _openPicker(context, st),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9EEF7)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10, offset: Offset(0, 4),
                  color: Color(0x0F000000),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 12, compact ? 8 : 12),
            child: Row(
              children: [
                // left: title & status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heading ?? (useGlobal ? 'Inkubator Aktif' : 'Inkubator'),
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (st.loading)
                        const Text('Memuat...',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600))
                      else if (st.error != null)
                        Text('Gagal memuat',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600))
                      else
                        Text(
                          sel?.name ?? 'Pilih inkubator',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatusDot(
                            color: (sel?.isOnline ?? false)
                                ? const Color(0xFF2CC84D)
                                : const Color(0xFF95A0B6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (sel?.isOnline ?? false) ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              fontSize: 12,
                              color: (sel?.isOnline ?? false)
                                  ? const Color(0xFF2CC84D)
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF475569)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPicker(BuildContext context, IncubatorProvider st) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return _PickerSheet(
          items: st.items,
          selected: useGlobal ? st.selected : valueOverride,
          // saat pilih:
          onSelect: (x) {
            if (useGlobal) {
              st.select(x);                 // ubah global
            } else {
              onChanged?.call(x);           // local callback
            }
          },
          onRefresh: () => st.refresh(),
          loading: st.loading,
          error: st.error,
        );
      },
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final List<Incubator> items;
  final Incubator? selected;
  final void Function(Incubator) onSelect;
  final Future<void> Function() onRefresh;
  final bool loading;
  final String? error;

  const _PickerSheet({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.onRefresh,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Text('Pilih Inkubator',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: loading ? null : () => onRefresh(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              )
            else if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(error!,
                    style: const TextStyle(color: Colors.red)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final x = items[i];
                    final isSel = x.id == selected?.id;
                    return ListTile(
                      onTap: () {
                        onSelect(x);
                        Navigator.pop(context);
                      },
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      leading: _StatusDot(
                        color: x.isOnline
                            ? const Color(0xFF2CC84D)
                            : const Color(0xFF95A0B6),
                      ),
                      title: Text(x.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('#${x.code} • ${x.status}',
                          style: TextStyle(color: Colors.grey.shade600)),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF4D7CFE))
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
