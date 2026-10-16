import 'property.dart';

/// The cost of a stay, computed from the listing's own published pricing.
/// Never adds fees the host did not set. The deposit is listed separately
/// because it is returned after checkout.
class StayQuote {
  const StayQuote._({
    required this.nights,
    required this.nightlyRate,
    required this.cleaningFee,
    required this.refundableDeposit,
  });

  /// Returns null when the dates are missing or invalid.
  static StayQuote? forStay(Property property, DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) return null;
    final nights = nightsBetween(checkIn, checkOut);
    if (nights <= 0) return null;
    return StayQuote._(
      nights: nights,
      nightlyRate: property.nightlyRate,
      cleaningFee: property.cleaningFee,
      refundableDeposit: property.refundableDeposit,
    );
  }

  final int nights;
  final double nightlyRate;
  final double cleaningFee;
  final double refundableDeposit;

  double get nightsTotal => nightlyRate * nights;

  /// What the guest pays the host for the stay (excluding the refundable deposit).
  double get total => nightsTotal + cleaningFee;

  static int nightsBetween(DateTime checkIn, DateTime checkOut) {
    final a = DateTime.utc(checkIn.year, checkIn.month, checkIn.day);
    final b = DateTime.utc(checkOut.year, checkOut.month, checkOut.day);
    return b.difference(a).inDays;
  }
}

/// Problems with requested dates/guests for a specific listing, checked
/// before an enquiry is sent (the server re-checks all of these).
List<String> stayProblems(Property property, {DateTime? checkIn, DateTime? checkOut, int? guests, DateTime? today}) {
  final problems = <String>[];
  final now = today ?? DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);
  if (checkIn == null || checkOut == null) {
    problems.add('Choose check-in and check-out dates.');
    return problems;
  }
  final nights = StayQuote.nightsBetween(checkIn, checkOut);
  if (checkIn.isBefore(todayDate)) problems.add('Check-in cannot be in the past.');
  if (nights <= 0) {
    problems.add('Check-out must be after check-in.');
  } else {
    if (nights < property.minimumNights) {
      problems.add('This place has a minimum stay of ${property.minimumNights} nights.');
    }
    if (nights > 90) problems.add('Stays can be at most 90 nights.');
    for (var i = 0; i < nights; i++) {
      if (property.isUnavailableOn(checkIn.add(Duration(days: i)))) {
        problems.add('The host has marked some of these dates as unavailable.');
        break;
      }
    }
  }
  if (guests != null && property.maximumGuests != null && guests > property.maximumGuests!) {
    problems.add('This place hosts at most ${property.maximumGuests} guests.');
  }
  return problems;
}
