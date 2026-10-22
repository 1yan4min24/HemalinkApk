import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/blood_request.dart';
import '../models/chat_thread.dart';
import '../models/donor_history.dart';
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
  }

  // ---------- state ----------
  List<UserAccount> _accounts = [];
  List<BloodRequest> _requests = [];
  List<ChatThread> _threads = [];
  List<DonorHistory> _histories = [];
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
    for (final t in _threads) {
      if (t.requesterId == me.id) t.requesterName = updated.name;
      if (t.donorId == me.id) t.donorName = updated.name;
    }
    await _saveAccounts();
    await _saveRequests();
    await _saveThreads();
    notifyListeners();
  }

  // ---------- permohonan ----------
  /// Permohonan yang boleh dilihat user: yang sudah diverifikasi + miliknya sendiri.
  List<BloodRequest> get visibleRequests {
    final me = currentUser;
    final list = _requests
        .where((r) => r.verified || (me != null && r.requesterId == me.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<BloodRequest> get pendingRequests =>
      _requests.where((r) => !r.verified).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get totalRequests => _requests.length;
  int get activeRequests => _requests.where((r) => r.verified).length;

  Future<void> addRequest({
    required String bloodType,
    required int bags,
    required String reason,
    required String hospital,
  }) async {
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
  }

  Future<void> deleteRequest(String id) async {
    _requests.removeWhere((r) => r.id == id);
    await _saveRequests();
    notifyListeners();
  }

  Future<void> approveRequest(String id) async {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i >= 0) _requests[i].verified = true;
    await _saveRequests();
    notifyListeners();
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
    stock.addAll(newStock);
    stockUpdatedAt = DateTime.now();
    await _store.writeMap('stock', stock);
    await _store.writeString(
        'stock_updated', stockUpdatedAt!.toIso8601String());
    notifyListeners();
  }

  int get totalUsers => _accounts.length;
  int get totalBagsRecorded => _histories.fold(0, (s, h) => s + h.bags);
  int get totalDonorsWithHistory =>
      _histories.map((h) => h.userId).toSet().length;
}
