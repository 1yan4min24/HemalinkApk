<?php

namespace App\Http\Resources;

use App\Support\Dt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatMessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'senderId' => (string) $this->sender_id,
            'text' => $this->text,
            'sentAt' => Dt::iso($this->created_at),
        ];
    }
}
