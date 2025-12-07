class IncTemplate {
  final String id;
  final String name;
  final String? description;
  final List<int> fan;   // panjang 6, isi 0/1
  final List<int> lamp;  // panjang 2, isi 0/1
  final bool? isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  IncTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.fan,
    required this.lamp,
    this.isArchived,
    this.createdAt,
    this.updatedAt,
  });

  factory IncTemplate.fromJson(Map<String, dynamic> j) => IncTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    fan: (j['fan'] as List).map((e) => (e as num).toInt()).toList(),
    lamp: (j['lamp'] as List).map((e) => (e as num).toInt()).toList(),
    isArchived: j['isArchived'] as bool?,
    createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
    updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at']) : null,
  );

  /// index kipas yang ON (0-based)
  List<int> enabledFanIdx() => [
    for (int i = 0; i < fan.length; i++) if (fan[i] != 0) i
  ];

  /// index lampu yang ON (0-based)
  List<int> enabledLampIdx() => [
    for (int i = 0; i < lamp.length; i++) if (lamp[i] != 0) i
  ];
}
