// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:byin_app/mqtt/mqtt_service.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:byin_app/main.dart';
import 'package:mqtt_client/mqtt_client.dart';

// Fake MQTT untuk test: tidak melakukan koneksi sungguhan
class _FakeMqttService extends MqttService {
  _FakeMqttService() : super(broker: 'test-broker', username: 'u', password: 'p');

  @override
  Future<void> connect() async {} // no-op

  Future<void> subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) async {}

  Future<void> publish(String topic, Object payload,
      {MqttQos qos = MqttQos.atLeastOnce, bool retain = false}) async {}
}

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    final fake = _FakeMqttService();

    await tester.pumpWidget(MyApp(mqtt: fake, api: ApiClient(baseUrl: 'http://10.0.2.2:3000/api/v1')));
    await tester.pump(); // biar build selesai

    // Sesuaikan dengan widget yang pasti ada di home (mis. DashboardPage)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
