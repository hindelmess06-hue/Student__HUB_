import 'package:flutter/material.dart';

import '../utils/icons.dart';


/// A raw database document: a JSON-like map. `id` is injected on read.
typedef Doc = Map<String, dynamic>;

DateTime _dt(Object? v) =>
    (v is String ? DateTime.tryParse(v) : null) ?? DateTime.now();
DateTime? _dtn(Object? v) => v is String ? DateTime.tryParse(v) : null;
String _s(Object? v, [String d = '']) => v is String ? v : d;
String? _sn(Object? v) => v is String && v.isNotEmpty ? v : null;
int _i(Object? v, [int d = 0]) => v is num ? v.toInt() : d;
bool _b(Object? v, [bool d = false]) => v is bool ? v : d;

// ───────────────────────── Roles ─────────────────────────

enum Role { student, facilityManager, professor, clubLeader, superAdmin }

extension RoleX on Role {
  /// The value stored in the database (`role: "facility_manager"`).
  String get wire => switch (this) {
        Role.student => 'student',
        Role.facilityManager => 'facility_manager',
        Role.professor => 'professor',
        Role.clubLeader => 'club_leader',
        Role.superAdmin => 'super_admin',
      };

  String get label => switch (this) {
        Role.student => 'Student',
        Role.facilityManager => 'Facility manager',
        Role.professor => 'Professor',
        Role.clubLeader => 'Club leader',
        Role.superAdmin => 'Super admin',
      };

  IconData get icon => switch (this) {
        Role.student => Icons.school_rounded,
        Role.facilityManager => Icons.store_mall_directory_rounded,
        Role.professor => Icons.menu_book_rounded,
        Role.clubLeader => Icons.groups_rounded,
        Role.superAdmin => Icons.admin_panel_settings_rounded,
      };

  Color get color => switch (this) {
        Role.student => const Color(0xFF9393AB),
        Role.facilityManager => const Color(0xFFFFB84D),
        Role.professor => const Color(0xFF8B7BFF),
        Role.clubLeader => const Color(0xFF22D3EE),
        Role.superAdmin => const Color(0xFFFF5C7A),
      };

  /// What the person is allowed to request from the profile screen.
  static const List<Role> requestable = [
    Role.facilityManager,
    Role.professor,
    Role.clubLeader,
  ];

  static Role parse(Object? v) =>
      Role.values.firstWhere((r) => r.wire == v, orElse: () => Role.student);
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    this.role = Role.student,
    this.assignedEntity,
    this.department,
  });

  final String uid;
  final String email;
  final String name;
  final Role role;

  /// Facility id (facility_manager) or club id (club_leader).
  final String? assignedEntity;

  /// Faculty / major chosen by the person (used to filter the feed).
  final String? department;
  final DateTime createdAt;

  Doc toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role.wire,
        'assignedEntity': assignedEntity,
        'department': department,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Doc m) => UserProfile(
        uid: _s(m['uid'], _s(m['id'])),
        email: _s(m['email']),
        name: _s(m['name']),
        role: RoleX.parse(m['role']),
        assignedEntity: _sn(m['assignedEntity']),
        department: _sn(m['department']),
        createdAt: _dt(m['createdAt']),
      );
}

// ───────────────────────── Role requests ("Demande") ─────────────────────────

enum RequestStatus { pending, approved, rejected }

class RoleRequest {
  RoleRequest({
    required this.id,
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.justification,
    required this.createdAt,
    this.target,
    this.status = RequestStatus.pending,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
    this.grantedEntity,
  });

  final String id;
  final String uid;
  final String email;
  final String name;

  /// The role being asked for.
  final Role role;

  /// Facility or club the person asked for (a hint for the admin).
  final String? target;
  final String justification;
  final DateTime createdAt;
  final RequestStatus status;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;
  final String? grantedEntity;

  Doc toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role.wire,
        'target': target,
        'justification': justification,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'decidedBy': decidedBy,
        'decidedAt': decidedAt?.toIso8601String(),
        'decisionNote': decisionNote,
        'grantedEntity': grantedEntity,
      };

  factory RoleRequest.fromMap(Doc m) => RoleRequest(
        id: _s(m['id']),
        uid: _s(m['uid']),
        email: _s(m['email']),
        name: _s(m['name']),
        role: RoleX.parse(m['role']),
        target: _sn(m['target']),
        justification: _s(m['justification']),
        createdAt: _dt(m['createdAt']),
        status: RequestStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => RequestStatus.pending,
        ),
        decidedBy: _sn(m['decidedBy']),
        decidedAt: _dtn(m['decidedAt']),
        decisionNote: _sn(m['decisionNote']),
        grantedEntity: _sn(m['grantedEntity']),
      );
}

