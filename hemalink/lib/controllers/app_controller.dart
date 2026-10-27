import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/blood_request.dart';
import '../models/chat_thread.dart';
import '../models/donor_history.dart';
import '../models/stock_log.dart';
import '../models/stock_request.dart';
import '../models/user_account.dart';
import '../screens/auth/login_screen.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Pusat state & logika aplikasi. Semua layar membaca dari sini.
/// Data sekarang berasal dari backend Laravel (lihat api_service.dart);
/// SharedPreferences hanya menyimpan token dan data akun untuk sesi.
class AppController extends ChangeNotifier {
  AppController._(this._store, this._api) {
    _api.onUnauthorized = _handleUnauthorized;
  }

  static late AppController instance;

  /// Dipasang di MaterialApp (lihat main.dart).
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  final StorageService _store;
  final ApiService _api;

  static Future<void> init() async {
    final store = await StorageService.create();
    final c = AppController._(store, ApiService());
    instance = c;
    c._restoreSession();
    if (c.isLoggedIn) {
      // Tunggu data awal sebentar agar layar pertama langsung terisi.
      await c.refreshAll().timeout(const Duration(seconds: 6), onTimeout: () {});
      if (c.isLoggedIn) c._startPolling(); // bisa false bila token sudah kedaluwarsa
    }
  }

  // ---------- state ----------
  List<BloodRequest> _requests = [];
  List<ChatThread> _threads = [];
  List<DonorHistory> _histories = [];
  List<StockRequest> _stockRequests = []; // user: milik sendiri, admin: semua
  List<StockLog> _stockLogs = [];
  Map<String, dynamic> _stats = {};
  final Map<String, int> stock = {
    for (final t in AppConstants.bloodTypes) t: 0
  };
  DateTime? stockUpdatedAt;

  UserAccount? currentUser;
  bool isAdmin = false;
  bool get isLoggedIn => currentUser != null;

  final Map<String, String> _sig = {}; // tanda data terakhir, untuk mendeteksi perubahan
  final Map<String, Uint8List> _attachmentCache = {};

  // ---------- util ----------
  String _msg(Object e) => e is ApiException ? e.message : 'Terjadi kesalahan: $e';

  void _toast(String msg) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Menjalankan aksi; mengembalikan pesan error atau null jika berhasil.
  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// Seperti [_run], tetapi error ditampilkan sebagai snackbar.
  Future<void> _runToast(Future<void> Function() action) async {
    final err = await _run(action);
    if (err != null) _toast(err);
  }

