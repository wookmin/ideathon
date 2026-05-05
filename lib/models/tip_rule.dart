class TipRule {
  const TipRule({
    required this.suggested,
    required this.min,
    required this.max,
    required this.culture,
  });

  final double suggested;
  final double min;
  final double max;
  final String culture;
}

const defaultTipRule = TipRule(suggested: 10, min: 0, max: 30, culture: '선택');

const tipRules = <String, TipRule>{
  'US': TipRule(suggested: 18, min: 15, max: 25, culture: '필수'),
  'CA': TipRule(suggested: 18, min: 15, max: 20, culture: '필수'),
  'GB': TipRule(suggested: 10, min: 0, max: 15, culture: '선택'),
  'AU': TipRule(suggested: 10, min: 0, max: 15, culture: '선택'),
  'JP': TipRule(suggested: 0, min: 0, max: 0, culture: '불필요'),
  'KR': TipRule(suggested: 0, min: 0, max: 0, culture: '불필요'),
  'TH': TipRule(suggested: 10, min: 0, max: 15, culture: '선택'),
  'VN': TipRule(suggested: 5, min: 0, max: 10, culture: '선택'),
  'FR': TipRule(suggested: 5, min: 0, max: 10, culture: '선택'),
  'DE': TipRule(suggested: 5, min: 0, max: 10, culture: '선택'),
};
