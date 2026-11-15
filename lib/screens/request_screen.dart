import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/forms.dart';

/// The "Demande": a student applies for a staff / organizer role.
class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  Role _role = Role.facilityManager;
  String? _target;
  final _why = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _why.dispose();
    super.dispose();
  }

  String _roleName(Role r) => switch (r) {
        Role.facilityManager => 'Facility staff',
        Role.professor => 'Professor',
        Role.clubLeader => 'Club leader',
        _ => r.label,
      };

  Future<void> _submit() async {
    final needsTarget = _role == Role.facilityManager || _role == Role.clubLeader;
    if (needsTarget && _target == null) {
      setState(() => _error = _role == Role.clubLeader
          ? 'Choose the club you lead.'
          : 'Choose the area you work in.');
      return;
    }
    if (_why.text.trim().length < 20) {
      setState(() => _error =
          'Explain your request in a few lines (position, course, club role...).');
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().submitRoleRequest(
            role: _role,
            target: needsTarget ? _target : null,
            justification: _why.text,
          );
      nav.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Request sent to the Super Admin')));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not send your request. Check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.palette;

    return AppScaffold(
      body: Column(
        children: [
          const DetailTopBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text('Apply for a staff role', style: AppText.display(30, height: 1.1)),
                const SizedBox(height: 8),
                Text(
                  'A Super Admin reviews every request. Once approved, your controls unlock in the app automatically.',
                  style: AppText.body(14.5, color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 24),
                const FormLabel('What are you applying for?'),
                ChoiceWrap<Role>(
                  values: RoleX.requestable,
                  labelOf: _roleName,
                  colorOf: (r) => r.color,
                  selected: _role,
                  onSelected: (r) => setState(() {
                    _role = r;
                    _target = null;
                  }),
                ),
                const SizedBox(height: 18),
                if (_role == Role.facilityManager) ...[
                  const FormLabel('Which area do you work in?'),
                  app.facilities.isEmpty
                      ? Text('No areas available yet.',
                          style: AppText.body(13.5, color: AppColors.muted))
                      : ChoiceWrap<String>(
                          values: app.facilities.map((f) => f.id).toList(),
                          labelOf: (id) => app.facilityById(id)?.name ?? id,
                          selected: _target,
                          onSelected: (id) => setState(() => _target = id),
                        ),
                  const SizedBox(height: 18),
                ],
                if (_role == Role.clubLeader) ...[
                  const FormLabel('Which club do you lead?'),
                  app.clubs.isEmpty
                      ? Text('No clubs available yet.',
                          style: AppText.body(13.5, color: AppColors.muted))
                      : ChoiceWrap<String>(
                          values: app.clubs.map((c) => c.id).toList(),
                          labelOf: (id) => app.clubById(id)?.name ?? id,
                          selected: _target,
                          onSelected: (id) => setState(() => _target = id),
                        ),
                  const SizedBox(height: 18),
                ],
                const FormLabel('Justification / proof'),
                AppField(
                  controller: _why,
                  hint: _role == Role.professor
                      ? 'Your department, the courses you teach...'
                      : _role == Role.clubLeader
                          ? 'Your role in the club, who can confirm it...'
                          : 'Your position, your supervisor, since when...',
                  icon: Icons.fact_check_rounded,
                  maxLines: 5,
                  keyboard: TextInputType.multiline,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.a.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: p.b),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The admin sees your name and ${app.user?.email ?? 'email'}.',
                          style: AppText.body(12.5,
                              color: AppColors.muted, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FormError(_error),
                GradientButton(
                  label: 'Send request',
                  icon: Icons.send_rounded,
                  loading: _busy,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
