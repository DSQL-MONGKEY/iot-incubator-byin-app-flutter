class Telemetry {
  final DateTime ts;
  final double? tDs, tDht, tMain, rh;
  final List<int> fan; // length 6
  final List<int> lamp; // length 2
  final String mode;
  final bool? gpsFix;
  final int? gpsSat;
  final double? lat, lon;
  final int? rev;

  Telemetry({
    required this.ts,
    this.tDs, this.tDht, this.tMain, this.rh,
    required this.fan, required this.lamp,
    required this.mode,
    this.gpsFix, this.gpsSat, this.lat, this.lon,
    this.rev,
  });

  factory Telemetry.fromJson(Map<String, dynamic> j) {
    double? f(x) => (x is num) ? x.toDouble() : null;
    List<int> arr(dynamic a, int n) {
      if (a is List) {
        final out = a.map((e)=> (e is num && e!=0)?1:0).toList();
        if (out.length == n) return out;
      }
      return List<int>.filled(n, 0);
    }

    return Telemetry(
      ts: DateTime.fromMillisecondsSinceEpoch((((j['ts'] ?? 0) as num) * 1000).toInt(), isUtc: true).toLocal(),
      tDs: f(j['t']?['ds']),
      tDht: f(j['t']?['dht']),
      tMain: f(j['t']?['main']),
      rh: f(j['rh']),
      fan: arr(j['fan'], 6),
      lamp: arr(j['lamp'], 2),
      mode: (j['mode'] ?? 'AUTO').toString(),
      gpsFix: j['gps']?['fix'] as bool?,
      gpsSat: (j['gps']?['sat'] as num?)?.toInt(),
      lat: f(j['gps']?['lat']),
      lon: f(j['gps']?['lon']),
      rev: (j['rev'] as num?)?.toInt(),
    );
  }
}
