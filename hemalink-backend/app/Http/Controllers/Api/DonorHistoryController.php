<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DonorHistoryResource;
use App\Models\DonorHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class DonorHistoryController extends Controller
{
    public function index(Request $request)
    {
        return DonorHistoryResource::collection(
            DonorHistory::where('user_id', $request->user()->id)->orderByDesc('date')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'place' => 'required|string|max:200',
            'reason' => 'required|string|max:200',
            'bags' => 'required|integer|between:1,50',
            'date' => 'required|date',
        ]);

        $history = DonorHistory::create([
            'user_id' => $request->user()->id,
            'place' => trim($data['place']),
            'reason' => trim($data['reason']),
            'bags' => $data['bags'],
            'date' => Carbon::parse($data['date']),
        ]);

        return new DonorHistoryResource($history);
    }

    public function destroy(Request $request, DonorHistory $donorHistory): JsonResponse
    {
        abort_unless((int) $donorHistory->user_id === (int) $request->user()->id, 403, 'Tidak diizinkan.');
        $donorHistory->delete();

        return response()->json(['message' => 'Riwayat dihapus.']);
    }
}
