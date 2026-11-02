import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../text/catalog.dart';

class ProfessorCard extends StatelessWidget {
  const ProfessorCard({super.key, required this.professor, this.onTap});

  final ProfessorSummary professor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final profile = professor.profile;
    final listings = professor.listings;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    // Najnižu cenu računa ProfessorSummary, ovde je samo ispisujemo. Sa više oglasa piše "od".
    final lowestPrice = professor.lowestPrice;
    String? priceText;
    if (lowestPrice != null) {
      priceText = listings.length > 1 ? 'od ${formatPrice(lowestPrice)}' : formatPrice(lowestPrice);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.px16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(name: profile.fullName),
              const SizedBox(width: AppSpacing.px12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName, style: AppTextStyles.bodyBaseMedium),
                    const SizedBox(height: AppSpacing.px2),
                    Text(profile.city.label, style: AppTextStyles.bodySm.copyWith(color: mutedColor)),
                    if (profile.isVerified) ...[
                      const SizedBox(height: AppSpacing.px8),
                      const AppBadge(label: 'Diploma potvrđena', tone: BadgeTone.verified),
                    ],
                    for (final listing in listings) ...[
                      const SizedBox(height: AppSpacing.px8),
                      Text(listing.description, style: AppTextStyles.bodySm),
                    ],
                    if (priceText != null) ...[
                      const SizedBox(height: AppSpacing.px8),
                      Text(priceText, style: AppTextStyles.bodySmMedium),
                    ],
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
