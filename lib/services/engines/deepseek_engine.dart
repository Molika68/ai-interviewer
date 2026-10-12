/// 直连大模型的面试引擎（DeepSeek OpenAI 兼容接口）。
///
/// 题目采用 SSE 流式生成（打字机效果），评分采用 JSON 结构化输出，
/// 这样既保证交互体验，也保证评分字段可被结果页直接使用。
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/interview.dart';
import 'interview_engine.dart';

class DeepSeekEngine implements InterviewEngine {
  DeepSeekEngine({
    required String apiKey,
    this.model = 'deepseek-chat',
    this.baseUrl = 'https://api.deepseek.com/v1',
    this.onDelta,
  }) : _apiKey = apiKey;

  final String _apiKey;
  final String model;
  final String baseUrl;

  /// 流式回调，用于把逐字生成的文本推送到 UI。
  final void Function(String text)? onDelta;

  static const int _totalRounds = 5;

  @override
  String get modeValue => 'ai';

  int get totalRounds => _totalRounds;

  Dio get _dio => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 90),
          headers: <String, dynamic>{
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

  String _systemPrompt(String position, List<String> skills) =>
      '你是一位资深技术面试官，正在面试一位"$position"候选人。'
      '候选人熟悉的技术栈：${skills.isEmpty ? '未指定' : skills.join('、')}。'
      '你要提出有区分度的技术问题，聚焦原理理解、工程实践与权衡判断，避免空泛的概念背诵题。'
      '每次只问一道题，语言用中文，表述简洁专业。';

  @override
  Future<InterviewQuestion> firstQuestion({
    required String position,
    required List<String> skills,
  }) async {
    final text = await _streamChat(
      messages: <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'system',
          'content': _systemPrompt(position, skills),
        },
        <String, dynamic>{
          'role': 'user',
          'content': '请出第 1 道面试题（共 $_totalRounds 道），直接给出题目正文，不要加序号和多余说明。',
        },
      ],
    );
    return InterviewQuestion(
      id: 'ai-1',
      text: text.trim(),
      techSkills: skills,
    );
  }

  @override
  Future<AnswerOutcome> submitAnswer({
    required InterviewQuestion question,
    required String answer,
    required int round,
    required int totalRounds,
  }) async {
    // 1) 结构化评分
    final evaluation = await _evaluateAnswer(
      question: question.text,
      answer: answer,
      skills: question.techSkills,
    );

    // 2) 还有题目则流式生成下一道
    if (round >= totalRounds) {
      return AnswerOutcome(evaluation: evaluation, finished: true);
    }
    final nextText = await _streamChat(
      messages: <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'system',
          'content': _systemPrompt('候选人', question.techSkills),
        },
        <String, dynamic>{
          'role': 'user',
          'content':
              '刚才的问题：${question.text}\n候选人的回答：${answer.isEmpty ? '(未作答)' : answer}\n'
                  '请出第 ${round + 1} 道面试题（共 $totalRounds 道）。'
                  '如果候选人回答明显偏浅，可以就同一方向追问得更具体；否则换一个新的考察点。'
                  '直接给出题目正文，不要加序号和多余说明。',
        },
      ],
    );

    return AnswerOutcome(
      evaluation: evaluation,
      nextQuestion: InterviewQuestion(
        id: 'ai-${round + 1}',
        text: nextText.trim(),
        techSkills: question.techSkills,
      ),
      finished: false,
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

    final technical =
        avg(scored.map((t) => t.evaluation!.technicalScore).toList());
    final communication =
        avg(scored.map((t) => t.evaluation!.communicationScore).toList());
    final experience =
        avg(scored.map((t) => t.evaluation!.experienceScore).toList());

    final summary = await _generateSummary(turns, position);
    final skills = _collectSkills(scored);

    return InterviewResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      mode: modeValue,
      position: position,
      technicalScore: technical,
      communicationScore: communication,
      experienceScore: experience,
      summary: summary,
      skills: skills,
      turns: turns,
    );
  }

  /// 流式对话：逐字回调，返回完整文本。
  Future<String> _streamChat({
    required List<Map<String, dynamic>> messages,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/chat/completions',
        data: <String, dynamic>{
          'model': model,
          'messages': messages,
          'stream': true,
          'temperature': 0.8,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final body = response.data;
      if (body is ResponseBody) {
        final buffer = StringBuffer();
        await for (final line in body.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
          final payload = trimmed.substring(5).trim();
          if (payload == '[DONE]') break;
          try {
            final json =
                jsonDecode(payload) as Map<String, dynamic>? ?? const <String, dynamic>{};
            final choices = json['choices'] as List<dynamic>? ?? const <dynamic>[];
            if (choices.isEmpty) continue;
            final delta = (choices.first as Map<String, dynamic>)['delta']
                    as Map<String, dynamic>? ??
                const <String, dynamic>{};
            final piece = delta['content']?.toString() ?? '';
            if (piece.isEmpty) continue;
            buffer.write(piece);
            onDelta?.call(piece);
          } catch (_) {
            // 忽略无法解析的心跳包
          }
        }
        if (buffer.isNotEmpty) return buffer.toString();
      }
    } catch (_) {
      // 流式失败时降级为非流式，保证流程不中断
    }
    return _chat(messages: messages);
  }

  /// 非流式对话。
  Future<String> _chat({
    required List<Map<String, dynamic>> messages,
    bool jsonMode = false,
  }) async {
    final response = await _dio.post<dynamic>(
      '/chat/completions',
      data: <String, dynamic>{
        'model': model,
        'messages': messages,
        'stream': false,
        if (jsonMode) 'response_format': <String, String>{'type': 'json_object'},
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final choices = data['choices'] as List<dynamic>? ?? const <dynamic>[];
      if (choices.isEmpty) return '';
      final message = (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>? ??
          const <String, dynamic>{};
      return message['content']?.toString() ?? '';
    }
    return '';
  }

  /// 结构化评分：要求模型输出 JSON。
  Future<AnswerEvaluation> _evaluateAnswer({
    required String question,
    required String answer,
    required List<String> skills,
  }) async {
    final prompt = '你是技术面试官，请对下面的回答打分。\n'
        '题目：$question\n'
        '回答：${answer.isEmpty ? '(候选人未作答)' : answer}\n'
        '相关技术栈：${skills.isEmpty ? '通用' : skills.join('、')}\n\n'
        '请严格输出如下 JSON（不要输出任何额外文字）：\n'
        '{"technicalScore":0-100的技术深度分,'
        '"communicationScore":0-100的表达清晰度分,'
        '"experienceScore":0-100的工程经验分,'
        '"techSkillScores":{"技术栈名":分数},'
        '"feedback":"150字左右的具体改进建议，指出答得好的点和缺失的点"}';

    String raw = '';
    try {
      raw = await _chat(
        messages: <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'system',
            'content': '你只输出 JSON，不要包含 markdown 代码块。',
          },
          <String, dynamic>{'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );
    } catch (_) {
      raw = '';
    }

    final parsed = _extractJson(raw);
    if (parsed == null) {
      return AnswerEvaluation(
        technicalScore: 60,
        communicationScore: 60,
        experienceScore: 60,
        feedback: '评分服务返回异常，已使用默认分。请检查 API Key 额度或网络后重试。',
        techSkillScores: const <String, double>{},
      );
    }

    double score(dynamic v) => (v as num?)?.toDouble().clamp(0, 100) ?? 60;
    final rawSkills = parsed['techSkillScores'];
    final skillMap = <String, double>{};
    if (rawSkills is Map) {
      rawSkills.forEach((key, value) {
        skillMap[key.toString()] = score(value);
      });
    }

    return AnswerEvaluation(
      technicalScore: score(parsed['technicalScore']),
      communicationScore: score(parsed['communicationScore']),
      experienceScore: score(parsed['experienceScore']),
      feedback: parsed['feedback']?.toString() ?? '暂无反馈',
      techSkillScores: skillMap,
    );
  }

  Future<String> _generateSummary(
    List<InterviewTurn> turns,
    String position,
  ) async {
    final digest = turns
        .asMap()
        .entries
        .map(
          (e) => '第${e.key + 1}题：${e.value.question.text}\n'
              '回答：${e.value.answer.isEmpty ? '(未作答)' : e.value.answer}\n'
              '评分：技术 ${e.value.evaluation?.technicalScore.toStringAsFixed(0) ?? '-'}'
              ' / 表达 ${e.value.evaluation?.communicationScore.toStringAsFixed(0) ?? '-'}'
              ' / 经验 ${e.value.evaluation?.experienceScore.toStringAsFixed(0) ?? '-'}',
        )
        .join('\n\n');

    try {
      return await _chat(
        messages: <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'system',
            'content': '你是资深技术面试官，输出中文，语气专业克制。',
          },
          <String, dynamic>{
            'role': 'user',
            'content': '岗位：$position\n下面是本次面试的问答记录：\n\n$digest\n\n'
                '请写一段 200-300 字的综合评价：指出候选人的优势、明显短板，'
                '并给出两条具体的提升建议。不要复述题目。',
          },
        ],
      );
    } catch (_) {
      return '综合评价生成失败，可查看下方逐题反馈。';
    }
  }

  List<SkillScore> _collectSkills(List<InterviewTurn> turns) {
    final map = <String, List<double>>{};
    for (final turn in turns) {
      turn.evaluation?.techSkillScores.forEach((skill, value) {
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

  /// 从模型输出中截取第一个完整的 JSON 对象。
  Map<String, dynamic>? _extractJson(String raw) {
    if (raw.isEmpty) return null;
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'```[a-zA-Z]*'), '').trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
