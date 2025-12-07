class TelemetrySeriesPoint {
  final DateTime ts;
  final double? tempBaby;
  final double? tempDht;
  final double? rh;

  TelemetrySeriesPoint({
    required this.ts,
    this.tempBaby,
    this.tempDht,
    this.rh,
  });

  factory TelemetrySeriesPoint.fromJson(Map<String, dynamic> j) {
    return TelemetrySeriesPoint(
      ts: DateTime.parse(j['ts'] as String),
      tempBaby: (j['temp_baby'] as num?)?.toDouble(),
      tempDht: (j['temp_dht'] as num?)?.toDouble(),
      rh: (j['rh'] as num?)?.toDouble(),
    );
  }
}
