import 'dart:convert';
import 'package:byin_app/features/incubators/incubator_model.dart';
import 'package:byin_app/features/settings/sensor_params_model.dart';
import 'package:byin_app/features/telemetry/telemetry_series_model.dart';
import 'package:byin_app/features/templates/template_model.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final http.Client _http;

  ApiClient({ required this.baseUrl, http.Client? httpClient })
    : _http = httpClient ?? http.Client();

  
  Future<Map<String, dynamic>> getJson(String path) async {
    final r = await http.get(Uri.parse('$baseUrl$path'));

    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }

    throw Exception('GET $path -> ${r.statusCode}');
  }

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) async {
    final r = await http.patch(Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode(body)
    );

    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }

    throw Exception('PATCH $path -> ${r.statusCode}');
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode(body)
    );

    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }

    throw Exception('PATCH $path -> ${r.statusCode}');
  }

  Future<void> delete(String path) async {
    final r = await http.delete(Uri.parse('$baseUrl$path'));

    if (r.statusCode >= 200 && r.statusCode < 300) return;

    throw Exception('DELETE $path -> ${r.statusCode}');
  }

  // ---------- INCUBATOR SPECIFIC HELPERS ----------

  Future<void> setIncubatorMode(String incubatorId, String mode) async {
    await patchJson('/incubators/$incubatorId/mode', { 'mode': mode });
  }

  Future<List<IncTemplate>> listTemplates(String incubatorId) async {
    final m = await getJson('/incubators/$incubatorId/templates');

    final list = (m['data'] as List).cast<Map<String, dynamic>>();

    return list.map(IncTemplate.fromJson).toList();
  }

  Future<void> applyTemplate(String incubatorId, String templateId,
  { String syncMode = 'SET_MANUAL', String requestedBy = 'byin-app' }) async {
    await postJson('/incubators/$incubatorId/templates/$templateId/apply', {
      'syncMode': syncMode,
      'requested_by': requestedBy
    });
  }

  Future<void> deleteTemplate(String incubatorId, String templateId) async {
    await delete('/incubators/$incubatorId/templates/$templateId');
  }

  Future<List<Incubator>> listIncubator() async {
    final uri  = Uri.parse('$baseUrl/incubators');
    final res = await _http.get(uri).timeout(const Duration(seconds: 8));

    if(res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if(body['success'] != true) {
      throw Exception('API Error');
    }

    final data = (body['data'] as List).cast<Map<String, dynamic>>();
    return data.map(Incubator.fromJson).toList();
  }

  Future<void> createIncubator({
    required String incubatorCode,
    required String name,
    required String status,
    required String mode,
    String? locationLabel,
    String? fwVersion, // optional; null -> backend default
  }) async {
    final payload = <String, dynamic>{
      'incubatorCode': incubatorCode,
      'name': name,
      'status': status,
      'mode': mode,
      if (locationLabel != null && locationLabel.isNotEmpty)
        'locationLabel': locationLabel,
      if (fwVersion != null && fwVersion.isNotEmpty) 'fwVersion': fwVersion,
    };
    await postJson('/incubators', payload);
  }

  Future<void> createTemplate(
    String incubatorId, {
    required String name,
    String? description,
    required List<int> fan,   // panjang 6
    required List<int> lamp,  // panjang 2
    required String createdBy,
  }) async {
    await postJson(
      '/incubators/$incubatorId/templates',
      {
        'name': name,
        'description': description,
        'fan': fan,
        'lamp': lamp,
        'created_by': createdBy,
      },
    );
  }
}

extension TelemetrySeriesApi on ApiClient {
  Future<List<TelemetrySeriesPoint>> getTelemetrySeries(
    String incubatorId, {
    required DateTime from,
    required DateTime to,
    int bucketSec = 300, // 5 menit cocok untuk range 1 bulan
  }) async {
    final uri = Uri.parse(
      '$baseUrl/incubators/$incubatorId/telemetry/series',
    ).replace(queryParameters: {
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      'bucket': '$bucketSec',
    });

    final res = await _http.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('series error ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    return list.map(TelemetrySeriesPoint.fromJson).toList();
  }
}


extension SensorParamsApi on ApiClient {
  // GET /incubators/{id}/params  -> return SensorParams? (bisa belum ada)
  Future<SensorParams?> getSensorParams(String incubatorId) async {
    final r = await getJson('/incubators/$incubatorId/params');
    final data = r['data'];

    if (data == null) return null;
    return SensorParams.fromJson(Map<String, dynamic>.from(data));
  }

  // PUT /incubators/{id}/params (upsert)
  Future<void> upsertSensorParams(String incubatorId, Map<String, dynamic> payload) async {
    await patchJson('/incubators/$incubatorId/params', payload);
  }
}

extension IncubatorManualControlApi on ApiClient {
  Future<void> setFanManual(String incubatorId, List<int> fan) async {
    await patchJson('/incubators/$incubatorId/fan', {'fan': fan});
  }

  Future<void> setLampManual(String incubatorId, List<int> lamp) async {
    await patchJson('/incubators/$incubatorId/lamp', {'lamp': lamp});
  }
}