// ───────────────────────── Announcements ─────────────────────────

enum AnnCategory { academic, administration, careers, campusLife, urgent }

extension AnnCategoryX on AnnCategory {
  String get label => switch (this) {
        AnnCategory.academic => 'Academic',
        AnnCategory.administration => 'Administration',
        AnnCategory.careers => 'Careers',
        AnnCategory.campusLife => 'Campus life',
        AnnCategory.urgent => 'Urgent',
      };

  IconData get icon => switch (this) {
        AnnCategory.academic => Icons.school_rounded,
        AnnCategory.administration => Icons.account_balance_rounded,
        AnnCategory.careers => Icons.work_rounded,
        AnnCategory.campusLife => Icons.celebration_rounded,
        AnnCategory.urgent => Icons.priority_high_rounded,
      };

  Color get color => switch (this) {
        AnnCategory.academic => const Color(0xFF8B7BFF),
        AnnCategory.administration => const Color(0xFF38BDF8),
        AnnCategory.careers => const Color(0xFF34D399),
        AnnCategory.campusLife => const Color(0xFFFF7AB6),
        AnnCategory.urgent => const Color(0xFFFF5C7A),
      };
}

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.category,
    required this.date,
    this.pinned = false,
    this.highPriority = false,
    this.department,
    this.clubId,
    this.authorUid = 'system',
    this.authorRole = 'super_admin',
  });

  final String id;
  final String title;
  final String body;
  final String author;
  final AnnCategory category;
  final DateTime date;
  final bool pinned;

  /// Professors / admins can flag an announcement as high priority.
  final bool highPriority;

  /// null = for everyone. Otherwise only that faculty sees it by default.
  final String? department;
  final String? clubId;
  final String authorUid;
  final String authorRole;

  String get excerpt {
    final flat = body.replaceAll('\n', ' ').trim();
    return flat.length <= 110 ? flat : '${flat.substring(0, 107)}...';
  }

  Doc toMap() => {
        'title': title,
        'body': body,
        'author': author,
        'category': category.name,
        'date': date.toIso8601String(),
        'pinned': pinned,
        'highPriority': highPriority,
        'department': department,
        'clubId': clubId,
        'authorUid': authorUid,
        'authorRole': authorRole,
      };

  factory Announcement.fromMap(Doc m) => Announcement(
        id: _s(m['id']),
        title: _s(m['title']),
        body: _s(m['body']),
        author: _s(m['author']),
        category: AnnCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => AnnCategory.campusLife,
        ),
        date: _dt(m['date']),
        pinned: _b(m['pinned']),
        highPriority: _b(m['highPriority']),
        department: _sn(m['department']),
        clubId: _sn(m['clubId']),
        authorUid: _s(m['authorUid'], 'system'),
        authorRole: _s(m['authorRole'], 'super_admin'),
      );
}

// ───────────────────────── Events ─────────────────────────

enum EventCategory { academic, cultural, sport, workshop, career }

extension EventCategoryX on EventCategory {
  String get label => switch (this) {
        EventCategory.academic => 'Academic',
        EventCategory.cultural => 'Cultural',
        EventCategory.sport => 'Sport',
        EventCategory.workshop => 'Workshop',
        EventCategory.career => 'Career',
      };

  IconData get icon => switch (this) {
        EventCategory.academic => Icons.school_rounded,
        EventCategory.cultural => Icons.theater_comedy_rounded,
        EventCategory.sport => Icons.sports_soccer_rounded,
        EventCategory.workshop => Icons.build_rounded,
        EventCategory.career => Icons.work_rounded,
      };

  Color get color => switch (this) {
        EventCategory.academic => const Color(0xFF8B7BFF),
        EventCategory.cultural => const Color(0xFFFF7AB6),
        EventCategory.sport => const Color(0xFFFFB84D),
        EventCategory.workshop => const Color(0xFF22D3EE),
        EventCategory.career => const Color(0xFF34D399),
      };
}

class CampusEvent {
  CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.organizer,
    required this.category,
    required this.start,
    required this.end,
    this.clubId,
    this.facilityId,
    this.department,
    this.createdBy = 'system',
    this.checkInEnabled = false,
    this.baseGoing = 0,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String organizer;
  final EventCategory category;
  final DateTime start;
  final DateTime end;
  final String? clubId;
  final String? facilityId;

  /// null = whole university; otherwise a faculty-wide event.
  final String? department;
  final String createdBy;

  /// true while the organiser has an active QR check-in session.
  final bool checkInEnabled;
  final int baseGoing;

  String get timeRange => '${_t(start)} - ${_t(end)}';

