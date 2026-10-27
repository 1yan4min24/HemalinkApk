<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BloodRequestResource;
use App\Models\BloodRequest;
use App\Models\BloodStock;
use App\Support\BloodUtils;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Forum permintaan darah (dipakai saat stok PMI kosong). */
class BloodRequestController extends Controller
{
    public function index()
    {
        return BloodRequestResource::collection(
            BloodRequest::with('user')->orderByDesc('id')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'blood_type' => ['required', Rule::in(BloodUtils::TYPES)],
            'bags' => 'required|integer|between:1,20',
            'reason' => 'required|string|max:500',
            'hospital' => 'required|string|max:200',
        ]);

        $stock = (int) BloodStock::where('blood_type', $data['blood_type'])->value('quantity');
        if ($stock > 0) {
            return response()->json([
                'message' => "Stok golongan {$data['blood_type']} masih tersedia di PMI. Silakan ajukan langsung ke PMI.",
            ], 422);
        }

        $req = BloodRequest::create([
            'user_id' => $request->user()->id,
            'blood_type' => $data['blood_type'],
            'bags' => $data['bags'],
            'reason' => trim($data['reason']),
            'hospital' => trim($data['hospital']),
        ]);

        return new BloodRequestResource($req->load('user'));
    }

    public function destroy(Request $request, BloodRequest $bloodRequest): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->isAdmin() || (int) $bloodRequest->user_id === (int) $user->id, 403, 'Tidak diizinkan.');

        $bloodRequest->delete();

        return response()->json(['message' => 'Permintaan dihapus.']);
    }
}
