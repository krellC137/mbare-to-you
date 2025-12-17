import 'package:intl/intl.dart';

/// DateTime extension methods
extension DateTimeExtension on DateTime {
  /// Formats date as 'dd MMM yyyy' (e.g., '15 Jan 2025')
  String toFormattedDate() => DateFormat('dd MMM yyyy').format(this);

  /// Formats time as 'HH:mm' (e.g., '14:30')
  String toFormattedTime() => DateFormat('HH:mm').format(this);

  /// Formats date and time as 'dd MMM yyyy, HH:mm'
  String toFormattedDateTime() => DateFormat('dd MMM yyyy, HH:mm').format(this);

  /// Formats date as 'dd/MM/yyyy'
  String toShortDate() => DateFormat('dd/MM/yyyy').format(this);

  /// Returns relative time string (e.g., 'Just now', '5 minutes ago')
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Checks if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Checks if date is within the current week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return isAfter(weekStart) && isBefore(weekEnd);
  }

  /// Returns the start of the day (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the end of the day (23:59:59)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Checks if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Checks if date is in the future
  bool get isFuture => isAfter(DateTime.now());
}

/// Nullable DateTime extension methods
extension NullableDateTimeExtension on DateTime? {
  /// Returns formatted date or empty string if null
  String toFormattedDateOrEmpty() {
    return this?.toFormattedDate() ?? '';
  }

  /// Returns formatted time or empty string if null
  String toFormattedTimeOrEmpty() {
    return this?.toFormattedTime() ?? '';
  }

  /// Returns relative time or default string if null
  String toRelativeTimeOrDefault([String defaultValue = 'N/A']) {
    return this?.toRelativeTime() ?? defaultValue;
  }
}
