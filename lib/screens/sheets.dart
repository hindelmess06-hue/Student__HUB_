import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icons.dart';
import '../widgets/common.dart';
import '../widgets/forms.dart';

const _genericError =
    'Could not save. Check your connection and your permissions, then try again.';

// ───────────────────────── Announcements ─────────────────────────

Future<void> showPublishSheet(BuildContext context, {Club? club}) {
  return showAppSheet<void>(
    context,
    title: club != null ? 'Announce to ${club.name}' : 'New announcement',
    builder: (_) => _PublishForm(club: club),
  );
}

class _PublishForm extends StatefulWidget {
  const _PublishForm({this.club});
  final Club? club;

  @override
  State<_PublishForm> createState() => _PublishFormState();
}

class _PublishFormState extends State<_PublishForm> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  late AnnCategory _category;
  bool _high = false;
  String? _dept;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final role = context.read<AppState>().role;
    if (widget.club != null) {
      _category = AnnCategory.campusLife;
    } else if (role == Role.professor) {
      _category = AnnCategory.academic;
      _high = true;
    } else {
      _category = AnnCategory.administration;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().length < 4) {
      setState(() => _error = 'Give your announcement a clear title.');
      return;
    }
    if (_body.text.trim().length < 10) {
      setState(() => _error = 'Add a few lines of details.');
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().publishAnnouncement(
            title: _title.text,
            body: _body.text,
            category: _category,
            highPriority: _high,
            department: _dept,
            clubId: widget.club?.id,
          );
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Announcement published')));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _genericError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppState>().role;
    final club = widget.club;
    final lockCategory = club != null || role == Role.professor;
    final isClub = club != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppField(
          controller: _title,
          hint: 'Title',
          icon: Icons.title_rounded,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _body,
          hint: 'Details',
          icon: Icons.notes_rounded,
          maxLines: 5,
          keyboard: TextInputType.multiline,
        ),
        const SizedBox(height: 16),
        if (!lockCategory) ...[
          const FormLabel('Category'),
          ChoiceWrap<AnnCategory>(
            values: AnnCategory.values,
            labelOf: (c) => c.label,
            colorOf: (c) => c.color,
            selected: _category,
            onSelected: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: 16),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              isClub
                  ? 'Posted on behalf of ${club.name}.'
                  : 'Posted as an academic announcement.',
              style: AppText.body(13, color: AppColors.muted),
            ),
          ),
        if (!isClub) ...[
          ToggleRow(
            title: 'High priority',
            subtitle: 'Adds a red tag and floats the post to the top.',
            value: _high,
            onChanged: (v) => setState(() => _high = v),
          ),
          const FormLabel('Audience'),
          ChoiceWrap<String?>(
            values: [null, ...AppConfig.departments],
            labelOf: (d) => d ?? 'Everyone',
            selected: _dept,
            onSelected: (d) => setState(() => _dept = d),
          ),
          const SizedBox(height: 16),
        ],
        FormError(_error),
        GradientButton(
          label: 'Publish',
          icon: Icons.send_rounded,
          loading: _busy,
          onTap: _submit,
        ),
      ],
    );
  }
}

// ───────────────────────── Events ─────────────────────────

Future<void> showCreateEventSheet(
  BuildContext context, {
  Club? club,
  Facility? facility,
}) {
  return showAppSheet<void>(
    context,
    title: club != null
        ? 'New event for ${club.name}'
        : facility != null
            ? 'New session at ${facility.name}'
            : 'New event',
    builder: (_) => _EventForm(club: club, facility: facility),
  );
}

