import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'package:byin_app/features/telemetry/telemetry_series_model.dart';
import 'package:flutter/material.dart';

class TelemetrySeriesProvider with ChangeNotifier {
  final ApiClient api;
  final IncubatorProvider inc;

  TelemetrySeriesProvider(this.api, this.inc) {
    // listen incubator change & fetch awal
    inc.addListener(_onIncChanged);
    scheduleMicrotask(fetch);
  }

  @override
  void dispose() {
    inc.removeListener(_onIncChanged);
    super.dispose();
  }

  // state
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool loading = false;
  List<TelemetrySeriesPoint> data = [];
  String? error;

  DateTime get month => _month;
  String? get incubatorId => inc.selected?.id;

  DateTime get _from => DateTime(_month.year, _month.month, 1);
  DateTime get _to =>
      DateTime(_month.year, _month.month + 1, 0, 23, 59, 59, 999);

  void _onIncChanged() => fetch();

  Future<void> fetch() async {
    final id = incubatorId;
    if (id == null) {
      data = [];
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    try {
      // 5 menit agar jumlah titik ramah untuk 1 bulan
      data = await api.getTelemetrySeries(id, from: _from, to: _to, bucketSec: 300);
    } catch (e) {
      error = e.toString();
      data = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void prevMonth() {
    _month = DateTime(_month.year, _month.month - 1, 1);
    fetch();
  }

  void nextMonth() {
    _month = DateTime(_month.year, _month.month + 1, 1);
    fetch();
  }

  Future<void> pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih bulan',
    );
    if (picked != null) {
      _month = DateTime(picked.year, picked.month, 1);
      fetch();
    }
  }
}
