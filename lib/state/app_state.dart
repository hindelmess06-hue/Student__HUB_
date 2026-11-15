import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../data/seed_data.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/data_store.dart';
import '../services/permissions.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

enum AuthStatus { loading, signedOut, needsVerification, signedIn }

enum CheckInResult { ok, already, invalid, closed, error }

class AppState extends ChangeNotifier {
  AppState(this.prefs, this.auth, this.store);

  final SharedPreferences prefs;
  final AuthService auth;
  final DataStore store;

  static const _kPalette = 'palette';
  static const _kFollowed = 'followed_clubs';
  static const _kGoing = 'going_events';
  static const _kSaved = 'saved_news';
  static const _kRead = 'read_news';
  static const _kAllDeps = 'show_all_departments';

  AuthStatus status = AuthStatus.loading;
  AuthUser? user;
  UserProfile? profile;

  int paletteIndex = 0;
  Palette get palette => Palette.all[paletteIndex];

  // Personal, per-device preferences.
  Set<String> followedClubs = {};
  Set<String> goingEvents = {};
  Set<String> savedNews = {};
  Set<String> readNews = {};
  bool showAllDepartments = false;

  // Shared, live data (from the store).
  List<Announcement> _news = [];
  List<CampusEvent> _events = [];
  List<Club> _clubs = [];
  List<Facility> _facilities = [];
  List<CampusAlert> _alerts = [];
  List<RoleRequest> myRequests = [];
  Set<String> myCheckIns = {};

  // Super admin only.
  List<RoleRequest> allRequests = [];
  List<UserProfile> allUsers = [];
  List<LogEntry> logs = [];

  final List<StreamSubscription<List<Doc>>> _subs = [];
  final List<StreamSubscription<List<Doc>>> _adminSubs = [];
  bool _adminListening = false;

  // ───────────── Boot & auth ─────────────

  Future<void> init() async {
    final idx = prefs.getInt(_kPalette) ?? 0;
    paletteIndex = (idx >= 0 && idx < Palette.all.length) ? idx : 0;
    followedClubs = (prefs.getStringList(_kFollowed) ?? []).toSet();
    goingEvents = (prefs.getStringList(_kGoing) ?? []).toSet();
    savedNews = (prefs.getStringList(_kSaved) ?? []).toSet();
    readNews = (prefs.getStringList(_kRead) ?? []).toSet();
    showAllDepartments = prefs.getBool(_kAllDeps) ?? false;

    AuthUser? u;
    try {
      u = await auth.currentUser();
    } catch (_) {
      u = null;
    }
    await _finishAuth(u);
  }

  /// Single place that decides where the person lands after any auth change.
  Future<void> _finishAuth(AuthUser? u) async {
    user = u;
    if (u == null) {
      _stop();
      profile = null;
      status = AuthStatus.signedOut;
    } else if (!u.verified) {
      _stop();
      status = AuthStatus.needsVerification;
    } else {
      await _bootstrap(u);
      status = AuthStatus.signedIn;
    }
    notifyListeners();
  }

  Future<void> signUp(String name, String email, String password) async {
    final u = await auth.signUp(name: name, email: email, password: password);
    await _finishAuth(u);
  }

  Future<void> signIn(String email, String password) async {
    final u = await auth.signIn(email: email, password: password);
    await _finishAuth(u);
  }

  Future<void> resendVerification() async {
    await auth.sendVerification();
    notifyListeners();
  }