class _EventForm extends StatefulWidget {
  const _EventForm({this.club, this.facility});
  final Club? club;
  final Facility? facility;

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  late final TextEditingController _location;
  DateTime _date = DateTime.now();
  int _start = 17 * 60;
  int _end = 19 * 60;
  late EventCategory _category;
  String? _dept;
  bool _checkIn = false;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final role = context.read<AppState>().role;
    _location = TextEditingController(text: widget.facility?.location ?? '');
    if (widget.club != null) {
      _category = EventCategory.cultural;
    } else if (widget.facility != null) {
      _category = EventCategory.sport;
      _checkIn = true;
    } else if (role == Role.professor) {
      _category = EventCategory.academic;
    } else {
      _category = EventCategory.academic;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().length < 4) {
      setState(() => _error = 'Give the event a clear title.');
      return;
    }
    if (_desc.text.trim().length < 10) {
      setState(() => _error = 'Add a short description.');
      return;
    }
    if (_location.text.trim().isEmpty) {
      setState(() => _error = 'Where does it take place?');
      return;
    }
    if (_end <= _start) {
      setState(() => _error = 'The end time must be after the start time.');
      return;
    }
    final start = DateTime(_date.year, _date.month, _date.day, _start ~/ 60, _start % 60);
    final end = DateTime(_date.year, _date.month, _date.day, _end ~/ 60, _end % 60);
    if (end.isBefore(DateTime.now())) {
      setState(() => _error = 'That time has already passed.');
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().createEvent(
            title: _title.text,
            description: _desc.text,
            location: _location.text,
            start: start,
            end: end,
            category: _category,
            clubId: widget.club?.id,
            facilityId: widget.facility?.id,
            department: _dept,
            checkIn: _checkIn,
          );
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Event created')));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _genericError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppState>().role;
    final canTarget = widget.club == null &&
        widget.facility == null &&
        (role == Role.professor || role == Role.superAdmin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppField(
          controller: _title,
          hint: 'Event title',
          icon: Icons.title_rounded,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _desc,
          hint: 'Description',
          icon: Icons.notes_rounded,
          maxLines: 4,
          keyboard: TextInputType.multiline,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _location,
          hint: 'Location',
          icon: Icons.location_on_rounded,
        ),
        const SizedBox(height: 16),
        const FormLabel('Date and time'),
        DateField(date: _date, onChanged: (d) => setState(() => _date = d)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TimeField(
                label: 'Starts',
                minutes: _start,
                onChanged: (m) => setState(() => _start = m),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TimeField(
                label: 'Ends',
                minutes: _end,
                onChanged: (m) => setState(() => _end = m),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const FormLabel('Category'),
        ChoiceWrap<EventCategory>(
          values: EventCategory.values,
          labelOf: (c) => c.label,
          colorOf: (c) => c.color,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: 16),
        if (canTarget) ...[
          const FormLabel('Audience'),
          ChoiceWrap<String?>(
            values: [null, ...AppConfig.departments],
            labelOf: (d) => d ?? 'Everyone',
            selected: _dept,
            onSelected: (d) => setState(() => _dept = d),
          ),
          const SizedBox(height: 16),
        ],
        ToggleRow(
          title: 'QR check-in',
          subtitle: 'Students scan a code on arrival to log their attendance.',
          value: _checkIn,
          onChanged: (v) => setState(() => _checkIn = v),
        ),
        FormError(_error),
        GradientButton(
          label: 'Create event',
          icon: Icons.event_available_rounded,
          loading: _busy,
          onTap: _submit,
        ),
      ],
    );
  }
}

// ───────────────────────── Emergency alerts ─────────────────────────

Future<void> showAlertSheet(BuildContext context, {Facility? facility}) {
  return showAppSheet<void>(
    context,
    title: 'Urgent banner',
    subtitle:
        'Pins a red banner on every student\'s home screen until you resolve it.',
    builder: (_) => _AlertForm(facility: facility),
  );
}

class _AlertForm extends StatefulWidget {
  const _AlertForm({this.facility});
  final Facility? facility;

  @override
  State<_AlertForm> createState() => _AlertFormState();
}

class _AlertFormState extends State<_AlertForm> {
  late final TextEditingController _title;
  final _message = TextEditingController();
  String? _facilityId;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _facilityId = widget.facility?.id;
    _title = TextEditingController(
      text: widget.facility != null ? '${widget.facility!.name} closed unexpectedly' : '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().length < 4) {
      setState(() => _error = 'Add a short headline.');
      return;
    }
    if (_message.text.trim().length < 5) {
      setState(() => _error = 'Tell students what is happening.');
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().triggerAlert(
            title: _title.text,
            message: _message.text,
            facilityId: _facilityId,
          );
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Banner is live')));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _genericError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pickScope = widget.facility == null && app.perms.isAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppField(
          controller: _title,
          hint: 'Headline',
          icon: Icons.warning_amber_rounded,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _message,
          hint: 'What happened? When will it reopen?',
          icon: Icons.notes_rounded,
          maxLines: 3,
          keyboard: TextInputType.multiline,
        ),
        const SizedBox(height: 16),
        if (pickScope) ...[
          const FormLabel('Concerns'),
          ChoiceWrap<String?>(
            values: [null, ...app.facilities.map((f) => f.id)],
            labelOf: (id) => id == null ? 'Campus-wide' : (app.facilityById(id)?.name ?? id),
            selected: _facilityId,
            onSelected: (id) => setState(() => _facilityId = id),
          ),
          const SizedBox(height: 16),
        ],
        FormError(_error),
        GradientButton(
          label: 'Publish urgent banner',
          icon: Icons.campaign_rounded,
          loading: _busy,
          onTap: _submit,
        ),
      ],
    );
  }
}

