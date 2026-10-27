<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** Format snake_case, sesuai yang dibaca login_screen & register_screen. */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'username' => $this->username,
            'phone' => $this->phone,
            'blood_type' => $this->blood_type,
            'city' => $this->city,
            'weight' => (int) $this->weight,
            'height' => (int) $this->height,
            'role' => $this->role,
        ];
    }
}
