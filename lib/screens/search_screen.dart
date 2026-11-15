import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

/// Searches announcements, events and clubs at once.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final q = _q.trim().toLowerCase();

    final List<Announcement> news = q.isEmpty
        ? []
        : app.announcements
            .where((a) =>
                a.title.toLowerCase().contains(q) ||
                a.body.toLowerCase().contains(q))
            .toList();
    final List<CampusEvent> events = q.isEmpty
        ? []
        : app.upcomingEvents
            .where((e) =>
                e.title.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q) ||
                e.location.toLowerCase().contains(q) ||
                e.organizer.toLowerCase().contains(q))
            .toList();
    final List<Club> clubs = q.isEmpty
        ? []
        : app.clubs
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.tagline.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q))
            .toList();
    final nothing = news.isEmpty && events.isEmpty && clubs.isEmpty;

    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Row(
              children: [
                GlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppField(
                    controller: _c,
                    hint: 'Search everything',
                    icon: Icons.search_rounded,
                    autofocus: true,
                    onChanged: (v) => setState(() => _q = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: q.isEmpty
                ? const EmptyState(
                    icon: Icons.search_rounded,
                    title: 'Search Student Hub',
                    subtitle:
                        'Find announcements, events and clubs in one go.',
                  )
                : nothing
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No results',
                        subtitle: 'Nothing matches "$_q". Try another word.',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        children: [
                          if (news.isNotEmpty) ...[
                            _Label('News (${news.length})'),
                            for (final a in news) ...[
                              NewsCard(item: a),
                              const SizedBox(height: 12),
                            ],
                          ],
                          if (events.isNotEmpty) ...[
                            _Label('Events (${events.length})'),
                            for (final e in events) ...[
                              EventTile(event: e),
                              const SizedBox(height: 12),
                            ],
                          ],
                          if (clubs.isNotEmpty) ...[
                            _Label('Clubs (${clubs.length})'),
                            for (final c in clubs) ...[
                              SizedBox(
                                height: 200,
                                child: ClubGridCard(club: c),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 0, 12),
        child: Text(text,
            style: AppText.display(15, color: AppColors.muted)),
      );
}
