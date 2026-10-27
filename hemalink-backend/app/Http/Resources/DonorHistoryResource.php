<?php

namespace App\Http\Resources;

use App\Support\Dt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DonorHistoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'userId' => (string) $this->user_id,
            'place' => $this->place,
            'reason' => $this->reason,
            'bags' => (int) $this->bags,
            'date' => Dt::iso($this->date),
        ];
    }
}
