/// 离线面试引擎：内置题库 + 规则评分。
///
/// 不依赖网络，保证 App 安装后任何环境都能完整走完一场面试，
/// 这对于"下载即可体验"的分发场景是刚需。
library;

import 'dart:math';

import '../../data/question_bank.dart';
import '../../models/interview.dart';
import 'interview_engine.dart';

class LocalEngine implements InterviewEngine {
  LocalEngine({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<QuestionSeed> _pool = <QuestionSeed>[];
  final Map<String, QuestionSeed> _seedMap = <String, QuestionSeed>{};
  int _cursor = 0;

  static const int _totalRounds = 5;

  @override
  String get modeValue => 'offline';

  int get totalRounds => _totalRounds;

  @override
  Future<InterviewQuestion> firstQuestion({
    required String position,
    required List<String> skills,
  }) async {
    _pool
      ..clear()
      ..addAll(kQuestionBank);
    // 若用户填写了技术栈，优先出与之相关的题目
    if (skills.isNotEmpty) {
      final matched = kQuestionBank
          .where(
            (q) => q.techSkills.any(
              (t) => skills.any(
                (s) => s.toLowerCase().contains(t.toLowerCase()) ||
                    t.toLowerCase().contains(s.toLowerCase()),
              ),
            ),
          )
          .toList();
      final rest = kQuestionBank.where((q) => !matched.contains(q)).toList()
        ..shuffle(_random);
      matched.shuffle(_random);
      _pool
        ..clear()
        ..addAll(<QuestionSeed>[...matched, ...rest]);
    } else {
      _pool.shuffle(_random);
    }
    _cursor = 0;
    _seedMap.clear();
    return _nextQuestion();
  }

  InterviewQuestion _nextQuestion() {
    if (_cursor >= _pool.length) {
      return const InterviewQuestion(id: '', text: '', techSkills: <String>[]);
    }
    final seed = _pool[_cursor];
    final id = 'local-${_cursor + 1}';
    _seedMap[id] = seed;
    return InterviewQuestion(
      id: id,
      text: seed.text,
      techSkills: seed.techSkills,
    );
  }

  @override
  Future<AnswerOutcome> submitAnswer({
    required InterviewQuestion question,
    required String answer,
    required int round,
    required int totalRounds,
  }) async {
    final seed = _seedMap[question.id];
    final evaluation = _evaluate(seed, answer);
    _cursor++;

    final hasNext = _cursor < _pool.length && round < totalRounds;
    return AnswerOutcome(
      evaluation: evaluation,
      nextQuestion: hasNext ? _nextQuestion() : null,
      finished: !hasNext,
    );
  }

  @override
  Future<InterviewResult> complete({
    required List<InterviewTurn> turns,
    required String position,
  }) async {
    final scored = turns.where((t) => t.evaluation != null).toList();
    double avg(List<double> values) =>
        values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

    final technical = avg(
      scored.map((t) => t.evaluation!.technicalScore).toList(),
    );
    final communication = avg(
      scored.map((t) => t.evaluation!.communicationScore).toList(),
    );
    final experience = avg(
      scored.map((t) => t.evaluation!.experienceScore).toList(),
    );

    return InterviewResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      mode: modeValue,
      position: position,
      technicalScore: technical,
      communicationScore: communication,
      experienceScore: experience,
      summary: _buildSummary(technical, communication, experience, turns.length),
      skills: _buildSkills(scored),
      turns: turns,
    );
  }

  /// 规则评分：关键词命中 + 回答长度 + 表达结构 + 实践细节。
  AnswerEvaluation _evaluate(QuestionSeed? seed, String rawAnswer) {
    final text = rawAnswer.trim();
    final lower = text.toLowerCase();

    final keywords = seed?.keywords ?? const <String>[];
    final hits = keywords
        .where((k) => lower.contains(k.toLowerCase()))
        .toList(growable: false);
    final keywordRatio =
        keywords.isEmpty ? 0.0 : hits.length / keywords.length;

    final lengthScore = (text.length / 180).clamp(0.0, 1.0);

    const structureWords = <String>[
      '例如',
      '比如',
      '因为',
      '所以',
      '首先',
      '其次',
      '最后',
      '总结',
      '方案',
      '指标',
      '结果',
      '流程',
    ];
    final structureHits =
        structureWords.where((w) => text.contains(w)).length;
    final structureScore = (structureHits / 4).clamp(0.0, 1.0);

    const practiceWords = <String>[
      '项目',
      '线上',
      '排查',
      '性能',
      '优化',
      '重构',
      '上线',
      '数据',
      '监控',
      '灰度',
      '缓存',
    ];
    final practiceHits = practiceWords.where((w) => text.contains(w)).length;
    final practiceScore = (practiceHits / 3).clamp(0.0, 1.0);

    double clampScore(double value) => (30 + value * 0.65 * 100).clamp(30, 95);

    final technical = clampScore(
      keywordRatio * 0.6 + lengthScore * 0.15 + structureScore * 0.25,
    );
    final communication = clampScore(lengthScore * 0.5 + structureScore * 0.5);
    final experience = clampScore(
      practiceScore * 0.6 + keywordRatio * 0.2 + lengthScore * 0.2,
    );

    final techSkillScores = <String, double>{};
    for (final skill in seed?.techSkills ?? const <String>[]) {
      techSkillScores[skill] = (technical + (hits.length - 2) * 2).clamp(30, 95);
    }

    return AnswerEvaluation(
      technicalScore: technical,
      communicationScore: communication,
      experienceScore: experience,
      feedback: _buildFeedback(
        seed: seed,
        hits: hits,
        keywords: keywords,
        textLength: text.length,
        average: (technical + communication + experience) / 3,
      ),
      techSkillScores: techSkillScores,
    );
  }

  String _buildFeedback({
    required QuestionSeed? seed,
    required List<String> hits,
    required List<String> keywords,
    required int textLength,
    required double average,
  }) {
    final buffer = StringBuffer();
    if (average >= 80) {
      buffer.writeln('整体回答质量较高，关键点覆盖完整。');
    } else if (average >= 60) {
      buffer.writeln('基本答到了方向，但深度和细节还可以再补充。');
    } else {
      buffer.writeln('回答偏简略，建议按"原理 → 实践 → 数据"的结构展开。');
    }

    if (hits.isNotEmpty) {
      buffer.writeln('\n已覆盖要点：${hits.join('、')}');
    }
    final missed = keywords.where((k) => !hits.contains(k)).toList();
    if (missed.isNotEmpty) {
      buffer.writeln('建议补充：${missed.take(4).join('、')}');
    }
    if (textLength < 60) {
      buffer.writeln('回答字数偏少（$textLength 字），面试场景建议展开到 150 字以上。');
    }
    if (seed != null) {
      buffer.writeln('\n参考答案要点：\n${seed.reference}');
    }
    return buffer.toString().trim();
  }

  String _buildSummary(
    double technical,
    double communication,
    double experience,
    int total,
  ) {
    final overall = (technical + communication + experience) / 3;
    final level = overall >= 85
        ? '表现优秀，具备较强的工程能力与表达逻辑'
        : overall >= 70
            ? '整体合格，部分方向还可以进一步深入'
            : '基础尚需巩固，建议围绕薄弱维度做针对性练习';
    return '本场共完成 $total 道题，综合得分 ${overall.toStringAsFixed(1)} 分。$level。'
        '\n\n技术深度 ${technical.toStringAsFixed(1)}｜'
        '表达能力 ${communication.toStringAsFixed(1)}｜'
        '项目经验 ${experience.toStringAsFixed(1)}。'
        '\n\n（离线模式由本地题库与规则引擎评分，开启 AI 模式可获得大模型实时追问与更有针对性的反馈。）';
  }

  List<SkillScore> _buildSkills(List<InterviewTurn> turns) {
    final map = <String, List<double>>{};
    for (final turn in turns) {
      final scores = turn.evaluation?.techSkillScores ?? const <String, double>{};
      scores.forEach((skill, value) {
        map.putIfAbsent(skill, () => <double>[]).add(value);
      });
    }
    return map.entries
        .map(
          (e) => SkillScore(
            name: e.key,
            score: e.value.reduce((a, b) => a + b) / e.value.length,
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }
}
