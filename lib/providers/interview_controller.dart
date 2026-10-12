/// 面试流程控制器（Riverpod Notifier）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interview.dart';
import '../services/engines/deepseek_engine.dart';
import '../services/engines/interview_engine.dart';
import '../services/engines/local_engine.dart';
import '../services/storage_service.dart';
import 'settings_controller.dart';

/// 一场面试所处的阶段。
enum InterviewPhase {
  idle,
  starting,
  questioning,
  evaluating,
  finished,
  error,
}

class InterviewState {
  const InterviewState({
    this.phase = InterviewPhase.idle,
    this.question,
    this.round = 0,
    this.totalRounds = 5,
    this.turns = const <InterviewTurn>[],
    this.lastEvaluation,
    this.result,
    this.error,
    this.streamingText = '',
    this.position = '',
  });

  final InterviewPhase phase;
  final InterviewQuestion? question;
  final int round;
  final int totalRounds;
  final List<InterviewTurn> turns;
  final AnswerEvaluation? lastEvaluation;
  final InterviewResult? result;
  final String? error;
  /// AI 流式生成中的文本，用于打字机效果
  final String streamingText;
  final String position;

  bool get isBusy =>
      phase == InterviewPhase.starting || phase == InterviewPhase.evaluating;

  InterviewState copyWith({
    InterviewPhase? phase,
    InterviewQuestion? question,
    bool clearQuestion = false,
    int? round,
    int? totalRounds,
    List<InterviewTurn>? turns,
    AnswerEvaluation? lastEvaluation,
    bool clearEvaluation = false,
    InterviewResult? result,
    String? error,
    bool clearError = false,
    String? streamingText,
    String? position,
  }) =>
      InterviewState(
        phase: phase ?? this.phase,
        question: clearQuestion ? null : (question ?? this.question),
        round: round ?? this.round,
        totalRounds: totalRounds ?? this.totalRounds,
        turns: turns ?? this.turns,
        lastEvaluation:
            clearEvaluation ? null : (lastEvaluation ?? this.lastEvaluation),
        result: result ?? this.result,
        error: clearError ? null : (error ?? this.error),
        streamingText: streamingText ?? this.streamingText,
        position: position ?? this.position,
      );
}

class InterviewController extends Notifier<InterviewState> {
  InterviewEngine? _engine;

  @override
  InterviewState build() => const InterviewState();

  /// 按当前设置创建引擎；AI 模式缺少 Key 时自动降级为离线模式。
  InterviewEngine _buildEngine(AppSettings settings) {
    if (settings.mode == EngineMode.ai && settings.apiKey.trim().isNotEmpty) {
      return DeepSeekEngine(
        apiKey: settings.apiKey.trim(),
        onDelta: (text) {
          state = state.copyWith(
            streamingText: state.streamingText + text,
          );
        },
      );
    }
    return LocalEngine();
  }

  /// 开启一场新的面试。
  Future<void> start({
    required String position,
    required List<String> skills,
  }) async {
    final settings = ref.read(settingsProvider);
    _engine = _buildEngine(settings);
    state = state.copyWith(
      phase: InterviewPhase.starting,
      clearError: true,
      clearEvaluation: true,
      streamingText: '',
      round: 0,
      turns: const <InterviewTurn>[],
      result: null,
      position: position,
    );

    try {
      final first = await _engine!.firstQuestion(
        position: position,
        skills: skills,
      );
      state = state.copyWith(
        phase: InterviewPhase.questioning,
        question: first,
        round: 1,
        streamingText: '',
      );
    } catch (e) {
      state = state.copyWith(
        phase: InterviewPhase.error,
        error: '生成题目失败：$e',
      );
    }
  }

  /// 提交当前题目的回答。
  Future<void> submitAnswer(String answer) async {
    final question = state.question;
    if (question == null || _engine == null) return;

    state = state.copyWith(
      phase: InterviewPhase.evaluating,
      clearError: true,
      streamingText: '',
    );

    try {
      final outcome = await _engine!.submitAnswer(
        question: question,
        answer: answer,
        round: state.round,
        totalRounds: state.totalRounds,
      );

      final turns = <InterviewTurn>[
        ...state.turns,
        InterviewTurn(
          question: question,
          answer: answer,
          evaluation: outcome.evaluation,
        ),
      ];

      if (outcome.finished || outcome.nextQuestion == null) {
        final result = await _engine!.complete(
          turns: turns,
          position: state.position,
        );
        await AppStorage.appendHistory(result);
        state = state.copyWith(
          phase: InterviewPhase.finished,
          turns: turns,
          lastEvaluation: outcome.evaluation,
          result: result,
          clearQuestion: true,
        );
        return;
      }

      state = state.copyWith(
        phase: InterviewPhase.questioning,
        turns: turns,
        lastEvaluation: outcome.evaluation,
        question: outcome.nextQuestion,
        round: state.round + 1,
        streamingText: '',
      );
    } catch (e) {
      // 出错时保留已完成的轮次，允许用户重试或结束
      state = state.copyWith(
        phase: InterviewPhase.questioning,
        error: '评分失败：$e',
        streamingText: '',
      );
    }
  }

  /// 提前结束并生成结果。
  Future<void> finishEarly() async {
    if (_engine == null || state.turns.isEmpty) {
      state = const InterviewState();
      return;
    }
    state = state.copyWith(phase: InterviewPhase.evaluating, streamingText: '');
    try {
      final result = await _engine!.complete(
        turns: state.turns,
        position: state.position,
      );
      await AppStorage.appendHistory(result);
      state = state.copyWith(
        phase: InterviewPhase.finished,
        result: result,
        clearQuestion: true,
      );
    } catch (e) {
      state = state.copyWith(
        phase: InterviewPhase.error,
        error: '生成结果失败：$e',
      );
    }
  }

  void reset() {
    _engine = null;
    state = const InterviewState();
  }
}

final interviewControllerProvider =
    NotifierProvider<InterviewController, InterviewState>(
  InterviewController.new,
);
