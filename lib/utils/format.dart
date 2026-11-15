const _wdShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _wdLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _moShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _moLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String two(int n) => n.toString().padLeft(2, '0');

String fmtTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

String weekdayShort(DateTime d) => _wdShort[d.weekday - 1];

String monthShort(DateTime d) => _moShort[d.month - 1];

String fmtDay(DateTime d) => '${weekdayShort(d)} ${d.day} ${monthShort(d)}';

String fmtLong(DateTime d) =>
    '${_wdLong[d.weekday - 1]}, ${d.day} ${_moLong[d.month - 1]} ${d.year}';

String fmtDateLine(DateTime d) =>
    '${_wdLong[d.weekday - 1]}, ${d.day} ${_moLong[d.month - 1]}';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whole calendar days between [d] and today (negative = past).
/// Uses UTC dates so daylight-saving changes can't shift the result.
int dayDiff(DateTime d, [DateTime? from]) {
  final n = from ?? DateTime.now();
  return DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(n.year, n.month, n.day))
      .inDays;
}

String relDay(DateTime d) {
  final n = dayDiff(d);
  if (n == 0) return 'Today';
  if (n == 1) return 'Tomorrow';
  if (n == -1) return 'Yesterday';
  if (n > 1 && n < 7) return _wdLong[d.weekday - 1];
  return fmtDay(d);
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return fmtDay(d);
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

String initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

String firstName(String name, String email) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first;
  final local = email.split('@').first;
  return local.isEmpty ? 'there' : local;
}
