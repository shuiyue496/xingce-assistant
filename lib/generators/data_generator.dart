import 'dart:math';

import '../models/question.dart';

/// Module 2: data-analysis calculation drills.
/// Numbers mimic real statistics-bureau data; estimation is judged by
/// relative error tolerance.
class DataGenerator {
  static const types = <DataType>[
    DataType('base_estimate', '估算前期量', '现期量÷(1+r)，±3%'),
    DataType('growth_estimate', '估算增长量', '现期量×r÷(1+r)，±3%'),
    DataType('delta_compare', '增量比大小', '两式比增量'),
    DataType('base_compare', '基期比大小', '两式比基期'),
    DataType('avg_annual_growth', '年均增长率', '柱状图，±3%'),
    DataType('frac_small', '分数计算（分子<分母）', '填小数，±2%'),
    DataType('frac_large', '分数计算（分子>分母）', '填小数，±2%'),
    DataType('base_ratio', '基期比重', '部分基期÷整体基期，±3%'),
    DataType('frac_compare', '分数比大小', '接近分数比较'),
    DataType('avg_annual', '年平均量', '表格求和平均，±1%'),
  ];

  static final Map<String, DataType> byId = {
    for (final t in types) t.id: t,
  };

  static const _topics = [
    ('某省粮食产量', '万吨'),
    ('某市地区生产总值', '亿元'),
    ('某省社会消费品零售总额', '亿元'),
    ('某县居民人均可支配收入', '元'),
    ('某国货物进出口总额', '亿美元'),
    ('某地区规模以上工业增加值', '亿元'),
  ];

  static int _ri(Random rng, int min, int max) => min + rng.nextInt(max - min + 1);
  static String _fmt(double v, [int digits = 0]) => v.toStringAsFixed(digits);

  /// Arbitrary growth rate 3.0~45.0 (one decimal), ~20% negative.
  static double _rateArbitrary(Random rng) {
    final v = _ri(rng, 30, 450) / 10.0;
    return rng.nextInt(100) < 20 ? -v : v;
  }

  /// Positive non-friendly rate 5.0~35.0 (one decimal) for compare questions.
  static double _ratePositive(Random rng) => _ri(rng, 50, 350) / 10.0;

  static String _rateText(double r) =>
      r < 0 ? '下降${_fmt(-r, 1)}%' : '增长${_fmt(r, 1)}%';

  static List<Question> generate(String typeId, int n) {
    final rng = Random();
    return List.generate(n, (_) => _build(typeId, rng));
  }

  static Question _build(String typeId, Random rng) {
    switch (typeId) {
      case 'base_estimate':
        return _baseEstimate(rng);
      case 'growth_estimate':
        return _growthEstimate(rng);
      case 'delta_compare':
        return _deltaCompare(rng);
      case 'base_compare':
        return _baseCompare(rng);
      case 'avg_annual_growth':
        return _avgAnnualGrowth(rng);
      case 'frac_small':
        return _fracSmall(rng);
      case 'frac_large':
        return _fracLarge(rng);
      case 'base_ratio':
        return _baseRatio(rng);
      case 'frac_compare':
        return _fracCompare(rng);
      case 'avg_annual':
        return _avgAnnual(rng);
      default:
        throw ArgumentError('unknown data type: $typeId');
    }
  }

  static Question _q(String typeId, String prompt, String answer,
      {double tol = 0,
      String expl = '',
      Map<String, dynamic>? data,
      bool compareMode = false,
      List<String>? options}) {
    return Question(
      module: 'data',
      typeId: typeId,
      typeName: DataGenerator.byId[typeId]!.name,
      prompt: prompt,
      options: options,
      answerText: answer,
      answerNum: double.tryParse(answer),
      tolerance: tol,
      explanation: expl,
      data: data,
      compareMode: compareMode,
    );
  }

