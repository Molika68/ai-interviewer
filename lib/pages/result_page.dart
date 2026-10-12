/// 面试结果报告页。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interview.dart';
import '../providers/interview_controller.dart';
import '../providers/settings_controller.dart';
import '../services/storage_service.dart';
import '../widgets/radar_chart.dart';

class ResultPage extends ConsumerWidget {
  const ResultPage({super.key, required this.result});

  final InterviewResult result;

  Color _levelColor(double score) => score >= 85
      ? Colors.green
      : score >= 70
          ? Colors.blue
          : score >= 60
              ? Colors.orange
              : Colors.redAccent;

  String _levelText(double score) => score >= 85
      ? '优秀'
      : score >= 70
          ? '良好'
          : score >= 60
              ? '合格'
              : '待提升';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overall = result.overall;

    final radarItems = <RadarItem>[
      RadarItem(label: '技术', value: result.technicalScore),
      RadarItem(label: '表达', value: result.communicationScore),
      RadarItem(label: '经验', value: result.experienceScore),
      ...result.skills
          .take(3)
          .map((s) => RadarItem(label: s.name, value: s.score)),
    ];

    return PopScope<Object?>(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('面试报告'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      Text(
                        result.position,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        overall.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w700,
                          color: _levelColor(overall),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(_levelText(overall)),
                        backgroundColor:
                            _levelColor(overall).withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          _ScoreColumn(
                            label: '技术深度',
                            value: result.technicalScore,
                          ),
                          _ScoreColumn(
                            label: '表达能力',
                            value: result.communicationScore,
                          ),
                          _ScoreColumn(
                            label: '项目经验',
                            value: result.experienceScore,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '能力雷达',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      RadarChart(
                        items: radarItems,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.summarize_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '综合评价',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.summary,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '逐题回顾',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...result.turns.asMap().entries.map(
                    (entry) => _TurnTile(
                      index: entry.key + 1,
                      turn: entry.value,
                    ),
                  ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  ref.read(interviewControllerProvider.notifier).reset();
                  ref.invalidate(historyProvider);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('返回首页'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '模式：${EngineMode.fromValue(result.mode).label}　'
                '时间：${_formatTime(result.createdAt)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) =>
      '${time.year}-${_pad(time.month)}-${_pad(time.day)} '
      '${_pad(time.hour)}:${_pad(time.minute)}';

  String _pad(int value) => value.toString().padLeft(2, '0');
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(
          value.toStringAsFixed(0),
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _TurnTile extends StatelessWidget {
  const _TurnTile({required this.index, required this.turn});

  final int index;
  final InterviewTurn turn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evaluation = turn.evaluation;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          '第 $index 题',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          turn.question.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: evaluation == null
            ? null
            : Text(
                evaluation.average.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '题目',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(turn.question.text),
                const SizedBox(height: 12),
                Text(
                  '你的回答',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  turn.answer.isEmpty ? '（未作答）' : turn.answer,
                  style: const TextStyle(height: 1.55),
                ),
                if (evaluation != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    '反馈',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evaluation.feedback,
                    style: const TextStyle(height: 1.55),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      _ChipScore('技术', evaluation.technicalScore),
                      _ChipScore('表达', evaluation.communicationScore),
                      _ChipScore('经验', evaluation.experienceScore),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipScore extends StatelessWidget {
  const _ChipScore(this.label, this.value);

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text('$label ${value.toStringAsFixed(0)}'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}
