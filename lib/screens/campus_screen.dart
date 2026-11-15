import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'sheets.dart';

class CampusScreen extends StatelessWidget {
  const CampusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = DateTime.now();
    final facilities = app.facilities;
    final openCount =
        facilities.where((f) => f.liveAt(now) == LiveStatus.open).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        ScreenHeader(
          title: 'Campus',
          subtitle: '$openCount of ${facilities.length} services open now',
          trailing: app.perms.isAdmin
              ? GlassIconButton(
                  icon: Icons.add_business_rounded,
                  onTap: () => showCreateFacilitySheet(context),
                )
              : null,
        ),
        if (facilities.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.apartment_rounded,
              title: 'No campus areas yet',
              subtitle: 'A Super Admin can create areas from the Admin dashboard.',
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.98,
              ),
              itemCount: facilities.length,
              itemBuilder: (_, i) => FadeSlideIn(
                index: i,
                child: _FacilityCard(facility: facilities[i], now: now),
              ),
            ),
          ),
        const SectionHeader('Useful contacts'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final c in SeedData.contacts) ...[
                GlassCard(
                  onTap: () =>
                      copyToClipboard(context, c.email, 'Email address'),
                  child: Row(
                    children: [
                      IconBadge(icon: c.icon, color: context.pal.b),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: AppText.body(15, w: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(c.role,
                                style: AppText.body(12.5,
                                    color: AppColors.muted)),
                            const SizedBox(height: 2),
                            Text(c.email,
                                style: AppText.body(12.5,
                                    color: context.pal.b)),
                          ],
                        ),
                      ),
                      const Icon(Icons.content_copy_rounded,
                          size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
          child: Text(
            'Sample information. Opening hours and contacts must be confirmed with the administration before launch.',
            textAlign: TextAlign.center,
            style: AppText.body(11.5, color: AppColors.muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.facility, required this.now});
  final Facility facility;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final live = facility.liveAt(now);
    final canManage = app.perms.canManageFacility(facility.id);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: canManage
          ? Role.facilityManager.color.withValues(alpha: 0.5)
          : null,
      onTap: () => showFacilitySheet(context, facility.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: facility.icon, color: context.pal.b, size: 42),
              const Spacer(),
              Pill(label: live.label, color: live.color),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(facility.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(16.5)),
              ),
              if (canManage)
                const Icon(Icons.tune_rounded,
                    size: 16, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            facility.note.isNotEmpty ? facility.note : facility.hoursLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              11.5,
              color: facility.note.isNotEmpty ? live.color : AppColors.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
