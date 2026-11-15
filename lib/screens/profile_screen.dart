import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'admin_screen.dart';
import 'request_screen.dart';
import 'sheets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign out?', style: AppText.display(20)),
        content: Text(
          'You will need to sign in again to see your campus feed.',
          style: AppText.body(14.5, color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppText.body(14.5)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sign out',
                style: AppText.body(14.5,
                    color: AppColors.danger, w: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      // Grab what we need before leaving this page, close it, then drop the
      // session. The root switches back to the sign-in screen by itself.
      final app = context.read<AppState>();
      Navigator.of(context).popUntil((r) => r.isFirst);
      await app.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.palette;
    final user = app.user;
    final profile = app.profile;
    final role = app.role;
    final name = (user?.name ?? '').isEmpty ? 'Student' : user!.name;
    final scope = app.entityName(role, profile?.assignedEntity);
    final pending = app.myPendingRequest;

    return AppScaffold(
      body: Column(
        children: [
          const DetailTopBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                FadeSlideIn(
                  child: Column(
                    children: [
                      Avatar(name: name, size: 96),
                      const SizedBox(height: 16),
                      Text(name, style: AppText.display(26)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '',
                          style: AppText.body(14, color: AppColors.muted)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          const Pill(
                            label: 'Verified UEMF account',
                            color: AppColors.success,
                            icon: Icons.verified_rounded,
                          ),
                          Pill(
                            label: scope == null
                                ? role.label
                                : '${role.label} · $scope',
                            color: role.color,
                            icon: role.icon,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  index: 1,
                  child: Row(
                    children: [
                      _Count(
                          value: '${app.followedClubs.length}',
                          label: 'Clubs followed'),
                      const SizedBox(width: 10),
                      _Count(
                          value: '${app.goingEvents.length}',
                          label: 'Events going'),
                      const SizedBox(width: 10),
                      _Count(
                          value: '${app.savedNews.length}',
                          label: 'Saved news'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Faculty / major
                FadeSlideIn(
                  index: 2,
                  child: GlassCard(
                    onTap: () => showDepartmentPicker(context),
                    child: Row(
                      children: [
                        IconBadge(icon: Icons.school_rounded, color: p.b),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Faculty / major',
                                  style: AppText.body(12.5,
                                      color: AppColors.muted)),
                              const SizedBox(height: 2),
                              Text(
                                app.myDepartment ?? 'Not set. Tap to choose',
                                style: AppText.body(15.5, w: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.muted),
                      ],
                    ),
                  ),
                ),

                // ── Staff / organizer role request
                if (role == Role.student) ...[
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: 2,
                    child: pending != null
                        ? GlassCard(
                            borderColor: AppColors.warning.withValues(alpha: 0.4),
                            child: Row(
                              children: [
                                const IconBadge(
                                  icon: Icons.hourglass_top_rounded,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Request pending',
                                          style: AppText.body(15.5,
                                              w: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${pending.role.label}${pending.target != null ? ' · ${app.entityName(pending.role, pending.target)}' : ''}, sent ${timeAgo(pending.createdAt)}',
                                        style: AppText.body(12.5,
                                            color: AppColors.muted,
                                            height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GradientButton(
                            label: 'Apply for Staff / Organizer Role',
                            icon: Icons.badge_rounded,
                            onTap: () => Navigator.of(context)
                                .push(fadeSlide(const RequestScreen())),
                          ),
                  ),
                ],

                // ── Request history
                if (app.myRequests.any((r) => r.status != RequestStatus.pending)) ...[
                  const SizedBox(height: 22),
                  Text('My requests', style: AppText.display(18)),
                  const SizedBox(height: 12),
                  for (final r in app.myRequests
                      .where((r) => r.status != RequestStatus.pending)
                      .take(4)) ...[
                    GlassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${r.role.label}${r.target != null ? ' · ${app.entityName(r.role, r.target)}' : ''}',
                                  style: AppText.body(14.5, w: FontWeight.w600),
                                ),
                              ),
                              Pill(
                                label: r.status == RequestStatus.approved
                                    ? 'Approved'
                                    : 'Rejected',
                                color: r.status == RequestStatus.approved
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                            ],
                          ),
                          if (r.decisionNote != null) ...[
                            const SizedBox(height: 6),
                            Text(r.decisionNote!,
                                style: AppText.body(12.5,
                                    color: AppColors.muted, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],

                // ── Super admin
                if (app.perms.isAdmin) ...[
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: 3,
                    child: GradientButton(
                      label: app.pendingRequestCount > 0
                          ? 'Admin dashboard (${app.pendingRequestCount} pending)'
                          : 'Admin dashboard',
                      icon: Icons.admin_panel_settings_rounded,
                      onTap: () => Navigator.of(context)
                          .push(fadeSlide(const AdminScreen())),
                    ),
                  ),
                ],

                const SizedBox(height: 26),
                FadeSlideIn(
                  index: 3,
                  child: Text('Accent colour', style: AppText.display(18)),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 3,
                  child: GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (var i = 0; i < Palette.all.length; i++)
                          GestureDetector(
                            onTap: () => context.read<AppState>().setPalette(i),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: Palette.all[i].gradient,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: app.paletteIndex == i
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: app.paletteIndex == i
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  Palette.all[i].name,
                                  style: AppText.body(
                                    11.5,
                                    color: app.paletteIndex == i
                                        ? Colors.white
                                        : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                FadeSlideIn(
                  index: 4,
                  child: GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.muted, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${AppConfig.appName} ${AppConfig.version}\n'
                            '${AppConfig.useFirebase ? 'Connected to Firebase.' : 'Demo mode: data and accounts stay on this phone.'}\n'
                            'Announcements, events and contacts are sample content.',
                            style: AppText.body(12.5,
                                color: AppColors.muted, height: 1.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeSlideIn(
                  index: 4,
                  child: GhostButton(
                    label: 'Sign out',
                    icon: Icons.logout_rounded,
                    color: AppColors.danger,
                    onTap: () => _confirmSignOut(context),
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

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        radius: 20,
        child: Column(
          children: [
            Text(value, style: AppText.display(26)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: AppText.body(11.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