// ───────────────────────── Faculty / major ─────────────────────────

Future<void> showDepartmentPicker(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'Your faculty or major',
    subtitle:
        'Your news and events are filtered to your studies. You can switch the filter off any time.',
    builder: (_) => const _DepartmentPicker(),
  );
}

class _DepartmentPicker extends StatelessWidget {
  const _DepartmentPicker();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ChoiceWrap<String?>(
      values: [null, ...AppConfig.departments],
      labelOf: (d) => d ?? 'No filter',
      selected: app.myDepartment,
      onSelected: (d) async {
        await context.read<AppState>().setDepartment(d);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}

// ─── Facilities ────────────────────────────────────────────────────────────

Future<void> showFacilitySheet(BuildContext context, String facilityId) {
  final name = context.read<AppState>().facilityById(facilityId)?.name ?? 'Campus area';
  return showAppSheet<void>(
    context,
    title: name,
    builder: (_) => _FacilityPanel(id: facilityId),
  );
}

class _FacilityPanel extends StatefulWidget {
  const _FacilityPanel({required this.id});
  final String id;

  @override
  State<_FacilityPanel> createState() => _FacilityPanelState();
}

class _FacilityPanelState extends State<_FacilityPanel> {
  late FacilityStatus _status;
  late int _open;
  late int _close;
  late Set<int> _days;
  late final TextEditingController _note;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final f = context.read<AppState>().facilityById(widget.id);
    _status = f?.status ?? FacilityStatus.open;
    _open = f?.openMinute ?? 8 * 60;
    _close = f?.closeMinute ?? 18 * 60;
    _days = Set<int>.from(f?.days ?? {});
    _note = TextEditingController(text: f?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_days.isEmpty) {
      setState(() => _error = 'Pick at least one open day.');
      return;
    }
    if (_close <= _open) {
      setState(() => _error = 'Closing time must be after opening time.');
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().updateFacility(
        widget.id,
        status: _status,
        note: _note.text.trim(),
        openMinute: _open,
        closeMinute: _close,
        days: _days,
      );
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Updated for all students')));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _genericError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.palette;
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final f = app.facilityById(widget.id);
    if (f == null) {
      return Text('This area no longer exists.',
          style: AppText.body(14, color: AppColors.muted));
    }
    final live = f.liveAt(DateTime.now());
    final canManage = app.perms.canManageFacility(f.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Pill(label: live.label, color: live.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(f.hoursLabel,
                  style: AppText.body(13.5, color: AppColors.muted)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(f.description,
            style: AppText.body(15, height: 1.5, color: AppColors.muted)),
        const SizedBox(height: 14),
        _InfoLine(icon: Icons.location_on_rounded, text: f.location),
        if (f.contact != null) ...[
          const SizedBox(height: 8),
          _InfoLine(icon: Icons.mail_rounded, text: f.contact!),
        ],
        if (f.note.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: live.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: live.color.withValues(alpha: 0.3)),
            ),
            child: Text(f.note,
                style: AppText.body(14, color: live.color, height: 1.4)),
          ),
        ],
        if (f.updatedBy.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Updated by ${f.updatedBy}, ${timeAgo(f.updatedAt)}',
              style: AppText.body(12, color: AppColors.muted)),
        ],
        if (canManage) ...[
          const SizedBox(height: 22),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Text('Manage this area', style: AppText.display(17)),
            ],
          ),
          const SizedBox(height: 14),
          const FormLabel('Status'),
          ChoiceWrap<FacilityStatus>(
            values: FacilityStatus.values,
            labelOf: (s) => s.label,
            colorOf: (s) => s.color,
            selected: _status,
            onSelected: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: 14),
          AppField(
            controller: _note,
            hint: 'Message for students (optional)',
            icon: Icons.chat_bubble_outline_rounded,
          ),
          const SizedBox(height: 14),
          const FormLabel('Opening hours'),
          Row(
            children: [
              Expanded(
                child: TimeField(
                  label: 'Opens',
                  minutes: _open,
                  onChanged: (m) => setState(() => _open = m),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TimeField(
                  label: 'Closes',
                  minutes: _close,
                  onChanged: (m) => setState(() => _close = m),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const FormLabel('Open days'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 1; d <= 7; d++)
                GestureDetector(
                  onTap: () => setState(() {
                    if (!_days.remove(d)) _days.add(d);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _days.contains(d)
                          ? p.b.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _days.contains(d)
                            ? p.b
                            : Colors.white.withValues(alpha: 0.09),
                      ),
                    ),
                    child: Text(
                      dayNames[d - 1],
                      style: AppText.body(
                        13,
                        w: FontWeight.w600,
                        color: _days.contains(d) ? p.b : AppColors.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FormError(_error),
          GradientButton(
            label: 'Save changes',
            icon: Icons.check_rounded,
            loading: _busy,
            onTap: _save,
          ),
          const SizedBox(height: 12),
          if (app.perms.canTriggerAlert(f.id))
            GhostButton(
              label: 'Post an urgent banner',
              icon: Icons.campaign_rounded,
              color: AppColors.danger,
              onTap: () => showAlertSheet(context, facility: f),
            ),
          if (app.perms.canCreateEvent) ...[
            const SizedBox(height: 12),
            GhostButton(
              label: 'Create a session (QR check-in)',
              icon: Icons.qr_code_2_rounded,
              onTap: () => showCreateEventSheet(context, facility: f),
            ),
          ],
        ],
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.muted),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: AppText.body(14.5))),
    ],
  );
}

// ───────────────────────── Create a campus area (admin) ─────────────────────────

Future<void> showCreateFacilitySheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'New campus area',
    subtitle: 'It appears for every student right away. Assign a manager later from the Users tab.',
    builder: (_) => const _FacilityForm(),
  );
}

class _FacilityForm extends StatefulWidget {
  const _FacilityForm();

