import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String broker;
  final int port; // default 8883 (TLS native)
  final String username;
  final String password;

  // BUKAN final -> agar bisa re-init saat fallback
  late MqttServerClient _client;
  final _rawStream = StreamController<_MqttMsg>.broadcast();

  String incubatorCode = '001'; // diubah dari UI / storage
  String? _currentTelemetryTopic;

  MqttService({
    required this.broker,
    this.port = 8883,
    required this.username,
    required this.password,
  });

  String topicTelemetry() => '/psk/incubator/$incubatorCode/telemetry';
  String topicMode()      => '/psk/incubator/$incubatorCode/control-mode';
  String topicFan()       => '/psk/incubator/$incubatorCode/fan';
  String topicLamp()      => '/psk/incubator/$incubatorCode/lamp';

  // ignore: library_private_types_in_public_api
  Stream<_MqttMsg> get messages => _rawStream.stream;

  // ---------- CONNECT WITH TLS -> FALLBACK WSS ----------
  Future<void> connect() async {
    final cid = 'byin-app-${DateTime.now().millisecondsSinceEpoch}';

    Future<void> _wireListener(MqttServerClient c) async {
      c.updates?.listen((events) {
        if (events.isEmpty) return;
        final rec = events.first;
        final topic = rec.topic;
        final msg = rec.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
        _rawStream.add(_MqttMsg(topic, payload));
      });
    }

    void _applyBaseConfig(MqttServerClient c) {
      c.keepAlivePeriod = 30;
      c.autoReconnect = true;
      c.setProtocolV311();
      c.logging(on: kDebugMode);
      c.onConnected = () => debugPrint('[MQTT] connected');
      c.onDisconnected = () => debugPrint('[MQTT] disconnected');
      c.onAutoReconnect = () => debugPrint('[MQTT] reconnecting…');
      c.onAutoReconnected = () => debugPrint('[MQTT] reconnected');
      c.connectionTimeoutPeriod = 10000; // 10s
    }

    MqttConnectMessage _connMsg() => MqttConnectMessage()
        .startClean()
        .withClientIdentifier(cid)
        .withWillQos(MqttQos.atLeastOnce);

    // 1) Coba TLS native :8883
    try {
      _client = MqttServerClient.withPort(broker, cid, 8883)
        ..secure = true;
      _applyBaseConfig(_client);
      _client.connectionMessage = _connMsg();

      debugPrint('[MQTT] try TLS :8883 …');
      await _client.connect(username, password);

      // sukses
      _currentTelemetryTopic = topicTelemetry();
      _client.subscribe(_currentTelemetryTopic!, MqttQos.atLeastOnce);
      await _wireListener(_client);
      debugPrint('[MQTT] OK TLS :8883, sub=$_currentTelemetryTopic');
      return;
    } on Exception catch (e) {
      debugPrint('[MQTT] TLS :8883 failed: $e');
      try { _client.disconnect(); } catch (_) {}
    }

    // 2) Fallback ke WSS :8884 /mqtt (recommended di emulator)
    try {
      _client = MqttServerClient.withPort(broker, cid, 8884)
        ..secure = true
        ..useWebSocket = true
        ..websocketPath = '/mqtt'
        // ignore: invalid_use_of_protected_member
        ..websocketProtocol = 'mqtt' as List<String>?;
      _applyBaseConfig(_client);
      _client.connectionMessage = _connMsg();

      debugPrint('[MQTT] try WSS :8884 /mqtt …');
      await _client.connect(username, password);

      // sukses
      _currentTelemetryTopic = topicTelemetry();
      _client.subscribe(_currentTelemetryTopic!, MqttQos.atLeastOnce);
      await _wireListener(_client);
      debugPrint('[MQTT] OK WSS :8884, sub=$_currentTelemetryTopic');
      return;
    } on Exception catch (e) {
      try { _client.disconnect(); } catch (_) {}
      debugPrint('[MQTT] WSS :8884 failed: $e');
      rethrow; // dua-duanya gagal -> lempar ke atas supaya ketahuan
    }
  }

  // ---------- PUBLISH HELPERS ----------
  Future<void> publishJson(
    String topic,
    Map<String, dynamic> json, {
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) async {
    final payload = jsonEncode(json);
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(topic, qos, builder.payload!, retain: retain);
    debugPrint('[MQTT] -> $topic $payload');
  }

  Future<void> setMode(String mode) =>
      publishJson(topicMode(), {'mode': mode});

  Future<void> setFan(List<int> fan, {bool ensureManual = true}) async {
    if (ensureManual) {
      await setMode('MANUAL');
      await Future.delayed(const Duration(milliseconds: 150));
    }
    await publishJson(topicFan(), {'fan': fan, 'mode': 'MANUAL'});
  }

  Future<void> setLamp(List<int> lamp) =>
      publishJson(topicLamp(), {'lamp': lamp});

  // ---------- LIFECYCLE ----------
  void dispose() {
    _rawStream.close();
    try { _client.disconnect(); } catch (_) {}
  }

  // ---------- GANTI INCUBATOR CODE + RESUB ----------
  Future<void> changeIncubatorCode(String newCode) async {
    if (incubatorCode == newCode) return;

    final oldTopic = _currentTelemetryTopic ?? topicTelemetry();
    incubatorCode = newCode;

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        _client.unsubscribe(oldTopic);
      } catch (_) {}
      _currentTelemetryTopic = topicTelemetry();
      _client.subscribe(_currentTelemetryTopic!, MqttQos.atLeastOnce);
      debugPrint('[MQTT] resub -> $_currentTelemetryTopic');
    }
  }

  String? _currentAckTopic;

  Future<void> ensureSubscribeAck(String code) async {
    final tp = '/psk/incubator/$code/ack';

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      if (_currentAckTopic != tp) {
        if (_currentAckTopic != null) {
          try {
            _client.unsubscribe(_currentAckTopic!);
          } catch (_) {

          }
        }

        _client.subscribe(tp, MqttQos.atLeastOnce);
        _currentAckTopic = tp;
      }
    }
  }

  Future<bool> waitAck({ required String type, Duration timeout = const Duration(seconds: 5) }) async {
    try {
      final ok = await messages
        .where((m) => m.topic == _currentAckTopic)
        .map((m) {
          try {
            final j = jsonDecode(m.payload) as Map<String, dynamic>;

            return (j['type'] == type);
          } catch (_) {
            return false;
          }
        })
        .firstWhere((x) => x == true)
        .timeout(timeout);
    
      return ok;
    } catch (_) { return false; }
  }
}

extension on MqttServerClient {
  set websocketProtocol(List<String>? websocketProtocol) {}

  set connectionTimeoutPeriod(int connectionTimeoutPeriod) {}

  set websocketPath(String websocketPath) {}
}

class _MqttMsg {
  final String topic;
  final String payload;
  _MqttMsg(this.topic, this.payload);
}
