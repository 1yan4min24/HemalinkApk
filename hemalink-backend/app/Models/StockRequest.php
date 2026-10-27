<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StockRequest extends Model
{
    public const PICKUP_HOURS = 24;

    public const PROCESSING = 'processing';
    public const APPROVED = 'approved';
    public const COMPLETED = 'completed';
    public const REJECTED = 'rejected';
    public const CANCELLED = 'cancelled';

    public const STATUSES = [
        self::PROCESSING, self::APPROVED, self::COMPLETED,
        self::REJECTED, self::CANCELLED,
    ];

    protected $fillable = [
        'user_id', 'requester_phone', 'blood_type', 'bags', 'patient_name',
        'hospital', 'reason', 'letter_no', 'attachment_path', 'attachment_name',
        'status', 'admin_note', 'approved_at', 'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'bags' => 'integer',
            'approved_at' => 'datetime',
            'resolved_at' => 'datetime',
        ];
    }

    /** Pengajuan yang masih menahan (mengunci) stok. */
    public function holdsStock(): bool
    {
        return in_array($this->status, [self::PROCESSING, self::APPROVED], true);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
