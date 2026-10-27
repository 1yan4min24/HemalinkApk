<?php

namespace App\Http\Resources;

use App\Support\Dt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatThreadResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'requestId' => (string) ($this->blood_request_id ?? ''),
            'requesterId' => (string) $this->requester_id,
            'requesterName' => $this->requester?->name ?? '',
            'donorId' => (string) $this->donor_id,
            'donorName' => $this->donor?->name ?? '',
            'bloodType' => $this->blood_type,
            'createdAt' => Dt::iso($this->created_at),
            'messages' => ChatMessageResource::collection($this->messages)->resolve(),
        ];
    }
}