  /// Untuk pemuat data latar belakang: error cukup dicatat.
  Future<void> _quiet(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[API] ${_msg(e)}');
    }
  }

  bool _changed(String key, Object? raw) {
    final s = jsonEncode(raw);
    if (_sig[key] == s) return false;
    _sig[key] = s;
    return true;
  }

  // ---------- sesi ----------
  void _restoreSession() {
    final token = _store.readString('auth_token');
    final user = _store.readMap('pengguna');
    if (token == null || user == null) return;
    _api.token = token;
    _applyUser(user);
  }

  void _applyUser(Map<String, dynamic> u) {
    currentUser = UserAccount(
      id: u['id'].toString(),
      name: (u['name'] as String?) ?? '',
      username: (u['username'] as String?) ?? '',
      passwordHash: '',
      phone: (u['phone'] as String?) ?? '',
      bloodType: (u['blood_type'] as String?) ?? '',
      city: (u['city'] as String?) ?? '',
      weight: (u['weight'] as num?)?.toInt() ?? 0,
      height: (u['height'] as num?)?.toInt() ?? 0,
    );
    isAdmin = u['role'] == 'admin';
  }

  Future<void> _startSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = (data['user'] as Map).cast<String, dynamic>();
    _resetData();
    _api.token = token;
    await _store.writeString('auth_token', token);
    await _store.writeMap('pengguna', user);
    _applyUser(user);
    notifyListeners();
    await refreshAll();
    _startPolling();
  }

  void _resetData() {
    _requests = [];
    _threads = [];
    _histories = [];
    _stockRequests = [];
    _stockLogs = [];
    _stats = {};
    for (final t in AppConstants.bloodTypes) {
      stock[t] = 0;
    }
    stockUpdatedAt = null;
    _sig.clear();
    _attachmentCache.clear();
  }

  Future<void> _clearSession() async {
    _stopPolling();
    _api.token = null;
    currentUser = null;
    isAdmin = false;
    _resetData();
    notifyListeners();
    await _store.remove('auth_token');
    await _store.remove('pengguna');
  }

  bool _loggingOut = false;

  void _handleUnauthorized() {
    if (_loggingOut || !isLoggedIn) return;
    _clearSession();
    _toast('Sesi berakhir, silakan masuk lagi.');
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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
  }) =>
      _run(() async {
        final data = await _api.register({
          'name': name.trim(),
          'username': username.trim().toLowerCase(),
          'password': password,
          'phone': phone.trim(),
          'blood_type': bloodType,
          'city': city.trim(),
          'weight': weight,
          'height': height,
        });
        await _startSession(data);
      });

  Future<String?> login(String username, String password,
          {required bool asAdmin}) =>
      _run(() async {
        final data = await _api.login(username.trim().toLowerCase(), password,
            asAdmin: asAdmin);
        await _startSession(data);
      });

  Future<void> logout() async {
    _loggingOut = true;
    try {
      await _api.logout();
    } catch (_) {
      // abaikan: token tetap dihapus di perangkat
    }
    await _clearSession();
    _loggingOut = false;
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String bloodType,
    required String city,
    required int weight,
    required int height,
  }) =>
      _runToast(() async {
        final m = await _api.updateProfile({
          'name': name.trim(),
          'phone': phone.trim(),
          'blood_type': bloodType,
          'city': city.trim(),
          'weight': weight,
          'height': height,
        });
        await _store.writeMap('pengguna', m);
        _applyUser(m);
        notifyListeners();
        unawaited(refreshAll());
      });

  // ---------- memuat data ----------
  Future<void> refreshAll() async {
    if (!isLoggedIn) return;
    await Future.wait([
      _loadStock(),
      _loadRequests(),
      _loadStockRequests(),
      if (isAdmin) _loadStockLogs(),
      if (isAdmin) _loadStats(),
      if (!isAdmin) _loadThreads(),
      if (!isAdmin) _loadHistories(),
    ]);
  }

  void _applyStock(Map<String, dynamic> m) {
    final st = (m['stock'] as Map).cast<String, dynamic>();
    for (final t in AppConstants.bloodTypes) {
      stock[t] = (st[t] as num?)?.toInt() ?? 0;
    }
    final ts = m['updatedAt'] as String?;
    stockUpdatedAt = ts == null ? null : DateTime.tryParse(ts)?.toLocal();
    notifyListeners();
  }

  Future<void> _loadStock() => _quiet(() async {
        final m = await _api.stock();
        if (_changed('stock', m)) _applyStock(m);
      });

  Future<void> _loadRequests() => _quiet(() async {
        final raw = await _api.bloodRequests();
        if (!_changed('requests', raw)) return;
        _requests = raw.map(BloodRequest.fromJson).toList();
        notifyListeners();
      });

  Future<void> _loadStockRequests() => _quiet(() async {
        final raw =
            isAdmin ? await _api.adminStockRequests() : await _api.myStockRequests();
        if (!_changed('stockRequests', raw)) return;
        _stockRequests = raw.map(StockRequest.fromJson).toList();
        notifyListeners();
      });

  Future<void> _loadStockLogs() => _quiet(() async {
        final raw = await _api.stockLogs();
        if (!_changed('stockLogs', raw)) return;
        _stockLogs = raw.map(StockLog.fromJson).toList();
        notifyListeners();
      });

  Future<void> _loadStats() => _quiet(() async {
        final m = await _api.adminStats();
        if (!_changed('stats', m)) return;
        _stats = m;
        notifyListeners();
      });

  Future<void> _loadThreads() => _quiet(() async {
        final raw = await _api.chatThreads();
        if (!_changed('threads', raw)) return;
        _threads = raw.map(ChatThread.fromJson).toList();
        notifyListeners();
      });

  Future<void> _loadHistories() => _quiet(() async {
        final raw = await _api.donorHistories();
        if (!_changed('histories', raw)) return;
        _histories = raw.map(DonorHistory.fromJson).toList();
        notifyListeners();
      });

  // ---------- polling sementara (digantikan WebSocket/Reverb nanti) ----------
  Timer? _timer;
  int _tick = 0;
  bool _polling = false;

  void _startPolling() {
    _timer?.cancel();
    _tick = 0;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (!isLoggedIn || _polling) return;
    _polling = true;
    try {
      _tick++;
      if (isAdmin) {
        await Future.wait([_loadStockRequests(), _loadStock()]);
      } else {
        await Future.wait([_loadThreads(), _loadStockRequests()]);
      }
      if (_tick % 5 == 0) {
        await Future.wait([
          _loadRequests(),
          if (!isAdmin) _loadStock(),
          if (isAdmin) _loadStats(),
        ]);
      }
    } finally {
      _polling = false;
    }
  }

  // ---------- permohonan (forum) ----------
  List<BloodRequest> get visibleRequests =>
      _requests.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get totalRequests => _requests.length;
  int get activeRequests => _requests.length;

  /// Mengembalikan pesan error, atau null jika berhasil.
  /// Forum hanya untuk golongan darah yang stoknya kosong di PMI (dicek server).
  Future<String?> addRequest({
    required String bloodType,
    required int bags,
    required String reason,
    required String hospital,
  }) =>
      _run(() async {
        final m = await _api.createBloodRequest({
          'blood_type': bloodType,
          'bags': bags,
          'reason': reason.trim(),
          'hospital': hospital.trim(),
        });
        _requests.add(BloodRequest.fromJson(m));
        _sig.remove('requests');
        notifyListeners();
      });

  Future<void> deleteRequest(String id) => _runToast(() async {
        await _api.deleteBloodRequest(id);
        _requests.removeWhere((r) => r.id == id);
        _sig.remove('requests');
        notifyListeners();
      });

  // ---------- pengajuan stok PMI ----------
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

  /// Foto bukti rekomendasi rumah sakit untuk sebuah pengajuan (diunduh dari server).
  Future<Uint8List?> stockAttachment(String id) async {
    final cached = _attachmentCache[id];
    if (cached != null) return cached;
    try {
      final bytes = await _api.stockAttachment(id);
      _attachmentCache[id] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('[API] bukti $id: ${_msg(e)}');
      return null;
    }
  }

  void _replaceStockRequest(Map<String, dynamic> m) {
    final r = StockRequest.fromJson(m);
    final i = _stockRequests.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      _stockRequests[i] = r;
    } else {
      _stockRequests.add(r);
    }
    _sig.remove('stockRequests');
    notifyListeners();
  }

  /// Pengaju langsung "mengunci" kantong darahnya: stok berkurang di server.
  /// Mengembalikan pesan error, atau null jika berhasil.
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
    if (currentUser == null) return 'Silakan login terlebih dahulu.';
    return _run(() async {
      final m = await _api.createStockRequest(
        fields: {
          'blood_type': bloodType,
          'bags': '$bags',
          'patient_name': patientName.trim(),
          'hospital': hospital.trim(),
          'reason': reason.trim(),
          'letter_no': letterNo.trim(),
          'attachment_name': attachmentName,
        },
        attachment: attachment,
        filename: attachmentName.isEmpty ? 'bukti.jpg' : attachmentName,
      );
      final id = m['id'].toString();
      _attachmentCache[id] = attachment;
      _replaceStockRequest(m);
      await _loadStock();
    });
  }

  /// Admin menyetujui pengajuan (bukti valid). Stok tetap tertahan untuk pemohon.
  Future<void> approveStockRequest(String id, {String note = ''}) =>
      _runToast(() async {
        _replaceStockRequest(await _api.approveStockRequest(id, note.trim()));
      });

  /// Admin menolak pengajuan; kantong dikembalikan ke stok.
  Future<void> rejectStockRequest(String id, String reason) =>
      _runToast(() async {
        _replaceStockRequest(await _api.rejectStockRequest(id, reason.trim()));
        await Future.wait([_loadStock(), _loadStockLogs()]);
      });

  /// Admin menandai darah sudah diambil di PMI.
  Future<void> completeStockRequest(String id) => _runToast(() async {
        _replaceStockRequest(await _api.completeStockRequest(id));
      });

  /// Admin membatalkan pengajuan; kantong dikembalikan ke stok.
  Future<void> cancelStockRequest(String id, {String note = ''}) =>
      _runToast(() async {
        _replaceStockRequest(await _api.cancelStockRequest(id, note.trim()));
        await Future.wait([_loadStock(), _loadStockLogs()]);
      });

  /// Pembatalan otomatis (24 jam) dilakukan server. Method ini hanya memuat ulang
  /// data supaya perubahan terlihat; mengembalikan jumlah pembatalan baru.
  Future<int> expireOverdueStockRequests() async {
    if (!isLoggedIn) return 0;
    final before = stockCount(StockRequestStatus.cancelled);
    await Future.wait([_loadStockRequests(), _loadStock()]);
    final diff = stockCount(StockRequestStatus.cancelled) - before;
    return diff < 0 ? 0 : diff;
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

  void _upsertThread(ChatThread t) {
    final i = _threads.indexWhere((e) => e.id == t.id);
    if (i >= 0) {
      _threads[i] = t;
    } else {
      _threads.add(t);
    }
    _sig.remove('threads');
    notifyListeners();
  }

  /// Membuka percakapan untuk sebuah permohonan (membuat baru bila belum ada).
  /// Mengembalikan null bila gagal (pesan error tampil sebagai snackbar).
  Future<ChatThread?> startChat(BloodRequest r) async {
    try {
      final t = ChatThread.fromJson(await _api.startChat(r.id));
      _upsertThread(t);
      return t;
    } catch (e) {
      _toast(_msg(e));
      return null;
    }
  }

  Future<void> sendMessage(String threadId, String text) => _runToast(() async {
        final m = ChatMessage.fromJson(
            await _api.sendMessage(threadId, text.trim()));
        final t = threadById(threadId);
        if (t == null) return;
        final dup = t.messages.any((x) =>
            x.senderId == m.senderId &&
            x.text == m.text &&
            x.sentAt.isAtSameMomentAs(m.sentAt));
        if (!dup) t.messages.add(m);
        _sig.remove('threads');
        notifyListeners();
      });

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
  }) =>
      _runToast(() async {
        final m = await _api.addDonorHistory({
          'place': place.trim(),
          'reason': reason.trim(),
          'bags': bags,
          'date': date.toUtc().toIso8601String(),
        });
        _histories.add(DonorHistory.fromJson(m));
        _sig.remove('histories');
        notifyListeners();
      });

  Future<void> deleteHistory(String id) => _runToast(() async {
        await _api.deleteDonorHistory(id);
        _histories.removeWhere((h) => h.id == id);
        _sig.remove('histories');
        notifyListeners();
      });

  // ---------- stok & statistik (admin) ----------
  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> updateStock(Map<String, int> newStock) => _run(() async {
        final m = await _api.updateStock(newStock);
        _sig['stock'] = jsonEncode(m);
        _applyStock(m);
        await _loadStockLogs();
      });

  int _stat(String key) => (_stats[key] as num?)?.toInt() ?? 0;

  int get totalUsers => _stat('totalUsers');
  int get totalBagsRecorded => _stat('totalBagsRecorded');
  int get totalDonorsWithHistory => _stat('totalDonorsWithHistory');
}
