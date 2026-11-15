import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'sheets.dart';

class ClubDetail extends StatelessWidget {
  const ClubDetail({super.key, required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // Always show the freshest version (a leader may just have edited it).
    final c = app.clubById(club.id) ?? club;
    final events = app.eventsForClub(c.id);
    final following = app.followedClubs.contains(c.id);
    final members = c.members + (following ? 1 : 0);
    final manage = app.perms.canManageClub(c.id);

    return AppScaffold(
      body: Column(
        children: [
          const DetailTopBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          c.color.withValues(alpha: 0.55),
                          c.color.withValues(alpha: 0.10),
                        ],
                      ),
                      border:
                          Border.all(color: c.color.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: c.color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: c.color.withValues(alpha: 0.55),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(c.icon, color: Colors.white, size: 34),
                        ),
                        const SizedBox(height: 18),
                        Text(c.name, style: AppText.display(32, height: 1.1)),
                        const SizedBox(height: 6),
                        Text(
                          c.tagline,
                          style: AppText.body(15,
                              color: Colors.white.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _MiniStat(value: '$members', label: 'members'),
                            const SizedBox(width: 24),
                            _MiniStat(
                                value: '${events.length}', label: 'events'),
                            const Spacer(),
                            FollowButton(club: c),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (manage) ...[
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    index: 1,
                    child: GlassCard(
                      borderColor: Role.clubLeader.color.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBadge(
                                icon: Icons.edit_rounded,
                                color: Role.clubLeader.color,
                                size: 38,
                              ),
                              const SizedBox(width: 12),
                              Text('Manage this club',
                                  style: AppText.display(17)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Tool(
                                icon: Icons.edit_note_rounded,
                                label: 'Edit page',
                                onTap: () => showEditClubSheet(context, c),
                              ),
                              _Tool(
                                icon: Icons.history_edu_rounded,
                                label: 'Post update',
                                onTap: () => showClubUpdateSheet(context, c),
                              ),
                              _Tool(
                                icon: Icons.campaign_rounded,
                                label: 'Announcement',
                                onTap: () => showPublishSheet(context, club: c),
                              ),
                              _Tool(
                                icon: Icons.event_available_rounded,
                                label: 'Create event',
                                onTap: () =>
                                    showCreateEventSheet(context, club: c),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FadeSlideIn(
                  index: 1,
                  child: Text('About', style: AppText.display(20)),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  index: 1,
                  child: Text(
                    c.description,
                    style: AppText.body(15.5,
                        height: 1.6,
                        color: AppColors.text.withValues(alpha: 0.9)),
                  ),
                ),
                if (c.updates.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  Text('Latest updates', style: AppText.display(20)),
                  const SizedBox(height: 14),
                  for (var i = 0; i < c.updates.length; i++)
                    _UpdateRow(
                      update: c.updates[i],
                      color: c.color,
                      last: i == c.updates.length - 1,
                    ),
                ],
                if (events.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('Upcoming events', style: AppText.display(20)),
                  const SizedBox(height: 14),
                  for (final e in events) ...[
                    EventTile(event: e),
                    const SizedBox(height: 12),
                  ],
                ],
                const SizedBox(height: 14),
                Text('Get in touch', style: AppText.display(20)),
                const SizedBox(height: 14),
                GlassCard(
                  onTap: c.email.isEmpty
                      ? null
                      : () => copyToClipboard(context, c.email, 'Email address'),
                  child: Row(
                    children: [
                      Avatar(name: c.president, size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.president,
                                style: AppText.body(15, w: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(c.email.isEmpty ? 'No contact yet' : c.email,
                                style: AppText.body(13, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      if (c.email.isNotEmpty)
                        const Icon(Icons.content_copy_rounded,
                            size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: Role.clubLeader.color),
            const SizedBox(width: 7),
            Text(label, style: AppText.body(13, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.display(22)),
        Text(label,
            style: AppText.body(12, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.update,
    required this.color,
    required this.last,
  });
  final ClubUpdate update;
  final Color color;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.5), blurRadius: 8),
                    ],
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeAgo(update.date),
                      style: AppText.body(12, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(update.text, style: AppText.body(15, height: 1.45)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
