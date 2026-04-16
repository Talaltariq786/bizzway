import 'dart:math';

/// Rent-a-car customer booking — **intent** (Urdu / English) for Cursor & owner app.
///
/// **USER FLOW (copy to your doc — over-asking mat karo):**
/// Self‑drive / din wali rent = customer ko “kahan jaunga / kab wapis” alag se nahi poochhna — **start time + kitni der / return expectation** booking window se cover hoti hai.
/// **Per-hour with driver** = sirf **start / pickup point** zaroori; **drop / destination optional** — city ride mein fixed route na ho to “kahan jana hai” force mat karo.
/// Purane user-flow docs se “har haal mein pickup + drop dono zaroori” wali line **hata do**; ab flow yahi hai.
///
/// **Capture kya karna hai (customer side):**
/// - Poora naam (`customerFullName`)
/// - CNIC: 13 digits — dashes/spaces optional; sirf digits count (`customerNic` stored normalized)
/// - Driving licence number (`customerLicenseNo`) — self‑drive ke liye; with‑driver hourly optional policy baad mein tighten kar sakte ho
/// - Trip type: city | airport | outstation | event (`rentacarTripType`) — context ke liye
/// - **Pickup** (`pickupAddress`) — start / collection point (zaroori)
/// - **Drop-off** (`dropoffAddress`) — **optional**; khali ho to notes mein line add nahi / “not specified”
/// - Gari kaise mile gi: `pickup_yard` ya `home_delivery` — `vehicleHandoverMode`
/// - Confirm par **booking code** `RC-XXXXXX` — `bookingCode` / `id`
/// - `notes` = handover + trip + pickup (+ drop agar diya ho)
///
/// Owner flow: dashboard bookings list / SMS — `bookingCode`, `customerNic`, `customerLicenseNo` yahan se.

/// JSON / API values for rent-a-car handover mode.
const String kVehicleHandoverPickupYard = 'pickup_yard';
const String kVehicleHandoverHomeDelivery = 'home_delivery';

/// Trip type values for rent-a-car booking.
const String kRentacarTripCity = 'city';
const String kRentacarTripAirport = 'airport';
const String kRentacarTripOutstation = 'outstation';
const String kRentacarTripEvent = 'event';

final _bookingCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Random booking code: `RC-` + 6 chars (avoids ambiguous I, O, 0, 1).
String generateRentacarBookingCode() {
  final r = Random();
  final b = StringBuffer('RC-');
  for (var i = 0; i < 6; i++) {
    b.write(_bookingCodeChars[r.nextInt(_bookingCodeChars.length)]);
  }
  return b.toString();
}

/// Returns 13 digits only, or null if count ≠ 13.
String? normalizeCnicDigits(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  return digits.length == 13 ? digits : null;
}

String _handoverLabel(String? mode) {
  switch (mode) {
    case kVehicleHandoverPickupYard:
      return 'Yard / branch pickup ($kVehicleHandoverPickupYard)';
    case kVehicleHandoverHomeDelivery:
      return 'Home delivery ($kVehicleHandoverHomeDelivery)';
    default:
      return mode ?? '';
  }
}

/// Full notes block: Handover + trip + pickup; drop sirf jab diya ho.
String composeRentacarNotes({
  required String tripType,
  required String pickup,
  String? drop,
  required String vehicleHandoverMode,
  String? userNotes,
}) {
  final handover = _handoverLabel(vehicleHandoverMode);
  final buf = StringBuffer()
    ..writeln('Trip: $tripType')
    ..writeln('Pickup: $pickup');
  final d = drop?.trim();
  if (d != null && d.isNotEmpty) {
    buf.writeln('Drop-off: $d');
  }
  buf.writeln('Handover: $handover');
  if (userNotes != null && userNotes.trim().isNotEmpty) {
    buf.writeln('Notes: ${userNotes.trim()}');
  }
  return buf.toString().trim();
}

