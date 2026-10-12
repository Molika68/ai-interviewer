/// 历史记录页：查看过往面试报告。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interview.dart';
import '../providers/settings_controller.dart';
import '../services/storage_service.dart';
import 'result_page.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('清空历史记录？'),
            content: const Text('所有本地保存的面试报告将被删除，且无法恢复。'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确认清空'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await ref.read(historyProvider.notifier).clearAll();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '清空',
            onPressed: () => _confirmClear(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败：$error')),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.inbox_rounded,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 14),
                      const Text('还没有面试记录'),
                      const SizedBox(height: 6),
                      Text(
                        '完成一场模拟面试后，报告会自动保存在本地',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _HistoryTile(result: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result});

  final InterviewResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final score = result.overall;
    final color = score >= 85
        ? Colors.green
        : score >= 70
            ? colorScheme.primary
            : Colors.orange;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Text(
            score.toStringAsFixed(0),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 15,
            ),
          ),
        ),
        title: Text(result.position),
        subtitle: Text(
          '${_formatTime(result.createdAt)}　'
          '${EngineMode.fromValue(result.mode).label}　'
          '${result.turns.length} 题',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ResultPage(result: result),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) =>
      '${_pad(time.month)}-${_pad(time.day)} ${_pad(time.hour)}:${_pad(time.minute)}';

  String _pad(int value) => value.toString().padLeft(2, '0');
}