  static String _t(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Doc toMap() => {
        'title': title,
        'description': description,
        'location': location,
        'organizer': organizer,
        'category': category.name,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'clubId': clubId,
        'facilityId': facilityId,
        'department': department,
        'createdBy': createdBy,
        'checkInEnabled': checkInEnabled,
        'baseGoing': baseGoing,
      };

  factory CampusEvent.fromMap(Doc m) => CampusEvent(
        id: _s(m['id']),
        title: _s(m['title']),
        description: _s(m['description']),
        location: _s(m['location']),
        organizer: _s(m['organizer']),
        category: EventCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => EventCategory.academic,
        ),
        start: _dt(m['start']),
        end: _dt(m['end']),
        clubId: _sn(m['clubId']),
        facilityId: _sn(m['facilityId']),
        department: _sn(m['department']),
        createdBy: _s(m['createdBy'], 'system'),
        checkInEnabled: _b(m['checkInEnabled']),
        baseGoing: _i(m['baseGoing']),
      );
}

class CheckIn {
  CheckIn({
    required this.eventId,
    required this.uid,
    required this.name,
    required this.email,
    required this.at,
  });

  final String eventId;
  final String uid;
  final String name;
  final String email;
  final DateTime at;

  factory CheckIn.fromMap(Doc m) => CheckIn(
        eventId: _s(m['eventId']),
        uid: _s(m['uid']),
        name: _s(m['name']),
        email: _s(m['email']),
        at: _dt(m['at']),
      );
}

// ───────────────────────── Clubs ─────────────────────────

enum ClubCategory { tech, arts, sport, social, science }

extension ClubCategoryX on ClubCategory {
  String get label => switch (this) {
        ClubCategory.tech => 'Tech',
        ClubCategory.arts => 'Arts',
        ClubCategory.sport => 'Sport',
        ClubCategory.social => 'Social',
        ClubCategory.science => 'Science',
      };
}

class ClubUpdate {
  ClubUpdate({required this.text, required this.date});
  final String text;
  final DateTime date;

  Doc toMap() => {'text': text, 'date': date.toIso8601String()};
}

class Club {
  Club({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.members,
    required this.color,
    required this.iconKey,
    required this.president,
    required this.email,
    required this.updates,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final ClubCategory category;
  final int members;
  final Color color;
  final String iconKey;
  final String president;
  final String email;
  final List<ClubUpdate> updates;

  IconData get icon => iconFor(iconKey);

  Doc toMap() => {
        'name': name,
        'tagline': tagline,
        'description': description,
        'category': category.name,
        'members': members,
        'color': color.toARGB32(),
        'iconKey': iconKey,
        'president': president,
        'email': email,
        'updates': updates.map((u) => u.toMap()).toList(),
      };

  factory Club.fromMap(Doc m) => Club(
        id: _s(m['id']),
        name: _s(m['name']),
        tagline: _s(m['tagline']),
        description: _s(m['description']),
        category: ClubCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => ClubCategory.social,
        ),
        members: _i(m['members']),
        color: Color(_i(m['color'], 0xFF7C5CFF)),
        iconKey: _s(m['iconKey'], 'groups'),
        president: _s(m['president'], 'Club leader'),
        email: _s(m['email']),
        updates: ((m['updates'] as List?) ?? const []).map((e) {
          final u = Map<String, dynamic>.from(e as Map);
          return ClubUpdate(text: _s(u['text']), date: _dt(u['date']));
        }).toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      );
}

// ───────────────────────── Campus facilities ─────────────────────────

/// What a facility manager sets. `open` means "follow the normal hours".
enum FacilityStatus { open, closed, maintenance }

/// What students actually see right now.
enum LiveStatus { open, closed, maintenance }

extension LiveStatusX on LiveStatus {
  String get label => switch (this) {
        LiveStatus.open => 'Open',
        LiveStatus.closed => 'Closed',
        LiveStatus.maintenance => 'Maintenance',
      };

  Color get color => switch (this) {
        LiveStatus.open => const Color(0xFF34D399),
        LiveStatus.closed => const Color(0xFF9393AB),
        LiveStatus.maintenance => const Color(0xFFFFB84D),
      };
}

extension FacilityStatusX on FacilityStatus {
  String get label => switch (this) {
        FacilityStatus.open => 'Open',
        FacilityStatus.closed => 'Closed',
        FacilityStatus.maintenance => 'Maintenance',
      };

