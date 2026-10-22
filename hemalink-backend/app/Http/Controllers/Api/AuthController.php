<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    // LOGIN
    public function login(Request $request)
    {
        $validated = $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('username', strtolower(trim($validated['username'])))->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'username' => ['Username atau password salah.'],
            ]);
        }

        // Buat token untuk login
        $token = $user->createToken('hemalink-token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'phone' => $user->phone,
                'blood_type' => $user->blood_type,
                'city' => $user->city,
                'weight' => $user->weight,
                'height' => $user->height,
                'role' => $user->role,
            ],
        ]);
    }

    // REGISTER (DAFTAR AKUN BARU)
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|unique:users,username',
            'password' => 'required|string|min:6',
            'phone' => 'nullable|string',
            'blood_type' => 'required|string',
            'city' => 'nullable|string',
            'weight' => 'nullable|integer',
            'height' => 'nullable|integer',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'username' => strtolower(trim($validated['username'])),
            'email' => strtolower(trim($validated['username'])) . '@hemalink.local',
            'password' => Hash::make($validated['password']),
            'phone' => $validated['phone'] ?? null,
            'blood_type' => $validated['blood_type'],
            'city' => $validated['city'] ?? null,
            'weight' => $validated['weight'] ?? null,
            'height' => $validated['height'] ?? null,
            'role' => 'user',
        ]);

        $token = $user->createToken('hemalink-token')->plainTextToken;

        return response()->json([
            'message' => 'Pendaftaran berhasil',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'phone' => $user->phone,
                'blood_type' => $user->blood_type,
                'city' => $user->city,
                'weight' => $user->weight,
                'height' => $user->height,
                'role' => $user->role,
            ],
        ], 201);
    }

    // LOGOUT (hapus token)
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Berhasil keluar']);
    }
}