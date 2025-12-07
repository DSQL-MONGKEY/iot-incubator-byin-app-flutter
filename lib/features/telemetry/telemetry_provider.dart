import 'dart:async';
import 'dart:convert';
import 'package:byin_app/mqtt/mqtt_service.dart';
import 'package:flutter/foundation.dart';

import 'telemetry_model.dart';

class TelemetryProvider extends ChangeNotifier {
  final MqttService mqtt;
  TelemetryProvider(this.mqtt);

  Telemetry? _last;
  Telemetry? get last => _last;

  final List<Telemetry> _history = <Telemetry>[];
  List<Telemetry> get history => List.unmodifiable(_history);

  static const int _buffer = 24; // mis. 24 titik terakhir untuk chart
  StreamSubscription? _sub;
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    // pastikan konek + subscribe
    await mqtt.connect();

    // dengarkan semua pesan lalu filter topic telemetry aktif
    _sub = mqtt.messages.listen((m) {
      if (m.topic != mqtt.topicTelemetry()) return;
      try {
        final map = jsonDecode(m.payload) as Map<String, dynamic>;
        final tel = Telemetry.fromJson(map);

        _last = tel;
        _history.add(tel);
        if (_history.length > _buffer) _history.removeAt(0);

        notifyListeners();
      } catch (e) {
        debugPrint('[Telemetry] parse error: $e');
      }
    });
  }

  /// Panggil ini setelah user mengganti incubator (code MQTT berubah).
  /// Akan kosongkan buffer dan (re)subscribe via service.
  Future<void> onIncubatorChanged(String newCode) async {
    await mqtt.changeIncubatorCode(newCode); // lihat patch di MqttService
    _history.clear();
    _last = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
