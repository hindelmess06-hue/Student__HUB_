/// Central place for the settings you are most likely to change.
class AppConfig {
  /// false = Demo mode (works instantly, no backend, no real emails).
  /// true  = Firebase mode (real accounts, real verification emails,
  ///         shared Cloud Firestore data).
  ///
  /// Switch without editing code:
  ///   flutter run --dart-define=USE_FIREBASE=true
  static const bool useFirebase =
      bool.fromEnvironment('USE_FIREBASE', defaultValue: false);

  /// Only emails on these domains (or their subdomains) can register.
  static const List<String> allowedDomains = ['ueuromed.org'];

  /// DEMO MODE ONLY: accounts with these emails become `super_admin` the
  /// first time they sign in, so you can try the whole approval workflow.
  /// In Firebase mode this list is ignored: you promote the first Super Admin
  /// by hand in the Firestore console (see README), because a client app must
  /// never be allowed to grant itself power.
  static const List<String> demoSuperAdminEmails = ['admin@ueuromed.org'];

  /// Faculties / majors a student can pick on their profile.
  static const List<String> departments = [
    'Civil Engineering',
    'Computer Science & AI',
    'Business & Management',
    'Architecture & Design',
    'Energy & Environment',
    'Law & Political Science',
  ];

  static const String appName = 'Student Hub';
  static const String universityShort = 'UEMF';
  static const String version = '2.0.0';
}
