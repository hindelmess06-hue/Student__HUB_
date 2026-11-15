import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../screens/announcement_detail.dart';
import '../screens/club_detail.dart';
import '../screens/event_detail.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// Full-width news row used in lists.
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.palette;
    final unread = !app.readNews.contains(item.id);
    final saved = app.savedNews.contains(item.id);

    return GlassCard(
      onTap: () =>
          Navigator.of(context).push(fadeSlide(AnnouncementDetail(item: item))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: item.category.icon, color: item.category.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(label: item.category.label, color: item.category.color),
                    if (item.highPriority) ...[
                      const SizedBox(width: 6),
                      const Pill(
                        label: 'Priority',
                        color: AppColors.danger,
                        icon: Icons.priority_high_rounded,
                      ),
                    ],
                    const Spacer(),
                    if (item.pinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.push_pin_rounded,
                            size: 14, color: AppColors.muted),
                      ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: p.b, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(16.5,
                      w: unread ? FontWeight.w700 : FontWeight.w500,
                      height: 1.25),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.author}  ·  ${timeAgo(item.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(12.5, color: AppColors.muted),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.read<AppState>().toggleSaved(item.id),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 22,
                          color: saved ? p.b : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact card for the horizontal carousel on the home screen.
class NewsMiniCard extends StatelessWidget {
  const NewsMiniCard({super.key, required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final unread = !context.watch<AppState>().readNews.contains(item.id);
    final color = item.category.color;
    return SizedBox(
      width: 264,
      child: GlassCard(
        onTap: () => Navigator.of(context)
            .push(fadeSlide(AnnouncementDetail(item: item))),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderColor: color.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.category.icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(item.category.label,
                    style: AppText.body(12.5, w: FontWeight.w600, color: color)),
                const Spacer(),
                if (unread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                item.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(17, height: 1.25),
              ),
            ),
            Text(
              '${item.author}  ·  ${timeAgo(item.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event, this.showDay = true});
  final CampusEvent event;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.palette;
    final going = app.goingEvents.contains(event.id);

    return GlassCard(
      onTap: () =>
          Navigator.of(context).push(fadeSlide(EventDetail(event: event))),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 64,
            decoration: BoxDecoration(
              gradient: going ? p.gradient : null,
              color: going ? null : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${event.start.day}',
                    style: AppText.display(22, color: Colors.white)),
                Text(
                  monthShort(event.start).toUpperCase(),
                  style: AppText.body(10.5,
                      w: FontWeight.w700,
                      color: going ? Colors.white : AppColors.muted,
                      letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(16, w: FontWeight.w600, height: 1.25),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      showDay
                          ? '${relDay(event.start)}, ${fmtTime(event.start)}'
                          : fmtTime(event.start),
                      style: AppText.body(12.5, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(12.5, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            going ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: going ? AppColors.success : AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class FollowButton extends StatelessWidget {
  const FollowButton({super.key, required this.club, this.compact = false});
  final Club club;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final following = app.followedClubs.contains(club.id);
    return Pressable(
      onTap: () {
        context.read<AppState>().toggleFollow(club.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 7 : 10,
        ),
        decoration: BoxDecoration(
          color: following
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              following ? Icons.check_rounded : Icons.add_rounded,
              size: compact ? 15 : 17,
              color: following ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 4),
            Text(
              following ? 'Following' : 'Follow',
              style: AppText.body(
                compact ? 12 : 13.5,
                w: FontWeight.w700,
                color: following ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square-ish club card used in the 2-column grid.
class ClubGridCard extends StatelessWidget {
  const ClubGridCard({super.key, required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () =>
          Navigator.of(context).push(fadeSlide(ClubDetail(club: club))),
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          club.color.withValues(alpha: 0.30),
          club.color.withValues(alpha: 0.06),
        ],
      ),
      borderColor: club.color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: club.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: club.color.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(club.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            club.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(17),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              club.tagline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(12.5, color: AppColors.muted, height: 1.35),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded,
                  size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text('${club.members}',
                  style: AppText.body(12, color: AppColors.muted)),
              const Spacer(),
              FollowButton(club: club, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Narrow club card for horizontal carousels.
class ClubMiniCard extends StatelessWidget {
  const ClubMiniCard({super.key, required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: GlassCard(
        onTap: () =>
            Navigator.of(context).push(fadeSlide(ClubDetail(club: club))),
        padding: const EdgeInsets.all(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            club.color.withValues(alpha: 0.30),
            club.color.withValues(alpha: 0.06),
          ],
        ),
        borderColor: club.color.withValues(alpha: 0.28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(club.icon, color: club.color, size: 30),
            const Spacer(),
            Text(club.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(16)),
            const SizedBox(height: 2),
            Text('${club.members} members',
                style: AppText.body(12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
