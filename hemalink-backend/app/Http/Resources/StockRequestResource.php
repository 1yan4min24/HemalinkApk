<?php

namespace App\Http\Resources;

use App\Support\Dt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StockRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'requesterId' => (string) $this->user_id,
            'requesterName' => $this->user?->name ?? '',
            'requesterPhone' => $this->requester_phone ?? '',
            'bloodType' => $this->blood_type,
            'bags' => (int) $this->bags,
            'patientName' => $this->patient_name,
            'hospital' => $this->hospital,
            'reason' => $this->reason,
            'letterNo' => $this->letter_no ?? '',
            'attachmentName' => $this->attachment_name ?? '',
            'createdAt' => Dt::iso($this->created_at),
            'status' => $this->status,
            'adminNote' => $this->admin_note ?? '',
            'approvedAt' => Dt::iso($this->approved_at),
            'resolvedAt' => Dt::iso($this->resolved_at),
        ];
    }
}