  Color get color => switch (this) {
        FacilityStatus.open => const Color(0xFF34D399),
        FacilityStatus.closed => const Color(0xFFFF5C7A),
        FacilityStatus.maintenance => const Color(0xFFFFB84D),
      };
}

class Facility {
  Facility({
    required this.id,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.location,
    required this.openMinute,
    required this.closeMinute,
    required this.days,
    this.contact,
    this.status = FacilityStatus.open,
    this.note = '',
    this.updatedBy = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final String location;

  /// Minutes since midnight. 0 and 1440 = open all day.
  final int openMinute;
  final int closeMinute;

  /// DateTime.weekday values: 1 = Monday ... 7 = Sunday.
  final Set<int> days;
  final String? contact;
  final FacilityStatus status;

  /// Short message from the manager ("Closed early, water leak").
  final String note;
  final String updatedBy;
  final DateTime updatedAt;

  IconData get icon => iconFor(iconKey);

  bool withinSchedule(DateTime t) {
    if (!days.contains(t.weekday)) return false;
    final m = t.hour * 60 + t.minute;
    return m >= openMinute && m < closeMinute;
  }

  LiveStatus liveAt(DateTime t) {
    if (status == FacilityStatus.maintenance) return LiveStatus.maintenance;
    if (status == FacilityStatus.closed) return LiveStatus.closed;
    return withinSchedule(t) ? LiveStatus.open : LiveStatus.closed;
  }

  static String fmtMinutes(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  String get hoursLabel {
    final allDay = openMinute == 0 && closeMinute >= 1440;
    final range =
        allDay ? '24h' : '${fmtMinutes(openMinute)} - ${fmtMinutes(closeMinute)}';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    if (sorted.isEmpty) return 'Closed';
    if (sorted.length == 7) return 'Every day, $range';
    final isRun = sorted.last - sorted.first == sorted.length - 1;
    if (isRun && sorted.length > 1) {
      return '${names[sorted.first - 1]} - ${names[sorted.last - 1]}, $range';
    }
    return '${sorted.map((d) => names[d - 1]).join(', ')}, $range';
  }

  Doc toMap() => {
        'name': name,
        'description': description,
        'iconKey': iconKey,
        'location': location,
        'openMinute': openMinute,
        'closeMinute': closeMinute,
        'days': (days.toList()..sort()),
        'contact': contact,
        'status': status.name,
        'note': note,
        'updatedBy': updatedBy,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Facility.fromMap(Doc m) => Facility(
        id: _s(m['id']),
        name: _s(m['name']),
        description: _s(m['description']),
        iconKey: _s(m['iconKey'], 'place'),
        location: _s(m['location']),
        openMinute: _i(m['openMinute'], 8 * 60),
        closeMinute: _i(m['closeMinute'], 18 * 60),
        days: ((m['days'] as List?) ?? const [1, 2, 3, 4, 5])
            .map((e) => (e as num).toInt())
            .toSet(),
        contact: _sn(m['contact']),
        status: FacilityStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => FacilityStatus.open,
        ),
        note: _s(m['note']),
        updatedBy: _s(m['updatedBy']),
        updatedAt: _dt(m['updatedAt']),
      );
}

class CampusContact {
  CampusContact({
    required this.name,
    required this.role,
    required this.email,
    required this.icon,
  });

  final String name;
  final String role;
  final String email;
  final IconData icon;
}

// ───────────────────────── Alerts & audit log ─────────────────────────

/// An urgent banner pinned on every student's home screen.
class CampusAlert {
  CampusAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.facilityId,
    this.active = true,
  });

  final String id;
  final String title;
  final String message;
  final String? facilityId;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool active;

  Doc toMap() => {
        'title': title,
        'message': message,
        'facilityId': facilityId,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'active': active,
      };

  factory CampusAlert.fromMap(Doc m) => CampusAlert(
        id: _s(m['id']),
        title: _s(m['title']),
        message: _s(m['message']),
        facilityId: _sn(m['facilityId']),
        createdBy: _s(m['createdBy']),
        createdByName: _s(m['createdByName']),
        createdAt: _dt(m['createdAt']),
        active: _b(m['active'], true),
      );
}

class LogEntry {
  LogEntry({
    required this.id,
    required this.actorUid,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.at,
  });

  final String id;
  final String actorUid;
  final String actorName;
  final Role actorRole;
  final String action;
  final DateTime at;

  Doc toMap() => {
        'actorUid': actorUid,
        'actorName': actorName,
        'actorRole': actorRole.wire,
        'action': action,
        'at': at.toIso8601String(),
      };

  factory LogEntry.fromMap(Doc m) => LogEntry(
        id: _s(m['id']),
        actorUid: _s(m['actorUid']),
        actorName: _s(m['actorName']),
        actorRole: RoleX.parse(m['actorRole']),
        action: _s(m['action']),
        at: _dt(m['at']),
      );
}
