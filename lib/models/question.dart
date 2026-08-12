import 'dart:convert';

/// A single generated exercise question shared by all three modules.
class Question {
  final String module; // 'calc' | 'data' | 'seq'
  final String typeId;
  final String typeName;
  final String prompt; // question stem, \n for line breaks
  final List<String>? options; // choice options (number sequence / compare)
  final String answerText; // exact answer shown to user
  final double? answerNum; // numeric answer used for tolerance checking
  final double tolerance; // relative error tolerance, 0 = exact match
  final String explanation;
  final Map<String, dynamic>? data; // extra payload (tables etc.)
  final bool compareMode; // render 大于/小于 buttons instead of A/B/C/D

  const Question({
    required this.module,
    required this.typeId,
    required this.typeName,
    required this.prompt,
    this.options,
    required this.answerText,
    this.answerNum,
    this.tolerance = 0,
    this.explanation = '',
    this.data,
    this.compareMode = false,
  });

  /// True when the user's typed answer is accepted.
  bool check(String userInput) {
    if (answerNum == null) return userInput.trim() == answerText;
    final parsed = double.tryParse(userInput.trim());
    if (parsed == null) return false;
    if (answerNum == 0) return parsed == 0;
    return (parsed - answerNum!).abs() / answerNum!.abs() <= tolerance;
  }

  Map<String, dynamic> toJson() => {
        'module': module,
        'typeId': typeId,
        'typeName': typeName,
        'prompt': prompt,
        'options': options == null ? null : jsonEncode(options),
        'answerText': answerText,
        'answerNum': answerNum,
        'tolerance': tolerance,
        'explanation': explanation,
        'data': data == null ? null : jsonEncode(data),
        'compareMode': compareMode,
      };

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        module: j['module'] as String,
        typeId: j['typeId'] as String,
        typeName: j['typeName'] as String,
        prompt: j['prompt'] as String,
        options: j['options'] == null
            ? null
            : (jsonDecode(j['options'] as String) as List).cast<String>(),
        answerText: j['answerText'] as String,
        answerNum: (j['answerNum'] as num?)?.toDouble(),
        tolerance: (j['tolerance'] as num?)?.toDouble() ?? 0,
        explanation: j['explanation'] as String? ?? '',
        data: j['data'] == null
            ? null
            : jsonDecode(j['data'] as String) as Map<String, dynamic>,
        compareMode: j['compareMode'] as bool? ?? false,
      );
}

/// One finished practice session (wrong-question book entry).
class WrongQuestion {
  final int? id;
  final Question question;
  final String userAnswer;
  final DateTime wrongAt;
  final int wrongCount;

  const WrongQuestion({
    this.id,
    required this.question,
    required this.userAnswer,
    required this.wrongAt,
    this.wrongCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': jsonEncode(question.toJson()),
        'userAnswer': userAnswer,
        'wrongAt': wrongAt.toIso8601String(),
        'wrongCount': wrongCount,
      };

  factory WrongQuestion.fromJson(Map<String, dynamic> j) => WrongQuestion(
        id: j['id'] as int?,
        question: Question.fromJson(
            jsonDecode(j['question'] as String) as Map<String, dynamic>),
        userAnswer: j['userAnswer'] as String,
        wrongAt: DateTime.parse(j['wrongAt'] as String),
        wrongCount: j['wrongCount'] as int? ?? 1,
      );
}

/// One finished practice session (history entry).
class PracticeRecord {
  final int? id;
  final String module;
  final String moduleName;
  final String typeId;
  final String typeName;
  final int total;
  final int correct;
  final int seconds;
  final DateTime doneAt;

  /// Per-question results: [{question, userAnswer, correct, seconds}].
  final List<Map<String, dynamic>>? details;

  const PracticeRecord({
    this.id,
    required this.module,
    required this.moduleName,
    required this.typeId,
    required this.typeName,
    required this.total,
    required this.correct,
    required this.seconds,
    required this.doneAt,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'module_name': moduleName,
        'type_id': typeId,
        'type_name': typeName,
        'total': total,
        'correct': correct,
        'seconds': seconds,
        'done_at': doneAt.toIso8601String(),
        'details': details == null ? null : jsonEncode(details),
      };

  factory PracticeRecord.fromJson(Map<String, dynamic> j) => PracticeRecord(
        id: j['id'] as int?,
        module: j['module'] as String,
        moduleName: j['module_name'] as String,
        typeId: j['type_id'] as String,
        typeName: j['type_name'] as String,
        total: j['total'] as int,
        correct: j['correct'] as int,
        seconds: j['seconds'] as int,
        doneAt: DateTime.parse(j['done_at'] as String),
        details: j['details'] == null
            ? null
            : (jsonDecode(j['details'] as String) as List)
                .cast<Map<String, dynamic>>(),
      );
}
