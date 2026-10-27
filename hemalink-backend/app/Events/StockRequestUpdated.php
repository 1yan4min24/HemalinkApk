<?php

namespace App\Events;

use App\Http\Resources\StockRequestResource;
use App\Models\StockRequest;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/** Status pengajuan berubah -> notifikasi real-time ke pemohon dan admin. */
class StockRequestUpdated implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public StockRequest $stockRequest)
    {
        $this->stockRequest->loadMissing('user');
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('user.' . $this->stockRequest->user_id),
            new PrivateChannel('admin'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'stock-request.updated';
    }

    public function broadcastWith(): array
    {
        return ['request' => (new StockRequestResource($this->stockRequest))->resolve()];
    }
}
