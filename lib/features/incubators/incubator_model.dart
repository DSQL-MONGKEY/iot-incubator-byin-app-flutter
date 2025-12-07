class Incubator {
  final String id;
  final String code;
  final String name;
  final String status; // ONLINE | OFFLINE | MAINTENANCE
  final String? mode;   // AUTO | MANUAL
  final String? fwVersion;
  final DateTime? lastSeenAt;

  Incubator({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    required this.mode,
    this.fwVersion,
    this.lastSeenAt,
  });

  bool get isOnline => status == 'ONLINE';

  factory Incubator.fromJson(Map<String, dynamic>j) => Incubator(
    id: j['id'] as String,
    code: j['code'] as String,
    name: j['name'] as String,
    status: j['status'] as String,
    mode: j['mode'] as String,
    fwVersion: j['fwVersion'] as String,
    lastSeenAt: j['last_seen_at'] != null 
    ? DateTime.parse(j['last_seen_at'] as String)
    : null,
  );
}