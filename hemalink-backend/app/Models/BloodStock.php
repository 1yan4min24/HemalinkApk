<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BloodStock extends Model
{
    protected $fillable = ['blood_type', 'quantity'];

    protected function casts(): array
    {
        return ['quantity' => 'integer'];
    }
}
