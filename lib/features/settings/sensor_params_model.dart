// lib/features/settings/sensor_params_model.dart
class SensorParams {
  final String id;
  final String incubatorId;

  double tempOnC;       // suhu "ON" (fan nyala)
  double tempOffC;      // suhu "OFF" (fan mati)
  double rhOnPercent;   // RH "ON"
  double rhOffPercent;  // RH "OFF"
  double emaAlpha;      // smoothing faktor 0..1
  int? minOnMs;         // anti chatter ON (opsional)
  int? minOffMs;        // anti chatter OFF (opsional)
  bool antiChatter;

  SensorParams({
    required this.id,
    required this.incubatorId,
    required this.tempOnC,
    required this.tempOffC,
    required this.rhOnPercent,
    required this.rhOffPercent,
    required this.emaAlpha,
    required this.minOnMs,
    required this.minOffMs,
    required this.antiChatter,
  });

  factory SensorParams.fromJson(Map<String, dynamic> j) => SensorParams(
    id: j['id'] as String,
    incubatorId: j['incubator_id'] as String,
    tempOnC: (j['temp_on_c'] as num).toDouble(),
    tempOffC: (j['temp_off_c'] as num).toDouble(),
    rhOnPercent: (j['rh_on_percent'] as num).toDouble(),
    rhOffPercent: (j['rh_off_percent'] as num).toDouble(),
    emaAlpha: (j['ema_alpha'] as num).toDouble(),
    minOnMs: j['min_on_ms'] == null ? null : (j['min_on_ms'] as num).toInt(),
    minOffMs: j['min_off_ms'] == null ? null : (j['min_off_ms'] as num).toInt(),
    antiChatter: (j['anti_chatter'] as bool?) ?? false,
  );

  Map<String, dynamic> toPayload() => {
    'temp_on_c': tempOnC,
    'temp_off_c': tempOffC,
    'rh_on_percent': rhOnPercent,
    'rh_off_percent': rhOffPercent,
    'ema_alpha': emaAlpha,
    'min_on_ms': minOnMs,
    'min_off_ms': minOffMs,
    'anti_chatter': antiChatter,
  };
}
