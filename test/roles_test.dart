import 'package:flutter_test/flutter_test.dart';
import 'package:student_hub/models/models.dart';
import 'package:student_hub/services/permissions.dart';

UserProfile _user(Role role, [String? entity]) => UserProfile(
      uid: 'u1',
      email: 'someone@ueuromed.org',
      name: 'Someone',
      role: role,
      assignedEntity: entity,
      createdAt: DateTime(2026, 1, 1),
    );

Facility _facility({
  FacilityStatus status = FacilityStatus.open,
  int open = 8 * 60,
  int close = 20 * 60,
  Set<int> days = const {1, 2, 3, 4, 5},
}) =>
    Facility(
      id: 'library',
      name: 'Library',
      description: '',
      iconKey: 'library',
      location: '',
      openMinute: open,
      closeMinute: close,
      days: days,
      status: status,
    );

void main() {
  group('Role wire format', () {
    test('round-trips', () {
      for (final r in Role.values) {
        expect(RoleX.parse(r.wire), r);
      }
      expect(RoleX.parse('facility_manager'), Role.facilityManager);
      expect(RoleX.parse('club_leader'), Role.clubLeader);
      expect(RoleX.parse('nonsense'), Role.student);
      expect(RoleX.parse(null), Role.student);
    });
  });

  group('Perms', () {
    test('student can only browse', () {
      final p = Perms(_user(Role.student));
      expect(p.isStaff, isFalse);
      expect(p.canPostAnnouncement, isFalse);
      expect(p.canCreateEvent, isFalse);
      expect(p.canManageFacility('library'), isFalse);
      expect(p.canManageClub('devhub'), isFalse);
      expect(p.canTriggerAlert('library'), isFalse);
      expect(p.usesFacultyFilter, isTrue);
    });

    test('facility manager is scoped to ONE facility', () {
      final p = Perms(_user(Role.facilityManager, 'library'));
      expect(p.canManageFacility('library'), isTrue);
      expect(p.canManageFacility('gym'), isFalse);
      expect(p.canTriggerAlert('library'), isTrue);
      expect(p.canTriggerAlert('gym'), isFalse);
      expect(p.canTriggerAlert(null), isFalse, reason: 'campus-wide is admin only');
      expect(p.canManageClub('devhub'), isFalse);
      expect(p.canPostAnnouncement, isFalse);
    });

    test('club leader is scoped to ONE club', () {
      final p = Perms(_user(Role.clubLeader, 'devhub'));
      expect(p.canManageClub('devhub'), isTrue);
      expect(p.canManageClub('harmony'), isFalse);
      expect(p.canPostAnnouncement, isTrue);
      expect(p.canCreateEvent, isTrue);
      expect(p.canManageFacility('library'), isFalse);
    });

    test('professor posts announcements and events, nothing else', () {
      final p = Perms(_user(Role.professor));
      expect(p.canPostAnnouncement, isTrue);
      expect(p.canCreateEvent, isTrue);
      expect(p.canManageFacility('library'), isFalse);
      expect(p.canManageClub('devhub'), isFalse);
      expect(p.isAdmin, isFalse);
    });

    test('super admin can do everything', () {
      final p = Perms(_user(Role.superAdmin));
      expect(p.isAdmin, isTrue);
      expect(p.canManageFacility('anything'), isTrue);
      expect(p.canManageClub('anything'), isTrue);
      expect(p.canTriggerAlert(null), isTrue);
      expect(p.usesFacultyFilter, isFalse);
    });

    test('only the author or an admin manages an event', () {
      final e = CampusEvent(
        id: 'e1',
        title: 't',
        description: 'd',
        location: 'l',
        organizer: 'o',
        category: EventCategory.workshop,
        start: DateTime(2026, 1, 1, 10),
        end: DateTime(2026, 1, 1, 11),
        createdBy: 'u1',
      );
      expect(Perms(_user(Role.clubLeader, 'x')).canManageEvent(e), isTrue);
      expect(
        Perms(UserProfile(
          uid: 'other',
          email: 'o@ueuromed.org',
          name: 'O',
          createdAt: DateTime(2026),
          role: Role.clubLeader,
          assignedEntity: 'x',
        )).canManageEvent(e),
        isFalse,
      );
    });
  });

  group('Facility live status', () {
    final monday10 = DateTime(2026, 11, 16, 10, 0); // a Monday
    final monday21 = DateTime(2026, 11, 16, 21, 0);
    final sunday10 = DateTime(2026, 11, 15, 10, 0);

    test('follows the schedule when set to open', () {
      final f = _facility();
      expect(f.liveAt(monday10), LiveStatus.open);
      expect(f.liveAt(monday21), LiveStatus.closed);
      expect(f.liveAt(sunday10), LiveStatus.closed);
    });

    test('manual closed and maintenance override the schedule', () {
      expect(_facility(status: FacilityStatus.closed).liveAt(monday10),
          LiveStatus.closed);
      expect(_facility(status: FacilityStatus.maintenance).liveAt(monday10),
          LiveStatus.maintenance);
    });

    test('24h facility is always open', () {
      final f = _facility(
          open: 0, close: 1440, days: const {1, 2, 3, 4, 5, 6, 7});
      expect(f.liveAt(DateTime(2026, 11, 15, 3, 30)), LiveStatus.open);
      expect(f.hoursLabel, 'Every day, 24h');
    });

    test('hours label', () {
      expect(_facility().hoursLabel, 'Mon - Fri, 08:00 - 20:00');
    });

    test('survives a map round trip', () {
      final f = _facility(status: FacilityStatus.maintenance);
      final back = Facility.fromMap({...f.toMap(), 'id': f.id});
      expect(back.status, FacilityStatus.maintenance);
      expect(back.days, f.days);
      expect(back.openMinute, f.openMinute);
    });
  });

  group('Documents', () {
    test('role request round trip', () {
      final r = RoleRequest(
        id: 'r1',
        uid: 'u1',
        email: 'a@ueuromed.org',
        name: 'A',
        role: Role.facilityManager,
        target: 'gym',
        justification: 'I work at the gym',
        createdAt: DateTime(2026, 5, 1),
      );
      final back = RoleRequest.fromMap({...r.toMap(), 'id': 'r1'});
      expect(back.role, Role.facilityManager);
      expect(back.target, 'gym');
      expect(back.status, RequestStatus.pending);
    });

    test('announcement keeps department and priority', () {
      final a = Announcement(
        id: 'n1',
        title: 'T',
        body: 'B',
        author: 'A',
        category: AnnCategory.academic,
        date: DateTime(2026, 5, 1),
        highPriority: true,
        department: 'Civil Engineering',
      );
      final back = Announcement.fromMap({...a.toMap(), 'id': 'n1'});
      expect(back.highPriority, isTrue);
      expect(back.department, 'Civil Engineering');
    });
  });
}
