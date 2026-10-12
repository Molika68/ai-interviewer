/// 设置页：切换面试引擎、配置 API Key 与默认岗位。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_controller.dart';
import '../services/storage_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _serverController;
  late final TextEditingController _positionController;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _serverController = TextEditingController();
    _positionController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _serverController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    if (!_filled) {
      _apiKeyController.text = settings.apiKey;
      _serverController.text = settings.serverBaseUrl;
      _positionController.text = settings.defaultPosition;
      _filled = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: <Widget>[
            Text(
              '面试引擎',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...EngineMode.values.map(
              (mode) => RadioListTile<EngineMode>(
                value: mode,
                groupValue: settings.mode,
                title: Text(mode.label),
                subtitle: Text(_modeDescription(mode)),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).setMode(value);
                  }
                },
              ),
            ),
            const Divider(height: 32),
            if (settings.mode == EngineMode.ai) ...<Widget>[
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'DeepSeek API Key',
                  hintText: 'sk-xxxxxxxx',
                  prefixIcon: Icon(Icons.key_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).setApiKey(value),
              ),
              const SizedBox(height: 8),
              Text(
                'Key 仅保存在本机，不会上传到任何第三方。DeepSeek 新用户有免费额度，'
                '可在 platform.deepseek.com 申请。',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (settings.mode == EngineMode.server) ...<Widget>[
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: '后端服务地址',
                  hintText: 'https://your-server.onrender.com',
                  prefixIcon: Icon(Icons.dns_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).setServerBaseUrl(value),
              ),
              const SizedBox(height: 8),
              Text(
                '服务端模式需要你已部署 NestJS 后端。未部署时请改用离线或 AI 模式。',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: '默认目标岗位',
                prefixIcon: Icon(Icons.work_outline_rounded),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => ref
                  .read(settingsProvider.notifier)
                  .setDefaultPosition(value),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(historyProvider.notifier).clearAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('历史记录已清空')),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('清空历史记录'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '关于',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'AI 面试官 · 移动端\n'
                      'Flutter 跨端实现，支持 Android 与 iOS。\n'
                      '内置离线题库引擎，可直连大模型获得实时追问与评分。',
                      style: TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _modeDescription(EngineMode mode) => switch (mode) {
        EngineMode.offline => '内置 30 道题库，规则引擎评分，无需联网',
        EngineMode.ai => '直连 DeepSeek，实时生成题目与个性化反馈',
        EngineMode.server => '连接自建 NestJS 后端（需已部署）',
      };
}
