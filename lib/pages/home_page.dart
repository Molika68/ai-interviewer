/// 首页：选择岗位与技术栈，开始一场模拟面试。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/interview_controller.dart';
import '../providers/settings_controller.dart';
import '../services/storage_service.dart';
import 'history_page.dart';
import 'interview_page.dart';
import 'settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController _positionController;
  late final TextEditingController _skillsController;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _positionController = TextEditingController();
    _skillsController = TextEditingController();
  }

  @override
  void dispose() {
    _positionController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  List<String> get _skills => _skillsController.text
      .split(RegExp(r'[,，、\s]+'))
      .where((e) => e.trim().isNotEmpty)
      .toList();

  Future<void> _startInterview() async {
    FocusScope.of(context).unfocus();
    final position = _positionController.text.trim().isEmpty
        ? '前端开发工程师'
        : _positionController.text.trim();
    final skills = _skills;

    await ref
        .read(interviewControllerProvider.notifier)
        .start(position: position, skills: skills);

    if (!mounted) return;
    final state = ref.read(interviewControllerProvider);
    if (state.phase == InterviewPhase.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? '启动失败')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const InterviewPage()),
    );
    if (mounted) {
      ref.read(interviewControllerProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final interview = ref.watch(interviewControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_filled && settings.defaultPosition.isNotEmpty) {
      _positionController.text = settings.defaultPosition;
      _skillsController.text = settings.defaultSkills.join('、');
      _filled = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 面试官'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: '历史记录',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: '设置',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: <Widget>[
            _ModeBanner(mode: settings.mode),
            const SizedBox(height: 18),
            Text(
              '模拟真实技术面试',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '填写目标岗位与擅长的技术栈，AI 将连续追问 5 道题，'
              '每道题给出技术深度、表达能力、项目经验三个维度的评分与改进建议。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: '目标岗位',
                hintText: '例如：高级前端开发工程师',
                prefixIcon: Icon(Icons.work_outline_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _skillsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '技术栈（用空格或顿号分隔）',
                hintText: 'JavaScript、Vue、React、Node.js',
                prefixIcon: Icon(Icons.code_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: interview.isBusy ? null : _startInterview,
              icon: interview.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(interview.isBusy ? '正在出题…' : '开始面试'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
              ),
              icon: const Icon(Icons.history_rounded),
              label: const Text('查看历史成绩'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),
            _TipsCard(mode: settings.mode),
          ],
        ),
      ),
    );
  }
}

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({required this.mode});

  final EngineMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOffline = mode == EngineMode.offline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOffline
            ? colorScheme.secondaryContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isOffline ? Icons.offline_bolt_rounded : Icons.auto_awesome_rounded,
            size: 20,
            color: isOffline
                ? colorScheme.onSecondaryContainer
                : colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOffline
                  ? '当前为离线体验模式：内置题库，无需联网'
                  : '当前为 AI 模式：需要有效的 API Key',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isOffline
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.mode});

  final EngineMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '答题小贴士',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '· 按「原理 → 实践 → 数据」的结构作答，例如说明优化前后的具体指标\n'
              '· 每道题建议 150 字以上，越具体得分越高\n'
              '· 离线模式由规则引擎评分，开启 AI 模式可获得大模型实时追问',
              style: TextStyle(height: 1.6),
            ),
            if (mode == EngineMode.offline) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                '想体验真实大模型追问？在设置里填 DeepSeek API Key 即可切换 AI 模式。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
