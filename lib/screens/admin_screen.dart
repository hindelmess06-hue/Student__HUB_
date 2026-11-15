import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/forms.dart';
import 'sheets.dart';

/// Super Admin control room: requests, users, campus areas, audit log.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!app.perms.isAdmin) {
      return const AppScaffold(
        body: Column(
          children: [
            DetailTopBar(),
            Expanded(
              child: EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Super admins only',
                subtitle: 'You do not have access to this area.',
              ),
            ),
          ],
        ),
      );
    }

    final pending = app.pendingRequestCount;
    final labels = [
      pending > 0 ? 'Requests ($pending)' : 'Requests',
      'Users',
      'Areas',
      'Audit log',
    ];

    return AppScaffold(
      body: Column(
        children: [
          const DetailTopBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Admin dashboard', style: AppText.display(30)),
            ),
          ),
          FilterChips(
            labels: labels,
            selected: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: switch (_tab) {
              0 => const _RequestsTab(),
              1 => const _UsersTab(),
              2 => const _AreasTab(),
              _ => const _LogTab(),
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Requests ─────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pending =
        app.allRequests.where((r) => r.status == RequestStatus.pending).toList();
    final done =
        app.allRequests.where((r) => r.status != RequestStatus.pending).toList();

    if (app.allRequests.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_rounded,
        title: 'No requests yet',
        subtitle:
            'When a student applies for a staff or organizer role, it shows up here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text('All caught up. No pending requests.',
                style: AppText.body(14, color: AppColors.muted)),
          )
        else
          for (final r in pending) ...[
            _RequestCard(request: r),
            const SizedBox(height: 14),
          ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Decided', style: AppText.display(16, color: AppColors.muted)),
          const SizedBox(height: 12),
          for (final r in done.take(20)) ...[
            _RequestCard(request: r),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final RoleRequest request;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = request;
    final pending = r.status == RequestStatus.pending;
    final target = app.entityName(r.role, r.target);

    return GlassCard(
      borderColor: pending ? r.role.color.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(name: r.name, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: AppText.body(15.5, w: FontWeight.w700)),
                    Text(r.email,
                        style: AppText.body(12.5, color: AppColors.muted)),
                  ],
                ),
              ),
              Text(timeAgo(r.createdAt),
                  style: AppText.body(12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(label: r.role.label, color: r.role.color, icon: r.role.icon),
              if (target != null)
                Pill(label: target, color: AppColors.muted, icon: Icons.place_rounded),
              if (!pending)
                Pill(
                  label: r.status == RequestStatus.approved ? 'Approved' : 'Rejected',
                  color: r.status == RequestStatus.approved
                      ? AppColors.success
                      : AppColors.danger,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(r.justification,
                style: AppText.body(13.5, height: 1.45)),
          ),
          if (!pending) ...[
            const SizedBox(height: 10),
            Text(
              '${r.status == RequestStatus.approved ? 'Approved' : 'Rejected'} by ${r.decidedBy ?? 'admin'}${r.decidedAt != null ? ', ${timeAgo(r.decidedAt!)}' : ''}${r.decisionNote != null ? '\n${r.decisionNote}' : ''}',
              style: AppText.body(12.5, color: AppColors.muted, height: 1.4),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: AppColors.danger,
                    onTap: () => _reject(context, r),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    onTap: () => _approve(context, r),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, RoleRequest r) {
    return showAppSheet<void>(
      context,
      title: 'Approve request',
      subtitle: '${r.name} · ${r.email}',
      builder: (_) => _ApproveForm(request: r),
    );
  }

  Future<void> _reject(BuildContext context, RoleRequest r) {
    return showAppSheet<void>(
      context,
      title: 'Reject request',
      subtitle: '${r.name} · ${r.email}',
      builder: (_) => _RejectForm(request: r),
    );
  }
}

class _ApproveForm extends StatefulWidget {
  const _ApproveForm({required this.request});
  final RoleRequest request;

  @override
  State<_ApproveForm> createState() => _ApproveFormState();
}

class _ApproveFormState extends State<_ApproveForm> {
  late Role _role = widget.request.role;
  late String? _entity = widget.request.target;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final needs = _role == Role.facilityManager || _role == Role.clubLeader;
    if (needs && _entity == null) {
      setState(() => _error = 'Choose the scope to assign.');
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().approveRequest(
            widget.request,
            role: _role,
            entity: needs ? _entity : null,
            note: _note.text,
          );
      nav.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Approved. Their controls unlock instantly')));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save. Check your connection and permissions.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormLabel('Role'),
        ChoiceWrap<Role>(
          values: RoleX.requestable,
          labelOf: (r) => r.label,
          colorOf: (r) => r.color,
          selected: _role,
          onSelected: (r) => setState(() {
            _role = r;
            _entity = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_role == Role.facilityManager) ...[
          const FormLabel('Assign to area'),
          ChoiceWrap<String>(
            values: app.facilities.map((f) => f.id).toList(),
            labelOf: (id) => app.facilityById(id)?.name ?? id,
            selected: _entity,
            onSelected: (id) => setState(() => _entity = id),
          ),
          const SizedBox(height: 16),
        ],
        if (_role == Role.clubLeader) ...[
          const FormLabel('Assign to club'),
          ChoiceWrap<String>(
            values: app.clubs.map((c) => c.id).toList(),
            labelOf: (id) => app.clubById(id)?.name ?? id,
            selected: _entity,
            onSelected: (id) => setState(() => _entity = id),
          ),
          const SizedBox(height: 16),
        ],
        AppField(
          controller: _note,
          hint: 'Note for the applicant (optional)',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        const SizedBox(height: 16),
        FormError(_error),
        GradientButton(
          label: 'Approve and assign',
          icon: Icons.verified_rounded,
          loading: _busy,
          onTap: _submit,
        ),
      ],
    );
  }
}

class _RejectForm extends StatefulWidget {
  const _RejectForm({required this.request});
  final RoleRequest request;

  @override
  State<_RejectForm> createState() => _RejectFormState();
}

class _RejectFormState extends State<_RejectForm> {
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context
          .read<AppState>()
          .rejectRequest(widget.request, note: _note.text);
      nav.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save. Check your connection and permissions.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppField(
          controller: _note,
          hint: 'Reason (shown to the applicant)',
          icon: Icons.chat_bubble_outline_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        FormError(_error),
        GradientButton(
          label: 'Reject request',
          icon: Icons.close_rounded,
          loading: _busy,
          onTap: _submit,
        ),
      ],
    );
  }
}

// ───────────────────────── Users ─────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final q = _q.trim().toLowerCase();
    final users = app.allUsers
        .where((u) =>
            q.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        if (a.role != b.role) {
          if (a.role == Role.student) return 1;
          if (b.role == Role.student) return -1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: AppField(
            controller: _search,
            hint: 'Search by name or email',
            icon: Icons.search_rounded,
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? const EmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'No users found',
                  subtitle: 'Accounts appear here after they sign up.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final scope = app.entityName(u.role, u.assignedEntity);
                    final isMe = u.uid == app.profile?.uid;
                    return GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(14),
                      onTap: isMe ? null : () => _edit(context, u),
                      child: Row(
                        children: [
                          Avatar(name: u.name.isEmpty ? u.email : u.name, size: 42),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name.isEmpty ? u.email : u.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(15, w: FontWeight.w700),
                                ),
                                Text(u.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(12.5,
                                        color: AppColors.muted)),
                                const SizedBox(height: 8),
                                Pill(
                                  label: scope == null
                                      ? u.role.label
                                      : '${u.role.label} · $scope',
                                  color: u.role.color,
                                  icon: u.role.icon,
                                ),
                              ],
                            ),
                          ),
                          if (!isMe)
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.muted),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, UserProfile u) {
    return showAppSheet<void>(
      context,
      title: u.name.isEmpty ? u.email : u.name,
      subtitle: u.email,
      builder: (_) => _UserEditForm(user: u),
    );
  }
}

class _UserEditForm extends StatefulWidget {
  const _UserEditForm({required this.user});
  final UserProfile user;

  @override
  State<_UserEditForm> createState() => _UserEditFormState();
}

class _UserEditFormState extends State<_UserEditForm> {
  late Role _role = widget.user.role;
  late String? _entity = widget.user.assignedEntity;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final needs = _role == Role.facilityManager || _role == Role.clubLeader;
    if (needs && _entity == null) {
      setState(() => _error = 'Choose the scope to assign.');
      return;
    }
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().setUserRole(
            widget.user,
            _role,
            entity: needs ? _entity : null,
          );
      nav.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save. Check your connection and permissions.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormLabel('Role'),
        ChoiceWrap<Role>(
          values: Role.values,
          labelOf: (r) => r.label,
          colorOf: (r) => r.color,
          selected: _role,
          onSelected: (r) => setState(() {
            _role = r;
            _entity = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_role == Role.facilityManager) ...[
          const FormLabel('Assigned area'),
          ChoiceWrap<String>(
            values: app.facilities.map((f) => f.id).toList(),
            labelOf: (id) => app.facilityById(id)?.name ?? id,
            selected: _entity,
            onSelected: (id) => setState(() => _entity = id),
          ),
          const SizedBox(height: 16),
        ],
        if (_role == Role.clubLeader) ...[
          const FormLabel('Assigned club'),
          ChoiceWrap<String>(
            values: app.clubs.map((c) => c.id).toList(),
            labelOf: (id) => app.clubById(id)?.name ?? id,
            selected: _entity,
            onSelected: (id) => setState(() => _entity = id),
          ),
          const SizedBox(height: 16),
        ],
        if (_role == Role.superAdmin)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Super admins can approve requests and change anyone\'s role. Be careful.',
              style: AppText.body(13, color: AppColors.warning, height: 1.4),
            ),
          ),
        FormError(_error),
        GradientButton(
          label: 'Save role',
          icon: Icons.check_rounded,
          loading: _busy,
          onTap: _save,
        ),
      ],
    );
  }
}

