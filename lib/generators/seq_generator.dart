import 'dart:math';

import '../models/question.dart';

/// Module 3: number-sequence reasoning.
/// Each generator emits an 8-term sequence with the 8th term missing.
class SeqGenerator {
  static const types = <SeqType>[
    SeqType('basic', '基础数列', '等差/等比/平方/质数/斐波那契'),
    SeqType('multi_level', '多级数列', '差分构成新数列'),
    SeqType('power', '幂次数列', 'n²/n³ ± 修正'),
    SeqType('recurrence', '递推数列', '前项运算得后项'),
    SeqType('factor', '因数分解', 'n(n+1) 型'),
    SeqType('fraction', '分数数列', '分子分母分别成规律'),
    SeqType('mechanical', '机械划分', '拆位各自成规律'),
    SeqType('multiple', '多重数列', '奇偶项分别看'),
    SeqType('graph', '图形数列', '九宫格找规律'),
    SeqType('periodic', '周期数列', '片段循环重复'),
  ];

  static final Map<String, SeqType> byId = {
    for (final t in types) t.id: t,
  };

  static List<Question> generate(String typeId, int n) {
    final rng = Random();
    return List.generate(n, (_) => _build(typeId, rng));
  }

  static Question _build(String typeId, Random rng) {
    switch (typeId) {
      case 'basic':
        return _basic(rng);
      case 'multi_level':
        return _multiLevel(rng);
      case 'power':
        return _power(rng);
      case 'recurrence':
        return _recurrence(rng);
      case 'factor':
        return _factor(rng);
      case 'fraction':
        return _fraction(rng);
      case 'mechanical':
        return _mechanical(rng);
      case 'multiple':
        return _multiple(rng);
      case 'graph':
        return _graph(rng);
      case 'periodic':
        return _periodic(rng);
      default:
        throw ArgumentError('unknown seq type: $typeId');
    }
  }

  static int _ri(Random rng, int min, int max) => min + rng.nextInt(max - min + 1);
  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  static Question _q(String typeId, List<int> seq, int answer,
      List<int> distractors, String expl) {
    final prompt = '${seq.sublist(0, 7).join(', ')}, ?';
    return _qOpts(typeId, prompt, answer, distractors, expl);
  }

  static Question _qOpts(String typeId, String prompt, int answer,
      List<int> distractors, String expl) {
    final opts = <String>{'$answer'};
    final rng = Random();
    var guard = 0;
    for (final d in distractors) {
      if (guard++ > 20) break;
      if (d > 0 && d != answer) opts.add('$d');
    }
    // pad with random near values until 4 options
    var pad = 1;
    while (opts.length < 4) {
      final cand = answer + (pad % 2 == 0 ? pad : -pad) + rng.nextInt(3);
      if (cand > 0 && cand != answer) opts.add('$cand');
      pad++;
    }
    final list = opts.take(4).toList()..shuffle(rng);
    return Question(
      module: 'seq',
      typeId: typeId,
      typeName: SeqGenerator.byId[typeId]!.name,
      prompt: prompt,
      options: list,
      answerText: '$answer',
      explanation: expl,
    );
  }

  static Question _fractionQ(String typeId, String prompt, int a, int b,
      List<String> distractors, String expl) {
    final rng = Random();
    final opts = <String>{'$a/$b'};
    opts.addAll(distractors.where((d) => d != '$a/$b'));
    while (opts.length < 4) {
      opts.add('${a + _ri(rng, 1, 3)}/${b + _ri(rng, 1, 4)}');
    }
    final list = opts.toList()..shuffle(rng);
    return Question(
      module: 'seq',
      typeId: typeId,
      typeName: SeqGenerator.byId[typeId]!.name,
      prompt: prompt,
      options: list,
      answerText: '$a/$b',
      explanation: expl,
    );
  }

