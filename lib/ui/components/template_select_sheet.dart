import 'package:byin_app/features/templates/template_model.dart';
import 'package:byin_app/mqtt/mqtt_service.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:byin_app/ui/utils/ui_helpers.dart';
import 'package:flutter/material.dart';

Future<void> showTemplateSelectSheet({
  required BuildContext context,
  required String incubatorId,
  required String incubatorCode,
  required ApiClient api,
  required MqttService mqtt,
  required VoidCallback onApplied,
  required VoidCallback onDeleted,
  required VoidCallback onNavigateCreate,
}) async {
  List<IncTemplate> items = const [];

  Future<void> reload() async {
    items = await api.listTemplates(incubatorId);
  }

  await reload();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return DraggableScrollableSheet(
            expand: false,                // << KUNCI: jangan paksa full expand
            initialChildSize: 0.75,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (_, scrollController) {
              final media = MediaQuery.of(ctx);
              return Padding(
                // aman saat keyboard muncul
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Pilih Template',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // List / Empty
                    Expanded(
                      child: items.isEmpty
                          ? _EmptyState(onCreate: () {
                              Navigator.pop(ctx);
                              onNavigateCreate();
                            })
                          : ListView.separated(
                              controller: scrollController,          // << penting
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final t = items[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: (t.description == null || t.description!.isEmpty)
                                      ? null
                                      : Text(t.description!),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min, // << jangan melar
                                    children: [
                                      TextButton(
                                        child: const Text('Terapkan'),
                                        onPressed: () async {
                                          final ok = await confirmDialog(
                                            context,
                                            title: 'Terapkan ${t.name}',
                                            message:
                                                'Mode akan disetel MANUAL dan pola Fan/Lampu dikirim ke inkubator.',
                                          );
                                          if (!ok) return;

                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => const Center(child: CircularProgressIndicator()),
                                          );

                                          try {
                                            await api.applyTemplate(
                                              incubatorId,
                                              t.id,
                                              syncMode: 'SET_MANUAL',
                                              requestedBy: 'byin-app',
                                            );

                                            await mqtt.ensureSubscribeAck(incubatorCode);
                                            final gotAck = await mqtt
                                                .waitAck(type: 'apply-template', timeout: const Duration(seconds: 5))
                                                .catchError((_) => false);

                                            if (context.mounted) {
                                              showToast(
                                                context,
                                                gotAck
                                                    ? 'Template diterapkan'
                                                    : 'Template diterapkan (tanpa ACK)',
                                              );
                                            }
                                            onApplied();
                                          } catch (e) {
                                            if (context.mounted) {
                                              showToast(context, 'Gagal apply: $e', error: true);
                                            }
                                          } finally {
                                            if (context.mounted) Navigator.pop(context); // tutup loading
                                            if (Navigator.canPop(ctx)) Navigator.pop(ctx); // tutup sheet
                                          }
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Hapus',
                                        icon: const Icon(Icons.delete_outline_rounded),
                                        onPressed: () async {
                                          final ok = await confirmDialog(
                                            context,
                                            title: 'Hapus Template?',
                                            message: 'Tindakan ini tidak bisa dibatalkan.',
                                          );
                                          if (!ok) return;

                                          try {
                                            await api.deleteTemplate(incubatorId, t.id);
                                            await reload();
                                            setState(() {}); // refresh isi sheet
                                            if (context.mounted) showToast(context, 'Template dihapus');
                                            onDeleted();
                                          } catch (e) {
                                            if (context.mounted) showToast(context, 'Gagal hapus: $e', error: true);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Belum ada template.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'Buat template agar pola kipas & lampu bisa diterapkan cepat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Buat Template'),
            ),
          ],
        ),
      ),
    );
  }
}
