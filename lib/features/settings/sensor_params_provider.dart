// lib/features/settings/sensor_params_provider.dart
import 'package:flutter/foundation.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:byin_app/mqtt/mqtt_service.dart';
import 'sensor_params_model.dart';

class SensorParamsProvider extends ChangeNotifier {
  final ApiClient api;
  final MqttService mqtt;

  SensorParamsProvider(this.api, this.mqtt);

  bool loading = false;
  String? error;
  SensorParams? params;

  String? _currentIncId;

  Future<void> load(String incubatorId) async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();

    _currentIncId = incubatorId;

    try {
      final res = await api.getSensorParams(incubatorId); // may be null if belum ada
      params = res ??
          SensorParams(
            id: '_new',
            incubatorId: incubatorId,
            tempOnC: 36.7,
            tempOffC: 36.3,
            rhOnPercent: 60.0,
            rhOffPercent: 50.0,
            emaAlpha: 0.2,
            minOnMs: 5000,
            minOffMs: 5000,
            antiChatter: true,
          );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Mutators (dipakai UI)
  void setTempOn(double v) { params?.tempOnC = v; notifyListeners(); }
  void setTempOff(double v) { params?.tempOffC = v; notifyListeners(); }
  void setRhOn(double v) { params?.rhOnPercent = v; notifyListeners(); }
  void setRhOff(double v) { params?.rhOffPercent = v; notifyListeners(); }
  void setMinOn(int? v) { params?.minOnMs = v; notifyListeners(); }
  void setMinOff(int? v) { params?.minOffMs = v; notifyListeners(); }
  void setAntiChatter(bool v) { params?.antiChatter = v; notifyListeners(); }
  void setAlpha(double v) { params?.emaAlpha = v; notifyListeners(); }

  Future<bool> save({required String incubatorId, required String incubatorCode}) async {
    if (params == null) return false;

    // Validasi sederhana
    if (params!.tempOffC > params!.tempOnC) {
      throw Exception('Suhu Minimum tidak boleh lebih besar dari Suhu Maksimum.');
    }
    if (params!.rhOffPercent > params!.rhOnPercent) {
      throw Exception('Kelembapan Minimum tidak boleh lebih besar dari Kelembapan Maksimum.');
    }

    loading = true; error = null; notifyListeners();

    try {
      await api.upsertSensorParams(incubatorId, params!.toPayload());

      // tunggu ACK dari device
      await mqtt.ensureSubscribeAck(incubatorCode);
      final got = await mqtt.waitAck(type: 'sensor-param', timeout: const Duration(seconds: 7));

      loading = false; notifyListeners();
      return got; // true => ACK ok, false => timeout/tidak ada ACK
    } catch (e) {
      loading = false; error = e.toString(); notifyListeners();
      rethrow;
    }
  }
}
