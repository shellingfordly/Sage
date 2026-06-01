import 'package:flutter/material.dart';

import '../../theme/app_styles.dart';
import '../../theme/app_text_styles.dart';
import '../models/ai_insight_models.dart';
import '../services/ai_insight_explainer.dart';

Future<void> showAiQaSheet(
  BuildContext context, {
  required AiInsightSnapshot snapshot,
  required AiInsightExplainer explainer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AiQaSheet(snapshot: snapshot, explainer: explainer),
  );
}

class _AiQaSheet extends StatefulWidget {
  const _AiQaSheet({required this.snapshot, required this.explainer});

  final AiInsightSnapshot snapshot;
  final AiInsightExplainer explainer;

  @override
  State<_AiQaSheet> createState() => _AiQaSheetState();
}

class _AiQaSheetState extends State<_AiQaSheet> {
  AiInsightAnswer? _selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI 问答', style: AppTextStyles.sectionTitle(context)),
              const SizedBox(height: 6),
              Text(
                '选择一个问题，基于当前账单快照给出建议',
                style: AppTextStyles.bodyMuted(context),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final question in AiInsightExplainer.defaultQuestions)
                    ActionChip(
                      label: Text(question.label),
                      onPressed: () {
                        setState(() {
                          _selected = widget.explainer.answer(
                            questionId: question.id,
                            snapshot: widget.snapshot,
                          );
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_selected != null) _AnswerCard(answer: _selected!),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer});

  final AiInsightAnswer answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer.title, style: AppTextStyles.bodyStrong(context)),
          const SizedBox(height: 8),
          Text(answer.summary, style: AppTextStyles.bodyMuted(context)),
          if (answer.suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final suggestion in answer.suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $suggestion',
                  style: AppTextStyles.bodyMuted(context),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
