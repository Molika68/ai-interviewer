/// 全局设置与历史记录的 Riverpod 控制器。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interview.dart';
import '../services/storage_service.dart';

/// 设置控制器：启动时异步读取本地配置。
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    // 先用默认值渲染界面，再异步加载真实配置
    Future<void>.microtask(_load);
    return const AppSettings();
  }

  Future<void> _load() async {
    state = await AppStorage.loadSettings();
  }

  Future<void> save(AppSettings next) async {
    state = next;
    await AppStorage.saveSettings(next);
  }

  Future<void> setMode(EngineMode mode) => save(state.copyWith(mode: mode));

  Future<void> setApiKey(String key) => save(state.copyWith(apiKey: key));

  Future<void> setServerBaseUrl(String url) =>
      save(state.copyWith(serverBaseUrl: url));

  Future<void> setDefaultPosition(String position) =>
      save(state.copyWith(defaultPosition: position));

  Future<void> setDefaultSkills(List<String> skills) =>
      save(state.copyWith(defaultSkills: skills));
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// 历史记录控制器。
class HistoryController extends AsyncNotifier<List<InterviewResult>> {
  @override
  Future<List<InterviewResult>> build() => AppStorage.loadHistory();

  Future<void> refresh() async {
    state = const AsyncLoading<List<InterviewResult>>();
    state = await AsyncValue.guard(AppStorage.loadHistory);
  }

  Future<void> clearAll() async {
    await AppStorage.clearHistory();
    state = const AsyncData<List<InterviewResult>>(<InterviewResult>[]);
  }
}

final historyProvider = AsyncNotifierProvider<HistoryController,
    List<InterviewResult>>(HistoryController.new);
