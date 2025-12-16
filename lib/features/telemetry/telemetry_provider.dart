import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:byin_app/services/api_client.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'telemetry_model.dart';

class TelemetryProvider extends ChangeNotifier {
  final ApiClient api;
  final IncubatorProvider inc;
  final Duration pollInterval;

  TelemetryProvider(
    this.api,
    this.inc, {
    this.pollInterval = const Duration(seconds: 5),
  }) {
    inc.addListener(_onIncChanged);
  }

  Telemetry? _last;
  Telemetry? get last => _last;

  String? _mode; // ✅ sumber mode untuk UI
  String? get mode => _mode;

  final List<Telemetry> _history = <Telemetry>[];
  List<Telemetry> get history => List.unmodifiable(_history);

  static const int _buffer = 24;
  Timer? _timer;
  bool _inited = false;

  bool _fetching = false;
  int _reqSeq = 0;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    _restartPolling();
  }

  void _onIncChanged() {
    // dipanggil setiap selected incubator berubah
    _restartPolling(clear: true);
  }

  void _restartPolling({bool clear = false}) {
    _timer?.cancel();

    if (clear) {
      _history.clear();
      _last = null;
      _mode = null;
      notifyListeners();
    }

    if (inc.selected?.id == null) return;

    // fetch sekali biar UI langsung update
    refreshOnce();

    // polling tiap 5 detik
    _timer = Timer.periodic(pollInterval, (_) => refreshOnce());
  }

  Future<void> refreshOnce() async {
    final incubatorId = inc.selected?.id;
    if (incubatorId == null) return;
    if (_fetching) return;

    _fetching = true;
    final mySeq = ++_reqSeq;

    try {
      // ✅ 1) Ambil latest telemetry dari backend
      final telMap = await api.getLatestTelemetry(incubatorId);
      final tel = Telemetry.fromJson(telMap);

      // ✅ 2) Ambil state/mode terkini dari backend
      //    (lebih “source of truth” daripada menunggu telemetry berikutnya)
      final modeStr = await api.getIncubatorMode(incubatorId);

      // kalau request ini masih yang terbaru (incubator belum ganti di tengah jalan)
      if (mySeq == _reqSeq) {
        _last = tel;
        _mode = (modeStr ?? _tryGetModeFromTelemetry(tel))?.toUpperCase();

        _history.add(tel);
        if (_history.length > _buffer) _history.removeAt(0);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Telemetry] polling error: $e');
    } finally {
      _fetching = false;
    }
  }

  // fallback kalau endpoint mode belum ada/return null
  String? _tryGetModeFromTelemetry(Telemetry tel) {
    // kalau model Telemetry kamu punya field "mode", pakai ini:
    try {
      final dynamic any = tel;
      final m = (any.mode as String?);
      return m;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    inc.removeListener(_onIncChanged);
    super.dispose();
  }
}

/// ===== Extension API untuk polling =====
extension TelemetryLatestApi on ApiClient {
  Future<Map<String, dynamic>> getLatestTelemetry(String incubatorId) async {
    final res = await getJson('/incubators/$incubatorId/telemetry/latest');

    final raw = res['data'];
    final Map<String, dynamic> d = (raw is Map<String, dynamic>)
        ? raw
        : Map<String, dynamic>.from(raw as Map);

    final dynamic rawTs = d['ts'];
    final int tsSec = switch (rawTs) {
      num v => v.toInt(),
      String s => (DateTime.tryParse(s)?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000,
      _ => DateTime.now().millisecondsSinceEpoch ~/ 1000, // fallback kalau masih {}
    };

    // ✅ map flat -> format yang Telemetry.fromJson pahami (mirip payload MQTT kamu)
    return {
      'v': 1,
      'ts': tsSec, // setelah backend patch harus ISO string / Date string
      't': {
        'main': d['temp_main'],
        'ds': null,
        'dht': null,
      },
      'rh': d['room_humid'],
      'fan': d['fan'] ?? [0, 0, 0, 0, 0, 0],
      'lamp': d['lamp'] ?? [0, 0],
      'mode': d['mode'],
      'gps': {
        'fix': d['gpsFix'] ?? false,
        'sat': d['gpsSat'] ?? -1,
        'lat': d['gpsLat'],
        'lon': d['gpsLon'],
      },
      'fw': d['fwVersion'],
      'rev': d['rev'],
    };
  }

  Future<String?> getIncubatorMode(String incubatorId) async {
    final res = await getJson('/incubators/$incubatorId');
    final data = res['data'];
    if (data is Map) {
      final m = data['mode'];
      if (m is String) return m;
    }
    return null;
  }
}

