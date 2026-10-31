<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\BloodUtils;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $request->merge([
            'username' => strtolower(trim((string) $request->input('username'))),
        ]);

        $data = $request->validate([
            'name' => 'required|string|max:100',
            'username' => ['required', 'string', 'min:4', 'max:30', 'regex:/^[a-z0-9_.]+$/', 'unique:users,username'],
            'password' => 'required|string|min:6|max:100',
            'phone' => 'required|string|min:9|max:30',
            'blood_type' => ['required', Rule::in(BloodUtils::TYPES)],
            'city' => 'required|string|max:100',
            'weight' => 'required|integer|between:20,250',
            'height' => 'required|integer|between:100,250',
        ], [
            'username.unique' => 'Username sudah dipakai, silakan pilih yang lain.',
        ]);

        $user = new User($data);
        $user->role = 'user';
        $user->save();

        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'user' => new UserResource($user),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
            'as_admin' => 'sometimes|boolean',
        ]);

        $user = User::where('username', strtolower(trim($data['username'])))->first();
        $invalid = response()->json(['message' => 'Username atau password salah.'], 401);

        if (!$user || !Hash::check($data['password'], $user->password)) {
            return $invalid;
        }
        // Bila app mengirim as_admin, tab yang dipilih harus cocok dengan role akun.
        if (array_key_exists('as_admin', $data) && (bool) $data['as_admin'] !== $user->isAdmin()) {
            return $invalid;
        }

        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'user' => new UserResource($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Berhasil keluar.']);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user());
    }

    /** Ganti sandi (juga dipakai setelah sandi sementara dari admin). */
    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:6|max:100',
        ]);

        $user = $request->user();

        if (!Hash::check($data['current_password'], $user->password)) {
            return response()->json(['message' => 'Sandi lama salah.'], 422);
        }
        if ($data['password'] === $data['current_password']) {
            return response()->json(['message' => 'Sandi baru harus berbeda dari sandi lama.'], 422);
        }

        $user->password = $data['password'];
        $user->must_change_password = false;
        $user->save();

        // Perangkat lain harus masuk ulang; perangkat ini tetap login.
        $current = $request->user()->currentAccessToken();
        $user->tokens()->where('id', '!=', $current->id)->delete();

        return response()->json(['user' => new UserResource($user)]);
    }

    public function updateProfile(Request $request): UserResource
    {
        $data = $request->validate([
            'name' => 'required|string|max:100',
            'phone' => 'required|string|min:9|max:30',
            'blood_type' => ['required', Rule::in(BloodUtils::TYPES)],
            'city' => 'required|string|max:100',
            'weight' => 'required|integer|between:20,250',
            'height' => 'required|integer|between:100,250',
        ]);

        $user = $request->user();
        $user->update($data);

        return new UserResource($user);
    }
}
