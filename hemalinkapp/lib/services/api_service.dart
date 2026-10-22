import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

// ✅ Untuk emulator Android (10.0.2.2 = localhost di komputer)
const String baseUrl = "http://10.0.2.2:8000/api";

class ApiService {
  final StorageService _storage;
  ApiService(this._storage);

  // === REGISTER (DAFTAR AKUN BARU) ===
  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String password,
    required String phone,
    required String bloodType,
    required String city,
    required int weight,
    required int height,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json", // ✅ TAMBAHAN: minta balasan JSON
      },
      body: jsonEncode({
        "name": name,
        "username": username,
        "password": password,
        "phone": phone,
        "blood_type": bloodType,
        "city": city,
        "weight": weight,
        "height": height,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['token'] != null) {
        await _storage.writeString('auth_token', data['token']);
      }
      if (data['user'] != null) {
        await _storage.writeMap('pengguna', data['user']);
      }
      return data;
    }
    throw Exception("Daftar gagal: ${res.body}");
  }

  // === LOGIN ===
  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json", // ✅ TAMBAHAN: minta balasan JSON
      },
      body: jsonEncode({"username": username, "password": password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['token'] != null) {
        await _storage.writeString('auth_token', data['token']);
      }
      if (data['user'] != null) {
        await _storage.writeMap('pengguna', data['user']);
      }
      return data;
    }
    throw Exception("Login gagal: ${res.body}");
  }

  // === AMBIL TOKEN ===
  String? _ambilToken() {
    return _storage.readString('auth_token');
  }

  // === CEK SUDAH LOGIN ===
  bool sudahLogin() {
    return _ambilToken() != null;
  }

  // === LOGOUT ===
  Future<void> logout() async {
    await _storage.remove('auth_token');
    await _storage.remove('pengguna');
    await _storage.remove('daftar_kebutuhan');
  }

  // === AMBIL DAFTAR PERMINTAAN DARAH ===
  Future<List<Map<String, dynamic>>> getKebutuhanDarah(
      {bool refresh = false}) async {
    final token = _ambilToken();
    if (token == null) throw Exception("Belum login");

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/blood-requests"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json", // ✅ TAMBAHAN
        },
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final hasil =
            data.map((e) => (e as Map).cast<String, dynamic>()).toList();
        await _storage.writeList('daftar_kebutuhan', hasil);
        return hasil;
      }
    } catch (e) {
      print("Gagal ambil dari server, pakai data tersimpan: $e");
    }
    return _storage.readList('daftar_kebutuhan');
  }

  // === BUAT PERMINTAAN DARAH ===
  Future<Map<String, dynamic>> buatPermintaan(Map<String, dynamic> data) async {
    final token = _ambilToken();
    if (token == null) throw Exception("Belum login");

    final res = await http.post(
      Uri.parse("$baseUrl/blood-requests"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json", // ✅ TAMBAHAN
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final hasil = jsonDecode(res.body) as Map<String, dynamic>;
      await getKebutuhanDarah(refresh: true);
      return hasil;
    }
    throw Exception("Gagal kirim permintaan: ${res.body}");
  }

  // === CARI PENDONOR ===
  Future<List<Map<String, dynamic>>> cariPendonor(String golonganDarah) async {
    final token = _ambilToken();
    if (token == null) throw Exception("Belum login");

    final res = await http.get(
      Uri.parse("$baseUrl/cari-pendonor/$golonganDarah"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json", // ✅ TAMBAHAN
      },
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    throw Exception("Gagal cari pendonor: ${res.body}");
  }
}
