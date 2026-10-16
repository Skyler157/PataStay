import 'package:flutter/material.dart';
import 'package:patastay_core/patastay_core.dart';

/// Picks a stay (check-in to check-out). When a [property] is given, nights
/// the host has blocked cannot be chosen, and a stay cannot span a blocked
/// night. Checking out on the morning a blocked period starts is allowed.
Future<DateTimeRange?> pickStayDates(BuildContext context, {DateTime? checkIn, DateTime? checkOut, Property? property}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  bool nightsFree(DateTime from, DateTime toExclusive) {
    for (var d = from; d.isBefore(toExclusive); d = d.add(const Duration(days: 1))) {
      if (property!.isUnavailableOn(d)) return false;
    }
    return true;
  }

  final range = await showDateRangePicker(
    context: context,
    firstDate: today,
    lastDate: today.add(const Duration(days: 365)),
    initialDateRange: checkIn != null && checkOut != null && !checkOut.isBefore(checkIn)
        ? DateTimeRange(start: checkIn, end: checkOut)
        : null,
    helpText: property == null ? 'Select your stay' : 'Select your stay · greyed-out dates are not available',
    saveText: 'Done',
    selectableDayPredicate: property == null || property.unavailableDates.isEmpty
        ? null
        : (day, start, end) {
            if (start != null && end == null && day.isAfter(start)) return nightsFree(start, day);
            return !property.isUnavailableOn(day);
          },
  );
  if (range == null) return null;
  if (range.end.difference(range.start).inDays < 1) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose at least one night.')));
    }
    return null;
  }
  return range;
}
