import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/blood_request.dart';
import '../models/chat_thread.dart';
import '../models/donor_history.dart';
import '../models/stock_log.dart';
import '../models/stock_request.dart';
import '../models/user_account.dart';
import '../services/storage_service.dart';

/// Pusat state & logika aplikasi. Semua layar membaca dari sini.
/// Untuk backend sungguhan, ganti isi method (bukan layar)-nya.
class AppController extends ChangeNotifier {
  AppController._(this._store);
  static late AppController instance;
  final StorageService _store;

  static Future<void> init() async {
    final store = await StorageService.create();
    instance = AppController._(store).._load();
    instance.expireOverdueStockRequests();
  }

  // ---------- state ----------
  List<UserAccount> _accounts = [];
  List<BloodRequest> _requests = [];
  List<ChatThread> _threads = [];
  List<DonorHistory> _histories = [];
  List<StockRequest> _stockRequests = [];
  List<StockLog> _stockLogs = [];
  final Map<String, int> stock = {
    for (final t in AppConstants.bloodTypes) t: 0
  };
  DateTime? stockUpdatedAt;

  UserAccount? currentUser;
  bool isAdmin = false;
  bool get isLoggedIn => currentUser != null;

  // ---------- load ----------
  void _load() {
    _accounts = _store.readList('accounts').map(UserAccount.fromJson).toList();
    _requests = _store.readList('requests').map(BloodRequest.fromJson).toList();
    _threads = _store.readList('threads').map(ChatThread.fromJson).toList();
    _histories =
        _store.readList('histories').map(DonorHistory.fromJson).toList();
    _stockRequests =
        _store.readList('stock_requests').map(StockRequest.fromJson).toList();
    _stockLogs = _store.readList('stock_logs').map(StockLog.fromJson).toList();

    final st = _store.readMap('stock');
    if (st != null) {
      for (final t in AppConstants.bloodTypes) {
        stock[t] = (st[t] as int?) ?? 0;
      }
    }
    final ts = _store.readString('stock_updated');
    stockUpdatedAt = ts == null ? null : DateTime.tryParse(ts);

    final session = _store.readString('session');
    if (session == 'admin') {
      isAdmin = true;
    } else if (session != null) {
      final i = _accounts.indexWhere((a) => a.id == session);
      if (i >= 0) currentUser = _accounts[i];
    }
  }

  String _hash(String p) => sha256.convert(utf8.encode(p)).toString();
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _saveAccounts() =>
      _store.writeList('accounts', _accounts.map((e) => e.toJson()).toList());
  Future<void> _saveRequests() =>
      _store.writeList('requests', _requests.map((e) => e.toJson()).toList());
  Future<void> _saveThreads() =>
      _store.writeList('threads', _threads.map((e) => e.toJson()).toList());
  Future<void> _saveHistories() =>
      _store.writeList('histories', _histories.map((e) => e.toJson()).toList());
  Future<void> _saveStockRequests() => _store.writeList(
      'stock_requests', _stockRequests.map((e) => e.toJson()).toList());
  Future<void> _saveStockLogs() => _store.writeList(
      'stock_logs', _stockLogs.map((e) => e.toJson()).toList());

  /// Mencatat perubahan stok (disimpan oleh _persistStock). Maksimal 500 catatan.
  void _logStock(
      String type, int before, int after, String actor, String reason) {
    _stockLogs.add(StockLog(
      id: _newId(),
      at: DateTime.now(),
      actor: actor,
      reason: reason,
      bloodType: type,
      before: before,
      after: after,
    ));
    if (_stockLogs.length > 500) {
      _stockLogs.removeRange(0, _stockLogs.length - 500);
    }
  }

  Future<void> _persistStock() async {
    await _saveStockLogs();
    stockUpdatedAt = DateTime.now();
    await _store.writeMap('stock', stock);
    await _store.writeString(
        'stock_updated', stockUpdatedAt!.toIso8601String());
  }

  // ---------- auth ----------
  /// Mengembalikan pesan error, atau null jika berhasil (otomatis login).
  Future<String?> register({
    required String name,
    required String username,
    required String phone,
    required String password,
    required String bloodType,
    required int weight,
    required int height,
    required String city,
  }) async {
    final u = username.trim().toLowerCase();
    if (u == AppConstants.adminUsername ||
        _accounts.any((a) => a.username == u)) {
      return 'Username sudah dipakai, silakan pilih yang lain.';
    }
    final acc = UserAccount(
      id: _newId(),
      name: name.trim(),
      username: u,
      passwordHash: _hash(password),
      phone: phone.trim(),
      bloodType: bloodType,
      city: city.trim(),
      weight: weight,
      height: height,
    );
    _accounts.add(acc);
    await _saveAccounts();
    currentUser = acc;
    isAdmin = false;
    await _store.writeString('session', acc.id);
    notifyListeners();
    return null;
  }

