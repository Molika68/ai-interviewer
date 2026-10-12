/// 本地持久化：用户设置与面试历史记录。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/interview.dart';

/// 面试引擎模式。
enum EngineMode {
  /// 离线题库 + 规则评分，无需网络
  offline('offline', '离线体验'),
  /// 直连大模型（用户自带 API Key）
  ai('ai', 'AI 模式'),
  /// 连接自建 NestJS 后端
  server('server', '服务端模式');

  const EngineMode(this.value, this.label);

  final String value;
  final String label;

  static EngineMode fromValue(String? value) => EngineMode.values.firstWhere(
        (e) => e.value == value,
        orElse: () => EngineMode.offline,
      );
}

/// 应用设置。
class AppSettings {
  const AppSettings({
    this.mode = EngineMode.offline,
    this.apiKey = '',
    this.serverBaseUrl = '',
    this.defaultPosition = '前端开发工程师',
    this.defaultSkills = const <String>['JavaScript', 'Vue', 'React'],
  });

  final EngineMode mode;
  final String apiKey;
  final String serverBaseUrl;
  final String defaultPosition;
  final List<String> defaultSkills;

  AppSettings copyWith({
    EngineMode? mode,
    String? apiKey,
    String? serverBaseUrl,
    String? defaultPosition,
    List<String>? defaultSkills,
  }) =>
      AppSettings(
        mode: mode ?? this.mode,
        apiKey: apiKey ?? this.apiKey,
        serverBaseUrl: serverBaseUrl ?? this.serverBaseUrl,
        defaultPosition: defaultPosition ?? this.defaultPosition,
        defaultSkills: defaultSkills ?? this.defaultSkills,
      );
}

/// 设置与历史的读写封装。
class AppStorage {
  AppStorage._();

  static const String _kMode = 'settings.mode';
  static const String _kApiKey = 'settings.apiKey';
  static const String _kServer = 'settings.serverBaseUrl';
  static const String _kPosition = 'settings.defaultPosition';
  static const String _kSkills = 'settings.defaultSkills';
  static const String _kHistory = 'history.items';
  static const int _kMaxHistory = 30;

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<AppSettings> loadSettings() async {
    final prefs = await _prefs;
    final skills = prefs.getString(_kSkills);
    return AppSettings(
      mode: EngineMode.fromValue(prefs.getString(_kMode)),
      apiKey: prefs.getString(_kApiKey) ?? '',
      serverBaseUrl: prefs.getString(_kServer) ?? '',
      defaultPosition: prefs.getString(_kPosition) ?? '前端开发工程师',
      defaultSkills: skills == null || skills.isEmpty
          ? const <String>['JavaScript', 'Vue', 'React']
          : (jsonDecode(skills) as List<dynamic>)
              .map((e) => e.toString())
              .toList(),
    );
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _prefs;
    await Future.wait(<Future<void>>[
      prefs.setString(_kMode, settings.mode.value),
      prefs.setString(_kApiKey, settings.apiKey),
      prefs.setString(_kServer, settings.serverBaseUrl),
      prefs.setString(_kPosition, settings.defaultPosition),
      prefs.setString(_kSkills, jsonEncode(settings.defaultSkills)),
    ]);
  }

  /// 读取历史记录，最新的排在前面。
  static Future<List<InterviewResult>> loadHistory() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kHistory);
    if (raw == null || raw.isEmpty) return const <InterviewResult>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => InterviewResult.fromJson(e as Map<String, dynamic>? ?? const <String, dynamic>{}),
          )
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return const <InterviewResult>[];
    }
  }

  /// 追加一条历史记录（最多保留 30 条）。
  static Future<void> appendHistory(InterviewResult result) async {
    final prefs = await _prefs;
    final current = await loadHistory();
    final next = <InterviewResult>[result, ...current];
    if (next.length > _kMaxHistory) {
      next.removeRange(_kMaxHistory, next.length);
    }
    await prefs.setString(
      _kHistory,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clearHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_kHistory);
  }
}