  // ---------- 估算前期量 ----------
  static Question _baseEstimate(Random rng) {
    final (topic, unit) = _topics[rng.nextInt(_topics.length)];
    final cur = _ri(rng, 2000, 9999);
    final r = _rateArbitrary(rng);
    final base = cur / (1 + r / 100);
    final divisor = (1 + r / 100).toStringAsFixed(3);
    return _q(
      'base_estimate',
      '2024 年$topic为 $cur$unit，比上年${_rateText(r)}。2023 年$topic约为多少$unit？（填整数）',
      _fmt(base, 2),
      tol: 0.03,
      expl: '$cur÷(1+${r > 0 ? '+' : ''}$r%)≈${_fmt(base, 2)}$unit，允许±3%',
      data: {'formula': '$cur/$divisor'},
    );
  }

  // ---------- 估算增长量 ----------
  static Question _growthEstimate(Random rng) {
    final (topic, unit) = _topics[rng.nextInt(_topics.length)];
    final cur = _ri(rng, 2000, 9999);
    final r = _rateArbitrary(rng);
    if (r < 0) {
      // negative growth: ask about the decline amount
      final delta = cur * -r / 100 / (1 + r / 100);
      return _q(
        'growth_estimate',
        '2024 年$topic为 $cur$unit，比上年下降${_fmt(-r, 1)}%。2024 年$topic比上年减少约多少$unit？（填整数）',
        _fmt(delta, 2),
        tol: 0.03,
        expl: '$cur×${_fmt(-r, 1)}%÷(1-${_fmt(-r, 1)}%)≈${_fmt(delta, 2)}$unit，允许±3%',
        data: {'formula': '$cur×${_fmt(-r, 1)}%÷${(1 + r / 100).toStringAsFixed(3)}'},
      );
    }
    final delta = cur * r / 100 / (1 + r / 100);
    return _q(
      'growth_estimate',
      '2024 年$topic为 $cur$unit，比上年增长${_fmt(r, 1)}%。2024 年$topic比上年增加约多少$unit？（填整数）',
      _fmt(delta, 2),
      tol: 0.03,
      expl: '$cur×${_fmt(r, 1)}%÷(1+${_fmt(r, 1)}%)≈${_fmt(delta, 2)}$unit，允许±3%',
      data: {'formula': '$cur×${_fmt(r, 1)}%÷${(1 + r / 100).toStringAsFixed(3)}'},
    );
  }

  // ---------- 增量比大小 ----------
  static Question _deltaCompare(Random rng) {
    var a = 0, b = 0, da = 0.0, db = 0.0, ra = 0.0, rb = 0.0;
    for (var i = 0; i < 10; i++) {
      a = _ri(rng, 100, 999);
      b = _ri(rng, 100, 999);
      ra = _ratePositive(rng);
      rb = _ratePositive(rng);
      if (rb == ra) rb = _ratePositive(rng);
      da = a * ra / 100 / (1 + ra / 100);
      db = b * rb / 100 / (1 + rb / 100);
      if ((da - db).abs() / max(da, db) > 0.02) break;
    }
    final answer = da > db ? '大于' : '小于';
    final expl = 'A 增量≈${_fmt(da, 1)}，B 增量≈${_fmt(db, 1)}，故 A ${answer}B';
    return _q(
      'delta_compare',
      'A：$a ÷ (1+$ra%) × $ra%\nB：$b ÷ (1+$rb%) × $rb%',
      answer,
      tol: 0,
      expl: expl,
      compareMode: true,
      options: const ['大于', '小于'],
      data: {
        'left': '$a/${(1 + ra / 100).toStringAsFixed(3)}×$ra%',
        'right': '$b/${(1 + rb / 100).toStringAsFixed(3)}×$rb%',
      },
    );
  }

