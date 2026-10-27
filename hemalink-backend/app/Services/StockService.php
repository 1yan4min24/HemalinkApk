<?php

namespace App\Services;

use App\Events\StockRequestUpdated;
use App\Models\BloodStock;
use App\Models\StockLog;
use App\Models\StockRequest;
use App\Support\Realtime;
use DomainException;
use Illuminate\Support\Facades\DB;

class StockService
{
    public static function log(string $type, int $before, int $after, string $actor, string $reason): void
    {
        StockLog::create([
            'blood_type' => $type,
            'before' => $before,
            'after' => $after,
            'actor' => $actor,
            'reason' => $reason,
        ]);
    }

    /** Ubah stok sebesar $delta. HARUS dipanggil di dalam DB::transaction. */
    public static function adjust(string $type, int $delta, string $actor, string $reason): BloodStock
    {
        $stock = BloodStock::where('blood_type', $type)->lockForUpdate()->firstOrFail();
        $before = (int) $stock->quantity;
        $after = $before + $delta;
        if ($after < 0) {
            throw new DomainException("Stok golongan $type hanya tersisa $before kantong.");
        }
        $stock->quantity = $after;
        $stock->save();
        self::log($type, $before, $after, $actor, $reason);

        return $stock;
    }

    /** Set stok ke nilai tertentu (input manual admin). Catat log hanya bila berubah. */
    public static function set(string $type, int $qty, string $actor, string $reason): void
    {
        $stock = BloodStock::where('blood_type', $type)->lockForUpdate()->firstOrFail();
        $before = (int) $stock->quantity;
        if ($before === $qty) {
            return;
        }
        $stock->quantity = $qty;
        $stock->save();
        self::log($type, $before, $qty, $actor, $reason);
    }

    /**
     * Pengajuan yang disetujui tapi tidak diambil dalam batas waktu
     * dibatalkan otomatis dan stoknya dikembalikan. Mengembalikan jumlahnya.
     */
    public static function expireOverdue(): int
    {
        $cutoff = now()->subHours(StockRequest::PICKUP_HOURS);
        $ids = StockRequest::where('status', StockRequest::APPROVED)
            ->where('approved_at', '<=', $cutoff)
            ->pluck('id');

        $n = 0;
        foreach ($ids as $id) {
            $done = DB::transaction(function () use ($id) {
                $sr = StockRequest::lockForUpdate()->find($id);
                if (!$sr || $sr->status !== StockRequest::APPROVED) {
                    return null;
                }
                $sr->load('user');
                self::adjust(
                    $sr->blood_type,
                    $sr->bags,
                    'Sistem',
                    'Tidak diambil dalam ' . StockRequest::PICKUP_HOURS . ' jam (' . $sr->user->name . ')'
                );
                $sr->update([
                    'status' => StockRequest::CANCELLED,
                    'resolved_at' => now(),
                    'admin_note' => 'Dibatalkan otomatis: tidak diambil dalam '
                        . StockRequest::PICKUP_HOURS . ' jam setelah disetujui.',
                ]);

                return $sr;
            });

            if ($done) {
                $n++;
                Realtime::send(new StockRequestUpdated($done));
            }
        }

        return $n;
    }
}
