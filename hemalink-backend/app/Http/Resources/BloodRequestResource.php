<?php

namespace App\Http\Resources;

use App\Support\Dt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BloodRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'requesterId' => (string) $this->user_id,
            'requesterName' => $this->user?->name ?? '',
            'bloodType' => $this->blood_type,
            'bags' => (int) $this->bags,
            'reason' => $this->reason,
            'hospital' => $this->hospital,
            'createdAt' => Dt::iso($this->created_at),
        ];
    }
}
