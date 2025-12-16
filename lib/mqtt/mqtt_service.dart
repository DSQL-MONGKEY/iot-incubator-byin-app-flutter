import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String broker;
  final String username;
  final String password;

  late MqttServerClient _client;
  final _rawStream = StreamController<_MqttMsg>.broadcast();

  String incubatorCode = '001';
  String? _tpTelemetry;
  String? _tpAck;

  MqttService({
    required this.broker,
    required this.username,
    required this.password,
  });

  // ---- Topics
  String _telemetryTopic(String code) => '/psk/incubator/$code/telemetry';
  String _ackTopic(String code)       => '/psk/incubator/$code/ack';
  String topicTelemetry()             => _telemetryTopic(incubatorCode);
  String topicMode()                  => '/psk/incubator/$incubatorCode/control-mode';
  String topicFan()                   => '/psk/incubator/$incubatorCode/fan';
  String topicLamp()                  => '/psk/incubator/$incubatorCode/lamp';

  Stream<_MqttMsg> get messages => _rawStream.stream;

  Future<void> connect() async {
    final cid = 'byin-app-${DateTime.now().millisecondsSinceEpoch}';

    void wireBase(MqttServerClient c) {
      c.keepAlivePeriod = 30;
      c.autoReconnect = true;
      c.setProtocolV311();
      c.logging(on: kDebugMode);

      c.onConnected = () {
        debugPrint('[MQTT] connected');
        _resubscribeAll();
      };
      c.onDisconnected = () => debugPrint('[MQTT] disconnected');
      c.onAutoReconnect = () => debugPrint('[MQTT] reconnecting…');
      c.onAutoReconnected = () {
        debugPrint('[MQTT] reconnected');
        _resubscribeAll();
      };

      // DEV ONLY (hapus untuk produksi): terima semua sertifikat
      // Signature di lib ini: (Object?) => bool
      c.onBadCertificate = (Object? _) {
        debugPrint('[MQTT] onBadCertificate (DEV) -> accept');
        return true;
      };

      c.onSubscribed = (t) => debugPrint('[MQTT] subscribed: $t');
      c.onUnsubscribed = (t) => debugPrint('[MQTT] unsubscribed: $t');
      c.pongCallback = () => debugPrint('[MQTT] PINGRESP');
    }

    void wireListener(MqttServerClient c) {
      c.updates?.listen((events) {
        if (events.isEmpty) return;
        final rec = events.first;
        final topic = rec.topic;
        final msg = rec.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
        if (kDebugMode) debugPrint('[MQTT] <= $topic ${payload.length}B');
        _rawStream.add(_MqttMsg(topic, payload));
      });
    }

    final connMsg = MqttConnectMessage()
        .startClean()
        .withClientIdentifier(cid)
        .withWillQos(MqttQos.atLeastOnce);

    // 1) Coba TLS native :8883
    try {
      _client = MqttServerClient.withPort(broker, cid, 8883)
        ..secure = true;
      wireBase(_client);
      _client.connectionMessage = connMsg;

      debugPrint('[MQTT] try TLS :8883 …');
      await _client.connect(username, password);

      wireListener(_client);
      _resubscribeAll();
      debugPrint('[MQTT] OK TLS :8883');
      return;
    } on Exception catch (e) {
      final rc = _client.connectionStatus?.returnCode;
      debugPrint('[MQTT] TLS :8883 failed: $e (rc=${rc?.name})');
      try { _client.disconnect(); } catch (_) {}
    }

    // 2) Fallback WSS :8884 (path default lib = /mqtt -> cocok untuk HiveMQ Cloud)
    try {
      _client = MqttServerClient.withPort(broker, cid, 8884)
        ..secure = true
        ..useWebSocket = true
        ..websocketProtocols = MqttClientConstants.protocolsSingleDefault; // ['mqtt']
      wireBase(_client);
      _client.connectionMessage = connMsg;

      debugPrint('[MQTT] try WSS :8884 …');
      await _client.connect(username, password);

      wireListener(_client);
      _resubscribeAll();
      debugPrint('[MQTT] OK WSS :8884');
      return;
    } on Exception catch (e) {
      final rc = _client.connectionStatus?.returnCode;
      debugPrint('[MQTT] WSS :8884 failed: $e (rc=${rc?.name})');
      try { _client.disconnect(); } catch (_) {}
      rethrow; // biar kelihatan errornya di UI/log
    }
  }

  void _resubscribeAll() {
    // telemetry
    final tpTel = _telemetryTopic(incubatorCode);
    if (_tpTelemetry != tpTel) {
      if (_tpTelemetry != null) {
        try { _client.unsubscribe(_tpTelemetry!); } catch (_) {}
      }
      _client.subscribe(tpTel, MqttQos.atLeastOnce);
      _tpTelemetry = tpTel;
      debugPrint('[MQTT] sub telemetry -> $_tpTelemetry');
    }
    // ack
    if (_tpAck != null) {
      _client.subscribe(_tpAck!, MqttQos.atLeastOnce);
      debugPrint('[MQTT] (re)sub ack -> $_tpAck');
    }
  }

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

  Future<void> setMode(String mode) => publishJson(topicMode(), {'mode': mode});

  Future<void> setFan(List<int> fan, {bool ensureManual = true}) async {
    if (ensureManual) {
      await setMode('MANUAL');
      await Future.delayed(const Duration(milliseconds: 150));
    }
    await publishJson(topicFan(), {'fan': fan, 'mode': 'MANUAL'});
  }

  Future<void> setLamp(List<int> lamp) => publishJson(topicLamp(), {'lamp': lamp});

  void dispose() {
    _rawStream.close();
    try { _client.disconnect(); } catch (_) {}
  }

  Future<void> changeIncubatorCode(String newCode) async {
    if (incubatorCode == newCode) return;
    incubatorCode = newCode;
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _resubscribeAll();
    }
  }

  Future<void> ensureSubscribeAck(String code) async {
    final tp = _ackTopic(code);
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      if (_tpAck != tp) {
        if (_tpAck != null) {
          try { _client.unsubscribe(_tpAck!); } catch (_) {}
        }
        _client.subscribe(tp, MqttQos.atLeastOnce);
        _tpAck = tp;
        debugPrint('[MQTT] sub ACK -> $_tpAck');
      }
    }
  }

  Future<bool> waitAck({required String type, Duration timeout = const Duration(seconds: 10)}) async {
    if (_tpAck == null) return false;
    try {
      final ok = await messages
          .where((m) => m.topic == _tpAck)
          .map((m) {
            try {
              final j = jsonDecode(m.payload) as Map<String, dynamic>;
              return j['type'] == type;
            } catch (_) { return false; }
          })
          .firstWhere((x) => x == true)
          .timeout(timeout);
      return ok;
    } catch (_) {
      return false;
    }
  }
}

class _MqttMsg {
  final String topic;
  final String payload;
  _MqttMsg(this.topic, this.payload);
}