  // ---------- 基期比大小 ----------
  static Question _baseCompare(Random rng) {
    var a = 0, b = 0, ba = 0.0, bb = 0.0, ra = 0.0, rb = 0.0;
    for (var i = 0; i < 10; i++) {
      a = _ri(rng, 100, 999);
      b = _ri(rng, 100, 999);
      ra = _ratePositive(rng);
      rb = _ratePositive(rng);
      if (rb == ra) rb = _ratePositive(rng);
      ba = a / (1 + ra / 100);
      bb = b / (1 + rb / 100);
      if ((ba - bb).abs() / max(ba, bb) > 0.02) break;
    }
    final answer = ba > bb ? '大于' : '小于';
    final expl = 'A 基期≈${_fmt(ba, 1)}，B 基期≈${_fmt(bb, 1)}，故 A ${answer}B';
    return _q(
      'base_compare',
      'A：$a ÷ (1+$ra%)\nB：$b ÷ (1+$rb%)',
      answer,
      tol: 0,
      expl: expl,
      compareMode: true,
      options: const ['大于', '小于'],
      data: {
        'left': '$a/${(1 + ra / 100).toStringAsFixed(3)}',
        'right': '$b/${(1 + rb / 100).toStringAsFixed(3)}',
      },
    );
  }

  // ---------- 年均增长率 ----------
  static Question _avgAnnualGrowth(Random rng) {
    final (topic, unit) = _topics[rng.nextInt(_topics.length)];
    final n = _ri(rng, 4, 5);
    final y0 = _ri(rng, 2011, 2015);
    final r = _ratePositive(rng);
    final start = _ri(rng, 25, 90) * 10000;
    final years = List.generate(n + 1, (i) => '${y0 + i}');
    final values = List.generate(n + 1, (i) => (start * pow(1 + r / 100, i)).round());
    final last = values.last;
    return _q(
      'avg_annual_growth',
      '求 ${y0 + 1}~${y0 + n} 年的年均增长率：',
      _fmt(r, 1),
      tol: 0.03,
      expl: '（$last÷$start）^(1/$n)-1≈${_fmt(r, 1)}%，允许±3%',
      data: {
        'chart': {
          'years': years,
          'values': values,
          'unit': '',
          'legend': '$topic（$unit）',
        },
        'noExtrapolate': true,
      },
    );
  }

  // ---------- 分数计算（分子<分母） ----------
  static Question _fracSmall(Random rng) {
    // Three difficulty tiers: easy small fractions, medium, hard 3-digit ones.
    final tier = rng.nextInt(10);
    int a, b;
    if (tier < 2) {
      // easy: familiar small fractions (7/16, 9/11...)
      const pool = [7, 8, 9, 11, 12, 13, 14, 15, 16];
      b = pool[rng.nextInt(pool.length)];
      a = _ri(rng, 1, b - 1);
    } else if (tier < 5) {
      // medium: two-digit denominators
      b = _ri(rng, 17, 99);
      a = _ri(rng, max(3, b ~/ 10), b - 1);
    } else {
      // hard: three-digit denominators, ratio 0.3~0.85
      b = _ri(rng, 300, 999);
      a = _ri(rng, b * 3 ~/ 10, b * 85 ~/ 100);
    }
    final v = a / b;
    return _q(
      'frac_small',
      '$a / $b ≈',
      _fmt(v, 3),
      tol: 0.02,
      expl: '$a÷$b=${_fmt(v, 3)}，建议写到小数点后 2~3 位，允许±2%',
      data: {
        'hint': '建议写到小数点后 2~3 位，允许误差范围：±2%',
        'prefix': '0.',
      },
    );
  }

  // ---------- 分数计算（分子>分母） ----------
  static Question _fracLarge(Random rng) {
    // Easy: one-digit denominator. Hard: two-digit denominator, 1.1~2.9 ratio.
    int a, b;
    if (rng.nextInt(10) < 4) {
      b = _ri(rng, 2, 9);
      a = _ri(rng, b + 1, b * 3);
    } else {
      b = _ri(rng, 11, 99);
      a = _ri(rng, b * 11 ~/ 10 + 1, b * 29 ~/ 10);
    }
    final v = a / b;
    return _q(
      'frac_large',
      '$a / $b ≈',
      _fmt(v, 3),
      tol: 0.02,
      expl: '$a÷$b=${_fmt(v, 3)}，允许±2%',
      data: {'hint': '建议写到小数点后 2~3 位，允许误差范围：±2%'},
    );
  }

