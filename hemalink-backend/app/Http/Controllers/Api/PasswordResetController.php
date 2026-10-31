<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PasswordResetResource;
use App\Models\PasswordResetRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PasswordResetController extends Controller
{
    private static function normalizePhone(string $p): string
    {
        $d = preg_replace('/\D+/', '', $p) ?? '';
        if (str_starts_with($d, '62')) {
            $d = '0' . substr($d, 2); // +62812... == 0812...
        }

        return $d;
    }

    /**
     * Publik: pengguna yang lupa sandi mengirim username + nomor HP.
     * Jawabannya selalu sama agar orang lain tidak bisa menebak username yang terdaftar.
     */
    public function forgot(Request $request): JsonResponse
    {
        $data = $request->validate([
            'username' => 'required|string|max:50',
            'phone' => 'required|string|max:30',
        ]);

        $user = User::where('username', strtolower(trim($data['username'])))
            ->where('role', 'user')
            ->first();

        if ($user && self::normalizePhone($user->phone) !== '' &&
            self::normalizePhone($user->phone) === self::normalizePhone($data['phone'])) {
            $pending = PasswordResetRequest::where('user_id', $user->id)
                ->where('status', PasswordResetRequest::PENDING)
                ->exists();
            if (!$pending) {
                PasswordResetRequest::create(['user_id' => $user->id]);
            }
        }

        return response()->json([
            'message' => 'Jika data cocok, permintaan Anda sudah diterima. Admin PMI akan menghubungi nomor HP Anda.',
        ]);
    }

    /** Admin: permintaan yang menunggu (terlama dulu) lalu riwayat terbaru. */
    public function index()
    {
        $pending = PasswordResetRequest::with('user')
            ->where('status', PasswordResetRequest::PENDING)
            ->orderBy('id')
            ->get();
        $handled = PasswordResetRequest::with('user')
            ->where('status', '!=', PasswordResetRequest::PENDING)
            ->orderByDesc('id')
            ->limit(20)
            ->get();

        return PasswordResetResource::collection($pending->concat($handled)->values());
    }

    /** Admin: buat sandi sementara. Sandi hanya ditampilkan SEKALI di respons ini. */
    public function approve(Request $request, PasswordResetRequest $passwordReset): JsonResponse
    {
        $temp = self::tempPassword();

        $req = DB::transaction(function () use ($request, $passwordReset, $temp) {
            $req = PasswordResetRequest::with('user')->lockForUpdate()->findOrFail($passwordReset->id);
            if ($req->status !== PasswordResetRequest::PENDING) {
                abort(422, 'Permintaan ini sudah ditangani.');
            }

            $user = $req->user;
            $user->password = $temp; // di-hash otomatis (cast "hashed")
            $user->must_change_password = true;
            $user->save();
            $user->tokens()->delete(); // keluarkan dari semua perangkat

            $req->update([
                'status' => PasswordResetRequest::DONE,
                'handled_by' => $request->user()->id,
                'handled_at' => now(),
            ]);

            return $req;
        });

        return response()->json([
            'request' => (new PasswordResetResource($req))->resolve(),
            'tempPassword' => $temp,
        ]);
    }

    public function reject(Request $request, PasswordResetRequest $passwordReset)
    {
        abort_unless($passwordReset->status === PasswordResetRequest::PENDING, 422, 'Permintaan ini sudah ditangani.');

        $passwordReset->update([
            'status' => PasswordResetRequest::REJECTED,
            'handled_by' => $request->user()->id,
            'handled_at' => now(),
        ]);

        return new PasswordResetResource($passwordReset->load('user'));
    }

    /** 8 karakter acak tanpa karakter yang mirip (0/O, 1/I/l). */
    private static function tempPassword(): string
    {
        $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        $out = '';
        for ($i = 0; $i < 8; $i++) {
            $out .= $chars[random_int(0, strlen($chars) - 1)];
        }

        return $out;
    }
}
