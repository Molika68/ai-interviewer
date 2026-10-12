/// 面试引擎的统一抽象。
///
/// 上层 UI 只依赖这个接口，因此离线题库、直连大模型、自建后端三种实现
/// 可以自由切换，互不干扰。
library;

import '../../models/interview.dart';

/// 提交一次回答后的结果：评分 + 下一题（或结束信号）。
class AnswerOutcome {
  const AnswerOutcome({
    required this.evaluation,
    this.nextQuestion,
    this.finished = false,
  });

  final AnswerEvaluation evaluation;
  final InterviewQuestion? nextQuestion;
  final bool finished;
}

abstract class InterviewEngine {
  /// 引擎标识，写入历史记录用于区分来源。
  String get modeValue;

  /// 生成第一道题。
  Future<InterviewQuestion> firstQuestion({
    required String position,
    required List<String> skills,
  });

  /// 提交回答，返回评分与后续题目。
  Future<AnswerOutcome> submitAnswer({
    required InterviewQuestion question,
    required String answer,
    required int round,
    required int totalRounds,
  });

  /// 汇总整场面试结果。
  Future<InterviewResult> complete({
    required List<InterviewTurn> turns,
    required String position,
  });
}
