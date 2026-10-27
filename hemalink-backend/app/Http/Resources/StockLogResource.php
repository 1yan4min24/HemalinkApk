<?php

namespace App\Http\Resources;

use App\Support\Dt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StockLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'at' => Dt::iso($this->created_at),
            'actor' => $this->actor,
            'reason' => $this->reason,
            'bloodType' => $this->blood_type,
            'before' => (int) $this->before,
            'after' => (int) $this->after,
        ];
    }
}
