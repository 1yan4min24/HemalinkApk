import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../controllers/app_controller.dart';
import '../core/constants/app_constants.dart';
import '../models/stock_request.dart';

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
  'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String monthLabel(DateTime d) => '${_bulan[d.month - 1]} ${d.year}';
String _ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

class BloodTypeRow {
  final String type;
  int requests = 0;
  int bagsRequested = 0;
  int bagsReleased = 0;
  BloodTypeRow(this.type);
}

/// Rekap bulanan pengajuan darah ke PMI.
class MonthlyReport {
  final DateTime month;
  final int totalRequests;
  final Map<StockRequestStatus, int> byStatus;
  final int bagsRequested;
  final int bagsReleased;
  final int forumRequests;
  final List<BloodTypeRow> rows;
  final String? topType;

  MonthlyReport({
    required this.month,
    required this.totalRequests,
    required this.byStatus,
    required this.bagsRequested,
    required this.bagsReleased,
    required this.forumRequests,
    required this.rows,
    required this.topType,
  });

  factory MonthlyReport.build(AppController c, DateTime month) {
    bool inMonth(DateTime d) => d.year == month.year && d.month == month.month;
    final rows = {for (final t in AppConstants.bloodTypes) t: BloodTypeRow(t)};
    final byStatus = {for (final s in StockRequestStatus.values) s: 0};
    var total = 0;
    var bagsReq = 0;
    var bagsRel = 0;
    for (final r in c.allStockRequests) {
      if (!inMonth(r.createdAt)) continue;
      total++;
      byStatus[r.status] = (byStatus[r.status] ?? 0) + 1;
      bagsReq += r.bags;
      final row = rows[r.bloodType];
      if (row != null) {
        row.requests++;
        row.bagsRequested += r.bags;
      }
      if (r.status == StockRequestStatus.completed) {
        bagsRel += r.bags;
        if (row != null) row.bagsReleased += r.bags;
      }
    }
    final list = rows.values.toList();
    BloodTypeRow? top;
    for (final r in list) {
      if (r.requests == 0) continue;
      if (top == null ||
          r.requests > top.requests ||
          (r.requests == top.requests && r.bagsRequested > top.bagsRequested)) {
        top = r;
      }
    }
    final forum =
        c.visibleRequests.where((r) => inMonth(r.createdAt)).length;
    return MonthlyReport(
      month: month,
      totalRequests: total,
      byStatus: byStatus,
      bagsRequested: bagsReq,
      bagsReleased: bagsRel,
      forumRequests: forum,
      rows: list,
      topType: top?.type,
    );
  }

  String get topLabel => topType ?? '-';

  String toCsv() {
    String q(Object v) {
      final s = '$v';
      return (s.contains(',') || s.contains('"') || s.contains('\n'))
          ? '"${s.replaceAll('"', '""')}"'
          : s;
    }

    final b = StringBuffer('\uFEFF'); // BOM agar Excel membaca UTF-8
    void row(List<Object> cells) => b.writeln(cells.map(q).join(','));
    row(['Laporan Bulanan Permintaan Darah']);
    row([AppConstants.pmiName]);
    row(['Periode', monthLabel(month)]);
    row([]);
    row(['Ringkasan', 'Jumlah']);
    row(['Total pengajuan stok', totalRequests]);
    row(['Kantong diminta', bagsRequested]);
    row(['Kantong keluar (sudah diambil)', bagsReleased]);
    row(['Golongan terbanyak diminta', topLabel]);
    row(['Permintaan di forum', forumRequests]);
    row([]);
    row(['Status pengajuan', 'Jumlah']);
    for (final s in StockRequestStatus.values) {
      row([s.label, byStatus[s] ?? 0]);
    }
    row([]);
    row(['Golongan', 'Jumlah pengajuan', 'Kantong diminta', 'Kantong keluar']);
    for (final r in rows) {
      row([r.type, r.requests, r.bagsRequested, r.bagsReleased]);
    }
    return b.toString();
  }

  Future<Uint8List> toPdf() async {
    final doc = pw.Document();
    final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Text('Laporan Bulanan Permintaan Darah',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(AppConstants.pmiName),
          pw.Text('Periode: ${monthLabel(month)}'),
          pw.SizedBox(height: 14),
          pw.Text('Ringkasan', style: bold),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: ['Keterangan', 'Jumlah'],
            data: <List<String>>[
              ['Total pengajuan stok', '$totalRequests'],
              ['Kantong diminta', '$bagsRequested'],
              ['Kantong keluar (sudah diambil)', '$bagsReleased'],
              ['Golongan terbanyak diminta', topLabel],
              ['Permintaan di forum', '$forumRequests'],
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Status Pengajuan', style: bold),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: ['Status', 'Jumlah'],
            data: <List<String>>[
              for (final s in StockRequestStatus.values)
                [s.label, '${byStatus[s] ?? 0}'],
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Per Golongan Darah', style: bold),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: [
              'Golongan',
              'Pengajuan',
              'Kantong diminta',
              'Kantong keluar'
            ],
            data: <List<String>>[
              for (final r in rows)
                [
                  r.type,
                  '${r.requests}',
                  '${r.bagsRequested}',
                  '${r.bagsReleased}'
                ],
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> exportPdf() async {
    final bytes = await toPdf();
    await Printing.sharePdf(bytes: bytes, filename: 'laporan-${_ym(month)}.pdf');
  }

  Future<void> exportCsv() async {
    await FileSaver.instance.saveFile(
      name: 'laporan-${_ym(month)}',
      bytes: Uint8List.fromList(utf8.encode(toCsv())),
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }
}
