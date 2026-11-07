/// 一次无尽挑战的结算记录，本地排行榜按波次、击杀、金币依次排序。
class EndlessRecord {
  const EndlessRecord({
    required this.waves,
    required this.kills,
    required this.gold,
    required this.date,
  });

  final int waves;
  final int kills;
  final int gold;
  final String date;

  factory EndlessRecord.fromJson(Map<String, dynamic> json) => EndlessRecord(
    waves: (json['waves'] as num?)?.toInt() ?? 0,
    kills: (json['kills'] as num?)?.toInt() ?? 0,
    gold: (json['gold'] as num?)?.toInt() ?? 0,
    date: json['date'] as String? ?? '',
  );

  factory EndlessRecord.now({
    required int waves,
    required int kills,
    required int gold,
  }) => EndlessRecord(
    waves: waves,
    kills: kills,
    gold: gold,
    date: DateTime.now().toIso8601String().substring(0, 10),
  );

  Map<String, Object> toJson() => {
    'waves': waves,
    'kills': kills,
    'gold': gold,
    'date': date,
  };

  static int compare(EndlessRecord a, EndlessRecord b) {
    if (a.waves != b.waves) return b.waves.compareTo(a.waves);
    if (a.kills != b.kills) return b.kills.compareTo(a.kills);
    return b.gold.compareTo(a.gold);
  }
}

/// 按坚守波数给出称号，用于结算与排行榜。
String endlessRank(int waves) {
  if (waves >= 60) return '神话守卫';
  if (waves >= 40) return '传奇守卫';
  if (waves >= 25) return '精英守卫';
  if (waves >= 15) return '老练守卫';
  if (waves >= 8) return '可靠守卫';
  return '见习守卫';
}
