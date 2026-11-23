import 'emg_calibrator.dart';

/// "12 more hours", "Expired" or "Not calibrated yet", from the saved
/// calibration and its existing 24-hour expiry ([Calibration.validFor]).
String calibrationGoodFor(Calibration? c, DateTime now) {
  if (c == null) return 'Not calibrated yet';
  if (c.isExpiredAt(now)) return 'Expired';
  final left = c.timestamp.add(Calibration.validFor).difference(now);
  final hours = left.inHours;
  if (hours < 1) return 'Less than 1 hour';
  return '$hours more ${hours == 1 ? 'hour' : 'hours'}';
}