  // ---------- 基础数列 ----------
  static Question _basic(Random rng) {
    final kind = rng.nextInt(5);
    switch (kind) {
      case 0: // arithmetic
        final a1 = _ri(rng, 2, 30);
        final d = _ri(rng, 2, 9);
        final seq = List.generate(8, (i) => a1 + i * d);
        return _q('basic', seq, seq.last, [seq.last + d, seq.last - d, a1],
            '等差数列，公差 $d：$a1, ${a1 + d}, …');
      case 1: // geometric
        final a1 = _ri(rng, 1, 4);
        final q = _ri(rng, 2, 3);
        final seq = List.generate(8, (i) => a1 * pow(q, i).toInt());
        return _q('basic', seq, seq.last,
            [seq.last * q, (seq.last / q).round(), seq.last + q],
            '等比数列，公比 $q');
      case 2: // squares
        final start = _ri(rng, 2, 9);
        final seq = List.generate(8, (i) => pow(start + i, 2).toInt());
        return _q('basic', seq, seq.last,
            [seq.last + 2 * (start + 7) + 1, seq.last + 1, seq.last - 1],
            '平方数列：$start², ${start + 1}², …');
      case 3: // primes
        const primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];
        final offset = rng.nextInt(2);
        final seq = primes.sublist(offset, offset + 8);
        return _q('basic', seq, seq.last, [seq.last + 2, seq.last + 4, seq.last + 6],
            '质数数列');
      default: // fibonacci variants
        final a = _ri(rng, 1, 3);
        final b = _ri(rng, 2, 5);
        final seq = <int>[a, b];
        for (var i = 2; i < 8; i++) {
          seq.add(seq[i - 1] + seq[i - 2]);
        }
        return _q('basic', seq, seq.last, [seq.last + seq[6], seq.last * 2, seq.last - seq[5]],
            '递推：前两项之和等于后一项');
    }
  }

  // ---------- 多级数列 ----------
  static Question _multiLevel(Random rng) {
    if (rng.nextBool()) {
      // second-level arithmetic: differences form an arithmetic series
      final d1 = _ri(rng, 1, 3);
      final dd = _ri(rng, 1, 3);
      final seq = <int>[];
      var a = _ri(rng, 1, 9);
      var diff = d1;
      for (var i = 0; i < 8; i++) {
        seq.add(a);
        a += diff;
        diff += dd;
      }
      return _q('multi_level', seq, seq.last,
          [seq.last + diff, seq.last + diff + dd, seq.last + diff - dd],
          '差数列：$d1, ${d1 + dd}, ${d1 + 2 * dd}, … 为等差数列（二级等差）');
    }
    // second-level geometric
    final d1 = _ri(rng, 2, 4);
    final q = 2;
    final seq = <int>[];
    var a = _ri(rng, 1, 9);
    var diff = d1;
    for (var i = 0; i < 8; i++) {
      seq.add(a);
      a += diff;
      diff *= q;
    }
    return _q('multi_level', seq, seq.last, [seq.last + diff, seq.last + diff * 2, seq.last + diff ~/ 2],
        '差数列：$d1, ${d1 * 2}, ${d1 * 4}, … 为等比数列（二级等比）');
  }

  // ---------- 幂次数列 ----------
  static Question _power(Random rng) {
    final square = rng.nextBool();
    final start = _ri(rng, 2, 8);
    final k = rng.nextBool() ? _ri(rng, 1, 6) : -_ri(rng, 1, 6);
    final seq = List.generate(8, (i) {
      final n = start + i;
      return (square ? n * n : n * n * n) + k;
    });
    final base = square ? '平方' : '立方';
    final dK = k >= 0 ? '+$k' : '$k';
    return _q('power', seq, seq.last,
        [seq.last + (square ? 2 * (start + 7) + 1 : 3 * pow(start + 7, 2).toInt() + 3) + 1,
          seq.last + 1, seq.last - 1],
        '$base数列修正：n²$dK / n³$dK');
  }

  // ---------- 递推数列 ----------
  static Question _recurrence(Random rng) {
    final kind = rng.nextInt(3);
    final seq = <int>[];
    switch (kind) {
      case 0: // a(n) = a(n-1) + 2*a(n-2)
        seq.addAll([_ri(rng, 1, 4), _ri(rng, 2, 6)]);
        for (var i = 2; i < 8; i++) {
          seq.add(seq[i - 1] + 2 * seq[i - 2]);
        }
        return _q('recurrence', seq, seq.last,
            [seq.last + seq[6] + 2 * seq[5], seq.last * 2, seq.last + seq[6]],
            '递推：后项 = 前项 + 2×前前项');
      case 1: // a(n) = 2*a(n-1) + k
        final k = _ri(rng, 1, 5);
        var a = _ri(rng, 2, 6);
        for (var i = 0; i < 8; i++) {
          seq.add(a);
          a = 2 * a + k;
        }
        return _q('recurrence', seq, seq.last,
            [2 * seq.last + k, 2 * seq.last, seq.last + k],
            '递推：后项 = 前项×2 + $k');
      default: // a(n) = 2*a(n-1) + a(n-2)
        seq.addAll([_ri(rng, 1, 4), _ri(rng, 2, 6)]);
        for (var i = 2; i < 8; i++) {
          seq.add(2 * seq[i - 1] + seq[i - 2]);
        }
        return _q('recurrence', seq, seq.last,
            [seq.last + 2 * seq[6] + seq[5], seq.last + seq[6], seq.last * 3],
            '递推：后项 = 前项×2 + 前前项');
    }
  }

  // ---------- 因数分解 ----------
  static Question _factor(Random rng) {
    final start = _ri(rng, 1, 5);
    final kind = rng.nextInt(3);
    final seq = List.generate(8, (i) {
      final n = start + i;
      switch (kind) {
        case 0:
          return n * (n + 1); // n(n+1)
        case 1:
          return n * (n + 2); // n(n+2)
        default:
          return n * n - 1; // (n-1)(n+1)
      }
    });
    final expl = switch (kind) {
      0 => '因数分解：n×(n+1)',
      1 => '因数分解：n×(n+2)',
      _ => '因数分解：(n-1)×(n+1) = n²-1',
    };
    return _q('factor', seq, seq.last,
        [seq.last + 2 * (start + 7) + 3, seq.last + 1, seq.last - 1], expl);
  }

  // ---------- 分数数列 ----------
  static Question _fraction(Random rng) {
    final da = _ri(rng, 1, 3); // numerator difference
    final db = _ri(rng, 1, 4); // denominator difference
    final a1 = _ri(rng, 1, 5);
    final b1 = _ri(rng, 4, 12);
    final nums = List.generate(8, (i) => a1 + i * da);
    final dens = List.generate(8, (i) => b1 + i * db);
    final prompt = List.generate(7, (i) => '${nums[i]}/${dens[i]}').join(', ');
    final an = nums.last, ad = dens.last;
    final g = _gcd(an, ad);
    final distractors = <String>[
      '${an + da}/${ad + db}', '${an - da}/${ad - db}', '${an + da}/${ad - db}',
    ];
    return _fractionQ('fraction', '$prompt, ?', an ~/ g, ad ~/ g, distractors,
        '分子等差 $da，分母等差 $db');
  }

  // ---------- 机械划分 ----------
  static Question _mechanical(Random rng) {
    if (rng.nextBool()) {
      // two-digit parts: tens follow arithmetic, units follow geometric
      final x1 = _ri(rng, 1, 4);
      final dx = _ri(rng, 1, 2);
      final y1 = _ri(rng, 2, 3);
      final q = 2;
      final terms = List.generate(8, (i) {
        final x = x1 + i * dx;
        final y = y1 * pow(q, i).toInt();
        return int.parse('$x$y');
      });
      return _q('mechanical', terms, terms.last,
          [int.parse('${x1 + 7 * dx}${y1 * pow(q, 8).toInt()}'),
            terms.last + 1, terms.last - 1],
          '机械划分：拆成两段，前段等差 $dx，后段等比 $q');
    }
    // two-digit parts: both arithmetic
    final x1 = _ri(rng, 1, 4);
    final dx = _ri(rng, 1, 2);
    final y1 = _ri(rng, 2, 5);
    final dy = _ri(rng, 2, 4);
    final terms = List.generate(8, (i) {
      final x = x1 + i * dx;
      final y = y1 + i * dy;
      return int.parse('$x$y');
    });
    return _q('mechanical', terms, terms.last,
        [int.parse('${x1 + 7 * dx + dx}${y1 + 7 * dy}'),
          int.parse('${x1 + 7 * dx}${y1 + 7 * dy + dy}'), terms.last - 1],
        '机械划分：拆成两段，前段等差 $dx，后段等差 $dy');
  }

  // ---------- 多重数列 ----------
  static Question _multiple(Random rng) {
    final oddD = _ri(rng, 2, 4);
    final evenD = _ri(rng, 3, 6);
    final o1 = _ri(rng, 1, 6);
    final e1 = _ri(rng, 2, 8);
    final seq = List.generate(8, (i) {
      if (i.isEven) return o1 + (i ~/ 2) * oddD;
      return e1 + ((i - 1) ~/ 2) * evenD;
    });
    return _q('multiple', seq, seq.last,
        [seq.last + evenD, seq.last - evenD, seq.last + oddD],
        '多重数列：奇数项等差 $oddD，偶数项等差 $evenD');
  }

  // ---------- 图形数列（九宫格） ----------
  static Question _graph(Random rng) {
    // 3x3 grid, middle cell of each row = left op right.
    final mul = rng.nextBool();
    final rows = List.generate(2, (_) {
      final l = _ri(rng, 1, 9);
      final r = _ri(rng, 1, 9);
      return [l, mul ? l * r : l + r, r];
    });
    final l3 = _ri(rng, 1, 9);
    final r3 = _ri(rng, 1, 9);
    final answer = mul ? l3 * r3 : l3 + r3;
    final grid = [...rows, [l3, null, r3]];
    final text = '${grid[0].join(' | ')}\n${grid[1].join(' | ')}\n${grid[2]
        .map((e) => e?.toString() ?? '?')
        .join(' | ')}';
    final expl = mul ? '每行中间 = 左 × 右' : '每行中间 = 左 + 右';
    return _qOpts('graph', text, answer, [answer + 1, answer - 1, answer + 5],
        expl);
  }

  // ---------- 周期数列 ----------
  static Question _periodic(Random rng) {
    final len = _ri(rng, 3, 4);
    final d = _ri(rng, 2, 5);
    final a1 = _ri(rng, 1, 4);
    // block: arithmetic segment of length len
    final block = List.generate(len, (i) => a1 + i * d);
    final seq = List.generate(8, (i) => block[i % len]);
    final answer = block[(8 - 1) % len];
    final wrong = <int>{answer + d, answer - d, a1, answer + 1};
    return _q('periodic', seq, answer, wrong.toList(),
        '周期数列：每 $len 项一循环，段内等差 $d');
  }
}

class SeqType {
  final String id;
  final String name;
  final String subtitle;

  const SeqType(this.id, this.name, this.subtitle);
}
