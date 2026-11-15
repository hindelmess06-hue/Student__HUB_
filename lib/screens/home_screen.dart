import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import '../widgets/alert_banner.dart';
import '../widgets/staff_tools.dart';
import 'announcement_detail.dart';
import 'search_screen.dart';
import '../models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});
  final void Function(int index) onNavigate;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.palette;
    final now = DateTime.now();

    final pinnedFirst = app.announcements;
    final hero = pinnedFirst.isEmpty
        ? null
        : pinnedFirst.firstWhere(
            (a) => a.pinned || a.highPriority,
            orElse: () => pinnedFirst.first,
          );
    final alerts = app.activeAlerts;
    final latest = app.latestNews.take(6).toList();
    final upcoming = app.upcomingEvents;
    final soon = upcoming.take(4).toList();
    final weekEnd = now.add(const Duration(days: 7));
    final thisWeek = upcoming.where((e) => e.start.isBefore(weekEnd)).length;

    // Suggest clubs the student does not follow yet.
    final suggested = [
      ...app.clubs.where((c) => !app.followedClubs.contains(c.id)),
      ...app.clubs.where((c) => app.followedClubs.contains(c.id)),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        // ── Header
        FadeSlideIn(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fmtDateLine(now),
                          style: AppText.body(13.5, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Text(
                        '${greeting()},',
                        style: AppText.display(15,
                            w: FontWeight.w500, color: AppColors.muted),
                      ),
                      GradientText(
                        firstName(app.user?.name ?? '', app.user?.email ?? ''),
                        style: AppText.display(34, letterSpacing: -0.8),
                      ),
                      if (app.perms.isStaff) ...[
                        const SizedBox(height: 6),
                        Pill(
                          label: app.role.label,
                          color: app.role.color,
                          icon: app.role.icon,
                        ),
                      ],
                    ],
                  ),
                ),
                GlassIconButton(
                  icon: Icons.search_rounded,
                  onTap: () => Navigator.of(context)
                      .push(fadeSlide(const SearchScreen())),
                ),
                const SizedBox(width: 10),
                const ProfileButton(),
              ],
            ),
          ),
        ),

        // ── Emergency banners (pinned for everyone)
        for (final a in alerts)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: AlertBanner(alert: a),
          ),

        // ── Staff tools (only for staff roles)
        if (app.perms.isStaff)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: StaffToolsCard(),
          ),

        // ── Hero announcement
        if (hero != null)
        FadeSlideIn(
          index: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Pressable(
              onTap: () => Navigator.of(context)
                  .push(fadeSlide(AnnouncementDetail(item: hero))),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: p.gradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: p.a.withValues(alpha: 0.4),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -14,
                      bottom: -20,
                      child: Icon(
                        hero.category.icon,
                        size: 130,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.push_pin_rounded,
                                      size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    hero.highPriority ? 'High priority' : (hero.pinned ? 'Pinned' : 'Latest'),
                                    style: AppText.body(11.5,
                                        w: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hero.category.label,
                              style: AppText.body(12.5,
                                  w: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(right: 60),
                          child: Text(
                            hero.title,
                            style: AppText.display(24,
                                color: Colors.white, height: 1.2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: Text(
                            hero.excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(13.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text('Read now',
                                style: AppText.body(14,
                                    w: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 6),
                            const Icon(Icons.north_east_rounded,
                                size: 16, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Stats
        FadeSlideIn(
          index: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                _Stat(
                  value: '${app.unreadCount}',
                  label: 'Unread news',
                  icon: Icons.mark_email_unread_rounded,
                  color: p.a,
                  onTap: () => onNavigate(1),
                ),
                const SizedBox(width: 10),
                _Stat(
                  value: '$thisWeek',
                  label: 'Events this week',
                  icon: Icons.event_rounded,
                  color: p.b,
                  onTap: () => onNavigate(2),
                ),
                const SizedBox(width: 10),
                _Stat(
                  value: '${app.followedClubs.length}',
                  label: 'Clubs followed',
                  icon: Icons.groups_rounded,
                  color: AppColors.success,
                  onTap: () => onNavigate(3),
                ),
              ],
            ),
          ),
        ),

        // ── Latest news carousel
        SectionHeader('Latest news',
            action: 'See all', onAction: () => onNavigate(1)),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: latest.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => NewsMiniCard(item: latest[i]),
          ),
        ),

        // ── Upcoming events
        SectionHeader('Happening soon',
            action: 'See all', onAction: () => onNavigate(2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (var i = 0; i < soon.length; i++) ...[
                FadeSlideIn(index: i, child: EventTile(event: soon[i])),
                if (i != soon.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),

        // ── Clubs
        SectionHeader('Discover clubs',
            action: 'See all', onAction: () => onNavigate(3)),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: suggested.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => ClubMiniCard(club: suggested[i]),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            Text(value, style: AppText.display(26)),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(11.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
