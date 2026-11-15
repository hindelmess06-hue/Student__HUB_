import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'announcements_screen.dart' show FacultyScopeBar;
import '../widgets/tiles.dart';
import 'sheets.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime? _day; // null = all upcoming
  int _cat = 0; // 0 = All, 1..n = categories, last = Going

  static final List<String> _labels = [
    'All',
    ...EventCategory.values.map((c) => c.label),
    'Going',
  ];

  List<CampusEvent> _filtered(AppState app) {
    var list = app.upcomingEvents;
    if (_day != null) {
      list = list.where((e) => sameDay(e.start, _day!)).toList();
    }
    if (_cat == _labels.length - 1) {
      list = list.where((e) => app.goingEvents.contains(e.id)).toList();
    } else if (_cat > 0) {
      final c = EventCategory.values[_cat - 1];
      list = list.where((e) => e.category == c).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final today = DateTime.now();
    final days = [
      for (var i = 0; i < 14; i++)
        DateTime(today.year, today.month, today.day + i),
    ];
    final items = _filtered(app);
    final upcoming = app.upcomingEvents;

    // Build list with day headers when browsing "All".
    final children = <Widget>[];
    DateTime? lastDay;
    var idx = 0;
    for (final e in items) {
      if (_day == null && (lastDay == null || !sameDay(lastDay, e.start))) {
        children.add(Padding(
          padding: EdgeInsets.only(top: lastDay == null ? 0 : 12, bottom: 10),
          child: Row(
            children: [
              Text(relDay(e.start),
                  style: AppText.display(16, color: AppColors.muted)),
              const SizedBox(width: 8),
              if (relDay(e.start) != fmtDay(e.start))
                Text(fmtDay(e.start),
                    style: AppText.body(12.5, color: AppColors.muted)),
            ],
          ),
        ));
        lastDay = e.start;
      }
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FadeSlideIn(
          index: idx++,
          child: EventTile(event: e, showDay: false),
        ),
      ));
    }

    return Column(
      children: [
        ScreenHeader(
          title: 'Events',
          subtitle: '${upcoming.length} coming up',
          trailing: app.perms.canCreateEvent
              ? GlassIconButton(
                  icon: Icons.add_rounded,
                  onTap: () => showCreateEventSheet(context),
                )
              : null,
        ),
        const FacultyScopeBar(),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: days.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              if (i == 0) {
                return _DayChip(
                  top: 'All',
                  bottom: '${upcoming.length}',
                  selected: _day == null,
                  hasEvents: false,
                  onTap: () => setState(() => _day = null),
                );
              }
              final d = days[i - 1];
              final has = upcoming.any((e) => sameDay(e.start, d));
              final sel = _day != null && sameDay(_day!, d);
              return _DayChip(
                top: i == 1 ? 'Today' : weekdayShort(d),
                bottom: '${d.day}',
                selected: sel,
                hasEvents: has,
                onTap: () => setState(() => _day = d),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        FilterChips(
          labels: _labels,
          selected: _cat,
          onSelected: (i) => setState(() => _cat = i),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: _cat == _labels.length - 1
                      ? "You're not going to anything yet"
                      : 'Nothing planned',
                  subtitle: _cat == _labels.length - 1
                      ? 'Open an event and tap "I\'m going" to build your agenda.'
                      : 'No events match this day and category.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                  children: children,
                ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.top,
    required this.bottom,
    required this.selected,
    required this.hasEvents,
    required this.onTap,
  });

  final String top;
  final String bottom;
  final bool selected;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: 60,
        decoration: BoxDecoration(
          gradient: selected ? p.gradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.09),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: p.a.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(top,
                style: AppText.body(11.5,
                    w: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.muted)),
            const SizedBox(height: 3),
            Text(bottom,
                style: AppText.display(20,
                    color: selected ? Colors.white : AppColors.text)),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasEvents
                    ? (selected ? Colors.white : p.b)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