  Future<String?> login(String username, String password,
      {required bool asAdmin}) async {
    final u = username.trim().toLowerCase();
    if (asAdmin) {
      if (u == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        isAdmin = true;
        currentUser = null;
        await _store.writeString('session', 'admin');
        notifyListeners();
        return null;
      }
      return 'Username atau password admin salah.';
    }
    final i = _accounts.indexWhere((a) => a.username == u);
    if (i < 0 || _accounts[i].passwordHash != _hash(password)) {
      return 'Username atau password salah.';
    }
    currentUser = _accounts[i];
    isAdmin = false;
    await _store.writeString('session', currentUser!.id);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    currentUser = null;
    isAdmin = false;
    await _store.remove('session');
    notifyListeners();
  }

  // ✅ Set user dari hasil login API (supaya layar beranda dll bisa baca data)
  void setCurrentUserFromApi({
    required String id,
    required String name,
    required String username,
    required String phone,
    required String bloodType,
    required String city,
    required int weight,
    required int height,
    required bool isAdmin,
  }) {
    currentUser = UserAccount(
      id: id,
      name: name,
      username: username,
      passwordHash: '',
      phone: phone,
      bloodType: bloodType,
      city: city,
      weight: weight,
      height: height,
    );
    this.isAdmin = isAdmin;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String bloodType,
    required String city,
    required int weight,
    required int height,
  }) async {
    final me = currentUser!;
    final updated = me.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      bloodType: bloodType,
      city: city.trim(),
      weight: weight,
      height: height,
    );
    final i = _accounts.indexWhere((a) => a.id == me.id);
    _accounts[i] = updated;
    currentUser = updated;
    for (final r in _requests.where((r) => r.requesterId == me.id)) {
      r.requesterName = updated.name;
    }
    for (final r in _stockRequests.where((r) => r.requesterId == me.id)) {
      r.requesterName = updated.name;
    }
    for (final t in _threads) {
      if (t.requesterId == me.id) t.requesterName = updated.name;
      if (t.donorId == me.id) t.donorName = updated.name;
    }
    await _saveAccounts();
    await _saveRequests();
    await _saveStockRequests();
    await _saveThreads();
    notifyListeners();
  }

  // ---------- permohonan (forum) ----------
  /// Forum permintaan darah: langsung tampil ke semua pengguna (tanpa verifikasi admin).
  List<BloodRequest> get visibleRequests =>
      _requests.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get totalRequests => _requests.length;
  int get activeRequests => _requests.length;

  /// Mengembalikan pesan error, atau null jika berhasil.
  /// Forum hanya untuk golongan darah yang stoknya kosong di PMI.
  Future<String?> addRequest({
    required String bloodType,
    required int bags,
    required String reason,
    required String hospital,
  }) async {
    if ((stock[bloodType] ?? 0) > 0) {
      return 'Stok golongan $bloodType masih tersedia di PMI. Silakan ajukan langsung ke PMI.';
    }
    final me = currentUser!;
    _requests.add(BloodRequest(
      id: _newId(),
      requesterId: me.id,
      requesterName: me.name,
      bloodType: bloodType,
      bags: bags,
      reason: reason.trim(),
      hospital: hospital.trim(),
      createdAt: DateTime.now(),
    ));
    await _saveRequests();
    notifyListeners();
    return null;
  }

  Future<void> deleteRequest(String id) async {
    _requests.removeWhere((r) => r.id == id);
    await _saveRequests();
    notifyListeners();
  }

  // ---------- pengajuan stok PMI ----------
  final Map<String, Uint8List> _attachmentCache = {};

  List<StockRequest> get allStockRequests =>
      _stockRequests.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<StockRequest> get myStockRequests {
    final me = currentUser;
    if (me == null) return [];
    return _stockRequests.where((r) => r.requesterId == me.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Pengajuan yang menunggu tanggapan admin (yang paling awal di atas).
  List<StockRequest> get processingStockRequests => _stockRequests
      .where((r) => r.status == StockRequestStatus.processing)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  int stockCount(StockRequestStatus s) =>
      _stockRequests.where((r) => r.status == s).length;

  /// Golongan dengan stok menipis (di atas 0 tetapi di bawah batas).
  List<String> get lowStockTypes => AppConstants.bloodTypes.where((t) {
        final n = stock[t] ?? 0;
        return n > 0 && n < AppConstants.lowStockThreshold;
      }).toList();

  /// Jumlah pengajuan disetujui yang hampir melewati batas pengambilan.
  int get nearExpiryCount => _stockRequests.where((r) {
        final d = r.pickupDeadline;
        return r.status == StockRequestStatus.approved &&
            d != null &&
            d.difference(DateTime.now()) <= AppConstants.nearExpiryWindow;
      }).length;

  /// Riwayat perubahan stok, terbaru di atas.
  List<StockLog> get stockLogs =>
      _stockLogs.toList()..sort((a, b) => b.at.compareTo(a.at));

  StockRequest? _findStock(String id) {
    for (final r in _stockRequests) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Foto bukti rekomendasi rumah sakit untuk sebuah pengajuan.
  Future<Uint8List?> stockAttachment(String id) async {
    final cached = _attachmentCache[id];
    if (cached != null) return cached;
    final raw = _store.readString('stock_att_$id');
    if (raw == null) return null;
    final bytes = base64Decode(raw);
    _attachmentCache[id] = bytes;
    return bytes;
  }

  /// Pengaju pertama langsung "mengunci" kantong darahnya: stok berkurang
  /// saat pengajuan dikirim. Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> requestStock({
    required String bloodType,
    required int bags,
    required String patientName,
    required String hospital,
    required String reason,
    required String letterNo,
    required Uint8List attachment,
    required String attachmentName,
  }) async {
    final me = currentUser;
    if (me == null) return 'Silakan login terlebih dahulu.';
    final available = stock[bloodType] ?? 0;
    if (available <= 0) {
      return 'Stok golongan $bloodType sedang kosong.';
    }
    if (bags > available) {
      return 'Stok golongan $bloodType hanya tersisa $available kantong.';
    }

    final id = _newId();
    try {
      await _store.writeString('stock_att_$id', base64Encode(attachment));
      if (_store.readString('stock_att_$id') == null) {
        throw StateError('attachment not saved');
      }
    } catch (_) {
      return 'Bukti rekomendasi gagal disimpan (penyimpanan penuh). Gunakan foto yang lebih kecil.';
    }
    _attachmentCache[id] = attachment;

    _logStock(bloodType, available, available - bags, me.name,
        'Pengajuan darah untuk pasien ${patientName.trim()}');
    stock[bloodType] = available - bags;
    _stockRequests.add(StockRequest(
      id: id,
      requesterId: me.id,
      requesterName: me.name,
      requesterPhone: me.phone,
      bloodType: bloodType,
      bags: bags,
      patientName: patientName.trim(),
      hospital: hospital.trim(),
      reason: reason.trim(),
      letterNo: letterNo.trim(),
      attachmentName: attachmentName,
      createdAt: DateTime.now(),
    ));
    await _persistStock();
    await _saveStockRequests();
    notifyListeners();
    return null;
  }

  /// Admin menyetujui pengajuan (bukti valid). Stok tetap tertahan untuk pemohon.
  Future<void> approveStockRequest(String id, {String note = ''}) async {
    final r = _findStock(id);
    if (r == null || r.status != StockRequestStatus.processing) return;
    r
      ..status = StockRequestStatus.approved
      ..approvedAt = DateTime.now()
      ..adminNote = note.trim();
    await _saveStockRequests();
    notifyListeners();
  }

  /// Admin menolak pengajuan; kantong dikembalikan ke stok.
  Future<void> rejectStockRequest(String id, String reason) async {
    final r = _findStock(id);
    if (r == null || r.status != StockRequestStatus.processing) return;
    final before = stock[r.bloodType] ?? 0;
    stock[r.bloodType] = before + r.bags;
    _logStock(r.bloodType, before, before + r.bags, 'Admin PMI',
        'Pengajuan ditolak (${r.requesterName})');
    r
      ..status = StockRequestStatus.rejected
      ..adminNote = reason.trim()
      ..resolvedAt = DateTime.now();
    await _persistStock();
    await _saveStockRequests();
    notifyListeners();
  }

  /// Admin menandai darah sudah diambil di PMI.
  Future<void> completeStockRequest(String id) async {
    final r = _findStock(id);
    if (r == null || !r.holdsStock) return;
    r
      ..status = StockRequestStatus.completed
      ..resolvedAt = DateTime.now();
    await _saveStockRequests();
    notifyListeners();
  }

  /// Admin membatalkan pengajuan; kantong dikembalikan ke stok.
  Future<void> cancelStockRequest(String id, {String note = ''}) async {
    final r = _findStock(id);
    if (r == null || !r.holdsStock) return;
    final before = stock[r.bloodType] ?? 0;
    stock[r.bloodType] = before + r.bags;
    _logStock(r.bloodType, before, before + r.bags, 'Admin PMI',
        'Pengajuan dibatalkan (${r.requesterName})');
    r
      ..status = StockRequestStatus.cancelled
      ..resolvedAt = DateTime.now();
    if (note.trim().isNotEmpty) r.adminNote = note.trim();
    await _persistStock();
    await _saveStockRequests();
    notifyListeners();
  }

  /// Pengajuan yang disetujui tetapi tidak diambil sebelum batas waktu
  /// dibatalkan otomatis dan stoknya dikembalikan. Mengembalikan jumlahnya.
  Future<int> expireOverdueStockRequests() async {
    final now = DateTime.now();
    var n = 0;
    for (final r in _stockRequests) {
      final d = r.pickupDeadline;
      if (r.status == StockRequestStatus.approved &&
          d != null &&
          now.isAfter(d)) {
        final before = stock[r.bloodType] ?? 0;
        stock[r.bloodType] = before + r.bags;
        _logStock(r.bloodType, before, before + r.bags, 'Sistem',
            'Tidak diambil dalam ${AppConstants.pickupDeadline.inHours} jam (${r.requesterName})');
        r
          ..status = StockRequestStatus.cancelled
          ..resolvedAt = now
          ..adminNote =
              'Dibatalkan otomatis: tidak diambil dalam ${AppConstants.pickupDeadline.inHours} jam setelah disetujui.';
        n++;
      }
    }
    if (n > 0) {
      await _persistStock();
      await _saveStockRequests();
      notifyListeners();
    }
    return n;
  }

  // ---------- chat ----------
  List<ChatThread> get myThreads {
    final me = currentUser;
    if (me == null) return [];
    return _threads
        .where((t) => t.requesterId == me.id || t.donorId == me.id)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  ChatThread? threadById(String id) {
    final i = _threads.indexWhere((t) => t.id == id);
    return i < 0 ? null : _threads[i];
  }

  /// Membuka percakapan untuk sebuah permohonan (membuat baru bila belum ada).
  Future<ChatThread> startChat(BloodRequest r) async {
    final me = currentUser!;
    final i =
        _threads.indexWhere((t) => t.requestId == r.id && t.donorId == me.id);
    if (i >= 0) return _threads[i];
    final t = ChatThread(
      id: _newId(),
      requestId: r.id,
      requesterId: r.requesterId,
      requesterName: r.requesterName,
      donorId: me.id,
      donorName: me.name,
      bloodType: r.bloodType,
      createdAt: DateTime.now(),
    );
    _threads.add(t);
    await _saveThreads();
    notifyListeners();
    return t;
  }

  Future<void> sendMessage(String threadId, String text) async {
    final t = threadById(threadId);
    if (t == null || currentUser == null) return;
    t.messages.add(ChatMessage(
      senderId: currentUser!.id,
      text: text.trim(),
      sentAt: DateTime.now(),
    ));
    await _saveThreads();
    notifyListeners();
  }

  // ---------- riwayat donor ----------
  List<DonorHistory> get myHistories {
    final me = currentUser;
    if (me == null) return [];
    return _histories.where((h) => h.userId == me.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  DateTime? get lastDonorDate {
    final h = myHistories;
    return h.isEmpty ? null : h.first.date;
  }

  int get totalBagsDonated => myHistories.fold(0, (s, h) => s + h.bags);

  /// Sisa hari sampai boleh donor lagi (0 = sudah siap).
  int get daysUntilEligible {
    final last = lastDonorDate;
    if (last == null) return 0;
    final next = last.add(const Duration(days: AppConstants.donorIntervalDays));
    final diff = next.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays + 1;
  }

  Future<void> addHistory({
    required String place,
    required String reason,
    required int bags,
    required DateTime date,
  }) async {
    _histories.add(DonorHistory(
      id: _newId(),
      userId: currentUser!.id,
      place: place.trim(),
      reason: reason.trim(),
      bags: bags,
      date: date,
    ));
    await _saveHistories();
    notifyListeners();
  }

  Future<void> deleteHistory(String id) async {
    _histories.removeWhere((h) => h.id == id);
    await _saveHistories();
    notifyListeners();
  }

  // ---------- stok & statistik (admin) ----------
  Future<void> updateStock(Map<String, int> newStock) async {
    for (final e in newStock.entries) {
      final before = stock[e.key] ?? 0;
      if (before != e.value) {
        _logStock(
            e.key, before, e.value, 'Admin PMI', 'Input manual oleh admin');
      }
    }
    stock.addAll(newStock);
    await _persistStock();
    notifyListeners();
  }

  int get totalUsers => _accounts.length;
  int get totalBagsRecorded => _histories.fold(0, (s, h) => s + h.bags);
  int get totalDonorsWithHistory =>
      _histories.map((h) => h.userId).toSet().length;
}
