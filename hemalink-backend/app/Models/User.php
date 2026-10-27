<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    // 'role' sengaja TIDAK fillable agar tidak bisa diisi dari request.
    protected $fillable = [
        'name', 'username', 'password', 'phone',
        'blood_type', 'city', 'weight', 'height',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'weight' => 'integer',
            'height' => 'integer',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function donorHistories(): HasMany
    {
        return $this->hasMany(DonorHistory::class);
    }
}
