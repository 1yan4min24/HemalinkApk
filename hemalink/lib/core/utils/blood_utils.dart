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

  /// Golongan yang bisa menerima darah dari [type].
  static List<String> canDonateTo(String type, List<String> all) =>
      all.where((r) => canDonate(type, r)).toList();

  /// Golongan yang bisa mendonorkan darah ke [type].
  static List<String> canReceiveFrom(String type, List<String> all) =>
      all.where((d) => canDonate(d, type)).toList();

  /// Keterangan singkat tentang golongan darah.
  static String note(String type) {
    if (type == 'O-') {
      return 'Donor universal: sel darah merah O- dapat diberikan ke semua golongan darah, sehingga sangat dibutuhkan pada kondisi darurat.';
    }
    if (type == 'AB+') {
      return 'Penerima universal: dapat menerima sel darah merah dari semua golongan darah.';
    }
    if (type.endsWith('-')) {
      return 'Rhesus negatif: pasien dengan golongan ini hanya dapat menerima darah Rhesus negatif.';
    }
    return 'Rhesus positif: pasien dengan golongan ini dapat menerima darah Rhesus positif maupun negatif (sesuai kecocokan ABO).';
  }
}
