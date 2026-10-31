<?php

namespace App\Http\Resources;

use App\Support\Dt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PasswordResetResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'userId' => (string) $this->user_id,
            'name' => $this->user?->name ?? '',
            'username' => $this->user?->username ?? '',
            'phone' => $this->user?->phone ?? '',
            'status' => $this->status,
            'createdAt' => Dt::iso($this->created_at),
            'handledAt' => Dt::iso($this->handled_at),
        ];
    }
}
