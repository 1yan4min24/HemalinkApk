<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DonorHistory extends Model
{
    protected $fillable = ['user_id', 'place', 'reason', 'bags', 'date'];

    protected function casts(): array
    {
        return ['bags' => 'integer', 'date' => 'datetime'];
    }
}
