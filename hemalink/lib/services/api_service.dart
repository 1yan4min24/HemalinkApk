import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Alamat backend Laravel.
/// - Emulator Android : 10.0.2.2 (= localhost komputer)
/// - HP fisik         : ganti dengan IP laptop, mis. http://192.168.1.10:8000/api
const String baseUrl = 'http://10.0.2.2:8000/api';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Lapisan HTTP ke backend. Tidak menyimpan apa pun ke perangkat:
/// token disimpan & dipasang oleh AppController.
class ApiService {
  String? token;

  /// Dipanggil saat server menjawab 401 padahal sudah login (token kedaluwarsa).
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 60);

  Map<String, String> _headers({bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<http.Response> _send(http.BaseRequest req, Duration timeout) async {
    try {
      final streamed = await req.send().timeout(timeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
          'Server tidak merespons. Periksa koneksi dan pastikan backend menyala.');
    } catch (_) {
      throw ApiException(
          'Tidak dapat terhubung ke server. Pastikan backend menyala ($baseUrl).');
    }
  }

  dynamic _decode(http.Response res, {bool auth = true}) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    if (res.statusCode == 401 && auth && token != null) {
      onUnauthorized?.call();
      throw const ApiException('Sesi berakhir, silakan masuk lagi.', 401);
    }
    throw ApiException(_errorMessage(res), res.statusCode);
  }

  String _errorMessage(http.Response res) {
    try {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (d is Map) {
        final errors = d['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return '${first.first}';
          if (first != null) return '$first';
        }
        final m = d['message'];
        if (m is String && m.isNotEmpty) return m;
      }
    } catch (_) {}
    if (res.statusCode >= 500) {
      return 'Terjadi kesalahan di server (${res.statusCode}).';
    }
    return 'Permintaan gagal (${res.statusCode}).';
  }

  Future<dynamic> _call(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final req = http.Request(method, _uri(path, query));
    req.headers.addAll(_headers(json: body != null));
    if (body != null) req.body = jsonEncode(body);
    final res = await _send(req, _timeout);
    return _decode(res, auth: auth);
  }

  Map<String, dynamic> _map(dynamic d) => (d as Map).cast<String, dynamic>();

  List<Map<String, dynamic>> _list(dynamic d) =>
      (d as List).map((e) => (e as Map).cast<String, dynamic>()).toList();

  // ---------- auth ----------
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async =>
      _map(await _call('POST', '/register', body: body, auth: false));

  Future<Map<String, dynamic>> login(String username, String password,
          {required bool asAdmin}) async =>
      _map(await _call('POST', '/login',
          body: {
            'username': username,
            'password': password,
            'as_admin': asAdmin,
          },
          auth: false));

  Future<void> logout() => _call('POST', '/logout');

  // ---------- lupa & ganti sandi ----------
  /// Publik. Server selalu menjawab sama (tidak membocorkan username terdaftar).
  Future<void> forgotPassword(String username, String phone) => _call(
      'POST', '/forgot-password',
      body: {'username': username, 'phone': phone}, auth: false);

  Future<Map<String, dynamic>> changePassword(
          String current, String newPassword) async =>
      _map(await _call('POST', '/change-password',
          body: {'current_password': current, 'password': newPassword}));

  Future<List<Map<String, dynamic>>> adminPasswordResets() async =>
      _list(await _call('GET', '/admin/password-resets'));

  /// Mengembalikan {request, tempPassword}; sandi sementara hanya tampil sekali.
  Future<Map<String, dynamic>> approvePasswordReset(String id) async =>
      _map(await _call('POST', '/admin/password-resets/$id/approve'));

  Future<void> rejectPasswordReset(String id) =>
      _call('POST', '/admin/password-resets/$id/reject');

  Future<Map<String, dynamic>> me() async => _map(await _call('GET', '/me'));

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async =>
      _map(await _call('PUT', '/profile', body: body));

  // ---------- stok ----------
  Future<Map<String, dynamic>> stock() async =>
      _map(await _call('GET', '/stock'));

  Future<Map<String, dynamic>> updateStock(Map<String, int> stock) async =>
      _map(await _call('PUT', '/admin/stock', body: {'stock': stock}));

  Future<List<Map<String, dynamic>>> stockLogs() async =>
      _list(await _call('GET', '/admin/stock-logs'));

  Future<Map<String, dynamic>> adminStats() async =>
      _map(await _call('GET', '/admin/stats'));

  // ---------- forum ----------
  Future<List<Map<String, dynamic>>> bloodRequests() async =>
      _list(await _call('GET', '/blood-requests'));

  Future<Map<String, dynamic>> createBloodRequest(
          Map<String, dynamic> body) async =>
      _map(await _call('POST', '/blood-requests', body: body));

  Future<void> deleteBloodRequest(String id) =>
      _call('DELETE', '/blood-requests/$id');

  // ---------- pengajuan ke PMI ----------
  Future<List<Map<String, dynamic>>> myStockRequests() async =>
      _list(await _call('GET', '/stock-requests'));

  Future<List<Map<String, dynamic>>> adminStockRequests() async =>
      _list(await _call('GET', '/admin/stock-requests'));

  Future<Map<String, dynamic>> createStockRequest({
    required Map<String, String> fields,
    required Uint8List attachment,
    required String filename,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/stock-requests'));
    req.headers.addAll(_headers());
    req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes('attachment', attachment,
        filename: filename));
    final res = await _send(req, _uploadTimeout);
    return _map(_decode(res));
  }

  Future<Uint8List> stockAttachment(String id) async {
    final req = http.Request('GET', _uri('/stock-requests/$id/attachment'));
    req.headers.addAll(_headers());
    final res = await _send(req, _uploadTimeout);
    if (res.statusCode == 200) return res.bodyBytes;
    _decode(res); // melempar ApiException yang sesuai
    throw ApiException('Bukti tidak tersedia.', res.statusCode);
  }

  Future<Map<String, dynamic>> approveStockRequest(
          String id, String note) async =>
      _map(await _call('POST', '/admin/stock-requests/$id/approve',
          body: {'note': note}));

  Future<Map<String, dynamic>> rejectStockRequest(
          String id, String reason) async =>
      _map(await _call('POST', '/admin/stock-requests/$id/reject',
          body: {'reason': reason}));

  Future<Map<String, dynamic>> completeStockRequest(String id) async =>
      _map(await _call('POST', '/admin/stock-requests/$id/complete'));

  Future<Map<String, dynamic>> cancelStockRequest(
          String id, String note) async =>
      _map(await _call('POST', '/admin/stock-requests/$id/cancel',
          body: {'note': note}));

  // ---------- chat ----------
  Future<List<Map<String, dynamic>>> chatThreads() async =>
      _list(await _call('GET', '/chat-threads'));

  Future<Map<String, dynamic>> startChat(String requestId) async =>
      _map(await _call('POST', '/chat-threads',
          body: {'request_id': int.tryParse(requestId) ?? requestId}));

  /// Hapus percakapan hanya untuk saya (lawan chat tetap melihatnya).
  Future<void> deleteChatThread(String threadId) =>
      _call('DELETE', '/chat-threads/$threadId');

  Future<Map<String, dynamic>> sendMessage(
          String threadId, String text) async =>
      _map(await _call('POST', '/chat-threads/$threadId/messages',
          body: {'text': text}));

  // ---------- riwayat donor ----------
  Future<List<Map<String, dynamic>>> donorHistories() async =>
      _list(await _call('GET', '/donor-histories'));

  Future<Map<String, dynamic>> addDonorHistory(
          Map<String, dynamic> body) async =>
      _map(await _call('POST', '/donor-histories', body: body));

  Future<void> deleteDonorHistory(String id) =>
      _call('DELETE', '/donor-histories/$id');

  // ---------- lain-lain ----------
  Future<List<Map<String, dynamic>>> cariPendonor(String bloodType) async =>
      _list(await _call(
          'GET', '/cari-pendonor/${Uri.encodeComponent(bloodType)}'));
}
