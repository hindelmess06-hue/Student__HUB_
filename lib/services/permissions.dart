import '../models/models.dart';

/// Every "who may do what" decision in one place. The UI uses this to show or
/// hide controls; `firestore.rules` enforces the same rules on the server
/// (the UI alone is never real security).
class Perms {
  const Perms(this.profile);

  final UserProfile? profile;

  Role get role => profile?.role ?? Role.student;
  String? get entity => profile?.assignedEntity;
  String? get uid => profile?.uid;

  bool get isAdmin => role == Role.superAdmin;
  bool get isStaff => role != Role.student;

  /// Professors, club leaders and admins can post announcements.
  bool get canPostAnnouncement =>
      isAdmin || role == Role.professor || role == Role.clubLeader;

  /// Professors (faculty events), club leaders (club events), facility
  /// managers (sessions at their own facility) and admins can create events.
  bool get canCreateEvent =>
      isAdmin ||
      role == Role.professor ||
      role == Role.clubLeader ||
      role == Role.facilityManager;

  bool canManageClub(String clubId) =>
      isAdmin || (role == Role.clubLeader && entity == clubId);

  bool canManageFacility(String facilityId) =>
      isAdmin || (role == Role.facilityManager && entity == facilityId);

  /// Emergency banner: a facility manager for their own facility, or an admin
  /// for anything (including campus-wide).
  bool canTriggerAlert(String? facilityId) =>
      isAdmin || (facilityId != null && canManageFacility(facilityId));

  bool canResolveAlert(CampusAlert a) =>
      isAdmin || a.createdBy == uid || canTriggerAlert(a.facilityId);

  bool canDeleteAnnouncement(Announcement a) => isAdmin || a.authorUid == uid;

  bool canManageEvent(CampusEvent e) => isAdmin || e.createdBy == uid;

  /// Staff always see everything; only students get the faculty filter.
  bool get usesFacultyFilter => role == Role.student;
}
