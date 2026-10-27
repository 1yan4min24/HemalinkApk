<?php

namespace App\Events;

use App\Http\Resources\StockRequestResource;
use App\Models\StockRequest;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/** Pengajuan baru masuk -> notifikasi real-time ke semua admin. */
class StockRequestSubmitted implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public StockRequest $stockRequest)
    {
        $this->stockRequest->loadMissing('user');
    }

    public function broadcastOn(): array
    {
        return [new PrivateChannel('admin')];
    }

    public function broadcastAs(): string
    {
        return 'stock-request.submitted';
    }

    public function broadcastWith(): array
    {
        return ['request' => (new StockRequestResource($this->stockRequest))->resolve()];
    }
}
