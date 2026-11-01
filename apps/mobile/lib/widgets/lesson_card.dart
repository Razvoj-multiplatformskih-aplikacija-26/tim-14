import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../data/demo_data.dart';
import '../text/dates.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.lesson, this.onTap});

  final Lesson lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final professorName = professorNames[lesson.professorId] ?? 'Profesor';
    final listingTitle = listingTitles[lesson.listingId] ?? '';
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.px16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(name: professorName),
              const SizedBox(width: AppSpacing.px12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(professorName, style: AppTextStyles.bodyBaseMedium),
                    const SizedBox(height: AppSpacing.px2),
                    Text(listingTitle, style: AppTextStyles.bodySm.copyWith(color: mutedColor)),
                    const SizedBox(height: AppSpacing.px8),
                    Text(formatLessonTime(lesson.start), style: AppTextStyles.bodySm),
                    const SizedBox(height: AppSpacing.px8),
                    LessonStatusBadge(status: lesson.status),
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
