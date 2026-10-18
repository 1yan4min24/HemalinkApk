class AppConstants {
  static const appName = 'HemaLink';
  static const tagline = 'Hubungan Kasih, Penyelamat Nyawa';

  static const bloodTypes = ['A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'];
  static const bloodGroups = ['A', 'B', 'AB', 'O'];

  /// Jeda minimal antar donor (hari). Sesuaikan dengan kebijakan PMI.
  static const donorIntervalDays = 60;

  static const pmiName = 'PMI Kota Ternate';
  static const pmiAddress =
      'Jl. Ki Hajar Dewantara, Takoma, Kec. Ternate Tengah, Kota Ternate';
  static const defaultCity = 'Kota Ternate, Maluku Utara';

  /// Akun admin PMI (lokal). GANTI sebelum dipakai, dan pindahkan ke backend
  /// (Firebase Auth / API) untuk penggunaan sungguhan.
  static const adminUsername = 'admin';
  static const adminPassword = 'pmi12345';
}
