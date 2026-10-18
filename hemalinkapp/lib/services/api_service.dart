import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

// Ganti dengan alamat backend kamu
const String baseUrl = "http://10.0.2.2:3000/api";

class ApiService {
  final StorageService _storage;
  ApiService(this._storage);

  // === LOGIN ===
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['token'] != null) {
        await _storage.writeString('auth_token', data['token']);
      }
      // Simpan data pengguna juga kalau ada
      if (data['pengguna'] != null) {
        await _storage.writeMap('pengguna', data['pengguna']);
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

  // === AMBIL DAFTAR KEBUTUHAN DARAH ===
  Future<List<Map<String, dynamic>>> getKebutuhanDarah(
      {bool refresh = false}) async {
    // Coba ambil dari server dulu
    final token = _ambilToken();
    if (token == null) throw Exception("Belum login");

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/kebutuhan"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final hasil =
            data.map((e) => (e as Map).cast<String, dynamic>()).toList();
        // Simpan ke penyimpanan lokal untuk cadangan
        await _storage.writeList('daftar_kebutuhan', hasil);
        return hasil;
      }
    } catch (e) {
      // Kalau server mati, pakai data lokal terakhir
      print("Gagal ambil dari server, pakai data tersimpan: $e");
    }

    // Kembalikan data tersimpan
    return _storage.readList('daftar_kebutuhan');
  }

  // === BUAT PERMINTAAN DARAH ===
  Future<Map<String, dynamic>> buatPermintaan(Map<String, dynamic> data) async {
    final token = _ambilToken();
    if (token == null) throw Exception("Belum login");

    final res = await http.post(
      Uri.parse("$baseUrl/kebutuhan"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final hasil = jsonDecode(res.body) as Map<String, dynamic>;
      // Segarkan daftar setelah tambah
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
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    throw Exception("Gagal cari pendonor: ${res.body}");
  }
}
