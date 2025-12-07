import 'package:flutter/foundation.dart';
import '../../mqtt/mqtt_service.dart';
import '../telemetry/telemetry_provider.dart';

class ControlProvider extends ChangeNotifier {
  final MqttService mqtt;
  final TelemetryProvider telemetry;

  ControlProvider(this.mqtt, this.telemetry);

  List<int> get fan => telemetry.last?.fan ?? List.filled(6, 0);
  List<int> get lamp => telemetry.last?.lamp ?? [1,1];

  Future<void> setModeAuto() => mqtt.setMode('AUTO');
  Future<void> setModeManual() => mqtt.setMode('MANUAL');

  Future<void> toggleFan(int i) async {
    final a = [...fan];
    a[i] = a[i] == 0 ? 1 : 0;
    await mqtt.setFan(a, ensureManual: true);
  }

  Future<void> toggleLampGroup() async {
    final v = lamp[0]==0 ? 1 : 0;
    await mqtt.setLamp([v,v]);
  }
}
