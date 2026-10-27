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

  /// Persyaratan pengambilan darah di PMI. Sesuaikan dengan aturan PMI Kota Ternate.
  static const pmiRequirements = [
    'Surat rekomendasi/permintaan darah dari rumah sakit (unggah fotonya di form ini, bawa aslinya ke PMI).',
    'Identitas pasien dan identitas pemohon (KTP).',
    'Data pasien, golongan darah, dan jumlah kantong sesuai surat dari rumah sakit.',
  ];

  /// Stok di bawah angka ini dianggap menipis (peringatan kuning untuk admin).
  static const lowStockThreshold = 5;

  /// Pengajuan yang disetujui harus diambil dalam waktu ini, jika tidak dibatalkan otomatis.
  static const pickupDeadline = Duration(hours: 24);

  /// Sisa waktu di bawah ini ditandai "hampir kedaluwarsa".
  static const nearExpiryWindow = Duration(hours: 6);

  /// Batas ukuran foto bukti rekomendasi (penyimpanan lokal terbatas).
  static const maxAttachmentBytes = 1536 * 1024;
  static const healthCheckNote =
      'Cek kesehatan dapat dilakukan langsung di PMI.';
}
