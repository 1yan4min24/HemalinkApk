<?php

namespace App\Providers;

use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Kembalikan array/objek polos (tanpa pembungkus "data"),
        // sesuai yang diharapkan api_service.dart.
        JsonResource::withoutWrapping();
    }
}
