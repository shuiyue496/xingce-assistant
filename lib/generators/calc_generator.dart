import 'dart:math';

import '../models/question.dart';

/// Module 1: basic arithmetic drills (16 types, program-generated).
class CalcGenerator {
  static const types = <CalcType>[
    CalcType('add_sub_2d', '两位数加减', '口算基本功'),
    CalcType('make_hundred', '凑整百', '补数到整百/整千'),
    CalcType('add_sub_3d', '三位数加减', '进位退位训练'),
    CalcType('multi_add', '多数相加', '3~5 个数连加'),
    CalcType('mixed_add_sub', '混合加减', '加减混合长式'),
    CalcType('mul_2d_1d', '两位数乘一位数', '乘法口诀延伸'),
    CalcType('mul_3d_1d', '三位数乘一位数', '进位乘法'),
    CalcType('mul_11', '两位数乘11', '首尾相加速算'),
    CalcType('mul_15', '两位数乘15', '先乘10再加半'),
    CalcType('mul_2d_2d', '两位数乘两位数', '交叉相乘'),
    CalcType('div_3d_1d', '三位数除一位数', '整除练习'),
    CalcType('div_3d_2d', '三位数除两位数', '竖式除法'),
    CalcType('mul_estimate', '乘法估算', '凑整估算，答案≈整十'),
    CalcType('div_5d_3d', '五位数除三位数', '估算，允许±2%'),
    CalcType('div_3d_4d', '三位数除四位数', '结果填百分数，允许±3%'),
  ];

  static final Map<String, CalcType> byId = {
    for (final t in types) t.id: t,
  };

  /// Generates [n] questions of [typeId].
  static List<Question> generate(String typeId, int n) {
    final rng = Random();
    return List.generate(n, (_) => _build(typeId, rng));
  }

  static Question _build(String typeId, Random rng) {
    switch (typeId) {
      case 'add_sub_2d':
        return _addSub(2, rng);
      case 'make_hundred':
        return _makeHundred(rng);
      case 'add_sub_3d':
        return _addSub(3, rng);
      case 'multi_add':
        return _multiAdd(rng);
      case 'mixed_add_sub':
        return _mixedAddSub(rng);
      case 'mul_2d_1d':
        return _mul('2d', '1d', rng);
      case 'mul_3d_1d':
        return _mul('3d', '1d', rng);
      case 'mul_11':
        return _mul11(rng);
      case 'mul_15':
        return _mul15(rng);
      case 'mul_2d_2d':
        return _mul('2d', '2d', rng);
      case 'div_3d_1d':
        return _div(3, 1, rng);
      case 'div_3d_2d':
        return _div(3, 2, rng);
      case 'mul_estimate':
        return _mulEstimate(rng);
      case 'div_5d_3d':
        return _divEstimate(5, 3, rng);
      case 'div_3d_4d':
        return _divPercent(rng);
      default:
        throw ArgumentError('unknown calc type: $typeId');
    }
  }

  static int _ri(Random rng, int min, int max) => min + rng.nextInt(max - min + 1);

  static int _numWithDigits(Random rng, int digits) =>
      _ri(rng, pow(10, digits - 1).toInt(), pow(10, digits).toInt() - 1);

  static Question _q(String typeId, String typeName, String prompt,
      String answer,
      {double tol = 0, String expl = ''}) {
    return Question(
      module: 'calc',
      typeId: typeId,
      typeName: typeName,
      prompt: prompt,
      answerText: answer,
      answerNum: double.tryParse(answer),
      tolerance: tol,
      explanation: expl,
    );
  }

  static Question _addSub(int digits, Random rng) {
    final typeName = digits == 2 ? '两位数加减' : '三位数加减';
    final a = _numWithDigits(rng, digits);
    final b = _numWithDigits(rng, digits);
    if (rng.nextBool()) {
      final ans = a + b;
      return _q('add_sub_${digits}d', typeName, '$a ＋ $b =', '$ans',
          expl: '$a＋$b=$ans');
    }
    final hi = max(a, b);
    final lo = min(a, b);
    final ans = hi - lo;
    return _q('add_sub_${digits}d', typeName, '$hi － $lo =', '$ans',
        expl: '`$hi－`$lo=`$ans');
  }

  static Question _makeHundred(Random rng) {
    // Two-digit numbers complement to 100, three-digit to 1000.
    final target = rng.nextBool() ? 100 : 1000;
    final lo = target == 100 ? 10 : 100;
    final part = _ri(rng, lo, target - 11);
    final ans = target - part;
    return _q('make_hundred', '凑整百', '$part ＋ ? = $target', '$ans',
        expl: '$target－$part＝$ans，凑整到$target');
  }

