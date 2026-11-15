import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'sheets.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _search = TextEditingController();
  int _cat = 0; // 0 = All, 1..n = categories, last = Saved
  String _q = '';

  static final List<String> _labels = [
    'All',
    ...AnnCategory.values.map((c) => c.label),
    'Saved',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Announcement> _filtered(AppState app) {
    var list = app.announcements;
    if (_cat == _labels.length - 1) {
      list = list.where((a) => app.savedNews.contains(a.id)).toList();
    } else if (_cat > 0) {
      final c = AnnCategory.values[_cat - 1];
      list = list.where((a) => a.category == c).toList();
    }
    final q = _q.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.body.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = _filtered(app);
    final savedTab = _cat == _labels.length - 1;

    return Column(
      children: [
        ScreenHeader(
          title: 'News',
          subtitle: '${app.unreadCount} unread',
          trailing: app.perms.canPostAnnouncement
              ? GlassIconButton(
                  icon: Icons.add_rounded,
                  onTap: () => showPublishSheet(context),
                )
              : null,
        ),
        const FacultyScopeBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppField(
            controller: _search,
            hint: 'Search announcements',
            icon: Icons.search_rounded,
            onChanged: (v) => setState(() => _q = v),
            suffix: _q.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.muted),
                    onPressed: () {
                      _search.clear();
                      setState(() => _q = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 14),
        FilterChips(
          labels: _labels,
          selected: _cat,
          onSelected: (i) => setState(() => _cat = i),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: savedTab
                      ? Icons.bookmark_border_rounded
                      : Icons.inbox_rounded,
                  title: savedTab ? 'Nothing saved yet' : 'No announcements',
                  subtitle: savedTab
                      ? 'Tap the bookmark on any announcement to keep it here.'
                      : 'Try another category or search term.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => FadeSlideIn(
                    index: i,
                    child: NewsCard(item: items[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

/// "Showing: Civil Engineering + general news" with a one-tap switch.
/// Only students get the faculty filter; staff always see everything.
class FacultyScopeBar extends StatelessWidget {
  const FacultyScopeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.perms.usesFacultyFilter) return const SizedBox.shrink();
    final p = app.palette;
    final dept = app.myDepartment;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.filter_alt_rounded, size: 18, color: p.b),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dept == null
                    ? 'Pick your faculty to see what matters to you'
                    : app.filterByDepartment
                        ? 'Showing $dept + general'
                        : 'Showing all faculties',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(13, color: AppColors.muted, height: 1.3),
              ),
            ),
            const SizedBox(width: 8),
            if (dept != null)
              GestureDetector(
                onTap: () => context.read<AppState>().toggleShowAllDepartments(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    app.filterByDepartment ? 'Show all' : 'Only mine',
                    style: AppText.body(13, w: FontWeight.w700, color: p.b),
                  ),
                ),
              ),
            GestureDetector(
              onTap: () => showDepartmentPicker(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  dept == null ? 'Choose' : 'Edit',
                  style: AppText.body(13, w: FontWeight.w700, color: p.b),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