// ───────────────────────── Areas ─────────────────────────

class _AreasTab extends StatelessWidget {
  const _AreasTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = DateTime.now();
    final facilities = app.facilities;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        GradientButton(
          label: 'Create a campus area',
          icon: Icons.add_business_rounded,
          onTap: () => showCreateFacilitySheet(context),
        ),
        const SizedBox(height: 12),
        if (!AppConfig.useFirebase || facilities.isEmpty)
          GhostButton(
            label: 'Load sample content',
            icon: Icons.download_rounded,
            onTap: () async {
              await context.read<AppState>().importSampleContent();
              if (context.mounted) toast(context, 'Sample content loaded');
            },
          ),
        const SizedBox(height: 18),
        for (final f in facilities) ...[
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.all(14),
            onTap: () => showFacilitySheet(context, f.id),
            child: Row(
              children: [
                IconBadge(icon: f.icon, color: context.pal.b),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: AppText.body(15, w: FontWeight.w700)),
                      Text(f.hoursLabel,
                          style: AppText.body(12.5, color: AppColors.muted)),
                    ],
                  ),
                ),
                Pill(
                  label: f.liveAt(now).label,
                  color: f.liveAt(now).color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ───────────────────────── Audit log ─────────────────────────

class _LogTab extends StatelessWidget {
  const _LogTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final logs = app.logs;

    if (logs.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'Nothing logged yet',
        subtitle: 'Every staff action is recorded here: who did what, and when.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: logs.length > 200 ? 200 : logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = logs[i];
        return GlassCard(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: e.actorRole.icon, color: e.actorRole.color, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${e.actorName} ',
                            style: AppText.body(14, w: FontWeight.w700),
                          ),
                          TextSpan(
                            text: e.action,
                            style: AppText.body(14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${e.actorRole.label}  ·  ${fmtDay(e.at)}, ${fmtTime(e.at)}',
                      style: AppText.body(12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
