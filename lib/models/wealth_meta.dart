class WealthMeta {
  const WealthMeta({
    this.annualRate,
    this.maturityDate,
    this.remindOnMaturity = false,
  });

  /// 年利率（百分数，如 2.5 表示 2.5%）。
  final double? annualRate;
  final DateTime? maturityDate;

  /// 是否在理财管理页高亮即将到期（不做系统推送）。
  final bool remindOnMaturity;

  bool get hasRate => annualRate != null && annualRate! > 0;

  bool get hasMaturity => maturityDate != null;

  Map<String, Object?> toJson() {
    return {
      if (annualRate != null) 'annualRate': annualRate,
      if (maturityDate != null)
        'maturityDate': DateTime(
          maturityDate!.year,
          maturityDate!.month,
          maturityDate!.day,
        ).toIso8601String(),
      if (remindOnMaturity) 'remindOnMaturity': true,
    };
  }

  factory WealthMeta.fromJson(Map<String, Object?>? json) {
    if (json == null || json.isEmpty) {
      return const WealthMeta();
    }
    final rateRaw = json['annualRate'];
    final maturityRaw = json['maturityDate'];
    return WealthMeta(
      annualRate: rateRaw is num ? rateRaw.toDouble() : null,
      maturityDate: maturityRaw is String ? DateTime.tryParse(maturityRaw) : null,
      remindOnMaturity: json['remindOnMaturity'] == true,
    );
  }

  WealthMeta copyWith({
    Object? annualRate = _unset,
    Object? maturityDate = _unset,
    bool? remindOnMaturity,
  }) {
    return WealthMeta(
      annualRate: identical(annualRate, _unset)
          ? this.annualRate
          : annualRate as double?,
      maturityDate: identical(maturityDate, _unset)
          ? this.maturityDate
          : maturityDate as DateTime?,
      remindOnMaturity: remindOnMaturity ?? this.remindOnMaturity,
    );
  }

  static const _unset = Object();
}

const defaultWealthSubtypeNames = <String>[
  '定期存款',
  '活期·货币',
  '基金',
  '股票',
  '收益',
  '其他',
];
