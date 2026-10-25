import '../core/constants/app_constants.dart';

enum StockRequestStatus {
  processing('Diproses'),
  approved('Disetujui'),
  completed('Sudah diambil'),
  rejected('Ditolak'),
  cancelled('Dibatalkan');

  final String label;
  const StockRequestStatus(this.label);
}

/// Pengajuan pengambilan darah langsung dari stok PMI.
class StockRequest {
  final String id;
  final String requesterId;
  String requesterName;
  final String requesterPhone;
  final String bloodType;
  final int bags;
  final String patientName;
  final String hospital;
  final String reason;
  final String letterNo;

  /// Nama file foto surat rekomendasi rumah sakit (isi file disimpan terpisah).
  final String attachmentName;
  final DateTime createdAt;
  StockRequestStatus status;

  /// Tanggapan/catatan dari admin PMI untuk pemohon.
  String adminNote;
  DateTime? approvedAt;
  DateTime? resolvedAt;

  StockRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    required this.bloodType,
    required this.bags,
    required this.patientName,
    required this.hospital,
    required this.reason,
    required this.letterNo,
    required this.createdAt,
    this.attachmentName = '',
    this.status = StockRequestStatus.processing,
    this.adminNote = '',
    this.approvedAt,
    this.resolvedAt,
  });

  /// Batas waktu pengambilan (sejak disetujui).
  DateTime? get pickupDeadline => approvedAt?.add(AppConstants.pickupDeadline);

  /// Pengajuan yang masih menahan (mengunci) stok.
  bool get holdsStock =>
      status == StockRequestStatus.processing ||
      status == StockRequestStatus.approved;

  Map<String, dynamic> toJson() => {
        'id': id,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'requesterPhone': requesterPhone,
        'bloodType': bloodType,
        'bags': bags,
        'patientName': patientName,
        'hospital': hospital,
        'reason': reason,
        'letterNo': letterNo,
        'attachmentName': attachmentName,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'adminNote': adminNote,
        'approvedAt': approvedAt?.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory StockRequest.fromJson(Map<String, dynamic> j) => StockRequest(
        id: j['id'] as String,
        requesterId: j['requesterId'] as String,
        requesterName: j['requesterName'] as String,
        requesterPhone: (j['requesterPhone'] as String?) ?? '',
        bloodType: j['bloodType'] as String,
        bags: j['bags'] as int,
        patientName: j['patientName'] as String,
        hospital: j['hospital'] as String,
        reason: j['reason'] as String,
        letterNo: (j['letterNo'] as String?) ?? '',
        attachmentName: (j['attachmentName'] as String?) ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: StockRequestStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => StockRequestStatus.processing,
        ),
        adminNote: (j['adminNote'] as String?) ?? '',
        approvedAt: j['approvedAt'] == null
            ? null
            : DateTime.tryParse(j['approvedAt'] as String),
        resolvedAt: j['resolvedAt'] == null
            ? null
            : DateTime.tryParse(j['resolvedAt'] as String),
      );
}
