import 'dart:async';
import 'package:flutter/foundation.dart';

import '../incubators/incubator_provider.dart';
import '../telemetry/telemetry_provider.dart';
import '../../services/api_client.dart';

class ControlProvider extends ChangeNotifier {
  final ApiClient api;
  final IncubatorProvider inc;
  TelemetryProvider _tel;

  ControlProvider(this.api, this.inc, this._tel) {
    inc.addListener(_onIncChanged);
    _tel.addListener(_syncFromTelemetry);
    _syncFromTelemetry();
  }

  // Kalau pakai ProxyProvider, telemetry bisa berubah instance-nya
  void updateTelemetry(TelemetryProvider next) {
    if (identical(_tel, next)) return;
    _tel.removeListener(_syncFromTelemetry);
    _tel = next;
    _tel.addListener(_syncFromTelemetry);
    _syncFromTelemetry();
  }

  // -------- state draft untuk UI --------
  List<int> _fanDraft = List.filled(6, 0);
  List<int> _lampDraft = const [0, 0];

  List<int> get fan => List.unmodifiable(_fanDraft);
  List<int> get lamp => List.unmodifiable(_lampDraft);

  String get mode => ((_tel.last?.mode ?? inc.selected?.mode ?? 'AUTO')).toUpperCase();
  bool get isAuto => mode == 'AUTO';
  bool get isManual => mode == 'MANUAL';

  bool _savingFan = false;
  bool _savingLamp = false;
  bool get savingFan => _savingFan;
  bool get savingLamp => _savingLamp;

  String? _error;
  String? get error => _error;

  Timer? _fanDebounce;
  Timer? _lampDebounce;

  bool _dirtyFan = false;
  bool _dirtyLamp = false;

  void _onIncChanged() {
    // incubator diganti: reset draft dari telemetry terbaru
    _dirtyFan = false;
    _dirtyLamp = false;
    _error = null;
    _fanDebounce?.cancel();
    _lampDebounce?.cancel();
    _syncFromTelemetry(force: true);
  }

  void _syncFromTelemetry({bool force = false}) {
    final last = _tel.last;
    if (last == null) return;

    final nextFan = (last.fan ?? List.filled(6, 0)).map((e) => e == 1 ? 1 : 0).toList();
    final nextLamp = (last.lamp ?? const [0, 0]).map((e) => e == 1 ? 1 : 0).toList();

    // Kalau user sedang edit (dirty) jangan overwrite draft
    if (force || (!_dirtyFan && !_savingFan)) {
      if (!listEquals(_fanDraft, nextFan)) _fanDraft = nextFan;
    }
    if (force || (!_dirtyLamp && !_savingLamp)) {
      if (!listEquals(_lampDraft, nextLamp)) _lampDraft = nextLamp;
    }

    notifyListeners();
  }

  // -------- Mode --------
  Future<void> setModeManual() async {
    final id = inc.selected?.id;
    if (id == null) return;

    _error = null;
    notifyListeners();

    try {
      await api.setIncubatorMode(id, 'MANUAL');
      await _tel.refreshOnce(); // biar mode di UI cepat update
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // -------- FAN --------
  void toggleFan(int index) {
    if (!isManual) return;
    if (index < 0 || index >= _fanDraft.length) return;

    final next = [..._fanDraft];
    next[index] = next[index] == 1 ? 0 : 1;

    _fanDraft = next;
    _dirtyFan = true;
    _error = null;
    notifyListeners();

    _fanDebounce?.cancel();
    _fanDebounce = Timer(const Duration(milliseconds: 300), _commitFan);
  }

  Future<void> _commitFan() async {
    if (_savingFan) return;
    final id = inc.selected?.id;
    if (id == null) return;

    if (!isManual) {
      _dirtyFan = false;
      _syncFromTelemetry(force: true);
      return;
    }

    _savingFan = true;
    notifyListeners();

    try {
      await api.setFanManual(id, _fanDraft);
      _dirtyFan = false;
      await _tel.refreshOnce();
    } catch (e) {
      _error = e.toString();
      _dirtyFan = false;
      _syncFromTelemetry(force: true); // rollback ke state server
    } finally {
      _savingFan = false;
      notifyListeners();
    }
  }

  // -------- LAMP (group) --------
  void toggleLampGroup() {
    if (!isManual) return;

    final currentOn = (_lampDraft.isNotEmpty && _lampDraft[0] == 1);
    final v = currentOn ? 0 : 1;

    _lampDraft = [v, v];
    _dirtyLamp = true;
    _error = null;
    notifyListeners();

    _lampDebounce?.cancel();
    _lampDebounce = Timer(const Duration(milliseconds: 300), _commitLamp);
  }

  Future<void> _commitLamp() async {
    if (_savingLamp) return;
    final id = inc.selected?.id;
    if (id == null) return;

    if (!isManual) {
      _dirtyLamp = false;
      _syncFromTelemetry(force: true);
      return;
    }

    _savingLamp = true;
    notifyListeners();

    try {
      await api.setLampManual(id, _lampDraft);
      _dirtyLamp = false;
      await _tel.refreshOnce();
    } catch (e) {
      _error = e.toString();
      _dirtyLamp = false;
      _syncFromTelemetry(force: true);
    } finally {
      _savingLamp = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _fanDebounce?.cancel();
    _lampDebounce?.cancel();
    inc.removeListener(_onIncChanged);
    _tel.removeListener(_syncFromTelemetry);
    super.dispose();
  }
}