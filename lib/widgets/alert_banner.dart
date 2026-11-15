import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// Red banner pinned at the top of the home screen for every student.
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.alert});
  final CampusAlert alert;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final canResolve = app.perms.canResolveAlert(alert);
    final facility = app.facilityById(alert.facilityId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF3B5C), Color(0xFFB4122E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B5C).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PulseDot(),
              const SizedBox(width: 8),
              Text('URGENT',
                  style: AppText.body(11.5,
                      w: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.4)),
              if (facility != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      facility.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(11.5,
                          w: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(timeAgo(alert.createdAt),
                  style: AppText.body(11.5,
                      color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 12),
          Text(alert.title,
              style: AppText.display(20, color: Colors.white, height: 1.2)),
          const SizedBox(height: 6),
          Text(alert.message,
              style: AppText.body(14,
                  color: Colors.white.withValues(alpha: 0.92), height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Posted by ${alert.createdByName}',
                    style: AppText.body(11.5,
                        color: Colors.white.withValues(alpha: 0.75))),
              ),
              if (canResolve)
                Pressable(
                  onTap: () async {
                    await context.read<AppState>().resolveAlert(alert);
                    if (context.mounted) toast(context, 'Banner resolved');
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Resolve',
                        style: AppText.body(13,
                            w: FontWeight.w700,
                            color: const Color(0xFFB4122E))),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.7 * _c.value),
              blurRadius: 4 + 8 * _c.value,
              spreadRadius: 2 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}