  static Question _multiAdd(Random rng) {
    final count = _ri(rng, 3, 5);
    // Mostly two-digit terms; occasionally one three-digit term.
    final nums = <int>[];
    final threePos = rng.nextInt(count);
    for (var i = 0; i < count; i++) {
      nums.add(i == threePos && rng.nextInt(100) < 20
          ? _numWithDigits(rng, 3)
          : _numWithDigits(rng, 2));
    }
    final sum = nums.reduce((a, b) => a + b);
    final prompt = nums.join(' ＋ ');
    return _q('multi_add', '多数相加', '$prompt =', '$sum',
        expl: '${nums.join('＋')}＝$sum');
  }

  static Question _mixedAddSub(Random rng) {
    final count = _ri(rng, 4, 6);
    var value = 0;
    final parts = <String>[];
    for (var i = 0; i < count; i++) {
      final num = rng.nextInt(100) < 15
          ? _numWithDigits(rng, 3)
          : _numWithDigits(rng, 2);
      if (i == 0) {
        value = num;
        parts.add('$num');
      } else if (rng.nextBool() || value - num < 0) {
        value += num;
        parts.add('＋ $num');
      } else {
        value -= num;
        parts.add('－ $num');
      }
    }
    return _q('mixed_add_sub', '混合加减', '${parts.join(' ')} =', '$value',
        expl: '${parts.join(' ')}＝$value');
  }

  static Question _mul(String aDigits, String bDigits, Random rng) {
    final a = _numWithDigits(rng, int.parse(aDigits[0]));
    final b = _numWithDigits(rng, int.parse(bDigits[0]));
    final ans = a * b;
    final name = '${aDigits == '2d' ? '两位数' : '三位数'}乘${bDigits == '1d' ? '一位数' : '两位数'}';
    return _q('mul_${aDigits}_$bDigits', name, '$a × $b =', '$ans',
        expl: '$a×$b＝$ans');
  }

  static Question _mul11(Random rng) {
    final a = _numWithDigits(rng, 2);
    final ans = a * 11;
    return _q('mul_11', '两位数乘11', '$a × 11 =', '$ans',
        expl: '两头一拉，中间相加：$a×11＝$ans');
  }

  static Question _mul15(Random rng) {
    final a = _numWithDigits(rng, 2);
    final ans = a * 15;
    return _q('mul_15', '两位数乘15', '$a × 15 =', '$ans',
        expl: '$a×15＝$a×10＋$a×5＝$ans');
  }

  static Question _div(int dividendDigits, int divisorDigits, Random rng) {
    // Non-exact division on purpose: trains estimation, ±3% tolerance.
    final d = divisorDigits == 1
        ? _ri(rng, 2, 9) // never divide by 1
        : _ri(rng, 11, 99);
    final a = _numWithDigits(rng, dividendDigits);
    final exact = a / d;
    final ans = exact.round();
    final name = '$dividendDigits位数除$divisorDigits位数';
    return _q('div_${dividendDigits}d_${divisorDigits}d', name, '$a ÷ $d ≈', '$ans',
        tol: 0.03,
        expl: '$a÷$d≈$ans（精确值 ${exact.toStringAsFixed(2)}）');
  }

  static Question _mulEstimate(Random rng) {
    // Exact product, ±5% tolerance (matches the original app).
    final a = _numWithDigits(rng, 2);
    final b = _numWithDigits(rng, 2);
    final ar = (a / 10).round() * 10;
    final br = (b / 10).round() * 10;
    final exact = a * b;
    return _q(
        'mul_estimate', '乘法估算', '$a × $b ≈', '$exact',
        tol: 0.05,
        expl: '估算：$a≈$ar，$b≈$br，$ar×$br=${ar * br}（精确值 $exact，允许±5%）');
  }

  static Question _divEstimate(int dividendDigits, int divisorDigits, Random rng) {
    final a = _numWithDigits(rng, dividendDigits);
    final d = _numWithDigits(rng, divisorDigits);
    final exact = a / d;
    final rounded = exact.round();
    return _q(
        'div_${dividendDigits}d_${divisorDigits}d',
        '$dividendDigits位数除$divisorDigits位数',
        '$a ÷ $d ≈',
        '$rounded',
        tol: 0.02,
        expl: '$a÷$d≈$rounded（精确值 ${exact.toStringAsFixed(2)}）');
  }

  static Question _divPercent(Random rng) {
    final a = _ri(rng, 100, 999);
    final d = _ri(rng, 1000, 9999);
    final pct = a * 100 / d; // percent value
    final rounded = (pct * 10).round() / 10;
    return _q(
        'div_3d_4d', '三位数除四位数', '$a ÷ $d =（填百分数，如 12.3）', _fmt(rounded),
        tol: 0.03,
        expl: '$a÷$d≈${_fmt(rounded)}%，即约 1/${(d / a).round()}');
  }

  static String _fmt(double v) {
    var s = v.toStringAsFixed(1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return s;
  }
}

class CalcType {
  final String id;
  final String name;
  final String subtitle;

  const CalcType(this.id, this.name, this.subtitle);
}
