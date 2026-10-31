<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatThreadClear extends Model
{
    protected $fillable = ['chat_thread_id', 'user_id', 'cleared_message_id', 'hidden'];

    protected function casts(): array
    {
        return [
            'cleared_message_id' => 'integer',
            'hidden' => 'boolean',
        ];
    }
}
