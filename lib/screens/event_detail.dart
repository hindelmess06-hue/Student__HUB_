import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'checkin_screen.dart';
import 'club_detail.dart';
import 'scan_screen.dart';

class EventDetail extends StatelessWidget {
  const EventDetail({super.key, required this.event});
  final CampusEvent event;

  Future<void> _confirmDelete(BuildContext context, CampusEvent e) async {
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete event?', style: AppText.display(20)),
        content: Text('It will disappear for every student.',
            style: AppText.body(14.5, color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppText.body(14.5)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: AppText.body(14.5,
                    color: AppColors.danger, w: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.deleteEvent(e);
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final e = app.eventById(event.id) ?? event;
    final going = app.goingEvents.contains(e.id);
    final color = e.category.color;
    final club = app.clubById(e.clubId);
    final goingCount = e.baseGoing + (going ? 1 : 0);
    final manage = app.perms.canManageEvent(e);
    final checkedIn = app.myCheckIns.contains(e.id);

    return AppScaffold(
      body: Column(
        children: [
          DetailTopBar(
            actions: [
              if (manage)
                GlassIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  onTap: () => _confirmDelete(context, e),
                ),
              GlassIconButton(
                icon: Icons.content_copy_rounded,
                onTap: () => copyToClipboard(
                  context,
                  '${e.title}\n${fmtLong(e.start)}, ${e.timeRange}\n${e.location}\nOrganised by ${e.organizer}',
                  'Event details',
                ),
              ),
            ],
          ),
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
                          color.withValues(alpha: 0.42),
                          color.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Pill(
                              label: e.category.label,
                              color: color,
                              icon: e.category.icon,
                            ),
                            if (e.department != null)
                              Pill(
                                label: e.department!,
                                color: app.palette.b,
                                icon: Icons.school_rounded,
                              ),
                            if (e.checkInEnabled)
                              const Pill(
                                label: 'QR check-in live',
                                color: AppColors.success,
                                icon: Icons.qr_code_2_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(e.title, style: AppText.display(27, height: 1.2)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded,
                                size: 16, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Text('$goingCount students going',
                                style: AppText.body(13.5,
                                    color: AppColors.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 1,
                  child: GlassCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.event_rounded,
                          label: 'Date',
                          value: fmtLong(e.start),
                          sub: relDay(e.start),
                        ),
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Time',
                          value: e.timeRange,
                        ),
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: e.location,
                        ),
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.groups_rounded,
                          label: 'Organiser',
                          value: e.organizer,
                          onTap: club == null
                              ? null
                              : () => Navigator.of(context)
                                  .push(fadeSlide(ClubDetail(club: club))),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  index: 2,
                  child: Text('About', style: AppText.display(20)),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  index: 2,
                  child: Text(
                    e.description,
                    style: AppText.body(15.5,
                        height: 1.6,
                        color: AppColors.text.withValues(alpha: 0.9)),
                  ),
                ),
                const SizedBox(height: 28),
                if (manage) ...[
                  FadeSlideIn(
                    index: 3,
                    child: GradientButton(
                      label: e.checkInEnabled
                          ? 'Show QR code and attendance'
                          : 'QR check-in and attendance',
                      icon: Icons.qr_code_2_rounded,
                      onTap: () => Navigator.of(context)
                          .push(fadeSlide(CheckInScreen(eventId: e.id))),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (checkedIn)
                  const FadeSlideIn(
                    index: 3,
                    child: _CheckedInBadge(),
                  )
                else if (e.checkInEnabled && !manage)
                  FadeSlideIn(
                    index: 3,
                    child: GradientButton(
                      label: 'Scan to check in',
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () => Navigator.of(context)
                          .push(fadeSlide(const ScanScreen())),
                    ),
                  ),
                if (checkedIn || (e.checkInEnabled && !manage))
                  const SizedBox(height: 12),
                FadeSlideIn(
                  index: 3,
                  child: going
                      ? GhostButton(
                          label: "You're going. Tap to cancel",
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          onTap: () {
                            context.read<AppState>().toggleGoing(e.id);
                            toast(context, 'Removed from your agenda');
                          },
                        )
                      : GhostButton(
                          label: "I'm going",
                          icon: Icons.event_available_rounded,
                          onTap: () {
                            context.read<AppState>().toggleGoing(e.id);
                            toast(context, 'Added to your agenda');
                          },
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

class _CheckedInBadge extends StatelessWidget {
  const _CheckedInBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success),
          const SizedBox(width: 8),
          Text('Checked in. Attendance logged',
              style: AppText.body(15, w: FontWeight.w700, color: AppColors.success)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final row = Row(
      children: [
        IconBadge(icon: icon, color: p.b, size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.body(12, color: AppColors.muted)),
              const SizedBox(height: 2),
              Text(value, style: AppText.body(15, w: FontWeight.w600)),
            ],
          ),
        ),
        if (sub != null)
          Text(sub!,
              style: AppText.body(13, w: FontWeight.w600, color: p.b)),
        if (onTap != null)
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(
          height: 1,
          color: Colors.white.withValues(alpha: 0.07),
        ),
      );
}
