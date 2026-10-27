<?php

namespace App\Http\Controllers\Api;

use App\Support\Dt;
use App\Http\Controllers\Controller;
use App\Http\Resources\StockLogResource;
use App\Models\BloodStock;
use App\Models\StockLog;
use App\Services\StockService;
use App\Support\BloodUtils;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class StockController extends Controller
{
    /** Stok per golongan: {"stock": {"A+": 3, ...}, "updatedAt": "..."} */
    public function show(): JsonResponse
    {
        $rows = BloodStock::pluck('quantity', 'blood_type');
        $stock = [];
        foreach (BloodUtils::TYPES as $t) {
            $stock[$t] = (int) ($rows[$t] ?? 0);
        }
        $updated = BloodStock::max('updated_at');

        return response()->json([
            'stock' => $stock,
            'updatedAt' => $updated ? Dt::iso($updated) : null,
        ]);
    }

    /** Admin: input stok manual. Body: {"stock": {"A+": 5, "B+": 2, ...}} */
    public function update(Request $request): JsonResponse
    {
        $rules = ['stock' => 'required|array'];
        foreach (BloodUtils::TYPES as $t) {
            $rules["stock.$t"] = 'required|integer|min:0|max:100000';
        }
        $data = $request->validate($rules);

        DB::transaction(function () use ($data) {
            foreach (BloodUtils::TYPES as $t) {
                StockService::set($t, (int) $data['stock'][$t], 'Admin PMI', 'Input manual oleh admin');
            }
        });

        return $this->show();
    }

    /** Admin: riwayat perubahan stok (maks. 500 terbaru). */
    public function logs(Request $request)
    {
        $logs = StockLog::query()
            ->when($request->query('blood_type'), fn ($q, $t) => $q->where('blood_type', $t))
            ->orderByDesc('id')
            ->limit(500)
            ->get();

        return StockLogResource::collection($logs);
    }
}
