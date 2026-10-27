<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BloodRequest extends Model
{
    protected $fillable = ['user_id', 'blood_type', 'bags', 'reason', 'hospital'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
