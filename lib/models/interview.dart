/// 面试业务的数据模型。
///
/// 字段结构与 NestJS 后端接口保持一致，这样本地引擎、DeepSeek 直连引擎和
/// 服务端引擎可以互相替换，上层 UI 不需要关心题目从哪来。
library;

/// 单个技术栈维度的得分，用于结果页雷达图。
class SkillScore {
  const SkillScore({required this.name, required this.score});

  final String name;
  final double score;

  factory SkillScore.fromJson(Map<String, dynamic> json) => SkillScore(
        name: json['name'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {'name': name, 'score': score};
}

/// 一道面试题。
class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.text,
    this.techSkills = const <String>[],
  });

  final String id;
  final String text;
  final List<String> techSkills;

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) =>
      InterviewQuestion(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        techSkills: (json['techSkills'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'text': text, 'techSkills': techSkills};
}

/// 单次回答的评分结果。
class AnswerEvaluation {
  const AnswerEvaluation({
    required this.technicalScore,
    required this.communicationScore,
    required this.experienceScore,
    required this.feedback,
    this.techSkillScores = const <String, double>{},
  });

  final double technicalScore;
  final double communicationScore;
  final double experienceScore;
  final String feedback;
  final Map<String, double> techSkillScores;

  double get average =>
      (technicalScore + communicationScore + experienceScore) / 3;

  factory AnswerEvaluation.fromJson(Map<String, dynamic> json) =>
      AnswerEvaluation(
        technicalScore: (json['technicalScore'] as num?)?.toDouble() ?? 0,
        communicationScore:
            (json['communicationScore'] as num?)?.toDouble() ?? 0,
        experienceScore: (json['experienceScore'] as num?)?.toDouble() ?? 0,
        feedback: json['feedback'] as String? ?? '',
        techSkillScores: (json['techSkillScores'] as Map<String, dynamic>? ??
                const <String, dynamic>{})
            .map(
          (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
        ),
      );

  Map<String, dynamic> toJson() => {
        'technicalScore': technicalScore,
        'communicationScore': communicationScore,
        'experienceScore': experienceScore,
        'feedback': feedback,
        'techSkillScores': techSkillScores,
      };
}

/// 一轮完整问答（题目 + 回答 + 评分）。
class InterviewTurn {
  const InterviewTurn({
    required this.question,
    this.answer = '',
    this.evaluation,
  });

  final InterviewQuestion question;
  final String answer;
  final AnswerEvaluation? evaluation;

  factory InterviewTurn.fromJson(Map<String, dynamic> json) => InterviewTurn(
        question: InterviewQuestion.fromJson(
          json['question'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        ),
        answer: json['answer'] as String? ?? '',
        evaluation: json['evaluation'] == null
            ? null
            : AnswerEvaluation.fromJson(
                json['evaluation'] as Map<String, dynamic>,
              ),
      );

  Map<String, dynamic> toJson() => {
        'question': question.toJson(),
        'answer': answer,
        if (evaluation != null) 'evaluation': evaluation!.toJson(),
      };
}

/// 一场面试的最终结果。
class InterviewResult {
  const InterviewResult({
    required this.id,
    required this.createdAt,
    required this.mode,
    required this.position,
    required this.technicalScore,
    required this.communicationScore,
    required this.experienceScore,
    required this.summary,
    required this.skills,
    required this.turns,
  });

  final String id;
  final DateTime createdAt;
  /// 面试引擎模式：offline / ai / server
  final String mode;
  final String position;
  final double technicalScore;
  final double communicationScore;
  final double experienceScore;
  final String summary;
  final List<SkillScore> skills;
  final List<InterviewTurn> turns;

  double get overall =>
      (technicalScore + communicationScore + experienceScore) / 3;

  factory InterviewResult.fromJson(Map<String, dynamic> json) =>
      InterviewResult(
        id: json['id'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        mode: json['mode'] as String? ?? 'offline',
        position: json['position'] as String? ?? '',
        technicalScore: (json['technicalScore'] as num?)?.toDouble() ?? 0,
        communicationScore:
            (json['communicationScore'] as num?)?.toDouble() ?? 0,
        experienceScore: (json['experienceScore'] as num?)?.toDouble() ?? 0,
        summary: json['summary'] as String? ?? '',
        skills: (json['skills'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) => SkillScore.fromJson(e as Map<String, dynamic>? ?? const <String, dynamic>{}),
            )
            .toList(),
        turns: (json['turns'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) => InterviewTurn.fromJson(e as Map<String, dynamic>? ?? const <String, dynamic>{}),
            )
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'mode': mode,
        'position': position,
        'technicalScore': technicalScore,
        'communicationScore': communicationScore,
        'experienceScore': experienceScore,
        'summary': summary,
        'skills': skills.map((e) => e.toJson()).toList(),
        'turns': turns.map((e) => e.toJson()).toList(),
      };
}
