<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StockLog extends Model
{
    protected $fillable = ['blood_type', 'before', 'after', 'actor', 'reason'];

    protected function casts(): array
    {
        return ['before' => 'integer', 'after' => 'integer'];
    }
}
