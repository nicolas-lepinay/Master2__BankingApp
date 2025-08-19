import 'package:equatable/equatable.dart';

class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  factory DateRange.today() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateRange(
      start: today,
      end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
    );
  }

  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return DateRange(
      start: startOfWeekDate,
      end: startOfWeekDate.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1)),
    );
  }

  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
    return DateRange(start: startOfMonth, end: endOfMonth);
  }

  factory DateRange.thisYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year + 1, 1, 1).subtract(const Duration(microseconds: 1));
    return DateRange(start: startOfYear, end: endOfYear);
  }

  factory DateRange.last30Days() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startDate = endDate.subtract(const Duration(days: 30));
    return DateRange(start: startDate, end: endDate);
  }

  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end) || 
           date.isAtSameMomentAs(start) || 
           date.isAtSameMomentAs(end);
  }

  bool overlaps(DateRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  Duration get duration => end.difference(start);

  int get daysCount => duration.inDays;

  DateRange copyWith({
    DateTime? start,
    DateTime? end,
  }) {
    return DateRange(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  List<Object?> get props => [start, end];

  @override
  bool get stringify => true;

  @override
  String toString() => 'DateRange(${start.toIso8601String()} - ${end.toIso8601String()})';
}