  Future<bool> refreshVerification() async {
    try {
      final ok = await auth.checkVerified();
      if (ok) await _finishAuth(await auth.currentUser());
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitCode(String code) async {
    final ok = await auth.submitCode(code);
    if (ok) await _finishAuth(await auth.currentUser());
    return ok;
  }

  Future<void> resetPassword(String email) => auth.sendPasswordReset(email);

  Future<void> discardUnverified() async {
    await auth.discardUnverified();
    await _finishAuth(null);
  }

  Future<void> signOut() async {
    await auth.signOut();
    await _finishAuth(null);
  }

  // ───────────── Live data plumbing ─────────────

  Future<void> _bootstrap(AuthUser u) async {
    _stop();
    try {
      if (!AppConfig.useFirebase) await _seedIfEmpty();
    } catch (_) {}

    // Make sure the person has a profile document.
    Doc? doc;
    try {
      doc = await store.get('users', u.uid);
    } catch (_) {}
    if (doc == null) {
      final boot = !AppConfig.useFirebase &&
          AppConfig.demoSuperAdminEmails.contains(u.email);
      final p = UserProfile(
        uid: u.uid,
        email: u.email,
        name: u.name,
        role: boot ? Role.superAdmin : Role.student,
        createdAt: DateTime.now(),
      );
      try {
        await store.set('users', u.uid, p.toMap());
      } catch (_) {}
      profile = p;
    } else {
      profile = UserProfile.fromMap(doc);
    }

    await Future.wait([
      _sub('users', (d) {
        if (d.isNotEmpty) {
          profile = UserProfile.fromMap(d.first);
          _syncAdminSubs();
        }
      }, field: 'uid', equals: u.uid),
      _sub('announcements', (d) => _news = _parse(d, Announcement.fromMap)),
      _sub('events', (d) => _events = _parse(d, CampusEvent.fromMap)),
      _sub('clubs', (d) => _clubs = _parse(d, Club.fromMap)),
      _sub('facilities', (d) => _facilities = _parse(d, Facility.fromMap)),
      _sub('alerts', (d) => _alerts = _parse(d, CampusAlert.fromMap)),
      _sub('requests', (d) {
        myRequests = _parse(d, RoleRequest.fromMap)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }, field: 'uid', equals: u.uid),
      _sub('checkins', (d) {
        myCheckIns = d.map((e) => '${e['eventId']}').toSet();
      }, field: 'uid', equals: u.uid),
    ]);
    _syncAdminSubs();
  }

  List<T> _parse<T>(List<Doc> docs, T Function(Doc) f) {
    final out = <T>[];
    for (final d in docs) {
      try {
        out.add(f(d));
      } catch (_) {}
    }
    return out;
  }

  StreamSubscription<List<Doc>> _listen(
    String collection,
    void Function(List<Doc>) onData, {
    String? field,
    Object? equals,
    void Function()? first,
  }) {
    var got = false;
    return store.watch(collection, field: field, equals: equals).listen(
      (d) {
        onData(d);
        if (!got) {
          got = true;
          first?.call();
        }
        notifyListeners();
      },
      onError: (_) {
        if (!got) {
          got = true;
          first?.call();
        }
      },
    );
  }

  Future<void> _sub(
    String collection,
    void Function(List<Doc>) onData, {
    String? field,
    Object? equals,
  }) {
    final done = Completer<void>();
    _subs.add(_listen(collection, onData,
        field: field, equals: equals, first: () => done.complete()));
    return done.future.timeout(const Duration(seconds: 6), onTimeout: () {});
  }

  /// Super admins also listen to every user, every request and the log.
  void _syncAdminSubs() {
    final admin = profile?.role == Role.superAdmin;
    if (admin && !_adminListening) {
      _adminListening = true;
      _adminSubs.add(_listen('users', (d) {
        allUsers = _parse(d, UserProfile.fromMap)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }));
      _adminSubs.add(_listen('requests', (d) {
        allRequests = _parse(d, RoleRequest.fromMap)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }));
      _adminSubs.add(_listen('logs', (d) {
        logs = _parse(d, LogEntry.fromMap)
          ..sort((a, b) => b.at.compareTo(a.at));
      }));
    } else if (!admin && _adminListening) {
      _cancelAdmin();
    }
  }

  void _cancelAdmin() {
    for (final s in _adminSubs) {
      s.cancel();
    }
    _adminSubs.clear();
    _adminListening = false;
    allUsers = [];
    allRequests = [];
    logs = [];
  }

  void _stop() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _cancelAdmin();
    _news = [];
    _events = [];
    _clubs = [];
    _facilities = [];
    _alerts = [];
    myRequests = [];
    myCheckIns = {};
  }

  // ───────────── Seed ─────────────

  Future<void> _seedIfEmpty() async {
    if (await store.isEmpty('clubs')) await _writeSeed();
  }

  Future<void> _writeSeed() async {
    await store.setMany('announcements',
        {for (final a in SeedData.announcements) a.id: a.toMap()});
    await store.setMany(
        'events', {for (final e in SeedData.events) e.id: e.toMap()});
    await store.setMany(
        'clubs', {for (final c in SeedData.clubs) c.id: c.toMap()});
    await store.setMany('facilities',
        {for (final f in SeedData.facilities) f.id: f.toMap()});
  }

  /// Super admin: (re)load the sample content. Overwrites same-id items.
  Future<void> importSampleContent() async {
    await _writeSeed();
    await _log('imported the sample content');
  }

  // ───────────── Derived state ─────────────

  Perms get perms => Perms(profile);
  Role get role => profile?.role ?? Role.student;
  String? get myDepartment => profile?.department;

  /// Students with a faculty selected only see their faculty + global items,
  /// unless they switch the filter off.
  bool get filterByDepartment =>
      perms.usesFacultyFilter && myDepartment != null && !showAllDepartments;

  bool _deptVisible(String? d) =>
      d == null || !filterByDepartment || d == myDepartment;

  /// Pinned first, then newest.
  List<Announcement> get announcements {
    final all = _news.where((a) => _deptVisible(a.department)).toList();
    all.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (a.highPriority != b.highPriority) return a.highPriority ? -1 : 1;
      return b.date.compareTo(a.date);
    });
    return all;
  }

  List<Announcement> get latestNews {
    final all = _news.where((a) => _deptVisible(a.department)).toList();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  Announcement? announcementById(String id) {
    for (final a in _news) {
      if (a.id == id) return a;
    }
    return null;
  }

  int get unreadCount =>
      announcements.where((a) => !readNews.contains(a.id)).length;

  List<CampusEvent> get events {
    final all = _events.where((e) => _deptVisible(e.department)).toList();
    all.sort((a, b) => a.start.compareTo(b.start));
    return all;
  }

  List<CampusEvent> get upcomingEvents {
    final now = DateTime.now();
    return events.where((e) => e.end.isAfter(now)).toList();
  }

  CampusEvent? eventById(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<CampusEvent> eventsForClub(String clubId) =>
      upcomingEvents.where((e) => e.clubId == clubId).toList();

  List<Club> get clubs {
    final all = [..._clubs];
    all.sort((a, b) => b.members.compareTo(a.members));
    return all;
  }

  Club? clubById(String? id) {
    if (id == null) return null;
    for (final c in _clubs) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Facility> get facilities {
    final all = [..._facilities];
    all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return all;
  }

  Facility? facilityById(String? id) {
    if (id == null) return null;
    for (final f in _facilities) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<CampusAlert> get activeAlerts {
    final all = _alerts.where((a) => a.active).toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  int get pendingRequestCount =>
      allRequests.where((r) => r.status == RequestStatus.pending).length;

  RoleRequest? get myPendingRequest {
    for (final r in myRequests) {
      if (r.status == RequestStatus.pending) return r;
    }
    return null;
  }

  /// Human name of what a staff role is attached to ("Library", "DevHub").
  String? entityName(Role r, String? entity) {
    if (entity == null) return null;
    if (r == Role.facilityManager) return facilityById(entity)?.name ?? entity;
    if (r == Role.clubLeader) return clubById(entity)?.name ?? entity;
    return entity;
  }

  // ───────────── Personal preferences ─────────────

  void setPalette(int i) {
    paletteIndex = i;
    prefs.setInt(_kPalette, i);
    notifyListeners();
  }

  void toggleFollow(String clubId) {
    if (!followedClubs.remove(clubId)) followedClubs.add(clubId);
    prefs.setStringList(_kFollowed, followedClubs.toList());
    notifyListeners();
  }

  void toggleGoing(String eventId) {
    if (!goingEvents.remove(eventId)) goingEvents.add(eventId);
    prefs.setStringList(_kGoing, goingEvents.toList());
    notifyListeners();
  }

  void toggleSaved(String newsId) {
    if (!savedNews.remove(newsId)) savedNews.add(newsId);
    prefs.setStringList(_kSaved, savedNews.toList());
    notifyListeners();
  }

  void markRead(String newsId) {
    if (readNews.add(newsId)) {
      prefs.setStringList(_kRead, readNews.toList());
      notifyListeners();
    }
  }

  void toggleShowAllDepartments() {
    showAllDepartments = !showAllDepartments;
    prefs.setBool(_kAllDeps, showAllDepartments);
    notifyListeners();
  }

  /// Pass null to clear the faculty filter.
  Future<void> setDepartment(String? department) async {
    final p = profile;
    if (p == null) return;
    showAllDepartments = false;
    prefs.setBool(_kAllDeps, false);
    await store.set('users', p.uid, {'department': department});
  }

  // ───────────── Writing helpers ─────────────

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(999)}';

  String get _actorName {
    final n = profile?.name ?? '';
    return n.isNotEmpty ? n : (profile?.email ?? 'Someone');
  }

  /// Audit trail: who did what, and when.
  Future<void> _log(String action) async {
    final p = profile;
    if (p == null) return;
    final e = LogEntry(
      id: _id('l'),
      actorUid: p.uid,
      actorName: _actorName,
      actorRole: p.role,
      action: action,
      at: DateTime.now(),
    );
    try {
      await store.set('logs', e.id, e.toMap());
    } catch (_) {}
  }

  // ───────────── Announcements ─────────────

  Future<void> publishAnnouncement({
    required String title,
    required String body,
    required AnnCategory category,
    bool highPriority = false,
    String? department,
    String? clubId,
  }) async {
    final p = profile!;
    final club = clubById(clubId);
    final a = Announcement(
      id: _id('n'),
      title: title.trim(),
      body: body.trim(),
      author: club?.name ?? _actorName,
      category: category,
      date: DateTime.now(),
      highPriority: highPriority,
      department: department,
      clubId: clubId,
      authorUid: p.uid,
      authorRole: p.role.wire,
    );
    await store.set('announcements', a.id, a.toMap(), merge: false);
    await _log(
        'posted ${highPriority ? 'a high-priority ' : 'an '}announcement "${a.title}"${club != null ? ' for ${club.name}' : ''}');
  }

  Future<void> deleteAnnouncement(Announcement a) async {
    await store.delete('announcements', a.id);
    await _log('deleted announcement "${a.title}"');
  }

  // ───────────── Events & QR check-in ─────────────

  Future<String> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime start,
    required DateTime end,
    required EventCategory category,
    String? clubId,
    String? facilityId,
    String? department,
    String? organizer,
    bool checkIn = false,
  }) async {
    final p = profile!;
    final e = CampusEvent(
      id: _id('e'),
      title: title.trim(),
      description: description.trim(),
      location: location.trim(),
      organizer: organizer ??
          clubById(clubId)?.name ??
          facilityById(facilityId)?.name ??
          _actorName,
      category: category,
      start: start,
      end: end,
      clubId: clubId,
      facilityId: facilityId,
      department: department,
      createdBy: p.uid,
    );
    await store.set('events', e.id, e.toMap(), merge: false);
    await _log('created event "${e.title}" (${fmtDay(start)})');
    if (checkIn) await startCheckIn(e.id);
    return e.id;
  }

  Future<void> deleteEvent(CampusEvent e) async {
    await store.delete('events', e.id);
    try {
      await store.delete('eventSecrets', e.id);
    } catch (_) {}
    await _log('deleted event "${e.title}"');
  }

  String _newToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Organiser: open a check-in session (also used to rotate the code).
  Future<void> startCheckIn(String eventId) async {
    await store.set('eventSecrets', eventId,
        {'eventId': eventId, 'token': _newToken(), 'open': true});
    await store.set('events', eventId, {'checkInEnabled': true});
    await _log('opened QR check-in for "${eventById(eventId)?.title ?? eventId}"');
  }

  Future<void> stopCheckIn(String eventId) async {
    await store.set('eventSecrets', eventId, {'open': false});
    await store.set('events', eventId, {'checkInEnabled': false});
    await _log('closed QR check-in for "${eventById(eventId)?.title ?? eventId}"');
  }

  /// Student: handle the text found in a QR code.
  Future<CheckInResult> checkIn(String payload) async {
    final p = profile;
    if (p == null) return CheckInResult.error;
    final uri = Uri.tryParse(payload.trim());
    final eventId = uri?.queryParameters['e'];
    final token = uri?.queryParameters['t'];
    if (uri == null ||
        uri.scheme != 'studenthub' ||
        uri.host != 'checkin' ||
        eventId == null ||
        token == null) {
      return CheckInResult.invalid;
    }
    if (myCheckIns.contains(eventId)) return CheckInResult.already;

    try {
      // Demo mode has no server rules, so verify the code here.
      // With Firestore the security rules do this check.
      if (!AppConfig.useFirebase) {
        final secret = await store.get('eventSecrets', eventId);
        if (secret == null || secret['open'] != true) {
          return CheckInResult.closed;
        }
        if (secret['token'] != token) return CheckInResult.invalid;
      }
      await store.set(
        'checkins',
        '${eventId}_${p.uid}',
        {
          'eventId': eventId,
          'uid': p.uid,
          'name': p.name,
          'email': p.email,
          'at': DateTime.now().toIso8601String(),
          'token': token,
        },
        merge: false,
      );
      return CheckInResult.ok;
    } catch (_) {
      return CheckInResult.invalid;
    }
  }

  // ───────────── Facilities & emergency alerts ─────────────

  Future<void> updateFacility(
      String id, {
        FacilityStatus? status,
        String? note,
        int? openMinute,
        int? closeMinute,
        Set<int>? days,
      }) async {
    final f = facilityById(id);
    final data = <String, dynamic>{
      'updatedBy': _actorName,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    final changes = <String>[];
    if (status != null && status != f?.status) {
      data['status'] = status.name;
      changes.add('set ${f?.name ?? id} to ${status.label}');
    }
    if (note != null && note != f?.note) {
      data['note'] = note;
      if (status == null || status == f?.status) {
        changes.add('updated the note for ${f?.name ?? id}');
      }
    }
    if ((openMinute != null && openMinute != f?.openMinute) ||
        (closeMinute != null && closeMinute != f?.closeMinute)) {
      final o = openMinute ?? f?.openMinute ?? 0;
      final c = closeMinute ?? f?.closeMinute ?? 0;
      data['openMinute'] = o;
      data['closeMinute'] = c;
      changes.add(
          'updated ${f?.name ?? id} hours to ${Facility.fmtMinutes(o)} - ${Facility.fmtMinutes(c)}');
    }
    if (days != null && !setEquals(days, f?.days)) {
      data['days'] = (days.toList()..sort());
      changes.add('updated open days for ${f?.name ?? id}');
    }
    if (changes.isEmpty) return;
    await store.set('facilities', id, data);
    await _log(changes.join(' and '));
  }

  Future<void> createFacility(Facility f) async {
    await store.set('facilities', f.id, f.toMap(), merge: false);
    await _log('created the campus area "${f.name}"');
  }

  String uniqueFacilityId(String name) {
    var slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty) slug = 'area';
    return facilityById(slug) == null ? slug : '${slug}_${Random().nextInt(9999)}';
  }

  Future<void> triggerAlert({
    required String title,
    required String message,
    String? facilityId,
  }) async {
    final p = profile!;
    final a = CampusAlert(
      id: _id('a'),
      title: title.trim(),
      message: message.trim(),
      facilityId: facilityId,
      createdBy: p.uid,
      createdByName: _actorName,
      createdAt: DateTime.now(),
    );
    await store.set('alerts', a.id, a.toMap(), merge: false);
    await _log('triggered an emergency banner: "${a.title}"');
  }

  Future<void> resolveAlert(CampusAlert a) async {
    await store.set('alerts', a.id, {'active': false});
    await _log('resolved the emergency banner "${a.title}"');
  }

  // ───────────── Clubs ─────────────

  Future<void> updateClubPage(
    String id, {
    String? tagline,
    String? description,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (tagline != null) data['tagline'] = tagline.trim();
    if (description != null) data['description'] = description.trim();
    if (email != null) data['email'] = email.trim();
    if (data.isEmpty) return;
    await store.set('clubs', id, data);
    await _log('edited the page of ${clubById(id)?.name ?? id}');
  }

  Future<void> postClubUpdate(String id, String text) async {
    final club = clubById(id);
    if (club == null) return;
    final updates = [
      ClubUpdate(text: text.trim(), date: DateTime.now()),
      ...club.updates,
    ];
    await store.set('clubs', id, {
      'updates': updates.map((u) => u.toMap()).toList(),
    });
    await _log('posted an update on ${club.name}');
  }

  // ───────────── Role requests ("Demande") ─────────────

  Future<void> submitRoleRequest({
    required Role role,
    String? target,
    required String justification,
  }) async {
    final p = profile!;
    final r = RoleRequest(
      id: _id('r'),
      uid: p.uid,
      email: p.email,
      name: p.name.isEmpty ? p.email : p.name,
      role: role,
      target: target,
      justification: justification.trim(),
      createdAt: DateTime.now(),
    );
    await store.set('requests', r.id, r.toMap(), merge: false);
    await _log(
        'requested the ${role.label} role${target != null ? ' (${entityName(role, target)})' : ''}');
  }

  /// Super admin: approve and assign the scope. This updates the user's
  /// document, and the person's app unlocks the new controls instantly.
  Future<void> approveRequest(
    RoleRequest r, {
    required Role role,
    String? entity,
    String? department,
    String? note,
  }) async {
    final userData = <String, dynamic>{
      'role': role.wire,
      'assignedEntity': entity,
    };
    if (department != null) userData['department'] = department;
    await store.set('users', r.uid, userData);
    await store.set('requests', r.id, {
      'status': RequestStatus.approved.name,
      'decidedBy': _actorName,
      'decidedAt': DateTime.now().toIso8601String(),
      'decisionNote': note == null || note.trim().isEmpty ? null : note.trim(),
      'grantedEntity': entity,
      'role': role.wire,
    });
    await _log(
        'approved ${r.name} as ${role.label}${entity != null ? ' (${entityName(role, entity)})' : ''}');
  }

  Future<void> rejectRequest(RoleRequest r, {String? note}) async {
    await store.set('requests', r.id, {
      'status': RequestStatus.rejected.name,
      'decidedBy': _actorName,
      'decidedAt': DateTime.now().toIso8601String(),
      'decisionNote': note == null || note.trim().isEmpty ? null : note.trim(),
    });
    await _log('rejected the ${r.role.label} request of ${r.name}');
  }

  /// Super admin: change or revoke someone's role directly.
  Future<void> setUserRole(
    UserProfile target,
    Role role, {
    String? entity,
  }) async {
    await store.set('users', target.uid, {
      'role': role.wire,
      'assignedEntity': role == Role.student ? null : entity,
    });
    await _log(role == Role.student
        ? 'revoked the staff role of ${target.name}'
        : 'set ${target.name} to ${role.label}${entity != null ? ' (${entityName(role, entity)})' : ''}');
  }
}
