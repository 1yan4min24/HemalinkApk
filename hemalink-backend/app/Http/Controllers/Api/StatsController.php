<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BloodRequest;
use App\Models\DonorHistory;
use App\Models\StockRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class StatsController extends Controller
{
    public function index(): JsonResponse
    {
        $byStatus = StockRequest::selectRaw('status, count(*) as total')->groupBy('status')->pluck('total', 'status');
        $counts = [];
        foreach (StockRequest::STATUSES as $s) {
            $counts[$s] = (int) ($byStatus[$s] ?? 0);
        }

        return response()->json([
            'totalUsers' => User::where('role', 'user')->count(),
            'totalDonorsWithHistory' => DonorHistory::distinct('user_id')->count('user_id'),
            'totalBagsRecorded' => (int) DonorHistory::sum('bags'),
            'activeRequests' => BloodRequest::count(),
            'stockRequests' => $counts,
        ]);
    }
}
