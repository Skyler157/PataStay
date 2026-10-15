import 'package:intl/intl.dart';

abstract final class Money {
  static final _whole = NumberFormat('#,##0', 'en');
  static final _withCents = NumberFormat('#,##0.00', 'en');

  /// `3500` -> `KES 3,500`; cents are only shown when present.
  static String kes(num amount) {
    final hasCents = amount % 1 != 0;
    return 'KES ${(hasCents ? _withCents : _whole).format(amount)}';
  }

  /// Compact form for filters and chips: `KES 3.5K`, `KES 12K`.
  static String kesCompact(num amount) {
    if (amount < 1000) return kes(amount);
    final thousands = amount / 1000;
    final text = thousands % 1 == 0 ? thousands.toStringAsFixed(0) : thousands.toStringAsFixed(1);
    return 'KES ${text}K';
  }
}

abstract final class Dates {
  static final _day = DateFormat('d MMM yyyy', 'en');
  static final _shortDay = DateFormat('EEE d MMM', 'en');

  static String day(DateTime date) => _day.format(date.toLocal());
  static String shortDay(DateTime date) => _shortDay.format(date.toLocal());

  /// "today", "yesterday", "3 days ago", "2 weeks ago", or a date.
  static String relative(DateTime date, {DateTime? now}) {
    final reference = (now ?? DateTime.now()).toLocal();
    final local = date.toLocal();
    final days = DateTime(reference.year, reference.month, reference.day)
        .difference(DateTime(local.year, local.month, local.day))
        .inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) {
      final weeks = days ~/ 7;
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    return 'on ${day(date)}';
  }
}