  // ---------- 基期比重 ----------
  static Question _baseRatio(Random rng) {
    final (partT, _) = _topics[rng.nextInt(_topics.length)];
    final (wholeT, _) = _topics[rng.nextInt(_topics.length)];
    final partCur = _ri(rng, 2000, 30000);
    final wholeCur = _ri(rng, partCur * 2, partCur * 10);
    final rp = _rateArbitrary(rng).abs();
    final rw = _rateArbitrary(rng).abs();
    final basePart = partCur / (1 + rp / 100);
    final baseWhole = wholeCur / (1 + rw / 100);
    final ratio = basePart * 100 / baseWhole;
    return _q(
      'base_ratio',
      '2024 年$partT为 $partCur 亿元，比上年增长${_fmt(rp, 1)}%；$wholeT为 $wholeCur 亿元，比上年增长${_fmt(rw, 1)}%。2023 年$partT占$wholeT的比重约为多少？（填百分数）',
      _fmt(ratio, 1),
      tol: 0.03,
      expl: '$partCur÷(1+${_fmt(rp, 1)}%)÷[$wholeCur÷(1+${_fmt(rw, 1)}%)]≈${_fmt(ratio, 1)}%，允许±3%',
    );
  }

  // ---------- 分数比大小 ----------
  static Question _fracCompare(Random rng) {
    var a1 = 0, b1 = 0, a2 = 0, b2 = 0;
    var v1 = 0.0, v2 = 0.0;
    for (var i = 0; i < 10; i++) {
      final k1 = _ri(rng, 55, 78) / 100.0;
      final k2 = k1 + (rng.nextBool() ? 1 : -1) * _ri(rng, 1, 3) / 100.0;
      b1 = _ri(rng, 150, 600);
      b2 = _ri(rng, 150, 600);
      a1 = (b1 * k1).round();
      a2 = (b2 * k2).round();
      v1 = a1 / b1;
      v2 = a2 / b2;
      final d = (v1 - v2).abs() / max(v1, v2);
      if (d > 0.004 && d < 0.08) break; // close but distinguishable
    }
    final answer = v1 > v2 ? '大于' : '小于';
    final expl =
        'A=$a1/$b1≈${_fmt(v1 * 100, 1)}%，B=$a2/$b2≈${_fmt(v2 * 100, 1)}%，故 A ${answer}B';
    return _q(
      'frac_compare',
      'A：$a1 / $b1\nB：$a2 / $b2',
      answer,
      tol: 0,
      expl: expl,
      compareMode: true,
      options: const ['大于', '小于'],
      data: {'left': '$a1/$b1', 'right': '$a2/$b2'},
    );
  }

  // ---------- 年平均量 ----------
  static Question _avgAnnual(Random rng) {
    final (topic, unit) = _topics[rng.nextInt(_topics.length)];
    final y0 = _ri(rng, 2011, 2014);
    final base = _ri(rng, 480, 720);
    final step = _ri(rng, 25, 45);
    final rows = <List<String>>[];
    var v = base;
    for (var i = 0; i < 6; i++) {
      rows.add(['${y0 + i}', '$v']);
      v += step + _ri(rng, -8, 12);
      if (v <= int.parse(rows.last[1])) v = int.parse(rows.last[1]) + 10;
    }
    final mean = rows.map((r) => int.parse(r[1])).reduce((a, b) => a + b) / 6;
    return _q(
      'avg_annual',
      '求 $y0~${y0 + 5} 年$topic的年平均量：（填整数，单位：$unit）',
      '${mean.round()}',
      tol: 0.01,
      expl: '（${rows.map((r) => r[1]).join('+')}）÷6≈${mean.round()}$unit，允许±1%',
      data: {
        'chart': {
          'years': rows.map((r) => r[0]).toList(),
          'values': rows.map((r) => int.parse(r[1])).toList(),
          'unit': '',
          'legend': '$topic（$unit）',
        },
        'hint': '允许误差范围：±1%',
      },
    );
  }
}

class DataType {
  final String id;
  final String name;
  final String subtitle;

  const DataType(this.id, this.name, this.subtitle);
}
