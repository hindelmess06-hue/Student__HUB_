import 'dart:math';

import '../app_config.dart';

/// Client-side rules for who may register.
///
/// IMPORTANT: this stops honest mistakes and gives instant feedback, but it
/// can be bypassed by anyone calling the backend directly. The real guarantee
/// comes from (1) the e-mail verification link and (2) backend rules that
/// check the verified e-mail domain. See README.md, "Hardening".
class EmailRules {
  static final RegExp _shape =
      RegExp(r'^[a-z0-9._%+\-]+@[a-z0-9\-]+(\.[a-z0-9\-]+)+$');

  static String normalize(String raw) => raw.trim().toLowerCase();

  static bool isAllowedDomain(String domain) => AppConfig.allowedDomains
      .any((d) => domain == d || domain.endsWith('.$d'));

  /// Returns null when the address is acceptable, otherwise a message that is
  /// safe to show to the user.
  static String? validate(String raw) {
    final email = normalize(raw);
    if (email.isEmpty) return 'Enter your university email.';

    final atCount = '@'.allMatches(email).length;
    if (atCount != 1 || !_shape.hasMatch(email) || email.contains('..')) {
      return "That doesn't look like a valid email address.";
    }
    final local = email.split('@').first;
    if (local.startsWith('.') || local.endsWith('.')) {
      return "That doesn't look like a valid email address.";
    }

    final domain = email.split('@').last;
    if (isAllowedDomain(domain)) return null;

    final suggestion = _closestAllowed(domain);
    if (suggestion != null) {
      return 'Did you mean @$suggestion? Only UEMF emails are accepted.';
    }
    return 'Only UEMF emails are accepted (name@${AppConfig.allowedDomains.first}).';
  }

  static String? _closestAllowed(String domain) {
    for (final d in AppConfig.allowedDomains) {
      if (_distance(domain, d) <= 3) return d;
    }
    return null;
  }

  /// Levenshtein edit distance, used to catch typos like "ueuromed.com".
  static int _distance(String a, String b) {
    final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = min(
          min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
          dp[i - 1][j - 1] + cost,
        );
      }
    }
    return dp[a.length][b.length];
  }
}
