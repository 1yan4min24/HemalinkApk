class BloodUtils {
  static String _abo(String t) => t.replaceAll(RegExp(r'[+-]'), '');

  /// Apakah pendonor bergolongan [donor] dapat mendonorkan ke penerima [recipient].
  static bool canDonate(String donor, String recipient) {
    final donorRhPositive = donor.endsWith('+');
    final recipientRhPositive = recipient.endsWith('+');
    final rhOk = !donorRhPositive || recipientRhPositive;
    final d = _abo(donor);
    final r = _abo(recipient);
    final aboOk = d == 'O' || d == r || r == 'AB';
    return rhOk && aboOk;
  }

  static String group(String type) => _abo(type);
}
