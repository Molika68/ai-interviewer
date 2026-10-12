import 'package:flutter_test/flutter_test.dart';

import 'package:ai_interviewer/models/interview.dart';
import 'package:ai_interviewer/services/engines/local_engine.dart';

void main() {
  test('离线引擎能完整跑完一场面试并产出报告', () async {
    final engine = LocalEngine();
    const position = '前端开发工程师';
    const skills = <String>['Vue', 'JavaScript'];

    final first = await engine.firstQuestion(
      position: position,
      skills: skills,
    );
    expect(first.text, isNotEmpty);
    expect(first.techSkills, isNotEmpty);

    final turns = <InterviewTurn>[];
    var current = first;
    const answer = 'Vue 2 使用 Object.defineProperty 劫持属性实现响应式，'
        'Vue 3 改用 Proxy。因为我在项目中做过性能优化，例如用 computed 缓存，'
        '首屏渲染时间从 1.2s 降到 0.6s，线上监控指标也有明显改善。';

    for (var round = 1; round <= 5; round++) {
      final outcome = await engine.submitAnswer(
        question: current,
        answer: answer,
        round: round,
        totalRounds: 5,
      );
      turns.add(
        InterviewTurn(
          question: current,
          answer: answer,
          evaluation: outcome.evaluation,
        ),
      );
      expect(outcome.evaluation.technicalScore, inInclusiveRange(0, 100));
      if (outcome.finished || outcome.nextQuestion == null) break;
      current = outcome.nextQuestion!;
    }

    final result = await engine.complete(turns: turns, position: position);
    expect(result.turns.length, greaterThanOrEqualTo(1));
    expect(result.overall, greaterThan(0));
    expect(result.summary, contains('综合得分'));
    expect(result.skills, isNotEmpty);
  });

  test('回答过于简略时得分明显低于详细回答', () async {
    final engine = LocalEngine();
    final question = await engine.firstQuestion(
      position: '前端开发工程师',
      skills: const <String>['Vue'],
    );

    final brief = await engine.submitAnswer(
      question: question,
      answer: '不知道',
      round: 1,
      totalRounds: 5,
    );

    final engine2 = LocalEngine();
    final question2 = await engine2.firstQuestion(
      position: '前端开发工程师',
      skills: const <String>['Vue'],
    );
    final detailed = await engine2.submitAnswer(
      question: question2,
      answer: 'Vue 2 用 Object.defineProperty 做依赖收集，Vue 3 用 Proxy 实现响应式。'
          '因为 Proxy 能拦截新增属性，所以在项目中我做过优化，例如用 shallowRef，'
          '线上首屏数据指标从 2s 降到 800ms，监控也验证了效果。',
      round: 1,
      totalRounds: 5,
    );

    expect(
      detailed.evaluation.technicalScore,
      greaterThan(brief.evaluation.technicalScore),
    );
  });
}
