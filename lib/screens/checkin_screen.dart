import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Organiser view: live QR code + live attendance list.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key, required this.eventId});
  final String eventId;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late final Stream<List<Doc>> _secret = context
      .read<AppState>()
      .store
      .watch('eventSecrets', field: 'eventId', equals: widget.eventId);
  late final Stream<List<Doc>> _attendees = context
      .read<AppState>()
      .store
      .watch('checkins', field: 'eventId', equals: widget.eventId);

  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) toast(context, 'Could not update. Check your permissions.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final event = app.eventById(widget.eventId);

    if (event == null || !app.perms.canManageEvent(event)) {
      return const AppScaffold(
        body: Column(
          children: [
            DetailTopBar(),
            Expanded(
              child: EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Organisers only',
                subtitle: 'Only the person who created this event can run check-in.',
              ),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      body: Column(
        children: [
          const DetailTopBar(),
          Expanded(
            child: StreamBuilder<List<Doc>>(
              stream: _secret,
              builder: (context, secretSnap) {
                final docs = secretSnap.data ?? const <Doc>[];
                final secret = docs.isEmpty ? null : docs.first;
                final open = secret != null && secret['open'] == true;
                final token = secret?['token'] as String?;
                final payload = token == null
                    ? null
                    : 'studenthub://checkin?e=${event.id}&t=$token';

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [
                    Text('Check-in', style: AppText.display(30)),
                    const SizedBox(height: 4),
                    Text(event.title,
                        style: AppText.body(14.5, color: AppColors.muted)),
                    const SizedBox(height: 20),
                    if (open && payload != null) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: context.pal.a.withValues(alpha: 0.4),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: payload,
                            size: 250,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Students scan this from the event page.',
                          style: AppText.body(13, color: AppColors.muted),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: GhostButton(
                              label: 'Copy code',
                              icon: Icons.content_copy_rounded,
                              onTap: () =>
                                  copyToClipboard(context, payload, 'Check-in code'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GhostButton(
                              label: 'New code',
                              icon: Icons.refresh_rounded,
                              onTap: _busy
                                  ? null
                                  : () => _run(() => context
                                      .read<AppState>()
                                      .startCheckIn(event.id)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GhostButton(
                        label: 'Stop check-in',
                        icon: Icons.stop_circle_outlined,
                        color: AppColors.danger,
                        onTap: _busy
                            ? null
                            : () => _run(() =>
                                context.read<AppState>().stopCheckIn(event.id)),
                      ),
                    ] else ...[
                      GlassCard(
                        child: Column(
                          children: [
                            IconBadge(
                              icon: Icons.qr_code_2_rounded,
                              color: context.pal.b,
                              size: 60,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              secret == null
                                  ? 'Check-in is not started'
                                  : 'Check-in is closed',
                              style: AppText.display(18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start a session to show a QR code. Students scan it with their phone to log their attendance.',
                              textAlign: TextAlign.center,
                              style: AppText.body(13.5,
                                  color: AppColors.muted, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: 'Start check-in',
                        icon: Icons.play_arrow_rounded,
                        loading: _busy,
                        onTap: () => _run(
                            () => context.read<AppState>().startCheckIn(event.id)),
                      ),
                    ],
                    const SizedBox(height: 28),
                    StreamBuilder<List<Doc>>(
                      stream: _attendees,
                      builder: (context, snap) {
                        final list = (snap.data ?? const <Doc>[])
                            .map(CheckIn.fromMap)
                            .toList()
                          ..sort((a, b) => b.at.compareTo(a.at));
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Attendance',
                                      style: AppText.display(20)),
                                ),
                                Pill(
                                  label: '${list.length} checked in',
                                  color: AppColors.success,
                                  icon: Icons.verified_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (list.isEmpty)
                              Text('Nobody yet.',
                                  style: AppText.body(14, color: AppColors.muted))
                            else
                              for (final c in list) ...[
                                GlassCard(
                                  radius: 18,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Avatar(name: c.name, size: 38),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(c.name.isEmpty ? c.email : c.name,
                                                style: AppText.body(14.5,
                                                    w: FontWeight.w600)),
                                            Text(c.email,
                                                style: AppText.body(12,
                                                    color: AppColors.muted)),
                                          ],
                                        ),
                                      ),
                                      Text(fmtTime(c.at),
                                          style: AppText.body(12.5,
                                              color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
