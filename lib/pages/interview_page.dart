/// 面试进行页：展示题目、收集回答、显示上一题反馈。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interview.dart';
import '../providers/interview_controller.dart';
import '../providers/settings_controller.dart';
import 'result_page.dart';

class InterviewPage extends ConsumerStatefulWidget {
  const InterviewPage({super.key});

  @override
  ConsumerState<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends ConsumerState<InterviewPage> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入你的回答')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(interviewControllerProvider.notifier).submitAnswer(text);
    if (!mounted) return;
    _answerController.clear();

    final state = ref.read(interviewControllerProvider);
    if (state.phase == InterviewPhase.finished && state.result != null) {
      ref.invalidate(historyProvider);
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(result: state.result!),
        ),
      );
    }
  }

  Future<void> _finishEarly() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('结束面试？'),
            content: const Text('将根据已完成的题目生成评分报告。'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('继续答题'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('生成报告'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await ref.read(interviewControllerProvider.notifier).finishEarly();
    if (!mounted) return;
    final state = ref.read(interviewControllerProvider);
    if (state.result != null) {
      ref.invalidate(historyProvider);
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(result: state.result!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope<Object?>(
      canPop: state.phase != InterviewPhase.evaluating,
      child: Scaffold(
        appBar: AppBar(
          title: Text('第 ${state.round} / ${state.totalRounds} 题'),
          actions: <Widget>[
            TextButton(
              onPressed: state.turns.isEmpty ? null : _finishEarly,
              child: const Text('结束'),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              LinearProgressIndicator(
                value: state.totalRounds == 0
                    ? 0
                    : (state.round - 1) / state.totalRounds,
                minHeight: 3,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: <Widget>[
                    if (state.error != null) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          state.error!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (state.lastEvaluation != null)
                      _FeedbackCard(evaluation: state.lastEvaluation!),
                    _QuestionCard(
                      question: state.question?.text ?? '',
                      streaming: state.streamingText,
                      loading: state.phase == InterviewPhase.starting ||
                          state.phase == InterviewPhase.evaluating,
                      techSkills: state.question?.techSkills ?? const <String>[],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _answerController,
                      maxLines: 4,
                      minLines: 2,
                      enabled: !state.isBusy,
                      decoration: const InputDecoration(
                        hintText: '输入你的回答，尽量给出原理和实际经验…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: state.isBusy ? null : _submit,
                        icon: state.isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(state.isBusy ? '正在评分…' : '提交回答'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.streaming,
    required this.loading,
    required this.techSkills,
  });

  final String question;
  final String streaming;
  final bool loading;
  final List<String> techSkills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayText = question.isEmpty ? streaming : question;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.record_voice_over_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '面试官提问',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                displayText.isEmpty ? '正在生成题目…' : displayText,
                key: ValueKey<String>(displayText),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
            if (techSkills.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: techSkills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.evaluation});

  final AnswerEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '上一题反馈 · 综合 ${evaluation.average.toStringAsFixed(1)} 分',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _MiniScore(
                  label: '技术',
                  value: evaluation.technicalScore,
                ),
                _MiniScore(
                  label: '表达',
                  value: evaluation.communicationScore,
                ),
                _MiniScore(
                  label: '经验',
                  value: evaluation.experienceScore,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              evaluation.feedback,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = value >= 80
        ? Colors.green
        : value >= 60
            ? colorScheme.primary
            : Colors.orange;
    return Column(
      children: <Widget>[
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
