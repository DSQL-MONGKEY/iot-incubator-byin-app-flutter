import 'package:flutter/foundation.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:byin_app/features/templates/template_model.dart';
import 'package:byin_app/features/incubators/incubator_provider.dart';

class TemplateProvider extends ChangeNotifier {
  final ApiClient api;
  final IncubatorProvider incProv;

  TemplateProvider(this.api, this.incProv) {
    // reload otomatis saat incubator terpilih berubah
    incProv.addListener(_onIncChanged);
  }

  List<IncTemplate> _items = [];
  List<IncTemplate> get items => _items;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    final inc = incProv.selected;
    if (inc == null) {
      _items = [];
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await api.listTemplates(inc.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void _onIncChanged() {
    // Ganti inkubator → muat ulang
    load();
  }

  @override
  void dispose() {
    incProv.removeListener(_onIncChanged);
    super.dispose();
  }
}
