import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../screens/admin_screen.dart';
import '../screens/club_detail.dart';
import '../screens/sheets.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Home-screen shortcuts that change with the person's role. They appear the
/// moment a Super Admin approves a request (the profile updates live).
class StaffToolsCard extends StatelessWidget {
  const StaffToolsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final perms = app.perms;
    final role = app.role;
    final entity = app.profile?.assignedEntity;
    final club = role == Role.clubLeader ? app.clubById(entity) : null;
    final facility = role == Role.facilityManager ? app.facilityById(entity) : null;

    final tools = <Widget>[
      if (perms.isAdmin)
        _ToolButton(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Admin dashboard',
          badge: app.pendingRequestCount,
          onTap: () =>
              Navigator.of(context).push(fadeSlide(const AdminScreen())),
        ),
      if (facility != null) ...[
        _ToolButton(
          icon: Icons.tune_rounded,
          label: 'Manage ${facility.name}',
          onTap: () => showFacilitySheet(context, facility.id),
        ),
        _ToolButton(
          icon: Icons.campaign_rounded,
          label: 'Urgent banner',
          onTap: () => showAlertSheet(context, facility: facility),
        ),
        _ToolButton(
          icon: Icons.qr_code_2_rounded,
          label: 'New session',
          onTap: () => showCreateEventSheet(context, facility: facility),
        ),
      ],
      if (club != null) ...[
        _ToolButton(
          icon: Icons.campaign_rounded,
          label: 'Announce to club',
          onTap: () => showPublishSheet(context, club: club),
        ),
        _ToolButton(
          icon: Icons.event_available_rounded,
          label: 'Club event',
          onTap: () => showCreateEventSheet(context, club: club),
        ),
        _ToolButton(
          icon: Icons.edit_rounded,
          label: 'Manage ${club.name}',
          onTap: () =>
              Navigator.of(context).push(fadeSlide(ClubDetail(club: club))),
        ),
      ],
      if (club == null && perms.canPostAnnouncement)
        _ToolButton(
          icon: Icons.campaign_rounded,
          label: 'Post announcement',
          onTap: () => showPublishSheet(context),
        ),
      if (role == Role.professor || perms.isAdmin)
        _ToolButton(
          icon: Icons.event_available_rounded,
          label: role == Role.professor ? 'Faculty event' : 'Create event',
          onTap: () => showCreateEventSheet(context),
        ),
      if (perms.isAdmin)
        _ToolButton(
          icon: Icons.warning_amber_rounded,
          label: 'Urgent banner',
          onTap: () => showAlertSheet(context),
        ),
    ];

    final scope = app.entityName(role, entity);

    return GlassCard(
      radius: 24,
      borderColor: role.color.withValues(alpha: 0.35),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          role.color.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.03),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: role.icon, color: role.color, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Staff tools', style: AppText.display(17)),
                    Text(
                      scope == null ? role.label : '${role.label} · $scope',
                      style: AppText.body(12.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tools.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No area is assigned to your role yet. Ask a Super Admin to assign one.',
                style: AppText.body(13, color: AppColors.muted, height: 1.4),
              ),
            )
          else ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: tools),
          ],
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
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
            Icon(icon, size: 17, color: p.b),
            const SizedBox(width: 7),
            Text(label, style: AppText.body(13, w: FontWeight.w600)),
            if (badge > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('$badge',
                    style: AppText.body(11, w: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
