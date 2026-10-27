<?php

namespace App\Console\Commands;

use App\Services\StockService;
use Illuminate\Console\Command;

class ExpireOverdueStockRequests extends Command
{
    protected $signature = 'stock:expire-overdue';

    protected $description = 'Batalkan pengajuan disetujui yang tidak diambil dalam 24 jam dan kembalikan stok';

    public function handle(): int
    {
        $n = StockService::expireOverdue();
        $this->info("$n pengajuan dibatalkan otomatis.");

        return self::SUCCESS;
    }
}
