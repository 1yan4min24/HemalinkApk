<?php

namespace App\Http\Controllers\Api;

use App\Support\Dt;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\BloodUtils;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class CariPendonorController extends Controller
{
    /** Pendonor yang cocok untuk golongan darah penerima dan sudah lewat jeda donor. */
    public function index(Request $request, string $type): JsonResponse
    {
        abort_unless(in_array($type, BloodUtils::TYPES, true), 422, 'Golongan darah tidak valid.');

        $compatible = array_values(array_filter(
            BloodUtils::TYPES,
            fn ($d) => BloodUtils::canDonate($d, $type)
        ));

        $donors = User::where('role', 'user')
            ->where('id', '!=', $request->user()->id)
            ->whereIn('blood_type', $compatible)
            ->withMax('donorHistories', 'date')
            ->get()
            ->filter(function ($u) {
                $last = $u->donor_histories_max_date;

                return !$last || Carbon::parse($last)->addDays(BloodUtils::DONOR_INTERVAL_DAYS)->isPast();
            })
            ->sortBy(fn ($u) => $u->blood_type === $type ? 0 : 1)
            ->map(fn ($u) => [
                'id' => (string) $u->id,
                'name' => $u->name,
                'phone' => $u->phone,
                'bloodType' => $u->blood_type,
                'city' => $u->city,
                'lastDonorDate' => $u->donor_histories_max_date
                    ? Dt::iso($u->donor_histories_max_date)
                    : null,
            ])
            ->values();

        return response()->json($donors);
    }
}