  @override
  State<_FacilityForm> createState() => _FacilityFormState();
}

class _FacilityFormState extends State<_FacilityForm> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _contact = TextEditingController();
  String _icon = 'place';
  int _open = 8 * 60;
  int _close = 18 * 60;
  final Set<int> _days = {1, 2, 3, 4, 5};
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _location.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 3) {
      setState(() => _error = 'Give the area a name.');
      return;
    }
    if (_location.text.trim().isEmpty) {
      setState(() => _error = 'Where is it on campus?');
      return;
    }
    if (_days.isEmpty) {
      setState(() => _error = 'Pick at least one open day.');
      return;
    }
    if (_close <= _open) {
      setState(() => _error = 'Closing time must be after opening time.');
      return;
    }
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.createFacility(Facility(
        id: app.uniqueFacilityId(_name.text),
        name: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? 'No description yet.' : _desc.text.trim(),
        iconKey: _icon,
        location: _location.text.trim(),
        openMinute: _open,
        closeMinute: _close,
        days: {..._days},
        contact: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      ));
      nav.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _genericError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppField(
          controller: _name,
          hint: 'Name (e.g. Swimming pool)',
          icon: Icons.store_mall_directory_rounded,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _desc,
          hint: 'Short description',
          icon: Icons.notes_rounded,
          maxLines: 3,
          keyboard: TextInputType.multiline,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _location,
          hint: 'Location on campus',
          icon: Icons.location_on_rounded,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _contact,
          hint: 'Contact email (optional)',
          icon: Icons.mail_rounded,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const FormLabel('Icon'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final k in kFacilityIconKeys)
              GestureDetector(
                onTap: () => setState(() => _icon = k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: k == _icon
                        ? p.b.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: k == _icon ? p.b : Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Icon(iconFor(k),
                      color: k == _icon ? p.b : AppColors.muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const FormLabel('Opening hours'),
        Row(
          children: [
            Expanded(
              child: TimeField(
                label: 'Opens',
                minutes: _open,
                onChanged: (m) => setState(() => _open = m),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TimeField(
                label: 'Closes',
                minutes: _close,
                onChanged: (m) => setState(() => _close = m),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const FormLabel('Open days'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var d = 1; d <= 7; d++)
              GestureDetector(
                onTap: () => setState(() {
                  if (!_days.remove(d)) _days.add(d);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _days.contains(d)
                        ? p.b.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: _days.contains(d)
                          ? p.b
                          : Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Text(
                    dayNames[d - 1],
                    style: AppText.body(
                      13,
                      w: FontWeight.w600,
                      color: _days.contains(d) ? p.b : AppColors.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FormError(_error),
        GradientButton(
          label: 'Create area',
          icon: Icons.add_business_rounded,
          loading: _busy,
          onTap: _submit,
        ),
      ],
    );
  }
}

// ───────────────────────── Clubs ─────────────────────────

Future<void> showEditClubSheet(BuildContext context, Club club) {
  return showAppSheet<void>(
    context,
    title: 'Edit club page',
    builder: (_) => _ClubEditForm(club: club),
  );
}

class _ClubEditForm extends StatefulWidget {
  const _ClubEditForm({required this.club});
  final Club club;

  @override
  State<_ClubEditForm> createState() => _ClubEditFormState();
}

class _ClubEditFormState extends State<_ClubEditForm> {
  late final TextEditingController _tagline =
      TextEditingController(text: widget.club.tagline);
  late final TextEditingController _desc =
      TextEditingController(text: widget.club.description);
  late final TextEditingController _email =
      TextEditingController(text: widget.club.email);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _tagline.dispose();
    _desc.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_tagline.text.trim().length < 3 || _desc.text.trim().length < 10) {
      setState(() => _error = 'Add a tagline and a description.');
      return;
    }
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().updateClubPage(
            widget.club.id,
            tagline: _tagline.text,
            description: _desc.text,
            email: _email.text,
          );
      nav.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _genericError;
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
          controller: _tagline,
          hint: 'Tagline',
          icon: Icons.short_text_rounded,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _desc,
          hint: 'About the club',
          icon: Icons.notes_rounded,
          maxLines: 6,
          keyboard: TextInputType.multiline,
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _email,
          hint: 'Contact email',
          icon: Icons.mail_rounded,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        FormError(_error),
        GradientButton(
          label: 'Save',
          icon: Icons.check_rounded,
          loading: _busy,
          onTap: _save,
        ),
      ],
    );
  }
}

Future<void> showClubUpdateSheet(BuildContext context, Club club) {
  return showAppSheet<void>(
    context,
    title: 'Post a club update',
    subtitle: 'Shown in the updates timeline on the club page.',
    builder: (_) => _ClubUpdateForm(club: club),
  );
}

class _ClubUpdateForm extends StatefulWidget {
  const _ClubUpdateForm({required this.club});
  final Club club;

  @override
  State<_ClubUpdateForm> createState() => _ClubUpdateFormState();
}

class _ClubUpdateFormState extends State<_ClubUpdateForm> {
  final _text = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_text.text.trim().length < 5) {
      setState(() => _error = 'Write a short update.');
      return;
    }
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().postClubUpdate(widget.club.id, _text.text);
      nav.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _genericError;
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
          controller: _text,
          hint: 'What is new?',
          icon: Icons.campaign_rounded,
          maxLines: 4,
          keyboard: TextInputType.multiline,
        ),
        const SizedBox(height: 18),
        FormError(_error),
        GradientButton(
          label: 'Post update',
          icon: Icons.send_rounded,
          loading: _busy,
          onTap: _post,
        ),
      ],
    );
  }
}
