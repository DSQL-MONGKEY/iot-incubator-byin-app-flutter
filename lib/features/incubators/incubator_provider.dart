import 'package:byin_app/features/incubators/incubator_model.dart';
import 'package:byin_app/mqtt/mqtt_service.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:flutter/material.dart';

class IncubatorProvider extends ChangeNotifier {
  final ApiClient api;
  final MqttService mqtt;

  IncubatorProvider(this.api, this.mqtt);

  List<Incubator> _items = [];
  Incubator? _selected;
  bool _loading = false;
  String? _error;

  List<Incubator> get items => _items;
  Incubator? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> bootstrap() async {
    if (_items.isNotEmpty) return;
    await refresh();

    if(_items.isNotEmpty && _selected == null) {
      select(_items.first);
    }
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await api.listIncubator();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void select(Incubator x) {
    _selected = x;

    // update code on mqtt path
    mqtt.changeIncubatorCode(x.code);
    notifyListeners();
  }
}